"use strict";

/*~
 * Support for "tribles", that is, tables of triples.  Uses Datatables.
 *
 * Terminology: "atom" here refers to one single part of a triple.  That is, either its
 * subject, its prediate or its object part.  It is represented by an object, with
 * properties like `iri`, `curie`, `value`, `type`, etc.
 *
 * A "resource" is a node in the graph, which is not a scalar value.  That is, it is an
 * atom with an `iri`.  A resource atom can also have a `curie`, an array of `labels`, and
 * an array of `classes`.
 *
 * Note on Datatables: if we want to return anything else than a simple string from a
 * column renderer (that is, actual HTML formatting), it must be as a lexical HTML string.
 * Not as jQuery nodes.  So if we use a jQuery node, we need to use `[0].outerHTML` to get
 * its HTML serialization when returning it.
 */

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

    // initialize the triple tables on the page
    $(document).ready(function () {
        $('.trible-fillin').each(fillInTrible);
    });

    /*~ Create a jQuery `a` element. */
    function aElem(href, content) {
        const elem = $(document.createElement('a'));
        elem.attr('href', href);
        elem.append(content);
        return elem;
    }

    /*~ Create a jQuery `code` element. */
    function codeElem(text, clazz) {
        const elem = $(document.createElement('code'));
        elem.addClass(clazz);
        elem.text(text);
        return elem;
    }

    /*~ Create a link (an `a` element) for an atom which is a resource. */
    function atomLink(kind, root, atom) {
        if ( atom.curie ) {
            // <a href="..."><code class="...">...</code></a>
            return aElem(
                root + 'triples/' + atom.curie,
                codeElem(atom.curie, kind)
            )[0].outerHTML;
        }
        else {
            // <a title="..." href="..."><code class="...">...</code></a>
            const hash = atom.iri.lastIndexOf('#');
            const text = hash >= 0
                ? '...' + atom.iri.slice(atom.iri.lastIndexOf('#'))
                : atom.iri;
            return aElem(
                root + 'triples?rsrc=' + encodeURIComponent(atom.iri),
                codeElem(text, kind)
            )[0].outerHTML;
        }
    }

    /*~
     * Create a value cell for an atom.
     *
     * TODO: Shouldn't we propagate rules also, through links?
     */
    function valueCell(kind, root, atom) {
        return atom.value
            ? atom.value
            : atomLink(kind, root, atom);
    }

    /*~ Create a cell with the label(s) of an atom. */
    function labelCell(root, atom) {
        if ( atom.labels ) {
            return atom.labels.join('<hr/>');
        }
        else {
            return '';
        }
    }

    /*~
     * Create a cell with the class(es) of an atom.
     *
     * TODO: Link to the "class" page, rather than to the "resource" page, once it is
     * deemed usable.
     */
    function classCell(root, atom) {
        if ( atom.classes ) {
            return atom.classes.map(function(c) {
                return atomLink('class', root, c);
            }).join('<br style="margin-bottom: 5pt"/>');
        }
        else {
            return '';
        }
    }

    /*~ Create a type cell for an atom. */
    function typeCell(atom) {
        if ( atom.iri || atom.curie ) {
            return '<span class="fa fa-link" title="Resource"/>';
        }
        else if ( atom.lang ) {
            return '<span class="fa fa-font" title="String, language: ' + atom.lang + '">'
                + String.fromCharCode(160) + atom.lang
                + '</span>';
        }
        // TODO: Handle blank nodes as well.
        //else if ( atom.type === 'blank' ) {
        //    return '<span class="fa fa-unchecked" title="Blank node"/>';
        //}
        else {
            switch ( atom['type-curie'] ) {
            case 'xs:decimal':
            case 'xs:double':
            case 'xs:float':
            case 'xs:int':
            case 'xs:integer':
                return '<span class="fa fa-usd" title="Number"/>';
            case 'xs:date':
            case 'xs:dateTime':
                return '<span class="fa fa-hourglass" title="Date"/>';
            default:
                // assuming a string for everything else.
                return '<span class="fa fa-font" title="String"/>';
            }
        }
    }

    /*~
     * Fill in a triple table, using its `data-*` attribute to retrieve the triples.
     *
     * Triples are retrieved asynchronously from the API triples endpoint.  The table is
     * passed as `this`.
     */
    function fillInTrible() {
        const table   = $(this);
        // extract params set on the table by the server
        const db      = table.data('trible-db');
        const rules   = table.data('trible-rules');
        const root    = table.data('trible-root');
        const subject = table.data('trible-subject');
        const object  = table.data('trible-object');
        const dir     = subject ? 'out' : 'in';
        if ( ! subject && ! object ) {
            throw new Error('Neither subject nor object set on the trible');
        }
        else if ( subject && object ) {
            throw new Error(`Both subject and object set on the trible: ${subject} - ${object}`);
        }
        // the endpoint url
        const params = {};
        if ( subject ) params.subject = subject;
        if ( object  ) params.object  = object;
        if ( rules   ) params.rules   = rules;
        const url = '/api/db/' + db + '/triples?'
            + Object.keys(params)
                .map(p => `${p}=${encodeURIComponent(params[p])}`)
                .join('&');
        // do it
        fetch(url, { credentials: 'same-origin' })
            .then(function(resp) {
                return resp.json();
            })
            .then(function(resp) {
                // should we first remove everything in the table?
                table.show();
                // TODO: Pass options stored in the DB config file on the server, as extra
                // data-trible-* attributes.  E.g. whether to paginate, etc.
                doFillIn(table, resp.triples, dir, root);
                // TODO: Display a load spinner, or a text saying "loading", and hide it
                // here when everything is done.  Alternatively or in addition, display an
                // error message, would any error occur (before or within fetch call...)
            });
    }

    /*~
     * Fill in a table with triples.
     *
     * The `table` is a jQuery table element.  The `triples` are an array of triples, each
     * with 3 atoms.  The `root` is used to resolve links.
     */
    function doFillIn(table, triples, dir, root) {
        const details = dir === 'out' ? 'object' : 'subject';
        const columns = [];
        if ( dir === 'in' ) {
            columns.push({
                title: 'Subject',
                render: function(datum, type, row) {
                    return valueCell('rsrc', root, row.subject);
                }});
        }
        columns.push({
            title: 'Property',
            render: function(datum, type, row) {
                return valueCell('prop', root, row.predicate);
            }});
        if ( dir === 'out' ) {
            columns.push({
                title: 'Object',
                render: function(datum, type, row) {
                    return valueCell('rsrc', root, row.object);
                }});
        }
        if ( triples.find(t => t[details].classes) ) {
            columns.push({
                title: 'Class',
                render: function(datum, type, row) {
                    return classCell(root, row[details]);
                }});
        }
        if ( triples.find(t => t[details].labels) ) {
            columns.push({
                title: 'Label',
                render: function(datum, type, row) {
                    return labelCell(root, row[details]);
                }});
        }
        columns.push({
            title: 'Type',
            data: details,
            searchable: false,
            orderable: false,
            className: 'dt-body-right',
            render: typeCell
        });
        table.DataTable({
            paging: false,
            info: false,
            language: {
                search: 'Filter triples:'
            },
            order: [[ dir === 'out' ? 0 : 1, 'asc' ]],
            data: triples,
            columns: columns
        });
    }

})();

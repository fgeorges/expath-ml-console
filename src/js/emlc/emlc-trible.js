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

    /*~ Display an error on the page. */
    function onError(err, template, loading) {
        if ( template ) {
            var tmpl  = $('#' + template);
            var alert = tmpl.clone();
            alert.children('strong').text('Error');
            alert.children('span').text(err.message || err);
            alert.addClass('show alert-danger');
            alert.insertBefore(tmpl);
            alert.show();
        }
        else {
            alert(`Error when loading triple table: ${err.message || err}`);
        }
        if ( loading ) {
            $('#' + loading).hide();
        }
        console.error(err);
    }

    /*~ Create a jQuery `a` element. */
    function aElem(href, content, title) {
        const elem = $(document.createElement('a'));
        elem.attr('href', href);
        elem.append(content);
        if ( title ) {
            elem.attr('title', title);
        }
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
    function atomLink(kind, root, atom, shorten) {
        if ( atom.blank ) {
            kind = 'blank';
        }
        if ( atom.curie ) {
            // <a href="..."><code class="...">...</code></a>
            return aElem(
                root + 'triples/' + atom.curie,
                codeElem(atom.curie, kind));
        }
        else {
            // <a title="..." href="..."><code class="...">...</code></a>
            const hash = shorten && atom.iri.lastIndexOf('#');
            const text = hash >= 0
                ? '...' + atom.iri.slice(hash)
                : atom.iri;
            return aElem(
                root + 'triples?rsrc=' + encodeURIComponent(atom.iri),
                codeElem(text, kind),
                hash >= 0 && atom.iri);
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
            : atomLink(kind, root, atom, true)[0].outerHTML;
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
                return atomLink('class', root, c, true)[0].outerHTML;
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
        const message = table.data('trible-message');
        const loading = table.data('trible-loading');
        try {
            // extract params set on the table by the server
            const db      = table.data('trible-db');
            const rules   = table.data('trible-rules');
            const root    = table.data('trible-root');
            const subject = table.data('trible-subject');
            const object  = table.data('trible-object');
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
                    const dir     = subject ? 'out' : 'in';
                    const triples = resp.triples;
                    if ( dir === 'out' && triples.length ) {
                        enrichSummary(triples[0].subject, root);
                    }
                    table.show();
                    // TODO: Pass options stored in the DB config file on the server, as extra
                    // data-trible-* attributes.  E.g. whether to paginate, etc.
                    doFillIn(table, triples, dir, root);
                    if ( loading ) {
                        $('#' + loading).hide();
                    }
                })
                .catch(function(err) {
                    onError(err, message, loading);
                });
        }
        catch (err) {
            onError(err, message, loading);
        }
    }

    /*~
     * Fill in a table with triples.
     *
     * The `table` is a jQuery table element.  The `triples` are an array of triples, each
     * with 3 atoms.  The `root` is used to resolve links.
     */
    function doFillIn(table, triples, dir, root) {
        const origin = dir === 'out' ? 'subject' : 'object';
        const dest   = dir === 'out' ? 'object'  : 'subject';
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
        if ( triples.find(t => t[dest].classes) ) {
            columns.push({
                title: 'Class',
                render: function(datum, type, row) {
                    return classCell(root, row[dest]);
                }});
        }
        if ( triples.find(t => t[dest].labels) ) {
            columns.push({
                title: 'Label',
                render: function(datum, type, row) {
                    return labelCell(root, row[dest]);
                }});
        }
        columns.push({
            title: 'Type',
            data: dest,
            searchable: false,
            orderable: false,
            className: 'dt-body-right',
            render: typeCell
        });
        table.DataTable({
            paging: false,
            infoCallback: function() { return `All the triples with this resource as their <em>${origin}</em>.<p/>`; },
            dom: "<'row'<'col-sm-12 col-md-6'i><'col-sm-12 col-md-6'f>><'row'<'col-sm-12'tr>>",
            language: {
                search: 'Filter triples:'
            },
            order: [[ dir === 'out' ? 0 : 1, 'asc' ]],
            data: triples,
            columns: columns
        });
    }

    /*~ Enrich the initial summary table with additional info. */
    function enrichSummary(atom, root) {
        const summary = $('#summary tbody');
        if ( atom.labels ) {
            const tr = $(document.createElement('tr'));
            const th = $(document.createElement('th'));
            const td = $(document.createElement('td'));
            summary.append(tr);
            tr.append(th);
            tr.append(td);
            if ( atom.labels.length > 1 ) {
                // <tr><th rowspan="...">Labels</th><td>...</td></tr>
                // <tr><td>...</td></td>
                th.text('Labels');
                th.attr('rowspan', atom.labels.length);
                td.text(atom.labels[0]);
                atom.labels.slice(1).forEach(function(label) {
                    const tr = $(document.createElement('tr'));
                    const td = $(document.createElement('td'));
                    summary.append(tr);
                    tr.append(td);
                    td.text(label);
                });
            }
            else {
                // <tr><th>Label</th><td>...</td></tr>
                th.text('Label');
                td.text(atom.labels[0]);
            }
        }
        if ( atom.classes ) {
            const tr = $(document.createElement('tr'));
            const th = $(document.createElement('th'));
            const td = $(document.createElement('td'));
            summary.append(tr);
            tr.append(th);
            tr.append(td);
            if ( atom.classes.length > 1 ) {
                // <tr><th rowspan="...">Classes</th><td>...</td></tr>
                // <tr><td>...</td></td>
                th.text('Classes');
                th.attr('rowspan', atom.classes.length);
                td.append(atomLink('class', root, atom.classes[0]));
                atom.classes.slice(1).forEach(function(clazz) {
                    const tr = $(document.createElement('tr'));
                    const td = $(document.createElement('td'));
                    summary.append(tr);
                    tr.append(td);
                    td.append(atomLink('class', root, clazz));
                });
            }
            else {
                // <tr><th>Class</th><td>...</td></tr>
                th.text('Class');
                td.append(atomLink('class', root, atom.classes[0]));
            }
        }
    }

})();

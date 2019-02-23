"use strict";

/*~
 * Support for "tribles", that is, tables of triples.  Uses Datatables.
 *
 * Terminology: "atom" here refers to one single part of a triple.  That is, either its
 * subject, its prediate or its object part.
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

    /*~ Create a jQuery a element. */
    function aElem(href, content) {
        const elem = $(document.createElement('a'));
        elem.attr('href', href);
        elem.append(content);
        return elem;
    }

    /*~ Create a jQuery code element. */
    function codeElem(text, clazz) {
        const elem = $(document.createElement('code'));
        elem.addClass(clazz);
        elem.text(text);
        return elem;
    }

    /*~
     * Create a value cell for an atom.
     *
     * TODO: Shouldn't we propagate rules also, through links?
     */
    function valueCell(kind, root, atom) {
        if ( atom.curie ) {
            // <a href="..."><code class="...">...</code></a>
            return aElem(
                root + 'triples/' + atom.curie,
                codeElem(atom.curie, kind)
            )[0].outerHTML;
        }
        else if ( atom.iri ) {
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
        else {
            return atom.value;
        }
    }

    /*~
     * Create a type cell for an atom.
     */
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

    function fillInTrible() {
        const table   = $(this);
        // extract params set on the table by the server
        const subject = table.data('trible-subject');
        const db      = table.data('trible-db');
        const rules   = table.data('trible-rules');
        const root    = table.data('trible-root');
        // the endpoint url
        const url = '/api/db/' + db + '/triples'
            + '?subject=' + encodeURIComponent(subject);
            + '&rules='   + encodeURIComponent(rules);
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
                doFillIn(table, resp.triples, root);
            });
    }

    function doFillIn(table, triples, root) {
        table.DataTable({
            paging: false,
            info: false,
            language: {
                search: 'Filter triples:'
            },
            data: triples,
            columns: [
                { title: 'Property',
                  render: function(datum, type, row) {
                      return valueCell('prop', root, row.predicate);
                  }},
                { title: 'Object',
                  render: function(datum, type, row) {
                      return valueCell('rsrc', root, row.object);
                  }},
                // TODO: Support the "label" (resp. "class") column, if there is any
                // object with a label (resp. class) in the whole triple list.
                //{ title: "Label" },
                //{ title: "Class" },
                { title: 'Type',
                  data: 'object',
                  searchable: false,
                  orderable: false,
                  className: 'dt-body-right',
                  render: typeCell }
            ]});
    }

})();

"use strict";

/*~
 * Support for "tribles", that is, "triple tables".  Uses Datatables.
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

    // module variable to store the triples from the requests to the endpoint
    const tripleCache = {
        triples: {
            "in":  null,
            "out": null
        },
        nodes:  {},
        edges:  {},
        values: {}    // not used yet
    };
    tripleCache.expected = Object.keys(tripleCache.triples).length;

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

    /*~
     * Shorten an atom IRI (to its CURIE if any, or if possible to "...#stuff" notation.)
     *
     * TODO: Add the concept of "shortened IRI" to the service (either the CURIE,
     * or "...#stuff" if there is a "#" (or ".../stuff" or "...:stuff",) when
     * applicable (and fallback to the full IRI when displaying it, if there is
     * none.)
     */
    function shorten(atom) {
        if ( atom.curie ) {
            return atom.curie;
        }
        else {
            const hash = atom.iri.lastIndexOf('#');
            return hash > 0
                ? '...' + atom.iri.slice(hash)
                : atom.iri;
        }
    }

    /*~ Create a link (an `a` element) for an atom which is a resource. */
    function atomLink(kind, root, atom, toshorten) {
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
            let tip;
            let text = atom.iri;
            if ( toshorten ) {
                text = shorten(atom);
                if ( atom.iri !== text ) {
                    tip = atom.iri;
                }
            }
            return aElem(
                root + 'triples?rsrc=' + encodeURIComponent(atom.iri),
                codeElem(text, kind),
                tip);
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
        if ( atom.blank ) {
            return '<span class="fa fa-vector-square" title="Blank node"/>';
        }
        else if ( atom.iri || atom.curie ) {
            return '<span class="fa fa-link" title="Resource"/>';
        }
        else if ( atom.lang ) {
            return '<span class="fa fa-font" title="String, language: ' + atom.lang + '">'
                + String.fromCharCode(160) + atom.lang
                + '</span>';
        }
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
                    showLoaded(table);
                    // TODO: Pass options stored in the DB config file on the server, as extra
                    // data-trible-* attributes.  E.g. whether to paginate, etc.
                    doFillIn(table, triples, dir, root);
                    cacheTriples(triples, dir);
                })
                .catch(function(err) {
                    onError(err, message, loading);
                });
        }
        catch (err) {
            onError(err, message, loading);
        }
    }

    function showLoaded(id) {
        const component = typeof id === 'string' ? $('#' + id) : id;
        const loading   = component.data('trible-loading');
        component.show();
        if ( loading ) {
            $('#' + loading).hide();
        }
    }

    function cacheTriples(triples, dir) {
        if ( tripleCache.triples[dir] ) {
            throw new Error(`Already received triples for request "${dir}"`);
        }
        // keep the triples as is, from the endpoint
        tripleCache.triples[dir] = triples;
        tripleCache.expected --;
        // cache the subject, if this is the correct request
        if ( ! tripleCache.subject && triples.length ) {
            tripleCache.subject = dir === 'out'
                ? shorten(triples[0].subject)
                : shorten(triples[0].object);
        }
        const addNode = function(rsrc, pred, atom) {
            let slot = tripleCache.nodes[rsrc];
            if ( ! slot ) {
                slot = tripleCache.nodes[rsrc] = {
                    name:    rsrc,
                    labels:  atom.labels  || [],
                    classes: atom.classes || [],
                    preds:   []
                };
            }
            if ( (! tripleCache.subject || tripleCache.subject !== rsrc) && (! slot.preds.includes(pred)) ) {
                slot.preds.push(pred);
            }
        };
        // fill in the cache map
        triples.forEach(function(t) {
            const s = shorten(t.subject);
            const p = shorten(t.predicate);
            addNode(s, p, t.subject);
            if ( t.object.value ) {
                let slot1 = tripleCache.values[s];
                if ( ! slot1 ) {
                    slot1 = tripleCache.values[s] = {};
                }
                let slot2 = slot1[p];
                if ( ! slot2 ) {
                    slot2 = slot1[p] = [];
                }
                slot2.push(t.object.value);
            }
            else {
                const o = t.object.iri && shorten(t.object);
                addNode(o, p, t.object);
                let slot1 = tripleCache.edges[s];
                if ( ! slot1 ) {
                    slot1 = tripleCache.edges[s] = {};
                }
                let slot2 = slot1[o];
                if ( ! slot2 ) {
                    slot2 = slot1[o] = {};
                }
                let slot3 = slot2[p];
                if ( ! slot3 ) {
                    slot3 = slot2[p] = {};
                }
                // does not allow several triples "?s ?p ?o" (yet?)
                slot3[p] = t.predicate;
            }
        });
        // time to draw?
        if ( tripleCache.expected ) {
            setTimeout(delayedDrawing, 1000);
        }
        else {
            drawGraph();
        }
    }

    function delayedDrawing() {
        // if still expecting one, then go (if not, the last one had already gone)
        if ( tripleCache.expected ) {
            drawGraph();
        }
    }

    /*~ Flatten the map into a node array suitable for D3. */
    function getNodes() {
        const nodes = Object.keys(tripleCache.nodes).map(function(name) {
            return tripleCache.nodes[name];
        });
        return nodes;
    }

    /*~ Flatten the map into an edge array suitable for D3. */
    function getEdges() {
        const edges = [];
        Object.keys(tripleCache.edges).forEach(function(source) {
            const slot = tripleCache.edges[source];
            Object.keys(slot).forEach(function(target) {
                // does not take the various predicates into account, yet (if more than one)
                edges.push({ source: source, target: target });
            });
        });
        return edges;
    }

    /*~
     * A textBlock is a text label, with a rectangle around it.
     *
     * This extension returns a function, which can be called on a D3 selection to append
     * a `text` element to it, as well as a `rect` element.  Typically, the selection is a
     * `g` element.  Positionning the text and the rect are done relatively to 0, so using
     * transform/translate is OK (well is mandatory) to move the text-block around.
     *
     * The value of the text label is given as a string or a function returning a string
     * (when called with datum/index).  The colors to use are represented by an object,
     * either fixed or returned by a function as well.  It must contain the properties
     * `text`, `bg` and `border`.
     */
    d3.textBlock = function() {
        // the params from 'instantiation'
        const params = {
            label:   null,
            details: null,
            colors:  null
        };

        function impl(selection) {
            // inside 'each()', datum is the current data item, index is its index.
            // 'this' is the element that has been appended, e.g. an svg:g
            selection.each(function(datum, index) {
                const label = typeof params.label === 'function'
                    ? params.label(datum, index)
                    : params.label;
                const details = typeof params.details === 'function'
                    ? params.details(datum, index)
                    : params.details;
                // TODO: Use CSS instead!
                const colors = typeof params.colors === 'function'
                    ? params.colors(datum, index)
                    : params.colors;
                const options = {
                    folded:  true,
                    label:   label,
                    details: details,
                    color:   colors.color,
                    bg:      colors.bg,
                    border:  colors.border
                };
                const parent = d3.select(this)
                    .on('click', function(datum, index) {
                        draw(this, options);
                    });
                draw(this, options);
            });
        }

        function draw(element, params) {
            const folded = params.folded;
            params.folded = ! folded;
            // remove all content from the parent
            const parent = d3.select(element).html(null);
            // first append text to the parent
            const text = parent.append('text')
                .text(params.label)
                .style('font-size', '9pt')
                .style('font-family', "'Source Code Pro', Consolas, Menlo, Monaco, 'Courier New', monospace")
                .attr('fill', params.color);
            // get the bounding box of the just created text element
            const bbox = text.node().getBBox();
            let maxwidth = bbox.width;
            let lines = 1;
            // this is a draft of something like a summary box for a resource
            // work in progress...
            if ( ! folded ) {
                const adaptWidth = function(e) {
                    const b = e.node().getBBox();
                    if ( b.width > maxwidth ) {
                        maxwidth = b.width;
                    }
                };
                text.style('text-decoration-line', 'underline')
                    .style('text-decoration-color', params.border);
                params.details.forEach(function(detail) {
                    if ( Array.isArray(detail) ) {
                        detail.forEach(function(d) {
                            const t = parent.append('text')
                                .text(d)
                                .attr('y', 1 + 16 * lines)
                                .style('font-size', '8pt');
                            ++lines;
                            adaptWidth(t);
                        });
                    }
                    else if ( detail.values.length ) {
                        const values = detail.values;
                        const t = parent.append('text')
                            .attr('y', 1 + 16 * lines);
                        t.append('tspan')
                            .text((values.length > 1 ? detail.plural : detail.singular) + ': ')
                            .style('font-size', '9pt');
                        t.append('tspan')
                            .text(values[0])
                            .style('font-size', '8pt')
                            .style('font-family', "'Source Code Pro', Consolas, Menlo, Monaco, 'Courier New', monospace")
                            .attr('fill', params.color);
                        values.slice(1).forEach(function(v) {
                            t.append('tspan')
                                .text(', ')
                                .style('font-size', '9pt');
                            t.append('tspan')
                                .text(v)
                                .style('font-size', '8pt')
                                .style('font-family', "'Source Code Pro', Consolas, Menlo, Monaco, 'Courier New', monospace")
                                .attr('fill', params.color);
                        });
                        ++lines;
                        adaptWidth(t);
                    }
                });
            }
            const bbox2 = text.node().getBBox();
            const bbox3 = text.node().getBBox();
            const bbox4 = text.node().getBBox();
            // then append svg rect to the parent
            // doing some adjustments so we fit snugly around the text: we are
            // inside a transform, so only have to move relative to 0
            parent.insert('rect', ':first-child')
                .attr('rx', 3)
                .attr('ry', 3)
                .attr('x', bbox.x - 5) // 5px margin
                .attr('y', bbox.y - 3) // 3px margin
                .attr('width', maxwidth + 10) // 5px margin on left + right
                .attr('height', bbox.height + 6 + (lines - 1) * 16)
                .attr('fill', params.bg)
                .attr('stroke', params.border)
                .attr('stroke-width', '1px');
        }

        // getter/setter for the label param
        impl.label = function(value) {
            if ( ! arguments.length ) {
                return params.label;
            }
            params.label = value;
            return impl;
        };

        // getter/setter for the details param
        impl.details = function(value) {
            if ( ! arguments.length ) {
                return params.details;
            }
            params.details = value;
            return impl;
        };

        // getter/setter for the colors param
        impl.colors = function(value) {
            if ( ! arguments.length ) {
                return params.colors;
            }
            params.colors = value;
            return impl;
        };

        return impl;
    };

    function drawGraph() {
        console.log(`Draw graph whilst still expecting ${tripleCache.expected} requests`);
        showLoaded('graph');
        const nodes  = getNodes();
        const edges  = getEdges();
        const height = 400;
        const graph  = d3.select('#graph')
            .attr('width',  '100%')
            .attr('height', height);
        // tblock is a function to create a text label, with a rectangle around it
        const tblock = d3.textBlock()
            .label(function(datum) {
                return datum.name;
            })
            .details(function(datum) {
                return [
                    { singular: 'predicate',
                      plural: 'predicates',
                      values: datum.preds },
                    { singular: 'class',
                      plural: 'classes',
                      values: datum.classes.map(function(c) {
                          return c.curie || c.iri;
                      }) },
                    datum.labels
                ];
            })
            .colors(function(datum) {
                return datum.name === tripleCache.subject
                    ? { color: '#dd1144', bg: '#fcf6f8', border: '#f7d6df' }
                    : { color: '#2a839e', bg: '#f5fafb', border: '#a8ddec' };
            });
        // all the vertex elements
        const vertices = graph.select('#graph-nodes').selectAll('rect')
            .data(nodes)
            .enter()
              .append('g')
              .attr('transform', function(datum) { return `translate(${datum.x},${datum.y})`; })
              .call(tblock);
        // all the link elements
        const links = d3.select('#graph-links')
            .selectAll('line')
            .data(edges)
            .enter()
              .append('line')
                .attr('stroke', '#a8ddec');
        // where the force graph magic happens
        d3.forceSimulation()
            .nodes(nodes)
            // parseInt() drops the "*px" at the end
            .force('center_force', d3.forceCenter((parseInt(graph.style('width')) / 2) - 75, height / 2))
            .force('charge_force', d3.forceManyBody())
            .force('links', d3.forceLink(edges).id(function(datum) { return datum.name; }).distance(160))
            .on('tick', function() {
                vertices.attr('transform', function(datum) {
                    const x = datum.x;
                    const y = datum.y;
                    return `translate(${x}, ${y})`;
                })
                links.attr('x1', function(datum) { return datum.source.x; })
                    .attr('y1', function(datum) { return datum.source.y; })
                    .attr('x2', function(datum) { return datum.target.x; })
                    .attr('y2', function(datum) { return datum.target.y; });
            });
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

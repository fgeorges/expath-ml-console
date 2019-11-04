"use strict";

/*~
 * Support for "tribles" and "triphs", that is, "triple tables" and "triple graphs".
 *
 * Tribles use Datatables.  Triphs use D3.
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
window.emlc = window.emlc || {debug: {}};

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
            var tmpl  = $(template);
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
            $(loading).hide();
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
                text = atom.abbrev;
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
        return atom.value === undefined
            ? atomLink(kind, root, atom, true)[0].outerHTML
            : atom.value;
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
            return '<span class="fa fa-clone" title="Blank node"/>';
        }
        else if ( atom.iri || atom.curie ) {
            return '<span class="fa fa-link" title="Resource"/>';
        }
        else if ( atom.lang ) {
            return '<span class="fa fa-font" title="String, language: ' + atom.lang + '">'
                + String.fromCharCode(160) + atom.lang
                + '</span>';
        }
        else if ( atom.numeric ) {
            return `<strong style="font-size: 1.2em;">3</strong>`;
        }
        else if ( ['xs:date', 'xs:dateTime'].includes(atom['type-curie']) ) {
            return '<span class="far fa-clock" title="Date"/>';
        }
        else {
            // assuming a string for everything else.
            return '<span class="fa fa-font" title="String"/>';
        }
    }

    /*~
     * Fill in a triple table, using its `data-*` attribute to retrieve the triples.
     *
     * Triples are retrieved asynchronously from the API triples endpoint.  The table is
     * passed as `this`.
     *
     * TODO: Pass options stored in the DB config file on the server, as extra attributes
     * data-trible-*.  E.g. whether to paginate, etc.
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
                    showLoaded(table, loading);
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

    function showLoaded(id, data) {
        const component = typeof id === 'string' ? $(id) : id;
        const loading   = data || component.data('trible-loading');
        component.show();
        if ( loading ) {
            $(loading).hide();
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
                ? triples[0].subject.abbrev
                : triples[0].object.abbrev;
        }
        const addNode = function(rsrc, pred, atomRsrc, atomPred) {
            let slot = tripleCache.nodes[rsrc];
            if ( ! slot ) {
                slot = tripleCache.nodes[rsrc] = {
                    name:    rsrc,
                    rsrc:    atomRsrc,
                    labels:  atomRsrc.labels  || [],
                    classes: atomRsrc.classes || [],
                    preds:   {}
                };
            }
            if ( (! tripleCache.subject || tripleCache.subject !== rsrc) && (! slot.preds[pred]) ) {
                slot.preds[pred] = atomPred;
            }
        };
        // fill in the cache map
        triples.forEach(function(t) {
            const s = t.subject.abbrev;
            const p = t.predicate.abbrev;
            addNode(s, p, t.subject, t.predicate);
            if ( t.object.value === undefined ) {
                const o = t.object.iri && t.object.abbrev;
                addNode(o, p, t.object, t.predicate);
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
            else {
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
            root:    null,
            tooltip: null,
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
                const iri = typeof params.iri === 'function'
                    ? params.iri(datum, index)
                    : params.iri;
                const root = typeof params.root === 'function'
                    ? params.root(datum, index)
                    : params.root;
                const tooltip = typeof params.tooltip === 'function'
                    ? params.tooltip(datum, index)
                    : params.tooltip;
                tooltip
                    .css('z-index', 100)
                    .on('click', function() { tooltip.hide(); });
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
                    root:    root,
                    tooltip: tooltip,
                    details: details,
                    color:   colors.color,
                    bg:      colors.bg,
                    border:  colors.border
                };
                d3.select(this)
                    .on('click', function() {
                        // TODO: Open its own edges (retrieve and draw triples from and to
                        // the current node, to "hop" through the semantic graph...)
                        //
                        // Send 2 requests, like in fillInTrible() (for triples in and out
                        // of the node.)  Add them to the same triple cache (I guess I can
                        // rework it a bit to be optimized as a "triple graph cache", so
                        // it is specifically for drawing the graph.
                        //
                        // Make sure it supports (and is robust for) real graphs, not only
                        // the current resource and its direct neighbours.
                        //
                        // And then just trigger drawing the graph again.
                    })
                    .on('mouseover', function() {
                        drawTip(datum, options);
                    });
                drawBox(this, options);
            });
        }

        function drawBox(element, params) {
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
            // then append svg rect to the parent
            // doing some adjustments so we fit snugly around the text: we are
            // inside a transform, so only have to move relative to 0
            parent.insert('rect', ':first-child')
                .attr('rx', 3)
                .attr('ry', 3)
                .attr('x', bbox.x - 5) // 5px margin
                .attr('y', bbox.y - 3) // 3px margin
                .attr('width', bbox.width + 10) // 5px margin on left + right
                .attr('height', bbox.height + 6)
                .attr('fill', params.bg)
                .attr('stroke', params.border)
                .attr('stroke-width', '1px');
        }

        function drawTip(datum, params) {
            const elem = function(name) { return $(document.createElement(name)) };
            const tt   = params.tooltip;

            tt.html(null)
                .css("left", (d3.event.pageX - 75) + "px")
                .css("top",  (d3.event.pageY + 10) + "px")
                .show();

            if ( datum.labels.length > 1 ) {
                const labels = elem('ul');
                tt.append(labels);
                datum.labels.forEach(function(l) {
                    labels.append(elem('li').text(l));
                });
                tt.append(elem('hr'));
            }
            else if ( datum.labels.length ) {
                tt.append(elem('p').text(datum.labels[0]));
                tt.append(elem('hr'));
            }

            const iri = elem('span');
            iri.append(elem('span').text('IRI: '));
            iri.append(atomLink('rsrc', params.root, datum, true));
            tt.append(iri);

            if ( datum.classes.length ) {
                const classes = elem('span');
                classes.append(elem('span').text('Type: '));
                datum.classes.forEach(function(c) {
                    classes.append(atomLink('class', params.root, c, true));
                });
                tt.append(elem('hr'));
                tt.append(classes);
            }

            const pkeys = Object.keys(datum.preds);
            if ( pkeys.length ) {
                const preds = elem('span');
                preds.append(elem('span').text('Predicate: '));
                pkeys.forEach(function(p) {
                    preds.append(atomLink('prop', params.root, datum.preds[p], true));
                });
                tt.append(elem('hr'));
                tt.append(preds);
            }
        }

        // getter/setter for the label param
        impl.label = function(value) {
            if ( ! arguments.length ) {
                return params.label;
            }
            params.label = value;
            return impl;
        };

        // getter/setter for the iri param
        impl.iri = function(value) {
            if ( ! arguments.length ) {
                return params.iri;
            }
            params.iri = value;
            return impl;
        };

        // getter/setter for the root param
        impl.root = function(value) {
            if ( ! arguments.length ) {
                return params.root;
            }
            params.root = value;
            return impl;
        };

        // getter/setter for the tooltip param
        impl.tooltip = function(value) {
            if ( ! arguments.length ) {
                return params.tooltip;
            }
            params.tooltip = value;
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
        showLoaded('#triph');
        const nodes   = getNodes();
        const edges   = getEdges();
        const height  = 400;
        const tooltip = $('#triph-tooltip');
        const graph   = d3.select('#triph')
            .attr('width',  '100%')
            .attr('height', height)
            .on('click', function() {
                tooltip.hide();
            });
        const root   = graph.attr('data-trible-root');
        const tblock = d3.textBlock()
            .root(root)
            .tooltip(tooltip)
            .label(function(datum) {
                return datum.name;
            })
            .iri(function(datum) {
                return datum.iri;
            })
            .colors(function(datum) {
                return datum.name === tripleCache.subject
                    ? { color: '#dd1144', bg: '#fcf6f8', border: '#f7d6df' }
                    : { color: '#2a839e', bg: '#f5fafb', border: '#a8ddec' };
            });
        // all the vertex elements
        const vertices = graph.select('#triph-nodes').selectAll('rect')
            .data(nodes)
            .enter()
              .append('g')
              .attr('transform', function(datum) { return `translate(${datum.x},${datum.y})`; })
              .call(tblock);
        // all the link elements
        const links = d3.select('#triph-links')
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
                    return `translate(${datum.x}, ${datum.y})`;
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

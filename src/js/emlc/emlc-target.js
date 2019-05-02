"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

    emlc.targetInitWidget = targetInitWidget;

    $(function () {
        // init all widgets on the page
        $('.emlc-target-widget').each(targetInitWidget);

        // make the target text field (displaying the selected target) read-only
        $('.emlc-target-field').on('keydown paste', function(e) {
            e.preventDefault();
        });

        // make each entry in the dropdown lists udpate the target field, on selection
        $('.emlc-target-entry').on('click', function(e) {
            e.preventDefault();
            var a     = $(this);
            var field = a.data('field');
            var label = a.data('label');
            var id    = a.data('id');
            // set the ID and label fields
            $(field + ' input:text'  ).val(label);
            $(field + ' input:hidden').val(id);
            // activate the components waiting for a target to be selected
            $('.need-target').prop('disabled', false);
        });
    });

    function targetInitWidget(elem)
    {
        // the widget element
        const widget = $(elem || this);
        // init selector buttons
        const selectors = widget.find('.emlc-target-selector');
        selectors.each(function() {
            const self = $(this);
            self.find('a').on('click', function(event) {
                event.preventDefault();
                targetSelect($(this), self, selectors, widget);
            });
        });
        // init execute button
        widget.find('.emlc-target-execute')
            .on('click', function(event) {
                targetExecute(widget);
            });
    }

    function targetSelect(item, self, selectors, widget)
    {
        // label and id of current selection (the A element)
        const label = item.data('label');
        const id    = item.data('id');
        // "reset" all buttons text to their original (and change colour)
        selectors.each(function() {
            const s = $(this);
            const l = s.data('label');
            s.find('button')
                .text(l)
                .removeClass('btn-secondary')
                .addClass('btn-outline-secondary');
        });
        // set the current button label to the selected item (and change colour)
        self.find('button')
            .text(label)
            .removeClass('btn-outline-secondary')
            .addClass('btn-secondary');
        // set the id on the widget
        widget.data('id', id);
    }

    function targetExecute(widget) {
        const error = (msg) => {
            emlc.footpanePurge();
            emlc.footpaneError(msg);
            emlc.footpaneExpand();
        };
        // params from widget
        const id     = widget.data('id');
        const lang   = widget.data('lang');
        const code   = widget.data('code');
        const params = widget.data('params');
        if ( ! id )   { error('No target selected');   return; }
        if ( ! lang ) { error('No lang for the code'); return; }
        if ( ! code ) { error('No code to execute');   return; }
        // the request content
        const body = {
            target: id,
            lang:   lang,
            params: [],
            code:   code
        };
        if ( params && params.length ) {
            for ( const p of params.split(/,/) ) {
                const e = $('#' + p);
                if ( e.length !== 1 ) {
                    error(`Not exactly one element with ID ${p}: ${e.length}`);
                }
                const n = e.data('param-name');
                const l = e.data('param-label');
                const t = e.data('param-type');
                const o = e.data('param-occurrence');
                const v = e.val();
                const r = { name: n, label: l, value: v };
                if ( ! n ) {
                    error(`Param with no name, ID ${p}`);
                }
                if ( ! l ) {
                    error(`Param with no label: ${n} - ID ${p}`);
                }
                if ( t ) {
                    r.type = t;
                }
                if ( o ) {
                    r.occurrence = o;
                }
                body.params.push(r);
            }
        }
        // the request
        const req = {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(body),
            credentials: 'same-origin'
        };
        // send it
        fetch('../api/tool/eval', req)
            .then(function(resp) {
                return resp.text();
            })
            .then(function(resp) {
                // TODO: Check HTTP response code, instead of relying solely on
                // JSON parsing throwing an error.  Especially that at the end of
                // the day, the endpoint should return, in case of error, a JSON
                // with all relevant information (not the default HTML by ML.)
                try {
                    const json = JSON.parse(resp);
                    emlc.footpanePurge();
                    json.result.forEach(function(res) {
                        emlc.footpaneAdd(res.value, res.type, json.input.dbname);
                    });
                    emlc.footpaneExpand();
                }
                catch (err) {
                    error(resp);
                }
            })
            .catch(function(err) {
                // TODO: Proper error reporting...
                alert('ERROR: ' + err);
                console.log(arguments);
                error(err);
            });
    }

})();

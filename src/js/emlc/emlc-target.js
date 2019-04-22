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
        const id   = encodeURIComponent(widget.data('id'));
        const lang = encodeURIComponent(widget.data('lang'));
        const code = encodeURIComponent(widget.data('code'));
        // TODO: Escape values... (should use a POST instead as well, shouldn't we?)
        const url = '../api/tool/eval?target=' + id + '&lang=' + lang + '&code=' + code;
        fetch(url, { credentials: 'same-origin' })
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
                    emlc.footpaneExpand();
                    emlc.footpaneText(JSON.stringify(json, null, 3));
                }
                catch (err) {
                    emlc.footpaneExpand();
                    emlc.footpaneError(resp);
                }
            })
            .catch(function(err) {
                // TODO: Proper error reporting...
                alert('ERROR: ' + err);
                console.log(arguments);
                emlc.footpaneExpand();
                emlc.footpaneError(err);
            });
    }

})();

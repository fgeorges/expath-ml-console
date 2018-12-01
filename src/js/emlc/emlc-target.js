"use strict";

$(document).ready(function () {

    // make the target text field (displaying the selected target) read-only
    $('.emlc-target-field').on('keydown paste', function(e) {
        e.preventDefault();
    });

    // make each entry in the dorpdown lists udpate the target field, on selection
    $('.emlc-target-entry').on('click', function(e) {
        e.preventDefault();
	var a     = $(this);
	var field = a.data('field');
	var label = a.data('label');
	var id    = a.data('id');
	$(field + ' input:text'  ).val(label);
	$(field + ' input:hidden').val(id);
    });

});

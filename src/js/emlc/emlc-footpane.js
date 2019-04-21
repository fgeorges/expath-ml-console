"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

    $(function() {
        init();
        colapse();
    });

    function height(elem) {
        return $(elem)[0].getBoundingClientRect().height;
    }

    function init() {
        // the "top" of ".result" must be the height of ".header"
        $('#footbody').css('top', height($('#footline')));
    };

    function colapse() {
        $('#footline').on('click', expand);
        $('#footline').css('cursor', 'pointer');
        $('#footpane').css('height', height($('#footline')));
        $('#main').css('margin-bottom', height($('#footpane')) + 'px');
    };

    function expand() {
        // TODO: Enable sliding the header as well, to change the footpane "height".
        $('#footline').on('click', colapse);
        $('#footline').css('cursor', 'ns-resize');
        $('#footpane').css('height', ($(window).height() / 2) + 'px');
        $('#main').css('margin-bottom', height($('#footpane')) + 'px');
    };

})();

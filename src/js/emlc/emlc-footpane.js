"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

    emlc.footpaneColapse = colapse;
    emlc.footpaneExpand  = expand;
    emlc.footpaneText    = text;
    emlc.footpaneError   = error;

    $(function() {
        init();
        colapse();
    });

    function height(elem) {
        return $(elem)[0].getBoundingClientRect().height;
    }

    function init() {
        // the "top" of ".result" must be the height of ".header"
        $('#footbody').css('top', height($('#footline')) + 10);
    };

    function colapse() {
        $('#footline').on('click', expand);
        $('#footline').css('cursor', 'pointer');
        $('#footpane').css('height', height($('#footline')));
        $('#main').css('margin-bottom', height($('#footpane')));
    };

    function expand() {
        // TODO: Enable sliding the header as well, to change the footpane "height".
        $('#footline').on('click', colapse);
        $('#footline').css('cursor', 'ns-resize');
        $('#footpane').css('height', ($(window).height() / 2) + 'px');
        $('#main').css('margin-bottom', height($('#footpane')));
    };

    function purge() {
        $('#footbody pre').remove();
    };

    function add(content) {
        const pre  = $('<pre>');
        const code = $('<code>');
        pre.append(code);
        code.text(content);
        $('#footbody').append(pre);
        return pre;
    };

    function text(content) {
        purge();
        return add(content);
    };

    function error(content) {
        purge();
        return add(content).css('color', 'red');
    };

})();

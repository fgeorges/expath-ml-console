"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {};

(function() {

    emlc.footpaneColapse = colapse;
    emlc.footpaneExpand  = expand;
    emlc.footpanePurge   = purge;
    emlc.footpaneAdd     = add;
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

    // TODO: xs:anyURI and sem:iri would result in links to the browsers (resp.
    // the document and triple browsers.)  The database to use is the one used
    // to evaluate the code...
    function add(text, type) {
        const pre  = $('<pre>');
        const span = $('<span>');
        const code = $('<code>');
        pre.append(span);
        pre.append(code);
        span.text(type);
        code.text(text);
        $('#footbody').append(pre);
        return pre;
    };

    function error(content) {
        return add(content).css('color', 'red');
    };

})();

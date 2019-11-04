"use strict";

// ensure the emlc global var
window.emlc = window.emlc || {debug: {}};

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
        $('#footline')
            .on('click', toggle)
            .css('cursor', 'pointer');
        $('#footline span:first')
            .on('click', colapse)
            .css('cursor', 'pointer');
        $('#footline span:last')
            .on('click', full)
            .css('cursor', 'pointer');
        $(window).on('resize', function() {
            const max  = $(window).height();
            if ( height($('#footpane')) > max ) {
                $('#footpane').css('height', max + 'px');
            }
        });
    };

    function toggle(event) {
        event && event.stopPropagation();
        if ( $('#footpane').data('colapsed') === 'colapsed' ) {
            resize(($(window).height() / 2) + 'px', 'half', 'ns-resize');
        }
        else {
            resize(height($('#footline')), 'colapsed', 'pointer');
        }
    };

    function colapse(event) {
        event && event.stopPropagation();
        if ( $('#footpane').data('colapsed') !== 'colapsed' ) {
            resize(height($('#footline')), 'colapsed', 'pointer');
        }
    };

    function expand(event) {
        event && event.stopPropagation();
        if ( $('#footpane').data('colapsed') !== 'expanded' ) {
            resize(($(window).height() / 2) + 'px', 'expanded', 'ns-resize');
        }
    };

    function full(event) {
        event && event.stopPropagation();
        if ( $('#footpane').data('colapsed') !== 'full' ) {
            resize(($(window).height()) + 'px', 'full', 'ns-resize');
        }
    };

    function resize(height, colapsed, cursor) {
        $('#footline').css('cursor', cursor);
        $('#footpane').css('height', height).data('colapsed', colapsed);
        $('#main').css('margin-bottom', height);
    };

    function purge() {
        $('#footbody pre').remove();
    };

    // TODO: xs:anyURI and sem:iri would result in links to the browsers (resp.
    // the document and triple browsers.)  The database to use is the one used
    // to evaluate the code...
    function add(text, type, dbname) {
        const pre  = $('<pre>');
        const span = $('<span>');
        const code = $('<code>');
        span.text(type);
        pre.append(span);
        if ( typeof text === 'object' ) {
            code.text(JSON.stringify(text, null, 3));
            pre.append(code);
        }
        else if ( type === 'xs:anyURI' ) {
            const a = $('<a>').attr('href', `../db/${dbname}/doc?uri=${encodeURIComponent(text)}`);
            code.text(text).addClass('doc');
            a.append(code);
            pre.append(a);
        }
        else if ( type === 'sem:iri' ) {
            const a = $('<a>').attr('href', `../db/${dbname}/triples?rsrc=${encodeURIComponent(text)}`);
            code.text(text).addClass('rsrc');
            a.append(code);
            pre.append(a);
        }
        else {
            code.text(text);
            pre.append(code);
        }
        $('#footbody').append(pre);
        return pre;
    };

    function error(content) {
        return add(content).css('color', 'red');
    };

})();

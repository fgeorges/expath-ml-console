xquery version "3.0";

(:~
 : Library to help generating the view.
 :)
module namespace v = "http://expath.org/ns/ml/console/view";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "config.xql";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $v:pages as element(pages) :=
   <pages>
      <page name="home"     title="Console Home"                 label="Home"     href="."/>
      <page name="pkg"      title="Packages"                     label="Packages"/>
      <page name="web"      title="Web Applications Containers"  label="Web"/>
      <!--page name="cxan"     title="CXAN Config"                  label="CXAN"/>
      <page name="xproject" title="XProject Tools"               label="XProject"/>
      <page name="xspec"    title="XSpec Tools"                  label="XSpec"/-->
      <page name="tools"    title="Goodies for MarkLogic"        label="Tools"/>
      <page name="help"     title="Console Help"                 label="Help"/>
      <!--page name="devel"    title="Devel's evil"                 label="Devel"/-->
   </pages>;

(:~
 : Redirect to `$url`, using a 302 HTTP status code.
 :
 : Note: I am not a fan of using side-effect functions like this.  The user
 : should be able to return a different status code and message than "200 OK"
 : on the view itself.
 :)
declare function v:redirect($url as xs:string)
   as empty-sequence()
{
   xdmp:set-response-code(302, 'Found'),
   xdmp:add-response-header('Location', $url)
};

(:~
 : Format the top-level menu of a console page.
 :
 : $page: the current page (must be the key of one menu)
 : $root: '' if a top-level page, or '../' if in a sub-directory
 :)
declare function v:console-page-menu($page as xs:string, $root as xs:string)
   as element(h:li)+
{
   for $p in $v:pages/page
   return
      <li xmlns="http://www.w3.org/1999/xhtml"> {
         attribute { 'class' } { 'current' }[$p/@name eq $page],
         <a class="stip" href="{ $root }{ $p/(@href, @name)[1] }" title="{ $p/@title }"> {
            $p/fn:string(@label)
         }
         </a>
      }
      </li>
};

declare variable $serial-options :=
   <options xmlns="xdmp:quote">
      <indent-untyped>yes</indent-untyped>
   </options>;

(:~
 : Format a `pre` element containing some XML.
 :
 : $elem: the element to serialize and display in a `pre` (with syntax highlighted)
 : $id: a unique ID to be used on the `pre` element
 :)
declare function v:display-xml(
   $elem as element()?,
   $id   as xs:string
) as element(h:pre)
{
   let $serialized := xdmp:quote($elem, $serial-options)
   let $lines      := fn:count(fn:tokenize($serialized, '&#10;'))
   return
      <pre id="{ $id }" style="height: { $lines * 12 - 4 }pt" xmlns="http://www.w3.org/1999/xhtml">
         <code class="language-xml"> {
            $serialized
         }
         </code>
      </pre>
};

(:~
 : Format a console page.
 :
 : $page: the current page (must be the key of one menu)
 : $title: the title of the page (to appear on top of the page)
 : $root: '' if a top-level page, or '../' if in a sub-directory
 : $content: the actual HTML content, pasted as the content of the page
 :
 : TODO: Shouldn't it set the response MIME type and HTTP code?
 :)
declare function v:console-page(
   $root    as xs:string,
   $page    as xs:string,
   $title   as xs:string,
   $content as function() as element()+
) as element(h:html)
{
   let $c := v:eval-content($content)
   return
      v:console-page-static(
         $root,
         $page,
         $title,
         $c)
};

(:~
 : Eval content, protecting from exceptions.
 :
 : The return value is the result of calling `$content`.  In case it throws an
 : error, this function returns HTML elements describing the error instead, to
 : be displayed to the user.
 :
 : FIXME: In order to be sure the transaction is rolled back in case of failure,
 : do NOT use try/catch here.  Move the error handling to the error handler
 : module, set on the appserver.
 :)
declare %private function v:eval-content(
   $content as function() as element()+
) as element()+
{
   try {
      $content()
   }
   catch c:* {
      <p><b>Error</b>: { $err:description }</p>
   }
   catch * {
      <p><b>SYSTEM ERROR</b> (please report this to the mailing list): { $err:description }</p>,
      v:display-xml($err:additional, 'error')
   }
};

(:~
 : Inject the content into the overall page structure of the console.
 :)
declare %private function v:console-page-static(
   $root    as xs:string,
   $page    as xs:string,
   $title   as xs:string,
   $content as element()+
) as element(h:html)
{
   <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
         <link rel="stylesheet" type="text/css" media="screen" href="{ $root }style/screen.css"/>
         <link rel="shortcut icon" type="image/png" href="{ $root }images/expath-icon.png"/>
         {
            v:add-header-extra($root, $content)
         }
         <title>{ $title }</title>
      </head>
      <body>
         <div id="container">
            <div id="header">
               <header>
                  <h1>
                     <a href="/">EXPath Console</a>
                  </h1>
                  <nav>
                     <ul> {
                        v:console-page-menu($page, $root)
                     }
                     </ul>
                  </nav>
               </header>
            </div>
            <div id="header-bottom-bar"/>
            <div id="content">
               <h1>{ $title }</h1>
               {
                  $content
               }
            </div>
         </div>
         {
            v:add-footer-extra($root, $content)
         }
      </body>
   </html>
};

(:~
 : Generate extra elements to be injected in the head, to support sorttable.
 :
 : TODO: Add specific CSS for jQuery File Upload?
 :)
declare %private function v:add-header-extra(
   $root    as xs:string,
   $content as element()+
) as element(h:script)*
{
   (: TODO: The test "@class eq '...'" is not perfect, as a class attribute
      can contain several classes, but for now it is OK, as all usages in
      the code base use exactly class="sortable". :)
   if ( fn:exists($content/descendant-or-self::h:table[@class eq 'sortable']) ) then (
      <script src="{ $root }js/sorttable.js" xmlns="http://www.w3.org/1999/xhtml"/>
   )
   else (
   )
   ,
   if ( fn:exists($content/descendant-or-self::h:*[@id eq 'fileupload']) ) then (
      <script src="{ $root }js/dropzone.js" xmlns="http://www.w3.org/1999/xhtml"/>
   )
   else (
   )
};

(:~
 : Generate extra elements to be injected at the end of the body.
 :
 : The extra elements are to support ACE code editors and jQuery File Upload.
 :)
declare %private function v:add-footer-extra(
   $root    as xs:string,
   $content as element()+
) as element(h:script)*
{
   let $codes  := $content/descendant-or-self::h:pre[fn:starts-with(h:code/@class, 'language-')]
   let $upload := $content/descendant-or-self::h:*[@id eq 'fileupload']
   return (
      if ( fn:exists($codes) ) then (
         <script src="{ $root }js/ace/ace.js" type="text/javascript" charset="utf-8"
                 xmlns="http://www.w3.org/1999/xhtml"/>,
         for $c at $pos in $codes
         let $var  := 'ace_editor_' || $pos
         let $id   := xs:string($c/@id)
         let $lang := fn:substring-after($c/h:code/@class, 'language-')
         return
            <script xmlns="http://www.w3.org/1999/xhtml">
                var { $var } = ace.edit("{ $id }");
                { $var }.setReadOnly(true);
                { $var }.setTheme("ace/theme/clouds");
                { $var }.getSession().setMode("ace/mode/{ $lang }");
            </script>
      )
      else (
      )
      ,
      if ( fn:exists($upload) ) then
         <wrapper xmlns="http://www.w3.org/1999/xhtml">
            <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"/>
            <script src="{ $root }js/file-upload/jquery.ui.widget.js"/>
            <script src="{ $root }js/file-upload/jquery.iframe-transport.js"/>
            <script src="{ $root }js/file-upload/jquery.fileupload.js"/>
            <script src="{ $root }js/file-upload/jquery.fileupload-ui.js"/>

<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
<!-- The jQuery UI widget factory, can be omitted if jQuery UI is already included -->
<script src="//blueimp.github.io/jQuery-File-Upload/js/vendor/jquery.ui.widget.js"></script>
<!-- The Load Image plugin is included for the preview images and image resizing functionality -->
<script src="//blueimp.github.io/JavaScript-Load-Image/js/load-image.all.min.js"></script>
<!-- The Canvas to Blob plugin is included for image resizing functionality -->
<script src="//blueimp.github.io/JavaScript-Canvas-to-Blob/js/canvas-to-blob.min.js"></script>
<!-- Bootstrap JS is not required, but included for the responsive demo navigation -->
<script src="//netdna.bootstrapcdn.com/bootstrap/3.2.0/js/bootstrap.min.js"></script>
<!-- The Iframe Transport is required for browsers without support for XHR file uploads -->
<script src="//blueimp.github.io/jQuery-File-Upload/js/jquery.iframe-transport.js"></script>
<!-- The basic File Upload plugin -->
<script src="//blueimp.github.io/jQuery-File-Upload/js/jquery.fileupload.js"></script>
<!-- The File Upload processing plugin -->
<script src="//blueimp.github.io/jQuery-File-Upload/js/jquery.fileupload-process.js"></script>
<!-- The File Upload image preview & resize plugin -->
<script src="//blueimp.github.io/jQuery-File-Upload/js/jquery.fileupload-image.js"></script>
<!-- The File Upload audio preview plugin -->
<script src="//blueimp.github.io/jQuery-File-Upload/js/jquery.fileupload-audio.js"></script>
<!-- The File Upload video preview plugin -->
<script src="//blueimp.github.io/jQuery-File-Upload/js/jquery.fileupload-video.js"></script>
<!-- The File Upload validation plugin -->
<script src="//blueimp.github.io/jQuery-File-Upload/js/jquery.fileupload-validate.js"></script>

            <!--script>
            $(function () {{
                $('#fileupload').fileupload({{
                    dataType: 'json',
                    url: $('#fileupload').fileupload('option', 'url'),
                    done: function (e, data) {{
                        $.each(data.result.files, function (index, file) {{
                            $('<p/>').text(file.name).appendTo(document.body);
                        }});
                    }}
                }});
            }});
            </script-->
            <script>
<![CDATA[
$(function () {
    'use strict';
    // Change this to the location of your server-side upload handler:
    var url = window.location.hostname === 'blueimp.github.io' ?
                '//jquery-file-upload.appspot.com/' : 'doc-upload',
        uploadButton = $('<button/>')
            .addClass('btn btn-primary')
            .prop('disabled', true)
            .text('Processing...')
            .on('click', function () {
                var $this = $(this),
                    data = $this.data();
                $this
                    .off('click')
                    .text('Abort')
                    .on('click', function () {
                        $this.remove();
                        data.abort();
                    });
                data.submit().always(function () {
                    $this.remove();
                });
            });
    $('#fileupload').fileupload({
        url: url,
        dataType: 'json',
        autoUpload: false,
        acceptFileTypes: /(\.|\/)(gif|jpe?g|png)$/i,
        maxFileSize: 5000000, // 5 MB
        // Enable image resizing, except for Android and Opera,
        // which actually support image resizing, but fail to
        // send Blob objects via XHR requests:
        disableImageResize: /Android(?!.*Chrome)|Opera/
            .test(window.navigator.userAgent),
        previewMaxWidth: 100,
        previewMaxHeight: 100,
        previewCrop: true
    }).on('fileuploadadd', function (e, data) {
        data.context = $('<div/>').appendTo('#files');
        $.each(data.files, function (index, file) {
            var node = $('<p/>')
                    .append($('<span/>').text(file.name));
            if (!index) {
                node
                    .append('<br>')
                    .append(uploadButton.clone(true).data(data));
            }
            node.appendTo(data.context);
        });
    }).on('fileuploadprocessalways', function (e, data) {
        var index = data.index,
            file = data.files[index],
            node = $(data.context.children()[index]);
        if (file.preview) {
            node
                .prepend('<br>')
                .prepend(file.preview);
        }
        if (file.error) {
            node
                .append('<br>')
                .append($('<span class="text-danger"/>').text(file.error));
        }
        if (index + 1 === data.files.length) {
            data.context.find('button')
                .text('Upload')
                .prop('disabled', !!data.files.error);
        }
    }).on('fileuploadprogressall', function (e, data) {
        var progress = parseInt(data.loaded / data.total * 100, 10);
        $('#progress .progress-bar').css(
            'width',
            progress + '%'
        );
    }).on('fileuploaddone', function (e, data) {
        $.each(data.result.files, function (index, file) {
            if (file.url) {
                var link = $('<a>')
                    .attr('target', '_blank')
                    .prop('href', file.url);
                $(data.context.children()[index])
                    .wrap(link);
            } else if (file.error) {
                var error = $('<span class="text-danger"/>').text(file.error);
                $(data.context.children()[index])
                    .append('<br>')
                    .append(error);
            }
        });
    }).on('fileuploadfail', function (e, data) {
        $.each(data.files, function (index) {
            var error = $('<span class="text-danger"/>').text('File upload failed.');
            $(data.context.children()[index])
                .append('<br>')
                .append(error);
        });
    }).prop('disabled', !$.support.fileInput)
        .parent().addClass($.support.fileInput ? undefined : 'disabled');
});
]]>
            </script>
         </wrapper>/*
      else
         ()
   )
};

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
 :)
declare function v:display-xml(
   $elem as element()
) as element(h:pre)
{
   v:ace-editor-xml($elem, 'code', (), (), (), ())
};

(:~
 : Format a `pre` element containing some XML, and turn it into an editor.
 :
 : $elem: the element to serialize and display in the editor
 : $uri: the URI (in the database) of the document being edited
 : $endpoint: the endpoint on MarkLogic to save the document (must accept POST
 :     requests, with a field "uri" for the doc URI and "doc" for the content)
 :)
declare function v:edit-xml(
   $elem     as element(),
   $id       as xs:string,
   $uri      as xs:string,
   $endpoint as xs:string
) as element(h:pre)
{
   v:ace-editor-xml($elem, 'editor', $id, $uri, $endpoint, '250pt')
};

(:~
 : Common implementation of `v:display-xml()` and `v:edit-xml()`.
 :)
declare %private function v:ace-editor-xml(
   $elem     as element(),
   $class    as xs:string,
   $id       as xs:string?,
   $uri      as xs:string?,
   $endpoint as xs:string?,
   $height   as xs:string?
) as element(h:pre)
{
   let $serialized := xdmp:quote($elem, $serial-options)
   let $lines      := fn:count(fn:tokenize($serialized, '&#10;'))
   return
      <pre xmlns="http://www.w3.org/1999/xhtml"
           class="{ $class }"
           ace-mode="ace/mode/xml"
           ace-theme="ace/theme/pastel_on_dark"
           ace-gutter="true">
      {
         attribute { 'id'           } { $id }[fn:exists($id)],
         attribute { 'ace-uri'      } { $uri }[fn:exists($uri)],
         attribute { 'ace-endpoint' } { $endpoint }[fn:exists($endpoint)],
         attribute { 'style'        } { 'height: ' || $height }[fn:exists($height)],
         $serialized
      }
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
   let $c     := v:eval-content($content)
   let $pres  := $c/descendant-or-self::h:pre
   let $codes := $pres[fn:tokenize(@class, '\s+') = ('code', 'editor')]
   return
      v:console-page-static(
         $root,
         $page,
         $title,
         $c,
         fn:exists($codes))
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
      v:display-xml($err:additional)
   }
};

(:~
 : Inject the content into the overall page structure of the console.
 :)
declare %private function v:console-page-static(
   $root    as xs:string,
   $page    as xs:string,
   $title   as xs:string,
   $content as element()+,
   $codes   as xs:boolean
) as element(h:html)
{
   <html xmlns="http://www.w3.org/1999/xhtml">
      <head>
         <link rel="stylesheet" type="text/css" media="screen" href="{ $root }style/screen.css"/>
         <link rel="shortcut icon" type="image/png" href="{ $root }images/expath-icon.png"/>
         <!-- TODO: Is there any table on this page...? -->
         <script src="{ $root }js/sorttable.js"/>
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
            if ( $codes ) then (
               <script src="{ $root }js/jquery.js"  type="text/javascript"/>,
               <script src="{ $root }js/ace/ace.js" type="text/javascript" charset="utf-8"/>,
               <script src="{ $root }js/ace/ext-static_highlight.js" type="text/javascript"/>,
               <script type="text/javascript">

                  var high = ace.require("ace/ext/static_highlight");
                  var dom = ace.require("ace/lib/dom");

                  // TODO: Replace by jQuery?
                  function qsa(sel) {{
                     return Array.apply(null, document.querySelectorAll(sel));
                  }}

                  qsa(".code").forEach(function (code) {{
                     high(
                        code,
                        {{
                           mode: code.getAttribute("ace-mode"),
                           theme: code.getAttribute("ace-theme"),
                           startLineNumber: 1,
                           showGutter: code.getAttribute("ace-gutter"),
                           trim: false
                        }},
                        function (highlighted) {{
                        }});
                  }});

                  // contains all editors on the page, by ID
                  var editors = {{}};

                  qsa(".editor").forEach(function (edElm) {{
                     var e = {{}};
                     e.id       = edElm.getAttribute("id");
                     e.uri      = edElm.getAttribute("ace-uri");
                     e.endpoint = edElm.getAttribute("ace-endpoint");
                     e.theme    = edElm.getAttribute("ace-theme");
                     e.mode     = edElm.getAttribute("ace-mode");
                     e.editor   = ace.edit(edElm);
                     e.editor.setTheme(e.theme);
                     e.editor.getSession().setMode(e.mode);
                     editors[e.id] = e;
                  }});

                  function saveDoc(id)
                  {{
                     // get the ACE doc
                     var info = editors[id];
                     var session = info.editor.getSession();
                     var doc = session.getDocument();
                     // the request content
                     var fd = new FormData();
                     fd.append("doc", doc.getValue());
                     fd.append("uri", info.uri);
                     // the request itself
                     $.ajax({{
                        url: info.endpoint,
                        method: "POST",
                        data: fd,
                        dataType: "text",
                        processData: false,
                        contentType: false,
                        success: function(data) {{
                           alert("Success: " + data);
                        }},
                        error: function(xhr, status, error) {{
                           alert("Error: " + status + " (" + error + ")\n\nSee logs for details.");
                        }}}});
                  }};
               </script>
            )
            else
               ()
         }
      </body>
   </html>
};

xquery version "3.0";

(:~
 : Library to help generating the view.
 :)
module namespace v = "http://expath.org/ns/ml/console/view";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "config.xql";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $v:pages as element(pages) :=
   <pages>
      <page name="pkg"      title="Packages"                      label="Packages"/>
      <!--page name="web"      title="Web Applications Containers"   label="Web"/>
      <page name="cxan"     title="CXAN Config"                   label="CXAN"/>
      <page name="xproject" title="XProject Tools"                label="XProject"/>
      <page name="xspec"    title="XSpec Tools"                   label="XSpec"/-->
      <page name="browser"  title="Documents and triples browser" label="Browser"/>
      <page name="loader"   title="The document manager"          label="Loader"/>
      <page name="profiler" title="XQuery Profiler"               label="Profiler"/>
      <page name="tools"    title="Goodies for MarkLogic"         label="Tools"/>
      <page name="help"     title="Console Help"                  label="Help"/>
      <!--page name="devel"    title="Devel's evil"                  label="Devel"/-->
   </pages>;

declare variable $v:semantic-prefixes :=
   <declarations>
      <decl prefix="dc">http://purl.org/dc/terms/</decl>
      <decl prefix="doap">http://usefulinc.com/ns/doap#</decl>
      <decl prefix="foaf">http://xmlns.com/foaf/0.1/</decl>
      <decl prefix="frbr">http://purl.org/vocab/frbr/core</decl>
      <decl prefix="org">http://www.w3.org/ns/org#</decl>
      <decl prefix="owl">http://www.w3.org/2002/07/owl#</decl>
      <decl prefix="time">http://www.w3.org/2006/time#</decl>
      <decl prefix="prov">http://www.w3.org/ns/prov#</decl>
      <decl prefix="rdf">http://www.w3.org/1999/02/22-rdf-syntax-ns#</decl>
      <decl prefix="rdfs">http://www.w3.org/2000/01/rdf-schema#</decl>
      <decl prefix="skos">http://www.w3.org/2004/02/skos/core#</decl>
      <decl prefix="vcard">http://www.w3.org/2006/vcard/ns#</decl>
      <decl prefix="xsd">http://www.w3.org/2001/XMLSchema#</decl>
   </declarations>;

(: ==== Generic view tools ======================================================== :)

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
         attribute { 'class' } { 'active' }[$p/@name eq $page],
         <a href="{ $root }{ $p/(@href, @name)[1] }" title="{ $p/@title }"> {
            $p/fn:string(@label)
         }
         </a>
      }
      </li>
};

(:~
 : Format a console page.
 :
 : $page: the current page (must be the key of one menu)
 : $title: the title of the page (to appear on top of the page)
 : $root: '' if a top-level page, or '../' if in a sub-directory
 : $content: the actual HTML content, pasted as the content of the page
 :)
declare function v:console-page(
   $root    as xs:string,
   $page    as xs:string,
   $title   as xs:string,
   $content as function() as element()+
) as element(h:html)
{
   v:console-page($root, $page, $title, $content, ())
};

(:~
 : Format a console page.
 :
 : $page: the current page (must be the key of one menu)
 : $title: the title of the page (to appear on top of the page)
 : $root: '' if a top-level page, or '../' if in a sub-directory
 : $content: the actual HTML content, pasted as the content of the page
 : $scripts: extra HTML "script" elements, to be added at the very end
 :
 : TODO: Shouldn't it set the response MIME type and HTTP code?
 :)
declare function v:console-page(
   $root    as xs:string,
   $page    as xs:string,
   $title   as xs:string,
   $content as function() as element()+,
   $scripts as element(h:script)*
) as element(h:html)
{
   let $cnt   := v:eval-content($content)
   let $pres  := $cnt/descendant-or-self::h:pre
   let $codes := $pres[fn:tokenize(@class, '\s+') = ('code', 'editor')]
   return
      v:console-page-static(
         $root,
         $page,
         $title,
         $cnt,
         $scripts,
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
   $scripts as element(h:script)*,
   $codes   as xs:boolean
) as element(h:html)
{
   <html lang="en" xmlns="http://www.w3.org/1999/xhtml">
      <head>
         <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
         <meta name="viewport" content="width=device-width, initial-scale=1"/>
         <meta name="ml.time"  content="{ xdmp:elapsed-time() }"/>
         <title>{ $title }</title>
         {
            v:import-css($root || 'style/', (
               'bootstrap.css',
               'expath-theme.css'
            )),
            v:import-css($root || 'js/', (
               'datatables-1.10.10/css/dataTables.bootstrap.css',
               'file-upload-9.11.2/jquery.fileupload.css',
               'file-upload-9.11.2/jquery.fileupload-ui.css',
               'gallery-2.16.0/blueimp-gallery.min.css'
            ))
         }
         <link href="{ $root }images/expath-icon.png" rel="shortcut icon" type="image/png"/>
      </head>
      <body>
         <nav class="navbar navbar-inverse navbar-fixed-top">
            <div class="container">
               <div class="navbar-header">
                  <button type="button" class="navbar-toggle collapsed" data-toggle="collapse"
                          data-target="#navbar" aria-expanded="false" aria-controls="navbar">
                     <span class="sr-only">Toggle navigation</span>
                     <span class="icon-bar"/>
                     <span class="icon-bar"/>
                     <span class="icon-bar"/>
                  </button>
                  <a class="navbar-brand" href="/">EXPath Console</a>
               </div>
               <div id="navbar" class="navbar-collapse collapse">
                  <ul class="nav navbar-nav"> {
                     v:console-page-menu($page, $root)
                  }
                  </ul>
                  <p class="navbar-text navbar-right">User: { xdmp:get-current-user() }</p>
               </div>
            </div>
         </nav>
         <div class="container theme-showcase" role="main">
         {
            <h1>{ $title }</h1>[fn:empty($content[@class = 'jumbotron'])],
            $content
         }
         </div>
         {
            v:import-javascript($root || 'js/', (
               'jquery.js',
               'bootstrap.js',
               'ace/ace.js',
               'ace/ext-static_highlight.js',
               'datatables-1.10.10/js/jquery.dataTables.js',
               'datatables-1.10.10/js/dataTables.bootstrap.js',
               'file-upload-9.11.2/vendor/jquery.ui.widget.js',
               'templates-2.5.5/tmpl.min.js',
               'load-image-1.14.0/load-image.all.min.js',
               'canvas-to-blob-2.2.0/canvas-to-blob.min.js',
               'gallery-2.16.0/jquery.blueimp-gallery.min.js',
               'file-upload-9.11.2/jquery.iframe-transport.js',
               'file-upload-9.11.2/jquery.fileupload.js',
               'file-upload-9.11.2/jquery.fileupload-process.js',
               'file-upload-9.11.2/jquery.fileupload-image.js',
               'file-upload-9.11.2/jquery.fileupload-audio.js',
               'file-upload-9.11.2/jquery.fileupload-video.js',
               'file-upload-9.11.2/jquery.fileupload-validate.js',
               'file-upload-9.11.2/jquery.fileupload-ui.js',
               'expath-console.js'
            )),
            $scripts
         }
      </body>
   </html>
};

declare function v:import-javascript($root as xs:string, $paths as xs:string+)
   as element(h:script)+
{
   $paths ! <script xmlns="http://www.w3.org/1999/xhtml"
                    type="text/javascript"
                    src="{ $root }{ . }"/>
};

declare function v:import-css($root as xs:string, $paths as xs:string+)
   as element(h:link)+
{
   $paths ! <link xmlns="http://www.w3.org/1999/xhtml"
                  rel="stylesheet"
                  type="text/css"
                  href="{ $root }{ . }"/>
};

(: ==== ACE editor tools ======================================================== :)

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
   $elem as node()
) as element(h:pre)
{
   v:ace-editor-xml($elem, 'code', 'xml', (), (), (), ())
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
   $elem as node(),
   $id   as xs:string,
   $uri  as xs:string,
   $top  as xs:string
) as element()+
{
   v:ace-editor-xml($elem, 'editor', 'xml', $id, $uri, $top, '250pt'),
   <button class="btn btn-default" onclick='saveDoc("{ $id }", "doc");'>Save</button>,
   <button class="btn btn-danger pull-right" onclick='deleteDoc("{ $id }");'>Delete</button>,
   <form method="POST" action="{ $top }delete" style="display: none" id="{ $id }-delete">
      <input type="hidden" name="doc"        value="{ $uri }"/>
      <input type="hidden" name="back-label" value="the directory"/>
      <input type="hidden" name="back-url"   value="browse{
         '/'[fn:not(fn:starts-with($uri, '/'))]
      }{
         fn:string-join(fn:tokenize($uri, '/')[fn:position() lt fn:last()], '/')
      }/"/>
   </form>
};

(:~
 : Like v:edit-xml(), but for text.  $mode is an ACE mode, e.g. "xquery".
 :
 : For editing "detached" text (not attached to a document in the database, so
 : without any URI).
 :)
declare function v:edit-text(
   $elem as text(),
   $mode as xs:string,
   $id   as xs:string
) as element(h:pre)
{
   v:ace-editor-xml($elem, 'editor', $mode, $id, (), (), '250pt')
};

(:~
 : Like v:edit-xml(), but for text.  $mode is an ACE mode, e.g. "xquery".
 :
 : For editing "detached" text (not attached to a document in the database, so
 : without any URI).
 :)
declare function v:edit-text(
   $elem as text(),
   $mode as xs:string,
   $id   as xs:string,
   $top  as xs:string
) as element(h:pre)
{
   v:ace-editor-xml($elem, 'editor', $mode, $id, (), $top, '250pt')
};

(:~
 : Like v:edit-xml(), but for text.  $mode is an ACE mode, e.g. "xquery".
 :
 : For editing "attached" text (attached to a document in the database, so with
 : a URI).
 :)
declare function v:edit-text(
   $elem as text(),
   $mode as xs:string,
   $id   as xs:string,
   $uri  as xs:string,
   $top  as xs:string
) as element()+
{
   v:ace-editor-xml($elem, 'editor', $mode, $id, $uri, $top, '250pt'),
   <button class="btn btn-default" onclick='saveDoc("{ $id }", "text");'>Save</button>,
   <button class="btn btn-danger pull-right" onclick='deleteDoc("{ $id }");'>Delete</button>,
   <form method="POST" action="{ $top }delete" style="display: none" id="{ $id }-delete">
      <input type="hidden" name="doc"        value="{ $uri }"/>
      <input type="hidden" name="back-label" value="the directory"/>
      <input type="hidden" name="back-url"   value="browse{
         '/'[fn:not(fn:starts-with($uri, '/'))]
      }{
         fn:string-join(fn:tokenize($uri, '/')[fn:position() lt fn:last()], '/')
      }/"/>
   </form>
};

(:~
 : Common implementation of `v:display-xml()` and `v:edit-xml()`.
 :)
declare %private function v:ace-editor-xml(
   $node     as node(),
   $class    as xs:string,
   $mode     as xs:string,
   $id       as xs:string?,
   $uri      as xs:string?,
   $top      as xs:string?,
   $height   as xs:string?
) as element(h:pre)
{
   <pre xmlns="http://www.w3.org/1999/xhtml"
        class="{ $class }"
        ace-mode="ace/mode/{ $mode }"
        ace-theme="ace/theme/pastel_on_dark"
        ace-gutter="true">
   {
      attribute { 'id'         } { $id }[fn:exists($id)],
      attribute { 'ace-uri'    } { $uri }[fn:exists($uri)],
      attribute { 'ace-top'    } { $top }[fn:exists($top)],
      attribute { 'style'      } { 'height: ' || $height }[fn:exists($height)],
      xdmp:quote($node, $serial-options)
   }
   </pre>
};

(: ==== Form tools ======================================================== :)

declare function v:form($action as xs:string, $content as element()+)
   as element(h:form)
{
   v:form($action, (), $content)
};

declare function v:form($action as xs:string, $attrs as attribute()*, $content as element()+)
   as element(h:form)
{
   let $class := attribute { 'class' } { 'form-horizontal' }[fn:empty($attrs[fn:node-name(.) eq xs:QName('class')])]
   return
      v:form-impl($action, ($attrs, $class), $content)
};

declare function v:inline-form($action as xs:string, $content as element()+)
   as element(h:form)
{
   v:inline-form($action, (), $content)
};

declare function v:inline-form($action as xs:string, $attrs as attribute()*, $content as element()+)
   as element(h:form)
{
   let $class := attribute { 'class' } { 'form-inline'  }[fn:empty($attrs[fn:node-name(.) eq xs:QName('class')])]
   let $style := attribute { 'style' } { 'height: 12pt' }[fn:empty($attrs[fn:node-name(.) eq xs:QName('style')])]
   return
      v:form-impl($action, ($attrs, $class, $style), $content)
};

declare %private function v:form-impl(
   $action  as xs:string,
   $attrs   as attribute()*,
   $content as element()+
) as element(h:form)
{
   <form xmlns="http://www.w3.org/1999/xhtml"
         method="post"
         action="{ $action }"
         enctype="multipart/form-data"> {
      $attrs,
      $content
   }
   </form>
};

declare function v:input-text($id as xs:string, $label as xs:string, $placeholder as xs:string)
   as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
      <label for="{ $id }" class="col-sm-2 control-label">{ $label }</label>
      <div class="col-sm-10">
         <input type="text" name="{ $id }" class="form-control" placeholder="{ $placeholder }"/>
      </div>
   </div>
};

declare function v:submit($label as xs:string)
   as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
      <div class="col-sm-offset-2 col-sm-10">
         <button type="submit" class="btn btn-default">{ $label }</button>
      </div>
   </div>
};

declare function v:input-select($id as xs:string, $label as xs:string, $options as element(h:option)+)
   as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
      <label for="{ $id }" class="col-sm-2 control-label">{ $label }</label>
      <div class="col-sm-10">
         <select name="{ $id }" class="form-control"> {
            $options
         }
         </select>
      </div>
   </div>
};

declare function v:input-option($val as xs:string, $label as xs:string)
   as element(h:option)
{
   <option xmlns="http://www.w3.org/1999/xhtml" value="{ $val }">{ $label }</option>
};

declare function v:input-select-databases($id as xs:string, $label as xs:string)
   as element(h:div)
{
   v:input-select-databases($id, $label, a:get-databases()/a:database)
};

declare function v:input-select-databases(
   $id    as xs:string,
   $label as xs:string,
   $dbs   as element(a:database)*
) as element(h:div)
{
   v:input-select($id, $label,
      for $db in $dbs
      order by $db/a:name
      return
         v:input-option($db/@id, $db/a:name))
};

declare function v:input-file($id as xs:string, $label as xs:string)
   as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
      <label for="{ $id }" class="col-sm-2 control-label">{ $label }</label>
      <div class="col-sm-10">
         <input type="file" name="{ $id }"/>
      </div>
   </div>
};

declare function v:input-checkbox($id as xs:string, $label as xs:string, $checked as xs:string)
   as element(h:div)
{
   <div xmlns="http://www.w3.org/1999/xhtml" class="form-group">
      <label for="{ $id }" class="col-sm-2 control-label">{ $label }</label>
      <div class="col-sm-10">
         <input type="checkbox" name="{ $id }" checked="{ $checked }"/>
      </div>
   </div>
};

declare function v:input-hidden($id as xs:string, $val as xs:string)
   as element(h:input)
{
   <input xmlns="http://www.w3.org/1999/xhtml"
          type="hidden" name="{ $id }" value="{ $val }"/>
};

(: ==== Link display tools ======================================================== :)

declare function v:doc-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'doc')
};

declare function v:coll-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'coll')
};

declare function v:dir-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'dir')
};

declare function v:rsrc-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'rsrc')
};

declare function v:class-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'class')
};

declare function v:prop-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'prop')
};

declare function v:db-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'db')
};

declare function v:as-link($href as xs:string, $name as xs:string)
{
   v:component-link($href, $name, 'as')
};

declare function v:component-link($href as xs:string, $name as xs:string, $kind as xs:string)
{
   <a href="{ $href }">
      <code class="{ $kind }">{ $name }</code>
   </a>
};

(: ==== Triple display tools ======================================================== :)

(:~
 : Shorten a resource URI, if a prefix can be found for it.
 :
 : The first entry in `$v:semantic-prefixes` that matches $uri (that is, the
 : first one for which $uri starts with the text value of) is used.  If there
 : is no such entry, the function returns the original `$uri`.
 :)
declare function v:shorten-resource($uri as xs:string)
   as xs:string
{
   let $decl := v:find-matching-prefix($uri)
   return
      if ( fn:empty($decl) ) then
         $uri
      else
         $decl/@prefix || ':' || fn:substring-after($uri, xs:string($decl))
};

(:~
 : Return the first matching prefix declaration, for a complete resource URI.
 :)
declare function v:find-matching-prefix($uri as xs:string)
   as element(decl)?
{
   v:find-matching-prefix($uri, $v:semantic-prefixes/decl)
};

(:~
 : Return the first matching prefix declaration, for a complete resource URI.
 :)
declare function v:find-matching-prefix($uri as xs:string, $decls as element(decl)*)
   as element(decl)?
{
   if ( fn:empty($decls) ) then
      ()
   else if ( fn:starts-with($uri, xs:string($decls[1])) ) then
      $decls[1]
   else
      v:find-matching-prefix($uri, fn:remove($decls, 1))
};

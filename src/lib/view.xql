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
   $content as function() as element(h:wrapper)
) as element(h:html)
{
   let $w := v:eval-content($content)
   return
      v:console-page-static(
         $root,
         $page,
         $title,
         $w,
         $w//h:pre[fn:starts-with(h:code/@class, 'language-')])
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
   $content as function() as element(h:wrapper)
) as element(h:wrapper)
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
   $content as element(h:wrapper),
   $codes   as element(h:pre)*
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
                  $content/*
               }
            </div>
         </div>
         {
            if ( fn:exists($codes) ) then (
               <script src="{ $root }js/ace/ace.js" type="text/javascript" charset="utf-8"/>,
               for $c at $pos in $codes
               let $var  := 'ace_editor_' || $pos
               let $id   := xs:string($c/@id)
               let $lang := fn:substring-after($c/h:code/@class, 'language-')
               return
                  <script>
                      var { $var } = ace.edit("{ $id }");
                      { $var }.setReadOnly(true);
                      { $var }.setTheme("ace/theme/clouds");
                      { $var }.getSession().setMode("ace/mode/{ $lang }");
                  </script>
            )
            else
               ()
         }
      </body>
   </html>
};

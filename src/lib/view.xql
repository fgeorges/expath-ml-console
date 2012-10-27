xquery version "3.0";

(:~
 : Library to help generating the view.
 :)
module namespace v = "http://expath.org/ns/ml/console/view";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "config.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace err  = "http://www.w3.org/2005/xqt-errors";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $v:pages as element(pages) :=
   <pages>
      <page name="home"     title="Console Home"                 label="Home"/>
      <page name="repo"     title="Package Repositories"         label="Repositories"/>
      <!--page name="web"      title="Web Applications Containers"  label="Web Containers"/-->
      <page name="cxan"     title="CXAN Config"                  label="CXAN"/>
      <!--page name="xproject" title="XProject Tools"            label="XProject"/>
      <page name="xspec"    title="XSpec Tools"                  label="XSpec"/-->
      <page name="tools"    title="Goodies for MarkLogic"        label="Tools"/>
      <page name="help"     title="Console Help"                 label="Help"/>
      <!--page name="devel"    title="Devel's evil"              label="Devel" right="true"/-->
   </pages>;

(:~
 : Format the top-level menu of a console page.
 :
 : $page: the current page (must be the key of one menu)
 : $root: '' if a top-level page, or '../' if in a sub-directory
 :)
declare function v:console-page-menu($page as xs:string, $root as xs:string)
   as element(li)+
{
   for $p in $v:pages/page
   return
      <li xmlns="http://www.w3.org/1999/xhtml"> {
         attribute { 'class' } { 'right' }[$p/@right/xs:boolean(.)],
         <a href="{ $root }{ $p/@name }.xq" title="{ $p/@title }"> {
            attribute { 'class' } { 'active' }[$p/@name eq $page],
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
 :
 : TODO: Shouldn't it set the response MIME type and HTTP code?
 :)
declare function v:console-page(
   $root    as xs:string,
   $page    as xs:string,
   $title   as xs:string,
   $content as function() as element()+
) as element(html)
{
   v:console-page-static(
      $root,
      $page,
      $title,
      try {
         $content()
      }
      catch c:* {
         <p><b>Error</b>: { $err:description }</p>
      }
      catch * {
         <p><b>SYSTEM ERROR</b> (please report this to the mailing list): { $err:description }</p>,
         <pre>{ xdmp:quote($err:additional) }</pre>
      })
};

declare function v:console-page-static(
   $root    as xs:string,
   $page    as xs:string,
   $title   as xs:string,
   $content as element()+
) as element(html)
{
   <html>
      <head>
         <title>{ $title }</title>
         <link rel="stylesheet" type="text/css" href="{ $root }style/default.css"/>
         <link rel="shortcut icon" type="image/png" href="{ $root }images/expath-icon.png"/>
         <script src="{ $root }js/sorttable.js"/>
      </head>
      <body>
         <div id="upbg"/>
         <div id="outer">
            <div id="header">
               <div id="headercontent">
                  <h1>EXPath Console</h1>
                  <h2>(: <i>Managing your Portable XQuery Extensions, Packages
                     and Web Applications on MarkLogic Server</i> :)</h2>
               </div>
            </div>
            <div id="menu">
               <ul> {
                  v:console-page-menu($page, $root)
               }
               </ul>
            </div>
            <div id="menubottom"/>
            <div id="content">
               <div class="normalcontent">
                  <h3><strong>{ $title }</strong></h3>
                  <div class="contentarea"> {
                     $content
                  }
                  </div>
               </div>
            </div>
         </div>
      </body>
   </html>
};

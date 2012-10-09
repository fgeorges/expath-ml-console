xquery version "1.0";

(:~
 : Library to help generating the view.
 :)
module namespace v = "http://expath.org/ns/ml/console/view";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "config.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h = "http://www.w3.org/1999/xhtml";

declare variable $v:pages as element(pages) :=
   <pages>
      <page name="home"     title="Console Home"          label="Home"/>
      <page name="repo"     title="Package Repositories"  label="Repositories"/>
      <page name="install"  title="Install Package"       label="Install"/>
      <page name="cxan"     title="Install From CXAN"     label="CXAN"/>
      <!--page name="xproject" title="XProject Tools"        label="XProject"/>
      <page name="xspec"    title="XSpec Tools"           label="XSpec"/-->
      <page name="setup"    title="Setup the Console"     label="Setup"/>
      <page name="tools"    title="Goodies for MarkLogic" label="Tools"/>
      <page name="help"     title="Console Help"          label="Help"/>
      <!--page name="devel"    title="Devel's evil"          label="Devel" right="true"/-->
   </pages>;

declare function v:console-page-menu($page as xs:string)
   as element(h:li)+
{
   for $p in $v:pages/page
   return
      <li xmlns="http://www.w3.org/1999/xhtml"> {
         attribute { 'class' } { 'right' }[$p/@right/xs:boolean(.)],
         <a href="{ $p/@name }.xq" title="{ $p/@title }"> {
            attribute { 'class' } { 'active' }[$p/@name eq $page],
            $p/fn:string(@label)
         }
         </a>
      }
      </li>
};

declare function v:check-setup($page as xs:string)
   as element(h:p)?
{
   if ( cfg:is-setup() or $page eq 'setup' ) then
      ()
   else
      <p><b>WARNING</b>: The console has not been setup, please
         <a href="setup.xq">proceed first</a>.</p>
};

(:~
 : Format a console page.
 :
 : TODO: Shouldn't it set the response MIME type and HTTP code?
 :)
declare function v:console-page($page as xs:string, $title as xs:string, $content as node()+)
   as element(h:html)
{
   <html>
      <head>
         <title>{ $title }</title>
         <link rel="stylesheet" type="text/css" href="style/default.css"/>
         <link rel="shortcut icon" type="image/png" href="images/expath-icon.png"/>
      </head>
      <body>
         <div id="upbg"/>
         <div id="outer">
            <div id="header">
               <div id="headercontent">
                  <h1>EXPath Console</h1>
                  <h2>(: <i>Managing your Portable XPath Extensions and Packages</i> :)</h2>
               </div>
            </div>
            <div id="menu">
               <ul> {
                  v:console-page-menu($page)
               }
               </ul>
            </div>
            <div id="menubottom"/>
            <div id="content">
               <div class="normalcontent">
                  <h3><strong>{ $title }</strong></h3>
                  <div class="contentarea"> {
                     v:check-setup($page),
                     $content
                  }
                  </div>
               </div>
            </div>
         </div>
      </body>
   </html>
};

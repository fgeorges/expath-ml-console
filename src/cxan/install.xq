xquery version "3.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xql";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "../lib/repo.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c     = "http://expath.org/ns/ml/console";
declare namespace err   = "http://www.w3.org/2005/xqt-errors";
declare namespace mlerr = "http://marklogic.com/xdmp/error";
declare namespace http  = "xdmp:http";
declare namespace xdmp  = "http://marklogic.com/xdmp";
declare namespace zip   = "xdmp:zip";

declare function local:page()
   as element()+
{
   (: TODO: Check the params are there, and validate them... :)
   let $repo-id := t:mandatory-field('repo')
   let $repo    := cfg:get-repo($repo-id)
   let $id      := t:optional-field('id', ())
   let $name    := t:optional-field('name', ())
   let $version := t:optional-field('version', ())
   let $site    := cfg:get-config()/c:cxan/c:site
   return (
      local:do-it($repo, $id, $name, $version, $site),
      <p>Back to the <a href="../repo/show.xq?repo={ $repo-id }">repository</a>.</p>
   )
};

declare function local:install(
   $repo as element(c:repo),
   $uri  as xs:string
) as element()+
{
   try {
      let $result   := xdmp:http-get($uri)
      let $response := $result[1]
      let $xar      := $result[2]
      let $code     := $response/xs:integer(http:code)
      return
         if ( $code eq 404 ) then
            <p><b>Error</b>: There is no package at { $uri }.</p>
         else if ( $code eq 200 ) then
            if ( r:install-package($xar, $repo) ) then
               <p>Package succesfully installed from { $uri } into { $repo/fn:string(@id) }.</p>
            else
               <p><b>Error</b>: Unknown error installing the package from { $uri }.
                  Does it already exist?</p>
         else (
            <p><b>Error</b>: CXAN server did not respond 200 Ok for the package
               (at '{ $uri }'):</p>,
            <pre>{ xdmp:quote($response) }</pre>
         )
   }
   catch * {
      if ( $err:additional/mlerr:code eq 'SVC-SOCHN' ) then (
         <p><b>Error</b>: Cannot access CXAN.</p>,
         <p>System error: <em>{ $err:description }</em></p>
      )
      else
         <p><b>Error</b>: Unknown error: <em>{ $err:description }</em></p>
   }
};

declare function local:do-it(
   $repo    as element(c:repo),
   $id      as xs:string?,
   $name    as xs:string?,
   $version as xs:string?,
   $site    as xs:string?
) as element()+
{
   if ( fn:exists($id[.]) and fn:exists($name[.]) ) then
      <p><b>Error</b>: Both CXAN ID and package name provided: resp. '{ $id }'
         and '{ $name }'.</p>
   else if ( fn:empty($site[.]) ) then
      <p><b>Error</b>: The console seems to have not been set up yet, please
         <a href="setup.xq">create a repo</a> first.</p>
   else if ( fn:exists($id[.]) ) then
      local:install($repo, fn:concat($site, 'file?id=', $id, '&amp;version=', $version))
   else if ( fn:exists($name[.]) ) then
      local:install($repo, fn:concat($site, 'file?name=', $name, '&amp;version=', $version))
   else
      <p><b>Error</b>: No CXAN ID nor package name provided.</p>
};

v:console-page('../', 'cxan', 'CXAN', local:page#0)

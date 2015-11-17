xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace r = "http://expath.org/ns/ml/console/repo"  at "../lib/repo.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace err   = "http://www.w3.org/2005/xqt-errors";
declare namespace http  = "xdmp:http";
declare namespace mlerr = "http://marklogic.com/xdmp/error";
declare namespace pp    = "http://expath.org/ns/repo/packages";
declare namespace xdmp  = "http://marklogic.com/xdmp";

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   (: the app server :)
   let $id-str     := t:mandatory-field('id')
   let $id         := xs:unsignedLong($id-str)
   let $as         := a:get-appserver($id)
   (: the package (id, name and version) :)
   let $pkg-id     := t:optional-field('pkg', ())
   let $name       := t:optional-field('name', ())
   let $version    := t:optional-field('version', ())
   let $override   := xs:boolean(t:optional-field('override', 'false'))
   let $std-site   := t:optional-field('std-website', 'prod')
   let $other-site := t:optional-field('other-website', ())
   let $site       := 
         if ( fn:ends-with($other-site, '/') ) then
            $other-site
         else if ( fn:exists($other-site) ) then
            $other-site || '/'
         else if ( $std-site eq 'prod' ) then
            'http://cxan.org/'
         else if ( $std-site eq 'dev' ) then
            'http://dev.cxan.org/'
         else
            <p><b>Error</b>: Cannot decide which CXAN website to use (std-website={ $std-site }).</p>
   return (
      local:install($pkg-id, $name, $version, $site, $as, $override),
      <p>Back to { v:as-link('../' || $as/@id, $as/a:name) }</p>
   )
};

declare function local:install(
   $id       as xs:string?,
   $name     as xs:string?,
   $version  as xs:string?,
   $site     as xs:string,
   $as       as element(a:appserver),
   $override as xs:boolean
) as element()+
{
   if ( fn:exists($id[.]) and fn:exists($name[.]) ) then
      <p><b>Error</b>: Both CXAN ID and package name provided: resp. '{ $id }'
         and '{ $name }'.</p>
   else if ( fn:exists($id[.]) ) then
      local:install-from-uri(
         $site || 'file?id=' || $id || '&amp;version=' || $version,
         $as,
         $override)
   else if ( fn:exists($name[.]) ) then
      local:install-from-uri(
         $site || 'file?name=' || $name || '&amp;version=' || $version,
         $as,
         $override)
   else
      <p><b>Error</b>: No CXAN ID nor package name provided.</p>
};

declare function local:install-from-uri(
   $uri      as xs:string,
   $as       as element(a:appserver),
   $override as xs:boolean
) as element()+
{
   try {
      let $result   := xdmp:http-get($uri)
      let $response := $result[1]
      let $xar      := $result[2]
      let $code     := $response/xs:integer(http:code)
      (: TODO:... !
      let $filename := ...
      let $override := xs:boolean(t:optional-field('override', 'false'))
      :)
      return
         if ( $code eq 404 ) then (
            <p><b>Error</b>: There is no package at { $uri }.</p>
         )
         else if ( $code eq 200 ) then (
            (:
            let $stored := a:appserver-save-in-repo-attic($xar, $filename, $as),
            let $pkg    := a:appserver-install-package($xar, $as, $override)
            :)
            let $pkg    := a:appserver-install-package($xar, $as)
            return
               if ( fn:exists($pkg) ) then
                  <p>Package <code>{ string($pkg/@name) }</code>, version
                     <code>{ string($pkg/@version) }</code>, successfully installed into the
                     repository associated to { v:as-link('../' || $as/@id, $as/a:name) },
                     within the package directory <code>{ xs:string($pkg/@dir) }</code>.</p>
               else
                  (: TODO: Provide more accurate info! :)
                  (: TODO: Use try/catch instead...! :)
                  <p>Package NOT installed into the repository associated to
                     { v:as-link('../' || $as/@id, $as/a:name) }.  Did it already exist?</p>
         )
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
      else (
         <p><b>Error</b>: Unknown error: <em>{ $err:description }</em></p>
      )
   }
};

v:console-page('../../', 'pkg', 'Install package', local:page#0)

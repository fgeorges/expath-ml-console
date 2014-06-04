xquery version "3.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xql";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "../lib/repo.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
   let $repo-id  := t:mandatory-field('repo')
   let $repo     := cfg:get-repo($repo-id)
   let $xar      := t:mandatory-field('xar')
   let $filename := t:mandatory-field-filename('xar')
   let $stored   := r:save-in-attic($xar, $filename, $repo)
   let $pkg      := r:install-package($xar, $repo)
   (:
   let $override := xs:boolean(t:optional-field('override', 'false'))
   let $pkg      := r:install-package($xar, $repo, $override)
   :)
   return (
      if ( exists($pkg) ) then
         <p>Package '{ $filename }' successfully installed into the repository
            '{ $repo-id }', within the package directory '{ $pkg/fn:string(@dir) }'.</p>
      else
         (: TODO: Provide more accurate info! :)
         (: TODO: Use try/catch instead...! :)
         <p>Package '{ $filename }' NOT installed into '{ $repo-id }'.  Did it
            already exist?</p>,
      <p>Back to the <a href="show.xq?repo={ $repo-id }">repository</a>.</p>
   )
};

v:console-page('../', 'pkg', 'Install package', local:page#0)

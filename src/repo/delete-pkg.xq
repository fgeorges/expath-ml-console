xquery version "3.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xqy";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "../lib/repo.xqy";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace pp = "http://expath.org/ns/repo/packages";

declare function local:page()
   as element()+
{
   let $id      := t:mandatory-field('repo')
   let $repo    := cfg:get-repo($id)
   let $pkgdir  := t:mandatory-field('pkg')
   let $pkg     := r:get-package-by-pkgdir($pkgdir, $repo)
   let $confirm := xs:boolean(t:optional-field('confirm', 'false'))
   return
      <wrapper> {
         if ( empty($pkg) ) then
            <p><b>Error</b>: Package '{ $pkgdir }' does not exist in '{ $id }'.</p>
         else if ( not($confirm) ) then
            <p>
               <span>Are you sure you want to delete '{ $pkgdir }' in repo '{ $id }': </span>
               <a href="delete-pkg?repo={ $id }&amp;pkg={ $pkgdir }&amp;confirm=true">Yes</a>
               <span> / </span>
               <a href="show?repo={ $id }">No</a>
            </p>
         else
            <p>
               { r:delete-package($pkg, $repo)[fn:false()] }
               Package { $pkg/fn:string(@name) }, version { $pkg/fn:string(@version) },
               succesfully uninstalled from { $pkgdir }.
            </p>
         }
         <p>Back to the <a href="show?repo={ $id }">repository</a>.</p>
      </wrapper>/*
      (:
      else if ( r:delete-package($pkg, $repo) ) then
         <p>Package { $pkg/@name } / { $pkg/@version } succesfully uninstalled from { $pkgdir }.</p>
      else
         <p>Error while deleting package { $pkg/@name } / { $pkg/@version } from { $pkgdir }.</p>
      :)
};

v:console-page('../', 'pkg', 'Repository', local:page#0)

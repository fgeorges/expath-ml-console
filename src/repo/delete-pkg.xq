xquery version "1.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xql";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "../lib/repo.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace pp = "http://expath.org/ns/repo/packages";

(:
   TODO: If on the filesystem, warn the user to delete the directory himself...!
:)

let $name    := t:mandatory-field('repo')
let $repo    := cfg:get-repo($name)
let $pkgdir  := t:mandatory-field('pkg')
let $pkg     := r:get-package-by-pkgdir($pkgdir, $repo)
let $confirm := xs:boolean(t:optional-field('confirm', 'false'))
return
   v:console-page(
      'repo',
      fn:concat('Repository ''', $name, ''''),
      '../',
      <wrapper> {
         if ( empty($pkg) ) then
            <p><b>Error</b>: Package '{ $pkgdir }' does not exist in '{ $name }'.</p>
         else if ( not($confirm) ) then
            <p>
               <span>Are you sure you want to delete '{ $pkgdir }' in repo '{ $name }': </span>
               <a href="delete-pkg.xq?repo={ $name }&amp;pkg={ $pkgdir }&amp;confirm=true">Yes</a>
               <span> / </span>
               <a href="show.xq?repo={ $name }">No</a>
            </p>
         else
            <p>
               { r:delete-package($pkg, $repo)[fn:false()] }
               Package { $pkg/fn:string(@name) }, version { $pkg/fn:string(@version) },
               succesfully uninstalled from { $pkgdir }.
            </p>
         }
         <p>Back to the <a href="show.xq?repo={ $name }">repository</a>.</p>
      </wrapper>/*)
(:
      else if ( r:delete-package($pkg, $repo) ) then
         <p>Package { $pkg/@name } / { $pkg/@version } succesfully uninstalled from { $pkgdir }.</p>
      else
         <p>Error while deleting package { $pkg/@name } / { $pkg/@version } from { $pkgdir }.</p>)
:)

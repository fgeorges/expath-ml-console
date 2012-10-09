xquery version "1.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "lib/admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "lib/repo.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace pp   = "http://expath.org/ns/repo/packages";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:package-row($pkg as element(pp:package), $repo as element(c:repo))
   as element(tr)
{
   <tr>
      <td>{ $pkg/fn:string(@name) }</td>
      <td>{ $pkg/fn:string(@dir) }</td>
      <td>{ $pkg/fn:string(@version) }</td>
      <td>
         <a href="do-delete.xq?repo={ $repo/@name }&amp;pkg={ $pkg/fn:escape-html-uri(@dir) }">delete</a>
      </td>
   </tr>
};

declare function local:to-remove-row($pkg as element(pp:package), $repo as element(c:repo))
   as element(tr)
{
   <tr>
      <td colspan="4">{ $repo/fn:string(c:absolute) }{ $pkg/fn:string(@dir) }/</td>
   </tr>
};

(: TODO: Check the parameter has been passed, to avoid XQuery errors! :)
(: (turn it into a human-friendly error instead...) :)
(: And validate it! (does the repo exist?) :)
let $name      := t:mandatory-field('repo')
let $repo      := cfg:get-repo($name)
let $packages  := r:get-packages-list($repo)
let $to-remove := r:get-to-remove-list($repo)
return
   v:console-page(
      'repo',
      'Repository',
      <wrapper>
         <p>Packages in the repository <b>'{ $name }'</b>:</p>
         {
            if ( fn:empty($packages/pp:package|$to-remove/pp:package) ) then
               <p><em>there is no package installed in this repository yet</em></p>
            else
               <table>
                  <thead>
                     <td>Name</td>
                     <td>Dir</td>
                     <td>Version</td>
                     <td>Action</td>
                  </thead>
                  <tbody> {
                     for $p in $packages/pp:package
                     return
                        local:package-row($p, $repo),
                     if ( fn:exists($to-remove/pp:package) ) then (
                        <tr><td colspan="4"><em>Directories to manually delete:</em></td></tr>,
                        for $p in $to-remove/pp:package
                        return
                           local:to-remove-row($p, $repo)
                     )
                     else (
                     )
                  }
                  </tbody>
               </table>
         }
      </wrapper>/*)

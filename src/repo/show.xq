xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xqy";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xql";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "../lib/repo.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace pp   = "http://expath.org/ns/repo/packages";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page()
   as element()+
{
   (: TODO: Check the parameter has been passed, to avoid XQuery errors! :)
   (: (turn it into a human-friendly error instead...) :)
   (: And validate it! (does the repo exist?) :)
   let $repo-id   := t:mandatory-field('repo')
   let $repo      := cfg:get-repo($repo-id)
   let $packages  := r:get-packages-list($repo)
   let $to-remove := r:get-to-remove-list($repo)
   return
      <wrapper> {
         if ( fn:empty($packages/pp:package|$to-remove/pp:package) ) then
            ()
         else
            <table class="table">
               <thead>
                  <td>Name</td>
                  <td>Dir</td>
                  <td>Version</td>
                  <td>Action</td>
               </thead>
               <tbody> {
                  for $p in $packages/pp:package
                  order by $p/fn:string(@dir)
                  return
                     local:package-row($p, $repo),
                  if ( fn:exists($to-remove/pp:package) ) then (
                     <tr><td colspan="4"><em>Directories to manually delete:</em></td></tr>,
                     for $p in $to-remove/pp:package
                     order by $p/fn:string(@dir)
                     return
                        local:to-remove-row($p, $repo)
                  )
                  else (
                  )
               }
               </tbody>
            </table>
         }
         <h4>Install from file</h4>
         <p>Install packages and applications from your filesystem, using a package
            file (usually a *.xar file).</p>
         <form method="post" action="install-pkg" enctype="multipart/form-data">
            <input type="file" name="xar"/>
            <input type="submit" value="Install"/>
            <!--br/><br/>
            <input type="checkbox" name="override" value="true"/>
            <em>Override the package of it already exists</em-->
            <input type="hidden" name="repo" value="{ $repo-id }"/>
         </form>
         <h4>Install from CXAN</h4>
         <p>Install packages and applications directly from CXAN, using a package
            name or a CXAN ID (one or the other), and optionally a version number
            (retrieve the latest version by default).</p>
         <form method="post" action="../cxan/install" enctype="multipart/form-data">
            <span>ID:</span>
            <input type="text" name="id" size="25"/>
            <span> or name:</span>
            <input type="text" name="name" size="50"/>
            <br/>
            <span>Version (optional):</span>
            <input type="text" name="version" size="15"/>
            <br/>
            <input type="submit" value="Install"/>
            <input type="hidden" name="repo" value="{ $repo-id }"/>
         </form>
      </wrapper>/*
};

declare function local:package-row($pkg as element(pp:package), $repo as element(c:repo))
   as element(tr)
{
   <tr>
      <td>{ $pkg/fn:string(@name) }</td>
      <td>{ $pkg/fn:string(@dir) }</td>
      <td>{ $pkg/fn:string(@version) }</td>
      <td>
         <a href="delete-pkg?repo={ $repo/@id }&amp;pkg={ $pkg/fn:escape-html-uri(@dir) }">delete</a>
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

v:console-page('../', 'pkg', 'Repository', local:page#0)

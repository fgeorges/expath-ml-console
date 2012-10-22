xquery version "1.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "lib/admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace w    = "http://expath.org/ns/ml/webapp";
declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : TODO: What if there is none?
 : TODO: Duplicated in repo.xq, factorize out!
 :)
declare function local:appserver-options()
{
   <select name="appserver"> {
      for $as in a:get-appservers()/a:appserver
      order by $as/a:name
      return
         (: For now, the way to detect WebDAV servers is that they do not have none of them. :)
         if ( fn:empty($as/(a:modules-db|a:modules-path)) ) then
            ()
         else
            <option value="{ $as/@id }">{ $as/fn:string(a:name) }</option>
   }
   </select>
};

let $container-refs := cfg:get-container-refs()
return
   v:console-page(
      'web',
      'Web containers',
      '',
      <wrapper> {
         if ( fn:empty($container-refs) ) then
            ()
         else (
            <table class="sortable">
               <thead>
                  <td>ID</td>
                  <td>Name</td>
                  <td>App Server</td>
                  <td>Root</td>
                  <td>Repo</td>
                  <td>Actions</td>
               </thead>
               <tbody> {
                  for $ref       in $container-refs
                  let $container := cfg:get-container($ref)
                  let $id        := $container/fn:string(@id)
                  let $name      := $container/fn:string(w:name)
                  let $escaped   := fn:escape-html-uri($id)
                  let $as-id     := xs:unsignedLong($container/@appserver)
                  let $appserver := a:get-appserver($as-id)
                  let $repo-name := fn:string($container/w:repo)
                  let $repo-esc  := fn:escape-html-uri($repo-name)
                  let $repo      := cfg:get-repo($repo-name)
                  order by $name
                  return
                     <tr>
                        <td>
                           <a href="web/show.xq?container={ $escaped }">{ $id }</a>
                        </td>
                        <td>{ $name }</td>
                        <td>{ fn:string($appserver/a:name) }</td>
                        <td>{ fn:string($container/w:web-root) }</td>
                        <td>
                           <a href="repo/show.xq?repo={ $repo-esc }">{ $repo-name }</a>
                        </td>
                        <td>
                           <a href="web/delete.xq?container={ $escaped }">remove</a> {
                           if ( fn:exists($repo/c:database) ) then (
                              <span>, </span>,
                              <a href="web/delete.xq?container={ $escaped }&amp;delete=true">delete</a>
                           )
                           else (
                           )
                        }
                        </td>
                     </tr>
               }
               </tbody>
            </table>,
            <p><em>Removing a web container means removing its configuration from the
               console. It does not delete the associated repo and all its content
               (installed packages and webapps). Deleting a web container does delete
               the associated repo and all its content (not available for on-disk
               repos).</em></p>
            )
         }
         <h4>Create a web container</h4>
         <p>A web container is a central place to install web application.  Each
            is associated to a MarkLogic HTTP Application Server. You can maintain
            several web containers, on the same or on different App Servers.  A web
            container is also associated to a repository, which must be on the
            modules database linked to the corresponding App Server (both can be
            created at once).</p>
         <p>You have to provide the web root of the web container (that is, all
            requests sent to that URI or any URI "underneath" will be treated by
            that web container). You also have to select the App Server to create
            the web container in (it must already exist, see the MarkLogic admin
            console for creating HTTP App Servers).</p>
         <form method="post" action="web/select-repo.xq" enctype="multipart/form-data">
            <span>The container ID (any valid NCName, must be unique):</span><br/>
            <input type="text" name="id" size="50"/><br/>
            <span>A human-friendly name (any string):</span><br/>
            <input type="text" name="name" size="50"/><br/>
            <span>The container root (the web context root for all web applications
               in this container):</span><br/>
            <input type="text" name="root" size="50"/><br/><br/>
            <span>Pick an application server:</span>
            { local:appserver-options() }
            <input name="create" type="submit" value="Create"/>
         </form>
      </wrapper>/*)

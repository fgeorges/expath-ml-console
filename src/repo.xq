xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "lib/admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

(: TODO: Maintain a list of repos removed but not deleted... (like for packages) :)

declare function local:page()
   as element()+
{
   let $repos := cfg:get-repos()
   return
      <wrapper> {
         if ( fn:empty($repos) ) then
            ()
         else (
            <table class="sortable">
               <thead>
                  <td>ID</td>
                  <td>Name</td>
                  <td>Database</td>
                  <td>Root</td>
                  <!-- Meaningful, really? -->
                  <!--td>Web?</td-->
                  <td>Actions</td>
               </thead>
               <tbody> {
                  for $repo    in $repos
                  let $id      := $repo/fn:string(@id)
                  let $escaped := fn:escape-html-uri($id)
                  order by $id
                  return
                     <tr>
                        <td>
                           <a href="repo/show.xq?repo={ $escaped }">{ $id }</a>
                        </td>
                        <td>{ fn:string($repo/c:name) }</td>
                        <td>{ fn:string($repo/c:database) }</td>
                        <td> {
                           if ( fn:exists($repo/c:database) ) then
                              fn:string($repo/c:root)
                           else
                              fn:string($repo/c:absolute)
                        }
                        </td>
                        <td>
                           <a href="repo/delete.xq?repo={ $escaped }">remove</a> {
                           if ( fn:exists($repo/c:database) ) then (
                              <span>, </span>,
                              <a href="repo/delete.xq?repo={ $escaped }&amp;delete=true">delete</a>
                           )
                           else (
                           )
                        }
                        </td>
                     </tr>
               }
               </tbody>
            </table>,
            <p><em>Removing a repository means removing its configuration from the
               console. It does not delete the repository content itself. Deleting
               a repository does (not available for on-disk repos).</em></p>
            )
         }
         <h4>Create a repository</h4>
         <p>A repository is a central place to install packages.  You can maintain
            several repositories.  You can create a repository in a database
            chosen by name, or in a database attached as the module database to an
            application server (which can then be on the filesystem).</p>
         <p>In both cases, you have to provide the path of the repository. If you
            select a database it will be resolved within the database.  If you
            select an appserver connected to a database module, it will be
            resolved within the database, taking the root into account.  If you
            select an appserver using the filsystem, it will be resolved within
            that directory.</p>
         <form method="post" action="repo/create.xq" enctype="multipart/form-data">
            <span>The repo ID (must be a valid NCName):</span><br/>
            <input type="text" name="id" size="50"/><br/>
            <span>The repo name (any string):</span><br/>
            <input type="text" name="name" size="50"/><br/>
            <span>The repo root (relative to the database root or to the app server root):</span><br/>
            <input type="text" name="root" size="50"/><br/><br/>
            <span>Pick an application server:</span>
            { local:appserver-options() }
            <input name="create-as" type="submit" value="Create"/>
            <span>, or a database:</span>
            { local:database-options() }
            <input name="create-db" type="submit" value="Create"/>
         </form>
      </wrapper>/*
};

(:~
 : TODO: What if there is none?
 : TODO: Duplicated in web.xq, factorize out!
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

(:~
 : TODO: ...
 : TODO: Duplicated in tools.xq, factorize out!
 :)
declare function local:database-options()
{
   <select name="database"> {
      for $db in a:get-databases()/a:database
      order by $db/a:name
      return
         <option value="{ $db/@id }">{ $db/fn:string(a:name) }</option>
   }
   </select>
};

v:console-page('', 'repo', 'Repositories', local:page#0)

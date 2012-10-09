xquery version "1.0";

(:~
 : Aimed at becoming a general config page for the console.
 : 
 : In a first time, it will just create the config document in MarkLogic, with
 : the database where to put the repository, and the associated prefix.  The
 : goal however is to be able to have several of them.
 :)

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "lib/admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : TODO: ...
 :)
declare function local:repo-options()
{
   let $repos := cfg:get-repos()
   return
      if ( fn:empty($repos) ) then
         <span><em>there is no repository configured yet</em></span>
      else (
         <span>Pick a repository to delete:</span>,
         <select name="repo"> {
            for $r in $repos
            order by $r/@name
            return
               <option value="{ $r/@name }">{ $r/fn:string(@name) }</option>
         }
         </select>,
         <input type="submit" value="Delete"/>
      )
};

(:~
 : TODO: What if there is none?
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

v:console-page(
   'setup',
   'Setup',
   <wrapper>
      <p>The console operates on one or several repositories.  This page
         provides you with tools to create new and delete existing
         repositories.</p>
      <h4>Delete an existing repository</h4>
      <p>Deleting a repository means to remove its configuration from the
         console.  It does not delete the repository content itself.</p>
      <form method="post" action="do-setup-delete.xq" enctype="multipart/form-data">
         { local:repo-options() }<br/>
         <input type="checkbox" name="remove" value="true"/>
         <em>Actually remove all the associated content from the database (not
            applicable for repositories on the filesystem).</em>
      </form>
      <h4>Create a new repository</h4>
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
      <form method="post" action="do-setup-create.xq" enctype="multipart/form-data">
         <span>The repo name (must be a valid NCName):</span><br/>
         <input type="text" name="name" size="50"/><br/><br/>
         <span>The repo root (relative to the database root or to the app server root):</span><br/>
         <input type="text" name="root" size="50"/><br/><br/>
         <span>Pick an application server:</span>
         { local:appserver-options() }
         <input name="create-as" type="submit" value="Create"/>
         <span>, or a database:</span>
         { local:database-options() }
         <input name="create-db" type="submit" value="Create"/>
      </form>
      <h4>Setup CXAN wesbite</h4>
      <p>Configure the CXAN website to talk to, for instance http://cxan.org/
         or http://test.cxan.org/.</p>
      {
         let $site := cfg:get-cxan-site()
         return
            if ( fn:empty($site) ) then
               <p><em>No repo has been created yet, please proceed first.</em></p>
            else
               <form method="post" action="do-setup-cxan.xq" enctype="multipart/form-data">
                  <span>The CXAN website: </span>
                  <input type="text" name="site" size="50" value="{ $site }"/>
                  <br/>
                  <input name="set-site" type="submit" value="Set"/>
               </form>
      }
   </wrapper>/*)

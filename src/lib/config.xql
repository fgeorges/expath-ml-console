xquery version "3.0";

(:~
 : Library to access the configuration.
 :
 : There are several documents managed by this library.  The first one is the
 : config document, with the config of the console itself.  Basically, it
 : contains the URI of the CXAN website, and config about all existing repos in
 : the MarkLogic Server instance.  Then there is one config file per database
 : attached to App Server with at least one web container.  Those are the web
 : containers config file.
 : 
 : The config document URI is: http://expath.org/coll/console/config.xml.  Its
 : content looks like the following:
 :
 :     <config xmlns="http://expath.org/ns/ml/console">
 :        <cxan>
 :           <site>http://cxan.org/</site>
 :        </cxan>
 :        <repo name="xxx">
 :           <root>path/relative/to/db/root</root>
 :           <database id="123">Modules</database>
 :           <packages-doc>path/relative/to/db/root/.expath-pkg/packages.xml</packages-doc>
 :        </repo>
 :        <repo name="yyy">
 :           <root>path/relative/to/dir</root>
 :           <directory>/dir/...</directory>
 :           <absolute>/dir/.../path/relative/to/dir</absolute>
 :           <packages-file>/dir/.../path/relative/to/dir/.expath-pkg/packages.xml</packages-file>
 :           <to-remove-file>/dir/.../path/relative/to/dir/.expath-pkg/to-remove.xml</to-remove-file>
 :        </repo>
 :        <container id="...">
 :           <name>...</name>
 :           <db id="...">...</db>
 :        </container>
 :     </config>
 : 
 : TODO: We should not cache the database name, we should just use the ID.
 : Remove the names from the config!  The name is legit in the in-memory
 : representation of the database as returned by the admin lib (that is, the
 : corresponding element a:database or within a:appserver), but not saved
 : within the config file.
 :
 : The config document URI is: http://expath.org/coll/webapp/config.xml.  Its
 : content looks like the following:
 :
 :     <config>
 :        <container id="..." appserver="...">
 :           <name>...</name>
 :           <web-root>...</web-root>
 :           <repo>...</repo>
 :           <repo-root>...</repo-root>
 :           <application id="...">
 :              <name>...</name>
 :              <!-- relative to container's root, defaults to the webapp abbrev -->
 :              <root>...</root>
 :              <pkg-dir>...</pkg-dir>
 :              <webapp xmlns="...">
 :                 ... [copy of expath-web.xml] ...
 :              </webapp>
 :           </application>
 :        </container>
 :     </config>
 : 
 : There is such a config document per database attached to an App Server with
 : at least one web container.  Recap: an App Server is attached a database,
 : and a database can be attached to several App Servers.
 :)
module namespace cfg = "http://expath.org/ns/ml/console/config";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "admin.xql";
import module namespace r = "http://expath.org/ns/ml/console/repo"  at "repo.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "tools.xql";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace w    = "http://expath.org/ns/ml/webapp";
declare namespace xdmp = "http://marklogic.com/xdmp";

(: TODO: Nothing should depend on this namespace here, move it to repo.xql or similar... :)
declare namespace pp = "http://expath.org/ns/repo/packages";

declare variable $cfg:config-docname :=
   "http://expath.org/coll/console/config.xml";
declare variable $cfg:web-config-docname :=
   "http://expath.org/coll/webapp/config.xml";

(: ==== Accessing config ======================================================== :)

(:~
 : Return true if the initial setup of the console has been done.
 :)
declare function cfg:is-setup()
   as xs:boolean
{
   fn:doc-available($cfg:config-docname)
};

(:~
 : Return the config file of the console.
 :)
declare function cfg:get-config()
   as element(c:config)?
{
   fn:doc($cfg:config-docname)/*
};

(:~
 : Return the list of existing repos.
 :)
declare function cfg:get-repos()
   as element(c:repo)*
{
   cfg:get-config()/c:repo
};

(:~
 : Return one specific repo given its name.
 :)
declare function cfg:get-repo($name as xs:string)
   as element(c:repo)?
{
   cfg:get-config()/c:repo[@name eq $name]
};

(:~
 : Return the existing repos suitable to be used by a specific App Server.
 :
 : Given the modules database attached to the App Server, and given its modules
 : root, only some repos can be used from code running within the App Server.
 : The different cases are:
 :
 :     - the App Server modules are stored on the file system
 :       -> all the repos (on the file system), in a sub-directory of the App
 :          Server modules root are returned
 :
 :     - the App Server modules are stored on a database
 :       -> all the repos in the same database, with a root which is underneath
 :          the App Server modules root are returned
 :
 : Throw 'appserver-not-exist' if the App Server does not exist.
 :)
declare function cfg:get-appserver-repos($as as element(a:appserver))
   as element(c:repo)*
{
   cfg:get-repos()[cfg:is-repo-in-appserver(., $as)]
};

(:~
 : Return true if the repo is usable on the App Server.
 :
 : See cfg:get-appserver-repos().
 :
 : TODO: Should probably use something more complex than starts-with()...
 :)
declare function cfg:is-repo-in-appserver($repo as element(c:repo), $as as element(a:appserver))
   as xs:boolean
{
   if ( fn:exists($as/a:modules-db) ) then
      $repo/c:database/@id eq $as/a:modules-db/@id and fn:starts-with($repo/c:root, $as/a:root)
   else
      fn:starts-with($repo/c:absolute, $as/a:modules-path)
};

(:~
 : TODO: ...
 :)
declare function cfg:get-cxan-site()
   as xs:string?
{
   cfg:get-config()/c:cxan/fn:string(c:site)
};

(:~
 : Return the container references, from the Console config file.
 :)
declare function cfg:get-container-refs()
   as element(c:container)*
{
   cfg:get-config()/c:container
};

(:~
 : Return the container reference, for a given ID.
 :)
declare function cfg:get-container-ref($id as xs:string)
   as element(c:container)?
{
   cfg:get-container-refs()[@id eq $id]
};

(:~
 : Return the container config, from its reference.
 :)
declare function cfg:get-container($container as element(c:container))
   as element(w:container)*
{
   $container
     / a:get-from-database(xs:unsignedLong(c:db/@id), $cfg:web-config-docname, '')
     / w:config
     / w:container[@id eq $container/@id]
};

(: ==== Managing repos ======================================================== :)

(:~
 : Return true if created, false is already exists.
 :
 : TODO: Create [repo]/.expath-pkg/packages.xml.
 : TODO: Add the path to [repo]/.expath-pkg/packages.xml as <packages-doc>.
 : TODO: Check if database still exists.
 : TODO: Factorise with cfg:create-repo-in-directory().
 :)
declare function cfg:create-repo-in-database(
   $name    as xs:string,
   $root    as xs:string,
   $db-id   as xs:string,
   $db-name as xs:string
) as element(c:repo)
{
   let $_root   := if ( fn:ends-with($root, '/') ) then $root else fn:concat($root, '/')
   let $repo    :=
         <repo name="{ $name }" xmlns="http://expath.org/ns/ml/console">
            <root>{ $_root }</root>
            <database id="{ $db-id }">{ $db-name }</database>
         </repo>
   let $pkg-doc :=
         r:insert-into(
            '.expath-pkg/packages.xml',
            <packages xmlns="http://expath.org/ns/repo/packages"/>,
            $repo)
   let $repo :=
         t:add-last-child(
            $repo,
            <packages-doc xmlns="http://expath.org/ns/ml/console">{ $pkg-doc }</packages-doc>)
   return
      cfg:insert-new-repo($repo)
};

(:~
 : Return true if created, false is already exists.
 :
 : TODO: Factorise with cfg:create-repo-in-database().
 :)
declare function cfg:create-repo-in-directory(
   $name as xs:string,
   $root as xs:string,
   $dir  as xs:string
) as element(c:repo)
{
   let $_root    := if ( fn:ends-with($root, '/') ) then $root else fn:concat($root, '/')
   let $_dir     := if ( fn:ends-with($dir, '/') )  then $dir  else fn:concat($dir, '/')
   let $absolute := fn:concat($_dir, if ( fn:starts-with($_root, '/') ) then fn:substring($_root, 2) else $_root)
   let $repo     :=
         <repo name="{ $name }" xmlns="http://expath.org/ns/ml/console">
            <root>{ $_root }</root>
            <directory>{ $_dir }</directory>
            <absolute>{ $absolute }</absolute>
         </repo>
   let $pkg-file :=
         r:insert-into(
            '.expath-pkg/packages.xml',
            <packages xmlns="http://expath.org/ns/repo/packages"/>,
            $repo)
   let $repo :=
         t:add-last-child(
            $repo,
            <packages-file xmlns="http://expath.org/ns/ml/console">{ $pkg-file }</packages-file>)
   let $rm-file :=
         r:insert-into(
            '.expath-pkg/to-remove.xml',
            <packages xmlns="http://expath.org/ns/repo/packages"/>,
            $repo)
   let $repo :=
         t:add-last-child(
            $repo,
            <to-remove-file xmlns="http://expath.org/ns/ml/console">{ $rm-file }</to-remove-file>)
   return
      cfg:insert-new-repo($repo)
};

(:~
 : Return true if created, false if already exists.
 :
 : If the config file does not exist yet, it is created.
 :
 : Throws 'c:repo-exists' if a repo with the same name already exists.
 :
 : TODO: Is it possible to return a reference to the inserted repo element,
 : instead of a reference to the in-memory element?
 :)
declare %private function cfg:insert-new-repo($repo as element(c:repo))
   as element(c:repo)
{
   if ( fn:exists(cfg:get-repo($repo/@name)) ) then
      t:error('repo-exists', ('The repo ''', $repo/@name, ''' already exists.'))
   else if ( cfg:is-setup() ) then
      xdmp:node-insert-child(cfg:get-config(), $repo)
   else
      xdmp:document-insert(
         $cfg:config-docname,
         <config xmlns="http://expath.org/ns/ml/console">
            <cxan>
               <site>http://test.cxan.org/</site>
            </cxan>
            { $repo }
         </config>),
   $repo
};

(:~
 : Forget about a previously created repository.
 :
 : If $delete is true, all content of the repo is deleted from the database.
 :
 : Throw 'repo-not-exist' if the given repository name does not exist.
 :
 : Throw 'repo-on-disk' if the repository is on disk and $delete is true.
 :)
declare function cfg:forget-repo($name as xs:string, $delete as xs:boolean)
   as empty-sequence()
{
   let $repo := cfg:get-repo($name)
   return (
      if ( fn:empty($repo) ) then
         t:error('repo-not-exist', ('The repo ''', $name, ''' does not exist.'))
      else if ( $delete and r:is-filesystem-repo($repo) ) then
         t:error('repo-on-disk', ('The repo ''', $name, ''' is on disk, it cannot be deleted.'))
      else if ( $delete ) then
         a:remove-directory($repo/c:database/@id, $repo/c:root)
      else
         (),
      xdmp:node-delete($repo)
   )
};

(: ==== Managing CXAN ======================================================== :)

(:~
 : Change the URI for the location of the CXAN site.
 :
 : Return the new URI.
 :
 : Throw 'c:not-setup' if the console has not been set up yet.
 :
 : Throw 'c:config-corrupted' if the config file does not have the CXAN config.
 :)
declare function cfg:set-cxan-site($site as xs:string)
   as xs:string
{
   if ( fn:not(cfg:is-setup()) ) then
      t:error('not-setup', 'Impossible to set the CXAN site before configuring at least one repo.')
   else if ( fn:empty(cfg:get-config()/c:cxan/c:site) ) then
      t:error('config-corrupted', 'Config file does not have a CXAN site?!?')
   else
      xdmp:node-replace(
         cfg:get-config()/c:cxan/c:site,
         <site xmlns="http://expath.org/ns/ml/console">{ $site }</site>),
   $site
};

(: ==== Managing web containers ======================================================== :)

(: Temporary! Copy of the comment at the top of the file while developing...
 : TODO: To remove.
 :
 :     <config>
 :        <container id="..." appserver="...">
 :           <name>...</name>
 :           <web-root>...</web-root>
 :           <repo>...</repo>
 :           <repo-root>...</repo-root>
 :           <application id="...">
 :              <name>...</name>
 :              <!-- relative to container's root, defaults to the webapp abbrev -->
 :              <root>...</root>
 :              <pkg-dir>...</pkg-dir>
 :              <webapp xmlns="...">
 :                 ... [copy of expath-web.xml] ...
 :              </webapp>
 :           </application>
 :        </container>
 :     </config>
:)

(:~
 : Create a new web container and record it in the config.
 :
 : $id the ID
 : $name the name
 : $root the web root
 : $as the App Server associayed to the container
 : $repo the repo associated to the container
 :
 : Throw 'container-exists' if the container already exists in the config.
 :
 : Throw 'c:not-setup' if the console has not been set up yet.
 :
 : TODO: Return the web container element instead...
 :)
declare function cfg:create-web-container(
   $id   as xs:string,
   $name as xs:string,
   $root as xs:string,
   $as   as element(a:appserver),
   $repo as element(c:repo)
) as element(c:container)
{
   let $container :=
         <container id="{ $id }" appserver="{ $as/fn:string(@id) }"
                    xmlns="http://expath.org/ns/ml/webapp">
            <name>{ $name }</name>
            <web-root>{ $root }</web-root>
            <repo>{ $repo/fn:string(@name) }</repo>
            <repo-root>{ $repo/fn:string(@root) }</repo-root>
         </container>
   let $ref :=
         <container id="{ $id }" xmlns="http://expath.org/ns/ml/console">
            <name>{ $name }</name>
            <db id="{ $as/a:db/fn:string(@id) }">{ $as/fn:string(a:db) }</db>
         </container>
   let $db   := $as/a:db/xs:unsignedLong(@id)
   let $doc  := a:get-from-database($db, $cfg:web-config-docname, '')
   let $conf := cfg:get-repos()
   return
      if ( fn:not(cfg:is-setup()) ) then
         (: TODO: This should not be an error, we should be able to create a
            container without having to create a repo first. :)
         t:error('not-setup', 'Impossible to create a web container before configuring at least one repo.')
      else if ( fn:exists($conf/c:container[@id eq $id]) ) then
         t:error('container-exists', ('The web container already exists: ''', $id, ''''))
      else
         let $config :=
                  if ( fn:exists($doc) ) then
                     t:add-last-child($doc/w:config, $container)
                  else
                     <config xmlns="http://expath.org/ns/ml/webapp"> {
                        $container
                     }
                     </config>
         let $dummy := a:insert-into-database($db, $cfg:web-config-docname, $config)
         let $dummy := xdmp:node-insert-child(cfg:get-config(), $ref)
         return
            $ref
};

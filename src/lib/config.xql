xquery version "3.0";

(:~
 : Library to access the configuration.
 :
 : TODO: Write schemas for the config files and other elements used in this
 : library module (and other library modules as well), and import them here to
 : validate any piece of data and documents we create/modify/access.
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
 :        <repo id="xxx">
 :           <name>First repo</name>
 :           <root>path/relative/to/db/root</root>
 :           <database id="123">Modules</database>
 :           <packages-doc>path/relative/to/db/root/.expath-pkg/packages.xml</packages-doc>
 :        </repo>
 :        <repo id="yyy">
 :           <name>Second repo</name>
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

import module namespace a = "http://expath.org/ns/ml/console/admin" at "admin.xqy";
import module namespace r = "http://expath.org/ns/ml/console/repo"  at "repo.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "tools.xql";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace w    = "http://expath.org/ns/ml/webapp";
declare namespace xdmp = "http://marklogic.com/xdmp";

(: TODO: Nothing should depend on this namespace here, move it to repo.xql or similar... :)
declare namespace pp = "http://expath.org/ns/repo/packages";

declare variable $cfg:config-docname     := "http://expath.org/coll/console/config.xml";
declare variable $cfg:web-config-docname := "http://expath.org/coll/webapp/config.xml";

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
 : Return one specific config element given its ID.
 :)
declare function cfg:get-config-elem($id as xs:string)
   as element()?
{
   cfg:get-config()/c:*[@id eq $id]
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
 : Return one specific repo given its ID.
 :)
declare function cfg:get-repo($id as xs:string)
   as element(c:repo)?
{
   cfg:get-config()/c:repo[@id eq $id]
};

(:~
 : Insert a new config element in the Console config document.
 :
 : If the config document does not exist yet, it is created.  The element to
 : add must have an @id, and no other element with the same ID can exist.
 :
 : Throws 'c:config-elem-exists' if an element with the same ID already exists.
 :
 : Return the config element itself.
 :)
declare %private function cfg:insert-new-config-element($elem as element())
   as element()
{
   if ( fn:exists(cfg:get-config-elem($elem/@id)) ) then
      t:error('config-elem-exists', 'The config element ''' || $elem/@id || ''' already exists.')
   else if ( cfg:is-setup() ) then
      xdmp:node-insert-child(cfg:get-config(), $elem)
   else
      xdmp:document-insert(
         $cfg:config-docname,
         <config xmlns="http://expath.org/ns/ml/console">
            <cxan>
               <site>http://test.cxan.org/</site>
            </cxan>
            { $elem }
         </config>),
   $elem
};

(:~
 : Insert a new config element in the Webapp config document in a specific database.
 :
 : If the config document does not exist yet in that database, it is created.
 : The element to add must have an @id, and no other element with the same ID
 : can exist.
 :
 : Throws 'c:config-elem-exists' if an element with the same ID already exists.
 :
 : Return the config element itself.
 :)
declare %private function cfg:insert-new-webapp-config-element(
   $elem as element(),
   $db   as xs:unsignedLong
) as element()
{
   let $cfg-doc  := a:get-from-database($db, $cfg:web-config-docname, '')
   let $cfg-elem := ( $cfg-doc/w:config, <config xmlns="http://expath.org/ns/ml/webapp"/> )[1]
   return
      if ( fn:exists($cfg-elem/w:*[@id eq $elem/@id]) ) then
         t:error(
            'config-elem-exists',
            'The webapp config element ' || $elem/@id || ' already exists in the database '
               || xs:string($db) || '.')
      else
         let $config := t:add-last-child($cfg-elem, $elem)
         let $dummy  := a:insert-into-database($db, $cfg:web-config-docname, $config)
         return
            $elem
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
 : TODO: Canonicalize all the different kinds of roots... (in order to prevent
 : the special cases "is the as root there?", "is it empty?", "is it '/'?", etc.
 : TODO: Should the repo have been created explicitly for the App Server?
 :)
declare function cfg:is-repo-in-appserver($repo as element(c:repo), $as as element(a:appserver))
   as xs:boolean
{
   if ( fn:exists($as/a:modules-db) ) then
      $repo/c:database/@id eq $as/a:modules-db/@id
         and ( fn:empty($as/a:root[.]) or $as/a:root eq '/' or fn:starts-with($repo/c:root, $as/a:root) )
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
   $id      as xs:string,
   $name    as xs:string,
   $root    as xs:string,
   $db-id   as xs:string,
   $db-name as xs:string
) as element(c:repo)
{
   let $_root   := if ( fn:ends-with($root, '/') ) then $root else fn:concat($root, '/')
   let $repo    :=
         <repo id="{ $id }" xmlns="http://expath.org/ns/ml/console">
            <name>{ $name }</name>
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
      cfg:insert-new-config-element($repo)
};

(:~
 : Return true if created, false is already exists.
 :
 : TODO: Factorise with cfg:create-repo-in-database().
 :)
declare function cfg:create-repo-in-directory(
   $id   as xs:string,
   $name as xs:string,
   $root as xs:string,
   $dir  as xs:string
) as element(c:repo)
{
   let $_root    := if ( fn:ends-with($root, '/') ) then $root else fn:concat($root, '/')
   let $_dir     := if ( fn:ends-with($dir, '/') )  then $dir  else fn:concat($dir, '/')
   let $absolute := fn:concat($_dir, if ( fn:starts-with($_root, '/') ) then fn:substring($_root, 2) else $_root)
   let $repo     :=
         <repo id="{ $id }" xmlns="http://expath.org/ns/ml/console">
            <name>{ $name }</name>
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
 : Throws 'c:repo-exists' if a repo with the same ID already exists.
 :
 : TODO: Is it possible to return a reference to the inserted repo element,
 : instead of a reference to the in-memory element?
 :)
declare %private function cfg:insert-new-repo($repo as element(c:repo))
   as element(c:repo)
{
   if ( fn:exists(cfg:get-repo($repo/@id)) ) then
      t:error('repo-exists', 'The repo ''' || $repo/@id || ''' already exists.')
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
 : Remove a repository from the config.
 :
 : If $delete is true, all content of the repo is deleted from the database.
 :
 : Throw 'repo-not-exist' if the given repository ID does not exist.
 :
 : Throw 'repo-on-disk' if the repository is on disk and $delete is true.
 :)
declare function cfg:remove-repo($id as xs:string, $delete as xs:boolean)
   as empty-sequence()
{
   let $repo := cfg:get-repo($id)
   return (
      if ( fn:empty($repo) ) then
         t:error('repo-not-exist', 'The repo ''' || $id || ''' does not exist.')
      else if ( $delete and r:is-filesystem-repo($repo) ) then
         t:error('repo-on-disk', 'The repo ''' || $id || ''' is on disk, it cannot be deleted.')
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
 : Throw 'c:container-exists' if the container already exists in the config.
 :
 : Throw 'c:not-setup' if the console has not been set up yet.
 :
 : Copy some files needed by EXPath Web.  The files are in ../trunk/expath-web/,
 : and must be copied to the dir /expath/web/ under the HTTP App Server root.
 : The file url-rewriter.xq is installed as the URL resolver on the HTTP AS if
 : and only if the AS does not have a URL resolver yet.
 :
 : TODO: Return the web container element instead...
 :
 : TODO: Check there is no conflicting container (with an ancestor or descendant
 : web root).
 :
 : TODO: Ensure the web root starts with a slash...
 :)
declare function cfg:create-web-container(
   $id   as xs:string,
   $name as xs:string,
   $root as xs:string,
   $as   as element(a:appserver),
   $repo as element(c:repo)
) as element(w:container)
{
   let $ref       :=
         <container id="{ $id }" xmlns="http://expath.org/ns/ml/console">
            <name>{ $name }</name>
            <db id="{ $as/a:db/fn:string(@id) }">{ $as/fn:string(a:db) }</db>
         </container>
   let $container :=
         <container id="{ $id }" appserver="{ $as/fn:string(@id) }"
                    xmlns="http://expath.org/ns/ml/webapp">
            <name>{ $name }</name>
            <web-root>{ $root }</web-root>
            <repo>{ $repo/fn:string(@id) }</repo>
            <repo-root>{ $repo/fn:string(c:root) }</repo-root> {
              if ( fn:exists($repo/c:absolute) ) then
                <repo-dir>{ $repo/fn:string(c:absolute) }</repo-dir>
              else
                ()
            }
            <db id="{ $as/a:db/fn:string(@id) }">{ $as/fn:string(a:db) }</db>
         </container>
   return
      if ( fn:exists(cfg:get-container-ref($id)) ) then
         t:error('container-exists', 'The web container already exists: ''' || $id || '''')
      else
         let $dummy := cfg:install-exapth-web-to-appserver($as)
         let $dummy := cfg:insert-new-webapp-config-element($container, $as/a:db/xs:unsignedLong(@id))
         let $dummy := cfg:insert-new-config-element($ref)
         return
            $container
};

declare function cfg:install-exapth-web-to-appserver(
   $as as element(a:appserver)
) as empty-sequence()
{
   (: TODO: How to detect CURRENT appserver modules location? :)
   let $this-db   := xdmp:modules-database()
   let $that-db   := $as/a:modules-db/xs:unsignedLong(@id)
   let $this-root := xdmp:modules-root()
   let $copy-fn   := if ( fn:exists($that-db) and $this-db eq 0 ) then
                        cfg:copy-file-fs-to-db(?, ?, $that-db)
                     else if ( fn:exists($as/a:modules-path) and $this-db eq 0 ) then
                        cfg:copy-file-fs-to-fs(?, ?, $as/a:modules-path)
                     else if ( fn:exists($that-db) and $this-db gt 0 ) then
                        cfg:copy-file-db-to-db(?, $this-db, ?, $that-db)
                     else if ( fn:exists($as/a:modules-path) and $this-db gt 0 ) then
                        cfg:copy-file-db-to-fs(?, $this-db, ?, $as/a:modules-path)
                     else
                        t:error('internal-error', 'App Server modules neither on DB nor FS?')
   let $dest  := fn:concat($as/a:root, 'expath/web/')
   let $trunk := cfg:get-trunk-path($this-root)
   for $file  in ('binary.xql', 'dispatcher.xql', 'launcher.xq', 'url-rewriter.xq')
   return
      $copy-fn(fn:concat($trunk, $file), fn:concat($dest, $file)),
   a:set-url-rewriter-if-not-yet($as, '/expath/web/url-rewriter.xq')
};

declare %private function cfg:get-trunk-path($root as xs:string) as xs:string
{
   let $path := xdmp:get-invoked-path()
   (: Handle other cases, like none of them ends (or starts) with a slash... :)
   let $idx  := if ( fn:ends-with($root, '/') and fn:starts-with($path, '/') ) then 2 else 1
   return
      if ( fn:ends-with($path, '/lib/config.xql') ) then
         fn:concat(
            $root,
            fn:substring($path, $idx, fn:string-length($path) - $idx - 13),
            'trunk/expath-web/')
      else
         t:error('internal-error', 'The module config.xql is not at the expected place...!')
};

declare %private function cfg:copy-file-fs-to-fs(
   $file as xs:string,
   $dest as xs:string,
   $mods as xs:string
) as empty-sequence()
{
   let $dummy := a:insert-into-filesystem(
                    $dest,
                    a:get-from-filesystem($file, fn:false()))
   return
      ()
};

declare %private function cfg:copy-file-fs-to-db(
   $file    as xs:string,
   $dest    as xs:string,
   $dest-db as xs:unsignedLong
) as empty-sequence()
{
   let $dummy := a:insert-into-database(
                    $dest-db,
                    $dest,
                    a:get-from-filesystem($file, fn:false()))
   return
      ()
};

declare %private function cfg:copy-file-db-to-fs(
   $file   as xs:string,
   $src-db as xs:unsignedLong,
   $dest   as xs:string,
   $mods   as xs:string
) as empty-sequence()
{
   t:error(
      'IMPLEMENT-ME',
      'Copy file from DB to FS not supported yet: ' || $file || ', ' || $dest || ', ' || $mods
         || ', please report this to the mailing list.')
};

declare %private function cfg:copy-file-db-to-db(
   $file    as xs:string,
   $src-db  as xs:unsignedLong,
   $dest    as xs:string,
   $dest-db as xs:unsignedLong
) as empty-sequence()
{
   t:error(
      'IMPLEMENT-ME',
      'Copy file from DB to DB not supported yet: ' || $file || ', ' || $dest
         || ', please report this to the mailing list.')
};

(:~
 : Remove a repository from the config.
 :
 : If $delete is true, all content of the repo is deleted from the database.
 :
 : Throw 'container-not-exist' if the given container ID does not exist.
 :
 : Throw 'repo-on-disk' if the repository attached to the container is on disk
 : and $delete is true.
 :)
declare function cfg:remove-container($id as xs:string, $delete as xs:boolean)
   as empty-sequence()
{
   let $ref := cfg:get-container-ref($id)
   return
      if ( fn:empty($ref) ) then
         t:error('container-not-exist', 'The web container ''' || $id || ''' does not exist.')
      else
         let $container := cfg:get-container($ref)
         return
            if ( fn:empty($container) ) then (
               t:error(
                  'config-corrupted',
                  'Config file has a reference to container ''' || $id
                     || ''' but it does not exist?!?')
            )
            else if ( $delete ) then (
               cfg:remove-repo($container/w:repo, $delete),
               cfg:remove-container-from-config($ref, $container)
            )
            else (
               cfg:remove-container-from-config($ref, $container)
            )
};

(:~
 : Remove the container element from the config file, in the correct database.
 :)
declare %private function cfg:remove-container-from-config(
   $ref       as element(c:container),
   $container as element(w:container)
) as empty-sequence()
{
   let $as-id                    := $container/xs:unsignedLong(@appserver)
   let $as                       := a:get-appserver($as-id)
   let $db-id                    := $as/a:db/xs:unsignedLong(@id)
   let $doc as element(w:config) := a:get-from-database($db-id, $cfg:web-config-docname, '')/*
   let $new-doc                  := t:remove-child($doc, $doc/w:container[@id eq $container/@id])
   let $dummy                    := a:insert-into-database($db-id, $cfg:web-config-docname, $new-doc)
   return
      xdmp:node-delete($ref)
};

(:~
 : Insert a new webapp in a given container config element.
 :
 : Throw 'c:container-not-exist' if the container does not exist in the webapp
 : config file in the database associated with this container App Server.
 :
 : Throw 'c:webapp-exists' if an application with the same root already exists.
 :
 : Return the application element itself.
 :)
declare function cfg:container-insert-new-webapp(
   $app       as element(w:application),
   $container as element(w:container)
) as element(w:application)
{
   let $db       := $container/w:db/xs:unsignedLong(@id)
   let $cfg-elem := a:get-from-database($db, $cfg:web-config-docname, '')/w:config
   let $cfg-cont := $cfg-elem/w:container[@id eq $container/@id]
   return
      if ( fn:empty($cfg-cont) ) then
         t:error(
            'container-not-exist',
            'The container ' || $container/@id || ' does not exists in the database '
               || xs:string($db) || '.')
      else if ( fn:exists($cfg-cont/w:application[@root eq $app/@root]) ) then
         t:error(
            'webapp-exists',
            'A webapp with root ' || $app/@root || ' already exists in the container '
                || $container/@id || ' in the database ' || xs:string($db) || '.')
      else
         let $config := t:remove-child($cfg-elem, $cfg-cont)
         let $config := t:add-last-child($config, t:add-last-child($container, $app))
         let $dummy  := a:insert-into-database($db, $cfg:web-config-docname, $config)
         return
            $app
};

(:~
 : Remove the webapp element from the config file, in the correct database.
 :)
declare function cfg:remove-webapp-from-config(
   $app as element(w:application)
) as empty-sequence()
{
   let $container as element(w:container) :=
         t:remove-child($app/.., $app)
   let $as-id   := $container/xs:unsignedLong(@appserver)
   let $as      := a:get-appserver($as-id)
   let $db-id   := $as/a:db/xs:unsignedLong(@id)
   let $doc as element(w:config) :=
         a:get-from-database($db-id, $cfg:web-config-docname, '')/*
   let $wrk-doc := t:remove-child($doc, $doc/w:container[@id eq $container/@id])
   let $new-doc := t:add-last-child($wrk-doc, $container)
   let $dummy   := a:insert-into-database($db-id, $cfg:web-config-docname, $new-doc)
   return
      ()
};

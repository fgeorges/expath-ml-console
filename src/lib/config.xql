xquery version "1.0";

(:~
 : Library to access the configuration.
 : 
 : The setup document URI is: http://expath.org/coll/console/config.xml.  Its
 : content looks like the following:
 :
 :     <config xmlns="http://expath.org/ns/ml/console">
 :        <repo name="xxx">
 :           <root>path/relative/to/db/root</root>
 :           <database id="123">Modules</database>
 :           <packages-doc>path/relative/to/db/root/.expath-pkg/packages.xml</packages-doc>
 :        </repo>
 :        <repo name="yyy">
 :           <root>path/relative/to/dir</root>
 :           <directory>/Users/fgeorges/...</directory>
 :           <absolute>/Users/fgeorges/.../path/relative/to/dir</absolute>
 :           <packages-file>/Users/fgeorges/.../path/relative/to/dir/.expath-pkg/packages.xml</packages-file>
 :        </repo>
 :     </config>
 : 
 : TODO: Can we cache the database IDs instead of their names?
 : 
 : TODO: Do we have to behave differently with on-disk databases? (for instance
 : the default Modules database)
 :)
module namespace cfg = "http://expath.org/ns/ml/console/config";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "admin.xql";
import module namespace r = "http://expath.org/ns/ml/console/repo"  at "repo.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "tools.xql";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

(: TODO: Nothing should depend on this namespace here, move it to repo.xql or similar... :)
declare namespace pp = "http://expath.org/ns/repo/packages";

declare variable $cfg:config-docname :=
   "http://expath.org/coll/console/config.xml";

declare function cfg:is-setup()
   as xs:boolean
{
   fn:doc-available($cfg:config-docname)
};

declare function cfg:get-config()
   as element(c:config)?
{
   fn:doc($cfg:config-docname)/*
};

declare function cfg:get-repos()
   as element(c:repo)*
{
   cfg:get-config()/c:repo
};

declare function cfg:get-repo($name as xs:string)
   as element(c:repo)*
{
   cfg:get-config()/c:repo[@name eq $name]
};

declare function cfg:get-cxan-site()
   as xs:string?
{
   cfg:get-config()/c:cxan/fn:string(c:site)
};

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
) as xs:boolean
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
) as xs:boolean
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
 :)
declare function cfg:insert-new-repo($repo as element(c:repo))
   as xs:boolean
{
   if ( fn:exists(cfg:get-repo($repo/@name)) ) then (
      fn:false()
   )
   else if ( cfg:is-setup() ) then (
      xdmp:node-insert-child(cfg:get-config(), $repo),
      fn:true()
   )
   else (
      xdmp:document-insert(
         $cfg:config-docname,
         <config xmlns="http://expath.org/ns/ml/console">
            <cxan>
               <site>http://test.cxan.org/</site>
            </cxan>
            { $repo }
         </config>),
      fn:true()
   )
};

(:~
 : Return the new URI of the CXAN site.
 :
 : If the config file does not exist yet, this is an error.
 :)
declare function cfg:set-cxan-site($site as xs:string)
   as xs:string
{
   if ( fn:not(cfg:is-setup()) ) then (
      t:error('CFG001', 'Impossible to set the CXAN site before configuring at least one repo.')
   )
   else if ( fn:empty(cfg:get-config()/c:cxan/c:site) ) then (
      t:error('CFG002', 'Config file does not have a CXAN site?!?')
   )
   else (
      xdmp:node-replace(
         cfg:get-config()/c:cxan/c:site,
         <site xmlns="http://expath.org/ns/ml/console">{ $site }</site>),
      $site
   )
};

(:~
 : Forget about a previously created repository.
 :
 : Return true if the repo exists and has been forgotten, false if it does not
 : exist.
 :)
declare function cfg:forget-repo($name as xs:string, $remove as xs:boolean)
   as xs:boolean
{
   let $repo := cfg:get-repo($name)
   return
      if ( fn:empty($repo) ) then (
         fn:false()
      )
      else if ( $remove and r:is-filesystem-repo($repo) ) then (
         fn:false()
      )
      else if ( $remove ) then (
         xdmp:node-delete($repo),
         a:remove-directory($repo/c:database/@id, $repo/c:root),
         fn:true()
      )
      else (
         xdmp:node-delete($repo),
         fn:true()
      )
};

xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare option xdmp:update "true";

declare function local:page()
   as element()+
{
   (: TODO: Check the parameters have been passed, to avoid XQuery errors! :)
   (: (turn them into human-friendly errors instead...) :)
   (: And validate them! (for instance is $id a lexical NCName?) :)
   let $id    := t:mandatory-field('id')
   let $name  := t:mandatory-field('name')
   let $root  := t:mandatory-field('root')
   let $do-as := t:optional-field('create-as', ())
   let $do-db := t:optional-field('create-db', ())
   return (
      if ( $do-as ) then
         let $as-param  := t:mandatory-field('appserver')
         let $as-id     := xs:unsignedLong($as-param)
         let $appserver := a:get-appserver($as-id)
         return
            local:create-repo-in-appserver($id, $name, $root, $appserver)
      else if ( $do-db ) then
         let $db-param := t:mandatory-field('database')
         let $db-id    := xs:unsignedLong($db-param)
         let $db       := a:get-database($db-id)
         return
            local:create-repo-in-database($id, $name, $root, $db)
      else
         t:error('SETUP001', 'Create neither a database nor an appserver?!?'),
      <p>Back to <a href="../repo">repositories</a>.</p>
   )
};

(:~
 : TODO: ...
 : TODO: Duplicated in web/create.xq, factorize out! Probably in lib/admin.xql?
 :)
declare function local:create-repo-in-appserver(
   $id   as xs:string,
   $name as xs:string,
   $root as xs:string,
   $as   as element(a:appserver)
) as element(h:p)+
{
   if ( fn:exists($as/a:modules-path) ) then
      local:create-repo-in-directory($id, $name, $root, $as/a:modules-path)
   else if ( fn:exists($as/a:modules-db) ) then
      (: TODO: Should we adapt the root to take DB's root in the AppServer? :)
      let $db-id := xs:unsignedLong($as/a:modules-db/@id)
      let $db    := a:get-database($db-id)
      return
         local:create-repo-in-database($id, $name, $root, $db)
   else
      t:error('SETUP002', ('How can I have a WebDAV appserver here?!?: ', xdmp:quote($as)))
};

(:~
 : TODO: ...
 : TODO: Duplicated in web/create.xq, factorize out! Probably in lib/admin.xql?
 :)
declare function local:create-repo-in-database(
   $id   as xs:string,
   $name as xs:string,
   $root as xs:string,
   $db   as element(a:database)
) as element(h:p)+
{
   let $db-id   := $db/fn:string(@id)
   let $db-name := $db/fn:string(a:name)
   let $res     := cfg:create-repo-in-database($id, $name, $root, $db-id, $db-name)
   return
      if ( $res ) then
         <p>The new repository '{ $id }' has been successfully created in
            database '{ $db-name }', at root '{ $root }'.</p>
      else
         <p><b>Error</b>: Cannot create the repository '{ $id }' in
            database '{ $db-name }', at root '{ $root }': the repository
            '<b>{ $id }</b>' already exists!  If you want to override it,
            you must delete it first.</p>
};

(:~
 : TODO: ...
 : TODO: Duplicated in web/create.xq, factorize out! Probably in lib/admin.xql?
 :)
declare function local:create-repo-in-directory(
   $id   as xs:string,
   $name as xs:string,
   $root as xs:string,
   $dir  as xs:string
) as element(h:p)+
{
   let $res := cfg:create-repo-in-directory($id, $name, $root, $dir)
   return
      if ( $res ) then
         <p>The new repository '{ $id }' has been successfully created in
            directory '{ $dir }', at root '{ $root }'.</p>
      else
         <p><b>Error</b>: Cannot create the repository '{ $id }' in
            directory '{ $dir }', at root '{ $root }': the repository
            '<b>{ $id }</b>' already exists!  If you want to override it,
            you must delete it first.</p>
};

v:console-page('../', 'pkg', 'Repositories', local:page#0)

xquery version "1.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "lib/admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:create-repo-in-appserver(
   $name as xs:string,
   $root as xs:string,
   $as   as element(a:appserver)
) as element(h:p)+
{
   if ( fn:exists($as/a:modules-path) ) then
      local:create-repo-in-directory($name, $root, $as/a:modules-path)
   else if ( fn:exists($as/a:modules-db) ) then
      (: TODO: Should we adapt the root to take DB's root in the AppServer? :)
      let $id := xs:unsignedLong($as/a:modules-db/@id)
      let $db := a:get-database($id)
      return
         local:create-repo-in-database($name, $root, $db)
   else
      t:error('SETUP002', ('How can I have a WebDAV appserver here?!?: ', xdmp:quote($as)))
};

declare function local:create-repo-in-database(
   $name as xs:string,
   $root as xs:string,
   $db   as element(a:database)
) as element(h:p)+
{
   let $db-id   := $db/fn:string(@id)
   let $db-name := $db/fn:string(a:name)
   let $res     := cfg:create-repo-in-database($name, $root, $db-id, $db-name)
   return
      if ( $res ) then
         <p>The new repository '{ $name }' has been successfully created in
            database '{ $db-name }', at root '{ $root }'.</p>
      else
         <p><b>Error</b>: Cannot create the repository '{ $name }' in
            database '{ $db-name }', at root '{ $root }': the repository
            '<b>{ $name }</b>' already exists!  If you want to override it,
            you must delete it first.</p>
};

declare function local:create-repo-in-directory(
   $name as xs:string,
   $root as xs:string,
   $dir  as xs:string
) as element(h:p)+
{
   let $res := cfg:create-repo-in-directory($name, $root, $dir)
   return
      if ( $res ) then
         <p>The new repository '{ $name }' has been successfully created in
            directory '{ $dir }', at root '{ $root }'.</p>
      else
         <p><b>Error</b>: Cannot create the repository '{ $name }' in
            directory '{ $dir }', at root '{ $root }': the repository
            '<b>{ $name }</b>' already exists!  If you want to override it,
            you must delete it first.</p>
};

(: TODO: Check the parameters have been passed, to avoid XQuery errors! :)
(: (turn them into human-friendly errors instead...) :)
(: And validate them! (for instance is $name a lexical NCName?) :)
let $name  := t:mandatory-field('name')
let $root  := t:mandatory-field('root')
let $do-as := t:optional-field('create-as', ())
let $do-db := t:optional-field('create-db', ())
return
   v:console-page(
      'setup',
      'Setup',
      if ( $do-as ) then
         let $as   := t:mandatory-field('appserver')
         let $id   := xs:unsignedLong($as)
         let $info := a:get-appserver($id)
         return
            local:create-repo-in-appserver($name, $root, $info)
      else if ( $do-db ) then
         let $db   := t:mandatory-field('database')
         let $id   := xs:unsignedLong($db)
         let $info := a:get-database($id)
         return
            local:create-repo-in-database($name, $root, $info)
      else
         t:error('SETUP001', 'Create neither a database nor an appserver?!?'))

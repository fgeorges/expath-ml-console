xquery version "1.0-ml";
(: TODO: Version "1.0-ml" needed because of the try/catch for WebDAV app servers.  To remove... :)

(:~
 : Library wrapping admin information retrieval and setting from MarkLogic.
 :)
module namespace a = "http://expath.org/ns/ml/console/admin";

import module namespace t     = "http://expath.org/ns/ml/console/tools"
   at "tools.xql";
import module namespace admin = "http://marklogic.com/xdmp/admin"
   at "/MarkLogic/admin.xqy";

declare namespace c = "http://expath.org/ns/ml/console";

(:~
 : Get a document from the database $db-id.
 :
 : The URI of the document is the relative URI $file resolved against the
 : absolute URI $root (which must end with a '/').
 :)
declare function a:get-from-database(
   $db-id as xs:unsignedLong,
   $root  as xs:string,
   $file  as xs:string
) as node()?
{
   a:eval-on-database(
      $db-id,
      'declare variable $path external;
       fn:doc($path)',
      (xs:QName('path'), fn:concat($root, $file)))
};

(:~
 : Insert a document into the database $db-id, at $uri.
 :
 : The return value is the URI of the document inserted.
 :)
declare function a:insert-into-database(
   $db-id as xs:unsignedLong,
   $uri   as xs:string,
   $doc   as node()
) as xs:string
{
   a:eval-on-database(
      $db-id,
      'declare namespace xdmp = "http://marklogic.com/xdmp";
       declare variable $uri external;
       declare variable $doc external;
       xdmp:document-insert($uri, $doc), $uri',
      (xs:QName('uri'), $uri, xs:QName('doc'), $doc))
};

(:~
 : Load a directory into the database $db-id from the filesystem, at $uri.
 :
 : The return value is the URI of the directory inserted.
 :)
declare function a:load-dir-into-database(
   $db-id   as xs:unsignedLong,
   $uri     as xs:string,
   $path    as xs:string,
   $include as xs:string?,
   $exclude as xs:string?
) as xs:string
{
   a:eval-on-database(
      $db-id,
      'declare namespace dir  = "http://marklogic.com/xdmp/directory";
       declare namespace xdmp = "http://marklogic.com/xdmp";
       declare variable $uri     external;
       declare variable $path    external;
       declare variable $include external;
       declare variable $exclude external;
       declare function local:matches($d, $r, $i, $e) {
         let $f := fn:concat($r, $d/dir:filename)
         return
            $d
               [$i eq "" or fn:matches($f, $i)]
               [$e eq "" or fn:not(fn:matches($f, $e))]
       };
       declare function local:load($u, $p, $r) {
         for $e in xdmp:filesystem-directory($p)/dir:entry[dir:type eq "directory" or local:matches(., $r, $include, $exclude)]
         return
            if ( $e/dir:type eq "file" ) then
               xdmp:document-load(
                  $e/dir:pathname,
                  <options xmlns="xdmp:document-load">
                     <uri>{ fn:string($u) }{ fn:string($e/dir:filename) }</uri>
                  </options>)
            else if ( $e/dir:type eq "directory" ) then
               local:load(fn:concat($u, $e/dir:filename, "/"), $e/dir:pathname, fn:concat($r, $e/dir:filename, "/"))
            else
               fn:error((), fn:concat("dir:type is neither directory nor file: ", $e/dir:type))
       };
       local:load($uri, $path, ""), $uri',
      (xs:QName('uri'), $uri,
       xs:QName('path'), $path,
       xs:QName('include'), ($include, '')[1],
       xs:QName('exclude'), ($exclude, '')[1]))
};

(:~
 : Load a directory into the database $db-id from a ZIP file, at $uri.
 :
 : The return value is the URI of the directory inserted.
 :)
declare function a:load-zipdir-into-database(
   $db-id as xs:unsignedLong,
   $uri   as xs:string,
   $zip   as binary()
) as xs:string
{
   a:eval-on-database(
      $db-id,
      'declare namespace xdmp = "http://marklogic.com/xdmp";
       declare namespace zip  = "xdmp:zip";
       declare variable $uri external;
       declare variable $zip external;
       declare function local:do-it() {
       for $part in xdmp:zip-manifest($zip)/zip:part/fn:string(.)
       where fn:not(fn:ends-with($part, "/")) (: skip dir entries :)
       return
          xdmp:document-insert(
             fn:concat($uri, $part),
             xdmp:zip-get($zip, $part))
       };
       local:do-it(), $uri',
      (xs:QName('uri'), $uri, xs:QName('zip'), $zip))
};

declare function a:eval-on-database(
   $db-id  as xs:unsignedLong,
   $query  as xs:string,
   $params as item()*
) as item()*
{
   xdmp:eval(
      $query,
      $params,
      <options xmlns="xdmp:eval">
         <database>{ $db-id }</database>
      </options>)
};

(:~
 : Get a document from the filesystem.
 :
 : The path of the document is the relative $file path resolved in the
 : absolute $dir (which must end with a '/').
 :
 : TODO: For now, parse the file, but it should support binaries and text files.
 :)
declare function a:get-from-directory(
   $dir  as xs:string,
   $file as xs:string
) as node()?
{
   xdmp:unquote(
      xdmp:filesystem-file(
         fn:concat($dir, $file)))
};

(:~
 : Create a document on the filesystem.
 :
 : The path of the document is the relative $file path resolved in the
 : absolute $dir (which must end with a '/').
 :
 : The return value is the path of the document created.
 :)
declare function a:insert-into-directory(
   $dir  as xs:string,
   $file as xs:string,
   $doc  as node()
) as xs:string
{
   let $path   := fn:concat($dir, $file)
   let $parent := t:dirname($path)
   return (
      t:ensure-dir($parent),
      xdmp:save($path, $doc),
      $path
   )
};

(:~
 : Return a specific application server.  The result is an element looking like:
 :
 :     <appserver id="123" xmlns="http://expath.org/ns/ml/console/admin">
 :        <name>Admin</name>
 :        <db id="456">Documents</db>
 :        <modules-db id="789">Modules</modules-db>
 :        <modules-path>/home/my/modules/</modules-path>
 :        <root>Admin/</root>
 :     </appserver>
 : 
 : The elements modules-db and modules-path are mutually exclusive, and are
 : optional.  If none is present, this is a WebDAV server, if modules-db is
 : present, its value is the ID of the app server modules database.  If
 : modules-path is present, its value is the absolute path to the directory
 : where the modules are stored for the app server.
 : 
 : TODO: Representing app servers all the same way is nonsense.  Create 3
 : different functions: for HTTP servers, XDBC servers, and WebDAV servers.
 :)
declare function a:get-appserver($as as xs:unsignedLong)
   as element(a:appserver)
{
   let $config := admin:get-configuration()
   let $db := admin:appserver-get-database($config, $as)
   let $mdb :=
            try {
               (: WebDAV ASs do not have a module DB:)
               (: TODO: How to retrieve the type of a server programmatically? :)
               admin:appserver-get-modules-database($config, $as)
            }
            catch ( $err ) {
               ()
            }
   return
      <a:appserver id="{ $as }">
         <a:name>{ admin:appserver-get-name($config, $as) }</a:name>
         <a:db id="{ $db }">{ admin:database-get-name($config, $db) }</a:db>
         {
            if ( fn:empty($mdb) ) then
               ()
            else if ( $mdb eq 0 ) then
               (: TODO: Resolve the path when it is on file system and relative... :)
               <a:modules-path>{ admin:appserver-get-root($config, $as) }</a:modules-path>
            else
               <a:modules-db id="{ $mdb }">{ admin:database-get-name($config, $mdb) }</a:modules-db>
         }
         <a:root>{ admin:appserver-get-root($config, $as) }</a:root>
      </a:appserver>
};

(:~
 : Return the application servers.  The result is an element looking like:
 :
 :     <appservers xmlns="http://expath.org/ns/ml/console/admin">
 :        ...
 :        { several elements returned by a:get-appserver($as) }
 :        ...
 :     </appservers>
 :
 : TODO: Representing app servers all the same way is nonsense.  Create 3
 : different functions: for HTTP servers, XDBC servers, and WebDAV servers.
 :)
declare function a:get-appservers()
   as element(a:appservers)
{
   <a:appservers> {
      let $config := admin:get-configuration()
      for $as in admin:get-appserver-ids($config)
      return
         a:get-appserver($as)
   }
   </a:appservers>
};

(:~
 : Return a specific database.  The result is an element looking like:
 :
 :     <database id="123" xmlns="http://expath.org/ns/ml/console/admin">
 :        <name>Admin</name>
 :     </databases>
 :)
declare function a:get-database($db as xs:unsignedLong)
   as element(a:database)
{
   let $config := admin:get-configuration()
   return
      <a:database id="{ $db }">
         <a:name>{ admin:database-get-name($config, $db) }</a:name>
      </a:database>
};

(:~
 : Return the databases.  The result is an element looking like:
 :
 :     <databases xmlns="http://expath.org/ns/ml/console/admin">
 :        <database id="123">
 :           <name>Admin</name>
 :        </database>
 :        ...
 :     </databases>
 :)
declare function a:get-databases()
   as element(a:databases)
{
   <a:databases> {
      let $config := admin:get-configuration()
      for $db in admin:get-database-ids($config)
      return
         a:get-database($db)
   }
   </a:databases>
};

(:~
 : Return a specific database or application server.
 :
 : If the ID passed as parameter is the ID of an existing database, then return
 : that database.  If the ID passed as parameter is the ID of an existing app
 : server, then return that app server.  If it identifies at the same time both
 : a database and an app server (which I don't think is possible), throw an
 : error.  If neither can be found, return the empty sequence.
 : 
 :     <database id="123" xmlns="http://expath.org/ns/ml/console/admin">
 :        <name>Admin</name>
 :     </databases>
 :)
declare function a:get-appserver-or-database($id as xs:unsignedLong)
   as element()?
{
   let $config := admin:get-configuration()
   let $dbs := admin:get-database-ids($config)
   let $ass := admin:get-appserver-ids($config)
   return
      if ( $id = $dbs and $id = $ass ) then
         t:error('ADMIN001', ('The id is for both a database and an app server: ', $id))
      else if ( $id = $dbs ) then
         a:get-database($id)
      else if ( $id = $ass ) then
         a:get-appserver($id)
      else
         ()
};

(:~
 : Remove a directory on a database, recursively.
 :)
declare function a:remove-directory($db-id as xs:unsignedLong, $dir as xs:string)
{
   a:eval-on-database(
      $db-id,
      'declare variable $dir external;
       xdmp:directory($dir, "infinity")/xdmp:document-delete(fn:document-uri(.))',
      (xs:QName('dir'), $dir))
};

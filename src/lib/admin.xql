xquery version "3.0";

(:~
 : Library wrapping admin information retrieval and setting from MarkLogic.
 :)
module namespace a = "http://expath.org/ns/ml/console/admin";

import module namespace t     = "http://expath.org/ns/ml/console/tools"
   at "tools.xql";
import module namespace admin = "http://marklogic.com/xdmp/admin"
   at "/MarkLogic/admin.xqy";

declare namespace c     = "http://expath.org/ns/ml/console";
declare namespace dir   = "http://marklogic.com/xdmp/directory";
declare namespace err   = "http://www.w3.org/2005/xqt-errors";
declare namespace mlerr = "http://marklogic.com/xdmp/error";
declare namespace pkg   = "http://expath.org/ns/pkg";
declare namespace pp    = "http://expath.org/ns/repo/packages";
declare namespace map   = "http://marklogic.com/xdmp/map";
declare namespace mlpkg = "http://marklogic.com/ns/expath-pkg";
declare namespace xdmp  = "http://marklogic.com/xdmp";
declare namespace cts   = "http://marklogic.com/cts";
declare namespace zip   = "xdmp:zip";

(: Non-configurable for now... :)
declare variable $repo-root := 'expath-repo/';
declare variable $packages-file-path := '.expath-pkg/packages.xml';
declare variable $attic-path := '.expath-pkg/attic/';

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Database tools
 :
 : Tools related to databases:
 :
 : - evaluate code on a specific database
 : - read documents from a specific database
 : - write documents to a specific database
 :)

(:~
 : Return a database ID.
 :
 : If `$db` is an xs:unsignedLong, it is returned as is.  If it is an a:database
 : element, its `@id` is returned.  If it is neither, it then must be the name
 : of a database, which is then resolved to an ID (if such a database does not
 : exist, the empty sequence is returned).
 :)
declare function a:database-id($db as item()) as xs:unsignedLong?
{
   if ( $db instance of element(a:database) ) then
      xs:unsignedLong($db/@id)
   else if ( $db castable as xs:unsignedLong ) then
      xs:unsignedLong($db)
   else
      t:catch-ml('XDMP-NOSUCHDB', function() {
         xdmp:database($db)
      })
};

(:~
 : Invoke the function on the given database.
 :)
declare function a:query-database(
   $db  as item(),
   $fun as function() as item()*
) as item()*
{
   xdmp:invoke-function(
      $fun,
      <options xmlns="xdmp:eval">
         <database>{ a:database-id($db) }</database>
      </options>)
};

(:~
 : Invoke the function on the given database, in update transaction mode.
 :)
declare function a:update-database(
   $db  as item(),
   $fun as function() as item()*
) as item()*
{
   xdmp:invoke-function(
      $fun,
      <options xmlns="xdmp:eval">
         <database>{ a:database-id($db) }</database>
         <transaction-mode>update-auto-commit</transaction-mode>
      </options>)
};

(:~
 : Eval the query on the given database, with the given parameters.
 :)
declare function a:eval-on-database(
   $db     as item(),
   $query  as xs:string,
   $params as map:map
) as item()*
{
   xdmp:eval(
      $query,
      $params,
      <options xmlns="xdmp:eval">
         <database>{ a:database-id($db) }</database>
      </options>)
};

(:~
 : Check whether `$doc` is available on the database `$db`.
 :)
declare function a:exists-on-database(
   $db  as item(),
   $doc as xs:string
) as xs:boolean
{
   a:eval-on-database(
      a:database-id($db),
      'declare variable $doc external;
       fn:doc-available($doc)',
      map:entry('doc', $doc))
};

(:~
 : Get a document from the database `$db`.
 :
 : The URI of the document is the absolute URI `$uri`.
 :)
declare function a:get-from-database(
   $db  as item(),
   $uri as xs:string
) as node()?
{
   a:eval-on-database(
      a:database-id($db),
      'declare variable $uri external;
       fn:doc($uri)',
      map:entry('uri', $uri))
};

(:~
 : Get a document from the database `$db`.
 :
 : The URI of the document is the relative URI `$file` resolved against the
 : absolute URI `$root` (which must end with a '/').
 :)
declare function a:get-from-database(
   $db   as item(),
   $root as xs:string,
   $file as xs:string
) as node()?
{
   a:get-from-database($db, $root || $file)
};

(:~
 : Insert a document into the database $db-id, at $uri.
 :
 : The return value is the URI of the document inserted.
 :
 : TODO: On a database with "directory creation" set to "manual-emforced", this
 : should fail if one directory (in the path to the document) does not exist.
 : The solution is to ensure all parents exist or create them.
 :)
declare function a:insert-into-database(
   $db  as item(),
   $uri as xs:string,
   $doc as node()
) as xs:string
{
   a:eval-on-database(
      $db,
      'declare namespace xdmp = "http://marklogic.com/xdmp";
       declare variable $uri external;
       declare variable $doc external;
       xdmp:document-insert($uri, $doc), $uri',
      map:new((
         map:entry('uri', $uri),
         map:entry('doc', $doc))))
};

(:~
 : Load a directory into the database $db-id from the filesystem, at $uri.
 :
 : The return value is the URI of the directory inserted.
 :)
declare function a:load-dir-into-database(
   $db      as item(),
   $uri     as xs:string,
   $path    as xs:string,
   $include as xs:string?,
   $exclude as xs:string?
) as xs:string
{
   a:eval-on-database(
      $db,
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
      map:new((
         map:entry('uri',     $uri),
         map:entry('path',    $path),
         map:entry('include', ($include, '')[1]),
         map:entry('exclude', ($exclude, '')[1]))))
};

(:~
 : Load a directory into the database $db-id from a ZIP file, at $uri.
 :
 : The return value is the URI of the directory inserted.
 :)
declare function a:load-zipdir-into-database(
   $db     as item(),
   $uri    as xs:string,
   $zip (: as binary() :)
) as xs:string
{
   a:eval-on-database(
      $db,
      'declare namespace xdmp = "http://marklogic.com/xdmp";
       declare namespace zip  = "xdmp:zip";
       declare variable $uri external;
       declare variable $zip external;
       declare function local:do-it() {
          for $part in xdmp:zip-manifest($zip)/zip:part/fn:string(.)
          (: encode each path part individually :)
          let $path := fn:string-join(fn:tokenize($part, "/") ! fn:encode-for-uri(.), "/")
          (: skip dir entries :)
          where fn:not(fn:ends-with($part, "/"))
          return
             xdmp:document-insert(
                fn:concat($uri, $path),
                xdmp:zip-get($zip, $part))
       };
       local:do-it(),
       $uri',
      map:new((
         map:entry('uri', $uri),
         map:entry('zip', $zip))))
};

(:~
 : Remove a document on a database.
 :)
declare function a:remove-doc($db as item(), $uri as xs:string)
{
   a:eval-on-database(
      $db,
      'declare namespace xdmp = "http://marklogic.com/xdmp";
       declare variable $uri external;
       xdmp:document-delete($uri)',
      map:entry('uri', $uri))
};

(:~
 : Remove documents and directories on a database.
 :
 : @param db   The database.
 : @param docs The URIs of the documents to delete.
 : @param dirs The URIs of the directories to delete.
 :)
declare function a:remove-docs-and-dirs($db as item(), $docs as xs:string*, $dirs as xs:string*)
{
   a:update-database($db, function() {
      $docs ! xdmp:document-delete(.),
      $dirs ! (. || '*') ! cts:uri-match(.) ! xdmp:document-delete(.)
   })
};

(:~
 : Remove a directory on a database, recursively.
 :
 : Note: Keep in mind that a directory name ends with '/', and that a URI ending
 : with '/' is not the same as the one without the leading '/'.
 :
 : TODO: For now, use xdmp:directory($pkgdir, 'infinity') to get the URI of all
 : the documents.  Is it possible to remove directories as well? (with their
 : property document, everything...)
 :
 : @todo For now, use xdmp:directory($pkgdir, 'infinity') to get the URI of all
 : the documents.  Is it possible to remove directories as well? (with their
 : property document, everything...)
 :)
declare function a:remove-directory($db as item(), $dir as xs:string)
{
   if ( fn:ends-with($dir, '/') ) then
      a:eval-on-database(
         $db,
         'declare namespace xdmp = "http://marklogic.com/xdmp";
          declare variable $dir external;
          xdmp:directory($dir, "infinity")/xdmp:document-delete(fn:document-uri(.))',
         map:entry('dir', $dir))
   else
      t:error('not-dir', 'The directory URI does not end with a forward slash: ' || $dir)
};

(:~
 : Return the value of the option `directory-creation` for `$db`.
 :
 : TODO: Add the flag to the element `a:database`, as it is used somewhere in
 : the application?
 :)
declare function a:database-dir-creation($db as item())
   as xs:string
{
   admin:database-get-directory-creation(
      admin:get-configuration(),
      a:database-id($db))
};

(:~
 : Deep browse directory, visiting only files.
 :)
declare function a:browse-db-files(
   $db   as item(),
   $path as xs:string,
   $fn   as function(xs:string) as item()*
) as item()*
{
   a:query-database($db, function() {
      cts:uri-match($path || '*')
         [fn:not(fn:ends-with(., '/'))]
         ! $fn(.)
   })
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Filesystem tools
 :
 : Tools related to accessing the filesystem:
 :
 : - read documents from the filesystem
 : - write documents to the filesystem
 :)

(:~
 : Get a raw file from the filesystem.
 :
 : Return the empty sequence if the file does not exist.
 :
 : $file the absolute path of the file
 :)
declare function a:get-from-filesystem($file  as xs:string) as xs:string?
{
   t:catch-ml('SVC-FILOPN', function() {
      (: the "true predicate" prevents the expression to be rewritten
         "outside the try/catch" by the optimizer
         TODO: Still needed with the anonymous function? :)
      xdmp:filesystem-file($file)[fn:true()]
   })
};

(:~
 : Return a MarkLogic filesystem directory descriptor.
 :
 : Return the empty sequence if the directory does not exist.
 :
 : $dir the absolute path of the directory
 :)
declare function a:get-directory($dir as xs:string) as element(dir:directory)?
{
   t:catch-ml('SVC-DIROPEN', function() {
      xdmp:filesystem-directory($dir)
   })
};

(:~
 : Get a document from the filesystem.
 :
 : $file the absolute path of the file
 : $parse true if the file is XML and must be parsed
 :
 : TODO: Support binary files as well.  Replace $parse by a flag kind of
 : parameter.  If 'xml', then xdmp:unquote(...), if 'text' then text{...}, and
 : if 'bin' then binary{...}.
 :)
declare function a:get-from-filesystem(
   $file  as xs:string,
   $parse as xs:boolean
) as node()?
{
   let $raw := a:get-from-filesystem($file)
   return
      if ( fn:empty($raw) ) then
         ()
      else if ( $parse ) then
         xdmp:unquote($raw)
      else
         text { $raw }
};

(:~
 : Get a document from the filesystem.
 :
 : The path of the document is the relative $file path resolved in the
 : absolute $dir (which must end with a '/').
 :)
declare function a:get-from-directory(
   $dir   as xs:string,
   $file  as xs:string,
   $parse as xs:boolean
) as node()?
{
   a:get-from-filesystem(
      fn:concat($dir, $file),
      $parse)
};

(:~
 : Create a document on the filesystem.
 :
 : @param $file the absolute path of the file.
 : @param $doc the document to save, either a document, an element or a text node.
 :
 : @return The path of the document created.
 :)
declare function a:insert-into-filesystem(
   $file as xs:string,
   $doc  as node()
) as xs:string
{
   a:insert-into-filesystem($file, $doc, ())
};

(:~
 : Create a document on the filesystem.
 : 
 : Options supported:
 :
 : - `indent`: indent the XML when serialized to the file.
 : 
 : @param $file The absolute path of the file.
 : @param $doc The document to save, either a document, an element or a text node.
 : @param $options The options supported are described above.
 :
 : @return The path of the document created.
 :)
declare function a:insert-into-filesystem(
   $file    as xs:string,
   $doc     as node(),
   $options as xs:string*
) as xs:string
{
   t:ensure-dir(t:dirname($file)),
   xdmp:save($file, $doc,
      <options xmlns="xdmp:save"> {
         for $o in $options return
            switch ( $o )
               case 'indent' return (
                  <indent>yes</indent>,
                  <indent-untyped>yes</indent-untyped>
               )
               default return (
                  t:error('not-supported', 'Option not supported: ' || $o)
               )
      }
      </options>),
   $file
};

(:~
 : Create a document on the filesystem.
 : 
 : Same as `a:insert-into-filesystem#2`, except the file path is given as a
 : directory path and a file path relative to it (the directory one must end
 : with a '/').
 :)
declare function a:insert-into-directory(
   $dir  as xs:string,
   $file as xs:string,
   $doc  as node()
) as xs:string
{
   a:insert-into-filesystem($dir || $file, $doc)
};

(:~
 : Create a document on the filesystem.
 : 
 : Same as `a:insert-into-filesystem#3`, except the file path is given as a
 : directory path and a file path relative to it (the directory one must end
 : with a '/').
 :)
declare function a:insert-into-directory(
   $dir     as xs:string,
   $file    as xs:string,
   $doc     as node(),
   $options as xs:string*
) as xs:string
{
   a:insert-into-filesystem($dir || $file, $doc, $options)
};

(:~
 : Return `true` if the file exists.
 :)
declare function a:file-exists($path as xs:string)
   as xs:boolean
{
   xdmp:filesystem-file-exists($path)
};

(:~
 : Deep browse directory, visiting only directories.
 :)
declare function a:browse-directories(
   $path as xs:string,
   $fn   as function(xs:string) as item()*
) as item()*
{
   $fn($path),
   a:get-directory($path)
      / dir:entry[dir:type eq 'directory']
      ! a:browse-directories(dir:pathname || '/', $fn)
};

(:~
 : Deep browse directory, visiting only files.
 :)
declare function a:browse-files(
   $path as xs:string,
   $fn   as function(xs:string) as item()*
) as item()*
{
   a:browse-directories($path, function($dir) {
      a:get-directory($dir)
         / dir:entry[dir:type eq 'file']
         ! $fn(dir:pathname)
   })
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Security tools
 :
 : Access components from the security model.
 :)

(:~
 : Evaluate a query on the security database of the current database.
 :
 : This is needed by most functions in the MarkLogic sec:* library.
 :)
declare function a:eval-on-security-db(
   $query  as xs:string,
   $params as map:map
) as item()*
{
   a:eval-on-database(
      xdmp:security-database(),
      $query,
      $params)
};

(:~
 : Evaluate a query on the security database of the `$db` database.
 :
 : This is needed by most functions in the MarkLogic sec:* library.
 :)
declare function a:eval-on-security-db(
   $db     as item(),
   $query  as xs:string,
   $params as map:map
) as item()*
{
   a:eval-on-database(
      xdmp:security-database(a:database-id($db)),
      $query,
      $params)
};

(:~
 : Return the name of a role, given its ID.  The scope is the current database.
 :)
declare function a:role-name($role as xs:unsignedLong)
   as xs:string
{
   a:eval-on-security-db(
      'import module namespace sec = "http://marklogic.com/xdmp/security"
          at "/MarkLogic/security.xqy";
       declare variable $role as xs:unsignedLong external;
       sec:get-role-names($role)',
      map:entry('role', $role))
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Admin entities
 :
 : Represent admin components as XML elements (roles, groups, app servers and
 : databases).
 :)

(:~
 : Return the roles on the current database.
 :)
declare function a:get-roles()
   as element(a:roles)
{
   <a:roles> {
      a:eval-on-security-db(
         'import module namespace sec = "http://marklogic.com/xdmp/security"
             at "/MarkLogic/security.xqy";
          declare namespace a = "http://expath.org/ns/ml/console/admin";
          let $ids  := sec:get-role-ids()
          for $name at $pos in sec:get-role-names($ids)
          return
             <a:role id="{ $ids[$pos] }">
                <a:name>{ $name }</a:name>
             </a:role>',
         map:new(()))
   }
   </a:roles>
};

(:~
 : Return a specific group.  The result is an element looking like:
 :
 :     <group id="123" xmlns="http://expath.org/ns/ml/console/admin">
 :        <name>Admin</name>
 :     </group>
 :)
declare function a:get-group($grp as xs:unsignedLong)
   as element(a:group)
{
   let $config := admin:get-configuration()
   return
      <a:group id="{ $grp }">
         <a:name>{ admin:group-get-name($config, $grp) }</a:name>
      </a:group>
};

(:~
 : Return the groups.  The result is an element looking like:
 :
 :     <groups xmlns="http://expath.org/ns/ml/console/admin">
 :        ...
 :        { several elements returned by a:get-group($grp) }
 :        ...
 :     </appservers>
 :)
declare function a:get-groups()
   as element(a:groups)
{
   <a:groups> {
      let $config := admin:get-configuration()
      for $grp in admin:get-group-ids($config)
      return
         a:get-group($grp)
   }
   </a:groups>
};

(:~
 : Return a specific application server.  The result is an element looking like:
 :
 :     <!-- when the modules are on the file system -->
 :     <appserver id="123" xmlns="http://expath.org/ns/ml/console/admin">
 :        <name>Admin</name>
 :        <db id="456">Documents</db>
 :        <modules-path>/home/my/modules/</modules-path>
 :        <root>/home/my/modules/</root>
 :     </appserver>
 : 
 :     <!-- when the modules are on a database -->
 :     <appserver id="123" xmlns="http://expath.org/ns/ml/console/admin">
 :        <name>Admin</name>
 :        <db id="456">Documents</db>
 :        <modules-db id="789">Modules</modules-db>
 :        <root>Admin/</root>
 :     </appserver>
 : 
 :     <!-- when the modules are on the file system, with a package repo -->
 :     <appserver id="123" xmlns="http://expath.org/ns/ml/console/admin">
 :        <name>Admin</name>
 :        <db id="456">Documents</db>
 :        <modules-path>/home/my/modules/</modules-path>
 :        <root>/home/my/modules/</root>
 :        <repo>
 :           <root>/home/my/modules/expath-repo/</root>
 :           <root-relative>expath-repo/</root-relative>
 :           <packages-file>/home/my/modules/expath-repo/.expath-pkg/packages.xml</packages-file>
 :        </repo>
 :     </appserver>
 : 
 :     <!-- when the modules are on a database, with a package repo -->
 :     <appserver id="123" xmlns="http://expath.org/ns/ml/console/admin">
 :        <name>Admin</name>
 :        <db id="456">Documents</db>
 :        <modules-db id="789">Modules</modules-db>
 :        <root>Admin/</root>
 :        <repo>
 :           <root>Admin/expath-repo/</root>
 :           <root-relative>expath-repo/</root-relative>
 :           <packages-file>Admin/expath-repo/.expath-pkg/packages.xml</packages-file>
 :        </repo>
 :     </appserver>
 : 
 : The elements `modules-db` and `modules-path` are mutually exclusive, and
 : are optional.  If none is present, this is a WebDAV server, if `modules-db`
 : is present, its value is the ID of the app server modules database.  If
 : `modules-path` is present, its value is the absolute path to the directory
 : where the modules are stored for the app server.
 :
 : The element `repo` is optional.  It is present when a package repository has
 : been initialized for the app server.  Its child element `root` is the
 : absolute path to the repository directory.  The element `root-relative` is
 : the same path, but relative to the app server's module root.  The element
 : `packages-file` is the absolute path to the repo's packages file.
 : 
 : TODO: Representing app servers all the same way is nonsense.  Create 3
 : different functions: for HTTP servers, XDBC servers, and WebDAV servers.
 :)
declare function a:get-appserver($as as xs:unsignedLong)
   as element(a:appserver)
{
   let $config := admin:get-configuration()
   let $db     := admin:appserver-get-database($config, $as)
   let $_root  := admin:appserver-get-root($config, $as)
   let $root   := if ( fn:ends-with($_root, '/') ) then $_root else $_root || '/'
   let $mdb    :=
            try {
               (: WebDAV ASs do not have a module DB :)
               (: TODO: How to retrieve the type of a server programmatically? :)
               (: TODO: Be sure to catch only this error! :)
               admin:appserver-get-modules-database($config, $as)
            }
            catch * {
               ()
            }
   let $pkgs   :=
            if ( fn:empty($mdb) ) then
               ()
            else if ( $mdb eq 0 ) then
               a:get-from-directory($root, $repo-root || $packages-file-path, fn:true())
            else
               a:get-from-database($mdb, $root, $repo-root || $packages-file-path)
   return
      <a:appserver id="{ $as }" type="{ admin:appserver-get-type($config, $as) }">
         <a:name>{ admin:appserver-get-name($config, $as) }</a:name>
         <a:port>{ admin:appserver-get-port($config, $as) }</a:port>
         <a:db id="{ $db }">{ admin:database-get-name($config, $db) }</a:db>
         {
            if ( fn:empty($mdb) ) then
               ()
            else if ( $mdb eq 0 ) then
               (: TODO: Resolve the path when it is on file system and relative... :)
               <a:modules-path>{ $root }</a:modules-path>
            else
               <a:modules-db id="{ $mdb }">{ admin:database-get-name($config, $mdb) }</a:modules-db>
         }
         {
            if ( fn:empty($pkgs) ) then
               ()
            else
               <a:repo>
                  <a:root>{ $root }{ $repo-root }</a:root>
                  <a:root-relative>{ $repo-root }</a:root-relative>
                  <a:packages-file>{ $root }{ $repo-root }{ $packages-file-path }</a:packages-file>
               </a:repo>
         }
         <a:root>{ $root }</a:root>
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
 : Return the app servers in the group.  The result is an element looking like:
 :
 :     <appservers group="123" xmlns="http://expath.org/ns/ml/console/admin">
 :        ...
 :        { several elements returned by a:get-appserver($as) }
 :        ...
 :     </appservers>
 :
 : TODO: Representing app servers all the same way is nonsense.  Create 3
 : different functions: for HTTP servers, XDBC servers, and WebDAV servers.
 :)
declare function a:get-appservers($group as element(a:group))
   as element(a:appservers)
{
   <a:appservers> {
      let $config := admin:get-configuration()
      for $as in admin:group-get-appserver-ids($config, $group/@id)
      return
         a:get-appserver($as)
   }
   </a:appservers>
};

(:~
 : Return a specific appserver by name.  The result is the same as `a:get-appserver()`.
 :
 : TODO: Isn't there a way to resolve an appserver ID by name?  Do I really have
 : instead to loop over all IDs, retrieve its name and see if it matches?
 : 
 : Use recursion to ensure we stop looking as soon as we found a match.
 :)
declare function a:get-appserver-by-name($name as xs:string)
   as element(a:appserver)?
{
   let $config := admin:get-configuration()
   return
      a:get-appserver-by-name-1(
         $name,
         admin:get-appserver-ids($config),
         $config)
};

(:~
 : Implements `a:get-appserver-by-name()`.
 :)
declare function a:get-appserver-by-name-1(
   $name   as xs:string,
   $ids    as xs:unsignedLong*,
   $config as element(configuration)
) as element(a:appserver)?
{
   if ( fn:empty($ids) ) then
      ()
   else if ( $name eq admin:appserver-get-name($config, fn:head($ids)) ) then
      a:get-appserver(fn:head($ids))
   else
      a:get-appserver-by-name-1($name, fn:tail($ids), $config)
};

(:~
 : TODO: ...
 :)
declare function a:set-url-rewriter-if-not-yet(
   $as   as element(a:appserver),
   $path as xs:string
) as empty-sequence()
{
   let $config := admin:get-configuration()
   let $id     := xs:unsignedLong($as/@id)
   return
      if ( fn:exists(admin:appserver-get-url-rewriter($config, $id)[.]) ) then
         ()
      else
         admin:save-configuration(
            admin:appserver-set-url-rewriter($config, $id, $path))
};

(:~
 : Return a specific database.  The result is an element looking like:
 :
 :     <database id="123" xmlns="http://expath.org/ns/ml/console/admin">
 :        <name>Admin</name>
 :     </databases>
 :
 : Return nothing if $db does not exist.
 :)
declare function a:get-database($db as item())
   as element(a:database)?
{
   if ( $db instance of element(a:database) ) then
      $db
   else
      let $id := a:database-id($db)
      return
         if ( fn:empty($id) ) then
            ()
         else
            let $config   := admin:get-configuration()
            let $schema   := admin:database-get-schema-database($config, $id)
            let $security := admin:database-get-security-database($config, $id)
            let $triggers := admin:database-get-triggers-database($config, $id)
            return
               <a:database id="{ $id }">
                  <a:name>{ admin:database-get-name($config, $id) }</a:name>
                  <a:triple-index>{ admin:database-get-triple-index($config, $id) }</a:triple-index>
                  <a:lexicons>
                     <a:uri>{ admin:database-get-uri-lexicon($config, $id) }</a:uri>
                     <a:coll>{ admin:database-get-collection-lexicon($config, $id) }</a:coll>
                  </a:lexicons>
                  {
                     if ( $schema ne 0 ) then
                        <a:schema id="{ $schema }">{ admin:database-get-name($config, $schema) }</a:schema>
                     else
                        (),
                     if ( $security ne 0 ) then
                        <a:security id="{ $security }">{ admin:database-get-name($config, $security) }</a:security>
                     else
                        (),
                     if ( $triggers ne 0 ) then
                        <a:triggers id="{ $triggers }">{ admin:database-get-name($config, $triggers) }</a:triggers>
                     else
                        ()
                  }
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
   let $dbs    := admin:get-database-ids($config)
   let $ass    := admin:get-appserver-ids($config)
   return
      if ( $id = $dbs and $id = $ass ) then
         t:error('non-unique-id', 'The id is for both a database and an app server: ' || $id)
      else if ( $id = $dbs ) then
         a:get-database($id)
      else if ( $id = $ass ) then
         a:get-appserver($id)
      else
         ()
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : App server packages
 :
 : Manage the packages on an app server (install them, uninstall them, list
 : them, etc.)
 :)

(:~
 : Return true if `$as` is a WebDAV app server.
 :)
declare function a:appserver-is-webdav($as as element(a:appserver))
   as xs:boolean
{
   fn:empty($as/(a:modules-db|a:modules-path))
};

(:~
 : Return true if `$as` has its modules stored in a database.
 :)
declare function a:appserver-modules-in-db($as as element(a:appserver))
   as xs:boolean
{
   fn:exists($as/a:modules-db)
};

(:~
 : Return true if a repository has been associated to `$as`.
 :)
declare function a:appserver-repo-initialized($as as element(a:appserver))
   as xs:boolean
{
   fn:exists($as/a:repo)
};

(:~
 : Get a file from the repository associated to `$as`.
 :
 : Throw `c:repo-not-initialized` if there is no repository associated to `$as`.
 :)
declare function a:appserver-get-from-repo(
   $file as xs:string,
   $as   as element(a:appserver)
) as node()?
{
   if ( fn:not(a:appserver-repo-initialized($as)) ) then
      t:error('repo-not-initialized', 'There is no repository associated to the app server: ' || $as/a:name)
   else if ( a:appserver-modules-in-db($as) ) then
      a:get-from-database($as/a:modules-db/@id, $as/a:repo/a:root, $file)
   else
      a:get-from-directory($as/a:repo/a:root, $file, fn:true())
};

(:~
 : Insert a file in the repository associated to `$as`.
 :
 : `$file` is the relative path to store the file (relative to the repository
 : root). It must be a valid URI reference (it must be relative, can contain '/',
 : and every other character has to be legal in a URI).
 :)
declare function a:appserver-insert-into-repo(
   $as   as element(a:appserver),
   $file as xs:string,
   $doc  as node()
) as xs:string
{
   if ( fn:not(a:appserver-repo-initialized($as)) ) then
      t:error('repo-not-initialized', 'There is no repository associated to the app server: ' || $as/a:name)
   else if ( a:appserver-modules-in-db($as) ) then
      a:insert-into-database($as/a:modules-db/@id, $as/a:repo/a:root || $file, $doc)
   else
      a:insert-into-directory($as/a:repo/a:root, $file, $doc)
};

(:~
 : Return the packages file from the repo associated to the app server, if any.
 :)
declare function a:appserver-get-packages($as as element(a:appserver))
   as element(pp:packages)?
{
   if ( fn:not(a:appserver-repo-initialized($as)) ) then
      ()
   else if ( a:appserver-modules-in-db($as) ) then
      a:get-from-database($as/a:modules-db/@id, $as/a:repo/a:packages-file)/*
   else
      a:get-from-filesystem($as/a:repo/a:packages-file, fn:true())/*
};

(:~
 : Return the package info for `$pkg/$version` in the repository associated to `$as`.
 :)
declare function a:appserver-get-package-by-name(
   $name    as xs:string,
   $version as xs:string,
   $as      as element(a:appserver)
) as element(pp:package)?
{
   a:appserver-get-packages($as)/pp:package[@name eq $name][@version eq $version]
};

(:~
 : Return the package info for `$pkgdir` in the repository associated to `$as`.
 :)
declare function a:appserver-get-package-by-pkgdir(
   $pkgdir as xs:string,
   $as     as element(a:appserver)
) as element(pp:package)?
{
   a:appserver-get-packages($as)/pp:package[@dir eq $pkgdir]
};

(:~
 : Initialize the repo associated to the app server.
 :
 : Return the same app server, with the additional element `repo`.
 :
 : Throw an error `c:repo-already-exists` if the repo has already been associated
 : to the app server.
 :
 : Throw an error `c:webdav-appserver` if the app server is a WebDAV server.
 :)
declare function a:appserver-init-repo($as as element(a:appserver))
   as element(a:appserver)
{
   (: Note: We cannot use `a:appserver-insert-into-repo` here, as `$as/a:repo`
      does not exist yet (it is being created right here...) :)
   t:add-last-child(
      $as,
      <a:repo>
         <a:root>{ $as/xs:string(a:root) }{ $repo-root }</a:root>
         <a:root-relative>{ $repo-root }</a:root-relative>
         <a:packages-file> {
            if ( a:appserver-repo-initialized($as) ) then
               t:error('repo-already-exists', 'Repo already initialized for app server: ' || $as/a:name)
            else if ( a:appserver-is-webdav($as) ) then
               t:error('webdav-appserver', 'Repo not supported for WebDAV servers: ' || $as/a:name)
            else if ( a:appserver-modules-in-db($as) ) then
               a:insert-into-database(
                  $as/a:modules-db/@id,
                  $as/xs:string(a:root) || $repo-root || $packages-file-path,
                  <packages xmlns="http://expath.org/ns/repo/packages"/>)
            else
               a:insert-into-directory(
                  $as/xs:string(a:root),
                  $repo-root || $packages-file-path,
                  <packages xmlns="http://expath.org/ns/repo/packages"/>)
         }
         </a:packages-file>
      </a:repo>)
};

(:~
 : Delete the repo associated to the app server `$as`.
 :
 : Throw `c:repo-not-initialized` if there is no repository associated to `$as`.
 :
 : Throw `c:not-confirmed` if `$confirmed` is false.  The message of the error
 : is suitable for being displayed to the user, to ask him/her to confirm the
 : deletion (containing the full path, the database name, etc.)  This allows
 : the UI layer to ask for confirmation, and the same single one piece of code
 : to gather the information used both for the actual deletion and for asking
 : for confirmation.
 :)
declare function a:appserver-nuke-repo(
   $as        as element(a:appserver),
   $confirmed as xs:boolean
) as empty-sequence()
{
   if ( fn:not(a:appserver-repo-initialized($as)) ) then
      t:error('repo-not-initialized', 'There is no repository associated to the app server: ' || $as/a:name)
   else if ( a:appserver-modules-in-db($as) ) then
      let $db  := xs:unsignedLong($as/a:modules-db/@id)
      let $dir := $as/a:repo/a:root
      return
         if ( $confirmed ) then
            a:appserver-nuke-repo-db($as, $db, $dir)
         else
            t:error(
               'not-confirmed',
               'Delete the entire directory "' || $dir || '" in the database "'
                  || $as/a:modules-db || '" (num. ' || $db || ')?')
   else
      let $dir := $as/a:repo/a:root
      return
         if ( $confirmed ) then
            a:appserver-nuke-repo-fs($as, $dir)
         else
            t:error('not-confirmed', 'Delete the entire directory "' || $dir || '" on the file system?')
};

declare %private function a:appserver-nuke-repo-db(
   $as  as element(a:appserver),
   $db  as item(),
   $dir as xs:string
) as empty-sequence()
{
   for $pkg in a:appserver-get-packages($as)/pp:package
   return
      a:appserver-delete-package($as, $pkg, fn:true()),
   a:remove-directory($db, $dir)
};

declare %private function a:appserver-nuke-repo-fs(
   $as  as element(a:appserver),
   $dir as xs:string
) as empty-sequence()
{
   for $pkg in a:appserver-get-packages($as)/pp:package
   return
      a:appserver-delete-package($as, $pkg, fn:true()),
   xdmp:filesystem-directory-delete($dir)
};

(:~
 : Save a binary document in the attic of the repository associated to `$as`.
 :
 : Use `$filename` to save the binary document.  The attic of a repository is
 : used to save the initial package XAR files, in order to keep track of the
 : packages installed in the repo.
 :)
declare function a:appserver-save-in-repo-attic(
   $xar   (: as binary() :),
   $filename as xs:string,
   $as       as element(a:appserver)
) as xs:string
{
   a:appserver-insert-into-repo($as, $attic-path || $filename, $xar)
};

(:~
 : Install the `$xar` package into the repository associated to `$as`.
 :
 : TODO: Add all the files in a specific collection (for this package, for this
 : version, in this app server)?  First be sure of the use cases (it might then
 : be easier to delete a package, but I am not sure this is enough to justify
 : it all...)
 :)
declare function a:appserver-install-package(
   $xar (: as binary() :),
   $as     as element(a:appserver)
) as element(pp:package)?
{
   (: create the package dir name from the package descriptor :)
   let $desc    := xdmp:zip-get($xar, 'expath-pkg.xml')/pkg:package
   let $name    := $desc/xs:string(@name)
   let $abbrev  := $desc/xs:string(@abbrev)
   let $version := $desc/xs:string(@version)
   let $pkg     := a:appserver-get-package-by-name($name, $version, $as)
   return
      if ( fn:exists($pkg) ) then
         (: TODO: Make it an error instead if it already exists and $override is false. :)
         ()
      else
         (: TODO: Validate $pkgdir (no space, it does not exist, etc.) :)
         let $pkgdir := $abbrev || '-' || $version
         let $dummy  := a:appserver-unzip-into-repo($xar, $pkgdir, $as)
         let $dummy  :=
               (: update the repository descriptor :)
               (: TODO: Detect if already there! (we can have duplicate if we add w/o checking) :)
               (: TODO: When the repo is in a database, we should update the document in place! :)
               (: TODO: Create a dedicated function to get/update packages.xml, as it is recorded
                  in $repo (either packages-doc or packages-file).  See r:get-packages-list()... :)
               a:appserver-insert-into-repo(
                  $as,
                  $packages-file-path,
                  t:add-last-child(
                     a:appserver-get-from-repo($packages-file-path, $as)/pp:packages,
                     <package xmlns="http://expath.org/ns/repo/packages"
                              name="{ $name }" dir="{ $pkgdir }" version="{ $version }"/>))
         let $dummy  := a:appserver-register-modules($as, $pkgdir, $desc)
         return
            a:appserver-get-package-by-name($name, $version, $as)
};

(:~
 : Register on `$as` the XQuery library modules declared in `$desc`.
 :
 : The value of `$pkgdir` is used to compute the path to modules in the repository.
 :)
declare function a:appserver-register-modules(
   $as      as element(a:appserver),
   $pkgdir  as xs:string,
   $desc    as element(pkg:package)
) as empty-sequence()
{
   admin:save-configuration(
      a:appserver-register-modules-impl(
         admin:get-configuration(),
         $as/@id,
         '/' || $as/a:repo/a:root-relative || $pkgdir || '/content/',
         (: TODO: Register other components than only XQuery library modules (like
            XSD schemas, XSLT stylesheets...) :)
         $desc/pkg:xquery[fn:exists(pkg:namespace)]))
};

(:~
 : Register on `$as` the XQuery library `$modules`.
 :
 : The `$modules` must be library modules, that is must contain a `pkg:namespace`
 : element.  The modules are registered on `$config`, but the configuration is
 : not saved automatically.
 :)
declare %private function a:appserver-register-modules-impl(
   $config  as element(configuration),
   $as      as xs:unsignedLong,
   $base    as xs:string,
   $modules as element(pkg:xquery)*
) as element(configuration)
{
   if ( fn:empty($modules) ) then
      $config
   else (
      let $new :=
            admin:appserver-add-module-location(
               $config,
               $as,
               admin:group-module-location(
                  $modules[1]/pkg:namespace,
                  $base || $modules[1]/pkg:file))
      return
         a:appserver-register-modules-impl($new, $as, $base, fn:remove($modules, 1))
   )
};

(:~
 : Unregister on `$as` the XQuery library modules declared in `$desc`.
 :
 : The value of `$pkgdir` is used to compute the path to modules in the repository.
 :)
declare function a:appserver-unregister-modules(
   $as     as element(a:appserver),
   $pkgdir as xs:string
) as empty-sequence()
{
   let $desc := a:appserver-get-from-repo($pkgdir || '/expath-pkg.xml', $as)/pkg:package
   let $base := '/' || $as/a:repo/a:root-relative || $pkgdir || '/content/'
   return
      admin:save-configuration(
         a:appserver-unregister-modules-impl(
            admin:get-configuration(),
            $as/@id,
            $base,
            (: TODO: Register other components than only XQuery library modules (like
               XSD schemas, XSLT stylesheets...) :)
            $desc/pkg:xquery[fn:exists(pkg:namespace)]))
};

(:~
 : Unregister on `$as` the XQuery library `$modules`.
 :
 : The `$modules` must be library modules, that is must contain a `pkg:namespace`
 : element.  The modules are unregistered from `$config`, but the configuration
 : is not saved automatically.
 :)
declare %private function a:appserver-unregister-modules-impl(
   $config  as element(configuration),
   $as      as xs:unsignedLong,
   $base    as xs:string,
   $modules as element(pkg:xquery)*
) as element(configuration)
{
   if ( fn:empty($modules) ) then
      $config
   else (
      let $new :=
            admin:appserver-delete-module-location(
               $config,
               $as,
               admin:group-module-location(
                  $modules[1]/pkg:namespace,
                  $base || $modules[1]/pkg:file))
      return
         a:appserver-unregister-modules-impl($new, $as, $base, fn:remove($modules, 1))
   )
};

(:~
 : Unzip in a sub-dir of the repository associated to `$as`.
 :
 : Let MarkLogic handle the format of each entry in the ZIP file (to store it
 : either as an XML tree, a text node or a binary node, based on the entry
 : filename).  See http://docs.marklogic.com/xdmp:zip-get.
 :
 : The entries in the elements /package/exclude/file, in the descriptor
 : `marklogic.xml`, if any, are excluded from the package, and never extracted
 : from the ZIP binary.
 :
 : TODO: Should not we use the same approach as a:load-dir-into-database when
 : unzipping on a database? (i.e. evaluating one query on the database, that
 : itself unzip the XAR, as opposed to unzipping each entry one by one and for
 : each of them, evaluating the query to insert it in the database...)
 :)
declare function a:appserver-unzip-into-repo(
   $zip (: as binary() :),
   $subdir as xs:string,
   $as     as element(a:appserver)
) as empty-sequence()
{
   let $entries := xdmp:zip-manifest($zip)/zip:part
   let $ml-desc := $entries[. eq 'marklogic.xml'] ! xdmp:zip-get($zip, .)/mlpkg:package
   let $dummy   := 
         (: TODO: Throw an error if $part is not a valid URI ref. :)
         for $part in $entries/xs:string(.)
         let $ref  := fn:substring-after($part, 'content/')
         where fn:not(fn:ends-with($part, '/')) (: skip dir entries :)
           and fn:not($ref = $ml-desc/mlpkg:exclude/mlpkg:file) (: excluded entries :)
         return
            a:appserver-insert-into-repo(
               $as,
               $subdir || '/' || $part,
               xdmp:zip-get($zip, $part))
   return
      ()
};

(:~
 : Delete the package `$pkg` from the app server `$as`.
 :
 : Throw `c:repo-not-initialized` if there is no repository associated to `$as`.
 :
 : Throw `c:not-confirmed` if `$confirmed` is false.  The message of the error
 : is suitable for being displayed to the user, to ask him/her to confirm the
 : deletion (containing the full path, the database name, etc.)  This allows
 : the UI layer to ask for confirmation, and the same single one piece of code
 : to gather the information used both for the actual deletion and for asking
 : for confirmation.
 :)
declare function a:appserver-delete-package(
   $as        as element(a:appserver),
   $pkg       as element(pp:package),
   $confirmed as xs:boolean
) as empty-sequence()
{
   if ( fn:not(a:appserver-repo-initialized($as)) ) then
      t:error('repo-not-initialized', 'There is no repository associated to the app server: ' || $as/a:name)
   else if ( a:appserver-modules-in-db($as) ) then
      let $db  := xs:unsignedLong($as/a:modules-db/@id)
      let $dir := $as/a:repo/a:root || $pkg/@dir || '/'
      return
         if ( $confirmed ) then
            a:appserver-delete-package-db($as, $db, $dir, $pkg/@dir)
         else
            t:error(
               'not-confirmed',
               'Delete the directory "' || $dir || '" in the database "'
                  || $as/a:modules-db || '" (num. ' || $db || ')?')
   else
      let $dir := $as/a:repo/a:root || $pkg/@dir || '/'
      return
         if ( $confirmed ) then
            a:appserver-delete-package-fs($as, $dir, $pkg/@dir)
         else
            t:error('not-confirmed', 'Delete the directory "' || $dir || '" on the file system?')
};

declare %private function a:appserver-delete-package-db(
   $as     as element(a:appserver),
   $db     as item(),
   $dir    as xs:string,
   $pkgdir as xs:string
) as empty-sequence()
{
   a:appserver-unregister-modules($as, $pkgdir),
   a:remove-directory($db, $dir),
   a:appserver-remove-pkg-from-list($as, $pkgdir)
};

declare %private function a:appserver-delete-package-fs(
   $as     as element(a:appserver),
   $dir    as xs:string,
   $pkgdir as xs:string
) as empty-sequence()
{
   a:appserver-unregister-modules($as, $pkgdir),
   xdmp:filesystem-directory-delete($dir),
   a:appserver-remove-pkg-from-list($as, $pkgdir)
};

declare %private function a:appserver-remove-pkg-from-list(
   $as     as element(a:appserver),
   $pkgdir as xs:string
) as empty-sequence()
{
   let $dummy :=
         a:appserver-insert-into-repo(
            $as,
            $packages-file-path,
            <packages xmlns="http://expath.org/ns/repo/packages"> {
               a:appserver-get-from-repo($packages-file-path, $as)
                  / pp:packages/pp:package[fn:not(@dir eq $pkgdir)]
            }
            </packages>)
   return
      ()
};

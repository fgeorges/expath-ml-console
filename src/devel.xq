xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "lib/admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "lib/repo.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

import module namespace admin = "http://marklogic.com/xdmp/admin"
   at "/MarkLogic/admin.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page()
   as element()+
{
   <wrapper>
      <p>Some useful queries used in the implementation of the console.</p>
      <p>You can use this page to show some useful information about your
         MarkLogic instance.  You can also inspect the code source of this page
         to see how to retrieve the same information from within XQuery.</p>
      <h4>Browsing a pkg dir</h4>
      <ul> {
         for $repo  in cfg:get-repos()
         let $db-id := $repo/c:database/@id
         let $root  := $repo/c:root
         let $docs  :=
               a:eval-on-database(
                  $db-id,
                  'declare variable $path external;
                   xdmp:directory($path, "infinity")',
                  (fn:QName('', 'path'), $root))
                  (: fn:QName('', 'path'), fn:concat($root, '.expath-pkg/')) :)
         for $d in $docs
         return
            <li>{ fn:document-uri($d) }</li>
      }
      </ul>
      <h4>Some infos</h4>
      <ul>
         <li>Module database: { xdmp:databases()[xdmp:database-name(.) eq 'Modules'] }</li>
         <li>Module root: { xdmp:modules-root() }</li>
         <li>"Modules" DB data dir: {
            let $config := admin:get-configuration()
            return
               admin:forest-get-data-directory(
                  $config,
                  admin:forest-get-id($config, "Modules"))
         }
         </li>
         <li>"expath-pkg" AS module DB: {
            let $config := admin:get-configuration()
            let $groupid := admin:group-get-id($config, "Default")
            return
               admin:appserver-get-modules-database(
                  $config,
                  admin:appserver-get-id($config, $groupid, "expath-pkg"))
         }
         </li>
         <li>"expath-pkg" AS root: {
            let $config := admin:get-configuration()
            let $groupid := admin:group-get-id($config, "Default")
            return
               admin:appserver-get-root(
                  $config,
                  admin:appserver-get-id($config, $groupid, "expath-pkg"))
         }
         </li>
      </ul>
      <h4>App servers</h4>
      <ul> {
         let $config := admin:get-configuration()
         for $as in admin:get-appserver-ids($config)
         return
            <li> {
               'Name: ', admin:appserver-get-name($config, $as),
               ' / ID: ', $as,
               ' / Modules DB: ',
               try {
                  admin:appserver-get-modules-database($config, $as)
               }
               catch * {
                  (: WebDAV ASs do not have a module DB:)
                  (: TODO: How to retrieve the type of a server programmatically? :)
                  (: TODO: Be sure to catch only this error! :)
                  'N/A'
               },
               ' / Root: ', admin:appserver-get-root($config, $as)
            }
            </li>
      }
      </ul>
      <h4>Forests</h4>
      <ul> {
         for $f in xdmp:forests()
         return
            <li> {
               fn:concat(xdmp:forest-name($f), ' (', xdmp:database-name(xdmp:forest-databases($f)), ')')
               (:fn:concat(xdmp:forest-name($f), ' (', xdmp:host-name(xdmp:forest-host($f)), ' / ', xdmp:database-name(xdmp:forest-databases($f)), ')'):)
            }
            </li>
      }
      </ul>
      <h4>Databases</h4>
      <ul> {
         for $db in xdmp:databases()
         return
            <li> {
               xdmp:database-name($db)
            }
            </li>
      }
      </ul>
   </wrapper>/*
};

v:console-page('', 'devel', 'Developement tools', local:page#0)

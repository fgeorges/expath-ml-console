xquery version "3.0";

(:~
 : Dump the Console config files and some MarkLogic object as XML.
 :)

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page()
   as element()+
{
   <wrapper>
      <p>This page shows the Console config files content, as well as various
         MarkLogic object as they are represented within the code of the
         Console, using XML elements.</p>
      <h4>Console config</h4>
      <p>The main Console config file.  It is stored within the database
         attached to the App Server the Console has been installed into, with
         the document URI { $cfg:config-docname }.</p>
      { local:display-xml(cfg:get-config()) }
      <h4>Web containers config</h4>
      <p>All the web container config files.  There are stored within different
         databases, attached to the App Servers whithin which web containers have
         been installed, with the document URI { $cfg:web-config-docname }.</p>
      {
         let $dbs  := cfg:get-container-refs()/c:db
         for $db   in fn:distinct-values($dbs/@id)
         let $id   := xs:unsignedLong($db)
         let $conf := a:get-from-database($id, $cfg:web-config-docname, '')/*
         return (
            <p>In the database '{ fn:string(($dbs[@id eq $db])[1]) }'</p>,
            local:display-xml($conf)
         )
      }
      <h4>Databases</h4>
      <p>The existing databases in this MarkLogic Server instance, as returned
         by the admin.xql library (and as used and manipulated by all the
         Console code).</p>
      { local:display-xml(a:get-databases()) }
      <h4>App Servers</h4>
      <p>The existing App Servers in this MarkLogic Server instance, as
         returned by the admin.xql library (and as used and manipulated by all
         the Console code).</p>
      { local:display-xml(a:get-appservers()) }
   </wrapper>/*
};

declare function local:display-xml($elem as element()?)
   as element(pre)
{
   <pre> {
      (: TODO: Add syntax highlighting... :)
      xdmp:quote(
         $elem,
         <options xmlns="xdmp:quote">
            <indent-untyped>yes</indent-untyped>
         </options>)
   }
   </pre>
};

v:console-page('../', 'tools', 'Show config', local:page#0)

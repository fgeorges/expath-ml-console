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

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   <wrapper>
      <p>This page shows various MarkLogic objects as they are represented
         within the code of the Console, using XML elements.</p>
      <h4>App Servers</h4>
      <p>The existing App Servers in this MarkLogic Server instance, as
         returned by the admin.xql library (and as used and manipulated all
         around the code of the Console):</p>
      { v:display-xml(a:get-appservers()) }
      <h4>Databases</h4>
      <p>The existing databases in this MarkLogic Server instance, as returned
         by the admin.xql library (and as used and manipulated all around the
         code of the Console):</p>
      { v:display-xml(a:get-databases()) }
   </wrapper>/*
};

v:console-page('../', 'tools', 'Show config', local:page#0)

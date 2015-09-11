xquery version "3.0";

(:~
 : Aimed at providing general tools for MarkLogic.
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "lib/admin.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   <wrapper>
      <p>Some generic tools for MarkLogic.</p>
      <h3>Document manager</h3>
      <p>The <a href="tools/docs">document manager</a> let you insert
         documents (single files one by one, entire directories, or
         directories archived as a ZIP file).  You can also delete existing
         documents and directories.</p>
      <h3>Admin entities</h3>
      <p>You can have a look at various MarkLogic objects, as they are
         represented within the code of the Console using XML elements at:
         <a href="tools/config">config</a>.</p>
      <h3>Browse a database</h3>
      <p>Provide a way to browse the content of a database , in a hierarchical
         kind of way (based on the directory "structure").</p>
      <!--p><b>TODO</b>: Provide a way to browse a database content, in a
         hierarchical kind of way (based on the directory "structure").
         Provide a "delete" button for each of them, as well as an "update"
         button (and more generally some useful actions to do on a document or
         file, like move, rename, etc.)</p-->
      {
         v:form('tools/browse-db', (
            v:input-select-databases('database', 'Database'),
            v:submit('Browse')))
      }
      <!--h4>Other tools</h4>
      <p><b>TODO</b>: Other tools to provide: providing a way to set the owner
         and permissions when inserting files, editing a document in place,
         generating xqdoc documentation, running test suites, checking a repo
         integrity (like no duplicates in packages.xml, check that packages.xml
         is in synch with the directories...), etc.</p-->
   </wrapper>/*
};

v:console-page('', 'tools', 'Tools', local:page#0)

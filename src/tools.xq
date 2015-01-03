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
   let $db-options := local:database-options()
   return
      <wrapper>
         <p>Some generic tools for MarkLogic.</p>
         <h4>Document manager</h4>
         <p>The <a href="tools/docs">document manager</a> let you insert
            documents (single files one by one, entire directories, or
            directories archived as a ZIP file).  You can also delete existing
            documents and directories.</p>
         <h4>Admin entities</h4>
         <p>You can have a look at various MarkLogic objects, as they are
            represented within the code of the Console using XML elements at:
            <a href="tools/config">config</a>.</p>
         <h4>Browse a database</h4>
         <!--p><b>TODO</b>: Provide a way to browse a database content, in a
            hierarchical kind of way (based on the directory "structure").
            Provide a "delete" button for each of them, as well as an "update"
            button (and more generally some useful actions to do on a document or
            file, like move, rename, etc.)</p-->
         <form method="post" action="tools/browse-db" enctype="multipart/form-data">
            <span>Database:</span>
            { $db-options }
            <br/>
            <input type="submit" value="Browse"/>
         </form>
         <!--h4>Other tools</h4>
         <p><b>TODO</b>: Other tools to provide: providing a way to set the owner
            and permissions when inserting files, editing a document in place,
            generating xqdoc documentation, running test suites, checking a repo
            integrity (like no duplicates in packages.xml, check that packages.xml
            is in synch with the directories...), etc.</p-->
      </wrapper>/*
};

(:~
 : TODO: ...
 : TODO: Duplicated in tools/docs.xq, factorize out!
 :)
declare function local:database-options()
{
   <select name="database"> {
      for $db in a:get-databases()/a:database
      order by $db/a:name
      return
         <option value="{ $db/@id }">{ $db/fn:string(a:name) }</option>
   }
   </select>
};

v:console-page('', 'tools', 'Tools', local:page#0)

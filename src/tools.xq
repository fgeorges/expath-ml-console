xquery version "3.0";

(:~
 : Aimed at providing general tools for MarkLogic.
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "lib/admin.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
   let $db-options := local:database-options()
   return
      <wrapper>
         <p>Some generic tools for MarkLogic.</p>
         <h4>Console and MarkLogic config</h4>
         <p>The following page shows the Console config files content, as well
            as various MarkLogic object as they are represented within the code
            of the Console, using XML elements: <a href="tools/config.xq">config</a>.</p>
         <h4>Insert a document</h4>
         <p>Insert a file at some specific place into a specific database. By
            default the file is expected to be XML, but you can change its type to
            text or binary. If the file already exists, it is overriden.</p>
         <form method="post" action="tools/insert.xq" enctype="multipart/form-data">
            <span>Target database:</span>
            { $db-options }
            <br/>
            <span>Target file:</span>
            <input type="text" name="uri" size="50"/>
            <br/>
            <span>File to insert:</span>
            <input type="file" name="file"/>
            <br/>
            <span>Format of the file:</span>
            <select name="format">
               <option value="xml">XML</option>
               <option value="text">Text</option>
               <option value="binary">Binary</option>
            </select>
            <br/>
            <input type="checkbox" name="override" value="true"/>
            <span>Override the target URI if it already exists in the database.</span>
            <br/>
            <input type="submit" value="Insert"/>
         </form>
         <h4>Insert a directory</h4>
         <p>Insert a directory recursively at some specific place into a
            specific database.  The optional filters are regex expressions (like
            "2012-03-[0-9]+\.xml" for instance). This requires the directory to
            be on the same machine as MarkLogic itself, and the path to be
            absolute. It is an error if the directory already exists in the
            database.</p>
         <p>The set of files to include is computed as following: first we
            start with all the files in the directory, including all of its
            descendants. If the include filter is provided, only the file with
            the filename matching the filter are included, all the other files
            are discarded (the match is done over the filename only, after the
            last '/', also for directories). If the exclude filter is provided,
            the set of selected files is further restricted by getting rid of
            the files matching the filter.</p>
         <form method="post" action="tools/insert.xq" enctype="multipart/form-data">
            <span>Target database:</span>
            { $db-options }
            <br/>
            <span>Target directory:</span>
            <input type="text" name="uri" size="50"/>
            <br/>
            <span>Directory to insert:</span>
            <input type="text" name="dir" size="50"/>
            <br/>
            <span>Include filter:</span>
            <input type="text" name="include" size="25"/>
            <br/>
            <span>Exclude filter:</span>
            <input type="text" name="exclude" size="25"/>
            <br/>
            <input type="submit" value="Insert"/>
         </form>
         <h4>Insert a zipped directory</h4>
         <p>Insert a directory based on a ZIP file. The ZIP file is expanded to
            create the content of the directory on the database. It is an error
            if the directory already exists in the database.</p>
         <form method="post" action="tools/insert.xq" enctype="multipart/form-data">
            <span>Target database:</span>
            { $db-options }
            <br/>
            <span>Target directory:</span>
            <input type="text" name="uri" size="50"/>
            <br/>
            <span>ZIP to insert:</span>
            <input type="file" name="zipdir"/>
            <br/>
            <input type="submit" value="Insert"/>
         </form>
         <h4>Browse a database</h4>
         <p><b>TODO</b>: Provide a way to browse a database content, in a
            hierarchical kind of way (based on the directory "structure").
            Provide a "delete" button for each of them, as well as an "update"
            button (and more generally some useful actions to do on a document or
            file, like move, rename, etc.)</p>
         <h4>Other tools</h4>
         <p><b>TODO</b>: Other tools to provide: providing a way to set the owner
            and permissions when inserting files, editing a document in place,
            generating xqdoc documentation, running test suites, checking a repo
            integrity (like no duplicates in packages.xml, check that packages.xml
            is in synch with the directories...), etc.</p>
      </wrapper>/*
};

(:~
 : TODO: ...
 : TODO: Duplicated in repo.xq, factorize out!
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

xquery version "1.0";

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

v:console-page(
   'help',
   'Help',
   <wrapper>
      <h4>Introduction</h4>
      <p>The EXPath Console for MarkLogic comes with several tools. The main
         goal though is to provide some support for XAR packages and a repository
         manager.  A XAR package is a collection of XML-related files, like
         XQuery modules, XSLT stylesheets or XML schemas. The console can create
         different repositories in MarkLogic, that is, different places where to
         install automatically such XAR packages using the console itself.</p>
      <p>A repository on MarkLogic is created either in a database (using some
         root directory under which everything belonging to the repo is installed),
         or on the filesystem in a specific directory (when creating a repository
         for a web server with the modules on the filesystem).</p>
      <p>The way the EXPath Packaging System is designed allows you to use the
         XQuery modules from the package, after installing the package, just by
         importing it using the module namespace, without specifying any "at
         clause":</p>
      <pre>import module namespace "http://example.org/cool/lib.xql";</pre>
      <p>Sadly, MarkLogic does not provide any way to override the way import
         statements are resolved. So once a package has been install, your
         importing XQuery module still have to hard-code the full path to the
         reporitory, and to the specific package:</p>
      <pre>import module namespace "http://example.org/cool/lib.xql" at "/repo/cool-stuff-1.2/lib.xql";</pre>
      <p>This is unfortunate, and we hope a later version of MarkLogic will
         provide a solution for that problem. The good news is that the EXPath
         Console at least provides a way to automatically install a package at
         a specific place by pressing a button in a graphical web interface.</p>
      <h4>Installation</h4>
      <p>Create a new HTTP server in the MarkLogic admin console, with the modules
         in a directory on the file system. The document database linked to the
         HTTP server will be used only to store the console configuration document.
         Copy then the source code of the console to the directory you just
         specified, and use your browser to access the console at (say if you
         set the port to 8888):</p>
      <pre>http://localhost:8888/home.xq</pre>
      <p>You should then see the console homepage. It should include a warning,
         telling that the console is not configured yet. This is normal, just
         proceed to the next step ;-)</p>
      <h4>Configuration</h4>
      <p>Go to the <a href="setup.xq">Setup page</a> from the menu. All you
         need to do is following the instruction and creating a repository in
         MarkLogic. Either attached to a specific database, or attached to the
         module database of a specific application server (which then can be
         on the filesystem). Once the console has been setup, you can start
         using it.</p>
      <h4>Pages</h4>
      <ul>
         <li>The page "<a href="repo.xq">Repositories</a>" lists all the
            repositories setup in this, console. You can then select and
            browse a specific repository, show what packages it contains,
            and delete specific packages.</li>
         <li>The page "<a href="install.xq">Install</a>" provides a simple
            form to install a XAR package. The package must be somewhere on
            your filesystem, you just need to select it by browsing the
            filesystem and select it. You have to select the target repository
            as well.</li>
         <li>The page "<a href="cxan.xq">CXAN</a>" lets you install a package
            straight from the global CXAN website, by giving its name and
            optionally a specific version number. CXAN is a global website
            collecting existing XAR packages out there.</li>
         <li>The page "<a href="tools.xq">Tools</a>" provides some general
            purpose tools for MarkLogic.</li>
      </ul>
   </wrapper>/*)

xquery version "3.0";

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
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
         statements are resolved. So once a package has been installed, your
         importing XQuery module still has to hard-code the full path to the
         reporitory, and to the specific package:</p>
      <pre>import module namespace "http://example.org/cool/lib.xql"
   at "/repo/cool-stuff-1.2/content/lib.xql";</pre>
      <p>This is unfortunate, and we have faith in that in a  later version
         MarkLogic will provide a solution for that problem. The good news is
         that the EXPath Console at least provides a way to automatically
         install a package at a specific place by pressing a button in a
         graphical web interface. But the "at location hint" is still a problem
         for building maintainable libraries and applications.</p>
      <p><a href="http://cxan.org/">CXAN</a> is an organized source of packages,
         if you are looking for a specific library of application.</p>
      <h4>Installation</h4>
      <p>If you are reading this page, you probably already installed succesfully
         the Console. The installation process is documented here though, for
         comprehensiveness.</p>
      <p>Create a new HTTP server in the MarkLogic admin console. Put the
         source code of the Console at the root of the App Server (depending on
         the options you selected creating the App Server, it could be on its
         modules database or on the filesystem if you decided to store the
         modules of this App Server on the filesystem). The document database
         linked to the HTTP server will be used only to store the console
         configuration document. You can then access the Console by pointing
         your preferred browser to (say if you set the port to 8888):</p>
      <pre>http://localhost:8888/home.xq</pre>
      <h4>Pages</h4>
      <p>Every page should be self-explained. If one page does not contain
         enough help for you to understand what to do, please report it to the
         mailing list. The top-level pages, or area, are the following:</p>
      <ul>
         <li>The page "<a href="repo.xq">Repositories</a>" lists all the
            repositories created in this console. The page provides a form to
            create new repositories, and the ability to remove and delete
            existing repos. From the repo list, you can open a specific repo,
            show the list of packages it contains, delete them and install new
            packages (from your filesystem or directly from CXAN).</li>
         <li>The page "<a href="cxan.xq">CXAN</a>" lets you configuring the
            CXAN website to talk to.</li>
         <li>The page "<a href="tools.xq">Tools</a>" provides some general
            purpose tools for MarkLogic, as well as the source of the internal
            Console config files.</li>
      </ul>
   </wrapper>/*
};

v:console-page('',  'help', 'Help', local:page#0)

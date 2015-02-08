xquery version "3.0";

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   <wrapper>
      <h4>Introduction</h4>
      <p>The EXPath Console for MarkLogic comes with several tools. The main
         goal though is to provide a repository manager and support for
         <a href="http://expath.org/spec/pkg">XAR packages</a>.  A XAR package
         is a collection of XML-related files, like XQuery modules, XSLT
         stylesheets or XML schemas. The console install one package on a
         specific app server.</p>
      <p>Once a package has been installed on an app server, other modules
         running in the same app server can import an XQuery modules from the
         package, just by importing it using the module namespace, without
         specifying any "at clause", decoupling dependencies between the
         importing and the imported modules:</p>
      <pre>import module namespace "http://example.org/cool/lib.xql";</pre>
      <p><a href="http://cxan.org/">CXAN</a> is an organized, online source of
         packages, if you are looking for a specific library or application.
         The page to install a package into an app server supports installed
         straight from CXAN.</p>
      <h4>Installation</h4>
      <p>If you are reading this page, you probably already installed succesfully
         the Console. The installation process is documented here though, for
         comprehensiveness.</p>
      <ul>
         <li>create a new HTTP server in the MarkLogic admin console</li>
         <li>put the source code of the Console at the root of the App Server
            (depending on the options you selected creating the App Server, it
            could be on its modules database or on the filesystem if you decided
            to store the modules of this App Server on the filesystem)</li>
         <li>make sure to set the app server URL rewriter field (at the end of
            the admin console page for the app server) to the value
            <code>/plumbing/rewriter.xq</code></li>
         <li>the document database linked to the HTTP server will not be used
            by the Console</li>
      </ul>
      <p>You can now access the Console by pointing your preferred browser to
         the appropriate App Server (you might need to adapt the port number,
         depending on how you configured your app server):
         <a href="http://localhost:8888/">http://localhost:8888/</a>.</p>
      <h4>Pages</h4>
      <p>Every page should be self-explaining. If one page does not contain
         enough help for you to understand what to do, please report it to the
         EXPath <a href="http://expath.org/lists">mailing list</a>. The top-level
         pages, or area, are the following:</p>
      <ul>
         <li>The page "<a href="pkg">Packages</a>" lists all the app servers.
            From a specific app server page, you can enable package support (by
            default it is disabled, in order to enable it, the Console has tp
            create an internal repository on its modules database or on the
            filesystem).  Once package support has been enabled, a specific app
            server page offers the ability to install packages for this app
            server (from your filesystem or directly from CXAN).</li>
         <li>The page "<a href="tools">Tools</a>" provides some general-purpose
            tools for MarkLogic, as well as the source of the internal Console
            config files.</li>
      </ul>
   </wrapper>/*
};

v:console-page('',  'help', 'Help', local:page#0)

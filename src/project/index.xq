xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xqy";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xqy";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xqy";

import module namespace g = "http://expath.org/ns/ml/console/project/global" at "global-lib.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xp   = "http://expath.org/ns/project";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page() as element()+
{
   <p>The projects on this system:</p>,
   let $projects := proj:projects()
   return
      <table class="table table-bordered datatable" id="prof-detail">
         <thead>
            <th>Name</th>
            <th>Title</th>
            <th>Type</th>
            <th>Info</th>
         </thead>
         <tbody> {
            if ( fn:empty($projects) ) then
               <td colspan="4"><em>no project yet</em></td>
            else
               for $proj in $projects
               let $id   := xs:string($proj/@id)
               order by $id
               return
                  <tr>
                     <td>{ v:proj-link('project/' || $id, $id) }</td>
                     <td>{ g:title($proj) }</td>
                     <td>{ xs:string($proj/@type) }</td>
                     <td>{ g:info($proj) }</td>
                  </tr>
         }
         </tbody>
      </table>,
   <p>Projects let you handle applications and libraries source files.</p>,
   <p>You can browse JavaScript and XQuery source files, and display their documentation.
      The documentation must be embedded in the source files as xqDoc comments in XQuery,
      and as the equivalent in JavaScript.  Respectively <code>(:~ ... :)</code> and
      <code>/*~ ... */</code>.</p>,
   <p>A project can also contain query books.  A query book, or qbook for short, is a simple
      Markdown file.  All the JavaScript and XQuery code blocks in the file are made executable
      on MarkLogic.  A bit like you would do with QConsole, except that the code is in Markdown
      files, so you can add any text, structure them in directories, and add them to Git.  You
      can also pass parameter to the queries using forms on the page.</p>,
   <p>The Console supports 3 types of projects:</p>,
   <ul>
      <li><b><a href="http://mlproj.org/">mlproj</a></b> - on the filesystem, must conform to some
         structure and conventions</li>
      <li><b>directories</b> - plug to existing source code directories on the filesystem</li>
      <li><b>databases</b> - plug to existing source code "directories" on a database</li>
   </ul>,

   <h3>mlproj</h3>,
   <p>The project manager <code>mlproj</code> defines a simple structure for MarkLogic projects.
      It is based on simple conventions, like a directory <code>src/</code> for source code, and on
      config files to describe the clusters for the various environments to manage.  You can find
      everything about <code>mlproj</code> on <a href="http://mlproj.org/">mlproj.org</a>.</p>,
   <p>You can either plug to an existing project, or create a brand-new one with a skeleton.</p>,
   v:one-liner-link('Add project', 'project/_/xproject', 'Add'),

   <h3>Directory</h3>,
   <p>The projects based on XProject are fully supported in the Console.  But if you projects
      are not following the same conventions, you can still add their source directories here.
      This will allow you to use simplest features, like browsing code and displaying their XQDoc
      comments.</p>,
   v:one-liner-link('Add project', 'project/_/srcdir', 'Add'),

   <h3>Database</h3>,
   <p>Modules stored in a database (like a database used as the module database for an appserver)
      can be browsed the same way <code>Source directories</code> allows to browse modules on a
      file system.  This allows you to look at source code already deployed on a modules
      database.</p>,
   v:one-liner-link('Add project', 'project/_/dbdir', 'Add')
};

v:console-page('./', 'project', 'Projects', local:page#0)

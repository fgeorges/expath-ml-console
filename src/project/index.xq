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
   <p>Projects let you handle applications and libraries source files.  For now, they allow you
      to browse project XQuery and JavaScript source files, and display their documentation.
      The documentation must be embedded in the source files as xqDoc comments in XQuery, and
      as the equivalent in JavaScript (only using <code>/*~ ... */</code> instead of
      <code>(:~ ... :)</code>.)</p>,
   <p>The Console supports 3 types of projects:</p>,
   <ul>
      <li><b><a href="http://expath.org/modules/xproject/">XProject</a></b> - on the filesystem,
         must conform to some conventions (conventions are enforced by the Console, to some
         extent)</li>
      <li><b>source directories</b> - plug to existing source files directories on the
         filesystem</li>
      <li><b>database directories</b> - plug to source files directories on a database (ideal for
         inspecting code of an installed application)</li>
   </ul>,
   <p>The forms below let you create new projects in the Console.</p>,

   <h3>XProject</h3>,
   <p>XProject is a simple project structure for XQuery- and XSLT-based projects.  It is based on
      simple conventions, like a directory <code>src/</code>, a directory <code>xproject/</code>,
      and a project descriptor in <code>xproject/project.xml</code>.  You can find everything
      about XProject on <a href="http://expath.org/modules/xproject/">this page</a>.  You can
      either plug to an existing project (use "add"), or create a brand-new one (use "create").</p>,
   v:one-liner-link('Add/create project', 'project/_/xproject', 'Add'),

   <h3>Source directories</h3>,
   <p>The projects based on XProject are fully supported in the Console.  But if you projects
      are not following the same conventions, you can still add their source directories here.
      This will allow you to use simplest features, like browsing and displaying their XQDoc
      comments.</p>,
   v:one-liner-link('Add project', 'project/_/srcdir', 'Add'),

   <h3>DB directories</h3>,
   <p>Modules stored in a database (like a database used as the module database for an appserver)
      can be browsed the same way <code>Source directories</code> allows to browse modules on a
      file system.</p>,
   v:one-liner-link('Add project', 'project/_/dbdir', 'Add')
};

v:console-page('./', 'project', 'Projects', local:page#0)

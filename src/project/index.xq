xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc  = "http://expath.org/ns/ml/console";
declare namespace xp   = "http://expath.org/ns/project";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page() as element()+
{
   if ( proj:is-console-init() ) then (
      <p>The projects on this system.</p>,
      <ul> {
         let $ids := proj:get-project-ids()
         return
            if ( fn:empty($ids) ) then
               <li><em>no project yet</em></li>
            else
               for $id    in $ids
               let $title := proj:get-descriptor($id)/xs:string(xp:title)
               return
                  <li>{ v:proj-link('project/' || $id, $id) } - { $title }</li>
      }
      </ul>,
      <h3>XProject</h3>,
      <p>XProject is a simple project structure for XQuery- and XSLT-based projects.  It is based on
         simple conventions, like a directory <code>src/</code>, a directory <code>xproject/</code>,
         and a project descriptor in <code>xproject/project.xml</code>.</p>,
      <h4>Add</h4>,
      <p>Add an existing XProject project.</p>,
      v:form('project/_/add-xproject', (
         v:input-text('id',  'ID',        'The ID of the project (default to the project abbrev)'),
         v:input-text('dir', 'Directory', 'Absolute path to the project directory'),
         v:submit('Add'))),
      <h4>Create</h4>,
      <p>Create a new XProject project.</p>,
      v:form('project/_/create-xproject', (
         v:input-text('id',      'ID',        'The ID of the project (default to the project abbrev)'),
         v:input-text('dir',     'Directory', 'Absolute path where to create the project directory'),
         v:input-text('name',    'Name',      'Project full name (a unique URI)'),
         v:input-text('abbrev',  'Abbrev',    'Project abbreviation'),
         v:input-text('version', 'Version',   'Version number (using SemVer)'),
         v:input-text('title',   'Title',     'Project title'),
         v:submit('Create'))),
      <h3>Source directories</h3>,
      <p>The projects based on XProject are fully supported in the Console.  But if you projects
         are not following the same conventions, you can still add their source directories here.
         This will allow you to use simplest features, like browsing and displaying their XQDoc
         comments.</p>,
      <h4>Add</h4>,
      <p>Add an existing source directory.</p>
   )
   else (
      (: TODO: Move this init process and button somewhere in the Tools area. :)
      <p>In order to support projects, the Console must be <em>initialized</em>
         (that is, its config file must be created).  This is an automated process,
         all you need to do is to click on the following button:</p>,
      v:inline-form('project/_/init-console', v:submit('Initialize'))
   )
};

v:console-page('./', 'project', 'Projects', local:page#0)
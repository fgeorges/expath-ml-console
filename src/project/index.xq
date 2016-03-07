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
      <h3>List</h3>,
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
      <h3>Add</h3>,
      <p>Add an existing project.</p>,
      v:form('project/_/add', (
         v:input-text('id',  'ID',        'The ID of the project (default to the project abbrev)'),
         v:input-text('dir', 'Directory', 'Absolute path to the project directory'),
         v:submit('Add'))),
      <h3>Create</h3>,
      <p>Create a new project.</p>,
      v:form('project/_/create', (
         v:input-text('id',      'ID',        'The ID of the project (default to the project abbrev)'),
         v:input-text('dir',     'Directory', 'Absolute path where to create the project directory'),
         v:input-text('name',    'Name',      'Project full name (a unique URI)'),
         v:input-text('abbrev',  'Abbrev',    'Project abbreviation'),
         v:input-text('version', 'Version',   'Version number (using SemVer)'),
         v:input-text('title',   'Title',     'Project title'),
         v:submit('Create')))
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

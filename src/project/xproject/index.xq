xquery version "3.0";

import module namespace v = "http://expath.org/ns/ml/console/view"
   at "../../lib/view.xql";

declare function local:page() as element()+
{
   <p>XProject is a simple project structure for XQuery- and XSLT-based projects.  It is based on
      simple conventions, like a directory <code>src/</code>, a directory <code>xproject/</code>,
      and a project descriptor in <code>xproject/project.xml</code>.  You can find everything
      about XProject on <a href="http://expath.org/modules/xproject/">this page</a>.  You can
      either plug to an existing project (use "add"), or create a brand-new one (use "create").</p>,
   <h3>Add</h3>,
   <p>Add an existing XProject project from the filesystem:</p>,
   v:form('xproject/add', (
      v:input-text('id',  'ID',        'The ID of the project (default to the project abbrev)'),
      v:input-text('dir', 'Directory', 'Absolute path to the project directory'),
      v:submit('Add'))),
   <h3>Create</h3>,
   <p>Create a new XProject project on the filesystem:</p>,
   v:form('xproject/create', (
      v:input-text('id',      'ID',        'The ID of the project (default to the project abbrev)'),
      v:input-text('dir',     'Directory', 'Absolute path where to create the project directory'),
      v:input-text('name',    'Name',      'Project full name (a unique URI)'),
      v:input-text('abbrev',  'Abbrev',    'Project abbreviation'),
      v:input-text('version', 'Version',   'Version number (using SemVer)'),
      v:input-text('title',   'Title',     'Project title'),
      v:submit('Create')))
(:
   <p>Add an XProject descriptor to an existing project on the filesystem (the directory must
      contain an <code>src/</code> subdirectory):</p>,
   v:form('xproject/init', (
      v:input-text('id',      'ID',        'The ID of the project (default to the project abbrev)'),
      v:input-text('dir',     'Directory', 'Absolute path where to create the project directory'),
      v:input-text('name',    'Name',      'Project full name (a unique URI)'),
      v:input-text('abbrev',  'Abbrev',    'Project abbreviation'),
      v:input-text('version', 'Version',   'Version number (using SemVer)'),
      v:input-text('title',   'Title',     'Project title'),
      v:submit('Init')))
:)
};

v:console-page('../../', 'project', 'XProject', local:page#0)

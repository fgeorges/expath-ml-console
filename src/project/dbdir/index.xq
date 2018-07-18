xquery version "3.0";

import module namespace v = "http://expath.org/ns/ml/console/view"
   at "../../lib/view.xqy";

declare function local:page() as element()+
{
   <p>Modules stored in a database (like a database used as the module database for an appserver)
      can be browsed the same way <code>Source directories</code> allows to browse modules on a
      file system.</p>,
   <h3>Add</h3>,
   <p>Add a directory from an existing database:</p>,
   v:form('dbdir/add', (
      v:input-select-databases('database', 'Database'),
      v:input-text('id',    'ID',    'The ID of the project'),
      v:input-text('root',  'Root',  'Absolute path to the source directory (optional)'),
      v:input-text('title', 'Title', 'Project title'),
      v:submit('Add')))
};

v:console-page('../../', 'project', 'DB directory projects', local:page#0)

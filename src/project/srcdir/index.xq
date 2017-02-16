xquery version "3.0";

import module namespace v = "http://expath.org/ns/ml/console/view"
   at "../../lib/view.xql";

declare function local:page() as element()+
{
   <p>The projects based on XProject are fully supported in the Console.  But if you projects
      are not following the same conventions, you can still add their source directories here.
      This will allow you to use simplest features, like browsing and displaying their XQDoc
      comments.</p>,
   <p>Add an existing source directory from the filesystem:</p>,
   v:form('srcdir/add', (
      v:input-text('id',    'ID',        'The ID of the project'),
      v:input-text('dir',   'Directory', 'Absolute path to the source directory'),
      v:input-text('title', 'Title',     'Project title'),
      v:submit('Add')))
};

v:console-page('../../', 'project', 'Source directory projects', local:page#0)

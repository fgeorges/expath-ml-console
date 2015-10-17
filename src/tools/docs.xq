xquery version "3.0";

(:~
 : The document manager page.
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   <wrapper>
      <p>Some tools to insert and delete documents.</p>
      <h3>Insert a document</h3>
      <p>Insert a file at some specific place into a specific database. By
         default the file is expected to be XML, but you can change its type to
         text or binary. If the file already exists, it is overriden.</p>
      {
         v:form('insert', (
            v:input-file('file', 'File to insert'),
            v:input-select-databases('database', 'Target database'),
            v:input-text('uri',  'Target document', 'The document URI'),
            v:input-select('format', 'Format of the file', (
               v:input-option('xml',    'XML'),
               v:input-option('text',   'Text'),
               v:input-option('binary', 'Binary'))),
            v:input-checkbox('override', 'Override', 'true'),
            v:submit('Insert')))
      }
      <h3>Insert triples</h3>
      <p>Insert managed triples into a specific database.  Only databases with
         the triple index enabled are elligeable.</p>
      {
         v:form('insert-triples', (
            v:input-file('file', 'Triples file'),
            v:input-select-databases(
               'database',
               'Target database',
               function($db) { $db/xs:boolean(a:triple-index) }),
            v:input-select('format', 'Format', (
               v:input-option('triplexml', 'MarkLogic sem:triples'),
               v:input-option('ntriple',   'N-Triples'),
               v:input-option('nquad',     'N-Quads'),
               v:input-option('turtle',    'Turtle'),
               v:input-option('rdfxml',    'RDF/XML'),
               v:input-option('n3',        'N3'),
               v:input-option('trig',      'TriG'),
               v:input-option('rdfjson',   'RDF/JSON'))),
            v:submit('Insert')))
      }
      <h3>Insert a directory</h3>
      <p>Insert a directory recursively at some specific place into a
         specific database.  The optional filters are regex expressions (like
         "2012-03-[0-9]+\.xml" for instance). This requires the directory to
         be on the same machine as MarkLogic itself, and the path to be
         absolute. It is an error if the directory already exists in the
         database.</p>
      <p>The set of files to include is computed as following: first we
         start with all the files in the directory, including all of its
         descendants. If the include filter is provided, only the file with
         the filename matching the filter are included, all the other files
         are discarded (the match is done over the filename only, after the
         last '/', also for directories). If the exclude filter is provided,
         the set of selected files is further restricted by getting rid of
         the files matching the filter.</p>
      {
         v:form('insert', (
            v:input-text('dir', 'Directory', 'The directory to insert, om the filesystem'),
            v:input-select-databases('database', 'Target database'),
            v:input-text('uri', 'Target directory', 'The URI of the target directory, in the database'),
            v:input-text('include', 'Include', 'An optional include filter pattern'),
            v:input-text('exclude', 'Exclude', 'An optional exclude filter pattern'),
            v:submit('Insert')))
      }
      <h3>Insert a zipped directory</h3>
      <p>Insert a directory based on a ZIP file. The ZIP file is expanded to
         create the content of the directory on the database. It is an error
         if the directory already exists in the database.</p>
      {
         v:form('insert', (
            v:input-file('zipdir', 'Zip to insert'),
            v:input-select-databases('database', 'Target database'),
            v:input-text('uri', 'Target directory', 'The URI of the target directory, in the database'),
            v:submit('Insert')))
      }
      <h3>Delete a document</h3>
      <p>Delete a document from a database. It is an error if there is no
         such document in the database.</p>
      {
         v:form('delete', (
            v:input-text('doc', 'Document', 'The URI of the document to delete from the database'),
            v:input-select-databases('database', 'Database'),
            v:submit('Delete')))
      }
      <h3>Delete a directory</h3>
      <p>Delete a directory entirely from a database. It is an error if there
         is no such directory in the database.</p>
      {
         v:form('delete', (
            v:input-text('dir', 'Directory', 'The URI of the directory to delete from the database'),
            v:input-select-databases('database', 'Database'),
            v:submit('Delete')))
      }
   </wrapper>/*
};

v:console-page('../', 'tools', 'Document manager', local:page#0)

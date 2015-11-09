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
      <h3>Browse documents</h3>
      <p>Browse the documents within a database, in a hierarchical kind of way
         (based on the directory "structure").</p>
      {
         v:form('tools/browse-db', (
            v:input-select-databases('database', 'Database'),
            v:submit('Documents')))
      }
      <h3>Browse triples</h3>
      <p>Browse the RDF resources within a database.  Only available for the databases
         with the triple index enabled.</p>
      {
         v:form('tools/browse-triples', (
            v:input-select-databases(
               'database',
               'Database',
               function($db) { $db/xs:boolean(a:triple-index) }),
            v:submit('Resources')))
      }
   </wrapper>/*
};

v:console-page('./', 'browser', 'Browser', local:page#0)

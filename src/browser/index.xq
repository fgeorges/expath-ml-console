xquery version "3.0";

(:~
 : The document manager page.
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare variable $databases     := a:get-databases()/a:database;
declare variable $triple-stores := $databases[xs:boolean(a:triple-index)];

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   <wrapper>
      <p>The browser lets you browse content on a database of your choice, any
         database.  You can brose content in several ways, depending on whether you
         want to browse triples or documents, by directories or by collections.</p>
      <p>Displaying one document whilst browsing will show you information about
         the document, and let you edit it (unless it is binary), with syntax
         highlighting support for XML and XQuery documents.  You can also edit
         the permissions of the document.</p>
      <h3>Directories</h3>
      <p>Browse the documents within a database, in a hierarchical kind of way
         (based on the directory "structure").</p>
      {
         v:form('tools/browse-db', (
            v:input-select-databases('database', 'Database', $databases),
            v:submit('Browse')))
      }
      <h3>Collections</h3>
      <p>Browse the documents within a database, based on the collections.</p>
      {
         v:form('tools/browse-colls', (
            v:input-select-databases('database', 'Database', $databases),
            v:submit('Browse')))
      }
      <h3>Triples</h3>
      <p>Browse the RDF resources within a database.  Only available for the databases
         with the triple index enabled.</p>
      {
         v:form('tools/browse-triples', (
            v:input-select-databases('database', 'Database', $triple-stores),
            v:submit('Browse')))
      }
<!--
      <h3>Classes</h3>
      <p>Browse the RDF classes within a database.  Only available for the databases
         with the triple index enabled.</p>
      {
         v:form('tools/browse-classes', (
            v:input-select-databases('database', 'Database', $triple-stores),
            v:submit('Browse')))
      }
-->
   </wrapper>/*
};

v:console-page('./', 'browser', 'Browser', local:page#0)

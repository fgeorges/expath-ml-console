xquery version "3.0";

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
   (: <img class="left" src="images/machine.jpg" alt="Machine"/> :)
   <wrapper>
      <div class="jumbotron">
         <h1>EXPath Console</h1>
         <p><em>(: Managing your portable Extensions, Packages and Web
            Applications :)</em></p>
      </div>
      <p>You will find the following sections in the Console:</p>
      <ul> {
         for $p in $v:pages/*
         return
            <li>
               <a href="{ $p/xs:string(@name) }">{ $p/xs:string(@title) }</a>
           </li>
      }
      </ul>
      <p>You will find the following types of component in the Console:</p>
      <ul>
         <li>
            { v:db-link('#', 'database') } -
            a database (all types of database: content, schemas, security, etc.)
         </li>
         <li>
            { v:as-link('#', 'appserver') } -
            an application server (all types of appserver: HTTP, XDBC, WebDAV or ODBC)
         </li>
         <li>
            { v:doc-link('#', 'document') } -
            a document (all types of document: XML, JSON, text or binary)
         </li>
         <li>
            { v:coll-link('#', 'collection') } -
            a collection
         </li>
         <li>
            { v:dir-link('#', 'directory') } -
            a directory (materialized as a property document or not, for document
            or collection URIs)
         </li>
         <li>
            { v:rsrc-link('#', 'resource') } -
            an RDF resource (that is, an IRI which is subject of at least one triple)
         </li>
         <li>
            { v:prop-link('#', 'property') } -
            an RDF property
         </li>
         <li>
            { v:class-link('#', 'class') } -
            an RDF class
         </li>
      </ul>
   </wrapper>/*
};

v:console-page('', 'home', 'EXPath Console', local:page#0)

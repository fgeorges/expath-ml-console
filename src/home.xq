xquery version "3.0";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "lib/tools.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "lib/view.xqy";
import module namespace i = "http://expath.org/ns/ml/console/init"  at "init/lib-init.xqy";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

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
      {
         t:unless(i:is-init(),
            <div class="row">
               <div class="col"/>
               <div class="col-8">
                  <div class="alert alert-warning" role="alert">
                     <strong>Not initialized</strong> Although you can use the Console as is, you
                     should consider initializing it through the <a href="init">init area</a>.
                  </div>
               </div>
               <div class="col"/>
            </div>)
      }
      <p>You will find the following sections in the Console:</p>
      <ul> {
         for $p in $v:pages/c:page
         return
            <li>
               <a href="{ $p/xs:string(@name) }">{ $p/xs:string(@title) }</a>
            </li>
      }
      </ul>
      <p>You will find the following types of component in the Console:</p>
      <ul>
         <li>
            { v:proj-link('#', 'project') } -
            a project
         </li>
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
            a directory (materialized as a property document or not, when browsing both
            document and collection URIs)
         </li>
         <li>
            { v:rsrc-link('#', 'resource', ()) } -
            an RDF resource (that is, an IRI which is subject of at least one triple)
         </li>
         <li>
            { v:prop-link('#', 'property', ()) } -
            an RDF property
         </li>
         <li>
            { v:class-link('#', 'class', ()) } -
            an RDF class
         </li>
      </ul>
      <p>The Console should be intuitive to use, but you can find documentation on the
         <a href="https://github.com/fgeorges/expath-ml-console">GitHub repository</a>.</p>
   </wrapper>/*
};

v:console-page('', 'home', 'EXPath Console', local:page#0)

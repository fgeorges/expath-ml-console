xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page()
   as element(table)
{
   <table class="table table-bordered datatable" id="prof-detail">
      <thead>
         <th>Name</th>
         <th>Schema</th>
         <th>Security</th>
         <th>Triggers</th>
         <th>Triples?</th>
      </thead>
      <tbody> {
         for $db       in a:get-databases()/a:database
         let $name     := $db/fn:string(a:name)
         let $schema   := $db/a:schema/fn:string(.)
         let $security := $db/a:security/fn:string(.)
         let $triggers := $db/a:triggers/fn:string(.)
         order by $name
         return
            <tr>
               <td>{ v:db-link('db/' || $name,     $name) } </td>
               <td>{ $schema   ! v:db-link('db/' || ., .) } </td>
               <td>{ $security ! v:db-link('db/' || ., .) } </td>
               <td>{ $triggers ! v:db-link('db/' || ., .) } </td>
               <td> {
                  if ( $db/xs:boolean(a:triple-index) ) then (
                     attribute { 'style' } { 'color: green' }, (:'&#x2611;':) '&#x2713;'
                  )
                  else (
                     attribute { 'style' } { 'color: red' }, (:'&#x2610;':) '&#x2717;'
                  )
               }
               </td>
            </tr>
      }
      </tbody>
   </table>
};

v:console-page('../', 'db', 'Databases', local:page#0)

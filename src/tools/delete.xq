xquery version "3.0";

(:~
 : Delete a document or a directory from a specific database.
 :
 : Accept the following request fields for a document (all mandatory):
 :   - database: the ID of the database containing the document to delete
 :   - doc: the URI of the document to delete (must not end with a '/')
 :
 : Accept the following request fields for a directory (all mandatory):
 :   - database: the ID of the database containing the directory to delete
 :   - dir: the URI of the directory to delete (must end with a '/')
 :
 : TODO: Split into 2 different queries for the 2 cases above...?
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare option xdmp:update "true";

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   (: TODO: Check the params are there, and validate them... :)
   let $db         := t:mandatory-field('database')
   let $back-url   := t:mandatory-field('back-url')
   let $back-label := t:mandatory-field('back-label')
   let $doc        := t:optional-field('doc', ())
   let $dir        := t:optional-field('dir', ())
   let $count      := fn:count(($doc, $dir))
   return (
      if ( $count ne 1 ) then (
         <p><b>Error</b>: Exactly 1 parameter out of "doc" and "dir" should be
            provided. Got { $count } of them.  Doc is "{ $doc }" and dir is
            "{ $dir }".</p>
      )
      else if ( fn:exists($doc) ) then (
         if ( a:exists-on-database($db, $doc) ) then (
            a:remove-doc($db, $doc),
            <p>Document successfully deleted from { $doc }.</p>
         )
         else (
            <p><b>Error</b>: The document "{ $doc }" does not exist on the
               database "{ $db }".</p>
         )
      )
      else (
         a:remove-directory($db, $dir),
         <p>Directory successfully deleted from { $dir }.</p>
      ),
      <p>Back to <a href="{ $back-url }">{ $back-label }</a>.</p>
   )
};

let $top := t:mandatory-field('top')
return
   v:console-page($top, 'tools', 'Tools', local:page#0)

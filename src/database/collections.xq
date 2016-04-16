xquery version "3.0";

import module namespace b = "http://expath.org/ns/ml/console/browse" at "browse-lib.xql";
import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h   = "http://www.w3.org/1999/xhtml";
declare namespace cts = "http://marklogic.com/cts";
declare namespace map = "http://marklogic.com/xdmp/map";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $path := t:optional-field('path', ())[.];

declare variable $db-root     := b:get-db-root($path);
declare variable $webapp-root := $db-root || '../../';

(:~
 : The page content, in case the DB does not exist.
 :)
declare function local:page--no-db($db as xs:string)
   as element(h:p)
{
   <p><b>Error</b>: There is no database "<code>{ $db }</code>".</p>
};

(:~
 : The page content, in case the collection lexicon is not enabled on the DB.
 :)
declare function local:page--no-lexicon($db as xs:string)
   as element(h:p)
{
   <p><b>Error</b>: The collection lexicon is not enabled on the database
      { v:db-link($db-root || 'colls', $db) }.  It is required to browse
      the collections.</p>
};

declare function local:display-coll($c as xs:string)
   as element(h:li)+
{
   let $isdir  := fn:ends-with($c, '/')
   let $isroot := $c eq '/' or fn:matches($c, '^http://[^/]+/$')
   let $name   := fn:tokenize($c, '/')[fn:last() - (1[$isdir], 0)[1]]
   let $label  := if ( $isroot ) then $c else ($name || '/'[$isdir])
   return
      (: if ends with a slash... :)
      if ( $isdir ) then (
         (: display as a "dir" :)
         <li> {
            v:dir-link(
               if ( $isroot ) then
                  ( 'colls' || '/'[fn:not(fn:starts-with($c, '/'))] || $c )
               else
                  ( fn:encode-for-uri($name) || '/' ),
               $label)
         }
         </li>,
         (: and maybe as a "final collection" :)
         if ( fn:exists(cts:collection-match($c)) ) then
            <li> {
               v:coll-link($db-root || 'colls?coll=' || fn:encode-for-uri($c), $label)
            }
            </li>
         else
            ()
      )
      (: if not it is a "final collection" :)
      else (
         <li> {
            v:coll-link($db-root || 'colls?coll=' || fn:encode-for-uri($c), $name)
         }
         </li>
      )
};

(:~
 : Create the URL to browse to a dir or a document.
 :)
declare function local:browse-to(
   $root as xs:string,
   $uri  as xs:string
) as xs:string
{
   $root
   || 'browse'
   || '/'[fn:not(fn:starts-with($uri, '/'))]
   || fn:replace(fn:replace(fn:encode-for-uri($uri), '%2F', '/'), '%3A', ':')
};

(:~
 : The page content, in case of the 'coll' param.
 :)
declare function local:page--show-coll(
   $db    as xs:string,
   $coll  as xs:string,
   $start as xs:integer
) as element()+
{
   <p>Database: { v:db-link($db-root || 'colls', $db) }</p>,
   (: TODO: Cut it into pieces, to show links to individual "collection directories..." :)
   <p>Collection: { v:coll-link($db-root || 'colls?coll=' || fn:encode-for-uri($coll), $coll) }</p>,
   let $docs :=
         ( fn:collection($coll) ! fn:document-uri(.) )
         [fn:position() ge $start and fn:position() lt $start + $b:page-size]
   return
      if ( fn:exists($docs) ) then (
         <ul> {
            for $d in $docs
            return
               <li> {
                  v:doc-link(local:browse-to($db-root, $d), $d)
               }
               </li>
         }
         </ul>
      )
      else (
         <p>No document in the collection.</p>
      )
};

(:~
 : The page content, in case of an empty path.
 : 
 : TODO: Displays only "/" and "http://*/" for now.  Find anything else that
 : ends with a "/" as well.  Maybe even "urn:*:" URIs?
 :)
declare function local:page--empty-path($db as xs:string, $start as xs:integer)
   as element()+
{
   <p>Database: { v:db-link('colls', $db) }</p>,
   b:display-list(
      (),
      (: TODO: Retrieve collections with name with no '/', e.g. "country-data". :)
      ( '/'[fn:exists(b:get-children-coll('/', 1))],
        b:get-children-coll('http://', 1) ),
      $start,
      function($child as xs:string, $pos as xs:integer) {
         local:display-coll($child)
      },
      function($items as element(h:li)*) {
         if ( fn:exists($items) ) then (
            <p>Choose the root to navigate:</p>,
            <ul> {
               $items
            }
            </ul>
         )
         else (
            <p>No collection in the database.</p>
         )
      })
};

(:~
 : The page content, in case of displaying a "collection dir".
 :)
declare function local:page--dir($db as xs:string, $start as xs:integer)
   as element()+
{
   <p>Database: { v:db-link($db-root || 'colls', $db) }</p>,
   b:display-list(
      $path,
      b:get-children-coll($path, $start),
      $start,
      function($child as xs:string, $pos as xs:integer) {
         local:display-coll($child)
      },
      function($items as element(h:li)*) {
         if ( fn:exists($items) ) then
            <ul> {
               $items
            }
            </ul>
         else
            <p>The collection has no "sub-collection".</p>
      })
};

(:~
 : The overall page function.
 :)
declare function local:page(
   $name  as xs:string,
   $path  as xs:string?,
   $coll  as xs:string?,
   $start as xs:integer
) as element()+
{
   let $db := a:get-database($name)
   return
      (: TODO: In this case, we should return "404 Not found". :)
      if ( fn:empty($db) ) then (
         local:page--no-db($name)
      )
      (: the collection lexicon is not required to show a specific collection by name :)
      else if ( fn:exists($coll) ) then (
         local:page--show-coll($name, $coll, $start)
      )
      (: TODO: In this case, we should NOT return "200 OK". :)
      else if ( fn:not($db/a:lexicons/xs:boolean(a:coll)) ) then (
         local:page--no-lexicon($name)
      )
      else if ( fn:empty($path) ) then (
         local:page--empty-path($name, $start)
      )
      else (
         local:page--dir($name, $start)
      )
};

let $db    := t:mandatory-field('name')
let $coll  := t:optional-field('coll', ())[.]
let $start := xs:integer(t:optional-field('start', 1)[.])
return
   v:console-page($webapp-root, 'browser', 'Browse collections', function() {
      a:query-database($db, function() {
         local:page($db, $path, $coll, $start)
      })
   })

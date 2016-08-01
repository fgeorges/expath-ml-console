xquery version "3.0";

(: TODO: Add a live completion mechanism (to suggest URIs of directories, documents,
 : collections or triples, as the user types down...)
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h = "http://www.w3.org/1999/xhtml";

declare function local:db-link($name as xs:string?)
   as element()
{
   if ( fn:exists($name[.]) ) then
      $name ! v:db-link(., .)
   else
      <em>none</em>
};

declare function local:popover($title as xs:string, $content as xs:string)
   as attribute()+
{
   attribute { 'data-toggle'    } { 'popover' },
   attribute { 'data-trigger'   } { 'hover' },
   attribute { 'data-placement' } { 'top' },
   attribute { 'title'          } { $title },
   attribute { 'data-content'   } { $content }
};

declare function local:input(
   $name  as xs:string,
   $label as xs:string,
   $hint  as xs:string,
   $title as xs:string,
   $help  as xs:string
) as element(div)
{
   v:input-text($name, $label, $hint, local:popover($title, $help))
};

declare function local:page($name as xs:string)
   as element()+
{
   let $db       := a:get-database($name)
   let $schema   := $db/a:schema/fn:string(.)
   let $security := $db/a:security/fn:string(.)
   let $triggers := $db/a:triggers/fn:string(.)
   return (

      <p>The database { $name ! v:db-link(., .) } is associated to the following databases:</p>,
      <ul>
         <li>Schema:   { local:db-link($schema) }</li>
         <li>Security: { local:db-link($security) }</li>
         <li>Triggers: { local:db-link($triggers) }</li>
      </ul>,

      <h3>Directories</h3>,
      v:ensure-uri-lexicon($db,
         function() {
            local:dir-area($db, $name)
         },
         function($database) {
            <p>The URI lexicon is not enabled on this database.  It is required
               to browse documents in a directory-like way.</p>
         }),

      <h3>Collections</h3>,
      v:ensure-coll-lexicon($db,
         function() {
            local:coll-area($db, $name)
         },
         function($database) {
            <p>The collection lexicon is not enabled on this database.  It is
               required to browse collections in a directory-like way.</p>
         }),

      <h3>Triples</h3>,
      v:ensure-triple-index($db,
         function() {
            local:triples-area($db, $name)
         },
         function($database) {
            <p>The triple index is not enabled on this database.  It is required
               to browse triples.</p>
         }),

      <h3>Config</h3>,
      local:config-area($db, $name)
   )
};

declare function local:dir-area($db as element(a:database), $name as xs:string)
   as element()+
{
   <p>You can browse documents in a directory-like fashion, or go straight to a
      specific directory, or go straight to a specific document:</p>,
   v:one-liner-link('Directories', $name || '/roots', 'Browse'),
   v:one-liner-form($name || '/dir', 'Go', 'get',
      v:input-text('uri', 'Directory', 'The URI of a directory')),
   v:one-liner-form($name || '/doc', 'Go', 'get',
      v:input-text('uri', 'Document', 'The URI of a document'))
};

declare function local:coll-area($db as element(a:database), $name as xs:string)
   as element()+
{
   <p>You can browse collections in a directory-like fashion, or go straight to a
      specific so-called "collection directory", or go straight to a specific
      collection:</p>,
   v:one-liner-link('Collections', $name || '/croots', 'Browse'),
   v:one-liner-form($name || '/cdir', 'Go', 'get',
      v:input-text('uri', 'Directory', 'The URI of a "collection directory"')),
   v:one-liner-form($name || '/coll', 'Go', 'get',
      v:input-text('uri', 'Collection', 'The URI of a collection'))
};

(:~
 : @todo Allow to browse restricted by collections, `rdf:type`, any query really...
 : (but by `rdf:type` is mandatory...)
 :)
declare function local:triples-area($db as element(a:database), $name as xs:string)
   as element()+
{
   (:
      TODO: Classes and rulesets still to be supported below...
   <p>You can browse RDF resources and classes, or go straight to a specific one (either by
      its full IRI, or by the abbreviated CURIE syntax).</p>,
   <p>The rule sets to apply are those selected below.</p>,
   :)
   <p>You can browse RDF resources, or go straight to a specific one (either by
      its full IRI, or by the abbreviated CURIE syntax).</p>,
   v:one-liner-link('Resources', $name || '/triples', 'Browse'),
   v:one-liner-form($name || '/triples', 'Go', 'get',
      v:input-text('rsrc', 'Resource IRI', 'The IRI of a resource')),
   v:one-liner-form($name || '/triples', 'Go', 'get',
      v:input-text('init-curie', 'Resource CURIE', 'The CURIE of a resource'))

   (:
      TODO: Work on class browsing (or just re-work it...)
   ,
   v:one-liner-link('Classes',   $name || '/classes', 'Browse'),
   v:one-liner-form($name || '/classes', 'Go',
      v:input-text('super', 'Class IRI', 'The IRI of a class')),
   v:one-liner-form($name || '/classes', 'Go',
      v:input-text('curie', 'Class CURIE', 'The CURIE of a class'))
   :)

   (:
      TODO: Add support for rulesets, in a list or a plain text field...
   ,
   <h4>Rulesets</h4>,
   <p>TODO: Display and select the rule sets...</p>,
   <ul style="list-style-type: none"> {
      (: TODO:... :)
      let $dir := '/opt/MarkLogic/Config/'
      (: TODO: Make sure the right values are passed above... :)
      (: Would probably write some pieec of JavaScript to construct, and pass the value,
         something like "domain,range,sameAs"... :)
      for $r at $pos in
            a:browse-files($dir, function($file) {
               fn:substring-after($file, $dir)[fn:ends-with(., '.rules')]
                  ! fn:substring-before(., '.')
            })
      order by $r
      return
         <li>
            <input name="ruleset-name-{ $pos }"  type="hidden" value="{ $r }"/>
            <input name="ruleset-check-{ $pos }" type="checkbox"/>
            { ' ' }
            { $r }
         </li>
   }
   </ul>
   :)
};

declare function local:config-area($db as element(a:database), $name as xs:string)
   as element()+
{
   <p>You can configure the browser behaviour on this database with the following config
      documents:</p>,
   <ul>
      <li> {
         if ( fn:doc-available($t:config-doc) ) then
            v:doc-link($db/a:name || '/', $t:config-doc)
         else
            <code>{ $t:config-doc }</code>
      }
      </li>
      <li> {
         if ( fn:doc-available($t:defaults-doc) ) then
            v:doc-link($db/a:name || '/', $t:defaults-doc)
         else
            <code>{ $t:defaults-doc }</code>
      }
      </li>
   </ul>,
   let $filename := fn:tokenize($t:config-doc, $t:config-doc/@sep)[fn:last()]
   return (
      <p>The former, <code>{ $filename }</code>, contains the configuration specific to this
         database: { $db/a:name ! v:db-link(., .) }. It must be in the same database it configures.
         It can define specific prefixes for triples, as well as URI schemes for brwosing documents,
         directories amd collections.</p>,
      local:insert-config-doc($t:config-doc, $filename, $db/a:name)
   ),
   let $filename := fn:tokenize($t:defaults-doc, $t:defaults-doc/@sep)[fn:last()]
   return (
      <p>The latter, <code>{ $filename }</code>, has the same format, but must be on the content
         database attached to the EXPath Console app server.  It provides then default values to be
         applied to all databases.</p>,
      local:insert-config-doc($t:defaults-doc, $filename, $db/a:name)
   )
};

declare function local:insert-config-doc($path as element(), $filename as xs:string, $db as xs:string)
   as element(h:form)?
{
   t:unless(fn:doc-available($path),
      v:one-liner-link($filename, '../loader/insert', 'Create', (
         v:input-hidden('uri',      $path),
         (: TODO: Will need to remove root and sep from here too... :)
         v:input-hidden('root',     $path/@root),
         v:input-hidden('sep',      $path/@sep),
         v:input-hidden('format',   'xml'),
         v:input-hidden('database', $db),
         v:input-hidden('redirect', 'true'),
         v:input-hidden('new-file', 'true'),
         v:input-hidden('file',
'<config xmlns="http://expath.org/ns/ml/console">
<!--
   <uri-schemes>
      <scheme sep="/">
         <root>
            <start>.</start>
         </root>
         <regex match="1">(\.[^/]+/).*</regex>
      </scheme>
   </uri-schemes>
   <triple-prefixes>
      <decl>
         <prefix>ns</prefix>
         <uri>http://example.org/my/prefix#</uri>
      </decl>
   </triple-prefixes>
-->
</config>'))))
};

let $name := t:mandatory-field('name')
return
   v:console-page(
      '../../',
      'db',
      'Database',
      function() {
         v:ensure-db($name, function() {
            local:page($name)
         })
      })

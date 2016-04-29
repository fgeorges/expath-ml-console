xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

(: TODO:... :)
declare variable $dir := '/opt/MarkLogic/Config/';

declare function local:db-link($name as xs:string?)
   as element()
{
   if ( fn:exists($name[.]) ) then
      $name ! v:db-link(., .)
   else
      <em>none</em>
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
      <p>You can browse documents in a directory-like fashion, or go straight to a specific
         directory or document.</p>,
      v:one-liner-link('Directories', $name || '/browse', 'Browse'),
      v:one-liner-form($name || '/browse', 'Go',
         v:input-text('init-path', 'Directory', 'The URI of a directory')),
      v:one-liner-form($name || '/browse', 'Go',
         v:input-text('init-path', 'Document', 'The URI of a document')),
      <h3>Collections</h3>,
      <p>You can browse collections in a directory-like fashion, or go straight to a specific
         collection prefix (to continue browsing) or to a specific collection (to list its
         documents).</p>,
      v:one-liner-link('Collections', $name || '/colls', 'Browse'),
      v:one-liner-form($name || '/colls', 'Go',
         v:input-text('init-path', 'Collection "prefix"', 'The beginning of the URI of a collection (dir-like)')),
      v:one-liner-form($name || '/colls', 'Go',
         v:input-text('coll', 'Collection', 'The URI of a collection')),
      t:when(xs:boolean($db/a:triple-index), (
         <h3>Triples</h3>,
         <p>You can browse RDF resources and classes, or go straight to a specific one (either by
            its full IRI, or by the abbreviated CURIE syntax).</p>,
         <p>The rule sets to apply are those selected below.</p>,
         v:one-liner-link('Resources', $name || '/triples', 'Browse'),
         v:one-liner-form($name || '/triples', 'Go',
            v:input-text('rsrc', 'Resource IRI', 'The IRI of a resource')),
         v:one-liner-form($name || '/triples', 'Go',
            v:input-text('init-curie', 'Resource CURIE', 'The CURIE of a resource')),
         v:one-liner-link('Classes',   $name || '/classes', 'Browse'),
         v:one-liner-form($name || '/classes', 'Go',
            v:input-text('super', 'Class IRI', 'The IRI of a class')),
         v:one-liner-form($name || '/classes', 'Go',
            v:input-text('curie', 'Class CURIE', 'The CURIE of a class'))
         (:
            TODO: Add support for rulesets, in a list or a plain text field...
         ,
         <h4>Rulesets</h4>,
         <p>TODO: Display and select the rule sets...</p>,
         <ul style="list-style-type: none"> {
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
         ))
   )
};

let $name := t:mandatory-field('name')
return
   v:console-page('../../', 'db', 'Database', function() { local:page($name) })

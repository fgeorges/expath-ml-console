xquery version "3.0";

(: TODO: Add a live completion mechanism (to suggest URIs of directories, documents,
 : collections or triples, as the user types down...)
 :)

import module namespace dbc = "http://expath.org/ns/ml/console/database/config" at "db-config-lib.xqy";

import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace xdmp = "http://marklogic.com/xdmp";

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

declare function local:page($db as element(a:database))
   as element()+
{
   let $name     := xs:string($db/a:name)
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
      v:input-text('uri', 'Directory', 'The URI of a directory', (), attribute { 'class' } { 'typeaheadDir' })),
   v:one-liner-form($name || '/doc', 'Go', 'get',
      v:input-text('uri', 'Document', 'The URI of a document', (), attribute { 'class' } { 'typeaheadDoc' }))
};

declare function local:coll-area($db as element(a:database), $name as xs:string)
   as element()+
{
   <p>You can browse collections in a directory-like fashion, or go straight to a
      specific so-called "collection directory", or go straight to a specific
      collection:</p>,
   v:one-liner-link('Collections', $name || '/croots', 'Browse'),
   v:one-liner-form($name || '/cdir', 'Go', 'get',
      v:input-text('uri', 'Directory', 'The URI of a "collection directory"', (), attribute { 'class' } { 'typeaheadCdir' })),
   v:one-liner-form($name || '/coll', 'Go', 'get',
      v:input-text('uri', 'Collection', 'The URI of a collection', (), attribute { 'class' } { 'typeaheadCdoc' }))
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
   v:one-liner-link('Resources', $name || '/triples', 'Browse', 'get',
      v:input-hidden('rulesets', '', attribute { 'class' } { 'expathRulesets' })),
   v:one-liner-form($name || '/triples', 'Go', 'get', (
      v:input-hidden('rulesets', '', attribute { 'class' } { 'expathRulesets' }),
      v:input-text('rsrc', 'Resource IRI', 'The IRI of a resource', (), attribute { 'class' } { 'typeaheadRsrc' }))),
   v:one-liner-form($name || '/triples', 'Go', 'get', (
      v:input-hidden('rulesets', '', attribute { 'class' } { 'expathRulesets' }),
      v:input-text('init-curie', 'Resource CURIE', 'The CURIE of a resource'))),
   <div class="form-horizontal"> {
      v:input-select-rulesets('rulesets', 'Rulesets',
         dbc:config-default-rulesets($db),
         (),
         attribute { 'id' } { 'rulesetPicker' })
   }
   </div>

   (:
      TODO: Work on class browsing (or just re-work it...)
   ,
   v:one-liner-link('Classes',   $name || '/classes', 'Browse'),
   v:one-liner-form($name || '/classes', 'Go',
      v:input-text('super', 'Class IRI', 'The IRI of a class')),
   v:one-liner-form($name || '/classes', 'Go',
      v:input-text('curie', 'Class CURIE', 'The CURIE of a class'))
   :)
};

declare function local:config-area($db as element(a:database), $name as xs:string)
   as element()+
{
   let $sys-db             := a:get-database(xdmp:database())
   let $sys-path           := dbc:config-system-doc($db)
   let $config-available   := t:query($db, function() { fn:doc-available($dbc:config-doc) })
   let $sys-available      := fn:doc-available($sys-path)
   let $defaults-available := fn:doc-available($dbc:defaults-doc)
   return (
      <p>You can configure the browser behaviour on this database with the following config
         documents (in order of precedence):</p>,
      <ul>
         <li> {
            if ( $config-available ) then
               v:doc-link($db/a:name || '/', $dbc:config-doc)
            else
               <code>{ xs:string($dbc:config-doc) }</code>
         }
         </li>
         <li> {
            if ( $sys-available ) then
               v:doc-link($sys-db/a:name || '/', $sys-path)
            else
               <code>{ xs:string($sys-path) }</code>
         }
         </li>
         <li> {
            if ( $defaults-available ) then
               v:doc-link($sys-db/a:name || '/', $dbc:defaults-doc)
            else
               <code>{ xs:string($dbc:defaults-doc) }</code>
         }
         </li>
      </ul>,
      let $filename := fn:tokenize($dbc:config-doc, $dbc:config-doc/@sep)[fn:last()]
      return (
         <p>The former, <code>{ $filename }</code> on { $db/a:name ! v:db-link(., .) }, contains the
            configuration specific to this database.</p>,
         t:unless($config-available,
            local:insert-config-doc($dbc:config-doc, $db/a:name))
      ),
      let $filename := fn:tokenize($sys-path, $sys-path/@sep)[fn:last()]
      return (
         <p>The second one, <code>{ $filename }</code> on { $sys-db/a:name ! v:db-link(., .) }, is
            the same but is stored in the ML Console database.</p>,
         t:unless($sys-available,
            local:insert-config-doc($sys-path, $sys-db/a:name))
      ),
      let $filename := fn:tokenize($dbc:defaults-doc, $dbc:defaults-doc/@sep)[fn:last()]
      return (
         <p>The latter, <code>{ $filename }</code> on { $sys-db/a:name ! v:db-link(., .) }, contains
            default values applied to all databases.</p>,
         t:unless($defaults-available,
            local:insert-config-doc($dbc:defaults-doc, $sys-db/a:name))
      )
   )
};

declare function local:insert-config-doc($path as element(), $db as xs:string)
   as element(h:form)?
{
   v:one-liner-link('Create it!', '../loader/insert', 'Create', (
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
            <fixed>/</fixed>
         </root>
         <regex>/.*</regex>
      </scheme>
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
   <default-rulesets>
      <ruleset>domain.rules</ruleset>
      <ruleset>range.rules</ruleset>
   </default-rulesets>
-->
</config>')))
};

let $name := t:mandatory-field('name')
return
   v:console-page(
      '../../',
      'db',
      'Database',
      function() {
         v:ensure-db($name, local:page#1)
      },
      (<lib>typeahead</lib>,
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript">
          // initiate the completion engines
          var amp = String.fromCharCode(38);
          function makeBloodhound(kind) {{
             return new Bloodhound({{
                datumTokenizer: Bloodhound.tokenizers.whitespace,
                queryTokenizer: Bloodhound.tokenizers.whitespace,
                remote: {{
                   url: '{ $name }/matching?type=' + kind + amp + 'input=%QUERY',
                   wildcard: '%QUERY'
                }}
             }});
          }};
          [ 'dir', 'doc', 'cdir', 'cdoc', 'rsrc' ].forEach(function(kind) {{
             var camel = kind.slice(0, 1).toUpperCase() + kind.slice(1);
             var clazz = '.typeahead' + camel;
             $(clazz).typeahead({{
                hint: true,
                highlight: true,
                minLength: 3
             }},
             {{
               name:   kind,
               source: makeBloodhound(kind)
             }})
             .on('typeahead:asyncrequest', function() {{
                $(clazz).addClass('loading');
             }})
             .on('typeahead:asynccancel typeahead:asyncreceive', function() {{
                $(clazz).removeClass('loading');
             }});
          }});
       </script>,
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript">
          // set the change listener on the ruleset picker
          // the picker is id=rulesetPicker, replicates are class=expathRulesets
          $('#rulesetPicker').change(function() {{
             var val = $(this).val();
             var str = val ? val.toString() : '';
             $('.expathRulesets').val(str);
          }});
       </script>))

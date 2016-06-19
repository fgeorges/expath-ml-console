xquery version "3.0";

(: TODO: Add a live completion mechanism (to suggest URIs of directories, documents,
 : collections or triples, as the user types down...)
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

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
         })
   )
};

(:~
 : @todo Factorize out with `local:coll-area()`.
 :)
declare function local:dir-area($db as element(a:database), $name as xs:string)
   as element()+
{
   <p>You can browse documents in a directory-like fashion:</p>,
   v:one-liner-link('Directories', $name || '/roots', 'Browse'),

   <p>Or go straight to a specific directory:</p>,
   v:form($name || '/dir', attribute { 'id' } { 'dirGoDir' },
      (local:input('uri', 'Directory', 'The URI of a directory', 'Diretory URI',
          '&lt;p&gt;The URI of a directory.  It must end with the path separator.
          Various URI schemes are supported:&lt;/p&gt;
          &lt;ul&gt;
             &lt;li&gt;starting with "/" or "http://" and using "/" as the path
             separator&lt;/li&gt;
             &lt;li&gt;starting with "urn:" and using ":" as the path
             separator&lt;/li&gt;
             &lt;li&gt;containing "/" as the path separator (the root being
             everything before the first slash.)&lt;/li&gt;
          &lt;/ul&gt;'),
       local:input('root', 'Root', 'The root', 'URI root',
          '&lt;p&gt;The part of the URI to be considered as the "root".  That is, the
          first level of directory in the URI.&lt;/p&gt;
          &lt;p&gt;If you leave it blank, the Console will try to infer it from the URI
          (if it starts with "/", "http://" or "urn:").&lt;/p&gt;'),
       local:input('sep', 'Separator', 'The path separator', 'Path separator',
          '&lt;p&gt;The string used as a path separator in the URI.  Typically, it is "/",
          but also ":" for URNs, but it can be different in specific cases.&lt;/p&gt;
          &lt;p&gt;If you leave it blank, the Console will try to infer it from the URI
          (if it starts with "/", "http://" or "urn:").&lt;/p&gt;'),
       v:submit('Go')),
      'get'),

   <p>Or go straight to a specific document:</p>,
   v:form($name || '/doc', attribute { 'id' } { 'dirGoDoc' },
      (local:input('uri', 'Document', 'The URI of a document', 'Document URI',
          '&lt;p&gt;The URI of a document.  Various URI schemes are supported:&lt;/p&gt;
          &lt;ul&gt;
             &lt;li&gt;starting with "/" or "http://" and using "/" as the path
             separator&lt;/li&gt;
             &lt;li&gt;starting with "urn:" and using ":" as the path
             separator&lt;/li&gt;
             &lt;li&gt;containing "/" as the path separator (the root being
             everything before the first slash.)&lt;/li&gt;
          &lt;/ul&gt;'),
       local:input('root', 'Root', 'The root', 'URI root',
          '&lt;p&gt;The part of the URI to be considered as the "root".  That is, the
          first level of directory in the URI.&lt;/p&gt;
          &lt;p&gt;If you leave it blank, the Console will try to infer it from the URI
          (if it starts with "/", "http://" or "urn:").&lt;/p&gt;'),
       local:input('sep', 'Separator', 'The path separator', 'Path separator',
          '&lt;p&gt;The string used as a path separator in the URI.  Typically, it is "/",
          but also ":" for URNs, but it can be different in specific cases.&lt;/p&gt;
          &lt;p&gt;If you leave it blank, the Console will try to infer it from the URI
          (if it starts with "/", "http://" or "urn:").&lt;/p&gt;'),
       v:submit('Go')),
      'get')
};

(:~
 : @todo Factorize out with `local:dir-area()`.
 :)
declare function local:coll-area($db as element(a:database), $name as xs:string)
   as element()+
{
   <p>You can browse collections in a directory-like fashion:</p>,
   v:one-liner-link('Collections', $name || '/croots', 'Browse'),

   <p>Or go straight to a specific so-called "collection directory":</p>,
   v:form($name || '/cdir', attribute { 'id' } { 'collGoDir' },
      (local:input('uri', 'Directory', 'The URI of a "collection directory"', 'Collection diretory URI',
          '&lt;p&gt;The URI of a "collection directory".  It must end with the path
          separator.  Various URI schemes are supported:&lt;/p&gt;
          &lt;ul&gt;
             &lt;li&gt;starting with "/" or "http://" and using "/" as the path
             separator&lt;/li&gt;
             &lt;li&gt;starting with "urn:" and using ":" as the path
             separator&lt;/li&gt;
             &lt;li&gt;containing "/" as the path separator (the root being
             everything before the first slash.)&lt;/li&gt;
          &lt;/ul&gt;'),
       local:input('root', 'Root', 'The root', 'URI root',
          '&lt;p&gt;The part of the URI to be considered as the "root".  That is, the
          first level of directory in the URI.&lt;/p&gt;
          &lt;p&gt;If you leave it blank, the Console will try to infer it from the URI
          (if it starts with "/", "http://" or "urn:").&lt;/p&gt;'),
       local:input('sep', 'Separator', 'The path separator', 'Path separator',
          '&lt;p&gt;The string used as a path separator in the URI.  Typically, it is "/",
          but also ":" for URNs, but it can be different in specific cases.&lt;/p&gt;
          &lt;p&gt;If you leave it blank, the Console will try to infer it from the URI
          (if it starts with "/", "http://" or "urn:").&lt;/p&gt;'),
       v:submit('Go')),
      'get'),

   <p>Or go straight to a specific collection:</p>,
   v:form($name || '/coll', attribute { 'id' } { 'collGoColl' },
      (local:input('uri', 'Collection', 'The URI of a collection', 'Collection URI',
          '&lt;p&gt;The URI of a collection.  Various URI schemes are supported:&lt;/p&gt;
          &lt;ul&gt;
             &lt;li&gt;starting with "/" or "http://" and using "/" as the path
             separator&lt;/li&gt;
             &lt;li&gt;starting with "urn:" and using ":" as the path
             separator&lt;/li&gt;
             &lt;li&gt;containing "/" as the path separator (the root being
             everything before the first slash.)&lt;/li&gt;
          &lt;/ul&gt;'),
       local:input('root', 'Root', 'The root', 'URI root',
          '&lt;p&gt;The part of the URI to be considered as the "root".  That is, the
          first level of directory in the URI.&lt;/p&gt;
          &lt;p&gt;If you leave it blank, the Console will try to infer it from the URI
          (if it starts with "/", "http://" or "urn:").&lt;/p&gt;'),
       local:input('sep', 'Separator', 'The path separator', 'Path separator',
          '&lt;p&gt;The string used as a path separator in the URI.  Typically, it is "/",
          but also ":" for URNs, but it can be different in specific cases.&lt;/p&gt;
          &lt;p&gt;If you leave it blank, the Console will try to infer it from the URI
          (if it starts with "/", "http://" or "urn:").&lt;/p&gt;'),
       v:submit('Go')),
      'get')
};

(:~
 : @todo Factorize out with other `local:*-area()` functions?
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
   v:one-liner-form($name || '/triples', 'Go',
      v:input-text('rsrc', 'Resource IRI', 'The IRI of a resource')),
   v:one-liner-form($name || '/triples', 'Go',
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
      },
      <script type="text/javascript">
         $(document).ready(function () {{

            // the change handler for "go to" forms
            function formChange(form, field) {{
               var uri  = field.val();
               var root = $(':input[name=root]', form);
               var sep  = $(':input[name=sep]',  form);
               if ( root.val() || sep.val() ) {{
                  // if `root` or `sep` is set, do not change them
               }}
               // TODO: Externalize "/", "http://", "." and "urn:"
               else if ( uri.startsWith('/') ) {{
                  root.val('/');
                  sep.val('/');
               }}
               else if ( uri.startsWith('http://') ) {{
                  root.val(uri.substring(0, uri.indexOf('/', 7) + 1));
                  sep.val('/');
               }}
               else if ( uri.startsWith('urn:') ) {{
                  root.val(uri.substring(0, uri.indexOf(':', 4) + 1));
                  sep.val(':');
               }}
               else if ( uri.indexOf('/') ) {{
                  root.val(uri.substring(0, uri.indexOf('/') + 1));
                  sep.val('/');
               }}
               else {{
                  console.log('Unknown URI format: ' + uri);
               }}
            }}

            // set the change handler on a "go to" form
            function setFormChange(form) {{
               $(':input[name=uri]', form).change(function() {{
                  formChange(form, $(this));
               }});
            }}

            // set up the "go to" forms
            setFormChange($('#dirGoDir'));
            setFormChange($('#dirGoDoc'));
            setFormChange($('#collGoDir'));
            setFormChange($('#collGoColl'));
         }});
      </script>)

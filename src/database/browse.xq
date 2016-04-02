xquery version "3.0";

import module namespace b   = "http://expath.org/ns/ml/console/browse" at "browse-lib.xql";
import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace bin = "http://expath.org/ns/ml/console/binary" at "../lib/binary.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace sec  = "http://marklogic.com/xdmp/security";

declare variable $path := t:optional-field('path', ())[.];

declare variable $db-root     := b:get-db-root($path);
declare variable $webapp-root := $db-root || '../../';

(:~
 : The page content, in case the DB does not exist.
 :)
declare function local:page--no-db($id as xs:unsignedLong)
   as element(h:p)
{
   <p><b>Error</b>: There is no database with the ID <code>{ $id }</code>.</p>
};

(:~
 : The page content, in case the URI lexicon is not enabled on the DB.
 :)
declare function local:page--no-lexicon($db as element(a:database))
   as element(h:p)
{
   <p><b>Error</b>: The URI lexicon is not enabled on the database
      { v:db-link($db-root || 'browse', $db/a:name) }.  It is required to
      browse the directories.</p>
};

(:~
 : The page content, in case of an init-path param.
 :
 : TODO: Is it still used?
 :)
declare function local:page--init-path($init as xs:string)
   as element(h:p)
{
   let $relative := 'browse' || '/'[fn:not(fn:starts-with($init, '/'))] || $init
   return (
      v:redirect($relative),
      <p>You are being redirected to <a href="{ $relative }">this page</a>...</p>
   )
};

(:~
 : The page content, in case of an empty path.
 : 
 : TODO: Displays only "/" and "http://*/" for now.  Find anything else that
 : ends with a "/" as well.  Maybe even "urn:*:" URIs?
 :
 : TODO: Lot of duplicated code with local:display-list(), factorize out?
 :)
declare function local:page--empty-path($db as element(a:database), $start as xs:integer)
   as element()+
{
   <p>Database: { v:db-link('browse', $db/a:name) }</p>,
   local:create-doc-form($db, ()),
   b:display-list(
      (),
      ( '/'[fn:exists(b:get-children-uri('/', 1))],
        b:get-children-uri('http://', 1) ),
      $start,
      function($child as xs:string, $pos as xs:integer) {
         <li>
            <input name="name-{ $pos }"   type="hidden" value="{ $child }"/>
            <input name="delete-{ $pos }" type="checkbox"/>
            { ' ' }
            { v:dir-link('browse/' || $child[. ne '/'], $child) }
         </li>
      },
      function($items as element(h:li)*) {
         if ( fn:exists($items) ) then (
            <p>Choose the root to navigate:</p>,
            local:display-list-children($path, $items)
         )
         else (
            <p>The database is empty.</p>
         )
      })
};

(:~
 : The page content, in case of displaying a dir.
 : 
 : TODO: Display whether the directory exists per se in MarkLogic (and its
 : properties if it has any, etc.)
 :
 : TODO: Is there a way to detect whether there is a URI Privilege for a specific
 : directory?  A way to say "the creation of docujments in this directory is
 : protected by privilege xyz..."
 :)
declare function local:page--dir($db as element(a:database), $start as xs:integer)
   as element()+
{
   <p>Database: { v:db-link($db-root || 'browse', $db/a:name) }</p>,
   local:display-list($db, $path, $start)
};

(:~
 : The page content, in case of displaying a document.
 :)
declare function local:page--doc($db as element(a:database))
   as element()+
{
   let $filename := fn:tokenize($path, '/')[fn:last()]
   let $selfref  := fn:encode-for-uri($filename)
   return (
      <p>
         { v:db-link($db-root || 'browse', $db/a:name) }
         { ' ' }
         { b:uplinks($path, fn:false()) }
         { ' ' }
         { v:doc-link($selfref, $filename) }
      </p>,
      if ( fn:not(fn:doc-available($path)) ) then (
         <p>The document <code>{ $path }</code> does not exist.</p>
      )
      else (
         <h3>Summary</h3>,
         <table class="table table-bordered datatable">
            <thead>
               <th>Name</th>
               <th>Value</th>
            </thead>
            <tbody>
               <tr>
                  <td>Type</td>
                  <td> {
                     typeswitch ( fn:doc($path)/node() )
                        case element() return 'XML'
                        case text()    return 'Text'
                        default        return 'Binary'
                  }
                  </td>
               </tr>
               <tr>
                  <td>Document URI</td>
                  <td> {
                     v:doc-link($selfref, $path)
                  }
                  </td>
               </tr>
               <tr>
                  <td>Collections</td>
                  <td> {
                     for $c in xdmp:document-get-collections($path)
                     return
                        <p style="margin-bottom: 5px"> {
                           v:coll-link($db-root || 'colls?coll=' || fn:encode-for-uri($c), $c)
                        }
                        </p>
                  }
                  </td>
               </tr>
               <tr>
                  <td>Forest</td>
                  <td>{ xdmp:forest-name(xdmp:document-forest($path)) }</td>
               </tr>
               <tr>
                  <td>Quality</td>
                  <td>{ xdmp:document-get-quality($path) }</td>
               </tr>
            </tbody>
         </table>,

         <h3>Content</h3>,
         let $doc := fn:doc($path)
         let $id  := fn:generate-id($doc)
         return
            if ( bin:is-json($doc/node()) ) then (
               v:edit-json($doc, $id, $path, $db-root)
            )
            else if ( fn:exists($doc/*) ) then (
               v:edit-xml($doc, $id, $path, $db-root)
            )
            else if ( fn:exists($doc/text()) and fn:empty($doc/node()[2]) ) then (
               (: TODO: Use the internal MarkLogic way to recognize XQuery modules? :)
               let $mode := ( 'xquery'[fn:matches($path, '\.xq[ylm]?$')],
                              'javascript'[fn:ends-with($path, '.sjs')],
                              'json'[fn:ends-with($path, '.json')],
                              'text' )[1]
               return
                  v:edit-text($doc/text(), $mode, $id, $path, $db-root)
            )
            else (
               <p>Binary document display not supported.</p>
               (:
               TODO: Implement binary doc deletion, without the ACE editor to hold the
               document URI...  Actually, should be easy to change using the ID, and
               use the URI instead...
               <button class="btn btn-danger" onclick='deleteDoc("{ $id }");'>
                  Delete
               </button>
               :)
            ),

         <h3>Properties</h3>,
         let $props := xdmp:document-properties($path)
         return
            if ( fn:exists($props) ) then
               v:display-xml($props/*)
            else
               <p>This document does not have any property.</p>,

         <h3>Permissions</h3>,
         let $perms := xdmp:document-get-permissions($path)
         return
            if ( fn:empty($perms) ) then
               <p>This document does not have any permission.</p>
            else
               <table class="table table-bordered">
                  <thead>
                     <th>Capability</th>
                     <th>Role</th>
                     <th>Remove</th>
                  </thead>
                  <tbody> {
                     for $perm       in $perms
                     let $capability := xs:string($perm/sec:capability)
                     let $role       := a:role-name($perm/sec:role-id)
                     return
                        <tr>
                           <td>{ $capability }</td>
                           <td>{ $role }</td>
                           <td> {
                              v:inline-form($webapp-root || 'tools/del-perm', (
                                 <input type="hidden" name="capability" value="{ $capability }"/>,
                                 <input type="hidden" name="role"       value="{ $role }"/>,
                                 <input type="hidden" name="uri"        value="{ $path }"/>,
                                 <input type="hidden" name="database"   value="{ $db/@id }"/>,
                                 <input type="hidden" name="redirect"   value="true"/>,
                                 (: TODO: Replace with a Bootstrap character icon... :)
                                 v:submit('Remove')))
                           }
                           </td>
                        </tr>
                  }
                  </tbody>
               </table>,

         <p>Add a permission:</p>,
         <form class="form-inline" action="{ $webapp-root }tools/add-perm" method="post">
            <div class="form-group">
               <label for="capability">Capability&#160;&#160;</label>
               <select name="capability" class="form-control">
                  <option value="read">Read</option>
                  <option value="update">Update</option>
                  <option value="insert">Insert</option>
                  <option value="execute">Execute</option>
               </select>
            </div>
            <div class="form-group">
               <label for="role">&#160;&#160;&#160;&#160;Role&#160;&#160;</label>
               <select name="role" class="form-control"> {
                  for $role in a:get-roles()/a:role/a:name
                  order by $role
                  return
                     <option value="{ $role }">{ $role }</option>
               }
               </select>
            </div>
            <input type="hidden" name="uri"      value="{ $path }"/>
            <input type="hidden" name="database" value="{ $db/@id }"/>
            <input type="hidden" name="redirect" value="true"/>
            <button type="submit" class="btn btn-default">Add</button>
         </form>
      )
   )
};

(:~
 : The overall page function.
 :)
declare function local:page(
   $id    as xs:unsignedLong,
   $path  as xs:string?,
   $init  as xs:string?,
   $start as xs:integer
) as element()+
{
   let $db := a:get-database($id)
   return
      (: TODO: In this case, we should NOT return "200 OK". :)
      if ( fn:empty($db) ) then (
         local:page--no-db($id)
      )
      (: TODO: In this case, we should NOT return "200 OK". :)
      else if ( fn:not($db/a:lexicons/xs:boolean(a:uri)) ) then (
         local:page--no-lexicon($db)
      )
      else if ( fn:exists($init) ) then (
         local:page--init-path($init)
      )
      else if ( fn:empty($path) ) then (
         local:page--empty-path($db, $start)
      )
      else if ( fn:ends-with($path, '/') ) then (
         local:page--dir($db, $start)
      )
      else (
         local:page--doc($db)
      )
};

(:~
 : Create the "create document" form.
 :)
declare function local:create-doc-form(
   $db   as element(a:database),
   $path as xs:string?
) as element()+
{
   <p id="show-files-area">
      <button class="btn btn-default"
              title="Display the upload area, to upload files or create empty documents"
              onclick="$('#files-area').slideToggle(); $('#show-files-area span').toggle();">
         <span>Add files...</span>
         <span style="display: none">Hide upload area</span>
      </button>
   </p>,

   <div style="display: none" id="files-area">

      <h4>Upload files</h4>

      <form id="fileupload" method="POST" enctype="multipart/form-data">
         <!-- The fileupload-buttonbar contains buttons to add/delete files and start/cancel the upload -->
         <div class="row fileupload-buttonbar">
            <div class="col-lg-7">
               <!-- The fileinput-button span is used to style the file input field as button -->
               <span class="btn btn-default fileinput-button">
                  <i class="glyphicon glyphicon-plus"/>
                  <span> Add files...</span>
                  <input type="file" name="files[]" multiple="true"/>
               </span>
               <span> </span>
               <button type="submit" class="btn btn-default start">
                  <i class="glyphicon glyphicon-upload"/>
                  <span> Start upload</span>
               </button>
               <span> </span>
               <button type="reset" class="btn btn-default cancel">
                  <i class="glyphicon glyphicon-ban-circle"></i>
                  <span> Cancel upload</span>
               </button>
               <!-- The global file processing state -->
               <span class="fileupload-process"></span>
            </div>
            <!-- The global progress state -->
            <div class="col-lg-5 fileupload-progress fade">
               <!-- The global progress bar -->
               <div class="progress progress-striped active" role="progressbar" aria-valuemin="0" aria-valuemax="100">
                  <div class="progress-bar progress-bar-success" style="width:0%;"></div>
               </div>
               <!-- The extended global progress state -->
               <div class="progress-extended"> </div>
            </div>
         </div>
         <!-- The table listing the files available for upload/download -->
         <table role="presentation" class="table table-striped"><tbody class="files"></tbody></table>
      </form>

      <div id="blueimp-gallery" class="blueimp-gallery blueimp-gallery-controls" data-filter=":even">
         <div class="slides"/>
         <h3 class="title"/>
         <a class="prev">‹</a>
         <a class="next">›</a>
         <a class="close">×</a>
         <a class="play-pause"/>
         <ol class="indicator"/>
      </div>

      <script id="template-upload" type="text/x-tmpl">
         {{% for (var i=0, file; file=o.files[i]; i++) {{ %}}
            <tr class="template-upload fade">
               <input type="hidden" name="database" value="{ $db/@id }"/>
               <input type="hidden" name="prefix"   value="{ $path }"/>
               <td>
                  <span class="preview"></span>
               </td>
               <td>
                  <p class="name">{{%=file.name%}}</p>
                  <strong class="error text-danger"></strong>
               </td>
               <td>
                  <p class="size">Processing...</p>
                  <div class="progress progress-striped active" role="progressbar"
                       aria-valuemin="0" aria-valuemax="100" aria-valuenow="0">
                     <div class="progress-bar progress-bar-success" style="width:0%;"/>
                  </div>
               </td>
               <td>
                  <select name="format" required="true" class="form-control">
                     {{%
                        var format = 'binary';
                        if ( file.name.endsWith('.xml') ) {{
                           format = 'xml';
                        }}
                        else if ( file.name.match('\\.(txt|text|ttl)$') ) {{
                           format = 'text';
                        }}
                     %}}
                     {{% if ( format === 'xml' ) {{ %}}
                        <option value="xml" selected="">XML</option>
                     {{% }} else {{ %}}
                        <option value="xml">XML</option>
                     {{% }} %}}
                     {{% if ( format === 'text' ) {{ %}}
                        <option value="text" selected="">Text</option>
                     {{% }} else {{ %}}
                        <option value="text">Text</option>
                     {{% }} %}}
                     {{% if ( format === 'binary' ) {{ %}}
                        <option value="binary" selected="">Binary</option>
                     {{% }} else {{ %}}
                        <option value="binary">Binary</option>
                     {{% }} %}}
                  </select>
               </td>
               <td>
                  {{% if (! (i || o.options.autoUpload) ) {{ %}}
                     <button class="btn btn-default start" disabled="true">
                        <i class="glyphicon glyphicon-upload"></i>
                        <span> Start</span>
                     </button>
                  {{% }} %}}
                  {{% if (!i) {{ %}}
                     <button class="btn btn-default cancel">
                        <i class="glyphicon glyphicon-ban-circle"></i>
                        <span> Cancel</span>
                     </button>
                  {{% }} %}}
               </td>
            </tr>
         {{% }} %}}
      </script>

      <!--
         TODO: Once a file has been uploaded, its name becomes a "clickable" link,
         which downloads the file.  Change that to be a link to the document page
         (just change the link to be a simple link, not to download anything...)
      -->
      <script id="template-download" type="text/x-tmpl">
         {{% for (var i=0, file; file=o.files[i]; i++) {{ %}}
            <tr class="template-download fade">
               <td>
                  <span class="preview">
                     {{% if (file.thumbnailUrl) {{ %}}
                        <a href="{{%=file.url%}}" title="{{%=file.name%}}" download="{{%=file.name%}}" data-gallery=""><img src="{{%=file.thumbnailUrl%}}"/></a>
                     {{% }} %}}
                  </span>
               </td>
               <td>
                  <p class="name">
                     {{% if (file.url) {{ %}}
                        <!-- {{%=file.thumbnailUrl?'data-gallery':''%}} -->
                        <!--a href="{{%=file.url%}}" title="{{%=file.name%}}" download="{{%=file.name%}}">{{%=file.name%}}</a-->
                        <a href="{{%=file.url%}}" title="{{%=file.name%}}">{{%=file.name%}}</a>
                     {{% }} else {{ %}}
                        <span>{{%=file.name%}}</span>
                     {{% }} %}}
                  </p>
                  {{% if (file.error) {{ %}}
                     <div><span class="label label-danger">Error</span> {{%=file.error%}}</div>
                  {{% }} %}}
               </td>
               <td>
                  <span class="size">{{%=o.formatFileSize(file.size)%}}</span>
               </td>
               <td>
                  {{% if (file.deleteUrl) {{ %}}
                     <!-- {{% if (file.deleteWithCredentials) {{ %}} data-xhr-fields='{{"withCredentials":true}}'{{% }} %}} -->
                     <button class="btn btn-default delete" data-type="{{%=file.deleteType%}}" data-url="{{%=file.deleteUrl%}}">
                        <i class="glyphicon glyphicon-trash"></i>
                        <span> Delete</span>
                     </button>
                     <input type="checkbox" name="delete" value="1" class="toggle"/>
                  {{% }} else {{ %}}
                     <button class="btn btn-default cancel">
                        <i class="glyphicon glyphicon-ban-circle"></i>
                        <span> Hide</span>
                     </button>
                  {{% }} %}}
               </td>
            </tr>
         {{% }} %}}
      </script>

      <h4>Create document</h4>

      {
         v:form($webapp-root || 'loader/insert', (
            v:input-text('uri', 'Document URI', 'relative to this directory'),
            v:input-select('format', 'Format', (
               v:input-option('xml',    'XML'),
               v:input-option('text',   'Text'),
               v:input-option('binary', 'Binary'))),
            if ( fn:exists($path) ) then
               v:input-hidden('prefix', $path)
            else
               (),
            v:input-hidden('database', $db/@id),
            v:input-hidden('redirect', 'true'),
            v:input-hidden('file',     '&lt;hello&gt;World!&lt;/hello&gt;'),
            v:submit('Create')))
      }

   </div>
};

(:~
 : TODO: Document... (especially the fact it accesses the entire URI index,
 : should be a problem with large databases, with a shit loads of documents.
 :
 : TODO: The details of how to retrieve the children must be in lib/admin.xql.
 :
 : TODO: Lot of duplicated code with local:page--empty-path(), factorize out?
 :)
declare function local:display-list(
   $db    as element(a:database),
   $path  as xs:string,
   $start as xs:integer
) as element()+
{
   local:create-doc-form($db, $path),
   b:display-list(
      $path,
      (: Do we really need to filter out "$path"?  Can't we get rid of it in get-children-uri()? :)
      b:get-children-uri($path, $start)[. ne $path],
      $start,
      function($child as xs:string, $pos as xs:integer) {
         let $dir  := fn:ends-with($child, '/')
         let $name := fn:tokenize($child, '/')[fn:last() - (1[$dir], 0)[1]]
         return
            <li>
               <input name="name-{ $pos }"   type="hidden" value="{ $child }"/>
               <input name="delete-{ $pos }" type="checkbox"/>
               { ' ' }
               {
                  if ( $dir ) then
                     v:dir-link(fn:encode-for-uri($name) || '/', $name || '/')
                  else
                     v:doc-link(fn:encode-for-uri($name), $name)
               }
            </li>
      },
      function($items as element(h:li)+) {
         local:display-list-children($path, $items)
      })
};

declare function local:display-list-children(
   $path  as xs:string?,
   $items as element(h:li)+
) as element()+
{
   v:form(
      '',
      attribute { 'id' } { 'orig-form' },
      <ul style="list-style-type: none"> {
         $items
      }
      </ul>),
   <button class="btn btn-danger"
           title="Delete selected documents and directories"
           onclick='deleteUris("orig-form", "hidden-form");'>
      Delete
   </button>,
   v:inline-form(
      $db-root || 'bulk-delete',
      (attribute { 'id'    } { 'hidden-form' },
       attribute { 'style' } { 'display: none' }),
      v:input-hidden('back-url', 'browse' || '/'[fn:not(fn:starts-with($path, '/'))] || $path))
};

(:
browse -> 2
browse/ -> 3
browse/http:/ -> 4
browse/http:// -> 5
browse/http://example.com/ -> 6
:)

let $slashes := if ( fn:empty($path) ) then 0 else fn:count(fn:tokenize($path, '/'))
let $db-str  := t:mandatory-field('id')
let $db      := xs:unsignedLong($db-str)
let $init    := t:optional-field('init-path', ())[.]
let $start   := xs:integer(t:optional-field('start', 1)[.])
let $params  := 
      map:new((
         map:entry('db',    $db),
         map:entry('path',  $path),
         map:entry('init',  $init),
         map:entry('start', $start),
         map:entry('fun',   local:page#4)))
return
   v:console-page(
      $webapp-root,
      'browser',
      'Browse documents',
      function() {
         a:eval-on-database(
            $db,
            'declare variable $db    external;
             declare variable $start external;
             declare variable $path  external := ();
             declare variable $init  external := ();
             declare variable $fun   external;
             $fun($db, $path, $init, $start)',
            $params)
      },
      <script type="text/javascript">
         // initialize the jQuery File Upload widget
         $('#fileupload').fileupload({{
            url: '{ $webapp-root }loader/upload'
         }});

         // is any required field missing value?
         function missingRequired(inputs) {{
            return inputs.filter(function () {{
               return ! ( this.value || !$(this).prop('required') );
            }}).first().focus().length != 0;
         }};

         // event handler to set the additional input fields
         $('#fileupload').bind('fileuploadsubmit', function (evt, data) {{
            // the input elements
            var inputs = data.context.find(':input');
            // missing any required value?
            if ( missingRequired(inputs) ) {{
               data.context.find('button').prop('disabled', false);
               return false;
            }}
            // set the form data from the input elements
            data.formData = inputs.serializeArray();

            // set the content type based on format
            var format = inputs.filter('[name="format"]').val();

// **********
// TODO: Set the file content type from the input selection (xml/text/binary)
//    - xml    -> application/xml
//    - text   -> text/plain
//    - binary -> application/octet-stream
// A bit of a hack, but will be parsed properly on ML-side.  What about HTML?
// **********
         }});
      </script>)

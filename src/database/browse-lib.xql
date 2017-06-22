xquery version "3.0";

module namespace b = "http://expath.org/ns/ml/console/browse";

import module namespace t   = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";
import module namespace sem = "http://marklogic.com/semantics" at "/MarkLogic/semantics.xqy";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace cts  = "http://marklogic.com/cts";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace xdmp = "http://marklogic.com/xdmp";

(: Fixed page size for now. :)
declare variable $b:page-size := 100;

(:~
 : Render directory children, by wrapping them in a delete form.
 :)
declare function b:dir-children($items as element(h:li)+, $back-url as xs:string) as element()+
{
   v:form(
      '',
      attribute { 'id' } { 'orig-form' },
      <ul xmlns="http://www.w3.org/1999/xhtml" style="list-style-type: none"> {
         $items
      }
      </ul>),
   <button xmlns="http://www.w3.org/1999/xhtml"
           class="btn btn-danger"
           title="Delete selected documents and directories"
           onclick='deleteUris("orig-form", "hidden-form");'>
      Delete
   </button>,
   v:inline-form(
      'bulk-delete',
      (attribute { 'id'    } { 'hidden-form' },
       attribute { 'style' } { 'display: none' }),
      v:input-hidden('back-url', $back-url))
};

(:~
 : Return `true` if `$type` is `docs`, or `false` if it is `coll`.
 :
 : @error If `$type` is neither `docs` nor `coll`.
 :)
declare function b:param-iscoll($type as xs:string) as xs:boolean
{
   if ( $type eq 'docs' ) then
      fn:false()
   else if ( $type eq 'coll' ) then
      fn:true()
   else
      t:error('unkown-enum', 'Unknown root type: ' || $type)
};

(:~
 : Resolve a URI to a triplet "URI / root / separator".
 :
 : ```
 : <path root="..." sep="...">...</path>
 : ```
 :)
declare function b:resolve-path($uri as xs:string, $iscoll as xs:boolean, $schemes as element(c:scheme)+)
   as element(path)
{
   b:resolve-path-1($uri, $iscoll, $schemes)
};

declare function b:resolve-path-1($uri as xs:string, $iscoll as xs:boolean, $schemes as element(c:scheme)*)
   as element(path)
{
   if ( fn:empty($schemes) ) then
      <path>{ $uri }</path>
   else
      let $match := b:scheme-match($uri, $iscoll, fn:head($schemes))
      return
         if ( fn:exists($match) ) then
            $match
         else
            b:resolve-path-1($uri, $iscoll, fn:tail($schemes))
};

declare function b:scheme-match($uri as xs:string, $iscoll as xs:boolean, $scheme as element(c:scheme))
   as element(path)?
{
   let $match := fn:analyze-string($uri, '^' || $scheme/c:regex || '$')
   let $nr    := $scheme/c:regex/@match/xs:integer(.)
   let $root  := ( $scheme/c:root/c:fix, $match/fn:match//fn:group[@nr eq $nr] )[1]
   return
      t:exists($match/fn:match,
         <path root="{ $root }" sep="{ $scheme/@sep }">{ $uri }</path>)
};

(:~
 : Return all roots on the database.
 :)
declare function b:get-roots($iscoll as xs:boolean, $start as xs:integer, $schemes as element(c:scheme)+)
   as element(path)*
{
   let $uris := t:when($iscoll, b:get-children-coll#3, b:get-children-uri#3)
   return
      ( $schemes ! b:resolve-root(., function($root, $sep) { $uris($root, $sep, ()) }) )
         [ fn:position() ge $start and fn:position() lt $start + $b:page-size ]
};

declare function b:resolve-root($uri as element(c:scheme), $uris as function(xs:string, xs:string) as element(path)*)
   as element(path)*
{
   let $root := $uri/c:root
   return
      if ( fn:exists($root/c:fix) ) then
         <path sep="{ $uri/@sep }">{ fn:string($root/c:fix) }</path>[fn:exists($uris($root/c:fix, $uri/@sep))]
      else if ( fn:exists($root/c:start) ) then
         $uris($root/c:start, $uri/@sep)
      else
         t:error('invalid-config', 'Invalid URI root configuration: ' || xdmp:quote($uri))
};

(:~
 : Implementation function for `b:get-children-uri()` and `b:get-children-coll()`.
 :)
declare %private function b:get-children-impl(
   $base    as xs:string,
   $sep     as xs:string,
   $start   as xs:integer?,
   (: Using the param type declaration generates a seg fault. Yup. :)
   (: $matcher as function(xs:string) as xs:string* :)
   $matcher
) as element(path)*
{
   let $repl := '^(' || $base || '([^' || $sep || ']*' || $sep || ')).*'
   (: TODO: Any way to get rid of distinct-values? :)
   let $vals := fn:distinct-values(($matcher($base), $matcher($base || '*') ! fn:replace(., $repl, '$1')))
   return
      if ( fn:exists($start) ) then
         $vals[fn:position() ge $start and fn:position() lt $start + $b:page-size] ! <path sep="{ $sep }">{ . }</path>
      else
         $vals ! <path sep="{ $sep }">{ . }</path>
};

(:~
 : Return the "directory" and "file" direct children of $base directory.
 :)
declare function b:get-children-uri(
   $base  as xs:string?,
   $sep   as xs:string,
   $start as xs:integer?
) as element(path)*
{
   b:get-children-impl($base, $sep, $start, cts:uri-match#1)
};

(:~
 : Return the "directory" and "file" direct children of $base "collection directory".
 :)
declare function b:get-children-coll(
   $base  as xs:string,
   $sep   as xs:string,
   $start as xs:integer?
) as element(path)*
{
   b:get-children-impl($base, $sep, $start, cts:collection-match#1)
};

(:~
 : Implementation function for `b:get-matching-dir()` and `b:get-matching-cdir()`.
 :
 : @todo Protect $input against special characters (like `*`).
 :)
declare %private function b:get-matching-dir-impl(
   $input   as xs:string,
   $sep     as xs:string,
   $length  as xs:integer?,
   (: Using the param type declaration generates a seg fault. Yup. :)
   (: $matcher as function(xs:string) as xs:string* :)
   $matcher
) as element(path)*
{
   let $repl := '(' || $input || '([^' || $sep || ']*' || $sep || ')).*'
   (: TODO: Any way to get rid of distinct-values? :)
   let $vals := fn:distinct-values($matcher('*' || $input || '*' || $sep || '*') ! fn:replace(., $repl, '$1'))
   return
      $vals[fn:position() le $length] ! <path sep="{ $sep }">{ . }</path>
};

(:~
 : Return the "directories" matching $input.
 :)
declare function b:get-matching-dir(
   $input  as xs:string,
   $sep    as xs:string,
   $length as xs:integer
) as element(path)*
{
   b:get-matching-dir-impl($input, $sep, $length, cts:uri-match#1)
};

(:~
 : Return the "collection directories" matching $input.
 :)
declare function b:get-matching-cdir(
   $input  as xs:string,
   $sep    as xs:string,
   $length as xs:integer
) as element(path)*
{
   b:get-matching-dir-impl($input, $sep, $length, cts:collection-match#1)
};

(:~
 : Implementation function for `b:get-matching-doc()` and `b:get-matching-cdoc()`.
 :
 : @todo Protect $input against special characters (like `*`).
 :)
declare %private function b:get-matching-doc-impl(
   $input   as xs:string,
   $sep     as xs:string,
   $length  as xs:integer?,
   (: Using the param type declaration generates a seg fault. Yup. :)
   (: $matcher as function(xs:string) as xs:string* :)
   $matcher
) as element(path)*
{
   let $repl := $input || '[^' || $sep || ']*$'
   let $vals := $matcher('*' || $input || '*')[fn:matches(., $repl)]
   return
      $vals[fn:position() le $length] ! <path sep="{ $sep }">{ . }</path>
};

(:~
 : Return the "documents" (URI leaves) matching $input.
 :)
declare function b:get-matching-doc(
   $input  as xs:string,
   $sep    as xs:string,
   $length as xs:integer
) as element(path)*
{
   b:get-matching-doc-impl($input, $sep, $length, cts:uri-match#1)
};

(:~
 : Return the "collection documents" (URI leaves) matching $input.
 :)
declare function b:get-matching-cdoc(
   $input  as xs:string,
   $sep    as xs:string,
   $length as xs:integer
) as element(path)*
{
   b:get-matching-doc-impl($input, $sep, $length, cts:collection-match#1)
};

(:~
 : Return the resources (subject IRIs) matching $input.
 :)
declare function b:get-matching-rsrc(
   $input  as xs:string,
   $length as xs:integer
) as element(iri)*
{
   sem:sparql(
      'SELECT DISTINCT ?s WHERE {
          ?s  ?o  ?p .
          FILTER( regex(?s, ?re) )
          FILTER( ! isBlank(?s) )
       }',
      map:entry('re', '.*[/#]?[^#/]*' || $input || '[^#/]*$'))
   ! <iri>{ xs:string(map:get(., 's')) }</iri>
};

(:~
 : @todo Document... (especially the fact it accesses the entire URI index,
 : should be a problem with large databases, with a shit loads of documents.
 :
 : @todo The details of how to retrieve the children must be in lib/admin.xqy.
 :
 : @param endpoint The endpoint being used (to generate "next" and "previous" links)
 :)
declare function b:display-list(
   $path     as xs:string?,
   $children as item()*,
   $endpoint as xs:string,
   $start    as xs:integer,
   $itemizer as function(item(), xs:integer) as element()+,
   $lister   as function(element()*) as element()+
) as element()+
{
   if ( fn:empty($children) ) then (
      <p xmlns="http://www.w3.org/1999/xhtml">There is nothing to show.</p>
   )
   else (
      if ( fn:exists($path) ) then
         let $count := fn:count($children)
         let $to    := $start + $count - 1
         return
            <p xmlns="http://www.w3.org/1999/xhtml">
               Content of <code>{ $path }</code>, results { $start } to { $to }{
                  (: TODO: These links do not work anymore! (must say 'dir' or 'cdir'... :)
                  t:when($start gt 1,
                     (', ', <a href="{ $endpoint }?uri={ $path }&amp;start={ $start - $b:page-size }">previous page</a>)),
                  t:when($count eq $b:page-size,
                     (', ', <a href="{ $endpoint }?uri={ $path }&amp;start={ $start + $count }">next page</a>))
               }:
            </p>
      else
         (),
      $lister(
         for $child at $pos in $children
         order by $child
         return
            $itemizer($child, $pos))
   )
};

(:~
 : Display the current directory, with each part being a link up to it.
 : 
 : Display the current directory (the parent directory when displaying a file).
 : Each part of the directory is clickable to go up to it in the browser (when
 : displaying a directory, the last part is not clickable, as it is the current
 : dir).
 :
 : The path is within quotes `"`, and contains appropriate text after (and a
 : link up to "/" when the path starts with "/", as it is not convenient to
 : click on such a short text).
 :)
declare function b:uplinks($path as xs:string, $root as xs:string, $sep as xs:string, $isdir as xs:boolean, $iscoll as xs:boolean)
   as node()+
{
   b:uplinks-1(
      b:uplinks-parse($path, $root, $sep, $isdir),
      $root,
      $sep,
      $iscoll)
};

declare function b:uplinks-parse($path as xs:string, $root as xs:string, $sep as xs:string, $isdir as xs:boolean)
   as element(path)*
{
   let $after := fn:substring-after($path, $root)
   let $toks  := ( $root, fn:tokenize($after, $sep)[.] )
   let $paths := if ( $isdir ) then $toks else $toks[fn:position() lt fn:last()]
   return
      $paths ! <path sep="{ $sep }">{ . }</path>
};

declare function b:uplinks-1($paths as element(path)*, $root as xs:string, $sep as xs:string, $iscoll as xs:boolean)
   as node()*
{
   if ( fn:empty($paths) ) then (
   )
   else if ( fn:empty($paths[2]) ) then (
      t:when($iscoll,
         v:croot-link('', $paths),
         v:root-link('', $paths))
   )
   else (
      b:uplinks-1($paths[fn:position() lt fn:last()], $root, $sep, $iscoll),
      text { ' ' },
      t:when($iscoll,
         v:cdir-link('', b:uplinks-2($paths, $sep), fn:head($paths)/@sep),
         v:dir-link('', b:uplinks-2($paths, $sep), fn:head($paths)/@sep))
   )
};

declare function b:uplinks-2($paths as element(path)*, $sep as xs:string)
   as xs:string
{
   if ( fn:ends-with($paths[1], $sep) ) then
      $paths[1] || fn:string-join(fn:remove($paths, 1), $sep) || $sep
   else
      fn:string-join($paths, $sep) || $sep
};

(:~
 : Create the "create document" form.
 :
 : Make sure to call `b:create-doc-form()` to include the required JavaScript code
 : in the page.
 :
 : TODO: Make sure both areas ("jump to" and "add files") are closed when expanding
 : one of them.  For now, because of simple toggling, they are independent of each
 : other: you can expand and collapse them independently (so e.g. have them both
 : expanded at the same time).
 :
 : TODO: Split the "add files" area into "upload files" and "create document" areas.
 :)
declare function b:create-doc-form(
   $root as xs:string,
   $db   as xs:string,
   $uri  as xs:string?
) as element()+
{
   <p xmlns="http://www.w3.org/1999/xhtml">
      <button class="btn btn-default" id="show-jump-area"
              title="Display the upload area, to upload files or create empty documents"
              onclick="$('#jump-area').slideToggle(); $('#show-jump-area span').toggle();">
         <span>Jump to...</span>
         <span style="display: none">Hide jump area</span>
      </button>
      <button class="btn btn-default" id="show-files-area"
              title="Display the upload area, to upload files or create empty documents"
              onclick="$('#files-area').slideToggle(); $('#show-files-area span').toggle();">
         <span>Add files...</span>
         <span style="display: none">Hide upload area</span>
      </button>
   </p>,

   <div xmlns="http://www.w3.org/1999/xhtml" style="display: none" id="jump-area">
      <h4>Jump to</h4>
      <p>Use the following form to directly access either a directory or a document by URI:</p>
      {
         v:one-liner-form('dir', 'Go', 'get', (
            if ( fn:exists($uri) ) then v:input-hidden('prefix', $uri) else (),
            v:input-text('uri', 'Directory', 'The URI of a directory'))),
         v:one-liner-form('doc', 'Go', 'get', (
            if ( fn:exists($uri) ) then v:input-hidden('prefix', $uri) else (),
            v:input-text('uri', 'Document', 'The URI of a document')))
      }
   </div>,

   <div xmlns="http://www.w3.org/1999/xhtml" style="display: none" id="files-area">

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
               <input type="hidden" name="database" value="{ $db }"/>
               <input type="hidden" name="prefix"   value="{ $uri }"/>
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
                        else if ( file.name.endsWith('.json') ) {{
                           format = 'json';
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
                     {{% if ( format === 'json' ) {{ %}}
                        <option value="json" selected="">JSON</option>
                     {{% }} else {{ %}}
                        <option value="json">JSON</option>
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
         v:form($root || 'loader/insert', (
            v:input-text('uri', 'Document URI', 'relative to this directory'),
            if ( fn:exists($uri) ) then
               v:input-hidden('prefix', $uri)
            else
               (),
            v:input-select('format', 'Format', (
               v:input-option('xml',    'XML'),
               v:input-option('json',   'JSON'),
               v:input-option('text',   'Text'),
               v:input-option('binary', 'Binary'))),
            v:input-hidden('database', $db),
            v:input-hidden('redirect', 'true'),
            v:input-hidden('new-file', 'true'),
            v:submit('Create')))
      }

   </div>
};

(:~
 : Generate the piece of JavaScript required by the code in `b:create-doc-form()`.
 :)
declare function b:create-doc-javascript() as element(h:script)
{
   <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript">

      // initialize the jQuery File Upload widget
      $('#fileupload').fileupload({{
         url: '../../loader/upload'
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
//    - json   -> application/json
// A bit of a hack, but will be parsed properly on ML-side.  What about HTML?
// **********
      }});
   </script>
};

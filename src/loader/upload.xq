(: object-node { } and array-node { } constructors are not available in 3.0 :)
xquery version "1.0-ml";

import module namespace i = "http://expath.org/ns/ml/console/insert" at "insert-lib.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xqy";

(: TODO: Is it possible to support (or at least detect) multiple files?  The
 : [plugin doc](https://github.com/blueimp/jQuery-File-Upload/wiki/Setup) gives
 : an example of output, containing 2 files.  When can that arrive?  Even with
 : the dynamic UI example the browser is based on?
 :
 : TODO: Implement the fields `deleteUrl` and `deleteType`, in the JSON response.
 :)


let $db     := t:mandatory-field('database')
(: there is no prefix when called from a database page (displaying the roots) :)
let $prefix := t:optional-field('prefix', ())
let $format := t:mandatory-field('format')
let $file   := t:mandatory-field('files[]')
let $name   := t:mandatory-field-filename('files[]')
let $res    := i:handle-file($db, $file, $format, $name, $prefix, fn:false())
let $size   := 666 (: TODO: How to find the size?  Is is possible?  Is it required? :)
return
   if ( fn:empty($res) ) then
      object-node {
         'files': array-node {
            object-node {
               'name':  $name,
               'error': 'The document already exists in ' || $prefix
            }
         }
      }
   else
      object-node {
         'files': array-node {
            object-node {
               'name': $name,
               (: 'size': $size, :)
               (: relative URL, may be different than $name if there was some escaping :)
               'url':  fn:tokenize($res, '/')[fn:last()] ! fn:encode-for-uri(.)
            }
         }
      }

xquery version "3.0";

module namespace t = "http://expath.org/ns/ml/console/tools";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

(: ==== Error handling ======================================================== :)

(:~
 : TODO: Return an HTTP error instead...
 :)
declare function t:error($code as xs:string, $msg as xs:string)
   as empty-sequence()
{
   fn:error(
      fn:QName('http://expath.org/ns/ml/console', fn:concat('c:', $code)),
      $msg)
};

(: ==== HTTP request fields ======================================================== :)

(:~
 : Return a request field, or a default value if it has not been passed.
 :)
declare function t:optional-field($name as xs:string, $default as item()?)
   as item()?
{
   ( xdmp:get-request-field($name), $default )[1]
};

(:~
 : Return a request field, or throw an error if it has not been passed.
 :)
declare function t:mandatory-field($name as xs:string)
   as item()
{
   let $f := xdmp:get-request-field($name)
   return
      if ( fn:exists($f) ) then
         $f
      else
         t:error('TOOLS001', 'Mandatory field not passed: ' || $name)
};

(:~
 : Return a request field filename, or throw an error if it has not been passed.
 :)
declare function t:mandatory-field-filename($name as xs:string)
   as item()
{
   let $f := xdmp:get-request-field-filename($name)
   return
      if ( fn:exists($f) ) then
         $f
      else
         t:error('TOOLS001', 'Mandatory field filename not passed: ' || $name)
};

(: ==== XML tools ======================================================== :)

(:~
 : Add an element as last child of a parent element. Return the modified parent.
 :)
declare function t:add-last-child($parent as element(), $new-child as element())
   as node()
{
   element { fn:node-name($parent) } {
      $parent/@*,
      $parent/node(),
      $new-child
   }
};

(:~
 : Remove an element from its parent element. Return the modified parent.
 :
 : Throw 'c:child-not-exist' if $child is not a child of $parent.
 :)
declare function t:remove-child($parent as element(), $child as element())
   as node()
{
   if ( fn:empty($parent/*[. is $child]) ) then
      t:error(
         'child-not-exist',
         'The child ' || fn:name($child) || ' does not exist in ' || fn:name($parent))
   else
      element { fn:node-name($parent) } {
         $parent/@*,
         $parent/node() except $child
      }
};

(: ==== String tools ======================================================== :)

(:~
 : Build a string by repeating `$str`, `$n` times.
 :)
declare function t:make-string($str as xs:string, $n as xs:integer)
   as xs:string?
{
   if ( $n gt 0 ) then
      $str || local:make-str($str, $n - 1)
   else
      ()
};

(: ==== File and URI tools ======================================================== :)

(:~
 : Given a path, strip the last component unless it ends with a slash.
 :)
declare function t:dirname($path as xs:string)
   as xs:string
{
   fn:replace($path, '/[^/]+$', '/')
};

(:~
 : Ensure a directory exists on the filesystem (if not it is created).
 :)
declare function t:ensure-dir($dir as xs:string)
   as empty-sequence()
{
   (: TODO: This is an undocumented function. :)
   (: See http://markmail.org/thread/a4d6puu3n5dpmkkw :)
   (: It does not harm if dir already exists, but look at xdmp:filesystem-directory() to detect it... :)
   xdmp:filesystem-directory-create(
      $dir,
      <options xmlns="xdmp:filesystem-directory-create">
         <create-parents>true</create-parents>
      </options>)
};

(:~
 : Ensure `$file` is a relative path (does not start with a '/').
 :)
declare function t:ensure-relative($file as xs:string)
   as xs:string
{
   if ( fn:starts-with($file, '/') ) then
      fn:substring($file, 2)
   else
      $file
};

xquery version "3.0";

module namespace t = "http://expath.org/ns/ml/console/tools";

declare namespace c     = "http://expath.org/ns/ml/console";
declare namespace err   = "http://www.w3.org/2005/xqt-errors";
declare namespace mlerr = "http://marklogic.com/xdmp/error";
declare namespace xdmp  = "http://marklogic.com/xdmp";

declare variable $console-ns := 'http://expath.org/ns/ml/console';

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Work on different databases
 :)

(:~
 : Return a database ID.
 :
 : If `$db` is an xs:unsignedLong, it is returned as is.  If it is an a:database
 : element, its `@id` is returned.  If it is neither, it then must be the name
 : of a database, which is then resolved to an ID (if such a database does not
 : exist, the empty sequence is returned).
 :)
declare function t:database-id($db as item()) as xs:unsignedLong?
{
   if ( $db instance of element() and fn:exists($db/@id) ) then
      xs:unsignedLong($db/@id)
   else if ( $db castable as xs:unsignedLong ) then
      xs:unsignedLong($db)
   else
      t:catch-ml('XDMP-NOSUCHDB', function() {
         xdmp:database($db)
      })
};

(:~
 : Invoke the function on the given database.
 :)
declare function t:query(
   $db  as item(),
   $fun as function() as item()*
) as item()*
{
   xdmp:invoke-function(
      $fun,
      <options xmlns="xdmp:eval">
         <database>{ t:database-id($db) }</database>
      </options>)
};

(:~
 : Invoke the function on the given database, in update transaction mode.
 :)
declare function t:update(
   $db  as item(),
   $fun as function() as item()*
) as item()*
{
   xdmp:invoke-function(
      $fun,
      <options xmlns="xdmp:eval">
         <database>{ t:database-id($db) }</database>
         <transaction-mode>update-auto-commit</transaction-mode>
      </options>)
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Simple tools
 :)

(:~
 : Ignore its parameter and always return the empty sequence.
 :)
declare function t:ignore($seq as item()*)
   as empty-sequence()
{
   ()
};

(:~
 : If `$pred` is true, return `$then`, if not, return the empty sequence.
 :)
declare function t:when($pred as xs:boolean, $then as item()*)
   as item()*
{
   t:when($pred, $then, ())
};

(:~
 : If `$pred` is true, return `$then`, if not, return `$else`.
 :)
declare function t:when($pred as xs:boolean, $then as item()*, $else as item()*)
   as item()*
{
   if ( $pred ) then
      $then
   else
      $else
};

(:~
 : If `$pred` is false, return `$then`, if not, return the empty sequence.
 :)
declare function t:unless($pred as xs:boolean, $then as item()*)
   as item()*
{
   t:when(fn:not($pred), $then, ())
};

(:~
 : If `$pred` is false, return `$then`, if not, return `$else`.
 :)
declare function t:unless($pred as xs:boolean, $then as item()*, $else as item()*)
   as item()*
{
   t:when(fn:not($pred), $then, $else)
};

(:~
 : If `$seq` is not empty, return `$then`, if not, return the empty sequence.
 :)
declare function t:exists($seq as item()*, $then as item()*)
   as item()*
{
   t:when(fn:exists($seq), $then)
};

(:~
 : If `$seq` is not empty, return `$then`, if not, return `$else`.
 :)
declare function t:exists($seq as item()*, $then as item()*, $else as item()*)
   as item()*
{
   t:when(fn:exists($seq), $then, $else)
};

(:~
 : If `$seq` is non empty, return it, if it is empty, return `$default` instead.
 :)
declare function t:default($seq as item()*, $default as item()*)
   as item()*
{
   if ( fn:exists($seq) ) then
      $seq
   else
      $default
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Error handling
 :)

(:~
 : Catch a MarkLogic error.
 :
 : Evaluate the function and catch a MarkLogic error, only if it is with the code
 : `$code`.  If there is an error, but with a different code, it is rethrown.  If
 : there is no error, the return value of the function is returned.  If the given
 : error is caught, then it is ignored and `()` is returned.
 :
 : @return `()` if the error is caught, or the original return value.
 :)
declare function t:catch-ml($code as xs:string, $fun as function() as item()*)
   as item()*
{
   try {
      $fun()
   }
   catch err:FOER0000 {
      if ( $err:additional/mlerr:code eq $code ) then
         ()
      else
         (: TODO: How to rethrow it? :)
         fn:error($err:code, $err:description, $err:value)
   }
};

(:~
 : TODO: Return an HTTP error instead... (or rather create a proper error handler?)
 :)
declare function t:error($code as xs:string, $msg as xs:string)
   as empty-sequence()
{
   fn:error(
      fn:QName('http://expath.org/ns/ml/console', 'c:' || $code),
      $msg)
};

(:~
 : TODO: Return an HTTP error instead... (or rather create a proper error handler?)
 :)
declare function t:error($code as xs:string, $msg as xs:string, $info as item()*)
   as empty-sequence()
{
   fn:error(
      fn:QName('http://expath.org/ns/ml/console', 'c:' || $code),
      $msg,
      $info)
};

(:~
 : If `$pred` is true, throw an error.
 : 
 : `t:when` is not usable as it is not a macro.  For instance, in the following
 : example, evaluating `t:error` to get the value of its parameter would always
 : throw an error:
 : 
 :     t:when($value gt 42,
 :        t:error('foobar', 'Value is greater than 42.'))
 :)
declare function t:error-when(
   $pred as xs:boolean,
   $code as xs:string,
   $msg  as xs:string
) as empty-sequence()
{
   if ( $pred ) then
      t:error($code, $msg)
   else
      ()
};

declare function t:error-when(
   $pred as xs:boolean,
   $code as xs:string,
   $msg  as xs:string,
   $info as item()*
) as empty-sequence()
{
   if ( $pred ) then
      t:error($code, $msg, $info)
   else
      ()
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : HTTP request fields
 :)

(:~
 : Return a request field, or a default value if it has not been passed.
 :)
declare function t:optional-field($name as xs:string, $default as item()?)
   as item()?
{
   ( xdmp:get-request-field($name), $default )[.][1]
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
 : Return a request field filename, or a default value if it has not been passed.
 :)
declare function t:optional-field-filename($name as xs:string, $default as item()?)
   as item()
{
   ( xdmp:get-request-field-filename($name), $default )[1]
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

(:~
 : Return a request field content-type, or a default value if it has not been passed.
 :)
declare function t:optional-field-content-type($name as xs:string, $default as item()?)
   as item()
{
   ( xdmp:get-request-field-content-type($name), $default )[1]
};

(:~
 : Return a request field content-type, or throw an error if it has not been passed.
 :)
declare function t:mandatory-field-content-type($name as xs:string)
   as item()
{
   let $f := xdmp:get-request-field-content-type($name)
   return
      if ( fn:exists($f) ) then
         $f
      else
         t:error('TOOLS001', 'Mandatory field content-type not passed: ' || $name)
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : HTTP response helpers
 :)

(:~
 : Set "404 Not found" on the HTTP response.
 :)
declare function t:respond-not-found($content as item()*)
   as item()*
{
   xdmp:set-response-code(404, 'Not found'),
   $content
};

(:~
 : Set "501 Not implemented" on the HTTP response.
 :)
declare function t:respond-not-implemented($content as item()*)
   as item()*
{
   xdmp:set-response-code(501, 'Not implemented'),
   $content
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : XML tools
 :)

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

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : String tools
 :)

(:~
 : Build a string by repeating `$str`, `$n` times.
 :)
declare function t:make-string($str as xs:string, $n as xs:integer)
   as xs:string?
{
   if ( $n gt 0 ) then
      $str || t:make-string($str, $n - 1)
   else
      ()
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : File and URI tools
 :)

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

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : HTTP Content-Type parsing
 :)

(:~
 : Parse a HTTP Content-Type value.
 :
 : $ctype must conform to RFC 2616 grammar for Content-Type.  The returned
 : element looks like the following:
 :
 : <!-- result of parsing "text/plain;charset=windows-1250" -->
 : <content-type type="text" subtype="plain">
 :    <param name="charset" value="windows-1250"/>
 : </content-type>
 : 
 : From https://tools.ietf.org/html/rfc2616#section-3.7:
 :
 : media-type     = type "/" subtype *( ";" parameter )
 : type           = token
 : subtype        = token
 :
 : The rule `parameter` is defined as `attribute "=" value`.  This function
 : allows space characters between ";", `attribute`, "=", and `value`, and
 : simply ignore them.
 :)
declare function t:parse-content-type($ctype as xs:string)
   as element(content-type)
{
   if ( fn:contains($ctype, '/') ) then
      <content-type type="{ fn:substring-before($ctype, '/') }"> {
         t:parse-content-type-1(
            fn:substring-after($ctype, '/'))
      }
      </content-type>
   else
      t:error('content-type-no-slash', 'invalid content-type, no slash: ' || $ctype)
};

(:~
 : Private helper for `t:parse-content-type()`.
 :)
declare %private function t:parse-content-type-1($input as xs:string)
   as node()+
{
   if ( fn:contains($input, ';') ) then (
      attribute { 'subtype' } { fn:substring-before($input, ';') },
      t:parse-content-type-2(
         fn:string-to-codepoints(
            fn:substring-after($input, ';')),
         (), (), 0)
   )
   else (
      attribute { 'subtype' } { $input }
   )
};

(:~
 : Private helper for `t:parse-content-type-1()`.
 :
 : # https://tools.ietf.org/html/rfc2616#section-3.6
 :
 : parameter               = attribute "=" value
 : attribute               = token
 : value                   = token | quoted-string
 :
 : # https://tools.ietf.org/html/rfc2616#section-2.2
 :
 : token          = 1*<any CHAR except CTLs or separators>
 : separators     = "(" | ")" | "<" | ">" | "@"
 :                | "," | ";" | ":" | "\" | <">
 :                | "/" | "[" | "]" | "?" | "="
 :                | "{" | "}" | SP | HT
 :
 : quoted-string  = ( <"> *(qdtext | quoted-pair ) <"> )
 : qdtext         = <any TEXT except <">>
 : quoted-pair    = "\" CHAR
 :
 : # Some char codes
 :
 : space=32
 : double quote=34
 : semi colon=59
 : equals=61
 : backslash=92
 :
 : # States (values for $state)
 :
 : 0: initial state, after a ';' has been seen, looking for a name
 : 1: scanning a name
 : 2: scanning a token
 : 3: scanning the content of a quoted string
 : 4: after the closing '"' of a quoted string
 : 5: after a '=' has been seen, looking for a value
 : 6: scanning spaces (before and after name, before and after value)
 :)
declare %private function t:parse-content-type-2(
   $input as xs:integer*,
   $name  as xs:integer*,
   $value as xs:integer*,
   $state as xs:integer
) as element(param)+
{
   let $head := fn:head($input)
   let $tail := fn:tail($input)
   return
      if ( fn:empty($input) ) then (
         t:parse-content-type-3($name, $value, $state)
      )
      else if ( $head eq 32 and $state = (0, 5, 6) ) then (
         t:parse-content-type-2($tail, $name, $value, $state)
      )
      else if ( $head eq 32 and $state = (1, 2, 4) ) then (
         t:parse-content-type-2($tail, $name, $value, 6)
      )
      else if ( $state eq 6 ) then (
         t:error('content-type-invalid-char', 'invalid char whilst consuming spaces: ' || $head)
      )
      else if ( $head eq 61 and $state ne 3 ) then (
         if ( fn:empty($name) ) then
            t:error('content-type-empty-name', 'empty name when encountering equals: ' || $state)
         else
            t:parse-content-type-2($tail, $name, $value, 5)
      )
      else if ( $head eq 59 and $state ne 3 ) then (
            t:parse-content-type-3($name, $value, $state),
            t:parse-content-type-2($tail, (), (), 1)
      )
      else if ( $state eq 4 ) then (
         t:error('content-type-invalid-char', 'invalid char after quoted string ended: ' || $head)
      )
      else if ( $state = (0, 1) ) then (
         t:parse-content-type-2($tail, ($name, $head), $value, 1)
      )
      else if ( $state eq 5 and $head eq 34 ) then (
         t:parse-content-type-2($tail, $name, $value, 3)
      )
      else if ( $state eq 5 ) then (
         t:parse-content-type-2($tail, $name, ($value, $head), 2)
      )
      else if ( $state eq 3 and $head eq 92 ) then (
         t:parse-content-type-2(fn:tail($tail), $name, ($value, $input[2]), $state)
      )
      else if ( $state eq 3 and $head eq 34 ) then (
         t:parse-content-type-2($tail, $name, $value, 4)
      )
      else if ( $head eq 34 ) then (
         t:error('content-type-invalid-char', 'double quote in invalid state: ' || $state)
      )
      else (
         t:parse-content-type-2($tail, $name, ($value, $head), $state)
      )
};

(:~
 : Private helper for `t:parse-content-type-2()`.
 :)
declare %private function t:parse-content-type-3(
   $name  as xs:integer*,
   $value as xs:integer*,
   $state as xs:integer
) as element(param)
{
   if ( $state = (2, 4) ) then
      <param name="{ fn:codepoints-to-string($name) }" value="{ fn:codepoints-to-string($value) }"/>
   else
      t:error('content-type-invalid-state', 'invalid state when semi-colon or <eof>: ' || $state)
};

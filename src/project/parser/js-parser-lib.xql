xquery version "3.0";

module namespace jsp = "http://expath.org/ns/ml/console/parser/js";

import module namespace parser = "http://expath.org/ns/ml/console/parser" at "parser-lib.xql";
import module namespace ecp    = "EcmaScript"                             at "lib/EcmaScript.xq";

declare namespace map  = "http://marklogic.com/xdmp/map";

declare function jsp:parse($href as xs:string, $module as xs:string)
   as element(module)
{
   parser:parse(
      $href,
      $module,
      map:new((
         map:entry('lang', 'javascript'),
         map:entry('parse', ecp:parse-Program#1),
         map:entry('functions', function($ast) {
            $ast/SourceElement/Statement/FunctionDeclaration
         }),
         map:entry('comment', function($fun, $pos) {
            $fun/../../preceding-sibling::node()[1][self::text()]
         }),
         map:entry('parse-comment', jsp:parse-comment#1),
         map:entry('comment-blocks', function($ast as element()) {
            $ast/jsdoc
         }),
         map:entry('name', function($fun as element(FunctionDeclaration)) {
            $fun/Identifier
         }),
         map:entry('params', function($fun as element(FunctionDeclaration)) {
            $fun/FormalParameterList/Identifier
         }),
         map:entry('param-name', fn:exactly-one#1), (: identity :)
         map:entry('opening', '/\*'),
         map:entry('closing', '\*/'),
         map:entry('continuation', '\*'))))
};

(:~
 : Parse a piece of text that must be a mix of whitespaces and comments.
 :
 : Return an element `ERROR` in case of error, or an element `ast`.  The content
 : of the element `ast` is a sequence of zero or more elements `comment` and
 : `jsdoc`.  The former contain the plain multi-line JavaScript comments, the
 : latter contain the "jsDoc" comments (like xqDoc, only starting with "/*~").
 :
 : Single-line comments and whitespaces outside of comments are discarded.  The
 : comment start and end tags (resp. "/*" and "*/") are preserved in the content
 : of elements `comment` and `jsdoc` (they are the first and last characters of
 : these elements, as surrounding whitespaces are discarded).
 :
 :     &lt;ast&gt;
 :        &lt;jsdoc&gt;/*~
 :      * This is a function.
 :      *
 :      * This function does this and that,
 :      *
 :      * @param thing The thing the function takes as argument.
 :      */&lt;/jsdoc&gt;
 :     &lt;/ast&gt;
 :)
declare function jsp:parse-comment($text as xs:string)
   as element()
{
   let $comments := jsp:parse-comment-1($text)
   return
      if ( fn:exists($comments[self::error]) ) then
         <ERROR>{ $comments[self::error] }</ERROR>
      else
         <ast>{ $comments }</ast>
};

declare function jsp:parse-comment-1($text as xs:string)
   as element()*
{
   if ( fn:matches($text, '^\s*$') ) then (
   )
   else if ( fn:matches($text, '^//') ) then (
      if ( fn:contains($text, '&#10;') ) then
         jsp:parse-comment-1(fn:substring-after($text, '&#10;'))
      else
         ()
   )
   else if ( fn:matches($text, '^/\*~') ) then (
      jsp:parse-comment-2($text, 'jsdoc')
   )
   else if ( fn:matches($text, '^\s+/\*~') ) then (
      jsp:parse-comment-2(fn:replace($text, '^\s+/', '/'), 'jsdoc')
   )
   else if ( fn:matches($text, '^/\*') ) then (
      jsp:parse-comment-2($text, 'comment')
   )
   else if ( fn:matches($text, '^\s+/\*') ) then (
      jsp:parse-comment-2(fn:replace($text, '^\s+/', '/'), 'comment')
   )
   else (
      jsp:parse-comment-error($text, fn:false())
   )
};

(: TODO: Does not support embedded multi-line comments... :)
declare function jsp:parse-comment-2($text as xs:string, $name as xs:string)
   as element()+
{
   if ( fn:contains($text, '*/') ) then (
      element { $name } { fn:substring-before($text, '*/') || '*/' },
      jsp:parse-comment-1(fn:substring-after($text, '*/'))
   )
   else (
      jsp:parse-comment-error($text, fn:true())
   )
};

declare function jsp:parse-comment-error($text as xs:string, $end as xs:boolean)
   as element(error)
{
   <error>
      <msg>Error parsing JavaScript comments, looking for comment { ('end'[$end], 'start')[1] }</msg>
      <input> {
         if ( fn:string-length($text) gt 50 ) then
            fn:substring($text, 0, 50) || '...'
         else
            $text
      }
      </input>
   </error>
};

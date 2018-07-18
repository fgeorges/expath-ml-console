xquery version "3.0";

module namespace parser = "http://expath.org/ns/ml/console/parser";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../../lib/tools.xqy";

declare namespace map = "http://marklogic.com/xdmp/map";

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Overall parsing of the modules
 :)

(:~
 : Parse a module.
 : 
 : Return a `module` element, of the following format:
 :
 : ```
 :     <module href="module uri">
 :        ( function
 :        | section )*
 :     </module>
 : 
 :     <function>
 :        ( comment?
 :        , signature )
 :     </function>
 : 
 :     <comment>
 :        ( head
 :        , body?
 :        , param*
 :        , return?
 :        , {tag}* )
 :     </comment>
 : 
 :     <signature name="local-name" type="xs:string+"> (type optional)
 :        ( param* )
 :     </signature>
 : 
 :     <section>
 :        ( head
 :        , body?
 :        , {tag}* )
 :     </section>
 : 
 :     <head/>, <body/>, <return/>
 :        := plain text
 : 
 :     <param name="param name"> (in `comment`)
 :        ( plain text )
 :     </param>
 : 
 :     <param name="param name" type="type def"> (in `signature`) (type optional)
 :        ( plain text )
 :     </param>
 : 
 :     {tag}
 :        := any other possible tag, plain text or with some attributes, TBD
 : ```
 : 
 : @param href A path or URI to use to refer to the module.
 : 
 : @param module The source code of the module, as text.
 : 
 : @param lang A map with info and functions about the specific language of the
 :     module.  It must contain the following entries:
 :
 :     - `lang` - the language, as a string
 :     - `parse()` - the REx-generated parser for the language
 :     - `functions()` - get the function definitions out of the AST
 :     - `comment()` - given a function in the AST, get the corresponding comment
 :     - `parse-comment()` - the REx-generated parser for the comments in the doc language
 :     - `comment-blocks()` - return xqDoc comments in the AST from `parse-comment()`
 :     - `name()` - return the name out of a function declaration
 :     - `arity()` - return the arity out of a function declaration
 :     - `type()` - return the type out of a function declaration
 :     - `param-name()` - return the name out of a parameter
 :     - `param-type()` - return the type out of a parameter
 :     - `opening` - the opening comment tag (like "\(\:" or "/\*"), must be a valid regex
 :     - `closing` - the closing comment tag (like ":\)" or "\*/"), must be a valid regex
 :     - `continuation` - the beginning of each line in a comment (":" or "*"), must be a
 :           valid regex, not including surrounding whitespaces
 :)
declare function parser:parse($href as xs:string, $module as xs:string, $lang as item())
   as element(module)
{
   <module href="{ $href }" lang="{ map:get($lang, 'lang') }"> {
      let $components := parser:parse-1($module, $lang)
      return
         if ( fn:exists($components[self::section]) ) then
            parser:normalize-sections($components)
         else
            $components
   }
   </module>
};

(:~
 : Impementation of `parser:parse#1`.  Return "*raw*" components.
 :)
declare %private function parser:parse-1($module as xs:string, $lang as item())
   as element((:function|section|error:))*
{
   let $ast := map:get($lang, 'parse')($module)
   return
      if ( fn:exists($ast/self::ERROR) ) then
         <error>{ $ast }</error>
      else
         for $fun   at $pos in map:get($lang, 'functions')($ast)
         let $comms := map:get($lang, 'comment')($fun, $pos)/parser:comment(., $lang)
         let $sects := $comms[section]
         return (
            $sects ! <section><head>{ section/node() }</head>{ node() except section }</section>,
            <function> {
               $comms except $sects,
               parser:signature($fun, $lang)
            }
            </function>
         )
};

(:~
 : Normalize section nesting for `xqp:parse#1`.
 : 
 : By "*nesting*", it actually only supports 1-level.  But it groups all functions
 : under the same section with the same `section` parent element.  From:
 : 
 : ```
 :     <function> ( z ) </function>
 :     <section> ( 1 ) </section>
 :     <function> ( a ) </function>
 :     <function> ( b ) </function>
 :     <section> ( 2 ) </section>
 :     <function> ( c ) </function>
 : ```
 : 
 : to:
 : 
 : ```
 :     <function> ( z ) </function>
 :     <section> ( 1 )
 :        <function> ( a ) </function>
 :        <function> ( b ) </function>
 :     </section>
 :     <section> ( 2 )
 :        <function> ( c ) </function>
 :     </section>
 : ```
 : 
 : @param $comps The components to normalize.  It is a mix of `section` and
 : `function` elements.  It must contain at least one `section` element.
 : 
 : @return A sequence of `section` elements, containing their corresponding
 : `function` elements.  If the first element in `$comps` is not a `section`
 : element, then all the elements before the first one are returned first.
 :)
declare %private function parser:normalize-sections(
   $comps as element((:function|section:))+
) as element((:function|section:))+
{
   let $head := fn:head($comps)
   let $tail := fn:tail($comps)
   return
      if ( $head instance of element(section) ) then
         parser:normalize-sections-1($head, (), $tail)
      else
         parser:normalize-sections-1((), $head, $tail)
};

(:~
 : Recursive implementation of `parser:normalize-sections#1`.
 :)
declare %private function parser:normalize-sections-1(
   $sect  as element(section)?,
   $acc   as element(function)*,
   $comps as element((:function|section:))*
) as element((:function|section:))+
{
   if ( fn:empty($comps) ) then
      parser:make-section($sect, $acc)
   else
      let $head := fn:head($comps)
      let $tail := fn:tail($comps)
      return
         if ( $head instance of element(section) ) then (
            parser:make-section($sect, $acc),
            parser:normalize-sections-1($head, (), $tail)
         )
         else (
            parser:normalize-sections-1($sect, ($acc, $head), $tail)
         )
};

(:~
 : Materialize a section when needed, private of `parser:normalize-sections#1`.
 :)
declare %private function parser:make-section(
   $sect  as element(section)?,
   $acc   as element(function)*
) as element((:function|section:))+
{
   if ( fn:exists($sect) ) then
      <section> {
         $sect/node(),
         $acc
      }
      </section>
   else
      $acc
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Parsing of the comments
 :)

(:~
 : Bla bla...
 :
 : @param text Bla bla...
 :)
declare function parser:comment($text as xs:string, $lang as item()) as element(comment)*
{
   (: This function is clearly not perfect.  Try to come with my own parser.
    : Some examples of failures:
    : - fails if text contains '<'
    : - fails if text contains '@'
    : TODO: 
    :)
   let $ast  := map:get($lang, 'parse-comment')($text)
   let $docs := map:get($lang, 'comment-blocks')($ast)
   return
      if ( fn:exists($ast/self::ERROR) ) then
         <comment>
            <ERROR>{ xs:string($ast) }</ERROR>
         </comment>
      else
         $docs ! <comment>{ parser:parse-doc(fn:tokenize(., '&#13;?&#10;'), $lang) }</comment>
};

declare function parser:signature($fun as element(), $lang as item()) as element(signature)
{
   <signature name="{ map:get($lang, 'name')($fun) }"> {
      map:get($lang, 'name') ! .($fun) ! attribute { 'arity' }{ . },
      map:get($lang, 'type') ! .($fun) ! attribute { 'type'  }{ . },
      for $param in map:get($lang, 'params')($fun)
      return
         <param name="{ map:get($lang, 'param-name')($param) }"> {
            map:get($lang, 'param-type') ! .($param) ! attribute { 'type' }{ . }
         }
         </param>
   }
   </signature>
};

declare function parser:parse-doc($lines as xs:string+, $lang as item()) as element()+
{
   let $cont  := '^\s*' || map:get($lang, 'continuation') || '\s*'
   let $open  := map:get($lang, 'opening')
   let $close := map:get($lang, 'closing')
   let $first := '^\s*' || $open  || '~+\s*$'
   let $last  := '^\s*' || $close || '\s*$'
   let $sect  := '^\s*' || $open  || '~~+\s*$'
   return
      if ( fn:empty($lines[2]) ) then
         parser:parse-simple-doc($lines, $open, $close)
      (: check first line is `(;~` :)
      else if ( fn:not(fn:matches($lines[1], $first)) ) then
         <ERROR>This is not a xqDoc comment (first line): "{ $lines[1] }"</ERROR>
      (: check last line is `;)` :)
      else if ( fn:not(fn:matches($lines[fn:last()], $close)) ) then
         <ERROR>This is not a xqDoc comment (last line): "{ $lines[fn:last()] }"</ERROR>
      else
         (: normalize lines, except first and last :)
         let $normed := parser:normalize-lines(fn:tail(fn:remove($lines, fn:count($lines))), $cont)
         return (
            if ( fn:matches($lines[1], $sect) ) then
               <section>{ $normed[1] }</section>
            else
               <head>{ $normed[1] }</head>,
            if ( fn:empty($normed[2][.]) ) then
               parser:parse-body((), fn:tail(fn:tail($normed)))
            else
               <ERROR>Line after head is not empty in xqDoc: "{ $normed[2] }"</ERROR>
         )
};

declare function parser:parse-simple-doc($line as xs:string, $open as xs:string, $close as xs:string) as element()
{
   let $start   := '^\s*' || $open
   let $end     := '~+\s*(.*\S)\s*' || $close || '\s*$'
   let $section := $start || '~' || $end
   let $simple  := $start || $end
   return
   if ( fn:matches($line, $section) ) then
      <section> {
         fn:replace($line, $section, '$1')
      }
      </section>
   else if ( fn:matches($line, $simple) ) then
      <head> {
         fn:replace($line, $simple, '$1')
      }
      </head>
   else
      <ERROR>This is not a simple xqDoc comment: "{ $line }"</ERROR>
};

declare function parser:normalize-lines($lines as xs:string*, $cont as xs:string) as xs:string*
{
   if ( fn:empty($lines) ) then (
   )
   else (
      if ( fn:matches(fn:head($lines), $cont) ) then
         fn:replace(fn:head($lines), $cont, '')
      else
         fn:head($lines),
      parser:normalize-lines(fn:tail($lines), $cont)
   )
};

declare function parser:ignore-last-empties($lines as xs:string*) as xs:string*
{
   if ( fn:empty($lines) ) then
      ()
   else if ( fn:empty($lines[fn:last()][.]) ) then
      parser:ignore-last-empties(
         fn:remove($lines, fn:count($lines)))
   else
      $lines
};

declare function parser:parse-body($accumulator as xs:string*, $lines as xs:string*) as element()*
{
   if ( fn:empty($lines) ) then (
      parser:build-body($accumulator)
   )
   else if ( fn:starts-with(fn:head($lines), '@') ) then (
      parser:build-body($accumulator),
      parser:parse-tags((), (), $lines)
   )
   else (
      parser:parse-body(
         ($accumulator, fn:head($lines)),
         fn:tail($lines))
   )
};

declare function parser:build-body($lines as xs:string*) as element(body)?
{
   let $b := parser:ignore-last-empties($lines)
   return
      t:when(fn:exists($b),
         <body> {
            fn:string-join($b, '&#10;')
         }
         </body>)
};

(: TODO: This function should not use ' ' but look for '\s+' instead.
 : Or not.  Option -pedantic?
 :)
declare function parser:parse-tag-head($line as xs:string) as xs:string+
{
   t:when(fn:not(fn:starts-with($line, '@')),
      <ERROR>Tag line does not start with @: "{ $line }"</ERROR>),
   let $tag  := fn:substring-before($line, ' ') ! fn:substring(., 2)
   let $rest := fn:substring-after($line, ' ')
   return
      switch ( $tag )
         case 'param' return (
            fn:substring-after($rest, ' '),
            $tag,
            fn:substring-before($rest, ' ')
         )
         (: extension, similar to @error but with the error code :)
         case 'throws' return (
            fn:substring-after($rest, ' '),
            $tag,
            fn:substring-before($rest, ' ')
         )
         default return (
            $rest,
            $tag
         )
};

declare function parser:parse-tags(
   $tag         as xs:string*,
   $accumulator as xs:string*,
   $lines       as xs:string*
) as element()+
{
   if ( fn:empty($lines) ) then (
      parser:build-tag($tag, $accumulator)
   )
   else if ( fn:empty($tag) ) then (
      let $parts := parser:parse-tag-head(fn:head($lines))
      return
         parser:parse-tags(fn:tail($parts), fn:head($parts), fn:tail($lines))
   )
   else if ( fn:starts-with(fn:head($lines), '@') ) then (
      parser:build-tag($tag, $accumulator),
      parser:parse-tags((), (), $lines)
   )
   else (
      parser:parse-tags(
         $tag,
         ($accumulator, fn:head($lines)),
         fn:tail($lines))
   )
};

declare function parser:build-tag($tag as xs:string+, $lines as xs:string+) as element()
{
   let $b := fn:string-join(parser:ignore-last-empties($lines), '&#10;')
   return
      switch ( $tag[1] )
         case 'param' return
            <param name="{ $tag[2] }">{ $b }</param>
         case 'throws' return
            <throws name="{ $tag[2] }">{ $b }</throws>
         case 'author' return
            <author>{ $b }</author>
         case 'version' return
            <version>{ $b }</version>
         case 'since' return
            <since>{ $b }</since>
         case 'see' return
            <see>{ $b }</see>
         case 'return' return
            <return>{ $b }</return>
         case 'deprecated' return
            <deprecated>{ $b }</deprecated>
         case 'error' return
            <error>{ $b }</error>
         (: TODO: This is an "extension" to XQDoc, document them all... :)
         case 'todo' return
            <todo>{ $b }</todo>
         default return
            <ERROR>
               <msg>Unknown tag: "{ $tag[1] }"</msg>
               { $tag ! <string>{ . }</string> }
               <content>{ $b }</content>
            </ERROR>
};

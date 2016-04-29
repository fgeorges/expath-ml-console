xquery version "3.0";

module namespace xqp = "http://expath.org/ns/ml/console/parser/xquery";

import module namespace parser = "http://github.com/jpcs/xqueryparser.xq"
   at "xqueryparser.xq";
import module namespace xqdc = "XQDocComments"
   at "lib/XQDocComments.xq";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../../lib/tools.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ First section... :)

(:~
 : Parse an XQuery module.
 : 
 : Return a `module` element, of the following format:
 :
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
 :     <signature name="local-name" type="xs:string+">
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
 :     <param name="param name" type="type def"> (in `signature`)
 :        ( plain text )
 :     </param>
 : 
 :     {tag}
 :        := any other possible tag, plain text or with some attributes, TBD
 : 
 : @param href A path or URI to use to refer to the XQuery module.
 : 
 : @param module The source code of the XQuery module, as text.
 :)
declare function xqp:parse($href as xs:string, $module as xs:string)
   as element(module)
{
   <module href="{ $href }" lang="xquery"> {
      let $components := xqp:parse-1($module)
      return
         if ( fn:exists($components[self::section]) ) then
            xqp:normalize-sections($components)
         else
            $components
   }
   </module>
};

(:~
 : Impementation of `xqp:parse#1`.  Return "*raw*" components.
 :)
declare %private function xqp:parse-1($module as xs:string)
   as element((:function|section|error:))*
{
   let $ast := parser:parse($module)
   return
      if ( fn:exists($ast/self::ERROR) ) then
         <error>{ $ast }</error>
      else
         let $mod   := $ast/Module/(LibraryModule|MainModule)
         for $fun   at $pos in $mod/Prolog/AnnotatedDecl/FunctionDecl
         let $pivot := if ( $pos eq 1 and $mod[self::MainModule] ) then $fun/../../.. else $fun/..
         let $comms := $pivot/preceding-sibling::node()[1][self::text()]/xqp:comment(.)
         let $sects := $comms[section]
         return (
            $sects ! <section><head>{ section/node() }</head>{ node() except section }</section>,
            <function> {
               $comms except $sects,
               xqp:signature($fun)
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
 :     <function> ( z ) </function>
 :     <section> ( 1 ) </section>
 :     <function> ( a ) </function>
 :     <function> ( b ) </function>
 :     <section> ( 2 ) </section>
 :     <function> ( c ) </function>
 : 
 : to:
 : 
 :     <function> ( z ) </function>
 :     <section> ( 1 )
 :        <function> ( a ) </function>
 :        <function> ( b ) </function>
 :     </section>
 :     <section> ( 2 )
 :        <function> ( c ) </function>
 :     </section>
 : 
 : @param $comps The components to normalize.  It is a mix of `section` and
 : `function` elements.  It must contain at least one `section` element.
 : 
 : @return A sequence of `section` elements, containing their corresponding
 : `function` elements.  If the first element in `$comps` is not a `section`
 : element, then all the elements before the first one are returned first.
 :)
declare %private function xqp:normalize-sections(
   $comps as element((:function|section:))+
) as element((:function|section:))+
{
   let $head := fn:head($comps)
   let $tail := fn:tail($comps)
   return
      if ( $head instance of element(section) ) then
         xqp:normalize-sections-1($head, (), $tail)
      else
         xqp:normalize-sections-1((), $head, $tail)
};

(:~
 : Recursive implementation of `xqp:normalize-sections#1`.
 :)
declare %private function xqp:normalize-sections-1(
   $sect  as element(section)?,
   $acc   as element(function)*,
   $comps as element((:function|section:))*
) as element((:function|section:))+
{
   if ( fn:empty($comps) ) then
      xqp:make-section($sect, $acc)
   else
      let $head := fn:head($comps)
      let $tail := fn:tail($comps)
      return
         if ( $head instance of element(section) ) then (
            xqp:make-section($sect, $acc),
            xqp:normalize-sections-1($head, (), $tail)
         )
         else (
            xqp:normalize-sections-1($sect, ($acc, $head), $tail)
         )
};

(:~
 : Materialize a section when needed, private of `xqp:normalize-sections#1`.
 :)
declare %private function xqp:make-section(
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

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Bla bla short... :)

(:~
 : Bla bla...
 :
 : @param text Bla bla...
 :)
declare function xqp:comment($text as xs:string) as element(comment)*
{
   (: This function is clearly not perfect.  Try to come with my own parser.
    : Some examples of failures:
    : - fails if text contains '<'
    : - fails if text contains '@'
    : TODO: 
    :)
   let $ast  := xqdc:parse-Comments($text)
   let $docs := $ast/XQDocComment
   return
      if ( fn:exists($ast/self::ERROR) ) then
         <comment>
            <ERROR>{ xs:string($ast) }</ERROR>
         </comment>
      else
         $docs ! <comment>{ xqp:parse-doc(fn:tokenize(., '&#13;?&#10;')) }</comment>
};

declare function xqp:signature($fun as element(FunctionDecl)) as element(signature)
{
   <signature name="{ xs:string($fun/QName/@localname) }" arity="{ fn:count($fun/ParamList/Param) }"> {
      $fun/SequenceType/xqp:type(.),
      for $param in $fun/ParamList/Param
      return
         <param name="{ $param/QName/@localname }"> {
            $param/TypeDeclaration/xqp:type(SequenceType)
         }
         </param>
   }
   </signature>
};

declare function xqp:type($type as element(SequenceType)) as attribute(type)
{
   attribute { 'type' } { $type }
};

declare function xqp:parse-doc($lines as xs:string+) as element()+
{
   if ( fn:empty($lines[2]) ) then
      xqp:parse-simple-doc($lines)
   (: check first line is `(;~` :)
   else if ( fn:not(fn:matches($lines[1], '^\s*\(:~+\s*$')) ) then
      <ERROR>This is not a xqDoc comment (first line): "{ $lines[1] }"</ERROR>
   (: check last line is `;)` :)
   else if ( fn:not(fn:matches($lines[fn:last()], '^\s*:\)\s*$')) ) then
      <ERROR>This is not a xqDoc comment (last line): "{ $lines[fn:last()] }"</ERROR>
   else
      (: normalize lines, except first and last :)
      let $normed := xqp:normalize-lines(fn:tail(fn:remove($lines, fn:count($lines))))
      return (
         if ( fn:matches($lines[1], '^\s*\(:~~+\s*$') ) then
            <section>{ $normed[1] }</section>
         else
            <head>{ $normed[1] }</head>,
         if ( fn:empty($normed[2][.]) ) then
            xqp:parse-body((), fn:tail(fn:tail($normed)))
         else
            <ERROR>Line after head is not empty in xqDoc: "{ $normed[2] }"</ERROR>
      )
};

declare function xqp:parse-simple-doc($line as xs:string) as element()
{
   if ( fn:matches($line, '^\s*\(:~~+\s*.+\s*:\)\s*$') ) then
      <section> {
         fn:replace($line, '^\s*\(:~~+\s*(.*\S)\s*:\)\s*$', '$1')
      }
      </section>
   else if ( fn:matches($line, '^\s*\(:~\s*.+\s*:\)\s*$') ) then
      <head> {
         fn:replace($line, '^\s*\(:~\s*(.*\S)\s*:\)\s*$', '$1')
      }
      </head>
   else
      <ERROR>This is not a simple xqDoc comment: "{ $line }"</ERROR>
};

declare function xqp:normalize-lines($lines as xs:string*) as xs:string*
{
   if ( fn:empty($lines) ) then
      ()
   else (
      if ( fn:starts-with(fn:head($lines), ' : ') ) then
         fn:substring(fn:head($lines), 4)
      else if ( fn:starts-with(fn:head($lines), ' :') ) then
         fn:substring(fn:head($lines), 3)
      else
         fn:head($lines),
      xqp:normalize-lines(fn:tail($lines))
   )
};

declare function xqp:ignore-last-empties($lines as xs:string*) as xs:string*
{
   if ( fn:empty($lines) ) then
      ()
   else if ( fn:empty($lines[fn:last()][.]) ) then
      xqp:ignore-last-empties(
         fn:remove($lines, fn:count($lines)))
   else
      $lines
};

declare function xqp:parse-body($accumulator as xs:string*, $lines as xs:string*) as element()*
{
   if ( fn:empty($lines) ) then (
      xqp:build-body($accumulator)
   )
   else if ( fn:starts-with(fn:head($lines), '@') ) then (
      xqp:build-body($accumulator),
      xqp:parse-tags((), (), $lines)
   )
   else (
      xqp:parse-body(
         ($accumulator, fn:head($lines)),
         fn:tail($lines))
   )
};

declare function xqp:build-body($lines as xs:string*) as element(body)?
{
   let $b := xqp:ignore-last-empties($lines)
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
declare function xqp:parse-tag-head($line as xs:string) as xs:string+
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

declare function xqp:parse-tags(
   $tag         as xs:string*,
   $accumulator as xs:string*,
   $lines       as xs:string*
) as element()+
{
   if ( fn:empty($lines) ) then (
      xqp:build-tag($tag, $accumulator)
   )
   else if ( fn:empty($tag) ) then (
      let $parts := xqp:parse-tag-head(fn:head($lines))
      return
         xqp:parse-tags(fn:tail($parts), fn:head($parts), fn:tail($lines))
   )
   else if ( fn:starts-with(fn:head($lines), '@') ) then (
      xqp:build-tag($tag, $accumulator),
      xqp:parse-tags((), (), $lines)
   )
   else (
      xqp:parse-tags(
         $tag,
         ($accumulator, fn:head($lines)),
         fn:tail($lines))
   )
};

declare function xqp:build-tag($tag as xs:string+, $lines as xs:string+) as element()
{
   let $b := fn:string-join(xqp:ignore-last-empties($lines), '&#10;')
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

xquery version "3.0";

module namespace jsp = "http://expath.org/ns/ml/console/parser/js";

import module namespace parser = "EcmaScript"
   at "lib/EcmaScript.xq";
import module namespace jsdc = "JSDocComments"
   at "lib/JSDocComments.xq";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../../lib/tools.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare function jsp:parse($href as xs:string, $module as xs:string)
   as element(module)
{
   <module href="{ $href }" lang="javascript"> {
      let $components := jsp:parse-1($module)
      return
         if ( fn:exists($components[self::section]) ) then
            jsp:normalize-sections($components)
         else
            $components
   }
   </module>
};

declare %private function jsp:parse-1($module as xs:string)
   as element((:function|section|error:))*
{
   let $ast := parser:parse-Program($module)
   return
      if ( fn:exists($ast/self::ERROR) ) then
         <error>{ $ast }</error>
      else
         for $fun   at $pos in $ast/SourceElement[Statement/FunctionDeclaration]
         let $comms := $fun/preceding-sibling::node()[1][self::text()]/jsp:comment(.)
         let $sects := $comms[section]
         return (
            $sects ! <section><head>{ section/node() }</head>{ node() except section }</section>,
            <function> {
               $comms except $sects,
               jsp:signature($fun/Statement/FunctionDeclaration)
            }
            </function>
         )
};

declare %private function jsp:normalize-sections(
   $comps as element((:function|section:))+
) as element((:function|section:))+
{
   let $head := fn:head($comps)
   let $tail := fn:tail($comps)
   return
      if ( $head instance of element(section) ) then
         jsp:normalize-sections-1($head, (), $tail)
      else
         jsp:normalize-sections-1((), $head, $tail)
};

declare %private function jsp:normalize-sections-1(
   $sect  as element(section)?,
   $acc   as element(function)*,
   $comps as element((:function|section:))*
) as element((:function|section:))+
{
   if ( fn:empty($comps) ) then
      jsp:make-section($sect, $acc)
   else
      let $head := fn:head($comps)
      let $tail := fn:tail($comps)
      return
         if ( $head instance of element(section) ) then (
            jsp:make-section($sect, $acc),
            jsp:normalize-sections-1($head, (), $tail)
         )
         else (
            jsp:normalize-sections-1($sect, ($acc, $head), $tail)
         )
};

declare %private function jsp:make-section(
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

declare function jsp:comment($text as xs:string) as element(comment)*
{
   let $ast  := jsdc:parse-Comments($text)
   let $docs := $ast/JSDocComment
   return
      if ( fn:exists($ast/self::ERROR) ) then
         <comment>
            <ERROR>{ xs:string($ast) }</ERROR>
         </comment>
      else
         $docs ! <comment>{ jsp:parse-doc(fn:tokenize(., '&#13;?&#10;')) }</comment>
};

declare function jsp:signature($fun as element(FunctionDeclaration)) as element(signature)
{
   <signature name="{ xs:string($fun/Identifier) }"> {
      $fun/FormalParameterList/Identifier ! <param name="{ . }"/>
   }
   </signature>
};

declare function jsp:parse-doc($lines as xs:string+) as element()+
{
   if ( fn:empty($lines[2]) ) then
      jsp:parse-simple-doc($lines)
   (: check first line is `/**` :)
   else if ( fn:not(fn:matches($lines[1], '^\s*/\*\*+\s*$')) ) then
      <ERROR>This is not a jsDoc comment (first line): "{ $lines[1] }"</ERROR>
   (: check last line is `;)` :)
   else if ( fn:not(fn:matches($lines[fn:last()], '^\s*\*/\s*$')) ) then
      <ERROR>This is not a jsDoc comment (last line): "{ $lines[fn:last()] }"</ERROR>
   else
      (: normalize lines, except first and last :)
      let $normed := jsp:normalize-lines(fn:tail(fn:remove($lines, fn:count($lines))))
      return (
         if ( fn:matches($lines[1], '^\s*/\*\*\*+\s*$') ) then
            <section>{ $normed[1] }</section>
         else
            <head>{ $normed[1] }</head>,
         if ( fn:empty($normed[2][.]) ) then
            jsp:parse-body((), fn:tail(fn:tail($normed)))
         else
            <ERROR>Line after head is not empty in jsDoc: "{ $normed[2] }"</ERROR>
      )
};

declare function jsp:parse-simple-doc($line as xs:string) as element()
{
   if ( fn:matches($line, '^\s*/\*\*\*+\s*.+\s*\*/\s*$') ) then
      <section> {
         fn:replace($line, '^\s*/\*\*\*+\s*(.*\S)\s*\*/\s*$', '$1')
      }
      </section>
   else if ( fn:matches($line, '^\s*/\*\*\s*.+\s\*/\s*$') ) then
      <head> {
         fn:replace($line, '^\s*/\*\*\s*(.*\S)\s*\*/\s*$', '$1')
      }
      </head>
   else
      <ERROR>This is not a simple jsDoc comment: "{ $line }"</ERROR>
};

declare function jsp:normalize-lines($lines as xs:string*) as xs:string*
{
   if ( fn:empty($lines) ) then
      ()
   else (
      if ( fn:starts-with(fn:head($lines), ' * ') ) then
         fn:substring(fn:head($lines), 4)
      else if ( fn:starts-with(fn:head($lines), ' *') ) then
         fn:substring(fn:head($lines), 3)
      else
         fn:head($lines),
      jsp:normalize-lines(fn:tail($lines))
   )
};

declare function jsp:ignore-last-empties($lines as xs:string*) as xs:string*
{
   if ( fn:empty($lines) ) then
      ()
   else if ( fn:empty($lines[fn:last()][.]) ) then
      jsp:ignore-last-empties(
         fn:remove($lines, fn:count($lines)))
   else
      $lines
};

declare function jsp:parse-body($accumulator as xs:string*, $lines as xs:string*) as element()*
{
   if ( fn:empty($lines) ) then (
      jsp:build-body($accumulator)
   )
   else if ( fn:starts-with(fn:head($lines), '@') ) then (
      jsp:build-body($accumulator),
      jsp:parse-tags((), (), $lines)
   )
   else (
      jsp:parse-body(
         ($accumulator, fn:head($lines)),
         fn:tail($lines))
   )
};

declare function jsp:build-body($lines as xs:string*) as element(body)?
{
   let $b := jsp:ignore-last-empties($lines)
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
declare function jsp:parse-tag-head($line as xs:string) as xs:string+
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

declare function jsp:parse-tags(
   $tag         as xs:string*,
   $accumulator as xs:string*,
   $lines       as xs:string*
) as element()+
{
   if ( fn:empty($lines) ) then (
      jsp:build-tag($tag, $accumulator)
   )
   else if ( fn:empty($tag) ) then (
      let $parts := jsp:parse-tag-head(fn:head($lines))
      return
         jsp:parse-tags(fn:tail($parts), fn:head($parts), fn:tail($lines))
   )
   else if ( fn:starts-with(fn:head($lines), '@') ) then (
      jsp:build-tag($tag, $accumulator),
      jsp:parse-tags((), (), $lines)
   )
   else (
      jsp:parse-tags(
         $tag,
         ($accumulator, fn:head($lines)),
         fn:tail($lines))
   )
};

declare function jsp:build-tag($tag as xs:string+, $lines as xs:string+) as element()
{
   let $b := fn:string-join(jsp:ignore-last-empties($lines), '&#10;')
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
         (: TODO: This is an "extension" to xqDoc, document them all... :)
         case 'todo' return
            <todo>{ $b }</todo>
         default return
            <ERROR>
               <msg>Unknown tag: "{ $tag[1] }"</msg>
               { $tag ! <string>{ . }</string> }
               <content>{ $b }</content>
            </ERROR>
};

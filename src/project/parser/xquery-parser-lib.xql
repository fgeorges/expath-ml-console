xquery version "3.0";

module namespace xqp = "http://expath.org/ns/ml/console/parser/xquery";

import module namespace parser   = "http://expath.org/ns/ml/console/parser" at "parser-lib.xql";
import module namespace xqparser = "http://github.com/jpcs/xqueryparser.xq" at "xqueryparser.xq";
import module namespace xqdoc    = "XQDocComments"                          at "lib/XQDocComments.xq";

declare namespace map = "http://marklogic.com/xdmp/map";

declare function xqp:parse($href as xs:string, $module as xs:string)
   as element(module)
{
   parser:parse(
      $href,
      $module,
      map:new((
         map:entry('lang', 'xquery'),
         map:entry('parse', xqparser:parse#1),
         map:entry('functions', function($ast) {
            $ast/Module/(LibraryModule|MainModule)/Prolog/AnnotatedDecl/FunctionDecl
         }),
         map:entry('comment', function($fun, $pos) {
            let $pivot := 
                  if ( $pos eq 1 and $fun/../../..[self::MainModule] ) then
                     $fun/../../..
                  else
                     $fun/..
            return
               $pivot/preceding-sibling::node()[1][self::text()]
         }),
         map:entry('parse-comment', xqdoc:parse-Comments#1),
         map:entry('comment-blocks', function($ast as element()) {
            $ast/XQDocComment
         }),
         map:entry('name', function($fun as element(FunctionDecl)) {
            $fun/QName/@localname
         }),
         map:entry('type', function($fun as element(FunctionDecl)) {
            $fun/SequenceType
         }),
         map:entry('arity', function($fun as element(FunctionDecl)) {
            fn:count($fun/ParamList/Param)
         }),
         map:entry('params', function($fun as element(FunctionDecl)) {
            $fun/ParamList/Param
         }),
         map:entry('param-name', function($param as element(Param)) {
            $param/QName/@localname
         }),
         map:entry('param-type', function($fun as element(Param)) {
            $fun/TypeDeclaration/SequenceType
         }),
         map:entry('opening', '\(:'),
         map:entry('closing', ':\)'),
         map:entry('continuation', ':'))))
};

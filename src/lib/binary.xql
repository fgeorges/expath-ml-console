xquery version "1.0-ml";

module namespace bin = "http://expath.org/ns/ml/console/binary";

declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : Return true if the parameter is a binary node.
 :)
declare function bin:is-binary($arg as node())
   as xs:boolean
{
   $arg instance of binary()
};

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

(:~
 : Return true if the parameter is a JSON node.
 : 
 : http://markmail.org/message/mypneadypxmj4xly
 :)
declare function bin:is-json($arg as node())
   as xs:boolean
{
   typeswitch ( $arg )
      case object-node()  return fn:true()
      case array-node()   return fn:true()
      case number-node()  return fn:true()
      case boolean-node() return fn:true()
      case null-node()    return fn:true()
      default             return fn:false()
};

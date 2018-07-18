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
 : Convert an `xs:hexBinary` item to a binary node.
 :)
declare function bin:hex-binary($arg as xs:hexBinary)
   as binary()
{
    binary { $arg }
};

(:~
 : Convert an `xs:base64Binary` item to a binary node.
 :)
declare function bin:base64-binary($arg as xs:base64Binary)
   as binary()
{
    bin:hex-binary(xs:hexBinary($arg))
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

declare function bin:is-json-array($arg as item())
   as xs:boolean
{
   $arg instance of json:array
};

declare function bin:is-json-object($arg as item())
   as xs:boolean
{
   $arg instance of json:object
};

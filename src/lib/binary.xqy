xquery version "1.0-ml";

module namespace bin = "http://expath.org/ns/ml/console/binary";

declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace xdmp = "http://marklogic.com/xdmp";

(:~
 : Return true if the parameter is a map.
 :)
declare function bin:is-map($arg as item())
   as xs:boolean
{
   $arg instance of map:map
};

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
      case document-node() return bin:is-json($arg/node())
      case object-node()   return fn:true()
      case array-node()    return fn:true()
      case number-node()   return fn:true()
      case boolean-node()  return fn:true()
      case null-node()     return fn:true()
      default              return fn:false()
};

declare function bin:is-json-array($arg as item())
   as xs:boolean
{
   $arg instance of json:array
};

(: TODO: Difference with bin:is-object-node()? :)
declare function bin:is-json-object($arg as item())
   as xs:boolean
{
   $arg instance of json:object
};

(: TODO: Difference with bin:is-json-object()? :)
declare function bin:is-object($arg as item())
   as xs:boolean
{
   $arg instance of object-node()
};

declare function bin:get-arrays($parent as node())
   as array-node()*
{
   $parent/array-node()
};

declare function bin:object($name as xs:string, $content as node()*)
   as object-node()
{
   object-node { $name: $content }
};

declare function bin:array($content as item()*)
   as array-node()
{
   array-node { $content }
};

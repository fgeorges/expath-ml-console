xquery version "3.0";

module namespace this = "http://expath.org/ns/ml/console/api/tool";

declare namespace cts   = "http://marklogic.com/cts";
declare namespace xdmp  = "http://marklogic.com/xdmp";
declare namespace mlerr = "http://marklogic.com/xdmp/error";
declare namespace map   = "http://marklogic.com/xdmp/map";
declare namespace err   = "http://www.w3.org/2005/xqt-errors";

declare variable $prefixes :=
  <prefixes>
    <prefix uri="http://www.w3.org/2001/XMLSchema" prefix="xs"/>
    <prefix uri="http://marklogic.com/cts"         prefix="cts"/>
    <prefix uri="http://marklogic.com/xdmp/map"    prefix="map"/>
    <prefix uri="http://marklogic.com/semantics"   prefix="sem"/>
  </prefixes>;

declare function this:eval-xquery(
  $xquery  as xs:string,
  $vars    as map:map,
  $options as map:map
) as map:map*
{
  let $_   := map:put($options, 'defaultXqueryVersion', '1.0-ml')
  for $res in xdmp:eval($xquery, $vars, $options)
  return
    map:new((
      map:entry('value', $res),
      if ( $res instance of node() ) then (
        map:entry('kind', 'node'),
        map:entry('type', xdmp:node-kind($res) || '()')
      )
      else
        let $type    := xdmp:type($res)
        let $ns      := fn:namespace-uri-from-QName($type)
        let $name    := fn:local-name-from-QName($type)
        let $prefix  := $prefixes/*[@uri eq $ns]/@prefix
        let $kind    := ('query'[$prefix eq 'cts'], 'map'[$prefix eq 'map'], 'atomic')[1]
        let $type    := if ( $prefix ) then $prefix || ':' || $name
                        else '{' || $ns || '}' || $name
        return (
          map:entry('kind', $kind),
          map:entry('type', $type)
        )
    ))
};

xquery version "1.0-ml";

module namespace b = "http://expath.org/ns/ml/webapp/binary";

declare function b:format-bodies($bodies as item()*)
{
  for $b in $bodies
  return
    if ( $b instance of document-node() and $b/node() instance of binary() ) then
      xs:base64Binary($b/node())
    else
      $b
};

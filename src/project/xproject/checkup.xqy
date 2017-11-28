xquery version "3.0";

module namespace check = "http://expath.org/ns/ml/console/project/xproject/checkup";

import module namespace proj  = "http://expath.org/ns/ml/console/project" at "../proj-lib.xqy";
import module namespace xproj = "http://expath.org/ns/ml/console/project/xproject" at "../xproject-lib.xql";
import module namespace a     = "http://expath.org/ns/ml/console/admin"   at "../../lib/admin.xqy";
import module namespace v     = "http://expath.org/ns/ml/console/view"    at "../../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc = "http://expath.org/ns/ml/console";
declare namespace xp  = "http://expath.org/ns/project";

declare function check:page(
   $id     as xs:string, 
   $proj   as element(mlc:project),
   $one    as function(item()*) as element(),
   $exists as function(item()*) as element(),
   $string as function(item()?, xs:boolean) as element()
) as element()+
{
   let $desc := xproj:descriptor($proj)
   let $dir  := proj:directory($proj)
   return (
      <p>Project dir: { $dir ! $string(., a:file-exists(.)) }</p>,
      <p>Dir <code>src</code>: { ($dir || 'src/') ! $string(., a:file-exists(.)) }</p>,
      <p>Dir <code>xproject</code>: { ($dir || 'xproject/') ! $string(., a:file-exists(.)) }</p>,
      <p>Project file: {
          $string($dir || 'xproject/project.xml', fn:exists($desc))
      } </p>,
      <p>Title: { $string($desc/xp:title, fn:exists($desc/xp:title)) }</p>
   )
};

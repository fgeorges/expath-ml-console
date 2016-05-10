xquery version "3.0";

module namespace check = "http://expath.org/ns/ml/console/project/dbdir/checkup";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "../proj-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../../lib/admin.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace mlc = "http://expath.org/ns/ml/console";

declare function check:page(
   $id     as xs:string, 
   $proj   as element(mlc:project),
   $one    as function(item()*) as element(),
   $exists as function(item()*) as element(),
   $string as function(item()?, xs:boolean) as element()
) as element()+
{
   <p>Project DB element: { $exists($proj/mlc:db) }</p>,
   <p>Project DB: { $proj/mlc:db ! $string(., fn:exists(a:database-id(fn:data(.)))) }</p>,
   <p>Root path element: { $exists($proj/mlc:root) }</p>
};

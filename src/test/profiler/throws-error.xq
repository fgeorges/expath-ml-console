xquery version "3.0";

(:~
 : Simulate the "/profiler/profile-json" endpoint, returning an error.
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin"
   at "../../lib/admin.xqy";
import module namespace p = "http://expath.org/ns/ml/console/profile"
   at "../../profiler/profile-lib.xql";

declare variable $db as xs:string :=
   a:get-databases()/a:database[a:name eq 'Documents']/@id;

declare variable $query :=
'
declare function local:fibonacci($n as xs:integer) as xs:integer?
{
   if ( $n lt 0 ) then
      ()
   else if ( $n eq 0 ) then
      0
   else if ( $n eq 1 ) then
      1
   else if ( $n eq 5 ) then
      error((), "FIVE!")
   else
      local:fibonacci($n - 2) + local:fibonacci($n - 1)
};
local:fibonacci(20)
';

p:profile($query, $db, 'json')

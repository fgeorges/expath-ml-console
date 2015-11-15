xquery version "3.0";

(:~
 : The profile service, returning a JSON report.
 :)

import module namespace p = "http://expath.org/ns/ml/console/profile" at "profile-lib.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xql";

p:profile(
   t:mandatory-field('query'),
   t:mandatory-field('target'),
   'json')

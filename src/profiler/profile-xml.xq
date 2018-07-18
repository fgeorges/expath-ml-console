xquery version "3.0";

(:~
 : The profile service, returning an XML report.
 :)

import module namespace p = "http://expath.org/ns/ml/console/profile" at "profile-lib.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools"   at "../lib/tools.xqy";

p:profile(
   t:mandatory-field('query'),
   t:mandatory-field('target'),
   'xml')

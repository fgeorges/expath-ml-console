xquery version "1.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

(: TODO: And validate them! :)
let $site   := t:mandatory-field('site')
let $result := cfg:set-cxan-site($site)
return
   v:console-page(
      'setup',
      'Setup',
      <p>CXAN site set to '{ $result }'.</p>)

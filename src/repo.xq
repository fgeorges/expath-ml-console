xquery version "1.0";

import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";

v:console-page(
   'repo',
   'Repositories',
   <wrapper>
      <p>Please choose a package repository:</p>
      <ul> {
         for $r in cfg:get-repos()/fn:string(@name)
         order by $r
         return
            <li><a href="do-repo.xq?repo={ fn:escape-html-uri($r) }">{ $r }</a></li>
      }
      </ul>
   </wrapper>/*)

xquery version "3.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xql";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "../lib/repo.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c   = "http://expath.org/ns/ml/console";
declare namespace w   = "http://expath.org/ns/ml/webapp";
declare namespace err = "http://www.w3.org/2005/xqt-errors";

declare function local:install-webapp($xaw, $repo, $container, $filename)
   as element(p)
{
   try {
      let $app := r:install-webapp($xaw, $repo, $container)
      return
         <p>Webapp '{ $filename }' successfully installed into the container
            '{ $container/fn:string(@id) }', in its repository
            '{ $repo/fn:string(@name) }', within the package directory
            '{ $app/fn:string(w:pkg-dir) }'.</p>
   }
   catch c:* {
      <p><b>Error</b>: { $err:description }</p>
   }
};

let $name      := t:mandatory-field('container')
let $ref       := cfg:get-container-ref($name)
let $container := cfg:get-container($ref)
let $repo      := cfg:get-repo($container/w:repo)
let $xaw       := t:mandatory-field('xaw')
let $filename  := t:mandatory-field-filename('xaw')
let $stored    := r:save-in-attic($xaw, $filename, $repo)
(:
let $override  := xs:boolean(t:optional-field('override', 'false'))
let $app       := r:install-webapp($xaw, $repo, $container, $override)
:)
return
   v:console-page(
      'web',
      'Install webapp',
      '../',
      (
         local:install-webapp($xaw, $repo, $container, $filename),
         <p>Back to the <a href="show.xq?container={ $name }">web container</a>.</p>
      ))

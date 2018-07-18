xquery version "3.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xqy";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "../lib/repo.xqy";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c   = "http://expath.org/ns/ml/console";
declare namespace w   = "http://expath.org/ns/ml/webapp";
declare namespace err = "http://www.w3.org/2005/xqt-errors";

(: TODO: Ask confirmation before deleting, as for packages!
 :)

declare function local:page()
   as element()+
{
   let $id        := t:mandatory-field('container')
   let $ref       := cfg:get-container-ref($id)
   let $container := cfg:get-container($ref)
   let $root      := t:mandatory-field('webapp')
   return (
      local:delete-webapp($container, $root),
      <p>Back to the <a href="show.xq?container={ $id }">web container</a>.</p>
   )
};

declare function local:delete-webapp($container as element(w:container), $root as xs:string)
   as element(p)
{
   let $app := $container/w:application[@root eq $root]
   return
      if ( fn:empty($app) ) then
         <p>Application does not exist (root={ $root }, container={ $container/fn:string(@id) }).</p>
      else (
         r:delete-webapp($app),
         <p>Webapp '{ $root }' successfully deleted from the container '{ $container/fn:string(@id) }'.</p>
      )
};

v:console-page('../', 'web', 'Install webapp', local:page#0)

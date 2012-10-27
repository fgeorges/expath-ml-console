xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xql";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page()
   as element()+
{
   (: TODO: Check the parameters have been passed, to avoid XQuery errors! :)
   (: (turn them into human-friendly errors instead...) :)
   (: And validate them! (for instance is $id a lexical NCName?) :)
   let $id        := t:mandatory-field('id')
   let $name      := t:mandatory-field('name')
   let $root      := t:mandatory-field('root')
   let $as-id     := t:mandatory-field('appserver')
   let $appserver := a:get-appserver(xs:unsignedLong($as-id))
   let $repo      := t:optional-field('repo', ())
   let $repo-id   := t:optional-field('repo-id', ())
   let $repo-name := t:optional-field('repo-name', ())
   let $repo-root := t:optional-field('repo-root', ())
   return (
      (: TODO: Any of those errors MUST prevent going any further...! :)
      if ( fn:exists($repo) and fn:exists(($repo-id, $repo-name, $repo-root)) ) then
         <p><b>Error</b>: The param 'repo' is exclusive with 'repo-id', 'repo-name'
            and 'repo-root'. Values passed resp.: '{ $repo }', '{ $repo-id }',
            '{ $repo-name }' and '{ $repo-root }'.</p>
      else if ( fn:empty(($repo, $repo-id, $repo-name, $repo-root)) ) then
         <p><b>Error</b>: You have to either select an existing repository
            or to create a new one.</p>
      else if ( fn:empty($repo) and ( fn:empty($repo-id) or fn:empty($repo-name) or fn:empty($repo-root) ) ) then
         <p><b>Error</b>: The params 'repo-id', 'repo-name' and 'repo-root'
            must all be set to create a new repository. Values passed resp.:
            '{ $repo-id }', '{ $repo-name }' and '{ $repo-root }'.</p>
      else
         local:create-container($id, $name, $root, $appserver, $repo, $repo-id, $repo-name, $repo-root),
      <p>Back to <a href="../web.xq">web containers</a>.</p>
   )
};

(:~
 : TODO: ...
 :)
declare function local:create-container(
   $id        as xs:string,
   $name      as xs:string,
   $root      as xs:string,
   $appserver as element(a:appserver),
   $repo      as xs:string?,
   $repo-id   as xs:string?,
   $repo-name as xs:string?,
   $repo-root as xs:string?
) as element(h:p)
{
   try {
      let $repo :=
            if ( fn:exists($repo) ) then
               cfg:get-repo($repo)
            else
               local:create-repo-in-appserver($repo-id, $repo-name, $repo-root, $appserver)
      let $container := cfg:create-web-container($id, $name, $root, $appserver, $repo)
      return
         <p>Web container '{ $name }' has been successfuly created.</p>
   }
   (: TODO: Make it generic for c:* errors, they all contain a proper message.:)
   catch c:repo-exists {
      <p><b>Error</b>: Error creating the repository '{ $repo-id }', it already exists.</p>
   }
};

(:~
 : TODO: ...
 : TODO: Duplicated in repo/create.xq, factorize out!
 : (no, actually we don't want the same here, we don;t want to return part of
 : the result page, we want to create the repo and stop everything else if there
 : is an error...)
 :)
declare function local:create-repo-in-appserver(
   $id   as xs:string,
   $name as xs:string,
   $root as xs:string,
   $as   as element(a:appserver)
) as element(c:repo)
{
   if ( fn:exists($as/a:modules-path) ) then
      cfg:create-repo-in-directory($id, $name, $root, $as/a:modules-path)
   else if ( fn:exists($as/a:modules-db) ) then
      (: TODO: Should we adapt the root to take DB's root in the AppServer? :)
      let $id   := xs:unsignedLong($as/a:modules-db/@id)
      let $db   := a:get-database($id)
      return
         cfg:create-repo-in-database($id, $name, $root, $id, $db/fn:string(a:name))
   else
      t:error('SETUP002', ('How can I have a WebDAV appserver here?!?: ', xdmp:quote($as)))
};

v:console-page('../', 'web', 'Web containers', local:page#0)

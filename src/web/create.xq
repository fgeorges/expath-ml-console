xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xqy";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xqy";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare option xdmp:update "true";

(:
 : TODO: For the validation of the $repo params, use the submit buttons.  There
 : are 2 different buttons (select and create), so we know in which case we are
 : (to which case we have to comply...)!
 :)

(:~
 : TODO: ...
 :)
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
   let $dummey    := local:check-repo-params($repo, $repo-id, $repo-name, $repo-root)
   return (
      local:create-container($id, $name, $root, $appserver, $repo, $repo-id, $repo-name, $repo-root),
      <p>Back to <a href="../web">web containers</a>.</p>
   )
};

(:~
 : Check the 4 repo params from the request are consistent.
 :)
declare function local:check-repo-params(
   $repo      as xs:string?,
   $repo-id   as xs:string?,
   $repo-name as xs:string?,
   $repo-root as xs:string?
) as empty-sequence()
{
   if ( fn:exists($repo) and fn:exists(($repo-id, $repo-name, $repo-root)) ) then
      local:repo-params-error('The param repo is exclusive with repo-id, repo-name and repo-root.', $repo, $repo-id, $repo-name, $repo-root)
   else if ( fn:empty(($repo, $repo-id, $repo-name, $repo-root)) ) then
      local:repo-params-error('You have to either select an existing repository or to create a new one.', $repo, $repo-id, $repo-name, $repo-root)
   else if ( fn:empty($repo) and ( fn:empty($repo-id) or fn:empty($repo-name) or fn:empty($repo-root) ) ) then
      local:repo-params-error('The params repo-id, repo-name and repo-root must all be set to create a new repository.', $repo, $repo-id, $repo-name, $repo-root)
   else
      ()
};

declare function local:repo-params-error(
   $msg       as xs:string,
   $repo      as xs:string?,
   $repo-id   as xs:string?,
   $repo-name as xs:string?,
   $repo-root as xs:string?
) as empty-sequence()
{
   t:error(
      'wrong-params',
      $msg || ' Values passed: repo=' || $repo || ', repo-id=' || $repo-id
         || ', repo-name=' || $repo-name || ' and repo-root=' || $repo-root || '.')
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
   let $repo as element(c:repo) :=
         if ( fn:exists($repo) ) then
            cfg:get-repo($repo)
         else
            local:create-repo-in-appserver($repo-id, $repo-name, $repo-root, $appserver)
   let $container := cfg:create-web-container($id, $name, $root, $appserver, $repo)
   return
      <p>Web container '{ $name }' has been successfuly created.</p>
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
      let $db-id := $as/a:modules-db/@id
      let $db    := a:get-database(xs:unsignedLong($db-id))
      return
         cfg:create-repo-in-database($id, $name, $root, $db-id, $db/fn:string(a:name))
   else
      t:error(
         'invalid-appserver',
         'How can I have a WebDAV appserver here?!?: ' || xdmp:quote($as))
};

v:console-page('../', 'web', 'Web containers', local:page#0)

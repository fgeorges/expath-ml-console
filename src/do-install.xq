xquery version "1.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace r   = "http://expath.org/ns/ml/console/repo"   at "lib/repo.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace zip  = "xdmp:zip";

(: TODO: Check the params are there, and validate them... :)
let $reponame := t:mandatory-field('repo')
let $repo     := cfg:get-repo($reponame)
let $xar      := t:mandatory-field('xar')
(: TODO: Check the filename is there... :)
let $filename := t:mandatory-field-filename('xar')
let $stored   := r:save-in-attic($xar, $filename, $repo)
let $pkg      := r:install($xar, $repo)
(:
let $override := xs:boolean(t:optional-field('override', 'false'))
let $pkg      := r:install($xar, $repo, $override)
:)
return
   v:console-page(
      'install',
      'Install',
      if ( exists($pkg) ) then
         <p>Package '{ $filename }' successfully installed into the repository
            '{ $reponame }', within the package directory '{ $pkg/fn:string(@dir) }'.</p>
      else
         (: TODO: Provide more accurate info! :)
         <p>Package '{ $filename }' NOT installed into '{ $reponame }'.  Did it
            already exist?</p>)

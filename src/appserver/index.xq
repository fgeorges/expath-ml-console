xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace pp = "http://expath.org/ns/repo/packages";

(: path relative to the AS. TODO: To be moved to a lib... :)
declare variable $packages-path := 'expath-repo/.expath-pkg/packages.xml';

(:~
 : Implement the page when there is no repo setup fot the app server.
 :)
declare function local:page-no-repo($as as element(a:appserver))
   as element()+
{
   <wrapper>
      <p>The app server { v:as-link($as/@id, $as/a:name) } has no repo setup.
         In order to be able to install packages for this app server, you must
         first setup a repo.</p>
      <p>Do you want to set one up?</p>
      { v:inline-form($as/@id || '/init-repo', v:submit('Initialise')) }
   </wrapper>/*
};

(:~
 : Implement the page when there is a repo setup fot the app server.
 :)
declare function local:page-with-repo($as as element(a:appserver), $pkgs as element(pp:packages))
   as element()+
{
   <wrapper>
      <p>Packages on { v:as-link($as/@id, $as/a:name) }</p>
      <h3>Installed packages</h3>
      {
         if ( fn:empty($pkgs/pp:package) ) then
            <p>There is no package installed on this app server.</p>
         else (
            <table class="table table-striped">
               <thead>
                  <th>Name</th>
                  <th>Dir</th>
                  <th>Version</th>
                  <th>Action</th>
               </thead>
               <tbody> {
                  for $p in $pkgs/pp:package
                  order by $p/fn:string(@dir)
                  return
                     local:package-row($p, $as)
               }
               </tbody>
            </table>
         )
      }
      <h3>Install from file</h3>
      <p>Install packages and applications from your filesystem, using a package
         file (usually a *.xar file).</p>
      {
         v:form($as/@id || '/install-pkg', (
            v:input-file('xar', 'Package file'),
            v:submit('Install')
            (: v:input-checkbox('override', 'true', 'Override the package if it already exists') :) ))
      }
      <h3>Install from CXAN</h3>
      <p>Install packages and applications directly from CXAN, using a package
         name or a CXAN ID (one or the other), and optionally a version number
         (retrieve the latest version by default).</p>
      <p>The default CXAN website is <a href="http://cxan.org/">http://cxan.org/</a>.
         If you are not sure, keep that one.  If you want to use the development
         CXAN website, you can use <a href="http://dev.cxan.org/">http://devcxan.org/</a>
         instead.</p>
      {
         (: TODO: Next step: use an XSLT stylesheet, and generate XML instead of
            calling functions to generate HTML... :)
         v:form($as/@id || '/install-cxan', (
            v:input-text('pkg',     'ID',      'CXAN package ID...'),
            v:input-text('name',    'Name',    '...or package name'),
            v:input-text('version', 'Version', 'Package version (latest by default)'),
            v:submit('Install'),
            v:input-select('std-website', 'Source website', (
               v:input-option('prod', 'http://cxan.org/'),
               v:input-option('dev',  'http://dev.cxan.org/'))),
            v:input-text('other=website', 'Other source',
               'Other specific CXAN website to use')))
      }
      <h3>Nuke the repo</h3>
      <p>Delete the package repository that has been setup on this app server.</p>
      {
         v:form($as/@id || '/delete-repo', v:submit('Delete'))
      }
   </wrapper>/*
};

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   let $id-str := t:mandatory-field('id')
   let $id     := xs:unsignedLong($id-str)
   let $as     := a:get-appserver($id)
   let $pkgs   := a:appserver-get-packages($as)
   return
      if ( fn:empty($pkgs) ) then
         local:page-no-repo($as)
      else
         local:page-with-repo($as, $pkgs)
};

declare function local:package-row($pkg as element(pp:package), $as as element(a:appserver))
   as element(tr)
{
   <tr>
      <td>{ $pkg/fn:string(@name) }</td>
      <td>{ $pkg/fn:string(@dir) }</td>
      <td>{ $pkg/fn:string(@version) }</td>
      <td> {
         v:inline-form($as/@id || '/pkg/' || $pkg/fn:escape-html-uri(@dir) || '/delete',
            v:submit('Delete'))
      }
      </td>
   </tr>
};

v:console-page('../', 'pkg', 'App server', local:page#0)

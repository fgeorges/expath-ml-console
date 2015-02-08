xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "lib/view.xql";

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
      <p>The app server "<code>{ $as/a:name }</code>" has no repo setup.  In
         order to be able to install packages for this app server, you must
         first setup a repo.  Do you want to set one up?</p>
      <form method="post" action="{ $as/@id }/init-repo" enctype="multipart/form-data">
         <input type="submit" value="Initialize"/>
         <span> repo for this app server.</span>
      </form>
   </wrapper>/*
};

(:~
 : Implement the page when there is a repo setup fot the app server.
 :)
declare function local:page-with-repo($as as element(a:appserver), $pkgs as element(pp:packages))
   as element()+
{
   <wrapper>
      {
         if ( fn:empty($pkgs/pp:package) ) then
            <p>The app server "<code>{ $as/a:name }</code>" has no package installed.</p>
         else (
            <p>The app server "<code>{ $as/a:name }</code>" has the following packages installed:</p>,
            <table class="sortable">
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
      <h4>Install from file</h4>
      <p>Install packages and applications from your filesystem, using a package
         file (usually a *.xar file).</p>
      <form method="post" action="{ $as/@id }/install-pkg" enctype="multipart/form-data">
         <input type="file" name="xar"/>
         <input type="submit" value="Install"/>
         <!--br/><br/>
         <input type="checkbox" name="override" value="true"/>
         <em>Override the package of it already exists</em-->
      </form>
      <h4>Install from CXAN</h4>
      <p>Install packages and applications directly from CXAN, using a package
         name or a CXAN ID (one or the other), and optionally a version number
         (retrieve the latest version by default).</p>
      <form method="post" action="{ $as/@id }/install-cxan" enctype="multipart/form-data">
         <span>ID:</span>
         <input type="text" name="pkg" size="25"/>
         <br/>
         <span> or name:</span>
         <input type="text" name="name" size="50"/>
         <br/>
         <span>Version (optional):</span>
         <input type="text" name="version" size="15"/>
         <br/>
         <input type="submit" value="Install"/>
         <br/>
         <span>CXAN website to use: </span>
         <select name="std-website">
            <option value="prod">http://cxan.org/</option>
            <option value="dev">http://dev.cxan.org/</option>
         </select>
         <br/>
         <span>Or specific CXAN to use:</span>
         <input type="text" name="other-website" size="50"/>
      </form>
      <h4>Nuke the repo</h4>
      <form method="post" action="{ $as/@id }/delete-repo" enctype="multipart/form-data">
         <p>Delete the package repository that has been setup on this app server.</p>
         <input type="submit" value="Delete"/>
      </form>
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
      <td>
         <!--a href="{ $as/@id }/{ $pkg/fn:escape-html-uri(@dir) }/delete-pkg">delete</a-->
         <form method="post" action="{ $as/@id }/pkg/{ $pkg/fn:escape-html-uri(@dir) }/delete" enctype="multipart/form-data">
            <input type="submit" value="Delete"/>
         </form>
      </td>
   </tr>
};

v:console-page('../', 'pkg', 'App server', local:page#0)

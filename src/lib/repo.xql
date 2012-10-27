xquery version "3.0";

module namespace r = "http://expath.org/ns/ml/console/repo";

import module namespace a   = "http://expath.org/ns/ml/console/admin" at "admin.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools" at "tools.xql";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace w    = "http://expath.org/ns/ml/webapp";
declare namespace pkg  = "http://expath.org/ns/pkg";
declare namespace pp   = "http://expath.org/ns/repo/packages";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace zip  = "xdmp:zip";

(: ==== Simple repo tools ======================================================== :)

(:~
 : Return true if $repo is a repository stored on the filesystem.
 :
 : TODO: That info should be stored directly in $repo!
 :)
declare function r:is-filesystem-repo($repo as element(c:repo))
   as xs:boolean
{
   fn:exists($repo/c:absolute)
};

(:~
 : Save the package $xar with name $filename in attic of the $repo.
 :
 : The attic is in [repo]/.expath-pkg/attic/.
 :)
declare function r:save-in-attic(
   $xar   (: as binary() :),
   $filename as xs:string,
   $repo     as element(c:repo)
) as xs:string
{
   (: TODO: Check if it already exists! :)
   r:insert-into(
      fn:concat('.expath-pkg/attic/', $filename),
      $xar,
      $repo)
};

(:~
 : Insert a file in a repository.
 :
 : $file is the relative path to store the file (relative to the $repo root).
 :)
declare function r:insert-into(
   $file as xs:string,
   $doc  as node(),
   $repo as element(c:repo)
) as xs:string
{
   if ( r:is-filesystem-repo($repo) ) then
      a:insert-into-directory($repo/c:absolute, $file, $doc)
   else
      a:insert-into-database($repo/c:database/@id, fn:concat($repo/c:root, $file), $doc)
};

(:~
 : Insert a file in a repository.
 :)
declare function r:get-from(
   $file as xs:string,
   $repo as element(c:repo)
) as node()?
{
   if ( r:is-filesystem-repo($repo) ) then
      a:get-from-directory($repo/c:absolute, $file)
   else
      a:get-from-database($repo/c:database/@id, $repo/c:root, $file)
};

(:~
 : Return the packages info for $repo.
 :
 : TODO: Is the returned element really optional?
 :)
declare function r:get-packages-list($repo as element(c:repo))
   as element(pp:packages)?
{
   r:get-from('.expath-pkg/packages.xml', $repo)/*
};

(:~
 : Return the list of packages to be removed in $repo.
 :)
declare function r:get-to-remove-list($repo as element(c:repo))
   as element(pp:packages)?
{
   r:get-from('.expath-pkg/to-remove.xml', $repo)/*
};

(:~
 : Return the package info for $pkg/$version in $repo.
 :)
declare function r:get-package-by-name(
   $name    as xs:string,
   $version as xs:string,
   $repo    as element(c:repo)
) as element(pp:package)?
{
   r:get-packages-list($repo)/pp:package[@name eq $name][@version eq $version]
};

(:~
 : Return the package info in $repo given the package directory $pkgdir.
 :)
declare function r:get-package-by-pkgdir(
   $pkgdir as xs:string,
   $repo   as element(c:repo)
) as element(pp:package)?
{
   r:get-packages-list($repo)/pp:package[@dir eq $pkgdir]
};

(: ==== Managing packages ======================================================== :)

(:~
 : Install the package $xar in $repo.
 :
 : Return the new package description from packages.xml if the package has been
 : installed, nothing if not if not (the package can have been not installed if
 : it already existed and $override is false).
 :
 : If the package already exists, $override tells what to do: either override
 : or do nothing and return nothing.
 :
 : TODO: Overriding an existing package has been disable for now.  Either re
 :)
declare function r:install-package(
   $xar     (: as binary() :),
   $repo     as element(c:repo)
) as element(pp:package)?
(:
declare function r:install-package(
   $xar     (: as binary() :),
   $repo     as element(c:repo),
   $override as xs:boolean
) as element(pp:package)?
:)
{
   (: create the package dir name from the package descriptor :)
   let $desc    := xdmp:zip-get($xar, 'expath-pkg.xml')
   let $name    := $desc/pkg:package/fn:string(@name)
   let $abbrev  := $desc/pkg:package/fn:string(@abbrev)
   let $version := $desc/pkg:package/fn:string(@version)
   let $pkg     := r:get-package-by-name($name, $version, $repo)
   return
      if ( fn:exists($pkg) ) then
         ()
      else
         (: TODO: Validate $pkgdir (no space, it does not exist, etc.) :)
         let $pkgdir  := fn:concat($abbrev, '-', $version)
         let $in-db   := r:is-filesystem-repo($repo)
         (: TODO: Binary?  Really?  Even for, say, XSLT stylesheets? :)
         let $options := <options xmlns="xdmp:zip-get"><format>binary</format></options>
         return (
            (: unzip each entry in the XAR to the package dir :)
            for $part in xdmp:zip-manifest($xar)/zip:part/fn:string(.)
            where fn:not(fn:ends-with($part, '/')) (: skip dir entries :)
            return
               r:insert-into(
                  fn:concat($pkgdir, '/', $part),
                  xdmp:zip-get($xar, $part, $options),
                  $repo),
            (: update the repository descriptor :)
            (: TODO: Detect if already there! (we can have duplicate if we add w/o checking) :)
            (: TODO: When the repo is in a database, we should update the document in place! :)
            (: TODO: Create a dedicated function to get/update packages.xml, as it is recorded
               in $repo (either packages-doc or packages-file).  See r:get-packages-list()... :)
            r:insert-into(
               '.expath-pkg/packages.xml',
               t:add-last-child(
                  r:get-from('.expath-pkg/packages.xml', $repo)/pp:packages,
                  <package xmlns="http://expath.org/ns/repo/packages"
                           name="{ $name }" dir="{ $pkgdir }" version="{ $version }"/>),
               $repo),
            r:get-package-by-name($name, $version, $repo)
         )[fn:last()]
};

(:~
 : Delete the package in the package directory $pkgdir from $repo.
 :
 : TODO:
 :   * for filesystem:
 :       - mark the package directory to be deleted
 :       - remove everything from ML (from packages.xml, etc.)
 :   * for databases:
 :       - use xdmp:directory($pkgdir, 'infinity') to get all the URIs of the documents
 :       - delete everything in $pkgdir
 :       - possible to remove directories as well? their property documents?
 :       - remove everything from ML (from packages.xml, etc.)
 :   * OLD for DB (might still be useful, move to r:install-package...):
 :       - add all the files to a collection for $repo/$pkdir when unzipping
 :       - http://expath.org/coll/pkg/repos/{repo}/packages/{pkgdir}
 :       - add that collection name to packages.xml
 :)
declare function r:delete-package(
   $pkg  as element(pp:package),
   $repo as element(c:repo)
)
{
   if ( r:is-filesystem-repo($repo) ) then
      (: TODO: Provide a way, in the GUI, for the user to forget one such package
         in to-remove.xml, once he has actually deleted it... :)
      r:insert-into(
         '.expath-pkg/to-remove.xml',
         t:add-last-child(r:get-from('.expath-pkg/to-remove.xml', $repo)/*, $pkg),
         $repo)
   else
      a:remove-directory($repo/c:database/@id, fn:concat($repo/c:root, $pkg/@dir)),
   r:remove-package-from-list($pkg, $repo)
};

(:~
 : Remove the package element from packages.xml, the repo package list.
 :)
declare %private function r:remove-package-from-list(
   $pkg  as element(pp:package),
   $repo as element(c:repo)
)
{
   r:insert-into(
      '.expath-pkg/packages.xml',
      <packages xmlns="http://expath.org/ns/repo/packages"> {
         r:get-from('.expath-pkg/packages.xml', $repo)/pp:packages/pp:package[fn:not(@dir eq $pkg/@dir)]
      }
      </packages>,
      $repo)
};

(: ==== Managing webapps ======================================================== :)

(:~
 : Install the webapp $xaw in $container (storage in $repo).
 :
 : TODO: Not implemented yet.
 :)
declare function r:install-webapp(
   $xaw    (: as binary() :),
   $repo      as element(c:repo),
   $container as element(w:container)
) as element(w:application)
(:
declare function r:install-webapp(
   $xaw    (: as binary() :),
   $repo      as element(c:repo),
   $container as element(w:container),
   $override  as xs:boolean
) as element(w:application)
:)
{
   t:error(
      'not-implemented-yet',
      'The function r:install-webapp($xaw, $repo, $container) is not implemented yet!')
};

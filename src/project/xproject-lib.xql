xquery version "3.0";

(:~
 : Information retrieval and manipulation for projects of type `xproject`.
 :)
module namespace this = "http://expath.org/ns/ml/console/project/xproject";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xql";

declare namespace mlc = "http://expath.org/ns/ml/console";
declare namespace xp  = "http://expath.org/ns/project";

declare function this:descriptor($proj as element(mlc:project))
   as element(xp:project)?
{
   proj:directory($proj)
      ! a:get-from-directory(., 'xproject/project.xml', fn:true())
      / *
};

declare function this:source($proj as element(mlc:project), $src as xs:string)
   as text()?
{
   proj:directory($proj)
      ! a:get-from-directory(. || 'src/', $src, fn:false())
};

declare function this:sources($proj as element(mlc:project))
   as xs:string*
{
   proj:directory($proj)
      ! this:sources-1(. || 'src/')
};

(: TODO: Store the module extension in xproject/marklogic.xml.
 :)
declare variable $exts := ('xq', 'xql', 'xqy', 'xqm');

(: TODO: Add filtering by extension to admin.xql...
 :)
declare function this:sources-1($dir as xs:string)
   as xs:string*
{
   a:browse-files($dir, function($file as xs:string) as xs:string? {
      fn:substring-after($file, $dir)[fn:tokenize(., '\.')[fn:last()] = $exts]
   })
};

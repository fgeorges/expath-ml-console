xquery version "3.0";

(:~
 : Information retrieval and manipulation for projects of type `dbdir`.
 :)
module namespace this = "http://expath.org/ns/ml/console/project/dbdir";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xqy";
import module namespace a    = "http://expath.org/ns/ml/console/admin"   at "../lib/admin.xqy";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

declare namespace mlc = "http://expath.org/ns/ml/console";

declare function this:title($proj as element(mlc:project))
   as xs:string?
{
   $proj/mlc:title
};

declare function this:info($proj as element(mlc:project))
   as item()*
{
   v:db-link('db/' || $proj/mlc:db, $proj/mlc:db),
   ' - ',
   v:dir-link('db/' || $proj/mlc:db || '/', $proj/mlc:root)
};

declare function this:db($proj as element(mlc:project))
   as xs:string
{
   $proj/mlc:db
};

declare function this:root($proj as element(mlc:project))
   as xs:string
{
   $proj/mlc:root
};

declare function this:readme($proj as element(mlc:project))
   as text()?
{
   a:get-from-database($proj/mlc:db, $proj/mlc:root || 'README.md')/node()
};

declare function this:source($proj as element(mlc:project), $src as xs:string)
   as text()?
{
   a:get-from-database($proj/mlc:db, $proj/mlc:root || $src)/node()
};

declare function this:sources($proj as element(mlc:project))
   as element(file)*
{
   this:root($proj)
      ! this:sources-1($proj, this:db($proj), .)
};

(: TODO: Store the module extension in the project config file.
 :)
declare variable $source-exts :=
   <extensions>
      <lang lang="xquery">
         <ext>xq</ext>
         <ext>xql</ext>
         <ext>xqy</ext>
         <ext>xqm</ext>
      </lang>
      <lang lang="javascript">
         <ext>sjs</ext>
      </lang>
   </extensions>;

(: TODO: Add filtering by extension to admin.xql...
 :)
declare function this:sources-1($proj as element(mlc:project), $db as xs:string, $dir as xs:string)
   as element(file)*
{
   a:browse-db-files($db, $dir, function($file as xs:string) as element(file)? {
      let $name := fn:substring-after($file, $dir)
      return
         this:source-lang($proj, $name) ! <file lang="{ . }">{ $name }</file>
   })
};

declare function this:source-lang($proj as element(mlc:project), $path as xs:string)
   as xs:string?
{
   let $ext  := fn:tokenize($path, '\.')[fn:last()]
   return
      $source-exts/lang[ext = $ext]/@lang
};

xquery version "3.0";

module namespace b = "http://expath.org/ns/ml/console/browse";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace cts  = "http://marklogic.com/cts";

(: Fixed page size for now. :)
declare variable $b:page-size := 100;

(:~
 : The path to the database root, relative to current $path.
 :)
declare function b:get-db-root($path as xs:string?)
   as xs:string
{
   if ( fn:empty($path) ) then
      './'
   else
      let $toks  := fn:tokenize($path, '/')
      let $count := fn:count($toks) + (-1[fn:starts-with($path, '/')], 0)[1]
      return
         t:make-string('../', $count)
};

(:~
 : Implementation function for `b:get-children-uri()` and `b:get-children-coll()`.
 :)
declare %private function b:get-children-impl(
   $base    as xs:string,
   $start   as xs:integer,
   (: Using the param type declaration generates a seg fault. Yup. :)
   (: $matcher as function(xs:string) as xs:string* :)
   $matcher
) as xs:string*
{
   let $add  := fn:not($base eq '' or fn:ends-with($base, '/'))
   let $pref := $base || '/'[$add] || '*'
   let $expr := $base || '/'[$add]
   let $repl := '^(' || $expr || '([^/]*/){1}).*'
   return
      (: TODO: Why is distinct-valus needed?  Any way to get rid of it? :)
      (: Do we really need to filter out "$path"?  Can't we get rid of it by tweaking the regex? :)
      fn:distinct-values(
         $matcher($pref) ! fn:replace(., $repl, '$1'))
         [. ne $base]
         [fn:position() ge $start and fn:position() lt $start + $b:page-size]
};

(:~
 : Return the "directory" and "file" direct children of $base directory.
 :)
declare function b:get-children-uri(
   $base  as xs:string,
   $start as xs:integer
) as xs:string*
{
   b:get-children-impl($base, $start, cts:uri-match#1)
};

(:~
 : Return the "directory" and "file" direct children of $base "collection directory".
 :)
declare function b:get-children-coll(
   $base  as xs:string,
   $start as xs:integer
) as xs:string*
{
   b:get-children-impl($base, $start, cts:collection-match#1)
};

(:~
 : TODO: Document... (especially the fact it accesses the entire URI index,
 : should be a problem with large databases, with a shit loads of documents.
 : TODO: The details of how to retrieve the children must be in lib/admin.xql.
 :)
declare function b:display-list(
   $path     as xs:string?,
   $children as xs:string*,
   $start    as xs:integer,
   $itemizer as function(xs:string, xs:integer) as element()+,
   $lister   as function(element()*) as element()+
) as element()+
{
   if ( fn:empty($children) ) then (
      <p>No such collection.</p>
   )
   else (
      if ( fn:exists($path) ) then
         let $count := fn:count($children)
         let $to    := $start + $count - 1
         return
            <p>
               Content of { b:uplinks($path, fn:true()) },
               results { $start } to { $to }{
                  t:cond($start gt 1,
                     (', ', <a href="./?start={ $start - $b:page-size }">previous page</a>)),
                  t:cond($count eq $b:page-size,
                     (', ', <a href="./?start={ $start + $count }">next page</a>))
               }:
            </p>
      else
         (),
      $lister(
         for $child at $pos in $children
         order by $child
         return
            $itemizer($child, $pos))
   )
};

(:~
 : Display the current directory, with each part being a link up to it.
 : 
 : Display the current directory (the parent directory when displaying a file).
 : Each part of the directory is clickable to go up to it in the browser (when
 : displaying a directory, the last part is not clickable, as it is the current
 : dir).
 :
 : The path is within quotes `"`, and contains appropriate text after (and a
 : link up to "/" when the path starts with "/", as it is not convenient to
 : click on such a short text).
 :)
declare function b:uplinks($path as xs:string, $isdir as xs:boolean)
   as node()+
{
   (: The 3 cases must be handled in slightly different ways, because the "go back
      to root" button is not necessary with "http" URIs (just click on the domain
      name part), while it is necessary for "/" URIs (clicking on the "/" is just
      no an option). :)
   if ( $path eq '/' ) then (
      v:dir-link('./', '/')
   )
   else if ( fn:starts-with($path, '/') ) then (
      let $toks := fn:tokenize($path, '/')[.]
      return (
         v:dir-link('./' || t:make-string('../', fn:count($toks) - (0[$isdir], 1)[1]), '/'),
         b:uplinks-1($toks[fn:position() lt fn:last()], ('../'[$isdir], './')[1]),
         if ( $isdir ) then (
            text { ' ' },
            v:dir-link('./', $toks[fn:last()] || '/')
         )
         else (
         )
      )
   )
   else if ( fn:starts-with($path, 'http://') ) then (
      let $toks_ := fn:remove(fn:tokenize($path, '/')[.], 1)
      let $toks  := ( 'http://' || $toks_[1], fn:remove($toks_, 1) )
      return (
         b:uplinks-1($toks[fn:position() lt fn:last()], ('../'[$isdir], './')[1]),
         if ( $isdir ) then (
            text { ' ' },
            v:dir-link('./', $toks[fn:last()] || '/')
         )
         else (
         )
      )
   )
   else (
      text { '(' },
      <a href="../">go up</a>,
      text { ') "' || $path || '"' }
   )
};

declare function b:uplinks-1($toks as xs:string*, $up as xs:string?)
   as node()*
{
   if ( fn:empty($toks) ) then (
   )
   else (
      b:uplinks-1($toks[fn:position() lt fn:last()], '../' || $up),
      text { ' ' },
      v:dir-link($up, $toks[fn:last()] || '/')
   )
};

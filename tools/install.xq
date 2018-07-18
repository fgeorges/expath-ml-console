xquery version "3.0";

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace http = "xdmp:http";
declare namespace zip  = "xdmp:zip";

(: Branch to download from GitHub, or a file accessible locally on the server:
 :
 : <config>
 :    <branch>develop</branch>
 : </config>
 :
 : or
 : 
 : <config>
 :    <file>/tmp/expath-ml-console-master.zip</file>
 : </config>
 :)
declare variable $config :=
   <config>
      <branch>feature/projects</branch>
   </config>;

declare function local:zip()
{
   let $branch := $config/branch/xs:string(.)[.]
   let $file   := $config/file/xs:string(.)[.]
   return
      if ( fn:exists($branch) and fn:exists($file) ) then
         fn:error((), 'Both branch and file specified: ' || $branch || ' - ' || $file)
      else if ( fn:exists($branch) ) then
         local:get($branch)
      else if ( fn:exists($file) ) then
         xdmp:external-binary($file)
      else
         fn:error((), 'Neither branch or file specified')
};

declare function local:get($branch as xs:string)
   as document-node()
{
   let $base := 'https://codeload.github.com/fgeorges/expath-ml-console/zip/'
   let $url  := $base || $branch
   let $res  := xdmp:http-get($url)
   return
      if ( $res[1]/xs:integer(http:code) eq 200 ) then
         $res[2]
      else
         fn:error((), 'HTTP GET on <' || $url || '> - ' || xdmp:quote($res[1])
            || ' - ' || xdmp:quote($res[2]))
};

let $zip   := local:zip()
let $parts := xdmp:zip-manifest($zip)/zip:part
let $src   := $parts[1]/fn:substring-before(., '/') || '/src/'
let $trunk := $src || 'trunk/'
let $len   := fn:string-length($src)
for $s     in $parts
                 [fn:starts-with(., $src)]
                 [fn:not(fn:ends-with(., '/'))]
                 [fn:not(fn:starts-with(., $trunk))]
                 / xs:string(.)
let $dest  := fn:substring($s, $len)
(: all mimetypes seem to be alright, except of course for .xql :)
let $opt   := <options xmlns="xdmp:zip-get"><format>text</format></options>[fn:ends-with($dest, '.xql')]
return
   xdmp:document-insert($dest, xdmp:zip-get($zip, $s, $opt))

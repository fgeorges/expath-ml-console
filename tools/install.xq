xquery version "3.0";

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace zip  = "xdmp:zip";

(: Choose a branch to be downloaded from GitHub, or a file accessible locally
   on the server.  So either:

   <config>
      <branch>develop</branch>
   </config>

   or
   
   <config>
      <file>/tmp/expath-ml-console-master.zip</file>
   </config>
:)
declare variable $config :=
   <config>
      <branch>feature/projects</branch>
   </config>;

declare variable $branch := $config/branch/xs:string(.);
declare variable $file   := $config/file/xs:string(.);

if $branch and $file -> error
if $branch -> HTTP GET
if $file -> filesystem read

declare variable $base-url  := 'https://github.com/fgeorges/expath-ml-console/archive/';
declare variable $extension := '.zip';
declare variable $url       := $base-url || $branch || $extension;

(: TODO: Needs more logic to differentiate between local file, and HTTP get, which branch, etc. :)
let $zip   := xdmp:external-binary($file)
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

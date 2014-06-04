xquery version "3.0";

declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $matches :=
   <matches>
      <error match=".xq$"                    message="Not allowed to invoke modules directly"/>
      <match match="^/$"                     replace="/home.xq"/>
      <match match="^/appserver/([0-9]+)$"   replace="/appserver.xq?id=$1"/>
      <match match="^/appserver/([0-9]+)/init-repo$"          replace="/appserver/init-repo.xq?id=$1"/>
      <match match="^/appserver/([0-9]+)/delete-repo$"        replace="/appserver/delete-repo.xq?id=$1"/>
      <match match="^/appserver/([0-9]+)/install-pkg$"        replace="/appserver/install-pkg.xq?id=$1"/>
      <match match="^/appserver/([0-9]+)/install-cxan$"       replace="/appserver/install-cxan.xq?id=$1"/>
      <match match="^/appserver/([0-9]+)/pkg/([^/]+)/delete$" replace="/appserver/delete-pkg.xq?id=$1&amp;pkg=$2"/>
      <match match="^/db/([0-9]+)/browse$"     replace="/database/browse.xq?id=$1"/>
      <match match="^/db/([0-9]+)/browse(.+)$" replace="/database/browse.xq?id=$1&amp;path=$2"/>
      <match match="^/cxan$"                 replace="/cxan.xq"/>
      <match match="^/cxan/change$"          replace="/cxan/change.xq"/>
      <match match="^/cxan/install$"         replace="/cxan/install.xq"/>
      <match match="^/devel$"                replace="/devel.xq"/>
      <match match="^/help$"                 replace="/help.xq"/>
      <match match="^/(images|js|style)/.+$" replace="$0"/>
      <match match="^/pkg$"                  replace="/repo.xq"/>
      <match match="^/repo/create$"          replace="/repo/create.xq"/>
      <match match="^/repo/delete-pkg$"      replace="/repo/delete-pkg.xq"/>
      <match match="^/repo/delete$"          replace="/repo/delete.xq"/>
      <match match="^/repo/install-pkg$"     replace="/repo/install-pkg.xq"/>
      <match match="^/repo/show$"            replace="/repo/show.xq"/>
      <match match="^/tools$"                replace="/tools.xq"/>
      <match match="^/tools/config$"         replace="/tools/config.xq"/>
      <match match="^/tools/insert$"         replace="/tools/insert.xq"/>
      <match match="^/web$"                  replace="/web.xq"/>
      <match match="^/web/create$"           replace="/web/create.xq"/>
      <match match="^/web/delete$"           replace="/web/delete.xq"/>
      <match match="^/web/install-pkg$"      replace="/web/install-pkg.xq"/>
      <match match="^/web/select-repo$"      replace="/web/select-repo.xq"/>
      <match match="^/web/show$"             replace="/web/show.xq"/>
      <match match="^/xproject$"             replace="/xproject.xq"/>
      <match match="^/xspec$"                replace="/xspec.xq"/>
   </matches>;

declare function local:replace($url as xs:string, $matches as element()*)
   as xs:string
{
   if ( fn:empty($matches) ) then
      $url
   else if ( fn:matches($url, $matches[1]/@match) ) then
      if ( $matches[1] instance of element(error) ) then
         fn:error((), $matches[1]/@message || '($url: ' || $url || ')')
      else
         fn:replace($url, $matches[1]/@match, $matches[1]/@replace)
   else
      local:replace($url, fn:remove($matches, 1))
};

local:replace(
   xdmp:get-request-url(),
   $matches/*)

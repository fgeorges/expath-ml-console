xquery version "3.0";

declare namespace http = "xdmp:http";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $config :=
   <config>
      <user name="admin" password="admin"/>
   </config>;

declare variable $base-url := 'http://localhost:8002/manage/v2/';

declare function local:options() as element()
{
   let $user := $config/user/xs:string(@name)
   let $pwd  := $config/user/xs:string(@password)
   return
      <options xmlns="xdmp:http">
         <authentication method="digest">
            <username>{ $user }</username>
            <password>{ $pwd }</password>
         </authentication>
      </options>
};

declare function local:delete($url as xs:string)
   as empty-sequence()
{
   let $res := xdmp:http-delete($base-url || $url, local:options())
   return
      if ( $res[1]/xs:integer(http:code) = (202, 204) ) then
         ()
      else
         fn:error((), 'HTTP DELETE on <' || $url || '> - ' || xdmp:quote($res[1])
            || ' - ' || xdmp:quote($res[2]))
};

(:
Deleting the server provokes a restart.
Deleting databases first is not an option as they are attached to the server.
So needs to evaluate this script twice actually (delete the server, then the DBs).
:)
local:delete('servers/emlc?group-id=Default'),
local:delete('databases/emlc-content?forest-delete=data'),
local:delete('databases/emlc-modules?forest-delete=data')

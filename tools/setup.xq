xquery version "3.0";

declare namespace http = "xdmp:http";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace db   = "http://marklogic.com/manage/databases";
declare namespace srv  = "http://marklogic.com/manage/servers";
declare namespace fst  = "http://marklogic.com/manage/forests";
declare namespace hst  = "http://marklogic.com/manage/hosts";

declare variable $config :=
   <config>
      <user name="admin" password="admin"/>
      <content reuse="false" name="emlc-content" schema="Schemas" security="Security"/>
      <modules reuse="false" name="emlc-modules" schema="Schemas" security="Security"/>
      <appserver reuse="false" name="emlc" group="Default" port="8010"/>
   </config>;

declare variable $base-url := 'http://localhost:8002/manage/v2/';

declare variable $databases := local:databases();
declare variable $servers   := local:servers();
declare variable $forests   := local:forests();
declare variable $hosts     := local:hosts();

declare function local:options($data as element()?) as element()
{
   let $user := $config/user/xs:string(@name)
   let $pwd  := $config/user/xs:string(@password)
   let $auth :=
         <authentication method="digest" xmlns="xdmp:http">
            <username>{ $user }</username>
            <password>{ $pwd }</password>
         </authentication>
   return
      if ( fn:exists($data) ) then
         <options xmlns="xdmp:http">
            { $auth }
            <data>{ xdmp:quote($data) }</data>
            <headers>
               <content-type>application/xml</content-type>
            </headers>
         </options>
      else
         <options xmlns="xdmp:http">
            { $auth }
         </options>
};

declare function local:get($url as xs:string, $code as xs:integer)
   as document-node()
{
   let $res := xdmp:http-get($base-url || $url, local:options(()))
   return
      if ( $res[1]/xs:integer(http:code) eq $code ) then
         $res[2]
      else
         fn:error((), 'HTTP GET on <' || $url || '> - ' || xdmp:quote($res[1])
            || ' - ' || xdmp:quote($res[2]))
};

declare function local:post($url as xs:string, $code as xs:integer, $data as element())
   as document-node()?
{
   let $res := xdmp:http-post($base-url || $url, local:options($data))
   return
      if ( $res[1]/xs:integer(http:code) eq $code ) then
         $res[2]
      else
         fn:error((), 'HTTP POST on <' || $url || '> - ' || xdmp:quote($data)
            || xdmp:quote($res[1]) || ' - ' || xdmp:quote($res[2]))
};

declare function local:databases()
   as element(db:list-item)+
{
   local:get('databases?format=xml', 200)
      / db:database-default-list/db:list-items/db:list-item
};

declare function local:servers()
   as element(srv:list-item)+
{
   local:get('servers?format=xml', 200)
      / srv:server-default-list/srv:list-items/srv:list-item
};

declare function local:forests()
   as element(fst:list-item)+
{
   local:get('forests?format=xml', 200)
      / fst:forest-default-list/fst:list-items/fst:list-item
};

declare function local:hosts()
   as element(hst:list-item)+
{
   local:get('hosts?format=xml', 200)
      / hst:host-default-list/hst:list-items/hst:list-item
};

declare function local:ensure-schemurity($db as element())
   as empty-sequence()
{
   if ( fn:empty($databases[db:nameref eq $db/@schema]) ) then
      fn:error((), 'Schema DB does not exist for ' || $db/@name || ': ' || $db/@schema)
   else if ( fn:empty($databases[db:nameref eq $db/@security]) ) then
      fn:error((), 'Security DB does not exist for ' || $db/@name || ': ' || $db/@security)
   else
      ()
};

declare function local:compile-db($db as element())
   as element()*
{
   let $exists := fn:exists($databases[db:nameref eq $db/@name])
   return
      if ( $exists and fn:not(xs:boolean($db/@reuse)) ) then
         fn:error((), 'Database exists but cannot be reused: ' || $db/@name)
      else if ( $exists ) then
         ()
      else
         <db schema="{ $db/@schema }" security="{ $db/@security }" name="{ $db/@name }"> {
            for $h at $pos in $hosts
            let $f := $db/@name || '-' || fn:format-number($pos, '000')
            return
               if ( fn:exists($forests[fst:nameref eq $f]) ) then
                  fn:error((), 'Database needs to be created, but forest already exists: '
                     || $db/@name || ' - ' || $f)
               else
                  <forest host="{ $h/hst:nameref }">{ $f }</forest>
         }
         </db>
};

declare function local:compile-srv($srv as element())
   as element()?
{
   let $exists := fn:exists($servers[srv:nameref eq $srv/@name][srv:groupnameref eq $srv/@group])
   (: TODO: Check whether the port number is already used... :)
   (: See http://marklogic.markmail.org/thread/pfzt43jeqzmijmo6. :)
   (:
   let $bound  := $servers[xs:integer(srv:port) eq xs:integer($srv/@port)]/xs:string(srv:nameref)
   :)
   return
      if ( $exists and fn:not(xs:boolean($srv/@reuse)) ) then
         fn:error((), 'App server exists but cannot be reused: ' || $srv/@name)
      (:
      else if ( $bound != $srv/@name ) then
         fn:error((), 'Port ' || $srv/@port || ' already bound to: ' || $bound)
      :)
      else if ( $exists ) then
         ()
      else
         <srv>{ $srv/(@group, @port) }{ xs:string($srv/@name) }</srv>
};

declare function local:create($what as element()*)
   as element()+
{
   if ( fn:empty($what) ) then
      <setup>Nothing to create.</setup>
   else
      for $w in $what
      return
         switch ( fn:node-name($w) )
            case xs:QName('db')  return local:create-db($w)
            case xs:QName('srv') return local:create-srv($w)
            default return
               fn:error((), 'Internal error, unknown creation: ' || xdmp:quote($w))
};

declare function local:create-db($db as element(db))
   as element(created)+
{
   for $f in $db/forest
   return (
      local:post('forests?format=xml', 201,
         <forest-properties xmlns="http://marklogic.com/manage">
            <forest-name>{ xs:string($f) }</forest-name>
            <host>{ xs:string($f/@host) }</host>
         </forest-properties>)/*,
      <created>Forest { xs:string($f) }</created>
   ),
   (: TODO: Set schema and security databases... :)
   local:post('databases?format=xml', 201,
      <database-properties xmlns="http://marklogic.com/manage">
         <database-name>{ xs:string($db/@name) }</database-name>
         <forests> {
            $db/*:forest ! <forest>{ xs:string(.) }</forest>
         }
         </forests>
      </database-properties>)/*,
   <created>Database { xs:string($db/@name) }</created>
};

declare function local:create-srv($srv as element(srv))
   as element(created)+
{
   let $content := xs:string($config/content/@name)
   let $modules := xs:string($config/modules/@name)
   return
      local:post('servers?format=xml', 201,
         <http-server-properties xmlns="http://marklogic.com/manage">
            <server-name>{ xs:string($srv) }</server-name>
            <group-name>{ xs:string($srv/@group) }</group-name>
            <server-type>http</server-type>
            <root>/</root>
            <port>{ xs:string($srv/@port) }</port>
            <content-database>{ $content }</content-database>
            <modules-database>{ $modules }</modules-database>
            <url-rewriter>/plumbing/rewriter.xml</url-rewriter>
         </http-server-properties>)/*,
   <created>App server { xs:string($srv) }</created>
};

local:ensure-schemurity($config/content),
local:ensure-schemurity($config/modules),
local:create((
   local:compile-db($config/content),
   local:compile-db($config/modules),
   local:compile-srv($config/appserver)
))

(:
   load modules...
:)

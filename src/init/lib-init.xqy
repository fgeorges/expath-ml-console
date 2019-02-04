xquery version "3.0";

module namespace init = "http://expath.org/ns/ml/console/init";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare variable $init:base-uri      := 'http://expath.org/ml/console/';
declare variable $init:config-uri    := $init:base-uri || 'config.xml';

declare function init:get-config() as element(c:config)
{
   init:get-config-no-check()
};

declare function init:get-config-no-check() as element(c:config)?
{
   fn:doc($init:config-uri)/*
};

declare function init:is-init() as xs:boolean
{
   let $cfg := init:get-config-no-check()/c:initialized
   return
      fn:exists($cfg)
      and $cfg/@status eq 'success'
      and $cfg/@on eq xdmp:version()
};

declare function init:make-config() as element(c:config)
{
   <config xmlns="http://expath.org/ns/ml/console">
      <initialized status="success" on="{ xdmp:version() }"/>
   </config>
};

xquery version "3.0";

import module namespace t    = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";
import module namespace v    = "http://expath.org/ns/ml/console/view"  at "../lib/view.xqy";
import module namespace init = "http://expath.org/ns/ml/console/init"  at "lib-init.xqy";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:not-inited()
   as element()+
{
   <p>The Console has not been initialized yet.</p>,
   <p>Click on "Init" to initialize it.</p>
};

declare function local:init-failed()
   as element()+
{
   <p>The Console initialization has previously failed.</p>,
   <p>Click on "Init" to re-initialize it.  This might override any existing
      configuration.</p>
};

declare function local:outdated-init()
   as element()+
{
   <p>The Console configuration is potentially outdated.  It has been initialized
      with an older version of MarkLogic.</p>,
   <p>Click on "Init" to re-initialize it.  This might override any existing
      configuration.</p>
};

declare function local:inited()
   as element()+
{
   <p>The Console has already been successfully initialized.</p>,
   <p>Click on "Init" to re-initialize it.  This might override any existing
      configuration.</p>
};

declare function local:page()
   as element()+
{
   <wrapper> {
      let $cfg := init:get-config-no-check()/c:initialized
      return
         if ( fn:empty($cfg) or $cfg/@status eq 'none' ) then
            local:not-inited()
         else if ( $cfg/@status eq 'failure' ) then
            local:init-failed()
         else if ( $cfg/@status eq 'success' and fn:not($cfg/@on eq xdmp:version()) ) then
            local:outdated-init()
         else if ( $cfg/@status eq 'success' ) then
            local:inited()
         else
            t:error('unknown-value', 'Invalid initialization status: ' || $cfg/@status),
      v:one-button-form('init', 'Init', v:input-hidden('doinit', 'true'))
   }
   </wrapper>/*
};

v:console-page-no-check('', 'init', 'Initialization', local:page#0, ())

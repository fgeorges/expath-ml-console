xquery version "3.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
   if ( cfg:is-setup() ) then
      <wrapper>
         <p>Configure the CXAN website to talk to, for instance http://cxan.org/
            or http://test.cxan.org/.</p>
         {
            let $site := cfg:get-cxan-site()
            return
               if ( fn:empty($site) ) then
                  <p><em>No repo has been created yet, please proceed first.</em></p>
               else
                  <form method="post" action="cxan/change" enctype="multipart/form-data">
                     <span>The CXAN website: </span>
                     <input type="text" name="site" size="50" value="{ $site }"/>
                     <input name="set-site" type="submit" value="Set"/>
                  </form>
         }
      </wrapper>/*
   else
      <p>The console has not been set up yet, please
         <a href="repo.xq">create a repo</a> first.</p>
};

v:console-page('', 'cxan', 'CXAN', local:page#0)

xquery version "3.0";

(:~
 : Provides XSpec-related tools.
 :)

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
   <p><b>TODO</b>: Provide XSpec-related tools, in particular running test
      suites, generating reports, etc.</p>
};

v:console-page('', 'xspec', 'XSpec', local:page#0)

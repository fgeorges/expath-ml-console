xquery version "1.0";

(:~
 : Provides XSpec-related tools.
 :)

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

v:console-page(
   'xspec',
   'XSpec',
   <p><b>TODO</b>: Provide XSpec-related tools, in particular running test
      suites, generating reports, etc.</p>)

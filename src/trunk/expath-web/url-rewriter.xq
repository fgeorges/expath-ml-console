xquery version "3.0";

import module namespace d = "http://expath.org/ns/ml/webapp/dispatcher"
  at "dispatcher.xql";

declare namespace xdmp = "http://marklogic.com/xdmp";

( d:dispatch(), xdmp:get-request-url() )[1]

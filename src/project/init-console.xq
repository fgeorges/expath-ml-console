xquery version "3.0";

import module namespace proj = "http://expath.org/ns/ml/console/project" at "proj-lib.xql";
import module namespace v    = "http://expath.org/ns/ml/console/view"    at "../lib/view.xql";

proj:init-console(),
v:redirect('../../project')

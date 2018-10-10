xquery version "3.1";

(:~
 : Display all created jobs.
 :)

import module namespace ui  = "http://expath.org/ns/ml/console/job/ui"  at "./job-ui-lib.xqy";
import module namespace job = "http://expath.org/ns/ml/console/job/lib" at "../../job/job-lib.xqy";
import module namespace v   = "http://expath.org/ns/ml/console/view"    at "../../lib/view.xqy";

v:console-page('../', 'job', 'Jobs', function() {
   ui:status-page(
      job:jobs-created(),
      job:count-jobs-created())
})

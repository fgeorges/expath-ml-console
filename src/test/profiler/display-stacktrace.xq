xquery version "3.0";

(:~
 : The profiler page.
 :)

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../../lib/admin.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare variable $script :=
   <script type="text/javascript">
      $(document).ready(function () {{
         $.ajax({{
            url: 'throws-error',
            method: 'GET',
            dataType: 'json',
            success: function(data) {{
               var pretty = JSON.stringify(data, null, 3);
               editorSetContent('raw-json', pretty);
               displayStackTrace(data, $('#stacktrace'));
            }},
            error: function(xhr, status, error) {{
               alert('Error: ' + status + ' (' + error + ')\n\nBody: ' + xhr.responseText);
            }}}});
      }});
   </script>;

(:~
 : The overall page function.
 :)
declare function local:page()
   as element()+
{
   <wrapper>
      <p>The goal is to write the stacktrace into <code>#stacktrace</code>:</p>
      <h3>Stacktrace</h3>
      <div id="stacktrace"/>
      <h3>Raw JSON</h3>
      { v:edit-text(text { '' }, 'json', 'raw-json') }
   </wrapper>/*
};

v:console-page('../../', 'test', 'Profiler test - Display stacktrace', local:page#0, $script)

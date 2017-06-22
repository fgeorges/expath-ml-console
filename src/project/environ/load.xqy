xquery version "3.0";

(: TODO: Factorize this script with show.xqy. :)

module namespace this = "http://expath.org/ns/ml/console/environ/setup";

import module namespace t = "http://expath.org/ns/ml/console/tools" at "../../lib/tools.xqy";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace json = "http://marklogic.com/xdmp/json";
declare namespace map  = "http://marklogic.com/xdmp/map";

declare function this:error(
   $environ as xs:string,
   $project as xs:string,
   $err     as item((: map:map :))
)
{
   v:console-page('../../../../', 'project', 'Environ ' || $environ, function() {
      let $code  := map:get($err, 'name')
      let $data  := map:get($err, 'data')
      let $msg   := map:get($err, 'message')
      let $stack := map:get($err, 'stack')
      return
         if ( $code eq 'SVC-SOCHN' ) then (
            <p><b>Error</b>: Unknown host: <code>{ json:array-values($data)[2] }</code>.</p>,
            <p>Check your environment file.</p>
         )
         (: TODO: Base the comparison on $code, not on $msg, once a proper error is thrown. :)
         else if ( $msg eq 'No host in space' ) then (
            <p><b>Error</b>: No host defined in the environment.</p>,
            <p>Where do you want to setup?  Check your environment file.</p>
         )
         else if ( $msg ) then (
            <p><b>Error</b>: Unknown error: { $msg }.</p>,
            <p>Please report this as an
               <a href="https://github.com/fgeorges/expath-ml-console">issue on Githib</a>.</p>,
            <pre>{ $stack }</pre>
         )
         else (
            <p><b>Error</b>: Unknown error (code: { $code }).</p>,
            <p>Please report this as an
               <a href="https://github.com/fgeorges/expath-ml-console">issue on Githib</a>.</p>,
            <pre>{ xdmp:quote($err) }</pre>
         )
   })
};

declare variable $this:action-props :=
   ('type', 'msg', 'api', 'url', 'verb', 'data', 'json');

declare variable $this:actions :=
   <actions xmlns="">
      <action type="ForestCreate"   icon="tree-conifer"/>
      <action type="ForesAttach"    icon="tree-conifer"/>
      <action type="ForestDetach"   icon="tree-conifer"/>
      <action type="DatabaseCreate" icon="floppy-disk"/>
      <action type="DatabaseUpdate" icon="floppy-disk"/>
      <action type="ServerCreate"   icon="hdd"/>
      <action type="ServerUpdate"   icon="hdd"/>
      <action type="DocInsert"      icon="file"/>
   </actions>;

declare function this:action($action as item((: map:map :))) as element()
{
   let $type := map:get($action, 'type')
   let $msg  := map:get($action, 'msg')
   let $def  := $this:actions/*[@type eq $type]
   return
      if ( fn:empty($def) ) then
         t:error('invalid-param', 'Unknown action type: ' || $type)
      else
         <p class="mlproj-todo"> {
            $this:action-props ! attribute { 'data-' || . } { map:get($action, .) },
            <span class="glyphicon glyphicon-{ $def/@icon }" aria-hidden="true"/>,
            ' ',
            $msg
         }
         </p>
};

declare function this:page(
   $environ as xs:string,
   $project as xs:string,
   $actions as item((: json:array :))
)
{
   v:console-page('../../../../', 'project', 'Environ ' || $environ, function() {
      <p>Setup the environment <code>{ $environ }</code>, in project
	 { v:proj-link('../../../' || $project, $project) }.</p>,
      let $seq := json:array-values($actions)
      return
         if ( fn:empty($seq) ) then (
	    <div id="summary" class="alert alert-success" role="alert">
	       Nothing to load.
	    </div>
         )
         else (
	    <p>Actions to be performed</p>,
	    json:array-values($actions) ! this:action(.),
	    <div id="summary" class="alert alert-info" role="alert">
	       Click on "Execute" to start loading.
	    </div>,
	    <button id="doit" type="button" class="btn btn-default">Execute</button>
         )
   },
   (<script>
      function execAction() {{
         var action = $(this);
         action
            .toggleClass('mlproj-todo mlproj-running')
            .children('span')
            .css('color', 'blue');
         var datas  = [ { fn:string-join($this:action-props ! ("'" || . || "'"), ', ') } ];
         var params = {{}};
         datas.forEach(function(name) {{
            // do not use action.data() as it parses lexical JSON automatically
            params[name] = action.attr('data-' + name);
         }});
         $.post('action/' + action.data('type'), params)
            .done(function(data) {{
               action
                  .toggleClass('mlproj-running mlproj-done')
                  .children('span')
                  .css('color', 'green');
               execNextAction();
            }})
            .fail(function(data) {{
               action
                  .toggleClass('mlproj-running mlproj-error')
                  .children('span')
                  .css('color', 'red');
               $('.mlproj-todo')
                  .toggleClass('mlproj-todo mlproj-ignored')
                  .children('span')
                  .css('color', 'orange');
               if ( data.responseJSON ) {{
                  $('#summary')
                     .toggleClass('alert-info alert-danger')
                     .text(data.responseJSON.error.message);
               }}
               else {{
                  $('#summary')
                     .toggleClass('alert-info alert-danger')
                     .text('Request interrupted with no response.'
                        + ' Maybe due to a MarkLogic restart?'
                        + ' Try to reload the page, or report the error.');
               }}
            }});
      }}
      function execNextAction() {{
         var todos = $('.mlproj-todo');
         if ( todos.length ) {{
            todos.first().each(execAction);
         }}
         else {{
            $('#summary')
               .toggleClass('alert-info alert-success')
               .text('Setup is complete.');
         }}
      }}
   </script>,
   <script>
      $(document).ready(function() {{
         $('#doit').click(function() {{
            $('#summary').text('Running the actions...');
            $(this).prop('disabled', true);
            execNextAction();
         }});
      }});
   </script>))
};

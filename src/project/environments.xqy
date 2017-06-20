xquery version "3.0";

module namespace env = "http://expath.org/ns/ml/console/environments";

import module namespace v = "http://expath.org/ns/ml/console/view" at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace json = "http://marklogic.com/xdmp/json";

declare function env:page(
   $project as xs:string,
   $envs    as item((: json:array :))
)
{
   v:console-page('../../', 'project', 'Environments', function() {
      <p>The project { v:proj-link('../' || $project, $project) } get the following
         environments defined.</p>,
      <p>You can perform project actions on specific environments.  For instance:
         deploy code on the production environment, test the codebase on your
         development environment, load data on the test environment, etc.</p>,
      <form> {
         for $env   in json:array-values($envs)
         let $name  := map:get($env, 'name')
         let $title := map:get($env, 'title')
         let $label := if ( $title ) then $name || ' - ' || $title else $name
         order by $name
         return
            v:input-radio('environs', 'env.' || $name, $name, $label)
      }
      </form>,
      <p>Select above the environment to act upon, in the action forms below.</p>,
      <h3>Show</h3>,
      <p>Show the details of an environment, with all imports resolved.</p>,
      v:form('to/be/set', attribute { 'data-action-template' } { 'environ/{env}/show' }, (
         v:input-text('environ', 'Environment', '<to be replaced>', (),
                      attribute { 'disabled' } { 'disabled' }),
         v:submit('Show'))),
      <h3>Setup</h3>,
      <p>Setup or update all components in an environment (its databases, servers, etc.)</p>,
      v:form('to/be/set', attribute { 'data-action-template' } { 'environ/{env}/setup' }, (
         v:input-text('environ', 'Environment', '<to be replaced>', (),
                      attribute { 'disabled' } { 'disabled' }),
         v:submit('Setup')))
   },
   (<script>
      function updateContextEnviron() {{
         if ( $(this).is(':checked') ) {{
            var env = $(this).val();
            $('input[name="environ"]').val(env);
            $('form').each(function() {{
               var template = $(this).data('action-template');
               if ( template ) {{
                  var action = template.replace('{{env}}', env);
                  $(this).attr('action', action);
               }}
            }});
            // TODO: Retrieve environ values and update dropdown lists (when it
            // will be necessary...)
         }}
      }}
   </script>,
   <script>
      $(document).ready(function() {{
         $('input[name="environs"]')
            .change(updateContextEnviron)
            .first()
            .prop("checked", true)
            .trigger('change');
      }});
   </script>))
};

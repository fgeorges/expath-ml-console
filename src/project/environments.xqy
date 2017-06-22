xquery version "3.0";

module namespace env = "http://expath.org/ns/ml/console/environments";

import module namespace v = "http://expath.org/ns/ml/console/view" at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace json = "http://marklogic.com/xdmp/json";

declare function env:input-select-text(
   $id            as xs:string,
   $label         as xs:string,
   $placeholder-1 as xs:string,
   $placeholder-2 as xs:string,
   $options       as element(h:option)*
) as element(h:div)+
{
   <div class="form-group">
      <label for="{ $id }-path" class="col-sm-2 control-label">{ $label }</label>
      <div class="col-sm-10">
         <div class="input-group">
            <!-- TODO: When source sets supported, only one of both is required... -->
            <input type="text" id="{ $id }-path" name="{ $id }-path" class="form-control"
                   placeholder="{ $placeholder-1 }" required="required"/>
            <span class="input-group-addon">
               <input type="radio" id="{ $id }-path-check"/>
            </span>
         </div>
      </div>
   </div>,
   <div class="form-group">
      { if ( fn:empty($options) ) then attribute { 'hidden' } { 'hidden' } else () }
      <label for="{ $id }-srcdir" class="col-sm-2 control-label"/>
      <div class="col-sm-10">
         <div class="input-group">
            <select id="{ $id }-srcdir" name="{ $id }-srcdir" class="form-control">
               <option value="" disabled="disabled" selected="selected" hidden="hidden">
                  { $placeholder-2 }
               </option>
               { $options }
            </select>
            <span class="input-group-addon">
               <input type="radio" id="{ $id }-srcdir-check"/>
            </span>
         </div>
      </div>
   </div>
};

declare function env:page(
   $project as xs:string,
   $envs    as item((: json:array :)),
   $details as xs:string
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
         v:submit('Setup'))),
      <h3>Load</h3>,
      <p>Load documents from a source (a source dir, a directory or a file) to a database
         (you can select a server as well to load to its content database):</p>,
      v:form('to/be/set', attribute { 'data-action-template' } { 'environ/{env}/load' }, (
         v:input-text('environ', 'Environment', '<to be replaced>', (),
                      attribute { 'disabled' } { 'disabled' }),
         env:input-select-text('source', 'Source',
            'Path to directory or file, relative to project dir...',
            '...or select a source directory',
            ((: TODO: Add source sets once supported... :))),
         v:input-select('target', 'Target', (
            v:input-optgroup('Databases',       ((: set dynamically by JavaScript... :))),
            v:input-optgroup('Servers',         ((: ...code, depending on the... :))),
            v:input-optgroup('Other databases', ((: ...selected environment :)))
         )),
         v:submit('Load')))
   },
   (<script>
      var details = JSON.parse('{ $details }');

      function defaultContentDb(detail) {{
         // if exactly 1 server, it is its content db
         if ( detail.servers.length === 1 ) {{
            return detail.servers[0].content;
         }}
         // if exactly 1 db, it is
         else if ( detail.databases.length === 1 ) {{
            return detail.databases[0].name;
         }}
         else {{
            // error, not exactly 1 server or database, just return nothing
            return;
         }}
      }}

      function updateContextEnviron() {{
         if ( $(this).is(':checked') ) {{

            // the environ name
            var env = $(this).val();

            // set the environ on all environ (read-only) fields
            $('input[name="environ"]').val(env);
            // inject it in all form endpoints template
            $('form').each(function() {{
               var template = $(this).data('action-template');
               if ( template ) {{
                  var action = template.replace('{{env}}', env);
                  $(this).attr('action', action);
               }}
            }});

            // the current environ detail
            var detail = details[env];
            // the default database to select
            var defaultDb = defaultContentDb(detail);

            // set the target dropdown lists...
            // ...the project databases
            var dbs = $('select[name="target"] optgroup').eq(0);
            dbs.children().remove();
            detail.databases.forEach(function(db) {{
               var opt = $('<option />', {{
                  text  : db.name,
                  value : 'db:' + db.name
               }});
               dbs.append(opt);
               if ( db.name === defaultDb ) {{
                  opt.select();
               }}
            }});
            // ...the project servers
            var srvs = $('select[name="target"] optgroup').eq(1);
            srvs.children().remove();
            detail.servers.forEach(function(srv) {{
               srvs.append($('<option />', {{
                  text  : srv.name + ' (content db: ' + srv.content + ')',
                  // TODO: Put the content db instead, so we always send a db?
                  value : 'srv:' + srv.name
               }}));
            }});
            // ...all other databases
            var alldbs = $('select[name="target"] optgroup').eq(2);
            alldbs.children().remove();
            details['@all-dbs'].sort().forEach(function(db) {{
               alldbs.append($('<option />', {{
                  text  : db,
                  value : 'other:' + db
               }}));
            }});
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
         // make these 2 radio buttons mutually exclusive
         $('#source-path-check').change(function() {{
            if ( $(this).val() === 'on' ) {{
               $('#source-path').focus();
               $('#source-srcdir-check').prop('checked', false);
            }}
         }});
         $('#source-srcdir-check').change(function() {{
            if ( $(this).val() === 'on' ) {{
               $('#source-srcdir').focus();
               $('#source-path-check').prop('checked', false);
            }}
         }});
         // when a field has focus, select its corresponding radio button
         $('#source-path').focus(function() {{
            $('#source-path-check').prop('checked', true);
            $('#source-srcdir-check').prop('checked', false);
         }});
         $('#source-srcdir').focus(function() {{
            $('#source-path-check').prop('checked', false);
            $('#source-srcdir-check').prop('checked', true);
         }});
      }});
   </script>))
};

xquery version "3.0";

module namespace env = "http://expath.org/ns/ml/console/environments";

import module namespace v = "http://expath.org/ns/ml/console/view" at "../lib/view.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace json = "http://marklogic.com/xdmp/json";

declare function env:input-select-text(
   $id            as xs:string,
   $label         as xs:string,
   $placeholder-1 as xs:string,
   $default       as xs:string,
   $placeholder-2 as xs:string,
   $options       as element(h:option)*
) as element(h:div)+
{
   <div class="exclusive">
      <div class="form-group row">
         <label for="{ $id }-path" class="col-sm-2 col-form-label">{ $label }</label>
         <div class="col-sm-10">
            <div class="input-group">
               <!-- TODO: When source sets supported, only one of both is required... -->
               <input type="text" name="{ $id }-path" class="form-control excl-first"
                      placeholder="{ $placeholder-1 }" required="required" value="{ $default }"/>
               <div class="input-group-append">
                  <div class="input-group-text">
                     <input type="radio" name="{ $id }-path-check" class="excl-first-check" checked="checked"/>
                  </div>
               </div>
            </div>
         </div>
      </div>
      <div class="form-group row">
         { ((: if ( fn:empty($options) ) then attribute { 'hidden' } { 'hidden' } else () :)) }
         <label for="{ $id }-srcset" class="col-sm-2 col-form-label"/>
         <div class="col-sm-10">
            <div class="input-group">
               <select id="{ $id }-srcset" name="{ $id }-srcset" class="form-control excl-second">
                  <option value="" disabled="disabled" selected="selected" hidden="hidden">
                     { $placeholder-2 }
                  </option>
                  { $options }
               </select>
               <div class="input-group-append">
                  <div class="input-group-text">
                     <input type="radio" name="{ $id }-srcset-check" class="excl-second-check"/>
                  </div>
               </div>
            </div>
         </div>
      </div>
   </div>
};

declare function env:page(
   $project as xs:string,
   $envs    as item((: json:array :)),
   $details as xs:string
) as document-node()
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
      <h3 class="lfam-error" style="display: none">Error</h3>,
      <pre class="lfam-error" style="display: none" id="lfam-error-msg"></pre>,
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
      <p>Load documents from a source (a file set, a directory or a file) to a database
         (you can select a server as well to load to its content database):</p>,
      v:form('to/be/set', (
         attribute { 'data-action-template' } { 'environ/{env}/load' },
         attribute { 'data-load-type'       } { 'load' }
         ), (
         v:input-text('environ', 'Environment', '<to be replaced>', (),
                      attribute { 'disabled' } { 'disabled' }),
         env:input-select-text('source', 'Source',
            'Path to directory or file, relative to project dir...',
            'data/',
            '...or select a source set',
            ((: set dynamically by JavaScript code, depending on the selected environment :))),
         v:input-select('target', 'Target', (
            v:input-optgroup('Databases',       ((: set dynamically by JavaScript... :))),
            v:input-optgroup('Servers',         ((: ...code, depending on the... :))),
            v:input-optgroup('Other databases', ((: ...selected environment :)))
         )),
         v:submit('Load'))),
      <h3>Deploy</h3>,
      <p>Deploy sources (from a file set, a directory or a file) to a database
         (you can select a server as well to deploy to its modules database):</p>,
      v:form('to/be/set', (
         attribute { 'data-action-template' } { 'environ/{env}/deploy' },
         attribute { 'data-load-type'       } { 'deploy' }
         ), (
         v:input-text('environ', 'Environment', '<to be replaced>', (),
                      attribute { 'disabled' } { 'disabled' }),
         env:input-select-text('source', 'Source',
            'Path to directory or file, relative to project dir...',
            'src/',
            '...or select a source set',
            ((: set dynamically by JavaScript code, depending on the selected environment :))),
         v:input-select('target', 'Target', (
            v:input-optgroup('Databases',       ((: set dynamically by JavaScript... :))),
            v:input-optgroup('Servers',         ((: ...code, depending on the... :))),
            v:input-optgroup('Other databases', ((: ...selected environment :)))
         )),
         v:submit('Deploy')))
   },
   (<script>
      var details = JSON.parse('{ fn:replace($details, '\\n', '\\\\n') }');

      function defaultContentDb(detail) {{
         // if exactly 1 server, it is its content db
         if ( detail.servers.length === 1 ) {{
            return detail.servers[0].content;
         }}
         // if exactly 1 db, it is
         else if ( detail.databases.length === 1 ) {{
            return detail.databases[0].name;
         }}
         // return nothing if not exactly 1 server or database
      }}

      function defaultModulesDb(detail) {{
         // if exactly 1 server, it is its content db
         if ( detail.servers.length === 1 ) {{
            return detail.servers[0].modules;
         }}
         // return nothing if not exactly 1 server
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

               var type = $(this).data('load-type');
               if ( type ) {{
                  $('.lfam-error').hide();
                  // the current environ detail
                  var detail = details[env];
		  // any error to display?
		  if ( detail.err ) {{
		    let msg = detail.err;
		    if ( detail.err.stack ) {{
		      msg = detail.err.stack.replace(/\\\\n/g, '\n');
		    }}
		    $('#lfam-error-msg').text(msg);
		    $('.lfam-error').show();
		  }}
                  // the default source set to select
                  var defaultSrc = type === 'load' ? 'data' : 'src';
                  // the default database to select
                  var defaultDb  = type === 'load'
                     ? defaultContentDb(detail)
                     : defaultModulesDb(detail);

                  // set the source sets dropdown list
                  var srcs = $(this).find('select[name="source-srcset"]');
                  srcs.children().remove();
                  detail.sources.forEach(function(src) {{
                     var opt = $('<option />', {{
                        text  : src.name,
                        value : 'src:' + src.name
                     }});
                     srcs.append(opt);
                     if ( src.name === defaultSrc ) {{
                        // TODO: In this case, select this field (the radio button on its right)
                        opt.prop('selected', true);
                     }}
                  }});
                  var group = $(this).find('div.exclusive').find('div.form-group').eq(1);
                  if ( detail.sources.length ) {{
                     group.show();
		     $(this).find('.excl-first-check' ).prop('checked', false);
		     $(this).find('.excl-second-check').prop('checked', true);
                  }}
                  else {{
                     group.hide();
		     $(this).find('.excl-first-check' ).prop('checked', true);
		     $(this).find('.excl-second-check').prop('checked', false);
                  }}

                  // set the target dropdown lists...
                  // ...the project databases
                  var dbs = $(this).find('select[name="target"] optgroup').eq(0);
                  dbs.children().remove();
                  detail.databases.forEach(function(db) {{
                     var opt = $('<option />', {{
                        text  : db.name,
                        value : 'db:' + db.name
                     }});
                     dbs.append(opt);
                     if ( db.name === defaultDb ) {{
                        opt.prop('selected', true);
                     }}
                  }});

                  // ...the project servers
                  var srvs = $(this).find('select[name="target"] optgroup').eq(1);
                  srvs.children().remove();
                  detail.servers.forEach(function(srv) {{
                     srvs.append($('<option />', {{
                        text  : srv.name + ' (content db: ' + srv.content + ')',
                        // TODO: Put the content db instead, so we always send a db?
                        value : 'srv:' + srv.name
                     }}));
                  }});

                  // ...all other databases
                  var alldbs = $(this).find('select[name="target"] optgroup').eq(2);
                  alldbs.children().remove();
                  details['@all-dbs'].sort().forEach(function(db) {{
                     alldbs.append($('<option />', {{
                        text  : db,
                        value : 'other:' + db
                     }}));
                  }});
               }}

            }});

         }}
      }}

      function initExclusive() {{
         var widget = $(this);
         // make these 2 radio buttons mutually exclusive
         widget.find('.excl-first-check').change(function() {{
            if ( $(this).val() === 'on' ) {{
               widget.find('.excl-first').focus();
               widget.find('.excl-second-check').prop('checked', false);
            }}
         }});
         widget.find('.excl-second-check').change(function() {{
            if ( $(this).val() === 'on' ) {{
               widget.find('.excl-second').focus();
               widget.find('.excl-first-check').prop('checked', false);
            }}
         }});
         // when a field has focus, select its corresponding radio button
         widget.find('.excl-first').focus(function() {{
            widget.find('.excl-first-check').prop('checked', true);
            widget.find('.excl-second-check').prop('checked', false);
         }});
         widget.find('.excl-second').focus(function() {{
            widget.find('.excl-first-check').prop('checked', false);
            widget.find('.excl-second-check').prop('checked', true);
         }});
      }}
   </script>,
   <script>
      $(document).ready(function() {{
         // set change listener, and select first environ
         // TODO: Select the default environ instead of the first one...?
         $('input[name="environs"]')
            .change(updateContextEnviron)
            .first()
            .prop("checked", true)
            .trigger('change');
         // initialize the "exclusive" fields
         $('.exclusive')
            .each(initExclusive);
      }});
   </script>))
};

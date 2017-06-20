xquery version "3.0";

module namespace disp = "http://expath.org/ns/ml/console/mlproj/display";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h = "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace json = "http://marklogic.com/xdmp/json";

(: TODO: Support when $value is an attay... :)
declare function disp:property(
   $prop  as item((: map:map :)),
   $level as xs:integer
) as element(h:tr)
{
   let $value := map:get($prop, 'value')
   let $def   := map:get($prop, 'prop')
   let $label := map:get($def,  'label')
   return
      <tr>
	 <td>{ $label }</td>
	 <td>{ $value }</td>
      </tr>
};

declare function disp:database(
   $name     as xs:string,
   $id       as xs:string?,
   $schema   as xs:string?,
   $security as xs:string?,
   $triggers as xs:string?,
   $forests  as xs:string*,
   $props    as item((: map:map :))
) as element()+
{
   <h3><span class="glyphicon glyphicon-floppy-disk" aria-hidden="true"/>{ ' ' }{ $name }</h3>,
   <p>Database <code>{ $name }</code>.</p>,
   <table class="table table-striped">
      <thead>
	 <th>Name</th>
	 <th>Value</th>
      </thead>
      <tbody>
	   <tr><td>Name</td>        <td><code>{ $name       }</code></td></tr>
	 { <tr><td>ID</td>          <td><code>{ $id         }</code></td></tr>[$id]       }
	 { <tr><td>Schema DB</td>   <td>      { $schema     }       </td></tr>[$schema]   }
	 { <tr><td>Security DB</td> <td>      { $security   }       </td></tr>[$security] }
	 { <tr><td>Triggers DB</td> <td>      { $triggers   }       </td></tr>[$triggers] }
	 { <tr><td>Forests</td>     <td>      { $forests[1] }       </td></tr>[$forests]  }
         {
            fn:tail($forests) ! <tr><td/><td>{ . }</td></tr>,
            map:keys($props) ! disp:property(map:get($props, .), 1)
	 }
      </tbody>
   </table>
};

declare function disp:server(
   $name    as xs:string,
   $id      as xs:string?,
   $group   as xs:string,
   $content as xs:string?,
   $modules as xs:string?,
   $props   as item((: map:map :))
) as element()+
{
   <h3><span class="glyphicon glyphicon-hdd" aria-hidden="true"/>{ ' ' }{ $name }</h3>,
   <p>Server <code>{ $name }</code>.</p>,
   <table class="table table-striped">
      <thead>
	 <th>Name</th>
	 <th>Value</th>
      </thead>
      <tbody>
	   <tr><td>Name</td>       <td><code>{ $name    }</code></td></tr>
	   <tr><td>Group</td>      <td>      { $group   }       </td></tr>
	 { <tr><td>ID</td>         <td><code>{ $id      }</code></td></tr>[$id]      }
	 { <tr><td>Content DB</td> <td>      { $content }       </td></tr>[$content] }
	 { <tr><td>Modules DB</td> <td>      { $modules }       </td></tr>[$modules] }
         {
            map:keys($props) ! disp:property(map:get($props, .), 1)
	 }
      </tbody>
   </table>
};

declare function disp:project(
   $code    as xs:string,
   $configs as item((: map:map :)),
   $title   as xs:string?,
   $name    as xs:string?,
   $version as xs:string?
) as element()+
{
   <h3><span class="glyphicon glyphicon-briefcase" aria-hidden="true"/>{ ' ' }{ $code }</h3>,
   <p>Project <code>{ $code }</code>.</p>,
   <table class="table table-striped">
      <thead>
	 <th>Name</th>
	 <th>Value</th>
      </thead>
      <tbody>
	   <tr><td>Code</td>    <td><code>{ $code    }</code></td></tr>
	 { <tr><td>Title</td>   <td>      { $title   }       </td></tr>[$title]   }
	 { <tr><td>Name</td>    <td>      { $name    }       </td></tr>[$name]    }
	 { <tr><td>Version</td> <td>      { $version }       </td></tr>[$version] }
      </tbody>
   </table>,
   (: TODO: Factorize out with environ parameters display... :)
   let $seq := json:array-values($configs)
   return
      if ( fn:exists($seq) ) then
	 <table class="table table-striped">
	    <thead>
	       <th>Config</th>
	       <th>Value</th>
	    </thead>
	    <tbody> {
               $seq ! <tr>
                  <td>{ map:get(., 'name')  }</td>
                  <td>{ map:get(., 'value') }</td>
               </tr>
            }
	    </tbody>
	 </table>
      else
         ()
};

declare function disp:environ(
   $envipath as xs:string,
   $title    as xs:string?,
   $desc     as xs:string?,
   $host     as xs:string?,
   $user     as xs:string?,
   $password as xs:string?,
   $srcdir   as xs:string?,
   $mods     as xs:string?,
   $params   as item((: json:array :)),
   $imports  as item((: json:array :))
) as element()+
{
   <h3><span class="glyphicon glyphicon-globe" aria-hidden="true"/>{ ' ' }{ $envipath }</h3>,
   <p>Environment <code>{ $envipath }</code>.</p>,
   <table class="table table-striped">
      <thead>
	 <th>Name</th>
	 <th>Value</th>
      </thead>
      <tbody>
	   <tr><td>Name or path</td> <td><code>{ $envipath }</code></td></tr>
	 { <tr><td>Title</td>        <td>      { $title    }       </td></tr>[$title]    }
	 { <tr><td>Description</td>  <td>      { $desc     }       </td></tr>[$desc]     }
	 { <tr><td>Host</td>         <td><code>{ $host     }</code></td></tr>[$host]     }
	 { <tr><td>User</td>         <td><code>{ $user     }</code></td></tr>[$user]     }
	 { <tr><td>Password</td>     <td>*****</td>                     </tr>[$password] }
	 { <tr><td>Sources dir</td>  <td><code>{ $srcdir   }</code></td></tr>[$srcdir]   }
	 { <tr><td>Modules DB</td>   <td><code>{ $mods     }</code></td></tr>[$mods]     }
      </tbody>
   </table>,
   let $seq := json:array-values($params)
   return
      if ( fn:exists($seq) ) then
	 <table class="table table-striped">
	    <thead>
	       <th>Parameter</th>
	       <th>Value</th>
	    </thead>
	    <tbody> {
               $seq ! <tr>
                  <td>{ map:get(., 'name')  }</td>
                  <td>{ map:get(., 'value') }</td>
               </tr>
            }
	    </tbody>
	 </table>
      else
         (),
   let $seq := json:array-values($imports)
   return
      if ( fn:exists($seq) ) then (
         <p>Imports:</p>,
         <pre>
            { $envipath }
            { $seq ! ('&#10;' || disp:indent(map:get(., 'level') - 1) || '-> ' || map:get(., 'href')) }
         </pre>
      )
      else (
      )
};

declare function disp:indent($level as xs:integer) as xs:string
{
   fn:string-join((1 to $level) ! '   ', '')
};

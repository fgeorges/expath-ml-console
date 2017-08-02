xquery version "3.0";

module namespace disp = "http://expath.org/ns/ml/console/mlproj/display";

import module namespace bin = "http://expath.org/ns/ml/console/binary" at "../../lib/binary.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h = "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";
declare namespace map  = "http://marklogic.com/xdmp/map";
declare namespace json = "http://marklogic.com/xdmp/json";

declare function disp:code($code as xs:string) as element()+
{
   <pre>{ $code }</pre>
};

declare function disp:to-implement($msg as xs:string) as element()+
{
   <p>TO IMPLEMENT: { $msg }</p>
};

declare function disp:check(
   $indent as xs:integer,
   $msg    as xs:string,
   $arg    as xs:string?
) as element()+
{
   <p>TODO: disp:check - { $indent } - { $msg } - { $arg }</p>
};

declare function disp:add(
   $indent as xs:integer,
   $verb   as xs:string,
   $msg    as xs:string,
   $arg    as xs:string?
) as element()+
{
   <p>TODO: disp:add - { $indent } - { $verb } - { $msg } - { $arg }</p>
};

declare function disp:remove(
   $indent as xs:integer,
   $verb   as xs:string,
   $msg    as xs:string,
   $arg    as xs:string?
) as element()+
{
   <p>TODO: disp:remove - { $indent } - { $verb } - { $msg } - { $arg }</p>
};

declare function disp:property($prop as item((: map:map :))) as element(h:tr)
{
   disp:property($prop, 1)
};

(: TODO: Use sub-tables instead of $level...? :)
declare function disp:property(
   $prop  as item((: map:map :)),
   $level as xs:integer
) as element(h:tr)+
{
   let $value := map:get($prop, 'value')
   let $def   := map:get($prop, 'prop')
   let $label := map:get($def,  'label')
   return
      if ( bin:is-json-array($value) ) then
         let $vals := json:array-values($value)
         return
            if ( bin:is-json-object($vals[1]) ) then
               for $v in $vals
               return (
                  <tr>
                     <td>{ fn:string-join((1 to (($level - 1) * 8)) ! '&#160;', '') }{ $label }</td>
                     <td/>
                  </tr>,
                  map:keys($v) ! disp:property(map:get($v, .), $level + 1)
               )
            else
               <tr>
                  <td>{ fn:string-join((1 to (($level - 1) * 8)) ! '&#160;', '') }{ $label }</td>
                  <td>{ $vals ! (., <br/>) }</td>
               </tr>
      else
         <tr>
            <td>{ fn:string-join((1 to (($level - 1) * 8)) ! '&#160;', '') }{ $label }</td>
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
            map:keys($props) ! disp:property(map:get($props, .))
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
            map:keys($props) ! disp:property(map:get($props, .))
	 }
      </tbody>
   </table>
};

declare function disp:source(
   $name  as xs:string,
   $props as item((: map:map :))
) as element()+
{
   <h3><span class="glyphicon glyphicon-inbox" aria-hidden="true"/>{ ' ' }{ $name }</h3>,
   <p>Source set <code>{ $name }</code>.</p>,
   <table class="table table-striped">
      <thead>
	 <th>Name</th>
	 <th>Value</th>
      </thead>
      <tbody>
         <tr>
            <td>Name</td>
            <td><code>{ $name }</code></td>
         </tr>
         { map:keys($props) ! disp:property(map:get($props, .)) }
      </tbody>
   </table>
};

declare function disp:mimetype(
   $name  as xs:string,
   $props as item((: map:map :))
) as element()+
{
   <h3><span class="glyphicon glyphicon-inbox" aria-hidden="true"/>{ ' ' }{ $name }</h3>,
   <p>Mimetype <code>{ $name }</code>.</p>,
   <table class="table table-striped">
      <thead>
	 <th>Name</th>
	 <th>Value</th>
      </thead>
      <tbody>
         <tr>
            <td>Name</td>
            <td><code>{ $name }</code></td>
         </tr>
         { map:keys($props) ! disp:property(map:get($props, .)) }
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

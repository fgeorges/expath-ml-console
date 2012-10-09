xquery version "1.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

v:console-page(
   'cxan',
   'CXAN',
   (<p>Install packages and applications directly from CXAN into a specific
      repository, using a package name or a CXAN ID (one or the other), and
      optionally a version number (retrieve the latest version by default).</p>,
    if ( cfg:is-setup() ) then
      <form method="post" action="do-cxan.xq" enctype="multipart/form-data">
         <span>Target repo:</span>
         <select name="repo"> {
            for $r in cfg:get-repos()
            return
               <option>{ $r/string(@name) }</option>
         }
         </select>
         <br/>
         <span>CXAN ID:</span>
         <input type="text" name="id" size="25"/>
         <br/>
         <span>Name:</span>
         <input type="text" name="name" size="50"/>
         <br/>
         <span>Version:</span>
         <input type="text" name="version" size="25"/>
         <br/>
         <input type="submit" value="Install"/>
      </form>
    else
      <p>The console has not been set up yet, please
         <a href="setup.xq">create a repo</a> first.</p>))

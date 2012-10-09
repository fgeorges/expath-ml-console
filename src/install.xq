xquery version "1.0";

import module namespace cfg = "http://expath.org/ns/ml/console/config" at "lib/config.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "lib/view.xql";

import module namespace admin = "http://marklogic.com/xdmp/admin" 
   at "/MarkLogic/admin.xqy";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace xdmp = "http://marklogic.com/xdmp";

v:console-page(
   'install',
   'Install',
   <wrapper>
      <p>Install a package into a repository.</p>
      <form method="post" action="do-install.xq" enctype="multipart/form-data">
         <input type="file" name="xar"/>
         <select name="repo"> {
            for $r in cfg:get-repos()
            return
               <option>{ $r/string(@name) }</option>
         }
         </select>
         <input type="submit" value="Install"/>
         <!--br/><br/>
         <input type="checkbox" name="override" value="true"/>
         <em>Override the package of it already exists</em-->
      </form>
   </wrapper>/*)

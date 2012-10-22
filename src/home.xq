xquery version "1.0";

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

v:console-page(
   'home',
   'EXPath Console',
   '',
   (: <img class="left" src="images/machine.jpg" alt="Machine"/> :)
   <wrapper>
      <p>Welcome to the EXPath console for MarkLogic. First, you might want to
         go the to <a href="help.xq">help section</a>. The other pages are:</p>
      <ul> {
         for $p in $v:pages/*[not(@name = ('home', 'help'))]
         return
            <li>
               <a href="{ $p/string(@name) }.xq">{ $p/string(@label) }</a>:
               { $p/string(@title) }
           </li>
      }
      </ul>
   </wrapper>/*)

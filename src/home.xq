xquery version "3.0";

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
   (: <img class="left" src="images/machine.jpg" alt="Machine"/> :)
   <wrapper>
      <p>Welcome to the EXPath console for MarkLogic. First, you might want to
         go the to <a href="help.xq">help section</a>. The other pages are:</p>
      <ul> {
         for $p in $v:pages/*[not(@name = ('.', 'help'))]
         return
            <li>
               <a href="{ $p/string(@name) }">{ $p/string(@title) }</a>
           </li>
      }
      </ul>
   </wrapper>/*
};

v:console-page('', 'home', 'EXPath Console', local:page#0)

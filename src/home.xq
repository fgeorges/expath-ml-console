xquery version "3.0";

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
   (: <img class="left" src="images/machine.jpg" alt="Machine"/> :)
   <wrapper>
      <p><em>(: Managing your Portable XQuery Extensions, Packages and Web
         Applications :)</em></p>
      <ul> {
         for $p in $v:pages/*[not(@name eq 'home')]
         return
            <li>
               <a href="{ $p/string(@name) }">{ $p/string(@title) }</a>
           </li>
      }
      </ul>
   </wrapper>/*
};

v:console-page('', 'home', 'EXPath Console', local:page#0)

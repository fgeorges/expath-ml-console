xquery version "3.0";

import module namespace v = "http://expath.org/ns/ml/console/view" at "lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare function local:page()
   as element()+
{
   (: <img class="left" src="images/machine.jpg" alt="Machine"/> :)
   <wrapper>
      <div class="jumbotron">
         <h1>EXPath Console</h1>
         <p><em>(: Managing your portable Extensions, Packages and Web
            Applications :)</em></p>
      </div>
      <p>You will find the following sections in the Console:</p>
      <ul> {
         for $p in $v:pages/*[fn:not(@name eq 'home')]
         return
            <li>
               <a href="{ $p/xs:string(@name) }">{ $p/xs:string(@title) }</a>
           </li>
      }
      </ul>
   </wrapper>/*
};

v:console-page('', 'home', 'EXPath Console', local:page#0)

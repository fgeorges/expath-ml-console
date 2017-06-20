xquery version "3.0";

import module namespace a   = "http://expath.org/ns/ml/console/admin"  at "../lib/admin.xqy";
import module namespace cfg = "http://expath.org/ns/ml/console/config" at "../lib/config.xql";
import module namespace t   = "http://expath.org/ns/ml/console/tools"  at "../lib/tools.xql";
import module namespace v   = "http://expath.org/ns/ml/console/view"   at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace h    = "http://www.w3.org/1999/xhtml";
declare namespace xdmp = "http://marklogic.com/xdmp";

declare function local:page()
   as element()+
{
   (: TODO: Check the parameters have been passed, to avoid XQuery errors! :)
   (: (turn them into human-friendly errors instead...) :)
   (: And validate them! (for instance is $id a lexical NCName?) :)
   let $id        := t:mandatory-field('id')
   let $name      := t:mandatory-field('name')
   let $root      := t:mandatory-field('root')
   let $appserver := xs:unsignedLong(t:mandatory-field('appserver'))
   return
      <wrapper>
         <p>About to create the web container '{ $id }'. You still have to
            associate the web container to a repository where to store its web
            applications. Either select an existing repository or create a new
            one.</p>
         <p>To cancel: go back to <a href="../web">web containers</a>.</p>
         <h4>Select a repository</h4>
         <!-- TODO: Tell it if there is no suitable repo for this App Server. -->
         <p>Select an existing repository to associate to the web container:</p>
         <form method="post" action="create" enctype="multipart/form-data">
            { local:repo-options($appserver) }
            <br/>
            <input name="select" type="submit" value="Select"/>
            <input type="hidden" name="id" value="{ $id }"/>
            <input type="hidden" name="name" value="{ $name }"/>
            <input type="hidden" name="root" value="{ $root }"/>
            <input type="hidden" name="appserver" value="{ $appserver }"/>
         </form>
         <h4>Create a repository</h4>
         <p>Create a new repository, on the selected App Server, to be associated
            to the web container:</p>
         <form method="post" action="create" enctype="multipart/form-data">
            <span>The repo ID (must be a valid NCName):</span><br/>
            <input type="text" name="repo-id" size="50"/><br/>
            <span>The repo name (any string):</span><br/>
            <input type="text" name="repo-name" size="50"/><br/>
            <span>The repo root (relative to the app server root):</span><br/>
            <input type="text" name="repo-root" size="50"/><br/>
            <input name="create" type="submit" value="Create"/>
            <input type="hidden" name="id" value="{ $id }"/>
            <input type="hidden" name="name" value="{ $name }"/>
            <input type="hidden" name="root" value="{ $root }"/>
            <input type="hidden" name="appserver" value="{ $appserver }"/>
         </form>
      </wrapper>/*
};

(:~
 : TODO: What if there is none?
 :)
declare function local:repo-options($as as xs:unsignedLong)
{
   <select name="repo"> {
      let $appserver := a:get-appserver($as)
      for $repo in cfg:get-appserver-repos($appserver)/fn:string(@id)
      order by $repo
      return
         <option value="{ $repo }">{ $repo }</option>
   }
   </select>
};

v:console-page('../', 'web', 'Web containers', local:page#0)

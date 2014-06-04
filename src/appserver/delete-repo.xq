xquery version "3.0";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xql";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xql";
import module namespace v = "http://expath.org/ns/ml/console/view"  at "../lib/view.xql";

declare default element namespace "http://www.w3.org/1999/xhtml";

declare namespace c   = "http://expath.org/ns/ml/console";
declare namespace err = "http://www.w3.org/2005/xqt-errors";

declare function local:page()
   as element()+
{
   (: the app server :)
   let $id-str  := t:mandatory-field('id')
   let $id      := xs:unsignedLong($id-str)
   let $as      := a:get-appserver($id)
   (: confirmed? :)
   let $confirm := t:optional-field('confirm', 'false')
   return (
      (: TODO: In those first few cases, we should NOT return "200 OK". :)
      if ( fn:empty($as) ) then
         <p><b>Error</b>: The app server "<code>{ $id-str }</code>" does not exist.</p>
      else if ( fn:not($confirm castable as xs:boolean) ) then
         <p><b>Error</b>: The parameter "<code>confirm</code>" is not a valid boolean:
            "<code>{ $confirm }</code>".</p>
      else
         try {
            a:appserver-nuke-repo($as, xs:boolean($confirm)),
            <p>The repository associated to the app server "<code>{ $as/xs:string(a:name) }</code>"
               has been entirely deleted.</p>
         }
         catch c:not-confirmed {
            <form method="post" action="delete-repo" enctype="multipart/form-data">
               <span>{ $err:description }</span>
               <br/><br/>
               <span><b>Warning</b>: This will remove all packages, if any, and all the repo management</span>
               <br/><br/>
               <input type="hidden" name="confirm" value="true"/>
               <input type="submit" value="Confirm"/>
               <a href="../{ $as/@id }">Cancel</a>
            </form>
         }
      ,
      <p>Back to the app server <a href="../{ $as/@id }">{ $as/xs:string(a:name) }</a>.</p>
   )
};

v:console-page('../../../../', 'pkg', 'Delete entire repository', local:page#0)

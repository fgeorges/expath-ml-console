xquery version "3.1";

module namespace dbc = "http://expath.org/ns/ml/console/database/config";

import module namespace a = "http://expath.org/ns/ml/console/admin" at "../lib/admin.xqy";
import module namespace t = "http://expath.org/ns/ml/console/tools" at "../lib/tools.xqy";

declare namespace c    = "http://expath.org/ns/ml/console";
declare namespace xdmp = "http://marklogic.com/xdmp";

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Database config access
 :
 : http://expath.org/ml/console/config.xml
 : <config>
 :    <uri-schemes>
 :       ...
 :    </uri-schemes>
 :    <triple-prefixes>
 :       ...
 :    </triple-prefixes>
 : </config>
 :
 : For instance, add the following in a document with the same URI as in the
 : variable `$dbc:config-doc`.  Either on the target database (to apply only to
 : browsing that database), or on the content database attached to the EXPath
 : Console app server (to set the default for all databases).
 :
 : <config xmlns="http://expath.org/ns/ml/console">
 :    <uri-schemes>
 :       <scheme sep="/">
 :          <root>
 :             <start>.</start>
 :          </root>
 :          <regex match="1">(\.[^/]+/).*</regex>
 :       </scheme>
 :    </uri-schemes>
 :  </config>
 :)

(: TODO: Make it possible to edit the list in the Console...:)
declare variable $dbc:config-doc   :=
   <path root="http://expath.org/" sep="/"
      >http://expath.org/ml/console/config.xml</path>;

declare variable $dbc:defaults-doc :=
   <path root="http://expath.org/" sep="/"
      >http://expath.org/ml/console/defaults.xml</path>;

(:~
 : Return the path where to store the config doc for `$db` on the system database.
 :
 : @todo The fact it relies on a:database is a sign that all this config stuff
 : should be in a dedicated module, outside of `tools`.  Then it should probably
 : even call a:get-database, out of a `$db` as an `item() `.
 :)
declare function dbc:config-system-doc($db as item()) as element(path)
{
   <path root="http://expath.org/" sep="/"> {
      'http://expath.org/ml/console/config/' || a:get-database($db)/a:name || '.xml'
   }
   </path>
};

declare variable $dbc:default-config :=
   <config xmlns="http://expath.org/ns/ml/console">
      <uri-schemes>
         <scheme sep="/">
            <root>
               <fixed>/</fixed>
            </root>
            <regex>/.*</regex>
         </scheme>
         <scheme sep="/">
            <root>
               <start>http://</start>
            </root>
            <regex match="1">(http://[^/]+/).*</regex>
         </scheme>
         <scheme sep=":">
            <root>
               <start>urn:</start>
            </root>
            <regex match="1">(urn:[^:]+:).*</regex>
         </scheme>
         <scheme sep="">
            <root>
               <fixed>latest</fixed>
            </root>
            <regex>latest</regex>
         </scheme>
      </uri-schemes>
      <triple-prefixes>
         <decl>
            <prefix>dc</prefix>
            <uri>http://purl.org/dc/terms/</uri>
         </decl>
         <decl>
            <prefix>doap</prefix>
            <uri>http://usefulinc.com/ns/doap#</uri>
         </decl>
         <decl>
            <prefix>foaf</prefix>
            <uri>http://xmlns.com/foaf/0.1/</uri>
         </decl>
         <decl>
            <prefix>frbr</prefix>
            <uri>http://purl.org/vocab/frbr/core</uri>
         </decl>
         <decl>
            <prefix>org</prefix>
            <uri>http://www.w3.org/ns/org#</uri>
         </decl>
         <decl>
            <prefix>owl</prefix>
            <uri>http://www.w3.org/2002/07/owl#</uri>
         </decl>
         <decl>
            <prefix>time</prefix>
            <uri>http://www.w3.org/2006/time#</uri>
         </decl>
         <decl>
            <prefix>prov</prefix>
            <uri>http://www.w3.org/ns/prov#</uri>
         </decl>
         <decl>
            <prefix>rdf</prefix>
            <uri>http://www.w3.org/1999/02/22-rdf-syntax-ns#</uri>
         </decl>
         <decl>
            <prefix>rdfs</prefix>
            <uri>http://www.w3.org/2000/01/rdf-schema#</uri>
         </decl>
         <decl>
            <prefix>skos</prefix>
            <uri>http://www.w3.org/2004/02/skos/core#</uri>
         </decl>
         <decl>
            <prefix>vcard</prefix>
            <uri>http://www.w3.org/2006/vcard/ns#</uri>
         </decl>
         <decl>
            <prefix>xsd</prefix>
            <uri>http://www.w3.org/2001/XMLSchema#</uri>
         </decl>
      </triple-prefixes>
   </config>;

declare function dbc:config-component($db as item()?, $name as xs:QName)
   as element((: $name :))*
{
   document {
      dbc:config-component-1(
         $name,
         ( $db ! t:query(., function() { fn:doc($dbc:config-doc)/* }),
           $db ! t:database-name(.) ! fn:doc(dbc:config-system-doc(.))/*,
           fn:doc($dbc:defaults-doc)/*,
           $dbc:default-config ))
   }/*
};

(:~
 : Helper for `dbc:config-component`, to reduce several config documents.
 :)
declare function dbc:config-component-1($name as xs:QName, $docs as element(c:config)*)
   as element((: $name :))*
{
   let $head := fn:head($docs)
   let $tail := fn:tail($docs)
   let $comp := $head/*[fn:node-name(.) eq $name]
   let $delg := ( $comp/@delegate/xs:string(.), $head/@delegate/xs:string(.) )[1]
   return
      if ( fn:empty($head) ) then (
      )
      else if ( $delg = ('never', 'false') ) then (
         $comp
      )
      else if ( $delg = ('before') ) then (
         dbc:config-component-1($name, $tail),
         $comp
      )
      else if ( $delg = ('after', 'true') or fn:empty($delg) ) then (
         $comp,
         dbc:config-component-1($name, $tail)
      )
      else (
         t:error('config', 'Unsupported @delegate value: ' || $delg)
      )
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Triple prefixes config
 :)

declare function dbc:config-triple-prefixes($db as item()?)
   as element(c:decl)*
{
   dbc:config-component($db, t:qname('triple-prefixes'))/*
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : URI schemes config
 :)

declare function dbc:config-uri-schemes($db as item()?)
   as element(c:scheme)*
{
   dbc:config-component($db, t:qname('uri-schemes'))/*
};

declare function dbc:resolve($uri as xs:string, $prefix as xs:string?, $schemes as element(c:scheme)*) as xs:string
{
   if ( fn:exists($prefix) and fn:not(dbc:is-absolute($uri, $schemes)) ) then
      $prefix || $uri
   else
      $uri
};

declare function dbc:is-absolute($uri as xs:string, $schemes as element(c:scheme)*) as xs:boolean
{
   if ( fn:empty($schemes) ) then
      fn:false()
   else if ( fn:starts-with($uri, fn:head($schemes)/c:root/(c:fixed|c:start)) ) then
      fn:true()
   else
      dbc:is-absolute($uri, fn:tail($schemes))
};

(:~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 : Default rulesets config
 :)

declare function dbc:config-default-rulesets($db as item()?)
   as element(c:ruleset)*
{
   dbc:config-component($db, t:qname('default-rulesets'))/*
};

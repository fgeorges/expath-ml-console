xquery version "3.0";

import module namespace b = "http://expath.org/ns/ml/webapp/binary" at "binary.xqy";

declare namespace map    = "http://marklogic.com/xdmp/map";
declare namespace pkg    = "http://expath.org/ns/pkg";
declare namespace w      = "http://expath.org/ns/ml/webapp";
declare namespace web    = "http://expath.org/ns/webapp";
declare namespace webapp = "http://expath.org/ns/webapp/descriptor";
declare namespace xdmp   = "http://marklogic.com/xdmp";
declare namespace xsl    = "http://www.w3.org/1999/XSL/Transform";

declare variable $web-config-docname := "http://expath.org/coll/webapp/config.xml";

declare variable $container := xdmp:get-request-field('expath-web-container');
declare variable $webapp    := xdmp:get-request-field('expath-web-app');
declare variable $servlet   := xdmp:get-request-field('expath-web-servlet');
declare variable $url       := xdmp:get-request-field('expath-web-url');

(:~
 : Return the web:request element corresponding to the current HTTP request.
 :)
declare function local:make-request(
  $cont   as element(w:container),
  $srv    as element(webapp:servlet),
  $bodies as item()*
) as element(web:request)
{
  let $protocol  := xdmp:get-request-protocol()
  let $host      := xdmp:get-request-header('host')
  let $authority := if ( fn:exists($host) ) then fn:string-join(($protocol, '://', $host)) else ()
  let $method    := fn:lower-case(xdmp:get-request-method())
  let $root      := fn:concat('/', $cont/w:web-root, '/', $webapp)
  let $path_     := fn:substring-after($url, $root)
  let $path      := if ( fn:contains($path_, '?') ) then fn:substring-before($path_, '?') else $path_
  let $regex     := fn:concat('^', $srv/webapp:url/@pattern, '$')
  return
    <web:request servlet="tools"
                 path="{ $path }"
                 method="{ $method }"
                 port="{ xdmp:get-request-port() }">
      <web:uri>{ $authority }{ $url }</web:uri>
      { <web:authority>{ $authority }</web:authority>[fn:exists($host)] }
      <web:context-root>{ $root }</web:context-root>
      <web:path> {
        for $node in fn:analyze-string($path, $regex)/*/node()
        let $match := $srv/webapp:url/webapp:match[@group/xs:integer(.) eq $node/@nr]
        return
          if ( fn:exists($match) ) then
            <web:match name="{ $match/fn:string(@name) }">{ fn:string($node) }</web:match>
          else
            <web:part>{ $node }</web:part>
      }
      </web:path>
      {
        (: TODO: If I am right, will include files from multipart/form-data...
           Should I at least test if xdmp:get-request-field-filename() exists? :)
        for $n in xdmp:get-request-field-names()[fn:not(fn:starts-with(., 'expath-web-'))]
        return
          <web:param name="{ $n }" value="{ xdmp:get-request-field($n) }"/>
      }
      {
        for $n in xdmp:get-request-header-names()
        return
          <web:header name="{ fn:lower-case($n) }" value="{ xdmp:get-request-header($n) }"/>
      }
      {
        let $type := xdmp:get-request-header('content-type')
        return
          if ( fn:starts-with($type, 'multipart/') ) then
            <web:multipart content-type="{ $type }"> {
              (: TODO: How to decode multipart requests...? :)
              fn:error((), 'Multipart request not supported yet.')
            }
            </web:multipart>
          else if ( fn:exists($bodies) ) then
            <web:body content-type="{ $type }" position="1"/>
          else
            ()
      }
    </web:request>
};

(:~
 : Analyze the response from the component and use its value.
 :
 : TODO: Handle the case when the result is not a web:response element.
 :)
declare function local:analyse-response($response as element(web:response), $payload)
{
  (: TODO: How to take $response/web:body/@method into account?  That is, how
     to set the serialization method? :)
  xdmp:set-response-code($response/xs:integer(@status), $response/@message),
  xdmp:set-response-content-type($response/web:body/@content-type),
  $payload
};

(: Duplicated in launcher.xq.  TODO: Factorize out... :)
declare function local:webapp-root($app as element(w:application))
  as xs:string
{
  (: if on dir and no leading slash, add one :)
  let $lead-slash := fn:starts-with($app/../w:repo-root, '/')
  let $slash := '/'[fn:exists($app/../w:repo-dir)][fn:not($lead-slash)]
  return
    fn:concat($slash, $app/../w:repo-root, $app/w:pkg-dir, '/content/')
};

declare function local:webapp-pkg-desc($app as element(w:application))
  as element(pkg:package)
{
  let $repo-dir := $app/../w:repo-dir
  let $relative := fn:concat($app/w:pkg-dir, '/expath-pkg.xml')
  return
    if ( fn:exists($repo-dir) ) then
      xdmp:unquote(
        xdmp:filesystem-file(
          fn:concat($repo-dir, $relative)))/*
    else
      xdmp:eval(
        'declare variable $path external; fn:doc($path)',
        (xs:QName('path'), fn:concat($app/../w:repo-root, $relative)),
        <options xmlns="xdmp:eval">
           <database>{ xdmp:modules-database() }</database>
        </options>)/*
};

declare function local:get-container($id as xs:string)
  as element(w:container)
{
  fn:doc($web-config-docname)
    / w:config
    / w:container[@id eq $id]
};

(:~
 : Invoke an XQuery main module component.
 :)
declare function local:invoke-query(
  $servlet as element(webapp:servlet),
  $request as element(web:request),
  $bodies  as item()*
) as item()+
{
  let $root  := local:webapp-root($servlet/../..)
  let $query := local:webapp-pkg-desc($servlet/../..)
                  / pkg:xquery[pkg:import-uri eq $servlet/webapp:xquery/@uri]
                  / fn:string(pkg:file)
  return
    if ( fn:exists($bodies) ) then
      (: TODO: How to pass a sequence as the value of a variable? :)
      fn:error((), 'Entity content not supported for query components, due to MarkLogic limitation.')
    else
      xdmp:invoke(fn:concat($root, $query), (xs:QName('web:input'), $request))
};

(:~
 : Invoke a function component in an XQuery library module.
 :)
declare function local:invoke-xquery-function(
  $servlet as element(webapp:servlet),
  $request as element(web:request),
  $bodies  as item()*
) as item()+
{
  let $qname    := $servlet/webapp:xquery/fn:resolve-QName(@function, .)
  let $ns       := fn:namespace-uri-from-QName($qname)
  let $function := fn:local-name-from-QName($qname)
  let $root     := local:webapp-root($servlet/../..)
  let $query    := local:webapp-pkg-desc($servlet/../..)
                     / pkg:xquery[pkg:namespace eq $ns]
                     / fn:string(pkg:file)
  return
    if ( fn:exists($bodies[2]) ) then
      fn:error((), 'Internal error: I thought multipart was not supported?!? Please report this to the mailing list.')
    else if ( fn:exists($bodies) ) then
      xdmp:eval(
         concat(
            'import module namespace ns = "', $ns, '" at "', fn:concat($root, $query), '";
             declare namespace web = "http://expath.org/ns/webapp";
             declare variable $web:request as element(web:request) external;
             (: More than one body not needed, as multipart is not supported for now. :)
             declare variable $web:body-01 as item() external;
             ns:', $function, '(($web:request, $body-01))'),
         (xs:QName('web:request'), $request,
          xs:QName('web:body-01'), $bodies[1]))
    else
      xdmp:eval(
         concat(
            'import module namespace ns = "', $ns, '" at "', fn:concat($root, $query), '";
             declare namespace web = "http://expath.org/ns/webapp";
             declare variable $web:input as item()+ external;
             ns:', $function, '($web:input)'),
         (xs:QName('web:input'), $request))
};

(:~
 : Invoke an XSLT stylesheet component.
 :)
declare function local:invoke-style(
  $servlet as element(webapp:servlet),
  $request as element(web:request),
  $bodies  as item()*
) as item()+
{
  let $params := map:map()
  let $dummy  := map:put($params, "{http://expath.org/ns/webapp}input", ($request, $bodies))
  let $root   := local:webapp-root($servlet/../..)
  let $style  := local:webapp-pkg-desc($servlet/../..)
                   / pkg:xslt[pkg:import-uri eq $servlet/webapp:xslt/@uri]
                   / fn:string(pkg:file)
  return
    xdmp:xslt-invoke(
      fn:concat($root, $style),
      document { $request },
      $params
      )/node()
};

(:~
 : Invoke a function component in an XSLT stylesheet.
 :)
declare function local:invoke-xslt-function(
  $servlet as element(webapp:servlet),
  $request as element(web:request),
  $bodies  as item()*
) as item()+
{
  let $qname    := $servlet/webapp:xslt/fn:resolve-QName(@function, .)
  let $ns       := fn:namespace-uri-from-QName($qname)
  let $function := fn:local-name-from-QName($qname)
  return
    local:invoke-xslt-component(
      <xsl:sequence select="ns:{ $function }($web:input)"/>,
      $ns,
      $servlet,
      $request,
      $bodies)
};

(:~
 : Invoke a named template component in an XSLT stylesheet.
 :)
declare function local:invoke-xslt-template(
  $servlet as element(webapp:servlet),
  $request as element(web:request),
  $bodies  as item()*
) as item()+
{
  let $qname    := $servlet/webapp:xslt/fn:resolve-QName(@template, .)
  let $ns       := fn:namespace-uri-from-QName($qname)
  let $template := fn:local-name-from-QName($qname)
  return
    local:invoke-xslt-component(
      <xsl:call-template name="ns:{ $template }">
        <xsl:with-param name="input" select="$web:input"/>
      </xsl:call-template>,
      $ns,
      $servlet,
      $request,
      $bodies)
};

(:~
 : Invoke a component in an XSLT stylesheet (function or named template).
 :)
declare function local:invoke-xslt-component(
  $implem  as element(),
  $ns      as xs:string,
  $servlet as element(webapp:servlet),
  $request as element(web:request),
  $bodies  as item()*
) as item()+
{
  let $params := map:map()
  let $dummy  := map:put($params, "{http://expath.org/ns/webapp}input", ($request, $bodies))
  let $root   := local:webapp-root($servlet/../..)
  let $style  := local:webapp-pkg-desc($servlet/../..)
                   / pkg:xslt[pkg:import-uri eq $servlet/webapp:xslt/@uri]
                   / fn:string(pkg:file)
  return
    xdmp:xslt-eval(
      (: TODO: See what is generated in Servlex... :)
      <xsl:stylesheet xmlns:web="http://expath.org/ns/webapp"
                      version="2.0">
        { namespace { 'ns' } { $ns } }
        <xsl:import href="{ $root }{ $style }"/>
        <xsl:param name="web:input" as="item()+"/>
        <xsl:template name="web:main">
          { $implem }
        </xsl:template>
      </xsl:stylesheet>,
      (),
      $params,
      <options xmlns="xdmp:eval">
        <template>web:main</template>
      </options>
      )/node()
};

(:~
 : Invoke a component.
 :
 : The supported components are:
 :   - XQuery function
 :   - XQuery main module
 :   - XSLT function
 :   - XSLT template
 :   - XSLT stylesheet
 :
 : The not supported components are:
 :   - XProc pipeline
 :)
declare function local:invoke(
  $servlet as element(webapp:servlet),
  $request as element(web:request),
  $bodies  as item()*
) as item()+
{
  if ( fn:exists($servlet/webapp:xslt/@function) ) then
    local:invoke-xslt-function($servlet, $request, $bodies)
  else if ( fn:exists($servlet/webapp:xslt/@template) ) then
    local:invoke-xslt-template($servlet, $request, $bodies)
  else if ( fn:exists($servlet/webapp:xslt) ) then
    local:invoke-style($servlet, $request, $bodies)
  else if ( fn:exists($servlet/webapp:xquery/@function) ) then
    local:invoke-xquery-function($servlet, $request, $bodies)
  else if ( fn:exists($servlet/webapp:xquery) ) then
    local:invoke-query($servlet, $request, $bodies)
  else if ( fn:exists($servlet/webapp:xproc) ) then
    fn:error((), 'TODO: XProc not supported', $servlet)
  else
    fn:error((), 'TODO: Invalid servlet!', $servlet)
};

(:
 : The main expression.
 :)

(: retrieve the servlet :)
let $cont     := local:get-container($container)
let $app      := $cont/w:application[@root eq $webapp]
let $srv      := $app/webapp:webapp/webapp:servlet[@name eq $servlet]
(: retrieve the request info :)
let $bodies   := b:format-bodies(xdmp:get-request-body())
let $request  := local:make-request($cont, $srv, $bodies)
(: invoke the component :)
let $result   := local:invoke($srv, $request, $bodies)
(: handle the result :)
let $response := $result[1]
let $payload  := $result[2]
return
  local:analyse-response($response, $payload)

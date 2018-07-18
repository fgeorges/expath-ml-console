xquery version "3.0";

module namespace d = "http://expath.org/ns/ml/webapp/dispatcher";

declare namespace webapp = "http://expath.org/ns/webapp/descriptor";
declare namespace pkg    = "http://expath.org/ns/pkg";
declare namespace w      = "http://expath.org/ns/ml/webapp";
declare namespace xdmp   = "http://marklogic.com/xdmp";

declare variable $web-config-docname := "http://expath.org/coll/webapp/config.xml";

(:~
 : Rewrite the URL if it is in one web container space.
 :
 : Each web container has a web-root.  If the URL has the same root (that is, if
 : the URL as a string starts with the web-root) as one web container, it is
 : rewriten to dispatch to the appropriate component in the appropriate webapp.
 : If there is none (no corresponding webapp, or no corresponding component),
 : then an error is throwm.
 :
 : If the URL is not within any web container space, the empty sequence is
 : returned.
 :)
declare function d:dispatch()
  as xs:string?
{
  let $url       := xdmp:get-request-path()
  let $container := d:get-container($url)
  return
    if ( fn:not(fn:starts-with($url, '/')) ) then
      fn:error((), 'TODO: What, does not start with /?')
    else if ( fn:starts-with($url, '/expath/web/') ) then
      (: TODO: Throw an appropriate error (result in 404, or another 40*). :)
      fn:error((), '/expath/web/ cannot be accessed from the outside')
    else if ( fn:empty($container) ) then
      ()
    else
      let $path := fn:substring-after($url, $container/w:web-root)
      let $app  := d:get-webapp($path, $container)
      return
        if ( fn:empty($app) ) then
          (: TODO: Throw an appropriate error (result in 404, and give more info...) :)
          fn:error((), 'No webapp found in the web container')
        else
          let $path := fn:substring-after($path, $app/@root)
          let $cpnt := d:first-matching($path, $app/webapp:webapp/(webapp:resource|webapp:servlet))
          return
            if ( fn:empty($cpnt) ) then
              (: TODO: Throw an appropriate error (result in 404, and give more info...) :)
              fn:error((), 'No component found in the web application')
            else
              d:rewrite($app, $path, $cpnt)
};

declare %private function d:get-params()
  as xs:string?
{
  (: TODO: Nothing better, really? :)
  let $url := xdmp:get-request-url()
  return
    if ( fn:contains($url, '?') ) then
      fn:substring-after($url, '?')
    else
      ()
};

(:~
 : Return the first matching component.
 :
 : A component is either an element webapp:resource or an element webapp:servlet.
 : The first one in the sequence order that matches the given path is returned.
 : A component matches when the path matches its regex (either @pattern for
 : resource or url/@pattern for servlet).
 :)
declare %private function d:first-matching($path as xs:string, $components as element()*)
  as element()?
{
  if ( fn:empty($components) ) then
    ()
  else
    let $c  := $components[1]
    let $re := ( $c/self::webapp:resource/@pattern,
                 $c/self::webapp:servlet/webapp:url/@pattern )
    return
      if ( fn:matches($path, fn:concat('^', $re, '$')) ) then
        $c
      else
        d:first-matching($path, fn:remove($components, 1))
};

(: Duplicated in launcher.xq.  TODO: Factorize out... :)
declare %private function d:webapp-root($app as element(w:application))
  as xs:string
{
  (: TODO: Why concatenating '/' ? :)
  (:fn:concat('/', $app/../w:repo-root, $app/w:pkg-dir, '/content/'):)
  fn:concat($app/../w:repo-root, $app/w:pkg-dir, '/content/')
};

(:~
 : Rewrite the URL given one component.
 :
 : If the component is a resource, it is rewritten directly.  If it is a
 : servlet, it is rewritten to launcher.xq, passing the needed information
 : through additional URL query parameters.
 :)
declare %private function d:rewrite(
  $app  as element(w:application),
  $path as xs:string,
  $cpnt as element()
) as xs:string
{
  typeswitch ( $cpnt )
    case element(webapp:resource) return
      (: TODO: What if params...? :)
      d:rewrite-resource($path, $cpnt, $app)
    case element(webapp:servlet) return
      d:rewrite-servlet($path, d:get-params(), $cpnt, $app)
    default return
      fn:error((), 'TODO: What the F?')
};

declare %private function d:rewrite-resource(
  $path as xs:string,
  $cpnt as element(webapp:resource),
  $app  as element(w:application)
) as xs:string
{
  if ( fn:exists($cpnt/@media-type) ) then
    (: TODO: Is this allowed in the URL rewriter? :)
    xdmp:set-response-content-type($cpnt/@media-type)
  else
    (),
  fn:concat(
    d:webapp-root($app),
    fn:replace($path, fn:concat('^', $cpnt/@pattern, '$'), $cpnt/@rewrite))
};

declare %private function d:rewrite-servlet(
  $path    as xs:string,
  $params  as xs:string?,
  $servlet as element(webapp:servlet),
  $app     as element(w:application)
) as xs:string
{
  fn:concat(
    '/expath/web/launcher.xq?expath-web-container=',
    $app/../@id,
    '&amp;expath-web-app=',
    $app/@root,
    '&amp;expath-web-servlet=',
    $servlet/@name,
    (: TODO: Encode it? :)
    '&amp;expath-web-url=',
    xdmp:get-request-url(),
    '&amp;'[fn:exists($params)],
    $params)
};

(:~
 : Return the container serving the $uri, if any.
 :
 : If several containers match, the first one is returned.  But that should
 : never happen, as this should be tested at web container creation.
 :)
declare %private function d:get-container($uri as xs:string)
  as element(w:container)?
{
  (
    fn:doc($web-config-docname)
      / w:config
      / w:container[fn:starts-with($uri, fn:concat(w:web-root, '/'))]
  )[1]
};

declare %private function d:get-webapp($uri as xs:string, $container as element(w:container)?)
  as element(w:application)?
{
  $container/w:application[fn:starts-with($uri, @root)]
};

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="xs xdmp"
                version="2.0">

   <xsl:template match="*" priority="-10">
      <xsl:variable name="path" select="
          string-join(for $a in ancestor-or-self::* return name($a), '/')"/>
      <xsl:sequence select="error((), concat('Unknown node: ', $path))"/>
   </xsl:template>

   <xsl:template match="*" priority="-10" mode="toc">
      <xsl:variable name="path" select="
          string-join(for $a in ancestor-or-self::* return name($a), '/')"/>
      <xsl:sequence select="error((), concat('Unknown node in toc: ', $path))"/>
   </xsl:template>

   <xsl:template match="module[error]">
      <p><b>Error</b>: parsing error.</p>
      <p>The module might be using MarkLogic extensions to XQuery not supported by the parser.
         <a href="https://github.com/jpcs/xqueryparser.xq/issues/6">Yet</a>...</p>
      <p>Error returned by the parser:</p>
      <pre>
         <xsl:value-of select="xdmp:quote(error/*)"/>
      </pre>
   </xsl:template>

   <xsl:template match="module">
      <p>Table of contents:</p>
      <xsl:choose>
         <xsl:when test="exists(section) and empty(*[1][self::section])">
            <ul>
               <li>
                  <a href="#sct.0">Functions</a>
                  <ul>
                     <xsl:apply-templates select="function" mode="toc"/>
                  </ul>
               </li>
               <xsl:apply-templates select="section" mode="toc"/>
            </ul>
         </xsl:when>
         <xsl:otherwise>
            <ul>
               <xsl:apply-templates select="*" mode="toc"/>
            </ul>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="empty(*[1][self::section])">
         <a name="sct.0"/>
         <h2>Functions</h2>
      </xsl:if>
      <xsl:apply-templates/>
   </xsl:template>

   <xsl:template match="section" mode="toc">
      <li>
         <a href="#sct.{ count(preceding-sibling::section) + 1 }">
            <xsl:value-of select="head"/>
         </a>
         <ul>
            <xsl:apply-templates select="function|section" mode="toc"/>
         </ul>
      </li>
   </xsl:template>

   <xsl:template match="function" mode="toc">
      <li>
         <a href="#fn.{ signature/@arity }.{ signature/@name }">
            <xsl:value-of select="signature/@name"/>
         </a>
      </li>
   </xsl:template>

   <xsl:template match="section">
      <a name="sct.{ count(preceding-sibling::section) + 1 }"/>
      <h2>
         <xsl:value-of select="head"/>
      </h2>
      <xsl:apply-templates select="* except head"/>
   </xsl:template>

   <xsl:template match="function">
      <a name="fn.{ signature/@arity }.{ signature/@name }"/>
      <h3>
         <xsl:value-of select="signature/@name"/>
      </h3>
      <div class="md-content">
         <xsl:value-of select="comment/head"/>
      </div>
      <pre>
         <xsl:value-of select="signature/@name"/>
         <xsl:text>(</xsl:text>
         <xsl:value-of separator="," select="
             signature/param/concat('&#10;   $', @name, @type/concat(' as ', .))"/>
         <xsl:if test="signature/param">
            <xsl:text>&#10;</xsl:text>
         </xsl:if>
         <xsl:text>)</xsl:text>
         <xsl:value-of select="signature/@type/concat(' as ', .)"/>
      </pre>
      <!--
          TODO: Do something more elaborate with the signature/param elements
          (e.g. display params not documented).
          TODO: Validate the params list in comment/param and in signature/param
          (here or in the parser lib).
      -->
      <xsl:if test="exists(comment/param)">
         <p>Parameters:</p>,
         <ul>
            <xsl:for-each select="comment/param">
               <li class="md-content">
                  <xsl:text>`</xsl:text>
                  <xsl:value-of select="@name"/>
                  <xsl:text>` - </xsl:text>
                  <xsl:value-of select="."/>
               </li>
            </xsl:for-each>
         </ul>
      </xsl:if>
      <xsl:apply-templates select="comment/return"/>
      <xsl:apply-templates select="comment/body"/>
      <xsl:apply-templates select="comment/(* except (head|param|return|body))"/>
   </xsl:template>

   <xsl:template match="head"/>
   <xsl:template match="param"/>
   <xsl:template match="return"/>

   <!-- TODO: Once they're all supported, turn it into a white list (error for all unknown...) -->
   <xsl:template match="comment/*" priority="0">
      <pre>
         <xsl:value-of select="xdmp:quote(.)"/>
      </pre>
   </xsl:template>

   <xsl:template match="return">
      <p>Return:</p>
      <ul>
         <li>
            <xsl:apply-templates/>
         </li>
      </ul>
   </xsl:template>

   <xsl:template match="body">
      <div class="md-content">
         <xsl:apply-templates/>
      </div>
   </xsl:template>

   <xsl:template match="todo">
      <div class="md-content todo">
         <xsl:apply-templates/>
      </div>
   </xsl:template>

</xsl:stylesheet>

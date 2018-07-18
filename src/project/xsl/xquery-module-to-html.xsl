<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns="http://www.w3.org/1999/xhtml"
                exclude-result-prefixes="xs xdmp"
                version="2.0">

   <xsl:import href="module-to-html.xsl"/>

   <xsl:template match="signature">
      <xsl:value-of select="@name"/>
      <xsl:text>(</xsl:text>
      <xsl:choose>
         <xsl:when test="count(param) ge 2">
            <xsl:value-of separator="," select="
                param/concat('&#10;   $', @name, @type/concat(' as ', .))"/>
            <xsl:text>&#10;</xsl:text>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="param/concat('$', @name, @type/concat(' as ', .))"/>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:text>)</xsl:text>
      <xsl:value-of select="@type/concat(' as ', .)"/>
   </xsl:template>

</xsl:stylesheet>

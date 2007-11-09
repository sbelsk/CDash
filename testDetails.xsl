<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version='1.0'>
<xsl:include href="header.xsl"/>
<xsl:include href="footer.xsl"/>
<xsl:output method="html"/>
<xsl:template match="/">
<html>
<head>
  <title><xsl:value-of select="cdash/title"/></title>
  <meta name="robots" content="noindex,nofollow" />
  <link rel="StyleSheet" type="text/css">
    <xsl:attribute name="href">
      <xsl:value-of select="cdash/cssfile"/>
    </xsl:attribute>
  </link>
</head>
<body bgcolor="#ffffff">
<xsl:call-template name="header"/>

<br/>
<p>
  <b>Site Name: </b><xsl:value-of select="cdash/test/site"/>
</p>
<p>
  <b>Build Name: </b><xsl:value-of select="cdash/test/build"/>
</p>
<table cellpadding="2">
  <tr>
    <td>
      <a>
        <xsl:attribute name="href">
	  <xsl:value-of select="cdash/test/summaryLink"/> 
        </xsl:attribute>
	<xsl:value-of select="cdash/test/test"/> 
      </a>
    </td>
    <td>
      <font>
        <xsl:attribute name="color">
          <xsl:value-of select="cdash/test/statusColor"/>
        </xsl:attribute>
	<xsl:value-of select="cdash/test/status"/>
      </font>
    </td>
  </tr>
</table>
<br/><br/><br/>
<table>
<xsl:for-each select="cdash/test/images/image">
  <tr>
    <th class="measurement"><xsl:value-of select="role"/></th>
    <td>
      <img>
	<xsl:attribute name="src">displayImage.php?imgid=<xsl:value-of select="imgid"/>
	</xsl:attribute>
      </img>
    </td>
  </tr>
</xsl:for-each>
   <tr>
      <th class="measurement">Execution Time</th>
      <td>
        <xsl:value-of select="cdash/test/time"/>
      </td>
   </tr>
   <tr>
      <th class="measurement">Command Line</th>
      <td>
        <xsl:value-of select="cdash/test/command"/>
      </td>
   </tr>
   <tr>
      <th class="measurement">Completion Status</th>
      <td>
        <xsl:value-of select="cdash/test/details"/>
      </td>
   </tr>

</table>
<br/><br/><br/>
<b>Test output</b>
<pre>
  <xsl:value-of select="cdash/test/output"/>
</pre>
<br/>

<!-- FOOTER -->
<br/>
<xsl:call-template name="footer"/>
</body>
</html>
</xsl:template>
</xsl:stylesheet>

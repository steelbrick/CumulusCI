<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sf="http://soap.sforce.com/2006/04/metadata" xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xslt="http://xml.apache.org/xslt" xmlns:xalan="http://xml.apache.org/xalan" exclude-result-prefixes="sf">

<xsl:param name="whitelist" select="" />

<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes" xslt:indent-amount="4"/>

    <xsl:template match="sf:CustomObject">
        <shite>
        <xsl:for-each select="sf:fields">
          <xsl:if test="substring(sf:fullName, string-length(sf:fullName) - 2) = '__c'">
          <xsl:if test="sf:required = 'false'">
          <xsl:if test="not(contains(substring(sf:fullName, 0, string-length(sf:fullName) - 2), '__'))">
          <xsl:if test="not(contains($whitelist, concat(',', sf:fullName, ',')))">
              <fieldPermissions>
                  <editable>true</editable>
                  <field><xsl:copy-of select="sf:fullName/text()"/></field>
                  <readable>true</readable>
              </fieldPermissions>
          </xsl:if>
          </xsl:if>
          </xsl:if>
          </xsl:if>
        </xsl:for-each>
        </shite>
    </xsl:template>

</xsl:stylesheet>

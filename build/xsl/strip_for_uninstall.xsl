<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sf="http://soap.sforce.com/2006/04/metadata" xmlns="http://soap.sforce.com/2006/04/metadata"  exclude-result-prefixes="sf">

	<xsl:template match="@* | node()">
		<xsl:copy><xsl:apply-templates select="@* | node()"/></xsl:copy>
	</xsl:template>

	<xsl:template match="sf:fields[sf:type!='Summary' and sf:type != 'MasterDetail' and not(sf:lookupFilter)]|sf:fieldSets|sf:actionOverrides|sf:listViews|sf:searchLayouts|sf:validationRules|sf:webLinks"/>

	<xsl:template match="sf:summarizedField|sf:summaryFilterItems|sf:lookupFilter"/>

	<xsl:template match="sf:summaryOperation/text()">
		<xsl:text>count</xsl:text>
	</xsl:template>

</xsl:stylesheet>

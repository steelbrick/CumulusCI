<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:sf="http://soap.sforce.com/2006/04/metadata" xmlns="http://soap.sforce.com/2006/04/metadata"  exclude-result-prefixes="sf">

	<xsl:template match="@* | node()">
		<xsl:copy><xsl:apply-templates select="@* | node()"/></xsl:copy>
	</xsl:template>

	<xsl:template match="sf:fields[sf:type!='Summary' and sf:type != 'MasterDetail' and not(sf:lookupFilter) and not(sf:formula)]|sf:fieldSets|sf:actionOverrides|sf:listViews|sf:searchLayouts|sf:validationRules|sf:webLinks"/>

	<xsl:template match="sf:summarizedField|sf:summaryFilterItems|sf:lookupFilter"/>

	<xsl:template match="sf:summaryOperation/text()">
		<xsl:text>count</xsl:text>
	</xsl:template>

	<xsl:template match="*[sf:type='Checkbox']/sf:formula/text()">
		<xsl:text>false</xsl:text>
	</xsl:template>

	<xsl:template match="*[sf:type='Text']/sf:formula/text()">
		<xsl:text>'Bork'</xsl:text>
	</xsl:template>

	<xsl:template match="*[sf:type='Number' or sf:type='Percent' or sf:type='Currency']/sf:formula/text()">
		<xsl:text>0</xsl:text>
	</xsl:template>

	<xsl:template match="*[sf:type='Date']/sf:formula/text()">
		<xsl:text>NOW()</xsl:text>
	</xsl:template>

</xsl:stylesheet>

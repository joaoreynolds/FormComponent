<!---
////////////////////////////////////////
FORM-BUILDING API
AUTHOR: John Reynolds - Blue Pine Media, LLC
AUTHOR WEBSITE: www.bluepinemedia.com
DATE CREATED: Mar 2, 2012

THIS COMPONENT BUILDS AN ELEMENT OBJECT

--->

<cfcomponent output="no">
	
    <!---VARS--->
    <cfset this.id = ''>
    <cfset this.name = ''>
    <cfset this.type = ''>
    <cfset this.label = ''>
    <cfset this.value = ''>
    <cfset this.isRequired = false>
    <cfset this.validationRules = ArrayNew(1)><!---array of rules: 'notEmpty','email','minValue'(must be matched with minValue),'minLength', 'match'(must accompany 'match' value)--->
    <cfset this.size = '50'>
    <cfset this.maxLength = '100'>
    <cfset this.rows = '3'>
    <cfset this.cols = '50'>
    <cfset this.items = ArrayNew(3)><!---THIS IS A 2-D ARRAY: ["optionValue","optionText","optionclass"]; or ["checkboxValue","checkBoxLabel","checkBoxClass"]; or ["radioValue","radioLabel","radioClass"] --->
    <cfset this.class = ''>
    <cfset this.labelClass = ''>
    <cfset this.showVertical = true><!---Show radio buttons or checkboxes in a group vertically (if false it's horizontal)--->
    <cfset this.minValue = '0'>
    <cfset this.minLength = '0'>
    <cfset this.filetypes = ''><!--- a string of allowed filetypes for file upload (ex: 'jpg,jpeg,gif,png') --->
    <cfset this.maxFileSize = '0'>
    <cfset this.fileNewName = ''>
    <cfset this.fileDirectory = ''>
    <cfset this.alone = false><!--- set to true to display element without surrounding html --->
    <cfset this.match = ''><!--- if validation rule includes "match" this value provides the id of the element it should match (ex: entering email twice) --->
    
    <cfset this.validStatus = true>
    <cfset this.tempFilePath = ''>
    
    
    <!---FUNCTIONS--->
    
    <cffunction name="init" output="true">
		<cfargument name="id" type="string" required="yes">
		<cfargument name="type" type="string" required="yes">
		<cfargument name="label" type="string" required="no" default="">
		<cfargument name="value" type="string" required="no" default="">
		<cfargument name="isRequired" type="boolean" required="no" default="false">
		<cfargument name="validationRules" type="array" required="no" default="#ArrayNew(1)#">
		<cfargument name="size" type="numeric" required="no" default="50">
		<cfargument name="maxLength" type="numeric" required="no" default="100">
		<cfargument name="rows" type="numeric" required="no" default="3">
		<cfargument name="cols" type="numeric" required="no" default="50">
		<cfargument name="items" type="array" required="no" default="#ArrayNew(3)#">
		<cfargument name="class" type="string" required="no" default="">
		<cfargument name="labelClass" type="string" required="no" default="">
		<cfargument name="showVertical" type="boolean" required="no" default="true">
		<cfargument name="minValue" type="numeric" required="no" default="0">
		<cfargument name="minLength" type="numeric" required="no" default="0">
		<cfargument name="preHTML" type="string" required="no" default="">
		<cfargument name="postHTML" type="string" required="no" default="">
		<cfargument name="filetypes" type="string" required="no" default="">
		<cfargument name="maxFileSize" type="numeric" required="no" default="">
		<cfargument name="fileNewName" type="string" required="no" default="">
		<cfargument name="fileDirectory" type="string" required="no" default="">
		<cfargument name="alone" type="boolean" required="no" default="false">
		<cfargument name="match" type="string" required="no" default="">
        
        
        
        
        
        <cfset this.id = arguments.id>
        <cfset this.name = arguments.id>
        <cfset this.type = arguments.type>
        <cfset this.label = arguments.label>
        <cfset this.value = arguments.value>
        <cfset this.isRequired = arguments.isRequired>
        <cfset this.validationRules = arguments.validationRules>
        <cfset this.size = arguments.size>
        <cfset this.maxLength = arguments.maxLength>
        <cfset this.rows = arguments.rows>
        <cfset this.cols = arguments.cols>
        <cfset this.items = arguments.items>
        <cfset this.class = arguments.class>
        <cfset this.labelClass = arguments.labelClass>
        <cfset this.showVertical = arguments.showVertical>
        <cfset this.minValue = arguments.minValue>
        <cfset this.minLength = arguments.minLength>
        <cfset this.preHTML = arguments.preHTML>
        <cfset this.postHTML = arguments.postHTML>
        <cfset this.filetypes = arguments.filetypes>
        <cfset this.maxFileSize = arguments.maxFileSize>
        <cfset this.fileNewName = arguments.fileNewName>
        <cfset this.fileDirectory = arguments.fileDirectory>
        <cfset this.alone = arguments.alone>
        <cfset this.match = arguments.match>
        
        
        
	</cffunction>
    
    
    
</cfcomponent>



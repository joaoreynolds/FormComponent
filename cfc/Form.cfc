<!---
////////////////////////////////////////
FORM-BUILDING API
AUTHOR: John Reynolds - Blue Pine Media, LLC
AUTHOR WEBSITE: www.bluepinemedia.com
DATE CREATED: Mar 2, 2012
VERSION 1.1.1 - Feb 28,2014

THIS COMPONENT BUILDS A FORM
INSTRUCTIONS::::

CREATE THE FORM OBJECT WITH THIS:
<cfset session.formName = createObject("component","colorfortessa.lib.components.Form")> //replace formName with your own form name


ADD ELEMENTS WITH THIS (after creating the form object): (values in example are default values -except for required elements, which have no default)
<cfset
	session.formName.addElement(
		id='firstName',					//(REQUIRED) id of element
		type='text',					//(REQUIRED) type: 'text,'textarea','select','hidden','solomessage','checkboxGroup','radioGroup' (solomessage displays no form element, rather just a mid-form block of text)
		label='',						// string that goes in the label near the element
		value='',						// the defualt value
		isRequired=false,				// mark true if form element is required
		validationRule=''				// specify what rule validation should follow: 'notEmpty','email'
		size=50							// size attr of the element
		maxLength=100					// maxLength attr of the element
		rows=3							// num of rows if type=textarea
		cols=50							// width if type=textarea
		items=''						// a 2-d array of items if type=select: ["optionValue","optionText","optionClass"]; or list of checkboxes in checkbox group: ["checkboxValue","checkBoxLabel","checkBoxClass"]; or radio buttons: ["radioValue","radioLabel","radioClass"]
		class=''						// class assigned to the form element
		labelClass=''					// class assigned to the label
		showVertical=true				// Show radio buttons or checkboxes in a group vertically (if false it's horizontal)
	)
>


CREATE THE ACTUAL FORM (INITIALIZE) WITH THIS (after adding all elements):
<cfoutput>
	#session.formName.init(
		formID='testForm',									// (REQUIRED) id of the form element
		successURL='/admissions/apiTest/confirm.cfm',		// (REQUIRED) url for redirect after form is submitted
		sendToEmail='',										// email (or list of emails) of recipient of form 
		emailSubject='',									// the subject line of said email
		formClass='',										// class assigned to the form element	
		sendToTouchnet=false,								// true if you want to send user to touchnet for payment
		amount='',											// the id of the hidden element that stores the amount sent to touchnet
		upaysiteid='',										// the touchnet site id
		validationKeyPrefix='',								// the prefix used for the validation key
		upaytest=false										// true if you want to test the payment system
	)#
</cfoutput>

THAT'S IT! EASY AS PIE!


--->

<cfcomponent>
	
    <!--- VARS--->
    <cfset variables.formID = ''><!---required as an identifier--->
    <cfset variables.emailAddress = ''><!---if left blank, no email will be sent--->
    <cfset variables.emailSubject = ''>
    <cfset variables.formClass = ''>
    <cfset variables.submitValue = 'Submit'>
    <cfset variables.sendToTouchnet = false>
    <cfset variables.amount = ''>
    <cfset variables.upaysiteid = ''>
    <cfset variables.validationKeyPrefix = ''>
    <cfset variables.upaytest = false>
    
    <!---VARS CREATED BY THE COMPONENT--->
    <cfset variables.elementObjectsArray = ArrayNew(1)><!---an array of element names--->
    <!---<cfset variables.currentURL = "http://" & "#CGI.SERVER_NAME#" & "#CGI.SCRIPT_NAME#">--->
    <cfset variables.currentURL = 
		"http" & 
		iif(CGI.HTTPS EQ "ON", de("s"), de("")) & 
		"://" & 
		CGI.SERVER_NAME & 
		iif ((CGI.HTTPS EQ "ON" AND CGI.SERVER_PORT NEQ 443) OR (CGI.HTTPS NEQ "ON" AND CGI.SERVER_PORT NEQ 80), de(":#CGI.SERVER_PORT#"), de("")) & 
		CGI.SCRIPT_NAME &
		iif(CGI.QUERY_STRING NEQ "", de("?#CGI.QUERY_STRING#"), de(""))
	/>

    <cfset variables.formValid = true>
    <cfset variables.confirmURL = ''>
    <cfset variables.requestNumber = ''>
    
    
    <!---FUNCTIONS///////////////////////////
	--->
    
    
    <!---INITIALIZES THE FORM AND CALLS ALL THE FUNCTIONS IN THE RIGHT ORDER--->
    <cffunction name="init" output="true">
		<cfargument name="formID" type="string" required="true">
		<cfargument name="successURL" type="string" required="true">
		<cfargument name="sendToEmail" type="string" required="false" default="">
		<cfargument name="emailSubject" type="string" required="false" default="">
		<cfargument name="formClass" type="string" required="false" default="">
		<cfargument name="submitValue" type="string" required="false" default="Submit">
		<cfargument name="sendToTouchnet" type="boolean" required="false" default="false">
		<cfargument name="amount" type="string" required="false" default="0">
		<cfargument name="upaysiteid" type="string" required="false" default="">
		<cfargument name="validationKeyPrefix" type="string" required="false" default="">
		<cfargument name="upaytest" type="boolean" required="false" default="false">
        
        
        <cfset variables.formID = arguments.formID>
        <cfset variables.successURL = arguments.successURL>
        <cfset variables.emailAddress = arguments.sendToEmail>
        <cfset variables.emailSubject = arguments.emailSubject>
        <cfset variables.formClass = arguments.formClass>
        <cfset variables.submitValue = arguments.submitValue>
        <cfset variables.sendToTouchnet = arguments.sendToTouchnet>
        <cfset variables.amount = arguments.amount>
        <cfset variables.upaysiteid = arguments.upaysiteid>
        <cfset variables.validationKeyPrefix = arguments.validationKeyPrefix>
        <cfset variables.upaytest = arguments.upaytest>
        
        <cfreturn this> 
	</cffunction>
    
    <cffunction name="prepareData" access="public">
    	
        <!---set the request number in case of touchnet payment--->
        <cfset variables.requestNumber = variables.formID & Right(Replace(CreateUUID(), "-", "", "ALL"), 12)>
        
        <!---create session variables that go in the form--->
        <cfset createSessionVars()>
        
        <cfif IsDefined('form.submitted')>
        	
            
            <!---save all form vars to the session vars--->
            <cfloop from="1" to="#ArrayLen(variables.elementObjectsArray)#" index="i">
            	<cfif variables.elementObjectsArray[i].type neq 'solomessage'>
                	<cfparam name="form.#variables.elementObjectsArray[i].id#" default="#variables.elementObjectsArray[i].value#" /><!---create empty form param--->
            		<cfset session.form[i] = evaluate( "form.#variables.elementObjectsArray[i].id#" )><!---save to session var--->
            		<cfset "session.#variables.formID#.#variables.elementObjectsArray[i].id#" = session.form[i]><!---save value into structure for reference after the form is submitted--->
                </cfif>
            </cfloop>
            
            
            <!---VALIDATE THE DATA--->
            <cfset validateData()>
            
            <!---HANDLE FILE UPLOADS--->
            <cfset handleFiles()>
            
            <!---SEND THE EMAIL--->
            <cfif (LEN(variables.emailAddress) GT 0) AND (variables.formValid eq true) ><!---if an email address is given and the form is valid, send email--->
            	<cfset sendEmail()>
            </cfif>
            
            <!---REDIRECT USER TO NEW PAGE OR PAYMENT SYSTEM--->
            <cfif variables.formValid eq true>
				<cfif variables.sendToTouchnet eq true>
                    <cfset submitTouchnet()>
                <cfelse>
                    <cflocation url="#variables.successURL#" addtoken="no">
                </cfif>
            </cfif>
            
        </cfif>
        
    </cffunction>
    
    <!---CREATES A NEW ELEMENT OBJECT, and saves these objects to an array elementObjectsArray--->
    <cffunction name="addElement" output="true" access="public">
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
		<cfargument name="maxFileSize" type="numeric" required="no" default="0">
		<cfargument name="fileNewName" type="string" required="no" default="">
		<cfargument name="fileDirectory" type="string" required="no" default="">
		<cfargument name="alone" type="boolean" required="no" default="false">
		<cfargument name="match" type="string" required="no" default="">
        
        
        <!---save new item into the elementObectsArray--->
        <cfset ArrayAppend(variables.elementObjectsArray, createObject("component","Element"))>
        <!---initialize (save all data to) this new element object--->
        <cfset variables.elementObjectsArray[#ArrayLen(variables.elementObjectsArray)#].init(
			id='#arguments.id#',
			type='#arguments.type#',
			label='#arguments.label#',
			value='#arguments.value#',
			isRequired='#arguments.isRequired#',
			validationRules='#arguments.validationRules#',
			size='#arguments.size#',
			maxLength='#arguments.maxLength#',
			rows='#arguments.rows#',
			cols='#arguments.cols#',
			items='#arguments.items#',
			class='#arguments.class#',
			labelClass='#arguments.labelClass#',
			showVertical='#arguments.showVertical#',
			minValue='#arguments.minValue#',
			minLength='#arguments.minLength#',
			preHTML='#arguments.preHTML#',
			postHTML='#arguments.postHTML#',
			filetypes='#arguments.filetypes#',
			maxFileSize='#arguments.maxFileSize#',
			fileNewName='#arguments.fileNewName#',
			fileDirectory='#arguments.fileDirectory#',
			alone='#arguments.alone#',
			match='#arguments.match#'
		)>
        
	</cffunction>
    
    <!---CREATE SESSION VARIABLES FOR ALL ELEMENTS--->
    <cffunction name="createSessionVars" output="true" access="private">
        <cfparam name="session.form" type="array" default="#ArrayNew(1)#" />
    	<cfloop from="1" to="#ArrayLen(variables.elementObjectsArray)#" index="s">
        	<!---create the session var and save whatever preset value into the session var--->
        	<cfset session.form[s] = variables.elementObjectsArray[s].value><!---save value into session array for looping in this component--->
            <cfset "session.#variables.formID#.#variables.elementObjectsArray[s].id#" = variables.elementObjectsArray[s].value><!---save value into structure for reference after the form is submitted--->
        </cfloop>
        <cfset "session.#variables.formID#.requestNumber" = variables.requestNumber>
    </cffunction>
    
    <!---OUTPUTS THE HTML--->
    <cffunction name="showForm" output="true">
    	<cfset prepareData()>
        
    	<!---open the form--->
        <cfif variables.formValid eq false>
			<cfoutput><p class="error">Your submission was unsuccessful because some fields have invalid information or are required. Please make sure all fields are correct and try again.</p></cfoutput>
        </cfif>
        <cfoutput>
        	<div class="form-holder">
                <form  name="#variables.formID#" id="#variables.formID#" action="#variables.currentURL#" method="post" class="#variables.formClass#" enctype="multipart/form-data">
                    <fieldset>
            
        </cfoutput>
        
        <!---show the elements:
		- 'text'
		- 'textarea'
		- 'select'
		- 'hidden'
		- 'solomessage'
		- 'checkboxGroup'
		- 'radioGroup'
		--->
    	<cfloop from="1" to="#ArrayLen(variables.elementObjectsArray)#" index="e">
			<cfoutput>
            	<cfif variables.elementObjectsArray[e].type eq 'hidden'>
                		<input id="#variables.elementObjectsArray[e].id#" name="#variables.elementObjectsArray[e].name#" type="hidden" value="#session.form[e]#" class="#variables.elementObjectsArray[e].class#" />
                <cfelseif variables.elementObjectsArray[e].type eq 'solomessage'>
                		#variables.elementObjectsArray[e].value#
            	<cfelse>
                	<cfif variables.elementObjectsArray[e].alone eq false><!---only show surrounding html if alone is false--->
                		<div class="form-elements">
                            <div class="left-element">
                                <label for="#variables.elementObjectsArray[e].id#" class="#variables.elementObjectsArray[e].labelClass# <cfif variables.elementObjectsArray[e].validStatus EQ FALSE> error </cfif>" >
                                	<cfif variables.elementObjectsArray[e].isRequired EQ true>*</cfif>#variables.elementObjectsArray[e].label#
                                </label>
                            </div>
                            <div class="right-element">
                    <cfelse>
                    	<cfif variables.elementObjectsArray[e].label neq ''><span class="#variables.elementObjectsArray[e].labelClass# <cfif variables.elementObjectsArray[e].validStatus EQ FALSE> error </cfif>"><cfif variables.elementObjectsArray[e].isRequired EQ true>*</cfif>#variables.elementObjectsArray[e].label#</span></cfif>
                    </cfif>
                            	#variables.elementObjectsArray[e].preHTML#
                            	<cfif variables.elementObjectsArray[e].type eq 'text'>
                                	<input id="#variables.elementObjectsArray[e].id#" name="#variables.elementObjectsArray[e].name#" type="text" size="#variables.elementObjectsArray[e].size#" maxlength="#variables.elementObjectsArray[e].maxLength#" value="#session.form[e]#" class="#variables.elementObjectsArray[e].class#" <cfif variables.elementObjectsArray[e].isRequired eq true>required</cfif> >
                                <cfelseif variables.elementObjectsArray[e].type eq 'password'>
                                	<input id="#variables.elementObjectsArray[e].id#" name="#variables.elementObjectsArray[e].name#" type="password" size="#variables.elementObjectsArray[e].size#" maxlength="#variables.elementObjectsArray[e].maxLength#" value="#session.form[e]#" class="#variables.elementObjectsArray[e].class#" <cfif variables.elementObjectsArray[e].isRequired eq true>required</cfif>>
                                <cfelseif variables.elementObjectsArray[e].type eq 'color'>
									<input id="#variables.elementObjectsArray[e].id#" name="#variables.elementObjectsArray[e].name#" type="color" size="#variables.elementObjectsArray[e].size#" maxlength="#variables.elementObjectsArray[e].maxLength#" value="#session.form[e]#" class="#variables.elementObjectsArray[e].class#" <cfif variables.elementObjectsArray[e].isRequired eq true>required</cfif>>
								<cfelseif variables.elementObjectsArray[e].type eq 'textarea'>
                                	<textarea id="#variables.elementObjectsArray[e].id#" name="#variables.elementObjectsArray[e].name#" rows="#variables.elementObjectsArray[e].rows#" cols="#variables.elementObjectsArray[e].cols#" class="#variables.elementObjectsArray[e].class#" <cfif variables.elementObjectsArray[e].isRequired eq true>required</cfif>>#session.form[e]#</textarea>
                                <cfelseif variables.elementObjectsArray[e].type eq 'select'>
                                	<select id="#variables.elementObjectsArray[e].id#" name="#variables.elementObjectsArray[e].name#" class="#variables.elementObjectsArray[e].class#" <cfif variables.elementObjectsArray[e].isRequired eq true>required</cfif>>
                                        <option value="" <cfif session.form[e] EQ "">selected="selected"</cfif>> - Select - </option>
                                        <cfloop from="1" to="#ArrayLen(variables.elementObjectsArray[e].items)#" index="o">
                                        	<option <cfif ArrayLen(variables.elementObjectsArray[e].items[o]) eq 3>class="#variables.elementObjectsArray[e].items[o][3]#"</cfif> value="#variables.elementObjectsArray[e].items[o][1]#" <cfif session.form[e] EQ "#variables.elementObjectsArray[e].items[o][1]#">selected="selected"</cfif>> #variables.elementObjectsArray[e].items[o][2]# </option>
                                        </cfloop>
                                    </select>
                                <cfelseif variables.elementObjectsArray[e].type eq 'checkboxGroup'>
                                	<cfloop from="1" to="#ArrayLen(variables.elementObjectsArray[e].items)#" index="c">
                                    	<cfset checkboxChecked = false>
                                        <cfif ListFind(session.form[e],variables.elementObjectsArray[e].items[c][1]) gt 0>
											<cfset checkboxChecked = true>
                                        </cfif>
                                    	<input id="#variables.elementObjectsArray[e].id#_#c#" name="#variables.elementObjectsArray[e].name#" type="checkbox" value="#variables.elementObjectsArray[e].items[c][1]#" <cfif checkboxChecked>checked="checked"</cfif> <cfif variables.elementObjectsArray[e].isRequired eq true AND c eq 1>required</cfif> /> <label for="#variables.elementObjectsArray[e].id#_#c#">#variables.elementObjectsArray[e].items[c][2]#</label>
                                    	<cfif variables.elementObjectsArray[e].showVertical eq true AND ArrayLen(variables.elementObjectsArray[e].items) neq 1><br \></cfif>
                                    </cfloop>
                                <cfelseif variables.elementObjectsArray[e].type eq 'radioGroup'>
                                	<cfloop from="1" to="#ArrayLen(variables.elementObjectsArray[e].items)#" index="r">
                                    	<input id="#variables.elementObjectsArray[e].id#_#r#" name="#variables.elementObjectsArray[e].name#" type="radio" value="#variables.elementObjectsArray[e].items[r][1]#" <cfif session.form[e] EQ "#variables.elementObjectsArray[e].items[r][1]#">checked="checked"</cfif> <cfif variables.elementObjectsArray[e].isRequired eq true AND c eq 1>required</cfif> /> #variables.elementObjectsArray[e].items[r][2]#
                                    	<cfif variables.elementObjectsArray[e].showVertical eq true AND ArrayLen(variables.elementObjectsArray[e].items) neq 1><br \></cfif>
                                    </cfloop>
                                <cfelseif variables.elementObjectsArray[e].type eq 'file'>
                                	<input type="file" name="#variables.elementObjectsArray[e].name#" id="#variables.elementObjectsArray[e].id#" value="#session.form[e]#" size="#variables.elementObjectsArray[e].size#" maxlength="#variables.elementObjectsArray[e].maxLength#" class="#variables.elementObjectsArray[e].class#" <cfif variables.elementObjectsArray[e].isRequired eq true>required</cfif> />
                                </cfif>
                            	#variables.elementObjectsArray[e].postHTML#
                	<cfif variables.elementObjectsArray[e].alone eq false><!---only show surrounding html if alone is false--->
                            </div>
                        </div>
                        <div class="clear"></div>
                    </cfif>
                </cfif>
			</cfoutput>
        </cfloop>
        
        <!---close the form--->
        <cfoutput>
                    </fieldset>
                    <div class="buttonbox">
                        <input type="hidden" name="submittedDate" id="submittedDate" value="<cfoutput>#now()#</cfoutput>" />
                        <span id="submit"><input name="submitted" type="submit" value="<cfoutput>#variables.submitValue#</cfoutput>"></span>
                    </div>
                    
                    <div class="clear"></div>
                </form>
            </div><!--/form-holder-->
        </cfoutput>
        
    </cffunction>
    
    <!---VALIDATE THE DATA--->
    <cffunction name="validateData" output="false" access="private">
    	<!---validation rules are:
        - 'notEmpty'
        - 'email'
        --->
    	<cfloop from="1" to="#ArrayLen(variables.elementObjectsArray)#" index="v">
        	<cfif variables.elementObjectsArray[v].isRequired eq true><!---if it is required --->
            	<cfif session.form[v] IS "" OR session.form[v] IS " ">
					<cfset variables.elementObjectsArray[v].validStatus = FALSE>
                    <cfset variables.formValid = false>
                </cfif>
            </cfif>
            <!---loop through validation rules array--->
            <cfloop from="1" to="#ArrayLen(variables.elementObjectsArray[v].validationRules)#" index="r">
				<cfif variables.elementObjectsArray[v].validationRules[r] eq 'notEmpty'>
                    <cfif session.form[v] IS "" OR session.form[v] IS " ">
                        <cfset variables.elementObjectsArray[v].validStatus = FALSE>
                        <cfset variables.formValid = false>
                    </cfif>
                </cfif>
                <cfif variables.elementObjectsArray[v].validationRules[r] eq 'email'>
                    <cfif LEN(session.form[v]) GT 0>
                        <cfif (LEN(session.form[v]) LT 8) OR (FindNoCase("@", session.form[v]) LTE 0) OR (FindNoCase(".", session.form[v]) LTE 0)>
                            <cfset variables.elementObjectsArray[v].validStatus = FALSE>
                            <cfset variables.formValid = false>
                        </cfif>
                    </cfif>
                </cfif>
                <cfif variables.elementObjectsArray[v].validationRules[r] eq 'minValue'>
                    <cfif session.form[v] LT variables.elementObjectsArray[v].minValue>
                        <cfset variables.elementObjectsArray[v].validStatus = FALSE>
                        <cfset variables.formValid = false>
                    </cfif>
                </cfif>
                <cfif variables.elementObjectsArray[v].validationRules[r] eq 'minLength'>
                    <cfif LEN(session.form[v]) LT variables.elementObjectsArray[v].minLength>
                        <cfset variables.elementObjectsArray[v].validStatus = FALSE>
                        <cfset variables.formValid = false>
                    </cfif>
                </cfif>
                <cfif variables.elementObjectsArray[v].validationRules[r] eq 'number'>
                    <cfif IsValid('float',session.form[v]) eq false>
                        <cfset variables.elementObjectsArray[v].validStatus = FALSE>
                        <cfset variables.formValid = false>
                    </cfif>
                </cfif>
                <cfif variables.elementObjectsArray[v].validationRules[r] eq 'match'>
					<cfif (session.form[v] neq evaluate('session.#variables.formID#.#variables.elementObjectsArray[v].match#'))>
                        <cfset variables.elementObjectsArray[v].validStatus = FALSE>
                        <cfset variables.formValid = false>
                    </cfif>
                </cfif>                
                
            </cfloop><!---end loop through rules--->
            
        </cfloop><!---end loop through elements--->
        
    </cffunction>
    
    <!---PROCESS FILE UPLOADS--->
    <cffunction name="handleFiles" output="true" access="private">
    
    	<cfloop from="1" to="#ArrayLen(variables.elementObjectsArray)#" index="e">
            <cfif variables.elementObjectsArray[e].type eq 'file'>
            
				<cfif NOT Len( session.form[e] )>
                    <!---do nothing--->
                <cfelse><!---something was added--->
                        
                    <cfset fileInstance = variables.elementObjectsArray[e].id>
                    
                    
                    <cffile
                    result="#fileInstance#"
                    action="upload"
                    filefield="#fileInstance#"
                    destination="#GetTempDirectory()#"
                    nameconflict="makeunique"
                    />
                    
                    <!---check file extension--->
                    <cfif LEN(variables.elementObjectsArray[e].filetypes)>
						<cfif NOT ListFindNoCase(
                        variables.elementObjectsArray[e].filetypes,
                        evaluate("#fileInstance#.ServerFileExt")
                        )>
                             
                            <cfset variables.elementObjectsArray[e].validStatus = FALSE>
                            <cfset variables.formValid = false>
                            <cfset variables.elementObjectsArray[e].postHTML = variables.elementObjectsArray[e].postHTML&' <span class="error">Incorrect File Type</span> '>
                             
                            <!---
                            Since this was not an acceptable file,
                            let's delete the one that was uploaded.
                            --->
                            <!---<cftry>
                            <cffile
                            action="DELETE"
                            file="#GetTempDirectory()#/#variables.elementObjectsArray[e].id.ServerFile#"
                            />
                             
                            <cfcatch>
                            <!--- File Delete Error. --->
                            </cfcatch>
                            </cftry>--->
                             
                        </cfif><!---end if the wrong file extension--->
                    </cfif><!---end if filetypes were defined--->
                    
                    <!---check file size--->
                    <cfif variables.elementObjectsArray[e].maxFileSize gt 0>
                    	<cfif evaluate("#fileInstance#.fileSize") gt variables.elementObjectsArray[e].maxFileSize>
                        	<cfset variables.elementObjectsArray[e].validStatus = FALSE>
                            <cfset variables.formValid = false>
                            <cfset variables.elementObjectsArray[e].postHTML = variables.elementObjectsArray[e].postHTML&' <span class="error">File too large</span> '>
                            <!---delete the file--->
                        </cfif>
                    </cfif>
                    
                    <cfif variables.elementObjectsArray[e].validStatus><!---the file is valid--->
                    	
                        <!---figure out destination path--->
						<cfif LEN(variables.elementObjectsArray[e].fileDirectory) gt 0>
                            <cfset destinationPath = expandPath(variables.elementObjectsArray[e].fileDirectory)>
                        <cfelse>
                        	<cfset destinationPath = GetTempDirectory() & '/'>
                        </cfif>
                        
						<!---move the file--->
                        <cfif LEN(variables.elementObjectsArray[e].fileDirectory) gt 0>
                            <cfset originalSource = GetTempDirectory() & evaluate("#fileInstance#.ServerFile")>
                            <cffile
                                action="copy"
                                source="#originalSource#"
                                destination="#destinationPath#"
                            >
                        </cfif>
                        
                        <!---rename the file--->
                        <cfif LEN(variables.elementObjectsArray[e].fileNewName) gt 0>
                            <cfset originalFilename = destinationPath & evaluate("#fileInstance#.ServerFile")>
                            <cfset newFilename = destinationPath & variables.elementObjectsArray[e].fileNewName &'.'& evaluate("#fileInstance#.serverFileExt")>
                            <cffile
                                action="rename"
                                source="#originalFilename#"
                                destination="#newFilename#"
                            >
                        </cfif>
                        
                        <!---set value as filename saved--->
                        <cfif LEN(variables.elementObjectsArray[e].fileNewName) gt 0>
                        	<cfset "session.#variables.formID#.#variables.elementObjectsArray[e].id#" = fileNewName &'.'& evaluate("#fileInstance#.serverFileExt")>
                        <cfelse>
                        	<cfset "session.#variables.formID#.#variables.elementObjectsArray[e].id#" = evaluate("#fileInstance#.ServerFile")>
                        </cfif>
                        <!---<cfset tmp = evaluate("#fileInstance#.ServerFile")>
                        <cfdump var="#tmp#">--->
                        
                            
                    </cfif><!---///file is valid--->
                    
                    <!---save the temp path--->
                    <cfset variables.elementObjectsArray[e].tempFilePath = ( evaluate("#fileInstance#.serverDirectory") & "/" & evaluate("#fileInstance#.ServerFile") ) />
                    
                    
                    
                    
            	</cfif> <!---end if a file was added to the file field--->
                
            </cfif> <!---end if this is a file--->
            
        
        </cfloop><!---end loop through elements--->
    </cffunction>
    
    <!---EMAIL THE FORM--->
    <cffunction name="sendEmail" output="true" access="private">
    	
        <cfmail type="html" to="#variables.emailAddress#" from="Utah State University <do-not-reply@usu.edu>" subject="#variables.emailSubject#">
        	An online form has been submitted:<br>
            <br>
            Submission Time: #dateformat(now(), "mmmm dd, yyyy")# - #TimeFormat(now(), "hh:mm tt")#<br />
            Request Number : #variables.requestNumber#<br>
            <br>
            <cfloop from="1" to="#ArrayLen(variables.elementObjectsArray)#" index="i">
            	<cfif variables.elementObjectsArray[i].type neq 'solomessage'>
					<cfset myValue = evaluate( "form.#variables.elementObjectsArray[i].name#" )>
                    <cfif variables.elementObjectsArray[i].type eq 'hidden'>
                    	#variables.elementObjectsArray[i].id#: #myValue#<br>
                    <cfelseif variables.elementObjectsArray[i].type eq 'checkboxGroup'>
                    	<cfif len(variables.elementObjectsArray[i].label) gt 0>
                        	#variables.elementObjectsArray[i].label#:
                        <cfelse>
                        	#variables.elementObjectsArray[i].id#:
                        </cfif>
                        <br>
                        <cfloop index="c" list="#myValue#"><!---checkbox values are returned as an array or list--->
                        	<cfloop from="1" to="#ArrayLen(variables.elementObjectsArray[i].items)#" index="z"><!---compare this value with the items array to get the label for readability--->
                            	<cfif variables.elementObjectsArray[i].items[z][1] eq c>
                                	#c# - #variables.elementObjectsArray[i].items[z][2]#
                                </cfif>
                            </cfloop>
                            <br \>
                        </cfloop>
                    <cfelseif variables.elementObjectsArray[i].type eq 'radioGroup'>
                    	<cfif len(variables.elementObjectsArray[i].label) gt 0>
                        	#variables.elementObjectsArray[i].label#:
                        <cfelse>
                        	#variables.elementObjectsArray[i].id#:
                        </cfif>
                        <cfloop from="1" to="#ArrayLen(variables.elementObjectsArray[i].items)#" index="r">
                        	<cfif variables.elementObjectsArray[i].items[r][1] eq myValue>
                                #myValue# - #variables.elementObjectsArray[i].items[r][2]#
                            </cfif>
                        </cfloop>
                        <br \>
                	<cfelseif variables.elementObjectsArray[i].type eq 'file'>
                    	<cfif LEN(variables.elementObjectsArray[i].tempFilePath)>
                			<cfmailparam file="#variables.elementObjectsArray[i].tempFilePath#" />
                        </cfif>
                    <cfelse>
                    	<cfif len(variables.elementObjectsArray[i].label) gt 0>
                        	#variables.elementObjectsArray[i].label#:
                        <cfelse>
                        	#variables.elementObjectsArray[i].id#:
                        </cfif>
                         #myValue#<br>
                    </cfif>
                </cfif>
            </cfloop>
        </cfmail>
        
    </cffunction>
    
    
    <!---SEND INFO TO TOUCHNET PAYMENT GATEWAY--->
    <cffunction name="submitTouchnet" output="true" access="private">
    	
        <cfset myAmount = evaluate( "form.#variables.amount#" )>
        <cfif myAmount gt 0>
			<!---- Online Payment Code --->
            <cfoutput>
               <!--- Set validation Key --->
               <cfset str_to_encrypt = "#variables.validationKeyPrefix##variables.requestNumber##myAmount#"/> 
             
               <!--- Encrypt string --->
               <cfset md5 = LCase(Hash(str_to_encrypt)) />
               <cfset hex = BinaryDecode(md5, 'Hex') />
               <cfset key = ToBase64(hex) />
               
               <cfif variables.upaytest eq true>
                    <cfset portVar = ':8443'><!--- for live site portVar is nothing, test site: :8443 --->
                    <cfset stringVar = 'C20241test_upay'><!--- for live site stringVar = C20241_upay, test site: ' C20241test_upay ' --->
               <cfelse>
                    <cfset portVar = ''>
                    <cfset stringVar = 'C20241_upay'>
               </cfif>
                
                <!--- https://secure.touchnet.com:8443/C20241test_upay/web/index.jsp -- upay site ID for live site:7 - for test site: 12 (these values for ASUSU only)--->
               <cfhttp url="https://secure.touchnet.com#portVar#/#stringVar#/web/index.jsp" method="post" resolveurl="false">
                <cfhttpparam type="formfield" name="UPAY_SITE_ID" value="#variables.upaysiteid#"/>
                <cfhttpparam type="formfield" name="BILL_NAME" value=""/>
                <cfhttpparam type="formfield" name="BILL_EMAIL_ADDRESS" value=""/>
                <cfhttpparam type="formfield" name="BILL_STREET1" value=""/>
                <cfhttpparam type="formfield" name="BILL_CITY" value=""/>
                <cfhttpparam type="formfield" name="BILL_STATE" value=""/>
                <cfhttpparam type="formfield" name="BILL_POSTAL_CODE" value=""/>
                <cfhttpparam type="formfield" name="EXT_TRANS_ID" value="#variables.requestNumber#"/>
                <cfhttpparam type="formfield" name="AMT" value="#myAmount#"/>
                <cfhttpparam type="formfield" name="VALIDATION_KEY" value="#key#"/>
                <cfhttpparam type="formfield" name="SUCCESS_LINK" value="#variables.successURL#?success">
                <cfhttpparam type="formfield" name="CANCEL_LINK" value="#variables.successURL#?cancel">
                <cfhttpparam type="formfield" name="ERROR_LINK" value="#variables.successURL#?error">
                <cfhttpparam type="formfield" name="formID" value="#variables.formID#"/>
               </cfhttp>
                <cfset httpReturned = replace(cfhttp.FileContent, 'action="', 'action="https&##x3a;&##x2f;&##x2f;secure.touchnet.com#portVar#')/>
                #httpReturned#
            </cfoutput>
            <cfabort>
            <!---- End Online Payment Code --->
    	<cfelse><!---no amount was given (free registration)--->
        	<cflocation url="#variables.successURL#?success" addtoken="no">
        </cfif>
    </cffunction>
    
</cfcomponent>



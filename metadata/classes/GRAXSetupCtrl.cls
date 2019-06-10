/* --------------------------------------------------------------------------
 * This file is subject to the terms and conditions defined in
 * file https://github.com/HardingPoint/GRAXForSFDC/blob/master/LICENSE,
 * which is part of this source code package.
 * --------------------------------------------------------------------------
 *          Copyright (c) 2017-2018 Harding Point
 *                  All rights reserved
 * --------------------------------------------------------------------------
 * Support:	Support@Grax.io
 * Website:	https://grax.io
 * Github:	https://github.com/HardingPoint/GRAXForSFDC
 * License:	https://github.com/HardingPoint/GRAXForSFDC/blob/master/LICENSE
 * --------------------------------------------------------------------------*/
 
/*****************************************************************************************
Name              : GRAXSetupCtrl
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
2. Leandro Brunner       08/23/2018             David Mackey        Create necessary "Permission Sets" (https://app.asana.com/0/326600806074978/749901377818186/f)
4. Ariel Yankelevich     05/07/2019           	David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
5. Nicolas Ralero			05/09/2019			David Mackey		Create Scheduled Jobs Upon Package Install (https://app.asana.com/0/1118660079719641/1105533057427274/f)
******************************************************************************************/

public with sharing class GRAXSetupCtrl {
    // DEPLOY
    String LastAppName = '';
    
    public GRAXSettings gxs {get;set;}
        
    public String warningMessage {get; set;}
    public String infoMessage {get; set;}
    public List<String> errorMessages {get; set;}

    public String scheduledJobsContextUserName {get; set;}
    
    public string graxconfig {get;set;}
    public boolean isauthorized {get;set;}
    public boolean isconfigured {get;set;}
    public boolean appselectdisabled {get;set;}
    public boolean disableeverything {get;set;}
    
    public boolean appselected {
        get {
            if (gxs.ProperlyConfigured == true)
                return true;
            else
                return false;
        }
        set;
    }
    
    public string actiontext {get;set;}
    public string actionbuttontext {get;set;}
    public string graxapp {get;set;}
    public string graxappJSON {get;set;}
    public boolean disablefielauditddeploy {get;set;}
    public List<SelectOption> graxapps {get;set;}

    public static String nsPrefix {
        get {
            String ns = GRAXUtils.getPureNameSpace();

            return String.isNotBlank(ns) ? ns + '.' : '';
        }
    }

    public static GRAXPermissions gp {
        get {
            return new GRAXPermissions(UserInfo.getUserId());
        }
    }

    public String userLocale {get;set;}
    public String userTimeZone {get;set;}
    public string objToQuery {get;set;}

    private String schedulerToCleanDataRecords = 'GRAXSchedulerToCleanDataRecords';
    private String schedulerToResendDataRecords = 'GRAXSchedulerToResendDataRecords';
    private String schedulerToProcessSchedJobs = 'GRAXSchedulerToProcessSchedJobs';
    private String schedulerToDeleteBackedUpData = 'GRAXSchedulerToDeleteBackedUpData';
    // private static String schedulerToProcessDynamicFlow = 'GRAXSchedulerToProcessDynamicFlow';

    public GRAXSetupCtrl() {
        // DEPLOY
        errorMessages = new List<String>();

        gxs = new GRAXSettings();
        System.Debug('[GRAX.io] Saved GRAX App: ' + gxs.graxConfig.Heroku_App_Name__c);
        
        actiontext = 'Save';
        actionbuttontext = 'Save GRAX Settings';
        
        disablefielauditddeploy = true;
        
        appselectdisabled = true;
        graxapps = new List<SelectOption>(); 
        graxapps.add(new SelectOption('','-- Choose Heroku Application --'));
        graxconfig = GetConfig();
        graxapps = ParseJSON();
        isauthorized = String.isNotBlank(graxconfig); // && graxapps.size() > 0;

        System.debug(gp.getIsAdmin());
        System.debug(gxs.ProperlyConfigured);

        if(!gp.getIsAdmin() && !gxs.ProperlyConfigured) {
            generatePageMessage('GRAX Configuration has not been completed. Please contact your System Administrator.', 'WARNING');            
        } else if (!gxs.ProperlyConfigured) {
            generatePageMessage('Please Select Application.', 'INFO');
        }

        /*if(gxs.ProperlyConfigured && String.isBlank(graxconfig)) {
            generatePageMessage('Can\'t connect to Heroku. Please contact your System Administrator.', 'WARNING');
        }*/
        
        LockSettings(gxs.ProperlyConfigured);

        userLocale = UserInfo.getLocale();
        userTimeZone = UserInfo.getTimeZone().getID();
        
        objToQuery = '';        
    }

    /*****************************************************************************************
    Name              : verifySchedules
    Description       : 
    Revision History  :
    Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
    ----------------------------------------------------------------------------------------
    1. Leandro Brunner       04/18/2018             David Mackey        https://app.asana.com/0/326600806074978/633149554508924/f
    ******************************************************************************************/
    public void verifySchedules() {
        try{
            Set<String> crons = new Set<String>();
            Id currentScheduleJobUserId;
    
            // Get CronTiggers if exist, and add Name to the Set.
            for(CronTrigger ct : [SELECT Id, OwnerId, CronJobDetail.Name FROM CronTrigger
                                    WHERE CronJobDetail.Name IN :new List<String>{
                                            schedulerToCleanDataRecords,
                                            schedulerToResendDataRecords + '0', schedulerToResendDataRecords + '1',
                                            schedulerToProcessSchedJobs,
                                            schedulerToDeleteBackedUpData
                                            //schedulerToProcessDynamicFlow + '0', schedulerToProcessDynamicFlow + '1'
                }
            ]) {
                currentScheduleJobUserId = ct.OwnerId;
                crons.add(ct.CronJobDetail.Name);
            }
    
            // Check if one of the relevant APEX Scheduled Jobs, is not currently active
            List<String> missingScheduleJobNames = new List<String>();
            for(String jobName : new List<String>{schedulerToCleanDataRecords, schedulerToResendDataRecords + '0', schedulerToResendDataRecords + '1', schedulerToProcessSchedJobs, schedulerToDeleteBackedUpData}){
                if(!crons.contains(jobName)){
                    missingScheduleJobNames.add(jobName);
                }
            }
    
            // If, at least, one of the APEX Scheduled Jobs, is missed, then display an error message
            if(!missingScheduleJobNames.isEmpty()){
                errorMessages.add('You currently have unscheduled jobs. Please go to the GRAX Configuration tab, click the "Unlock" button, APEX Scheduled Jobs section, and click "Activate Scheduled Jobs".');
            }
    
            // Query relevant information about the User that is currently defined as the GRAX APEX Scheduled Jobs' running User
            List<User> currentScheduleJobUsers = [SELECT Id, isActive, Name FROM User WHERE Id =: currentScheduleJobUserId];
    
            // Check if the GRAX APEX Scheduled Jobs' running User is "Inactive", and then, display an error message, if needed
            if(!currentScheduleJobUsers.isEmpty()){
                scheduledJobsContextUserName = currentScheduleJobUsers[0].Name;
                if (!currentScheduleJobUsers[0].isActive) {
                    errorMessages.add('The GRAX processes running user is inactive. Please go to the GRAX Configuration tab, click the "Unlock" button, APEX Scheduled Jobs section, and click "Activate Scheduled Jobs".');
                }
            }
    
            // Display a generic error message, when errors were found, in the previous steps, and the current User, is not a GRAX Admin User
            if(!gp.getIsAdmin() && !errorMessages.isEmpty()) {
                errorMessages.add('You currently have unscheduled jobs. Please contact your GRAX Admin to assist in scheduling the required GRAX processes');
            }
        }catch(Exception e) {
            errorMessages.add(e.getMessage());       
        }
    }

    public PageReference saveScheduleJobs(){
        errorMessages = new List<String>();
        warningMessage = '';
        infoMessage = '';

        try{
            // Get CronTiggers if exist, and abort them, in order to re-schedule them with the running User
            for(CronTrigger ct : [SELECT Id FROM CronTrigger WHERE CronJobDetail.Name IN :new List<String>{schedulerToCleanDataRecords, schedulerToResendDataRecords + '0', schedulerToResendDataRecords + '1', schedulerToProcessSchedJobs, schedulerToDeleteBackedUpData /*, schedulerToProcessDynamicFlow + '0', schedulerToProcessDynamicFlow + '1' */ }]){
                System.abortJob(ct.Id);
            }

            // Schedule the "GRAXSchedulerToCleanDataRecords" job, to run it every hour at minute 45
            System.schedule(schedulerToCleanDataRecords, '0 45 * * * ?', new GRAXSchedulerToCleanDataRecords());

            // Schedule the "GRAXSchedulerToResendDataRecords" job, to run every 30 mins
            Integer minutesFactor = 30;
            String cronExpression = '';
    
            for(Integer i = 0; i < 2; i++){
                cronExpression = '0 '+ String.valueOf(i * minutesFactor) + ' * * * ?';

                System.schedule(schedulerToResendDataRecords + String.valueOf(i), cronExpression, new GRAXSchedulerToResendDataRecords());
            }
            
            // Schedule the "GRAXSchedulerToProcessSchedJob" job, to run hourly
            System.schedule(schedulerToProcessSchedJobs, '0 0 * * * ?', new GRAXSchedulerToProcessSchedJobs());

            // Schedule the "GRAXSchedulerToDeleteBackedUpData" job, to run hourly
            System.schedule(schedulerToDeleteBackedUpData, '0 0 * * * ?', new GRAXSchedulerToDeleteBackedUpData());

            // Schedule the "GRAXSchedulerToProcessDynamicFlow" job, to run every 30 minutes
            //for(Integer i = 0; i < 2; i++){
                // cronExpression = '0 '+ String.valueOf(i * minutesFactor) + ' * * * ?';

                // System.schedule(schedulerToProcessDynamicFlow + String.valueOf(i), cronExpression, new GRAXSchedulerToProcessDynamicFlow());
            //}

            // Set the "Scheduled Jobs Context User Name", to be the current User Name
            scheduledJobsContextUserName = UserInfo.getName();

            // Lock the sections, and display a message that the "Scheduled Jobs" has been properly enabled
            LockSettings(true);
            generatePageMessage('Schedule jobs successfuly enabled', 'INFO');            
        }catch(AsyncException e){
            errorMessages.add('This SF environment has reached its maximum number of scheduled APEX Jobs. Please try scheduling again.');
        }catch(Exception e) {
            errorMessages.add(e.getMessage());
        }
        PageReference pageRef = new pagereference(ApexPages.currentPage().getUrl());
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public pagereference AuthorizeHeroku(){
		return new pagereference(GetUrl('/platforms/heroku/oauth/authorize', 'https://api.grax.io/test/api', new Map<String, String> {
            'callbackUrl' => 'https://' + URL.getSalesforceBaseUrl().getHost() + (
                UserInfo.getUiThemeDisplayed().startsWith('Theme4') ? '/lightning/n/' + GRAXUtils.getNameSpacePrefix() + 'GRAX_DEPLOY' : Page.GRAXSetup.getUrl())
        }));
    }

	    public void LockSettings(Boolean LockFlag){
        if (LockFlag){
            errorMessages = new List<String>();
            
            actiontext = 'GRAX Settings';
            actionbuttontext = 'Unlock';
            disableeverything = true;
            graxapp = gxs.graxConfig.Heroku_App_Name__c;
            if(gp.getIsAdmin()) {
                generatePageMessage('GRAX Settings Locked', 'INFO');                
            }

            verifySchedules();
            LoadAuditTrail();
        }else{
            actiontext = 'GRAX Settings';
            actionbuttontext = 'Save';
            disableeverything = false;
            if(gp.getIsAdmin()) {
                generatePageMessage('GRAX Settings Unlocked', 'INFO');                
            }
        }
    }
    
    public void LoadAuditTrail(){
        if (gxs.graxConfig.Postgres_URL__c!=''){
                GRAXAuditTrail audittrail = new GRAXAuditTrail();
                    String auditsettings = audittrail.GetAuditSettings(gxs.graxConfig.Postgres_URL__c);
                    if (auditsettings.indexOf('Unauthorized endpoint')!=-1){
                        System.Debug('[GRAX.io] auditsettings: ' + auditsettings);
                        if(gp.getIsAdmin()) {
                            errorMessages.add('Please Add Remote Site: ' + gxs.graxConfig.GRAX_API_Url__c);
                        } else {
                            generatePageMessage('GRAX Configuration has not been completed. Please contact your System Administrator.', 'WARNING');
                        }
                    }
                    if (audittrail.numberoftables == 0)
                        disablefielauditddeploy = false;
                    else
                        disablefielauditddeploy = true;
        }
    }
    
    public pagereference UpdateAuditTrail(){
        gxs.UpdateSettings();
        LoadAuditTrail();
        return null;
    }        
    
         
    public pagereference UpdateCustomSettings(){
		pagereference pageRef;

        System.Debug('[GRAX.io] Saving Configuration gxs.graxConfig.ApiToken__c!: ' + gxs.graxConfig.ApiToken__c);
        System.Debug('[GRAX.io] Saving Configuration gxs.graxConfig.LicenseToken__c!: ' + gxs.graxConfig.LicenseToken__c);
        System.Debug('[GRAX.io] Saving Configuration gxs.graxConfig.graphdburl__c!: ' + gxs.graxConfig.graphdburl__c);
        if (actionbuttontext=='Save'){
            if(String.isBlank(gxs.graxConfig.GRAX_API_Url__c) && String.isNotBlank(gxs.graxConfig.Heroku_App_Name__c)) {
                gxs.graxConfig.GRAX_API_Url__c = 'https://' + gxs.graxConfig.Heroku_App_Name__c + '.herokuapp.com/graxproxy/api';
            }
            if (gxs.graxConfig.ApiToken__c!='' && gxs.graxConfig.GatewayToken__c!='' && gxs.graxConfig.LicenseToken__c!=''){
                System.Debug('[GRAX.io] Saving Configuration: ' + gxs.graxConfig.Heroku_App_Name__c);
                gxs.UpdateSettings();
                generatePageMessage('Saved GRAX Settings.', 'INFO');                
            }else
                System.Debug('[GRAX.io] Saving Configuration SKIPPED: ' + gxs.graxConfig.Heroku_App_Name__c);
            LockSettings(true);

            pageRef = new pagereference(ApexPages.currentPage().getUrl());
            pageRef.setRedirect(true);
        }
        else{
            LockSettings(false);
            System.Debug('[GRAX.io] Saving Configuration SKIPPED: ' + gxs.graxConfig.Heroku_App_Name__c);
        
            pageRef = null;
        }

        return pageRef;
    }
    
    public pagereference CreateParitions(){
        if (gxs.graxConfig.Postgres_URL__c!=''){
            GRAXAuditTrail audittrail = new GRAXAuditTrail();
                audittrail.CreateAuditSettings(gxs.graxConfig.Postgres_URL__c,1000);
            }
        return null;
    }
    
    public pagereference DropParitions(){
        if (gxs.graxConfig.Postgres_URL__c!=''){
            GRAXAuditTrail audittrail = new GRAXAuditTrail();
                audittrail.DropAuditParitions(gxs.graxConfig.Postgres_URL__c,1000);
            }
        return null;
    }
    
    public pagereference LoginToHeroku(){
        pagereference p = new pagereference('https://id.heroku.com/login');
        return p;
    }
    
    public pagereference SignUpHeroku(){
        pagereference p = new pagereference('https://signup.heroku.com/?c=70130000001x9jFAAQ');
        return p;
    }
    
    public pagereference DeployGraxApp(){
        pagereference p = new pagereference(gxs.GRAXDeployURL);
        return p;
    }

    public pagereference DeploySelectedApp(){
        pagereference p = new pagereference(gxs.GRAXDeployURL); 
        return p;
    }
    
    public String GetConfig(){
        GRAXCloud.CallOutResponse callout = GRAXCloud.doHTTP('GET', null, GetUrl('/platforms/heroku/getconfig','https://api.grax.io/test/api'), null);
        if(callout.success) {
            return callout.response;
        }

        return graxconfig;
    }
    
 	private String GetUrl(string path,string apiurl, Map<String, Object> extraParams){
        String Url = apiurl + path + '?';
        Url += 'orgid=' + EncodingUtil.urlEncode(UserInfo.getOrganizationId(),'UTF-8');
        Url += '&userid=' + EncodingUtil.urlEncode(UserInfo.getUserId(),'UTF-8');
            
        if (ApexPages.currentPage().getHeaders().get('Host')!=null) {
            Url += '&host=' + EncodingUtil.urlEncode(ApexPages.currentPage().getHeaders().get('Host'),'UTF-8');
        }
            
        if (UserInfo.getOrganizationName()!=null) {
            Url += '&companyname=' + EncodingUtil.urlEncode(UserInfo.getOrganizationName(),'UTF-8');
                
            if (UserInfo.getFirstName()!=null) {
                Url += '&firstname=' + EncodingUtil.urlEncode(UserInfo.getFirstName(),'UTF-8');
            }
                
            if (UserInfo.getLastName()!=null) {
                Url += '&lastname=' + EncodingUtil.urlEncode(UserInfo.getLastName(),'UTF-8');
            }
                
            if (UserInfo.getUserEmail()!=null) {
                Url += '&email=' + EncodingUtil.urlEncode(UserInfo.getUserEmail(),'UTF-8');
            }
        }

        if(extraParams <> null) {
            for(String k : extraParams.keySet()) {
                Url += '&' + EncodingUtil.urlEncode(k, 'UTF-8');
                Url += '=' + EncodingUtil.urlEncode(String.valueOf(extraParams.get(k)),'UTF-8');
            }
        }

        return Url;
    }

    private String GetUrl(string path,string apiurl){
        return GetUrl(path, apiurl, null);
    }

    private String GetUrl(string path){
        return GetUrl(path,gxs.ApiURL);
    }

    public string getGRAXAppConfig(){
        graxappJSON = queryAppConfig(graxapp);

        // return graxappJSON;
        return null;
    }
    	
    public void setGRAXAppConfig(String newValue){
		graxappJSON = String.isNotBlank(newValue) ? newValue : queryAppConfig(graxapp);
    }
    
    public String queryAppConfig(String appName){
        graxappJSON = '';
        if(appName!='' && appName != LastAppName && appName != null) {
        		System.Debug('[GRAX.io] Getting App Configuration: ' + appName);
            GRAXCloud.CallOutResponse callout = GRAXCloud.doHTTP('GET', null, GetUrl('/platforms/heroku/getappconfig','https://api.grax.io/test/api') + '&appname=' + appName, null);
            System.Debug('[GRAX.io] callout.response: ' + callout.response);
            if(callout.success) {
                graxappJSON = callout.response;
            }
            LastAppName = appName;
	        gxs.graxConfig.Heroku_App_Name__c = appName;
	        gxs.graxConfig.ApiToken__c = GetAppConfig('ENGAGEMENTGRAPH_APITOKEN');
	        gxs.graxConfig.GatewayToken__c = GetAppConfig('ENGAGEMENTGRAPH_GATEWAYTOKEN');
	        gxs.graxConfig.graphdburl__c = GetAppConfig('GRAPHCONNECT_URL');
	        gxs.graxConfig.LicenseToken__c = GetAppConfig('ENGAGEMENTGRAPH_LICENSETOKEN');
	        gxs.graxConfig.Postgres_URL__c = GetAppConfig('DATABASE_URL');
	        gxs.graxConfig.GRAX_Flow_URL__c = String.isNotBlank(appName) ? 'https://' + appName + '.herokuapp.com' : '';
            gxs.graxConfig.GRAX_API_Url__c = String.isNotBlank(appName) ? 'https://' + appName + '.herokuapp.com/graxproxy/api' : '';
        }else
        		System.Debug('[GRAX.io] Already Have App Configuration: ' + appName);
        		
        return graxappJSON;
    }
    
    public String GetAppConfig(String fieldName){
    		String ReturnValue = '';
    		if (graxappJSON!='' && graxappJSON!=null){
    			JSONParser parser = JSON.createParser(graxappJSON);
    			while (parser.nextToken() != null) {
    				if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == fieldName){
        				parser.nextToken();
        				ReturnValue = parser.getText();
        				system.debug('[GRAX.io] FOUND SETTING : ' + fieldName + '=' + ReturnValue);
        			}
        		}
    		}
    		return ReturnValue;
    }
    
    public List<SelectOption> ParseJSON(){
        String FieldName = '';
        String FieldValue = '';
        String GraxAppName = '';
        try{
            if (String.isNotBlank(graxconfig)){
                JSONParser parser = JSON.createParser(graxconfig);
                while (parser.nextToken() != null) {
                    if (parser.getCurrentToken() == JSONToken.FIELD_NAME)
                    {
                        FieldName = parser.getText();
                        parser.nextToken();
                        FieldValue = parser.getText();
                        
                        if (FieldName=='authorized')
                            isconfigured = true;
                        
                        if (FieldName=='name')
                            GraxAppName = FieldValue;
                        
                        if (FieldName=='id'){
                            appselectdisabled = false;
                            system.debug('[GRAX.io] ' + GraxAppName + '=' + FieldValue);
                            graxapps.add(new SelectOption(GraxAppName,GraxAppName)); 
                        }
                    }	
                }
            } else {
                String graxapp = gxs.graxConfig.Heroku_App_Name__c;

                if(String.isNotBlank(graxapp)) {
                    graxapps.add(new SelectOption(graxapp, graxapp));

                    isconfigured = true;
                }
            }
		} catch (Exception e) {
		     //Generic exception handling code here
		} finally {
		     //optional finally block
		     //code to run whether there is an exception or not
		}
    		
        graxapps.sort();
        return graxapps;
   	}

	public List<SelectOption> getItems() 
    {   
        String objectname;
        List<SelectOption> options = new List<SelectOption>();
        Map<String, SObjectType> sObjects = Schema.getGlobalDescribe();
            options.add(new SelectOption('' ,'-- SELECT SALESFORCE OBJECT --', true));
        for (String apiName : sObjects.keySet())
        {
            Map<String, Schema.RecordTypeInfo> types = sObjects.get(apiName).getDescribe().getRecordTypeInfosByName();
            if (types.size() > 0){
                // system.debug(apiName);
                // system.debug('[GRAX.io] Type: ' + sObjects.get(apiName).getDescribe().getRecordTypeInfosByName());
                // system.debug('[GRAX.io] Type: ' + sObjects.get(apiName).getDescribe().getName());
                objectname = sObjects.get(apiName).getDescribe().getName();
                // system.debug('[GRAX.io] ' + sObjects.get(apiName));
                // options.add(new SelectOption(apiName ,apiName ));
                
                objectname = sObjects.get(apiName).getDescribe().getName();
                options.add(new SelectOption(objectname ,objectname ));
            }
        }
        options.sort();
        
        return options;
    }
	    

    // FLOW
    
    public string getPropURLToDisplay_Flow() { 
        String flowUrl = 'https://grax.io';
        if (gxs.graxConfig.GRAX_Flow_URL__c != null )
            flowUrl = gxs.graxConfig.GRAX_Flow_URL__c; 
        return flowUrl;
    }
    
    public pagereference connect(){
        pagereference p=new pagereference(getPropURLToDisplay_Flow());
        return p;
    }

    // COMMON
    public pagereference CancelReload() {
        pagereference pageRef = new pagereference(ApexPages.currentPage().getUrl());
        pageRef.setRedirect(true);

        return pageRef;
    }

	private void generatePageMessage(String message, String severity){
        if(severity == 'WARNING'){
            warningMessage = message;
        }else if(severity == 'INFO'){
            infoMessage = message;
        }
    }
}
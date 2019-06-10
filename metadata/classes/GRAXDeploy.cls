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

public with sharing class GRAXDeploy {

	String LastAppName = '';
	GRAXSettings gxs = new GRAXSettings();
	public string graxconfig {get;set;}
	public boolean isconfigured {get;set;}
	public boolean appselectdisabled {get;set;}
	public boolean disableeverything {get;set;}
	
	public boolean disableaudit {get;set;}
	public boolean appselected {
		get {
			if (graxsetting_apitoken!='' && graxsetting_gatewaytoken!='' && graxsetting_graphdburl!='' && graxsetting_licensetoken!='')
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
	
	// Should remove this and bind directly to settings object (Duh!)
	public string graxsetting_graxapp {get;set;}
	public string graxsetting_apitoken {get;set;}
	public string graxsetting_gatewaytoken  {get;set;}
	public string graxsetting_graphdburl {get;set;}
	public string graxsetting_flowurl {get;set;}
	public string graxsetting_apiurl {get;set;}
	public string graxsetting_s3accesskey {get;set;}
	public string graxsetting_s3secret {get;set;}
	public string graxsetting_s3bucket {get;set;}
	public string graxsetting_s3region {get;set;}
	public string graxsetting_licensetoken {get;set;}
	
	public List<SelectOption> graxapps {get;set;} 
	
    public GRAXDeploy() {
    		
    		actiontext = 'Save';
    		actionbuttontext = 'Save GRAX Settings';
    		
    		appselectdisabled = true;
    		graxapps = new List<SelectOption>(); 
    		graxapps.add(new SelectOption('','-- Choose Heroku Application --'));
    		graxconfig = GetConfig();	
    		graxapps = ParseJSON();
    		isconfigured = false;
		
		if (GRAXSettings.IsConfigured()==false)
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Please Select Application.'));
		
		LockSettings(GRAXSettings.IsConfigured());
    }
    
    public pagereference AuthorizeHeroku(){
		pagereference p = new pagereference(GetUrl('/platforms/heroku/oauth/authorize'));
		return p;
    }
   	
   	public void LockSettings(Boolean LockFlag){
   		if (LockFlag){
   			actiontext = 'GRAX Settings';
   			actionbuttontext = 'Unlock';
   			disableeverything = true;
   			GRAXSettings settings = new GRAXSettings();
	    		graxsetting_apitoken = settings.graxConfig.ApiToken__c;
			graxsetting_gatewaytoken = settings.graxConfig.GatewayToken__c;
			graxsetting_licensetoken = settings.graxConfig.LicenseToken__c;
			graxsetting_graphdburl = settings.graxConfig.graphdburl__c;
			graxsetting_flowurl = settings.graxConfig.GRAX_Flow_URL__c;
			graxsetting_apiurl = settings.graxConfig.GRAX_API_Url__c;
			graxsetting_graxapp = settings.graxConfig.Heroku_App_Name__c;
			graxsetting_s3secret = settings.graxConfig.s3secretaccesskey__c;
			graxsetting_s3accesskey = settings.graxConfig.s3accesskeyid__c;
			
			graxsetting_s3bucket = settings.graxConfig.s3bucket__c;
			graxsetting_s3region = settings.graxConfig.s3region__c;
			
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'GRAX Settings Locked'));
   		}else{
   			actiontext = 'GRAX Settings';
   			actionbuttontext = 'Save';
   			disableeverything = false;
   			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'GRAX Settings Unlocked'));
   		}
   	}
   		 
    public pagereference UpdateCustomSettings(){
    		if (actionbuttontext=='Save'){
    			if (graxsetting_apitoken!='' && graxsetting_gatewaytoken!='' && graxsetting_licensetoken!='' && graxsetting_graphdburl!=''){
	    			GRAXSettings settings = new GRAXSettings();
				settings.graxConfig.ApiToken__c = graxsetting_apitoken;
				settings.graxConfig.GatewayToken__c = graxsetting_gatewaytoken;
				settings.graxConfig.LicenseToken__c =graxsetting_licensetoken;
				settings.graxConfig.graphdburl__c = graxsetting_graphdburl;
				settings.graxConfig.GRAX_Flow_URL__c = graxsetting_flowurl;
				settings.graxConfig.GRAX_API_Url__c = graxsetting_apiurl;
				settings.graxConfig.Heroku_App_Name__c = graxsetting_graxapp;
				
				settings.graxConfig.s3accesskeyid__c = graxsetting_s3accesskey;
				settings.graxConfig.s3secretaccesskey__c = graxsetting_s3secret;
				settings.graxConfig.s3bucket__c = graxsetting_s3bucket;
				settings.graxConfig.s3region__c = graxsetting_s3region;
				
				settings.UpdateSettings();
				ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Saved GRAX Settings.'));
	    		}
	    		LockSettings(true);
    		}
    		else
    			LockSettings(false);
    		
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
		pagereference p = new pagereference('https://heroku.com/deploy?template=https://github.com/HardingPoint/GRAX/blob/master');
		return p;
    }
    
    public String GetConfig(){
		if(!Test.isRunningTest()) {
			GRAXCloud.CallOutResponse callout = GRAXCloud.doHTTP('GET', null, GetUrl('/platforms/heroku/getconfig'), null);

			if(callout.success) {
				return callout.response;	
			}
		}

		return graxconfig;
    }
    
    private String GetUrl(string path){
    		String Url = gxs.ApiURL + path + '?';
    		
    		if (!Test.isRunningTest()){
	    		Url += 'orgid=' + EncodingUtil.urlEncode(UserInfo.getOrganizationId(),'UTF-8');
	    		Url += '&userid=' + EncodingUtil.urlEncode(UserInfo.getUserId(),'UTF-8');
	    		
	    		if (ApexPages.currentPage().getHeaders().get('Host')!=null)
	    			Url += '&host=' + EncodingUtil.urlEncode(ApexPages.currentPage().getHeaders().get('Host'),'UTF-8');
	    		
	    		if (UserInfo.getOrganizationName()!=null)
	    			Url += '&companyname=' + EncodingUtil.urlEncode(UserInfo.getOrganizationName(),'UTF-8');
	    			
	    		if (UserInfo.getFirstName()!=null)
	    			Url += '&firstname=' + EncodingUtil.urlEncode(UserInfo.getFirstName(),'UTF-8');
	    			
	    		if (UserInfo.getLastName()!=null)	
	    			Url += '&lastname=' + EncodingUtil.urlEncode(UserInfo.getLastName(),'UTF-8');
	    			
	    		if (UserInfo.getUserEmail()!=null)	
	    			Url += '&email=' + EncodingUtil.urlEncode(UserInfo.getUserEmail(),'UTF-8');
    		}
    		return Url;
    }

    public string getGRAXAppConfig(){
    		graxappJSON = queryAppConfig(graxapp);
		return graxappJSON;
    	}
    	
    	public void setGRAXAppConfig(String newValue){
		graxappJSON = queryAppConfig(graxapp);
    	}
    
    public String queryAppConfig(String appName){
		graxappJSON = '';

		if (appName!='' && appName != LastAppName && appName!=null && !Test.isRunningTest()) {
			GRAXCloud.CallOutResponse callout = GRAXCloud.doHTTP('GET', null, GetUrl('/platforms/heroku/getappconfig') + '&appname=' + appName, null);

			if(callout.success) {
				graxappJSON = callout.response;

				LastAppName = appName;
			    graxsetting_graxapp = appName;
			    graxsetting_apitoken = GetAppConfig('ENGAGEMENTGRAPH_APITOKEN');
			    graxsetting_gatewaytoken = GetAppConfig('ENGAGEMENTGRAPH_GATEWAYTOKEN');
			    graxsetting_graphdburl = GetAppConfig('GRAPHCONNECT_URL');
			    graxsetting_licensetoken = GetAppConfig('ENGAGEMENTGRAPH_LICENSETOKEN');
			    graxsetting_flowurl = 'https://' + appName + '.herokuapp.com';
			    graxsetting_apiurl = ''; // Let it default to code base
			}
		}
		
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
	    		if (graxconfig!=null && graxconfig!=''){
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
}
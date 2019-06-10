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
Name              : GRAXSettings
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
2. Ariel Yankelevich     02/28/2019           	David Mackey        New Advanced/Custom Setting (https://app.asana.com/0/326600806074978/1111746752627422/f)
3. Ariel Yankelevich     05/07/2019           	David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
******************************************************************************************/

public virtual class GRAXSettings {
	public Boolean ProperlyConfigured = false; 
	public String graphdburl = '';
	public String LicenseToken = '';
	public String GatewayToken = '';
	public String ApiToken = '';
	public String PostgresURL = '';
	
	public GRAXSettings__c graxConfig {get;set;}
	
	// Default to the testing URL
	public String ApiURL = 'https://api.grax.io/test/api';
	public String GRAXDeployURL = 'https://www.heroku.com/deploy/?template=https://github.com/HardingPoint/grax-secure';

	private String ExecutionSource = '';

	public GRAXSettings(String executionSource, String objectName) {
		ExecutionSource = executionSource;
		ProperlyConfigured = Initialize(objectName);
	}

	// Load Settings for Object
	public GRAXSettings(String objectName) {
		ProperlyConfigured = Initialize(objectName);
	}

	// Default Constructor
    public GRAXSettings() {
		ProperlyConfigured = Initialize('');
    }
    
    public void UpdateSettings(){
		upsert graxConfig;
    }
    
    // Load the configuration & object settings.
    private Boolean Initialize(String ObjectName){
    		graxConfig = GRAXSettings__c.getOrgDefaults();
		if (graxConfig != null){
			// GRAX Custom Settings Values.
			graphdburl = graxConfig.graphdburl__c;
			LicenseToken = graxConfig.LicenseToken__c;
			GatewayToken = graxConfig.GatewayToken__c;
			PostgresURL = graxConfig.Postgres_URL__c;
			ApiToken = graxConfig.ApiToken__c;
			
			if(graxConfig.GRAX_API_Url__c != '' && graxConfig.GRAX_API_Url__c != null){
				ApiURL=graxConfig.GRAX_API_Url__c;
			}
			
			if ((LicenseToken != null && LicenseToken != '') &&
				(GatewayToken != null && GatewayToken != '') &&
				(ApiToken != null && ApiToken != '')){
					ProperlyConfigured = true;
			}
		}
    		
		return ProperlyConfigured;
    }
    
    public static Boolean IsConfigured(){
    		GRAXSettings gx = new GRAXSettings();
    		return gx.ProperlyConfigured;
    }
    
	// ------------------------------------------------------------------------
	// Should move these to a seperate class
	public void debug(String output){
    		debug('', output, '');
    }
    
    public void debug(String MethodName, String output){
    		debug(MethodName, output, '');
    }
    
    public void debug(String MethodName, String output, String Error){
    		String Source = ExecutionSource;
    		if (Source!='' && MethodName!='')
    			Source += '.' + MethodName;
    		else if (MethodName!='')
    			Source = MethodName;
    		GRAXSettings.debug(Source, output, Error, 0);
    }
    
    public static void debug(String source, String output, String error, Integer level){
    		if (Source!='')
    			Source += ': ';
    		if (error!='')
    			error = ' [GRAX Error] ' + error;
    			
    		System.debug('[GRAX.io] ' + source + output + error);
    }
    // ------------------------------------------------------------------------
}
/*****************************************************************************************
Name              : GRAXSetupCtrlTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
2. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
******************************************************************************************/

@isTest
public with sharing class GRAXSetupCtrlTest {
    
    @isTest
    static void DeployConstructorTest() {
		GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
    
		GRAXSettings gxs = GRAXUnitTest.getSettings();
		
     	PageReference pageRef = Page.GRAXSetup;
    		Test.setCurrentPage(pageRef); 
    		
     	GRAXSetupCtrl deploy = new GRAXSetupCtrl();
     	deploy.gxs = gxs;
		
		deploy.graxconfig = '{"authorized": "true","graxapps": [{"name": "' + gxs.graxConfig.Heroku_App_Name__c + '","id": "f0e91e26-e079-4663-b4fc-78aea8ae44c5"}]}';
		deploy.graxappJSON = '{"ENGAGEMENTGRAPH_ADMINPWD":"kmdEzscyQa7gSVuT","ENGAGEMENTGRAPH_ADMINUSER":"admin","ENGAGEMENTGRAPH_APITOKEN":"e74b42e509a30e7c9dc5527cc73a86fbe4fd0e0fe2271dfdf83c3933dabc7268","ENGAGEMENTGRAPH_APIURL":"https://api.grax.io/test/api","ENGAGEMENTGRAPH_APIVERSION":"v9.3","ENGAGEMENTGRAPH_GATEWAYTOKEN":"nlqV5TlUov6On6kgev2by3dpdwct0QGN8Vkqj4MA","ENGAGEMENTGRAPH_LICENSETOKEN":"U2FsdGVkX19PV5qeK5Vzm1TeHv8t2srLzktZLKMzFwY7OzjR3H8NzGUYgjtFOe4DBaLFKkvXPUjwumd5vVOngF5BpsuwcRSTo6/Pf8PmnHo=","ENGAGEMENTGRAPH_URL":"test.hardingpoint.com","ENGAGEMENTMANAGER_CACHE_DIR":"./HardingPoint/cache/","ENGAGEMENTMANAGER_CACHE_ENABLED":"true","ENGAGEMENTMANAGER_ENVIRONMENT":"Production","ENGAGEMENTMANAGER_READONLYPWD":"HardingPoint!","ENGAGEMENTMANAGER_READONLYUSER":"readonly","GRAPHCONNECT_BOLT_PASSWORD":"b.U6ppfez3ulMw.CW6bwPBPi6f0eE8S","GRAPHCONNECT_BOLT_URL":"bolt://hobby-fjnmeiioglmjgbkeecngjoal.dbs.graphenedb.com:24786","GRAPHCONNECT_BOLT_USER":"app88135813-UPGXLo","GRAPHCONNECT_URL":"https://app88135813-UPGXLo:b.U6ppfez3ulMw.CW6bwPBPi6f0eE8S@hobby-fjnmeiioglmjgbkeecngjoal.dbs.graphenedb.com:24780"}';
		
		deploy.ParseJSON();
		deploy.GetAppConfig('ENGAGEMENTGRAPH_ADMINUSER');
		
		String value = '';
		value=deploy.actiontext;
		value=deploy.actionbuttontext;
		value=deploy.graxapp;
		value=deploy.graxappJSON;
		value=deploy.gxs.graxConfig.Heroku_App_Name__c;
		value=deploy.gxs.graxConfig.ApiToken__c;
		value=deploy.gxs.graxConfig.GatewayToken__c;
		value=deploy.gxs.graxConfig.graphdburl__c;
		value=deploy.gxs.graxConfig.GRAX_Flow_URL__c;
		value=deploy.gxs.graxConfig.GRAX_API_Url__c;
		value=deploy.gxs.graxConfig.LicenseToken__c;
		
		value=deploy.getGRAXAppConfig();
		deploy.setGRAXAppConfig(deploy.graxappJSON);
		
		deploy.queryAppConfig(deploy.graxapp);
		
		deploy.appselected = true;
     	boolean b = deploy.appselected;
     	
     	deploy.LockSettings(false);
     	deploy.LockSettings(true);
     	
     	deploy.actionbuttontext = 'Save';
		deploy.UpdateCustomSettings();
     	
     	deploy.AuthorizeHeroku();
     	deploy.LoginToHeroku();
     	deploy.SignUpHeroku();
     	deploy.DeployGraxApp();
     	deploy.GetConfig();

    }

	// CONFIGURATION
    @isTest
    static void ConfigurationConstructorTest() {
        GRAXSettings gxs = GRAXUnitTest.getSettings();
		GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();

        GRAXSetupCtrlTest.Initialize();

        Test.stopTest();
    }

    @isTest
    static void TestNotConfiguredPage() {
		PageReference pageRef = Page.GRAXConfiguration;
        Test.setCurrentPage(pageRef);  
    }
    
    @isTest
    static void TestPage() {
        GRAXSettings gxs = GRAXUnitTest.getSettings();
		PageReference pageRef = Page.GRAXConfiguration;
        Test.setCurrentPage(pageRef);  	
    }
    
    public static GRAXSetupCtrl Initialize(){
		PageReference currentPage = Page.GRAXSetup;
		Test.setCurrentPageReference(currentPage);

		GRAXSetupCtrl gsc = new GRAXSetupCtrl();
        gsc.objToQuery = 'Account';
        
        gsc.getPropURLToDisplay_Flow();
        
        gsc.getItems();
        
        gsc.UpdateAuditTrail();
		gsc.CreateParitions();
		gsc.DropParitions();

		gsc.DeploySelectedApp();

		gsc.connect();

		gsc.verifySchedules();
		gsc.saveScheduleJobs();
		gsc.verifySchedules();

		gsc.cancelReload();
		return gsc;
    }

}
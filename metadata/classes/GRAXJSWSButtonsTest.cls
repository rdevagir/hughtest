/*****************************************************************************************
Name              : GRAXJSWSButtonsTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Ariel Yankelevich     05/30/2019           	David Mackey        Restore Button on External Object (https://app.asana.com/0/326600806074978/1124474865343484/f)
******************************************************************************************/
@isTest
private class GRAXJSWSButtonsTest {
    
    @isTest(seeAllData = false)
    static void restoreExternalObject() {
    	GRAX_Schedule_Process__c gq = new GRAX_Schedule_Process__c();
        gq.Object_Name__c = 'GRAX_Schedule_Process__c';
        insert gq;
        
    	String params = '{"externalObjectAPIName": "GRAX_Schedule_Process__c", "externalObjectId": "' + gq.Id + '", "objecttype": "GRAX_Schedule_Process__c", "idFieldName": "Id", "graxorgidFieldName": "Name"}';
    	
    	String responseData = '{"status":"success","data":[{"Object_Name__c":"GRAX_Schedule_Process__c"}],"message":"queryBackup"}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', responseData, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
    	Test.startTest();
		String result = GRAXJSWSButtons.restoreExternalObject(params);
        Test.stopTest();
        
        Map<String,Object> m = (Map<String,Object>) JSON.deserializeUntyped(result);
        System.assertEquals('success', (String)m.get('status'));
    }
}
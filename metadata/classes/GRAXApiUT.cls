/*****************************************************************************************
Name              : GRAXApiUT
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
2. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
******************************************************************************************/

@isTest(SeeAllData=true)
public with sharing class GRAXApiUT {

    @isTest
    static void cloudconfigTest() {
    		GRAXSettings gxs = GRAXUnitTest.getSettings();

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, '{}', 'http://test.grax.io/applications/neo4j/configure', null);
        
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        GRAXApi.cloudconfig('Account');

        Test.stopTest();


      	
    }
    
    @isTest
    static void mockTest() {
      	GRAXApi.mock('Account');
      	GRAXApi.mock('Case');
      	GRAXApi.mock('Opportunity');
      	GRAXApi.mock('Contact');
      	GRAXApi.mock('Lead');
    }
    
    @isTest
    static void jsonContentInsertBadTest() {
    		// Bad Call
    		GRAXSettings gxs = GRAXUnitTest.getSettings();
      	String results = GRAXApi.jsonContent(null,null);
    }
    
    @isTest
    static void jsonContentArchive() {
        GRAXSettings gxs = GRAXUnitTest.getSettings();
        List<SObject> triggerNew = GRAXUnitTest.getTestAccount();
        List<SObject> triggerOld = GRAXUnitTest.getTestAccount();
        GRAXApi.jsonContentCallout(triggerNew, triggerOld, false);
    }
    
    @isTest
    static void jsonContentInsertTest() {
    		GRAXSettings gxs = GRAXUnitTest.getSettings();
      	List<SObject> acctList = GRAXUnitTest.getTestAccount();
      	String results = GRAXApi.jsonContent(acctList,null);
    }
    
    @isTest
    static void jsonContentUpdateTest() {
    		GRAXSettings gxs = GRAXUnitTest.getSettings();
      	List<SObject> acctList = GRAXUnitTest.getTestAccount();
      	String results = GRAXApi.jsonContent(acctList,acctList);
    }
    
    @isTest
    static void jsonContentDeleteTest() {
    		GRAXSettings gxs = GRAXUnitTest.getSettings();
      	List<SObject> acctList = GRAXUnitTest.getTestAccount();
      	String results = GRAXApi.jsonContent(null,acctList);
    }
    
    @isTest
    static void jsonContentUpdateWithConfigTest() {
    		GRAXSettings gxs = GRAXUnitTest.getSettings();
      	List<SObject> acctList = GRAXUnitTest.getTestAccount();
      	String results = GRAXApi.jsonContent(acctList,acctList,'{}');
    }
}
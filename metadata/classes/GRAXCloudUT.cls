@isTest
private class GRAXCloudUT{

    @isTest
    static void ConstructorTest() {
        GRAXSettings gxs = GRAXUnitTest.getSettings();
        GRAXCloud gx = new GRAXCloud();
    }
    
       
    /*****************************************************************************************
    Name              : calloutnowTest
    Description       : 
    Revision History  :
    Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
    ----------------------------------------------------------------------------------------
    1. Leandro Brunner       04/17/2018				David Mackey        https://app.asana.com/0/326600806074978/633149554508924/f
    ******************************************************************************************/
    @isTest
    static void calloutnowTest() {
        GRAXSettings gxs = GRAXUnitTest.getSettings();
        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, '{"message": "Test successful"}', 'http://test.grax.io', null);
		
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        GRAXCloud.calloutnow('http://test.grax.io','{}');
        GRAXCloud.callout('http://test.grax.io','{}');

        Test.stopTest();
    }
    
    /*****************************************************************************************
    Name              : calloutTest
    Description       : 
    Revision History  :
    Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
    ----------------------------------------------------------------------------------------
    1. Leandro Brunner       04/17/2018				David Mackey        https://app.asana.com/0/326600806074978/633149554508924/f
    ******************************************************************************************/
    @isTest(seeAllData = false)
    static void calloutTest() {
        GRAXSettings gxs = GRAXUnitTest.getSettings();

		GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, '{"message": "Test successful"}', 'http://test.grax.io/applications/neo4j/configure', null);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        GRAXCloud.callout('http://test.grax.io', '{}', 'Test', '');

        Test.stopTest();

        GRAX_Data_Record__c dr = [SELECT Salesforce_Object__c, Status__c FROM GRAX_Data_Record__c LIMIT 1];

        System.assertEquals('Sent Successful', dr.Status__c);
    }

    /*****************************************************************************************
    Name              : calloutTest2
    Description       : 
    Revision History  :
    Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
    ----------------------------------------------------------------------------------------
    1. Leandro Brunner       04/17/2018				David Mackey        https://app.asana.com/0/326600806074978/633149554508924/f
    ******************************************************************************************/
    @isTest(seeAllData = false)
    static void calloutTest2() {
        GRAXSettings gxs = GRAXUnitTest.getSettings();

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(408, '{"message": "Request Timeout"}', 'http://test.grax.io/applications/neo4j/configure', null);
        
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        GRAXCloud.callout('http://test.grax.io', '{}', 'Test', '');

        Test.stopTest();

        GRAX_Data_Record__c dr = [SELECT Salesforce_Object__c, Status__c FROM GRAX_Data_Record__c LIMIT 1];

        System.assertEquals('Error', dr.Status__c);
    }
    
    @isTest
    static void calloutTest3() {
    	GRAXSettings gxs = GRAXUnitTest.getSettings();
        List<Account> records = [select Id, Name From Account ORDER BY Name ASC LIMIT 1];
        
        System.debug('SOMETHING HERE: ' + records);

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(408, '{"message": "Request Timeout"}', 'http://test.grax.io/applications/neo4j/configure', null);
        
        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        //GRAXCloud.callout('http://test.grax.io', '{}', records);

        Test.stopTest();
    }
    
    
}
/*****************************************************************************************
Name              : GRAXLogs
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       11/27/2018             David Mackey        Logs Enhancement (https://app.asana.com/0/326600806074978/861352422200250/f)
******************************************************************************************/
@isTest(seeAllData=false)
public with sharing class GRAXLogsTest {
    @isTest
    public static void GRAXLogsTest1() {
        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"message": "Test successful"}', null);

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        try {
            List<Integer> li = new List<Integer>();
            li.add(15);
            // This list contains only one element,
            // but we're attempting to access the second element
            // from this zero-based list.
            Integer i1 = li[0]; 
            Integer i2 = li[1]; // Causes a ListException
        } catch(Exception e) {
            GRAXLogs.addLogException(e);
        }

        Test.stopTest();
    }
}
/*****************************************************************************************
Name              : GRAXBatchToProcessSchedJobFromReportTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
2. Leandro Brunner          06/25/2018
******************************************************************************************/
@isTest
public with sharing class GRAXBatchToProcessSchedJobFromReportTest {
    public static String csvTest = '"Report ID","Object Name"\r\n"00OZ0000000he4iMAA","Report"\r\n';

    @isTest
    public static void GRAXBatchToProcessSchedJobFromReportTest1() {
        GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.Status__c = 'Sent Successful';
        dr.of_Times_Sent__c = 1;
        insert dr;

        
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Report__c = '00OZ0000000he4iMAA';
        gsp.Select_Criteria__c = null;
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = true;
        insert gsp;
        
        GRAXUtils.setSelectionJSON(gsp.Id, '{"uniqueKey":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c","parentUniqueKey":null,"relatedFieldName":null,"name":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c","childObjRelStructure":[{"uniqueKey":"GRAX_Data_Record__c_Attachments","parentUniqueKey":"GRAX_Data_Record__c","relatedFieldName":"ParentId","name":"Attachment","childObjRelStructure":[]}]}');

        System.assertNotEquals(null, GRAXUtils.getSelectionJSON(gsp.Id));

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, '{"message": "Test successful"}', 'http://test.grax.io/applications/neo4j/configure', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);


        csvTest = '';
        csvTest += '"GRAX Data Record ID","Object Name"\r\n';
        csvTest += '"' + dr.Id + '","' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c"\r\n';

        Test.startTest();

        GRAXBatchToProcessSchedJobFromReport b = new GRAXBatchToProcessSchedJobFromReport(gsp.Id, null, 100, true);

        Id jobId = Database.executebatch(b);

        Test.stopTest();

        System.assertNotEquals(null, b.mainBatchProcess.query);

        for(GRAX_Schedule_Process__c schedProcess : [SELECT Id, Next_Run_Date__c, Last_Run_Date__c, Status__c FROM GRAX_Schedule_Process__c WHERE Id = :gsp.Id]) {
            System.assertEquals('Pending send data to GRAX', schedProcess.Status__c);
        }

        System.assertEquals(1, [SELECT Id FROM GRAX_Data_Record_Id__c].size());
    }

}
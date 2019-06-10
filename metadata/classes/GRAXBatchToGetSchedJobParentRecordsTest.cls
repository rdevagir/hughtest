/*****************************************************************************************
Name              : GRAXBatchToGetSchedJobParentRecordsTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
2. Ariel Yankelevich     04/26/2019           	David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
******************************************************************************************/
@isTest
private class GRAXBatchToGetSchedJobParentRecordsTest {

    @isTest(seeAllData = false)
    static void GRAXBatchToGetSchedJobParentRecordsTest1() {
        GRAX_Schedule_Process__c gq = new GRAX_Schedule_Process__c();
        gq.Object_Name__c = 'GRAX_Schedule_Process__c';
        insert gq;

        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(1);
        //gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        gsp.type__c = 'Multi-Object';
        gsp.Execution_Unique_Key__c = 'testing123';
        gsp.Progressive__c = true;
        insert gsp;

        GRAXUtils.setSelectionJSON(gsp.Id, '[{"uniqueKey":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c","parentUniqueKey":"testParentKey","relatedFieldName":null,"name":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c","childObjRelStructure":[]}]');

        System.assertNotEquals(null, GRAXUtils.getSelectionJSON(gsp.Id));
        
        GRAX_Data_Record__c dr1 = new GRAX_Data_Record__c(Salesforce_Object__c = 'GRAXQuery__c', Status__c = 'Processing', of_Times_Sent__c = 1, Error_Message__c = null, GRAX_Schedule_Process__c = gsp.Id, GRAX_Archive_Process__c = null, Last_Sent_Date__c = Date.today(), Execution_Unique_Key__c = 'testing123', Sched_Proc_Hierarchy_Unique_Key__c = 'testParentKey');
        insert new List<GRAX_Data_Record__c> {dr1};

        GRAX_Data_Record_Id__c dri1 = new GRAX_Data_Record_Id__c(GRAX_Data_Record__c = dr1.Id, Execution_Unique_Key__c = 'testing', Processed_Child_Index__c = -1, SFDC_Id__c = dr1.Id);
        GRAX_Data_Record_Id__c dri2 = new GRAX_Data_Record_Id__c(GRAX_Data_Record__c = dr1.Id, Execution_Unique_Key__c = 'testing', Processed_Child_Index__c = -1, SFDC_Id__c = dr1.Id);
        GRAX_Data_Record_Id__c dri3 = new GRAX_Data_Record_Id__c(GRAX_Data_Record__c = dr1.Id, Execution_Unique_Key__c = 'testing', Processed_Child_Index__c = -1, SFDC_Id__c = dr1.Id);
		insert new List<GRAX_Data_Record_Id__c> {dri1, dri2, dri3};

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"message": "Test successful"}', null);

        GRAXBatchToProcessSchedJob b = new GRAXBatchToProcessSchedJob(gsp.Id, null, 0, null, true, true);
        GRAXBatchToGetSchedJobParentRecords b1 = new GRAXBatchToGetSchedJobParentRecords(b);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Id jobId = Database.executebatch(b1);

        Test.stopTest();

        System.assertEquals(3, [SELECT Id FROM GRAX_Data_Record_Id__c WHERE GRAX_Data_Record__r.GRAX_Schedule_Process__c =: gsp.Id AND Execution_Unique_Key__c =: gsp.Execution_Unique_Key__c AND Processed_Child_Index__c > -1].size());
    }
}
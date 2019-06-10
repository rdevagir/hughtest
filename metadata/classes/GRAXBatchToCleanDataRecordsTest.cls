/*****************************************************************************************
Name              : GRAXBatchToCleanDataRecordsTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       	04/17/2018			David Mackey        https://app.asana.com/0/326600806074978/633149554508924/f
2. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
******************************************************************************************/
@isTest
private class GRAXBatchToCleanDataRecordsTest {
    @TestSetup
    static void setup() {
        // To delete
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'CreatedDate';
        gsp.Target_Start_Datetime__c = Datetime.now().addDays(-3);
        gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = true;
        gsp.Progressive__c = true;
		gsp.Execution_Unique_Key__c = 'testing123';
        insert gsp;

        GRAX_Archive_Process__c archiveProc = new GRAX_Archive_Process__c();
        archiveProc.GRAX_Schedule_Process__c = gsp.Id;
        archiveProc.Async_Records_Successfully_Sent__c = 0;
        archiveProc.Async_Records_to_Process__c = 0;
        archiveProc.Records_Successfully_Sent__c = 2;
        archiveProc.Records_To_Process__c = 0;
        insert archiveProc;

        // To delete
        GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.Salesforce_Object__c = 'GRAX_Schedule_Process__c';
        dr.Status__c = 'Sent Successful';
        dr.of_Times_Sent__c = 1;
        dr.Error_Message__c = null;
        //dr.GRAX_Archive_Process__c = archiveProc.Id;
        dr.Last_Sent_Date__c = Date.today().addDays(-3);
        dr.Execution_Unique_Key__c = 'testing123';

        // To delete
        GRAX_Data_Record__c dr2 = new GRAX_Data_Record__c();
        dr2.Salesforce_Object__c = 'GRAX_Schedule_Process__c';
        dr2.Status__c = 'Sent Successful';
        dr2.of_Times_Sent__c = 1;
        dr2.Error_Message__c = null;
        dr2.GRAX_Archive_Process__c = archiveProc.Id;
        dr2.Last_Sent_Date__c = Date.today().addDays(-2);
		dr2.Execution_Unique_Key__c = 'testing123';

        GRAX_Data_Record__c dr3 = new GRAX_Data_Record__c();
        dr3.Salesforce_Object__c = 'GRAX_Schedule_Process__c';
        dr3.Status__c = 'Processing';
        dr3.of_Times_Sent__c = 1;
        dr3.Error_Message__c = null;
        dr3.GRAX_Schedule_Process__c = gsp.Id;
        dr3.GRAX_Archive_Process__c = archiveProc.Id;
        dr3.Last_Sent_Date__c = Date.today();
		dr3.Execution_Unique_Key__c = 'testing123';

		insert new List<GRAX_Data_Record__c> { dr, dr2, dr3 };

        // To delete
        GRAX_Data_Record_Id__c dri = new GRAX_Data_Record_Id__c();
        dri.GRAX_Data_Record__c = dr.Id;
		dri.Execution_Unique_Key__c = 'testing123';

        // To delete
        GRAX_Data_Record_Id__c dri2 = new GRAX_Data_Record_Id__c();
        dri2.GRAX_Data_Record__c = dr2.Id;
		dri2.Execution_Unique_Key__c = 'testing123';

        GRAX_Data_Record_Id__c dri3 = new GRAX_Data_Record_Id__c();
        dri3.GRAX_Data_Record__c = dr3.Id;
		dri3.Execution_Unique_Key__c = 'testing123';

		insert new List<GRAX_Data_Record_Id__c> { dri, dri2, dri3 };
    }

    @isTest(seeAllData = false)
    static void GRAXBatchToCleanDataRecordsTest1() {
    	delete [SELECT Id FROM GRAX_Data_Record_Id__c];
        
        Integer objectIndex = GRAXBatchToCleanDataRecords.objects2Execute.indexOf('GRAX_Data_Record__c');

        Test.startTest();
        database.executebatch(new GRAXBatchToCleanDataRecords(objectIndex, null, null), 10);
        Test.stopTest();
        
        System.assertEquals(1, [SELECT Id FROM GRAX_Data_Record__c].size());
    }

    @isTest(seeAllData = false)
    static void GRAXBatchToCleanDataRecordsTest2() {
        Integer objectIndex = GRAXBatchToCleanDataRecords.objects2Execute.indexOf('GRAX_Data_Record_Id__c');

        Test.startTest();
        database.executebatch(new GRAXBatchToCleanDataRecords(objectIndex, null, null), 10);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM GRAX_Data_Record_Id__c].size());
    }

    @isTest(seeAllData = false)
    static void GRAXBatchToCleanDataRecordsTest3() {
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'CreatedDate';
        gsp.Target_Start_Datetime__c = Datetime.now().addDays(-3);
        gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = true;
        gsp.Progressive__c = false;
        insert gsp;

        GRAX_Archive_Process__c archiveProc = new GRAX_Archive_Process__c();
        archiveProc.GRAX_Schedule_Process__c = gsp.Id;
        archiveProc.Async_Records_Successfully_Sent__c = 0;
        archiveProc.Async_Records_to_Process__c = 0;
        archiveProc.Records_Successfully_Sent__c = 1;
        archiveProc.Records_To_Process__c = 0;
        insert archiveProc;

        Integer objectIndex = GRAXBatchToCleanDataRecords.objects2Execute.indexOf('GRAX_Archive_Process__c');

        Test.startTest();
        database.executebatch(new GRAXBatchToCleanDataRecords(objectIndex, null, null), 10);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE GRAX_Schedule_Process__c =: gsp.Id].size());
    }

    @isTest(seeAllData = false)
    static void GRAXBatchToCleanDataRecordsTest4() {
        delete [SELECT Id FROM GRAX_Data_Record_Id__c];
        
        Integer objectIndex = GRAXBatchToCleanDataRecords.objects2Execute.indexOf('GRAX_Data_Record__c');
		
		List<GRAX_Schedule_Process__c> gsp = [SELECT Id, Execution_Unique_Key__c FROM GRAX_Schedule_Process__c WHERE Object_Name__c = 'GRAX_Schedule_Process__c' LIMIT 1];
		
        Test.startTest();
        database.executebatch(new GRAXBatchToCleanDataRecords(objectIndex, gsp[0].Id, gsp[0].Execution_Unique_Key__c), 10);
        Test.stopTest();

        System.assertEquals(1, [SELECT Id FROM GRAX_Data_Record__c].size());
    }

    @isTest(seeAllData = false)
    static void GRAXBatchToCleanDataRecordsTest5() {
        Integer objectIndex = GRAXBatchToCleanDataRecords.objects2Execute.indexOf('GRAX_Data_Record_Id__c');

		List<GRAX_Schedule_Process__c> gsp = [SELECT Id, Execution_Unique_Key__c FROM GRAX_Schedule_Process__c WHERE Object_Name__c = 'GRAX_Schedule_Process__c' LIMIT 1];

		Test.startTest();
        database.executebatch(new GRAXBatchToCleanDataRecords(objectIndex, gsp[0].Id, gsp[0].Execution_Unique_Key__c), 10);
        Test.stopTest();

		System.assertEquals(1, [SELECT Id FROM GRAX_Data_Record_Id__c].size());
    }
}
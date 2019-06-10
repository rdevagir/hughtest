/*****************************************************************************************
Name              : GRAXDataRecordTriggerTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner    06/07/2018
******************************************************************************************/
@isTest
public with sharing class GRAXDataRecordTriggerTest {
    
    @isTest
    public static void rollUpTotalRecordsToProcessTest() {
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'Account';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Datetime.now().addDays(1);
        gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        insert gsp;

        GRAX_Archive_Process__c ap = new GRAX_Archive_Process__c(
            Async_Records_Successfully_Sent__c = 0,
            Async_Records_to_Process__c=0,
            Records_Successfully_Sent__c=0,
            Records_To_Process__c=0,
            GRAX_Schedule_Process__c=gsp.Id
        );
        insert ap;

        GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.Status__c = 'Not Sent';
        dr.of_Times_Sent__c = 0;
        dr.GRAX_Archive_Process__c = ap.Id;
        insert dr;

        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE Records_To_Process__c = 1].size());

        delete dr;

        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE Records_To_Process__c = 0].size());

        undelete dr;

        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE Records_To_Process__c = 1].size());
    }

    @isTest
    public static void rollUpTotalRecordsSuccessfullySentTest() {
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'Account';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Datetime.now().addDays(1);
        gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        insert gsp;

        GRAX_Archive_Process__c ap = new GRAX_Archive_Process__c(
            Async_Records_Successfully_Sent__c = 0,
            Async_Records_to_Process__c=0,
            Records_Successfully_Sent__c=0,
            Records_To_Process__c=0,
            GRAX_Schedule_Process__c=gsp.Id
        );
        insert ap;

        GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.Status__c = 'Not Sent';
        dr.GRAX_Archive_Process__c = ap.Id;
        insert dr;

        dr.Status__c = 'Sent Successful';
        update dr;

        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE Records_Successfully_Sent__c = 1].size());

        dr.Status__c = 'Error';
        update dr;

        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE Records_Successfully_Sent__c = 0].size());
    }

    @isTest
    public static void rollUpTotalAsyncRecordsToProcessTest() {
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'Attachment';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Datetime.now().addDays(1);
        gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = true;
        insert gsp;

        GRAX_Archive_Process__c ap = new GRAX_Archive_Process__c(
            Async_Records_Successfully_Sent__c=0,
            Async_Records_to_Process__c=0,
            Records_Successfully_Sent__c=0,
            Records_To_Process__c=0,
            GRAX_Schedule_Process__c=gsp.Id
        );
        insert ap;

        GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.Status__c = 'Not Sent';
        dr.of_Times_Sent__c = 0;
        dr.GRAX_Archive_Process__c = ap.Id;
        dr.Salesforce_Object__c = 'Attachment';
        insert dr;

        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE Async_Records_to_Process__c = 1].size());

        delete dr;

        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE Async_Records_to_Process__c = 0].size());

        undelete dr;

        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE Async_Records_to_Process__c = 1].size());
    }

    @isTest
    public static void rollUpTotalAsyncRecordsSuccessfullySentTest() {
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'Attachment';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Datetime.now().addDays(1);
        gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = true;
        insert gsp;

        GRAX_Archive_Process__c ap = new GRAX_Archive_Process__c(
            Async_Records_Successfully_Sent__c = 0,
            Async_Records_to_Process__c=0,
            Records_Successfully_Sent__c=0,
            Records_To_Process__c=0,
            GRAX_Schedule_Process__c=gsp.Id
        );
        insert ap;

        GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.Status__c = 'Not Sent';
        dr.of_Times_Sent__c = 0;
        dr.GRAX_Archive_Process__c = ap.Id;
        dr.Salesforce_Object__c = 'Attachment';
        insert dr;

        GRAX_Data_Record_Id__c dri = new GRAX_Data_Record_Id__c();
        dri.GRAX_Data_Record__c = dr.Id;
        insert dri;

        dri.Status__c = 'Sent to GRAX';
        update dri;
        

        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE Async_Records_Successfully_Sent__c = 1].size());
    }
    
    @isTest
    public static void rollUpTotalValuesToScheduleProcessTest() {
    	GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'Account';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Datetime.now().addDays(1);
        gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        gsp.Execution_Unique_Key__c = 'testUniqueKey';
        insert new List<GRAX_Schedule_Process__c>{gsp};
        
        GRAX_Data_Record__c dr1 = new GRAX_Data_Record__c(GRAX_Schedule_Process__c = gsp.Id, Salesforce_Object__c = 'Test', Status__c = 'Processing', Execution_Unique_Key__c = gsp.Execution_Unique_Key__c, of_Times_Sent__c = 0);
        GRAX_Data_Record__c dr2 = new GRAX_Data_Record__c(GRAX_Schedule_Process__c = gsp.Id, Salesforce_Object__c = 'Test', Status__c = 'Processing', Execution_Unique_Key__c = gsp.Execution_Unique_Key__c, of_Times_Sent__c = 0);
        insert new List<GRAX_Data_Record__c>{dr1, dr2};
        
        GRAX_Data_Record_Id__c dri1 = new GRAX_Data_Record_Id__c(GRAX_Data_Record__c = dr1.Id);
        GRAX_Data_Record_Id__c dri2 = new GRAX_Data_Record_Id__c(GRAX_Data_Record__c = dr1.Id);
        GRAX_Data_Record_Id__c dri3 = new GRAX_Data_Record_Id__c(GRAX_Data_Record__c = dr2.Id);
        insert new List<GRAX_Data_Record_Id__c>{dri1, dri2, dri3};
        
        Map<Id, GRAX_Schedule_Process__c> gsp2Check = new Map<Id, GRAX_Schedule_Process__c>([SELECT Id, Total_Records_To_Send__c, Total_Records_Sent__c, Total_Records_Errors__c FROM GRAX_Schedule_Process__c WHERE Id IN :new List<GRAX_Schedule_Process__c>{gsp}]);
		System.assertEquals(3, gsp2Check.get(gsp.Id).Total_Records_To_Send__c);
		System.assertEquals(0, gsp2Check.get(gsp.Id).Total_Records_Sent__c);
		System.assertEquals(0, gsp2Check.get(gsp.Id).Total_Records_Errors__c);
		
		dr1.Status__c = 'Error';
		dr1.of_Times_Sent__c = 5;
		dr2.Status__c = 'Sent Successful';
		update new List<GRAX_Data_Record__c>{dr1, dr2};
		
		gsp2Check = new Map<Id, GRAX_Schedule_Process__c>([SELECT Id, Total_Records_To_Send__c, Total_Records_Sent__c, Total_Records_Errors__c FROM GRAX_Schedule_Process__c WHERE Id IN :new List<GRAX_Schedule_Process__c>{gsp}]);
		System.assertEquals(3, gsp2Check.get(gsp.Id).Total_Records_To_Send__c);
		System.assertEquals(1, gsp2Check.get(gsp.Id).Total_Records_Sent__c);
		System.assertEquals(2, gsp2Check.get(gsp.Id).Total_Records_Errors__c);
    }
}
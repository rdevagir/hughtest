/*****************************************************************************************
Name              : GRAXBatchToReTrySendingDataRecordsTest
Description       : Add a new Action in the Scheduled Job table when the status is 
                    "Completed - Error Sending Data to GRAX" and then fire the batch process 
                    which will set the variables to re-send the records which "completed with error".
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
2. Nahuel Leiva            05/28/2019           David Mackey          Constellation Prod Backup Issues (https://app.asana.com/0/326600806074978/1124574665749273/f)
******************************************************************************************/
@isTest
public with sharing class GRAXBatchToReTrySendingDataRecordsTest {
    
    @isTest(seeAllData = false)
    public static void GRAXBatchToReTrySendingDataRecords_Test1() {
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(1);
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        gsp.Status__c = 'Pending send data to GRAX';
        insert gsp;
        
        GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.GRAX_Schedule_Process__c = gsp.Id;
        dr.Salesforce_Object__c = 'Test';
        dr.Status__c = 'Error';
        dr.of_Times_Sent__c = 5;
        insert new List<GRAX_Data_Record__c> {dr};
        
        GRAXBatchToReTrySendingDataRecords batch = new GRAXBatchToReTrySendingDataRecords(gsp.Id);
        
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
        
        Map<Id, GRAX_Data_Record__c> dataRecords2Check = new Map<Id, GRAX_Data_Record__c>([SELECT Id, Status__c, of_Times_Sent__c, Error_Message__c FROM GRAX_Data_Record__c]);
        System.assertEquals(0, dataRecords2Check.get(dr.Id).of_Times_Sent__c);
        
    }
}
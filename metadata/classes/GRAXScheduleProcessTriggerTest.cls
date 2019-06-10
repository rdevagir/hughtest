/*****************************************************************************************
Name              : GRAXScheduleProcessTriggerTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Ariel Yankelevich    05/08/2019          	  David Mackey        	Delete GRAXDataRecords (https://app.asana.com/0/326600806074978/1121760476564629/f)
2. Ariel Yankelevich    05/10/2019          	  David Mackey        	Deactivate/Activate Scheduled Process (https://app.asana.com/0/326600806074978/1122644080179927/f)
******************************************************************************************/
@isTest
public with sharing class GRAXScheduleProcessTriggerTest {
    
    @isTest(SeeAllData=false)
    public static void rollUpTotalRecordsToProcessTest() {
    	GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(1);
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        gsp.type__c = 'Multi-Object';
        gsp.Execution_Unique_Key__c = 'testing123';
        gsp.Status__c = 'Running';
        insert gsp;
        
        gsp.Status__c = 'Aborted';
        update gsp;
        
        Map<Id, GRAX_Schedule_Process__c> gsps2Check = new Map<Id, GRAX_Schedule_Process__c>([SELECT Id, Status__c, Execution_Unique_Key__c FROM GRAX_Schedule_Process__c WHERE Id IN :new List<GRAX_Schedule_Process__c>{gsp}]);
        System.assertEquals('Aborted', gsps2Check.get(gsp.Id).Status__c);
        System.assertNotEquals(gsp.Execution_Unique_Key__c, gsps2Check.get(gsp.Id).Execution_Unique_Key__c);
    }
    
    @isTest(SeeAllData=false)
    public static void removeNextRunDateOnInactiveTest() {
    	GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(1);
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        gsp.type__c = 'Multi-Object';
        gsp.Execution_Unique_Key__c = 'testing123';
        gsp.Status__c = 'Completed';
        gsp.Active__c = true;
        insert gsp;
        
        gsp.Active__c = false;
        update gsp;
        
        Map<Id, GRAX_Schedule_Process__c> gsps2Check = new Map<Id, GRAX_Schedule_Process__c>([SELECT Id, Next_Run_Date__c FROM GRAX_Schedule_Process__c WHERE Id IN :new List<GRAX_Schedule_Process__c>{gsp}]);
        System.assertEquals(null, gsps2Check.get(gsp.Id).Next_Run_Date__c);
    }
}
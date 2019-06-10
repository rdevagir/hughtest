/*****************************************************************************************
Name              : GRAXSchedulerToProcessSchedJobsTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner    05/23/2018                David Mackey        "Restore" Button for Backup/Archive (https://app.asana.com/0/326600806074978/665432711419635/f)
******************************************************************************************/
@isTest
public class GRAXSchedulerToProcessSchedJobsTest {

    @testSetup static void setup() {
        GRAX_Schedule_Process__c gsp1 = new GRAX_Schedule_Process__c();
        gsp1.Object_Name__c = 'GRAX_Data_Record__c';
        gsp1.Date_Field__c = 'LastModifiedDate';
        gsp1.Target_Report__c = '00OZ0000000he4iMAA';
        gsp1.Select_Criteria__c = null;
        gsp1.Schedule_Type__c = 'Once';
        gsp1.Next_Run_Date__c = Datetime.now();
        gsp1.Archive__c = true;
        insert gsp1;

        GRAXUtils.setSelectionJSON(gsp1.Id, '{"uniqueKey":"GRAX_Data_Record__c","parentUniqueKey":null,"relatedFieldName":null,"name":"GRAX_Data_Record__c","childObjRelStructure":[]}');
        
        for(String obj : new List<String>{ 'Account', 'Opportunity', 'Case', 'Event' }) {
            GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();

            gsp.Object_Name__c = obj;
            gsp.Date_Field__c = 'LastModifiedDate';
            gsp.Target_Start_Datetime__c = Datetime.now();
            gsp.Select_Criteria__c = 'Main Object not modified';
            gsp.Schedule_Type__c = 'Monthly';
            gsp.Next_Run_Date__c = Datetime.now();
            gsp.Archive__c = false;

            insert gsp;

            GRAXUtils.setSelectionJSON(gsp.Id, '{"uniqueKey":"' + obj + '","parentUniqueKey":null,"relatedFieldName":null,"name":"' + obj + '","childObjRelStructure":[]}');
        }
    }

    static testmethod void GRAXSchedulerToProcessSchedJobsTest() {
        Test.startTest();
        
        Datetime dt = Datetime.now().addMinutes(1);
        String CRON_EXP = '0 '+ dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();

        String jobId = System.schedule('GRAXSchedulerToProcessSchedJobs', CRON_EXP, new GRAXSchedulerToProcessSchedJobs());

        Test.stopTest();

        /*for(GRAX_Schedule_Process__c sp : [SELECT Id, Status__c FROM GRAX_Schedule_Process__c LIMIT 4]){
            System.assert(String.isNotBlank(sp.Status__c));
       	}*/
    }

	@isTest(seeAllData = false)
	static void GRAXSchedulerToProcessSchedJobs_Test2(){
		GRAX_Schedule_Process__c gsp1 = new GRAX_Schedule_Process__c();
        gsp1.Object_Name__c = 'GRAX_Data_Record__c';
        gsp1.Date_Field__c = 'LastModifiedDate';
        gsp1.Target_Report__c = '00OZ0000000he4iMAA';
        gsp1.Select_Criteria__c = null;
        gsp1.Schedule_Type__c = 'Once';
        gsp1.Next_Run_Date__c = Datetime.now().addDays(-1);
		gsp1.Status__c = 'Completed';
		gsp1.JobId__c = '000000000000000';
		insert gsp1;

		Test.startTest();

		GRAXSchedulerToProcessSchedJobs.enqueueSchedule(gsp1, true);

		GRAXSchedulerToProcessSchedJobs.isEmptyId('000000000000000');

		Test.stopTest();
	}
}
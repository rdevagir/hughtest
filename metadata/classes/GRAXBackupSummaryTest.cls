@isTest
private class GRAXBackupSummaryTest {
	@isTest
	static void GRAXBackupSummaryTest1() {
		Integer testRecordsSize = 2;
        
        List<GRAX_Schedule_Process__c> gspList = new List<GRAX_Schedule_Process__c>();

        for(Integer i = 0; i < testRecordsSize; i++) {
            GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();

            gsp.Object_Name__c = 'GRAX_Schedule_Process__c';
            gsp.Progressive__c = false;
            gsp.Start_Time__c = Datetime.now();
            gsp.Last_Run_Date__c = Datetime.now().addMinutes(2);
            gsp.Status__c = 'Completed';
            gsp.Execution_Unique_Key__c = 'testest' + String.valueOf(i);

            if(Math.mod(i, 2) == 0) {
                gsp.Archive__c = true;
                gsp.Send_Notifications__c = true;
                gsp.type__c = 'Hierarchy';
            } else {
                gsp.Archive__c = false;
                gsp.Send_Notifications__c = false;
                gsp.type__c = 'Multi-Object';
            }

            gspList.add(gsp);
        }

        insert gspList;


        List<GRAX_Data_Record__c> drList = new List<GRAX_Data_Record__c>();

        for(GRAX_Schedule_Process__c gsp : gspList) {
            GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
            dr.Salesforce_Object__c = gsp.Object_Name__c;
            dr.Status__c = 'Sent Successful';
            dr.of_Times_Sent__c = 1;
            dr.Error_Message__c = null;
            dr.Overall_SFObject_Process_Start_Time__c = Datetime.now().addMinutes(-1);
            dr.Overall_SFObject_Process_End_Time__c = dr.Overall_SFObject_Process_Start_Time__c.addMinutes(2);
            dr.Execution_Unique_Key__c = gsp.Execution_Unique_Key__c;

            drList.add(dr);
        }

        insert drList;

        System.assert(GRAXBackupSummary.summariesList == null);

        for(GRAX_Schedule_Process__c gsp : gspList) {
            GRAXBackupSummary.generateExecutionSummary(gsp.Id, gsp.Execution_Unique_Key__c);
        }

        System.assert(GRAXBackupSummary.summariesList <> null);
        System.assert(GRAXBackupSummary.summariesList.size() == testRecordsSize);

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        System.assert(GRAXBackupSummary.summariesList <> null);
        System.assert(GRAXBackupSummary.summariesList.size() == testRecordsSize);

        Test.startTest();

        GRAXBackupSummary.sendSummaries();

        Test.stopTest();

        System.assert(GRAXBackupSummary.summariesList.size() == 0);
	}
}
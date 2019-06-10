/*****************************************************************************************
Name              : GRAXBatchToResendDataRecordsTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       	04/17/2018			David Mackey        https://app.asana.com/0/326600806074978/633149554508924/f
2. Ariel Yankelevich     	03/14/2019         	David Mackey        Oak North Issues (https://app.asana.com/0/326600806074978/1114340491893894/f)
3. Nicolas Ralero		 	04/11/2019			David Mackey		GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
4. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
******************************************************************************************/
@isTest
private class GRAXBatchToResendDataRecordsTest {
    
    @isTest(seeAllData = false)
    static void GRAXBatchToResendDataRecordsTest() {
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(1);
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        gsp.type__c = 'Multi-Object';
        gsp.Status__c = 'Pending send data to GRAX';
        insert gsp;
        
        GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.GRAX_Schedule_Process__c = gsp.Id;
		dr.Salesforce_Object__c = 'Test';
		dr.Status__c = 'Error';
		dr.of_Times_Sent__c = 4;

        GRAX_Data_Record__c dr2 = new GRAX_Data_Record__c();
        dr2.GRAX_Schedule_Process__c = gsp.Id;
		dr2.Salesforce_Object__c = 'Test';
		dr2.Status__c = 'Error';
		dr2.of_Times_Sent__c = 5;

		insert new List<GRAX_Data_Record__c> { dr, dr2 };

		Attachment att = new Attachment();
		att.Name = 'request.txt';
		att.Body = Blob.valueOf('{}');
		att.ParentId = dr.Id;

        Attachment att2 = new Attachment();
		att2.Name = 'request.txt';
		att2.Body = Blob.valueOf('{}');
		att2.ParentId = dr2.Id;

        insert new List<Attachment> { att, att2 };

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, '{"message": "Test successful"}', 'http://test.grax.io/applications/neo4j/configure', null);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        database.executebatch(new GRAXBatchToResendDataRecords());

        Test.stopTest();

        Map<Id, GRAX_Data_Record__c> dataRecords2Check = new Map<Id, GRAX_Data_Record__c>([SELECT Id, Status__c, of_Times_Sent__c, Error_Message__c FROM GRAX_Data_Record__c]);

        System.assertEquals(5, dataRecords2Check.get(dr.Id).of_Times_Sent__c);
        System.assertEquals(null, dataRecords2Check.get(dr.Id).Error_Message__c);
        System.assertEquals('Sent Successful', dataRecords2Check.get(dr.Id).Status__c);

        System.assertEquals(5, dataRecords2Check.get(dr2.Id).of_Times_Sent__c);
        System.assertEquals('Error', dataRecords2Check.get(dr2.Id).Status__c);
    }
    
    @isTest(seeAllData = false)
    static void GRAXBatchToResendDataRecordsTest2() {
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(1);
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        gsp.type__c = 'Multi-Object';
        gsp.Status__c = 'Pending send data to GRAX';
        gsp.Execution_Unique_Key__c = 'testUniqueKey';
        insert new List<GRAX_Schedule_Process__c>{gsp};
        
        GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.GRAX_Schedule_Process__c = gsp.Id;
		dr.Salesforce_Object__c = 'Test';
		dr.Status__c = 'Processing';
		dr.Execution_Unique_Key__c = gsp.Execution_Unique_Key__c;
		dr.of_Times_Sent__c = 4;

        GRAX_Data_Record__c dr2 = new GRAX_Data_Record__c();
        dr2.GRAX_Schedule_Process__c = gsp.Id;
		dr2.Salesforce_Object__c = 'Test';
		dr2.Status__c = 'Error';
		dr2.Execution_Unique_Key__c = gsp.Execution_Unique_Key__c;
		dr2.of_Times_Sent__c = 4;

		insert new List<GRAX_Data_Record__c> { dr, dr2 };
		
		GRAX_Data_Record_Id__c dri1 = new GRAX_Data_Record_Id__c(GRAX_Data_Record__c = dr.Id);
        insert new List<GRAX_Data_Record_Id__c>{dri1};
		
		dr.Status__c = 'Error';
		dr.of_Times_Sent__c = 5;
		update new List<GRAX_Data_Record__c> { dr };
		
		Map<Id, GRAX_Schedule_Process__c> gsp2Check = new Map<Id, GRAX_Schedule_Process__c>([SELECT Id, Total_Records_Errors__c FROM GRAX_Schedule_Process__c WHERE Id IN :new List<GRAX_Schedule_Process__c>{gsp}]);
		System.assertEquals(1, gsp2Check.get(gsp.Id).Total_Records_Errors__c);

		Attachment att = new Attachment();
		att.Name = 'request.txt';
		att.Body = Blob.valueOf('{}');
		att.ParentId = dr.Id;

        Attachment att2 = new Attachment();
		att2.Name = 'request.txt';
		att2.Body = Blob.valueOf('{}');
		att2.ParentId = dr2.Id;

        insert new List<Attachment> { att, att2 };

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, '{"message": "Test successful"}', 'http://test.grax.io/applications/neo4j/configure', null);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        GRAXBatchToResendDataRecords b = new GRAXBatchToResendDataRecords();
        b.currentJobId = gsp.Id;
        b.isExecuteNow = true;
        database.executebatch(b);

        Test.stopTest();

        gsp2Check = new Map<Id, GRAX_Schedule_Process__c>([SELECT Id, Status__c FROM GRAX_Schedule_Process__c WHERE Id IN :new List<GRAX_Schedule_Process__c>{gsp}]);        
        System.assertEquals('Completed - Errors sending data', gsp2Check.get(gsp.Id).Status__c);
    }
    
    @isTest(seeAllData = false)
    static void GRAXBatchToResendDataRecordsTest3(){
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(1);
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        gsp.type__c = 'Hierarchy';
        gsp.Status__c = 'Running';
        insert gsp;

		Attachment att1 = new Attachment(ParentId = gsp.Id, Name = 'DelayedGraxDataRecordIdsToUpdateStatus.txt', Body = Blob.valueOf(JSON.serialize(new List<String>{'12345'})));
		insert new List<Attachment>{att1};

		GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.GRAX_Schedule_Process__c = gsp.Id;
		dr.Salesforce_Object__c = 'Test';
		dr.Status__c = 'Error';
		dr.of_Times_Sent__c = 4;

        GRAX_Data_Record__c dr2 = new GRAX_Data_Record__c();
        dr2.GRAX_Schedule_Process__c = gsp.Id;
		dr2.Salesforce_Object__c = 'Test';
		dr2.Status__c = 'Error';
		dr2.of_Times_Sent__c = 5;

		insert new List<GRAX_Data_Record__c> { dr, dr2 };

		Attachment att = new Attachment();
		att.Name = 'request.txt';
		att.Body = Blob.valueOf('{}');
		att.ParentId = dr.Id;

        Attachment att2 = new Attachment();
		att2.Name = 'request.txt';
		att2.Body = Blob.valueOf('{}');
		att2.ParentId = dr2.Id;

        insert new List<Attachment> { att, att2 };

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, '{"message": "Test successful"}', 'http://test.grax.io/applications/neo4j/configure', null);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);        
		database.executebatch(new GRAXBatchToResendDataRecords());

        Test.stopTest();

		Attachment attachment2Check = [SELECT Id, Body FROM Attachment WHERE Id = : att1.Id];
		System.assert(attachment2Check.Body.toString().contains(dr.Id));
	}

	@isTest(seeAllData = false)
    static void GRAXBatchToResendDataRecordsTest4(){
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(1);
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        gsp.type__c = 'Hierarchy';
        gsp.Status__c = 'Pending send data to GRAX';
        insert gsp;

		GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
        dr.GRAX_Schedule_Process__c = gsp.Id;
		dr.Salesforce_Object__c = 'Test';
		dr.Status__c = 'Error';
		dr.of_Times_Sent__c = 4;

        GRAX_Data_Record__c dr2 = new GRAX_Data_Record__c();
        dr2.GRAX_Schedule_Process__c = gsp.Id;
		dr2.Salesforce_Object__c = 'Test';
		dr2.Status__c = 'Error';
		dr2.of_Times_Sent__c = 5;

		insert new List<GRAX_Data_Record__c> { dr, dr2 };

		Attachment att1 = new Attachment(ParentId = gsp.Id, Name = 'DelayedGraxDataRecordIdsToUpdateStatus.txt', Body = Blob.valueOf(JSON.serialize(new List<String>{dr.Id, dr2.Id})));
		insert new List<Attachment>{att1};

		Attachment att = new Attachment();
		att.Name = 'request.txt';
		att.Body = Blob.valueOf('{}');
		att.ParentId = dr.Id;

        Attachment att2 = new Attachment();
		att2.Name = 'request.txt';
		att2.Body = Blob.valueOf('{}');
		att2.ParentId = dr2.Id;

        insert new List<Attachment> { att, att2 };

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, '{"message": "Test successful"}', 'http://test.grax.io/applications/neo4j/configure', null);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);		
		database.executebatch(new GRAXBatchToResendDataRecords());

        Test.stopTest();

		Map<Id, GRAX_Data_Record__c> dataRecords2Check = new Map<Id, GRAX_Data_Record__c>([SELECT Id, Status__c, of_Times_Sent__c, Error_Message__c FROM GRAX_Data_Record__c]);
        
        System.assertEquals(null, dataRecords2Check.get(dr.Id).Error_Message__c);
        System.assertEquals('Sent Successful', dataRecords2Check.get(dr.Id).Status__c);
        
        System.assertEquals('Error', dataRecords2Check.get(dr2.Id).Status__c);
    }
}
/*****************************************************************************************
Name              : GRAXBatchToProcessSchedJobTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner    		05/23/2018          David Mackey        "Restore" Button for Backup/Archive (https://app.asana.com/0/326600806074978/665432711419635/f)
2. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
******************************************************************************************/
@IsTest(SeeAllData=false)
public class GRAXBatchToProcessSchedJobTest {

    @isTest
    static void GRAXBatchToProcessSchedJobTest1() {
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
        insert gsp;

        GRAXUtils.setSelectionJSON(gsp.Id, '[{"uniqueKey":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c","parentUniqueKey":null,"relatedFieldName":null,"name":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c","childObjRelStructure":[]}]');

        System.assertNotEquals(null, GRAXUtils.getSelectionJSON(gsp.Id));

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"message": "Test successful"}', null);

        GRAXBatchToProcessSchedJob b = new GRAXBatchToProcessSchedJob(gsp.Id, null, 0, null, true, true);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Id jobId = Database.executebatch(new GRAXBatchToProcessSchedJobMainObject(b), 1);

        Test.stopTest();

        for(GRAX_Schedule_Process__c schedProcess : [SELECT Id, Next_Run_Date__c, Last_Run_Date__c, Status__c FROM GRAX_Schedule_Process__c WHERE Id = :gsp.Id]) {
            System.assertEquals('Completed', schedProcess.Status__c);
        }

        //GRAX_Data_Record__c dr = [SELECT Id FROM GRAX_Data_Record__c WHERE GRAX_Schedule_Process__c = :gsp.Id LIMIT 1];

        //System.assertEquals(1, [SELECT Id FROM GRAX_Data_Record_Id__c WHERE GRAX_Data_Record__c = :dr.Id AND SFDC_Id__c = :gq.Id].size());
    }

    @isTest
    static void GRAXBatchToProcessSchedJobTest2() {
        GRAX_Data_Record__c gq = new GRAX_Data_Record__c();
        gq.Salesforce_Object__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c';
        insert gq;

        Attachment att = new Attachment();      
        att.Name = 'Test';
        att.body = Blob.valueOf('Test');
        att.parentId = gq.id;
        insert att;

        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_End_Datetime__c = Date.today().addDays(1);
        //gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        insert gsp;

        GRAXUtils.setSelectionJSON(gsp.Id, '{"uniqueKey":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c","parentUniqueKey":null,"relatedFieldName":null,"name":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c","childObjRelStructure":[{"uniqueKey":"GRAX_Data_Record__c_Attachments","parentUniqueKey":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c","relatedFieldName":"ParentId","name":"Attachment","childObjRelStructure":[]}]}');

        String selectedJSON = GRAXUtils.getSelectionJSON(gsp.Id);

        System.assertNotEquals(null, selectedJSON);

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"message": "Test successful"}', null);
        
        GRAXBatchToProcessSchedJob b1 = new GRAXBatchToProcessSchedJob(gsp.Id, null, 0, null, false, false);
        GRAXBatchToProcessSchedJob b2 = new GRAXBatchToProcessSchedJob(gsp.Id, b1.objects2Process, 1, b1.currentSelectCriteria, b1.isExecuteNow, false);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Database.executebatch(b1, 1);
        //Database.executebatch(b2, 1);

        Test.stopTest();

        GRAX_Data_Record__c dr;

        for(GRAX_Data_Record__c r : [SELECT Id FROM GRAX_Data_Record__c WHERE GRAX_Schedule_Process__c = :gsp.Id LIMIT 1]) {
            dr = r;
        }

        System.assertNotEquals(null, dr);

        System.assertEquals(1, [SELECT Id FROM GRAX_Data_Record_Id__c WHERE GRAX_Data_Record__c = :dr.Id AND SFDC_Id__c = :gq.Id].size());
    }

    @isTest
    static void GRAXBatchToProcessSchedJobTestAttachmentArchive() {
        GRAX_Data_Record__c gq = new GRAX_Data_Record__c();
        gq.Salesforce_Object__c = 'GRAX_Data_Record__c';
        insert gq;

        Attachment att = new Attachment();      
        att.Name = 'Test';
        att.body = Blob.valueOf('Test');
        att.parentId = gq.id;
        insert att;

        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'GRAX_Data_Record__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(-1);
        //gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = true;
        insert gsp;

        GRAXUtils.setSelectionJSON(gsp.Id, '{"uniqueKey":"GRAX_Data_Record__c_Attachments","parentUniqueKey":"GRAX_Data_Record__c","relatedFieldName":"ParentId","name":"Attachment","childObjRelStructure":[]}');

        System.assertNotEquals(null, GRAXUtils.getSelectionJSON(gsp.Id));

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"message": "Test successful"}', null);

        GRAXBatchToProcessSchedJob b = new GRAXBatchToProcessSchedJob(gsp.Id, null, 0, null, false, false);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Id jobId = Database.executebatch(b, 2);

        Test.stopTest();

        GRAX_Data_Record__c dr = [SELECT Id FROM GRAX_Data_Record__c WHERE GRAX_Schedule_Process__c = :gsp.Id LIMIT 1];

        Attachment att2 = [SELECT Id, Body FROM Attachment WHERE ParentId = :dr.Id ORDER BY CreatedDate DESC LIMIT 1];
        String att2BodyString = att2.Body.toString();

        System.assertNotEquals(null, att2);

        System.assert(att2BodyString.contains('GRAX_Data_Record_Id'));
        System.assert(att2BodyString.contains('Ready to Process'));
    }
    
    @isTest(seeAllData = false)
    static void GRAXBatchToProcessSchedJobTestContentDocument() {
        GRAX_Schedule_Process__c gq = new GRAX_Schedule_Process__c();
        gq.Object_Name__c = 'GRAX_Schedule_Process__c';
        insert gq;

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = Blob.valueOf('some content to access later on');
        cv.Title = 'some title';
        cv.PathOnClient = 'some title'+'.txt';        
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
		cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
		cdl.LinkedEntityId = gq.id;
		cdl.ShareType = 'V';
		insert cdl;
              
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(-1);
        //gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        insert gsp;

        GRAXUtils.setSelectionJSON(gsp.Id, '{"uniqueKey":"GRAX_Schedule_Process__c_ContentDocumentLink","parentUniqueKey":"GRAX_Schedule_Process__c","relatedFieldName":"LinkedEntityId","name":"ContentDocumentLink","childObjRelStructure":[]}');

        System.assertNotEquals(null, GRAXUtils.getSelectionJSON(gsp.Id));

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"message": "Test successful"}', null);

        GRAXBatchToProcessSchedJob b = new GRAXBatchToProcessSchedJob(gsp.Id, null, 0, null, false, false);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Id jobId = Database.executebatch(b, 2);

        Test.stopTest();
	
		System.assertEquals(1, [SELECT Id FROM GRAX_Data_Record__c WHERE GRAX_Schedule_Process__c = :gsp.Id AND Salesforce_Object__c IN ('ContentDocumentLink', 'ContentVersion')].size());
    }
    
    @isTest(seeAllData = false OnInstall=false)
    static void GRAXBatchToProcessSchedJobTestFeedComment() {
        Account acc = new Account(Name = 'Test acc1', BillingCity = 'USA');
        insert acc;

        FeedItem fi = new FeedItem();
        fi.ParentId = acc.Id;
        fi.Body = 'test body';
        insert fi;
        
        FeedComment fc = new FeedComment();
        fc.FeedItemId = fi.Id;
        fc.CommentBody = 'test body';
        insert fc;
              
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'Account';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(-1);
        //gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = false;
        insert gsp;

        GRAXUtils.setSelectionJSON(gsp.Id, '{"uniqueKey":"Account_FeedComment","parentUniqueKey":"Account","relatedFieldName":"ParentId","name":"FeedComment","childObjRelStructure":[]}');
        
        System.assertNotEquals(null, GRAXUtils.getSelectionJSON(gsp.Id));

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"message": "Test successful"}', null);

        GRAXBatchToProcessSchedJob b = new GRAXBatchToProcessSchedJob(gsp.Id, null, 0, null, false, false);

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Id jobId = Database.executebatch(b, 2);

        Test.stopTest();
	
		System.assertEquals(1, [SELECT Id FROM GRAX_Data_Record__c WHERE GRAX_Schedule_Process__c = :gsp.Id AND Salesforce_Object__c IN ('FeedComment')].size());
    }

    @isTest
    static void GRAXBatchToProcessSchedJobExecuteNowTest() {
        Datetime now = Datetime.now();
        
        GRAX_Data_Record__c gq = new GRAX_Data_Record__c();
        gq.Salesforce_Object__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c';
        insert gq;

        Attachment att = new Attachment();      
        att.Name = 'Test';
        att.body = Blob.valueOf('Test');
        att.parentId = gq.id;
        insert att;

        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';
        gsp.Date_Field__c = 'CreatedDate';
        gsp.Target_Start_Datetime__c = Date.today().addDays(-1);
        gsp.Target_End_Datetime__c = Date.today().addDays(1);
        //gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = now;
        gsp.Archive__c = true;
        insert gsp;

        GRAXUtils.setSelectionJSON(gsp.Id, '{"uniqueKey":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c","parentUniqueKey":null,"relatedFieldName":null,"name":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c","childObjRelStructure":[]}');

        System.assertNotEquals(null, GRAXUtils.getSelectionJSON(gsp.Id));

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"message": "Test successful"}', null);

        GRAXBatchToProcessSchedJob b = new GRAXBatchToProcessSchedJob(gsp.Id, null, 0, null, true, false);

        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        Id jobId = Database.executebatch(b, 1);

        Test.stopTest();

        GRAX_Data_Record__c dr = [SELECT Id FROM GRAX_Data_Record__c WHERE GRAX_Schedule_Process__c = :gsp.Id LIMIT 1];

        //System.assertEquals(1, [SELECT Id FROM GRAX_Schedule_Process__c WHERE Id = :gsp.Id AND Next_Run_Date__c = :now].size());
        //System.assertEquals(1, [SELECT Id FROM GRAX_Data_Record_Id__c WHERE Status__c = 'Successfully Deleted' AND GRAX_Data_Record__c = :dr.Id AND SFDC_Id__c = :gq.Id].size());
        //System.assertEquals(0, [SELECT Id FROM GRAXQuery__c WHERE Id = :gq.Id].size());
    }

    @isTest
    static void GRAXBatchToProcessSchedJobTestStatus() {
        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Total_Records_To_Send__c = 10;
        gsp.Total_Records_Sent__c = 10;
        insert gsp;

        gsp.Status__c = 'Completed';
        update gsp;

        for(GRAX_Schedule_Process__c gsp2 : [SELECT Status__c FROM GRAX_Schedule_Process__c WHERE Id = :gsp.Id]) {
            System.assertEquals(gsp2.Status__c, gsp.Status__c);
            System.assertEquals(gsp2.Status__c, 'Completed');
        }
    }
    
}
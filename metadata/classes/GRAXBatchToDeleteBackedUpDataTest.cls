/*****************************************************************************************
Name              : GRAXBatchToDeleteBackedUpDataTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       05/24/2018             David Mackey        "Restore" Button for Backup/Archive (https://app.asana.com/0/326600806074978/665432711419635/f)
******************************************************************************************/
@isTest
public class GRAXBatchToDeleteBackedUpDataTest {

    @isTest(seeAllData = false)
    static void GRAXBatchToProcessSchedJobTest1() {
        List<GRAX_Data_Record__c> drList = new List<GRAX_Data_Record__c>();

        for(Integer i=0; i < 3; i++) {
            GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
            dr.Status__c = 'Sent Successful';
            dr.of_Times_Sent__c = 1;

            drList.add(dr);
        }

        insert drList;

        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c';
        gsp.Date_Field__c = 'LastModifiedDate';
        gsp.Target_Start_Datetime__c = Datetime.now().addDays(1);
        gsp.Select_Criteria__c = 'Main Object not modified';
        gsp.Schedule_Type__c = 'Once';
        gsp.Next_Run_Date__c = Datetime.now();
        gsp.Archive__c = true;
        gsp.Execution_Unique_Key__c = 'test123';
        insert gsp;

        GRAXUtils.setSelectionJSON(gsp.Id, '{"uniqueKey":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c","parentUniqueKey":null,"relatedFieldName":null,"name":"' + GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c","childObjRelStructure":[]}');

        System.assertNotEquals(null, GRAXUtils.getSelectionJSON(gsp.Id));
        
        GRAX_Archive_Process__c archiveProc = new GRAX_Archive_Process__c();
        archiveProc.GRAX_Schedule_Process__c = gsp.Id;
        archiveProc.Async_Records_Successfully_Sent__c = 0;
        archiveProc.Async_Records_to_Process__c = 0;
        archiveProc.Records_Successfully_Sent__c = 3;
        archiveProc.Records_To_Process__c = 0;
        archiveProc.Execution_Unique_Key__c = 'test123';
        insert archiveProc;

        List<Id> backupedIds = new List<Id>();

        for(GRAX_Data_Record__c gdr : drList) {
            GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
            dr.Salesforce_Object__c = GRAXUtils.getNameSpacePrefix() + 'GRAX_Data_Record__c';
            dr.Status__c = 'Sent Successful';
            dr.of_Times_Sent__c = 1;
            dr.Error_Message__c = null;
            dr.GRAX_Schedule_Process__c = gsp.Id;
            dr.GRAX_Archive_Process__c = archiveProc.Id;
            insert dr;

            System.assertNotEquals(null, dr.Id);

            Attachment req_att = new Attachment();
            req_att.Name = 'request.txt';
            req_att.Body = Blob.valueOf('{}');
            req_att.ParentId = dr.Id;
            insert req_att;
            
            System.assertNotEquals(null, req_att.Id);
            
            GRAX_Data_Record_Id__c dataRecId = new GRAX_Data_Record_Id__c();
            dataRecId.SFDC_Id__c = gdr.Id;
            dataRecId.GRAX_Data_Record__c = dr.Id;
            dataRecId.Status__c = 'To be Deleted';
            
            insert dataRecId;

            backupedIds.add(gdr.Id);

            System.assertNotEquals(null, dataRecId.Id);
        }

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', JSON.serialize(backupedIds), null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        System.assertEquals(1, [SELECT Id FROM GRAX_Archive_Process__c WHERE Id = :archiveProc.Id AND Status__c = 'Ready to Delete'].size());

        Test.startTest();

        GRAXBatchToDeleteBackedUpData b = new GRAXBatchToDeleteBackedUpData();
        Id jobId = Database.executebatch(b);

        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM GRAX_Data_Record__c WHERE Id IN :drList].size());
    }
}
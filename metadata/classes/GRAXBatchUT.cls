/*****************************************************************************************
Name              : GRAXBatchUT
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
2. Nahuel Leiva       		05/17/2019			David Mackey		Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
3. Ariel Yankelevich    	05/31/2019          David Mackey        Constellation Prod Backup Issues (https://app.asana.com/0/326600806074978/1124574665749273/f)
4. Ariel Yankelevich     	06/05/2019          David Mackey        Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
******************************************************************************************/

@isTest(SeeAllData=false)
public with sharing class GRAXBatchUT {
    
    @isTest
    static void ProcessHistoryTest() {
		GRAXBatch b = new GRAXBatch('test');

        Test.startTest();

        Id jobId = Database.executebatch(b, 1);

        Test.stopTest();
    }

	/*****************************************************************************************
	Name              : executeGRAXBatchesTest
	Description       : 
	Revision History  :
	Created/Modified by   Created/Modified Date     Requested by		Related Task/Issue     
	----------------------------------------------------------------------------------------
	1. Nahuel Leiva       		05/17/2019			David Mackey		Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
	2. Ariel Yankelevich    	05/31/2019          David Mackey        Constellation Prod Backup Issues (https://app.asana.com/0/326600806074978/1124574665749273/f)
	3. Ariel Yankelevich     	06/05/2019          David Mackey        Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
	******************************************************************************************/
    @isTest(seeAllData = false)
    static void executeGRAXBatchesTest() {
        String result = '';
        
        try {
            GRAXBatch.executeGRAXBatches('lkajhsfkluhjqiowafhjklasf');
        } catch (Exception e) {
            result = e.getMessage();
        }
        
        GRAXBatch.executeGRAXBatches('{"batchName" : "DeleteBackedUpData", "jobId" : "a051U00000EFGVqQAP", "cleanObjectName": "", "query": "SELECT Id FROM GRAX_Data_Record_Id__c WHERE Id <> null"}');
        GRAXBatch.executeGRAXBatches('{"batchName" : "ResendDataRecords", "jobId" : "a051U00000EFGVqQAP", "cleanObjectName": "", "query": "SELECT Id FROM GRAX_Data_Record__c"}');
        GRAXBatch.executeGRAXBatches('{"batchName" : "CleanDataRecords", "jobId" : "a051U00000EFGVqQAP", "cleanObjectName": "GRAX_Data_Record__c", "chunkSize": 50, "useIdChunking": true, "query": "SELECT Id FROM GRAX_Data_Record__c WHERE Id <> null", "chunkIdRangeSize": 5000}');
        
        try {
            GRAXBatch.executeGRAXBatches('{ "jobId" : "a051U00000EFGVqQAP", "cleanObjectName": ""}');
        } catch (Exception e) {
            result = e.getMessage();
        }
        System.assert(result <> '');
    }
}
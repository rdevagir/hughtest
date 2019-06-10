/*****************************************************************************************
Name              : GRAXRESTWS_BackupProcessNotification
Description       : Test methods for the GRAXRESTWS_RestoreProcessNotification APEX Class
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner	  05/29/2019			    David Mackey          Review "Backup Stats" (https://app.asana.com/0/326600806074978/1107778902588819/f)
******************************************************************************************/
@isTest
public class GRAXRESTWS_BackupProcessNotificationTest {
	
    @isTest
    static void GRAXRESTWS_BackupProcessNotification_Test() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

		GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
		gsp.Execution_Unique_Key__c = 'test';
		gsp.Name__c = 'test';
		insert gsp;

		GRAXUtils.setSelectionJSON(gsp.Id, '["' + gsp.Id + '"]', 'usersSelectionJSON.txt');
		GRAXUtils.setSelectionJSON(gsp.Id, 'test@test.com,test2@test.com', 'extraEmails.txt');
        
        String jsonString = '{"GRAX_Schedule_Process" : "' + gsp.Id + '", "GRAX_Execution_Unique_Key" : "' + gsp.Execution_Unique_Key__c + '", "GRAX_Backup_Summary" : "test", "GRAX_Backup_Summary_Link": "http://test.com", "GRAX_Backup_Summary_Name": "test" }';

        req.requestUri = '/services/apexrest/GRAXRESTWS/BackupProcessNotification/';
        req.requestBody = Blob.valueOf(jsonString);                   
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        GRAXRESTWS_BackupProcessNotification.doPost();
        
        String result = String.valueOf(res.responseBody);
    }
}
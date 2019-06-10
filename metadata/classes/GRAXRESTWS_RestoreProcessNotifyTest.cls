/*****************************************************************************************
Name              : GRAXRESTWS_RestoreProcessNotifyTest
Description       : Test methods for the GRAXRESTWS_RestoreProcessNotification APEX Class
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas Ralero			01/09/2019			David Mackey		Restore Status (https://app.asana.com/0/326600806074978/962748953350535/f)
******************************************************************************************/
@isTest
public class GRAXRESTWS_RestoreProcessNotifyTest {
	
    @isTest
    static void GRAXRESTWS_RestoreProcessNotification_Test() {
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        
        String jsonString = '{"GRAX_Execution_Unique_Key" : "123456", "GRAX_Restore_Summary" : "The results are the following: test test test.", "GRAX_Restore_Link" : "http://www.test.com" }';

        req.requestUri = '/services/apexrest/GRAXRESTWS/RestoreProcessNotification/';
        req.requestBody = Blob.valueOf(jsonString);                   
        req.httpMethod = 'POST';
        
        RestContext.request = req;
        RestContext.response = res;
        
        GRAXRESTWS_RestoreProcessNotification.doPost();
        
        String result = String.valueOf(res.responseBody);
    }
}
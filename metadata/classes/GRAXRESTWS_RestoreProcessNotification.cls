/*****************************************************************************************
Name              : GRAXRESTWS_RestoreProcessNotification
Description       : This Web Service class sends an email notification when the GRAX Restore process has finished
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas Ralero			01/08/2019			David Mackey		Restore Status (https://app.asana.com/0/326600806074978/962748953350535/f)
******************************************************************************************/
@RestResource(urlMapping='/GRAXRESTWS/RestoreProcessNotification/*')
global with sharing class GRAXRESTWS_RestoreProcessNotification {
		
	@HttpPost
	global static void doPost(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        String result = '';
        
        try{
        	// Get the JSON from the request params
        	//String JSONStr = req.params.get('payload');
        	String JSONStr = req.requestBody.toString();
        	Map<String,Object> m = (Map<String,Object>) JSON.deserializeUntyped(JSONStr);
        	
        	// Get the Email Template that will be used to send the email message
        	EmailTemplate template = [SELECT Id from EmailTemplate WHERE DeveloperName = 'GRAX_Restore_Notification3'];

			// Render the email template as a new email message
			Messaging.SingleEmailMessage emailMsg = Messaging.renderStoredEmailTemplate(template.Id, UserInfo.getUserId(), null);
			emailMsg.setSaveAsActivity(false);
        	
        	// Parse the JSON and replace the custom merge fields in the rendered template with the corresponding value in the JSON
			for(String mergeField : m.keySet()){
				String mergeFieldValue = String.valueOf(m.get(mergeField));					
				emailMsg.htmlBody = emailMsg.htmlBody.replace('[[' + mergeField + ']]', mergeFieldValue);					
			}
			
			// FOR TEST PURPOSES ONLY - TO BE REMOVED
			// emailMsg.setTreatTargetObjectAsRecipient(false);                 
            // emailMsg.setToAddresses(new List<String>{'nralero@sysmart.com.ar'});
            //
            
            // Sends the email message
			if(!Test.isRunningTest()){
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.Email>{emailMsg}); 
            }
            
			res.statusCode = 200;
			result = '{"result" : "Email notification successfully sent."}';    
        }catch(Exception e){            
            res.statusCode = 500;
            result = '{"error":"' + (e.getMessage() + '\nStack Trace: ' + e.getStackTraceString() + '\nLine Number: ' + e.getLineNumber() + '\nException Type: ' + e.getTypeName()).replace('"', '\\"') + '"}';
        }
        
        res.responseBody = Blob.valueOf(result);
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
	}
}
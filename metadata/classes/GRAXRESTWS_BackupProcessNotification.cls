/*****************************************************************************************
Name              : GRAXRESTWS_BackupProcessNotification
Description       : This Web Service class sends an email notification when the GRAX Backup process has finished
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas Ralero			01/08/2019			David Mackey		Restore Status (https://app.asana.com/0/326600806074978/962748953350535/f)
2. Leandro Brunner			02/27/2019			David Mackey		Review "Backup Stats" (https://app.asana.com/0/326600806074978/1107778902588819/f)
******************************************************************************************/
@RestResource(urlMapping='/GRAXRESTWS/BackupProcessNotification/*')
global with sharing class GRAXRESTWS_BackupProcessNotification {
		
	@HttpPost
	global static void doPost(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        String result = '';
        
        try{
        	// Get the JSON from the request params
        	String JSONStr = req.requestBody.toString();
        	Map<String,Object> m = (Map<String,Object>) JSON.deserializeUntyped(JSONStr);
        	
        	// Get the Email Template that will be used to send the email message
        	EmailTemplate template = [SELECT Id from EmailTemplate WHERE DeveloperName = 'GRAX_Schedule_Process_Notification4'];

			// Render the email template as a new email message
			Messaging.SingleEmailMessage emailMsg = Messaging.renderStoredEmailTemplate(template.Id, UserInfo.getUserId(), null);
			emailMsg.setSaveAsActivity(false);
        	
        	// Parse the JSON and replace the custom merge fields in the rendered template with the corresponding value in the JSON
			for(String mergeField : m.keySet()){
				String mergeFieldValue = String.valueOf(m.get(mergeField));					
				emailMsg.htmlBody = emailMsg.htmlBody.replace('[[' + mergeField + ']]', mergeFieldValue);					
			}

			List<String> emailsTo = new List<String>();

			Id gspId = (Id)m.get('GRAX_Schedule_Process');

			Attachment usersSelectionAttachment = GRAXUtils.getSelectionAttachment(gspId, 'usersSelectionJSON.txt');
            List<Object> usersSelectionIds = (List<Object>)JSON.deserializeUntyped(GRAXUtils.getSelectionJSON(usersSelectionAttachment, '[]'));
			
			for(Object oId : usersSelectionIds) {
				emailsTo.add((Id)oId);
			}

			if(emailsTo.size() > 0) {
				emailMsg.setToAddresses(emailsTo);
			}

			Attachment extraEmailsAttachment = GRAXUtils.getSelectionAttachment(gspId, 'extraEmails.txt');
            String extraEmails = GRAXUtils.getSelectionJSON(extraEmailsAttachment, null);

			if(extraEmails <> null) {
				emailMsg.setBccAddresses(extraEmails.split(','));
			}

			// FOR TEST PURPOSES ONLY - TO BE REMOVED
			// emailMsg.setTreatTargetObjectAsRecipient(false);                 
            // emailMsg.setToAddresses(new List<String>{'lbrunner@sysmart.com.ar'});
            
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
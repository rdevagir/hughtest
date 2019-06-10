/* --------------------------------------------------------------------------
 * This file is subject to the terms and conditions defined in
 * file https://github.com/HardingPoint/GRAXForSFDC/blob/master/LICENSE,
 * which is part of this source code package.
 * --------------------------------------------------------------------------
 *          Copyright (c) 2017-2018 Harding Point
 *                  All rights reserved
 * --------------------------------------------------------------------------
 * Support:	Support@Grax.io
 * Website:	https://grax.io
 * Github:	https://github.com/HardingPoint/GRAXForSFDC
 * License:	https://github.com/HardingPoint/GRAXForSFDC/blob/master/LICENSE
 * --------------------------------------------------------------------------*/

global virtual with sharing class GRAXCloud extends GRAXSettings{
	//Class that manages full communication with GRAX Cloud.

	// Constructor
    //public GRAXCloud() {	
    //}

	

	global static CallOutResponse calloutnow(String url, String content) {
		CallOutResponse response;
		
		String apiURL = url;
		String requestBody = content;
		String httpMethod = 'POST';
		String contentType = '';
		Map<String, String> headers = new Map<String, String>();
		
		GRAXCloud gx = new GRAXCloud();
		if (gx.ProperlyConfigured){
			if (url == ''){				
				apiURL = gx.ApiURL;
			}

			headers.put('Content-Type', 'application/json');
			headers.put('licensetoken', gx.LicenseToken);
			headers.put('authorizationToken', gx.ApiToken);
			headers.put('x-api-key', gx.GatewayToken);
			headers.put('sfdcorgid', UserInfo.getOrganizationId());
		}

		// Call the method to execute the Callout
		response = doHTTP(httpMethod, requestBody, apiURL, headers, true);
			
		return response;
	}

	/*****************************************************************************************
	Name              : callout
	Description       : Add the sobjectName parameter when the function is called from a trigger.
	Revision History  :
	Created/Modified by   Created/Modified Date     Requested by		Related Task/Issue     
	----------------------------------------------------------------------------------------
	1. Leandro Brunner       04/17/2018				David Mackey		https://app.asana.com/0/326600806074978/633149554508924/f
	******************************************************************************************/
	global static void callout(String url, String content) {
		if(!GRAXBatchToDeleteBackedUpData.is_GRAXBatchToDeleteBackedUpData_Running){
			GRAXCloud.callout(url, content, Trigger.new);
		}
	}


	/*****************************************************************************************
	Name              : callout
	Description		  : Add the "triggerNew" parameter, used when the method is called from the "GRAXQueueTriggerCallout" asynchronous queueable job
	Revision History  :
	Created/Modified by   Created/Modified Date     Requested by		Related Task/Issue     
	----------------------------------------------------------------------------------------
	1. Nicolas Ralero			04/30/2019			Dave Mackey			PCORI Trigger Error Message (https://app.asana.com/0/326600806074978/1118654927922828/f)
	******************************************************************************************/
	public static void callout(String url, String content, List<SObject> triggerNew){
		String sobjectName = '';
		String sfdcIds = '';

		if(triggerNew <> null && triggerNew[0] <> null && triggerNew[0].Id <> null) {
			sobjectName = String.valueOf(triggerNew[0].Id.getSobjectType());

			for(Integer i = 0; i < triggerNew.size(); i++){
				sfdcIds += ';' + triggerNew[i].Id;
			}
			sfdcIds = sfdcIds.substring(1);
		}

		if(!Test.isRunningTest()) GRAXCloud.callout(url, content, sobjectName, sfdcIds);
	}

	/*****************************************************************************************
	Name              : callout
	Description       : Create a new "GRAX_Data_Record__c" next to your "Attachment" from the parameters,
						and try to add to the queue the process responsible for making the call. (GRAXQueueCallout)
	Revision History  :
	Created/Modified by   Created/Modified Date     Requested by		Related Task/Issue     
	----------------------------------------------------------------------------------------
	1. Leandro Brunner       04/17/2018				David Mackey		https://app.asana.com/0/326600806074978/633149554508924/f
	******************************************************************************************/
    public static void callout(String url, String content, String sobjectName, String sfdcIds) {
		GRAX_Data_Record__c dr = new GRAX_Data_Record__c();
		dr.Salesforce_ID__c = sfdcIds;
		dr.Salesforce_Object__c = sobjectName;
		dr.Status__c = 'Not Sent';
		dr.of_Times_Sent__c = 0;
		dr.Error_Message__c = null;		

		Attachment req_att = new Attachment();
		req_att.Name = 'request.txt';
		req_att.Body = Blob.valueOf(content);

		if(!GRAXCloud.isGRAXQueueTriggerCalloutRunning){
			insert dr;

			req_att.ParentId = dr.Id;
			insert req_att;

			// Verify limits before adding the callout to the queue.
			if(Limits.getQueueableJobs() != Limits.getLimitQueueableJobs() || Test.isRunningTest()) {
				System.enqueueJob(new GRAXQueueCallout(url, content, dr));
			} else {
				dr.Status__c = 'Not Processed - Queuable Jobs Full';
				update dr;
			}
		}else{
			sendAndUpdateGRAXDataRecord(url, content, dr);

			req_att.ParentId = dr.Id;
			insert req_att;
		}
	}

	/*****************************************************************************************
	Name              : sendDataRecordToGRAX
	Description       : Makes the call to the "calloutnow" function, check its result, and sets the "GRAX_Data_Record__c" fields.
	Revision History  :
	Created/Modified by   Created/Modified Date     Requested by		Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Leandro Brunner       04/17/2018				David Mackey		https://app.asana.com/0/326600806074978/633149554508924/f
	******************************************************************************************/
	public static void sendDataRecordToGRAX(String url, String content, GRAX_Data_Record__c dr) {
		CallOutResponse callOutRes = GRAXCloud.calloutnow(url, content);
		
		dr.Error_Message__c = '';
		dr.Last_Sent_Date__c = System.now();
		dr.of_Times_Sent__c += 1;
			
		if(callOutRes.success){
			dr.Status__c = 'Sent Successful';
		}else{
			dr.Status__c = 'Error';
			dr.Error_Message__c = callOutRes.response;
		}
	}

	/*****************************************************************************************
	Name              : GRAXQueueCallout
	Description       : Queueable that makes the asynchronous call to "calloutnowAndUpdateDataRecord".
	Revision History  :
	Created/Modified by   Created/Modified Date     Requested by		Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Leandro Brunner       04/17/2018				David Mackey		https://app.asana.com/0/326600806074978/633149554508924/f
	******************************************************************************************/
	public class GRAXQueueCallout implements Queueable, Database.AllowsCallouts {
		String url;
		String content;
		GRAX_Data_Record__c dataRecord;

		public GRAXQueueCallout(String url, String content, GRAX_Data_Record__c dataRecord) {
			this.url = url;
			this.content = content;
			this.dataRecord = dataRecord;	
		}

		public void execute(QueueableContext context) {
			sendAndUpdateGRAXDataRecord(url, content, dataRecord);
		}
	}

	/*****************************************************************************************
	Name              : GRAXQueueTriggerCallout
	Description       : Queueable class that makes asynchronous callouts from the GRAX APEX Triggers
	Revision History  :
	Created/Modified by		Created/Modified Date	Requested by		Related Task/Issue             
	----------------------------------------------------------------------------------------
	1. Nicolas Ralero			04/29/2019			David Mackey		PCORI Trigger Error Message (https://app.asana.com/0/326600806074978/1118654927922828/f)
	******************************************************************************************/

	public static Boolean isGRAXQueueTriggerCalloutRunning = false;

	public class GRAXQueueTriggerCallout implements Queueable, Database.AllowsCallouts {
		List<SObject> triggerNew;
		List<SObject> triggerOld;

		public GRAXQueueTriggerCallout(List<SObject> triggerNew, List<SObject> triggerOld) {
			this.triggerNew = triggerNew;
			this.triggerOld = triggerOld;
		}

		public void execute(QueueableContext context) {
			GRAXCloud.isGRAXQueueTriggerCalloutRunning = true;

			String content = GRAXApi.jsonContent(triggerNew, triggerOld);

			GRAXCloud.callout('', content, triggerNew);
		}
	}

	// Method called from both the "callout" synchronous process, and the "GRAXQueueTriggerCallout" asynchronous queueable job
	private static void sendAndUpdateGRAXDataRecord(String url, String content, GRAX_Data_Record__c dataRecord){
		if(url <> null && content <> null && dataRecord <> null) {
			GRAXCloud.sendDataRecordToGRAX(url, content, dataRecord);
			upsert dataRecord;
		}
	}
	
	// Following is a structure that encapsulates the HTTP request and allows to parse HTTP callout responses
	global class CallOutResponse {
		public String response {get; set;}
		public Boolean success {get; set;}
		
		public CallOutResponse(Boolean success, String response){
			this.success = success;
			this.response = response;
		}
	}
	
	
	// Generic method to do callouts via HTTP protocol
	public static CallOutResponse doHTTP(String httpMethod, String parameters, String endpoint, Map<String, String> headers, Boolean auth){
        CallOutResponse callOutRes = new CallOutResponse(false, '');
        
        if(string.isBlank(httpMethod)){
        	httpMethod = 'GET';
        }
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res;
        req.setTimeout(120000);
        req.setMethod(httpMethod);

		if(auth <> null && auth && endpoint.indexOf('grax.io')==-1) {
			GRAXCloud gx = new GRAXCloud();
			// Set up the Username and Password to authenticate on the server
	        String username = gx.GatewayToken;
	        String password = gx.ApiToken;        
	        if (username!='' && password!=''){
	        	    String token = EncodingUtil.base64Encode(Blob.valueOf(username + ':' + password));
	        		// Add the Basic authorization header to the HTTP Call
	        		req.setHeader('Authorization', 'Basic ' + token);
	        }
		}

        if(headers <> null){
        	for(String headerName : headers.keySet()){ 
       			req.setHeader(headerName, headers.get(headerName));
        	}
        }

        if(string.isNotBlank(parameters)){
        	req.setBody(parameters);
        }
        req.setEndpoint(endpoint);

        try{
            res = h.send(req);
        }catch(System.CalloutException e) {
			// GRAXLogs.addLogException(e);
			
            callOutRes.response = 'CalloutException: ' + e.getMessage() + '\nStack Trace: ' + e.getStackTraceString() + '\nLine Number: ' + e.getLineNumber() + '\nException Type: ' + e.getTypeName();
        }
        
        if(res <> null){
        	callOutRes.success = String.valueOf(res.getStatusCode()).startsWith('2');
        	
        	callOutRes.response = '';
        	if(!callOutRes.success){
        		callOutRes.response = 'Status Code: ' + res.getStatusCode() + ', Status: ' + res.getStatus() + ', Response Body: ';
        	}
        	callOutRes.response += res.getBody();
	    }
        
        return callOutRes;
    }

	public static CallOutResponse doHTTP(String httpMethod, String parameters, String endpoint, Map<String, String> headers) {
		return doHTTP(httpMethod, parameters, endpoint, headers, true);
	}
}
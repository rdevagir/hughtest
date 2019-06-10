/*****************************************************************************************
Name              : GRAXRESTWS_QueryReferenceRecords
Description       : Web Service method to query the reference records from the "getReferenceInfoInBulk" function in Node JS, and verify if they exist in Salesforce
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas Ralero			10/24/2018			David Mackey		  Mass Restore multiple records (https://app.asana.com/0/326600806074978/774373429525631/f)
******************************************************************************************/

@RestResource(urlMapping='/GRAXRESTWS/QueryReferenceRecords/*')
global with sharing class GRAXRESTWS_QueryReferenceRecords {
	
	@HttpPost
	global static void doPost(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        String result = '';
        
        try{
        	String query = req.requestBody.toString();
        	
        	// Remove the first and last quotes
            query = query.removeStart('"').removeEnd('"'); 
        	
        	List<SObject> records = Database.query(query);
        	
        	result = JSON.serialize(records);        	        	        	        	   	        	        	 
        	
			res.statusCode = 200;       
        }catch(Exception e){            
            res.statusCode = 500;
            result = '{"error":"' + (e.getMessage() + '\nStack Trace: ' + e.getStackTraceString() + '\nLine Number: ' + e.getLineNumber() + '\nException Type: ' + e.getTypeName()).replace('"', '\\"') + '"}';
        }
        
        res.responseBody = Blob.valueOf(result);
        res.addHeader('Content-Type', 'application/json;charset=UTF-8');
	}
}
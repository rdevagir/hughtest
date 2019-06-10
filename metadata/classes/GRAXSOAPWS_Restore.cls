/*****************************************************************************************
Name              : GRAXSOAPWS_Restore
Description       : This Web Service class allow to restore from Node
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner    05/28/2019                David Mackey          Restore Button on External Object (https://app.asana.com/0/326600806074978/1124474865343484/f)
******************************************************************************************/
global with sharing class GRAXSOAPWS_Restore {

	webservice static String restore(String params) {    
        String result = '';
        
        try {
        	Map<String,Object> m = (Map<String,Object>) JSON.deserializeUntyped(params);

			String externalObjectAPIName = (String)m.get('externalObjectAPIName');
			String externalObjectId = (String)m.get('externalObjectId');

			String objecttype = (String)m.get('objecttype');
			Id recordId;
			Id graxorgid;

			for(SObject so : Database.query('SELECT Id__c, graxorgid__c FROM ' + externalObjectAPIName + ' WHERE Id=\'' + externalObjectId + '\'')) {
				System.debug(JSON.serializePretty(so));
				
				recordId = (Id)so.get('Id__c');
				graxorgid = (Id)so.get('graxorgid__c');
			}

			GRAXCloud.CallOutResponse callOutRes = GRAXRestoreCtrl.restoreSObject(objecttype, recordId, graxorgid);
            
			if(callOutRes == null) {
				result = '{"error" : "Bad Params"}';
			} else {
				result = callOutRes.response;  
			}
        } catch (Exception e) {            
            result = '{"error":"' + (e.getMessage() + '\nStack Trace: ' + e.getStackTraceString() + '\nLine Number: ' + e.getLineNumber() + '\nException Type: ' + e.getTypeName()).replace('"', '\\"') + '"}';
        }
        
        return result;
	}

}
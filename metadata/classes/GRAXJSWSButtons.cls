/*****************************************************************************************
Name              : GRAXJSWSButtons
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner    	 05/28/2019             David Mackey        Restore Button on External Object (https://app.asana.com/0/326600806074978/1124474865343484/f)
2. Ariel Yankelevich     05/30/2019           	David Mackey        Restore Button on External Object (https://app.asana.com/0/326600806074978/1124474865343484/f)
******************************************************************************************/
global with sharing class GRAXJSWSButtons {

	// This Web Service method allows to invoke the NodeJS's Restore Recursive method
	webservice static String restoreExternalObject(String params) {    
        String result = '';
        
        try {
        	Map<String,Object> m = (Map<String,Object>) JSON.deserializeUntyped(params);

			String externalObjectAPIName = (String)m.get('externalObjectAPIName');
			String externalObjectId = (String)m.get('externalObjectId');

			String objecttype = (String)m.get('objecttype');
			String recordId, graxorgid;
			
			String idFieldName = 'Id__c';
			if(m.containsKey('idFieldName')){
				idFieldName = (String)m.get('idFieldName');
			}
			
			String graxorgidFieldName = 'graxorgid__c';
			if(m.containsKey('graxorgidFieldName')){
				graxorgidFieldName = (String)m.get('graxorgidFieldName');
			}

			for(SObject so : Database.query('SELECT ' + idFieldName + ', ' + graxorgidFieldName + ' FROM ' + externalObjectAPIName + ' WHERE Id = \'' + externalObjectId + '\'')) {
				System.debug(JSON.serializePretty(so));
				
				recordId = (String)so.get(idFieldName);
				graxorgid = (String)so.get(graxorgidFieldName);
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
/* --------------------------------------------------------------------------
 * This file is subject to the terms and conditions defined in
 * file https://github.com/HardingPoint/GRAXForSFDC/blob/master/LICENSE,
 * which is part of this source code package.
 * --------------------------------------------------------------------------
 *          Copyright (c) 2017-2018 Harding Point
 *                  All rights reserved
 * --------------------------------------------------------------------------
 * Support: Support@Grax.io
 * Website: https://grax.io
 * Github:  https://github.com/HardingPoint/GRAXForSFDC
 * License: https://github.com/HardingPoint/GRAXForSFDC/blob/master/LICENSE
 * --------------------------------------------------------------------------*/

/*****************************************************************************************
Name              : GRAXApi
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner			04/07/2018
2. Ariel Yankelevich		07/13/2018			David Mackey		Pass the SF "Company Name" in the Json (https://app.asana.com/0/326600806074978/741694214355703/f)
3. Joe Gaska				07/30/2018			David Mackey		Removed S3 settings sent only with audit trail on.	
4. Leandro Brunner			07/31/2018			David Mackey		Too many fields/too much to query errors (https://app.asana.com/0/326600806074978/763054542504017/f)
5. Leandro Brunner			08/09/2018			David Mackey		Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
6. Ariel Yankelevich		02/20/2019			David Mackey		GRAX "XF" Fields (https://app.asana.com/0/326600806074978/1110592656396265/f)
7. Ariel Yankelevich		02/28/2019			David Mackey		Metadata Sync (https://app.asana.com/0/326600806074978/1111506265745344/f)
8. Leandro Brunner			03/08/2019			David Mackey		New Issues (https://app.asana.com/0/326600806074978/1112342626420899/f)
9. Nicolas Ralero			04/29/2019			David Mackey		PCORI Trigger Error Message (https://app.asana.com/0/326600806074978/1118654927922828/f)
10. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
11. Nicolas Ralero			05/22/2019			David Mackey		Backup Object for Failed ObjectTimeMachine Records (https://app.asana.com/0/326600806074978/1120749825873615/f)
******************************************************************************************/

global class GRAXApi extends GRAXCloud {
    // -------------------------------------------------
    // https://grax.io
    // Support Contact - Support@Grax.io
    // -------------------------------------------------
	private static Boolean isArchive = false;

	global static void jsonContentCallout(List<SObject> triggerNew, List<SObject> triggerOld, Boolean isSynchronous){
		// Run the "JSON Content Callout" logic, synchronously, if it was specifically defined in the APEX Trigger, on the object calling this functionality, or if the "Queueable Jobs" Limit, have been reached.
		// Otherwise, call the "JSON Content Callout" logic, asynchronously, through the corresponding "Queueable Job".
		if(isSynchronous || Limits.getQueueableJobs() == Limits.getLimitQueueableJobs()){
			GRAXCloud.callout('', GRAXApi.jsonContent(triggerNew, triggerOld));
		}else{
			System.enqueueJob(new GRAXQueueTriggerCallout(triggerNew, triggerOld));
		}
	}

	global static String jsonContent(List<SObject> triggerNew, List<SObject> triggerOld) {
        return jsonContent(triggerNew,triggerOld,'');
    }

	public static String jsonContentArchive(String objectName, Map<Id, String> recsJSONById) {
        isArchive = true;

        // Include the reference fields and GRAX keys to each JSON record in the Map.
        addGRAXFieldsToJSONMap(recsJSONById, objectName);
    
        // Concatenate the JSON representation for each record in a JSON List
        String recJSONList = '[' + String.join(recsJSONById.values(), ',') + ']';

        // Return the entire JSON including the GRAX Headers, and the list of records
        return generateGRAXJsonContent('[]', recJsonList, new GRAXSettings(objectName), objectName, '', true);
    }
 
    public static String jsonContent(List<SObject> triggerNew, List<SObject> triggerOld, String graxconfig) {
        if (triggerNew != null || triggerOld != null){
            String newObjects = '[]';
            String oldObjects = '[]';
            String Operation = '';
            String FilterFields = '';
            
            Schema.SObjectType sObjectType;
            if (triggerNew != null){
                    Operation = 'Insert Operation';
                    sObjectType = triggerNew.getSObjectType();
                }else if (triggerOld != null){
                    Operation = 'Delete Operation';
                    sObjectType = triggerOld.getSObjectType();
                }
            
                String ObjectType = '' + sObjectType;
                GRAXSettings gxcSettings = new GRAXSettings(ObjectType);
            
            gxcSettings.debug('GRAXCloud.jsonContent', Operation + ' : ObjectType=' + ObjectType);
            
            newObjects = JSON.serialize(triggerNew, true);

            if((Trigger.isExecuting && (Trigger.isInsert || Trigger.isUpdate)) || isArchive || (GRAXCloud.isGRAXQueueTriggerCalloutRunning && triggerNew <> null)) {
                Map<Id, String> recsJSONById = new Map<Id, String>();

                // Generate the map of JSON records.
                for(SObject so : triggerNew) {
                    recsJSONById.put(so.Id, JSON.serialize(so, true));
                }

                // Add Reference fields and GRAX keys to each JSON record.
                addGRAXFieldsToJSONMap(recsJSONById, ObjectType);

                // Concatenate the list of JSON records.
                newObjects = '[' + String.join(recsJSONById.values(), ',') + ']';
            }

            if (triggerOld != null) {
                oldObjects = JSON.serialize(triggerOld, true);
            }

            return generateGRAXJsonContent(oldObjects, newObjects, gxcSettings, ObjectType, graxconfig, isArchive);
		}else{
			GRAXSettings.debug('GRAXCloud.jsonContent','Both Lists Empty, should never happen','ERROR triggerNew==null && triggerOld==null', 0);
			return '{}';
		}

    }

    /*****************************************************************************************
    Name              : generateGRAXJsonContent
    Description       : Return the GRAX Api JSON with the headers from the records JSON
                        String oldObjects : JSON with the old records.
                        String newObjects : JSON with the new records.
                        GRAXSettings gxcSettings : GRAXSettings from the SObject Name
                        String objectName : SObject Name
                        String graxconfig : GRAX Configuration
                        Boolean isArchive 
    Revision History  :
    Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
    ----------------------------------------------------------------------------------------
    1. Leandro Brunner        08/09/2018            David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
    ******************************************************************************************/
    public static String generateGRAXJsonContent(String oldObjects, String newObjects, GRAXSettings gxcSettings, String objectName, String graxconfig, Boolean isArchive) {
        if (newObjects != null || oldObjects != null){
            String Operation = '';
            String FilterFields = '';
            
            if (newObjects != null) {
                Operation = 'Insert Operation';
            } else if (oldObjects != null) {
                Operation = 'Delete Operation';
                    }
                    
            gxcSettings.debug('GRAXCloud.jsonContent', Operation + ' : ObjectType=' + objectName);

            /*--------------------------------------------------*/
                
            /* --------------------------------------------------   
            // If graxconfig is NOT null it has been passed in from outside a trigger and is correct
            if ((graxconfig != null && graxconfig != '') && triggerNew != null) {
                    gxcSettings.debug('GRAXCloud.jsonContent',' Called from GRAX Configuration');
                newObjects = JSON.serialize(triggerNew);
            }else if (triggerNew != null && (graxconfig == null || graxconfig == '') ){
                    gxcSettings.debug('GRAXCloud.jsonContent',' Called from Trigger');
                    if(gxcSettings.GRAXQuery == null){
                        newObjects = JSON.serialize(triggerNew);            
                    } else if(gxcSettings.GRAXQuery.Enable_Audit_Log__c == true){
                        FilterFields = gxcSettings.GRAXQuery.Selected_Fields__c;
                        newObjects = JSON.serialize(triggerNew);
                    }else{
                        // Pass filtered fields 
                        List<Id> Ids = GetIds(triggerNew);
                        if(Test.isRunningTest()) {
                            FilterFields = 'Id';
                        } else {
                            FilterFields = gxcSettings.GRAXQuery.Selected_Fields__c;
                        }
                        String Query = 'Select ' + FilterFields + ' FROM ' + objectName + ' Where Id in :Ids';
                        newObjects = JSON.serialize(Database.query(Query));
                    }         
            }
			--------------------------------------------------*/   
            
            if(objectName <> null){
            	// Include the Lookup Map within the graxconfig attribute
            	graxconfig = '{"sobject":\"' + objectName + '\",' + 
	    							'"fieldsselected":"",' +
	    							'"orderby":"",' + 
	    							'"filterby":"",' + 
	    							'"typemap":{},' + 
	    							'"lookupmap":' + 
	    								JSON.serialize(GRAXUtils.getReferenceFieldsMap(objectName)) + 
	    						'}';
	    						
            }
            
            String graxconfigsetting = '"graxconfig": ' + graxconfig + ',';

	        String s3settings = '';  
	        
	        // ----------------------------------------------------------------------------------------
			//	        if (gxcSettings.GRAXQuery.Enable_Audit_Log__c == true && triggerNew != null && 
			//	        		gxcSettings.graxConfig.s3accesskeyid__c!='' && gxcSettings.graxConfig.s3secretaccesskey__c!='' ){
			// ----------------------------------------------------------------------------------------
	        		
	        		s3settings = '"s3audit":"true",' + 
	        					 '"s3accesskeyid":"' + gxcSettings.graxConfig.s3accesskeyid__c + '",' + 
	        					 '"s3secretaccesskey":"' + gxcSettings.graxConfig.s3secretaccesskey__c + '",' + 
	        					 '"s3bucket":"' + gxcSettings.graxConfig.s3bucket__c + '",' + 
	        					 '"s3region":"' + gxcSettings.graxConfig.s3region__c + '",' + 
	        					 '"filterfields":"' + FilterFields + '",';
	        					 
	        	// ----------------------------------------------------------------------------------------				 
			//}
			// ----------------------------------------------------------------------------------------
	       
	        String content = '{' + 
									'"archive": '+ (isArchive? 'true':'false') + ',' +
	        						'"orgId": "'+ UserInfo.getOrganizationId() + '",' +
	        						'"userId": ' + JSON.serialize(UserInfo.getUserId()) + ',' + 
	        						'"graphdburl": "' + gxcSettings.graphdburl + '",' + 
	        						'"postgresurl": "' + gxcSettings.PostgresURL + '",' + 
	        						s3settings +
	        						graxconfigsetting + 
	        						'"new": ' + newObjects + ',' + 
	        						'"old": ' + oldObjects + 
	        					'}';        
	
	        return content;
		}else{
			GRAXSettings.debug('GRAXCloud.jsonContent','Both JSON Empty, should never happen','ERROR newObjects==null && oldObjects==null', 0);
			return '{}';
		}
    }

    /*****************************************************************************************
    Name              : addGRAXFieldsToJSONMap
    Description       : Add Reference Fields and GRAX Keys to each JSON Record in the Map structure.
                        Map<Id, String> recsJSONById : Map of JSON rerialized records by Id.
                        String objectName: SObject name of the records.
    Revision History  :
    Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
    ----------------------------------------------------------------------------------------
    1. Leandro Brunner        08/09/2018            David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
    2. Leandro Brunner        04/04/2019            David Mackey        Time Machine Enhancements (https://app.asana.com/0/326600806074978/1116669836270094/f)
    ******************************************************************************************/
    public static void addGRAXFieldsToJSONMap(Map<Id, String> recsJSONById, String objectName) {
        for(Id recId : recsJSONById.keySet()) {
            // Get JSON of the record.
            String rec = recsJSONById.get(recId);

            // Remove the brackets chars '{', '}'
            rec = rec.substring(1, rec.length() - 1);

            // Concatenate the key "GRAXCompanyName" to the JSON.
            rec += ',"GRAXCompanyName":"' + UserInfo.getOrganizationName() + '"';

            // Add brackets and update the map.
            recsJSONById.put(recId, '{' + rec + '}');
        }

        // Get list of reference fields to query
        List<String> referenceFields = GRAXUtils.getReferenceFields(objectName);

        List<String> extraFieldsToQuery = new List<String>();

        if(Trigger.isExecuting || GRAXCloud.isGRAXQueueTriggerCalloutRunning) {
            Set<String> objectFieldSet = GRAXUtils.getDescribeFieldsResultForObject(objectName).keySet();

            if(objectFieldSet.contains('Name')) {
                extraFieldsToQuery.add('Name');
            }
        }

        if(referenceFields.size() > 0) {
            Set<Id> recIds = recsJSONById.keySet();

            for(List<Object> rFields : GRAXUtils.splitList(referenceFields, 35)) {
                // build the query to retrive same records including the name field of every lookup in the current object.
                String strQuery = 'SELECT ' + String.join(rFields, ',') + ' FROM ' + objectName;
                strQuery += ' WHERE Id IN :recIds';

                for(SObject so : Database.query(strQuery)) {
                    Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(recsJSONById.get(so.Id));

                    for(Object refFld : rFields) {
                        Object val = GRAXUtils.parseSObjectFieldValue(so, (String)refFld);

                        if(val <> null) {
                            m.put(GRAXUtils.getGraxFieldFromReference((String)refFld), val);
                        }
                    }
        
                    recsJSONById.put(so.Id, JSON.serialize(m, true));
                }
            }
        }

        if(extraFieldsToQuery.size() > 0) {
            Set<Id> recIds = recsJSONById.keySet();

            for(List<Object> eFields : GRAXUtils.splitList(extraFieldsToQuery, 35)) {
                // build the query to retrive same records including the name field of every lookup in the current object.
                String strQuery = 'SELECT ' + String.join(eFields, ',') + ' FROM ' + objectName;
                strQuery += ' WHERE Id IN :recIds';

                for(SObject so : Database.query(strQuery)) {
                    Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(recsJSONById.get(so.Id));

                    for(Object refFld : eFields) {
                        Object val = GRAXUtils.parseSObjectFieldValue(so, (String)refFld);

                        if(val <> null) {
                            m.put((String)refFld, val);
                        }
                    }
        
                    recsJSONById.put(so.Id, JSON.serialize(m, true));
                }
            }
        }
    }
    
    public static void cloudconfig(String sobjectName){
        GRAXSettings gxcSettings = new GRAXSettings(sobjectName);
        String url = gxcSettings.ApiURL + '/applications/neo4j/configure';
        String payload = '{' +
                '"sfdcorgid": "'+ UserInfo.getOrganizationId() + '",' +
                '"userId": "' + UserInfo.getUserId() + '",' + 
                '"sfdcobjectname": "' + sobjectName + '",' +
                '"graphdburl": "' + gxcSettings.graphdburl + '"' +
            '}';
            
        // No Need to do this anymore removing Neo4j Support    
        // GRAXCloud.calloutnow(url, payload);
    }

    public static SObject mock(String sobjectName) {
        SObjectType t = Schema.getGlobalDescribe().get(sobjectName);
        SObject o = t.newSobject();
        Map<String, Schema.SObjectField> m = t.getDescribe().fields.getMap();

        for (String fieldName : m.keySet()) {
        DescribeFieldResult f = m.get(fieldName).getDescribe();
        if (!f.isNillable() && f.isCreateable() && !f.isDefaultedOnCreate()) {
        if (f.getType() == DisplayType.Boolean) {
            o.put(f.getName(), false);
            }
            else if (f.getType() == DisplayType.Currency) {
                o.put(f.getName(), 0);
            }
            else if (f.getType() == DisplayType.Date) {
                o.put(f.getName(), Date.today());
            }
            else if (f.getType() == DisplayType.DateTime) {
                o.put(f.getName(), System.now());
            }
            else if (f.getType() == DisplayType.Double) {
                o.put(f.getName(), 0.0);
            }
            else if (f.getType() == DisplayType.Email) {
                o.put(f.getName(), 'foo@foo.com');
            }
            else if (f.getType() == DisplayType.Integer) {
                o.put(f.getName(), 0);
            }
            else if (f.getType() == DisplayType.Percent) {
                o.put(f.getName(), 0);
            }
            else if (f.getType() == DisplayType.Phone) {
                o.put(f.getName(), '555-555-1212');
            }
            else if (f.getType() == DisplayType.String) {
                o.put(f.getName(), 'TEST');
            }
            else if (f.getType() == DisplayType.TextArea) {
                o.put(f.getName(), 'TEST');
            }
            else if (f.getType() == DisplayType.Time) {
                o.put(f.getName(), System.now().time());
            }
            else if (f.getType() == DisplayType.URL) {
                o.put(f.getName(), 'http://foo.com');
            }
            else if (f.getType() == DisplayType.PickList) {
                o.put(f.getName(), f.getPicklistValues()[0].getValue());
            }
        }
    }
    return o;
    }
}
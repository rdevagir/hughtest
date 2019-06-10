/*****************************************************************************************
Name              : GRAXBatchToDeleteBackedUpData
Description       : This batch process deletes all the SFDC records that have been successfully sent to the GRAX Cloud
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Ariel Yankelevich		05/09/2018			David Mackey		GRAX Archiving -- Salesforce Delete (https://app.asana.com/0/326600806074978/628249897265165/f)
2. Ariel Yankelevich		06/05/2018			David Mackey		Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
3. Leandro Brunner			11/06/2018			David Mackey		Minor UI Enhancements (https://app.asana.com/0/326600806074978/880565726418326/f)
4. Leandro Brunner			12/26/2018			David Mackey		Backup/Archive UI Updates (https://app.asana.com/0/326600806074978/950283827722121/f)
5. Nicolas Ralero			01/04/2019			David Mackey		Chatter Backup (https://app.asana.com/0/326600806074978/958019584834204/f)
6. Leandro Brunner			01/23/2019			David Mackey		Update GRAXBatchtoDelete Process (https://app.asana.com/0/326600806074978/999564713541979/f)
7. Leandro Brunner			02/27/2019			David Mackey		Review "Backup Stats" (https://app.asana.com/0/326600806074978/1107778902588819/f)
8. Ariel Yankelevich      	03/21/2019          David Mackey        Oak North Updates #2 (https://app.asana.com/0/326600806074978/1114502823954369/f)
9. Leandro Brunner			03/21/2019			David Mackey		Review "Backup Stats" (https://app.asana.com/0/326600806074978/1107778902588819/f)
10. Ariel Yankelevich      	03/28/2019          David Mackey        GRAX Summary Issues (https://app.asana.com/0/326600806074978/1116043357503391/f)
11. Ariel Yankelevich      	04/05/2019          David Mackey        Latest Package Bugs (https://app.asana.com/0/326600806074978/1117046362603242/f)
12. Ariel Yankelevich      	04/09/2019          David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
13. Ariel Yankelevich     	06/05/2019          David Mackey        Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
******************************************************************************************/
global class GRAXBatchToDeleteBackedUpData implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {
    global String query = '';
    public Boolean isExecuteNow = false;
    public Id currentJobId;
    public Boolean startToDeleteBackedUpData = true;
    
    private String executionUniqueKey;
    private Set<Id> graxArchiveProcessIds = new Set<Id>();
    private Set<String> objects2PreventCallingEmptyRecycleBin = new Set<String>{'CaseComment', 'IdeaComment'};

    private Map<String, Set<Id>> deletedRecordsByExecUniqueKey = new Map<String, Set<Id>>();
    private Map<String, Set<String>> deletedObjectTypesByExecUniqueKey = new Map<String, Set<String>>();
    
    // Monitor variable to prevent calling any trigger when deleting the SFDC records
    public static Boolean is_GRAXBatchToDeleteBackedUpData_Running = false;
    
    public GRAXBatchToDeleteBackedUpData(){
    	// First get the Ids of the GRAX Archive Processes that meet the criteria
    	List<String> gapIds = new List<String>();
    	for(GRAX_Archive_Process__c gap : [SELECT Id, Execution_Unique_Key__c, GRAX_Schedule_Process__r.Execution_Unique_Key__c FROM GRAX_Archive_Process__c WHERE Status__c IN ('Ready to Delete','Delete Process Started') AND GRAX_Schedule_Process__r.Status__c <> 'Aborted']){
    		// Make sure that the Execution_Unique_Key__c matches between the GRAX Schedule Process and its respective GRAX Archive Process record
    		if(gap.Execution_Unique_Key__c == gap.GRAX_Schedule_Process__r.Execution_Unique_Key__c){
    			gapIds.add(gap.Id);
    		}
    	}
    	
    	startToDeleteBackedUpData = gapIds.size() > 0;
    	
    	query = 'SELECT Id FROM GRAX_Data_Record_Id__c WHERE Id = \'000000000000000\'';
    	
    	if(startToDeleteBackedUpData){
	    	// Define the main query to retrieve GRAX_Data_Record_Id__c records that have been successfully sent to GRAX
	        //query = 'SELECT Id, SFDC_Id__c, of_Attempts_to_Delete__c, GRAX_Data_Record__r.Salesforce_Object__c, GRAX_Data_Record__r.GRAX_Archive_Process__c, GRAX_Data_Record__r.GRAX_Schedule_Process__r.Execution_Unique_Key__c, GRAX_Data_Record__r.GRAX_Schedule_Process__r.Status__c FROM GRAX_Data_Record_Id__c WHERE GRAX_Data_Record__r.GRAX_Archive_Process__r.Status__c IN (\'Ready to Delete\',\'Delete Process Started\') AND Status__c NOT IN (\'Successfully Deleted\',\'Deleted with Master Parent\') AND (Status__c <> \'Delete Error\' OR of_Attempts_to_Delete__c < 5) AND GRAX_Data_Record__r.GRAX_Schedule_Process__r.Status__c <> \'Aborted\'';
	        query = 'SELECT Id, SFDC_Id__c, of_Attempts_to_Delete__c, GRAX_Data_Record__r.Salesforce_Object__c, GRAX_Data_Record__r.GRAX_Archive_Process__c, GRAX_Data_Record__r.GRAX_Schedule_Process__r.Execution_Unique_Key__c, GRAX_Data_Record__r.GRAX_Schedule_Process__r.Status__c FROM GRAX_Data_Record_Id__c';
	        query += ' WHERE Status__c NOT IN (\'Successfully Deleted\',\'Deleted with Master Parent\') AND (Status__c <> \'Delete Error\' OR of_Attempts_to_Delete__c < 5) AND GRAX_Data_Record__r.GRAX_Archive_Process__c IN (\'' + String.join(gapIds, '\',\'') + '\')';
    	}
    }
    
    global Database.querylocator start(Database.BatchableContext BC) {
        if(isExecuteNow && currentJobId <> null) {
            query += ' AND GRAX_Data_Record__r.GRAX_Schedule_Process__r.Id = :currentJobId';
        
            for(GRAX_Schedule_Process__c gsp : [SELECT Id, Status__c, Execution_Unique_Key__c FROM GRAX_Schedule_Process__c WHERE Id = :currentJobId LIMIT 1]) {
                executionUniqueKey = gsp.Execution_Unique_Key__c;
                
                gsp.Status__c = 'Deleting Salesforce records';
                update gsp;
            }
            
            // Find the GRAX Archive Process Id correspondent to this Schedule-Archive Job
            if(executionUniqueKey <> null){
            	for(GRAX_Archive_Process__c gap : [SELECT Id FROM GRAX_Archive_Process__c WHERE GRAX_Schedule_Process__c =: currentJobId AND Execution_Unique_Key__c =: executionUniqueKey LIMIT 1]) {
            		graxArchiveProcessIds.add(gap.Id);
            	}
            }
        }
        
        query += ' ORDER BY GRAX_Data_Record__r.GRAX_Schedule_Process__c, GRAX_Data_Record__r.Process_Object_Index__c DESC, GRAX_Data_Record__r.Salesforce_Object__c';
        
        return Database.getQueryLocator(query);
    }

    private List<Id> getBackupedIds(Set<Id> scopeIds, String executionUniqueKey, Set<String> objectTypes) {
        List<Id> backupedIds = new List<Id>();

        if(executionUniqueKey <> null && scopeIds.size() > 0) {
            GRAXSettings gxcSettings = new GRAXSettings();

            String url = gxcSettings.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake/verifyExistentBackups';

            String content = '';
            content = '{' +
                '"orgid": "'+ UserInfo.getOrganizationId() + '",' +
                '"ids": ' + JSON.serialize(scopeIds) + ',' +
                '"executionUniqueKey": "'+ executionUniqueKey + '",' +
                '"objecttypes": ' + JSON.serialize(objectTypes) +
            '}';

            System.debug(content);
            
            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(url, content);

            System.debug(callOutRes);

            if(callOutRes.success) {
                for(Object elem : (List<Object>)JSON.deserializeUntyped(callOutRes.response)){
                	backupedIds.add((Id)elem);
                }
            }
        }

        return backupedIds;
    }

    private void sendDeletedRecordsIds() {
        System.debug(JSON.serialize(deletedRecordsByExecUniqueKey));

        if(deletedRecordsByExecUniqueKey.size() > 0) {
            GRAXSettings gxcSettings = new GRAXSettings();

            String url = gxcSettings.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake/setAsArchived';

            String content = '';
            content = '{' +
                '"orgid": "'+ UserInfo.getOrganizationId() + '",' +
                '"deletedRecordsByExecUniqueKey": ' + JSON.serialize(deletedRecordsByExecUniqueKey) + ',' +
                '"objecttypesByExecUniqueKey": '+ JSON.serialize(deletedObjectTypesByExecUniqueKey) +
            '}';

            System.debug(content);
            
            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(url, content);

            System.debug(callOutRes);

            if(callOutRes.success) {
                deletedRecordsByExecUniqueKey.clear();
            }
        }

        System.debug(JSON.serialize(deletedRecordsByExecUniqueKey));
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        sendDeletedRecordsIds();

		if(this.isExecuteNow && this.currentJobId <> null && GRAXUtils.checkIfScheduleIsAborted(this.currentJobId)) {
            System.abortJob(BC.getJobId());
        }else{
            Map<Id, GRAX_Schedule_Process__c> scheduleProcesses2UpById = new Map<Id, GRAX_Schedule_Process__c>();
            List<Map<Id, SObject>> listOfRecs2DelByDataRecId = new List<Map<Id, SObject>>();
            Map<String, Set<Id>> recIdsByExecUniqueKey = new Map<String, Set<Id>>();
            Map<String, Set<String>> objectTypesByExecUniqueKey = new  Map<String, Set<String>>();
            Set<Id> verifiedBackedUpIds = new Set<Id>();
            List<GRAX_Data_Record_Id__c> dataRecIds2Up= new List<GRAX_Data_Record_Id__c>();
            List<SObject> recs2ClearRecycleBin = new List<SObject>();
            Map<Id, GRAX_Data_Record_Id__c> dataRecIdsMap = new Map<Id, GRAX_Data_Record_Id__c>();
            Integer currentRecIndex = 0;
            Integer totalNumberOfRecs = scope.size();
            
            // Get the Execution Unique Key from the first element
            String currentExecutionUniqueKey = ((GRAX_Data_Record_Id__c)scope[currentRecIndex]).GRAX_Data_Record__r.GRAX_Schedule_Process__r.Execution_Unique_Key__c;
                
            Set<Id> recIds = new Set<Id>();
            recIdsByExecUniqueKey.put(currentExecutionUniqueKey, recIds);
            
            while(currentRecIndex < totalNumberOfRecs){
            	Map<Id, SObject> recs2DelByDataRecId = new Map<Id, SObject>();
                Integer numberOfObjects = 0;
                String currentObjectName = '';
                Boolean breakOnExecutionUniqueKeyChanged = false;
                                
                for(Integer i = currentRecIndex; i <= totalNumberOfRecs && numberOfObjects <= 10 && !breakOnExecutionUniqueKeyChanged; i++){
                    if(i < totalNumberOfRecs){
                        GRAX_Data_Record_Id__c dataRecId = (GRAX_Data_Record_Id__c)scope[i];
                        dataRecIdsMap.put(dataRecId.Id, dataRecId);
                        
                        // Store the GRAX Archive Process Id in the List to check its status at the end of the batch execution
                        graxArchiveProcessIds.add(dataRecId.GRAX_Data_Record__r.GRAX_Archive_Process__c);
                        
                        // Set the current process flags to start over the 'while' iteration when there are 10 different object types in the list
                        if(currentObjectName <> dataRecId.GRAX_Data_Record__r.Salesforce_Object__c){
                            currentObjectName = dataRecId.GRAX_Data_Record__r.Salesforce_Object__c;
                            numberOfObjects++;
                        }
                        
                        // Add this Id to the list of recIds to verify is they exist in the Datalake
                        recIds.add(dataRecId.SFDC_Id__c);
                        
                        // Set the current process flags to start over the 'while' iteration when the Execution Unique Key changes, as we need to verify these records in the Datalake for the current key
                        if(currentExecutionUniqueKey <> dataRecId.GRAX_Data_Record__r.GRAX_Schedule_Process__r.Execution_Unique_Key__c){
                        	recIds.remove(dataRecId.SFDC_Id__c);
                        	
                        	recIds = new Set<Id>();
                        	currentExecutionUniqueKey = dataRecId.GRAX_Data_Record__r.GRAX_Schedule_Process__r.Execution_Unique_Key__c;
                        	recIdsByExecUniqueKey.put(currentExecutionUniqueKey, recIds);
                        	                            
                            breakOnExecutionUniqueKeyChanged = true;
                        }
                        
                        if(dataRecId.GRAX_Data_Record__r.GRAX_Schedule_Process__r.Status__c <> 'Deleting Salesforce records'){
		                	GRAX_Schedule_Process__c schedProcess = dataRecId.GRAX_Data_Record__r.GRAX_Schedule_Process__r;
		                	schedProcess.Status__c = 'Deleting Salesforce records';
		                	scheduleProcesses2UpById.put(schedProcess.Id, schedProcess);
		                }
                        
                        if(numberOfObjects <= 10 && !breakOnExecutionUniqueKeyChanged){
                            // Create a new instance of the SObject
                            SObject sObj2Del = GRAXUtils.createObjectInstance(dataRecId.GRAX_Data_Record__r.Salesforce_Object__c, dataRecId.SFDC_Id__c, false);
                            
                            // Add the current object to the list of possible Object Types during this iteration
                            if(!objectTypesByExecUniqueKey.containsKey(dataRecId.GRAX_Data_Record__r.GRAX_Schedule_Process__r.Execution_Unique_Key__c)){
                            	objectTypesByExecUniqueKey.put(dataRecId.GRAX_Data_Record__r.GRAX_Schedule_Process__r.Execution_Unique_Key__c, new Set<String>());
                            }
                            objectTypesByExecUniqueKey.get(dataRecId.GRAX_Data_Record__r.GRAX_Schedule_Process__r.Execution_Unique_Key__c).add(dataRecId.GRAX_Data_Record__r.Salesforce_Object__c);
                            
                            recs2DelByDataRecId.put(dataRecId.Id, sObj2Del);
                        }
                    }
                    
                    currentRecIndex = i;
                }
                
                System.debug(recs2DelByDataRecId.values());
                
                listOfRecs2DelByDataRecId.add(recs2DelByDataRecId);
            }
            
            // Verify that all these Records Ids were correctly backed up in GRAX's Datalake
            for(String executionUniqueKey : recIdsByExecUniqueKey.keySet()){
            	Set<Id> backedUpIds = new Set<Id>(getBackupedIds(recIdsByExecUniqueKey.get(executionUniqueKey), executionUniqueKey, objectTypesByExecUniqueKey.get(executionUniqueKey)));
                verifiedBackedUpIds.addAll(backedUpIds);
            }
            
            for(Map<Id, SObject> recs2DelByDataRecId : listOfRecs2DelByDataRecId){
            	Map<Id, SObject> verifiedRecs2DelByDataRecId = new Map<Id, SObject>();
            	
            	for(Id drId : recs2DelByDataRecId.keySet()) {
                    SObject rec = recs2DelByDataRecId.get(drId);

                    if(verifiedBackedUpIds.contains(rec.Id)) {
                        verifiedRecs2DelByDataRecId.put(drId, rec);
                    } else {
                        GRAX_Data_Record_Id__c dataRecId = dataRecIdsMap.get(drId);
                        
                        dataRecId.Status__c = 'Delete Error';
                        dataRecId.Error_Description__c = 'This record was not correctly backed up during this GRAX Schedule Process execution.';
                        
                        // Prevent any further attempt on this record
                        //dataRecId.of_Attempts_to_Delete__c = 5;
                        
                        // Add one to the number of attempts to delete this record
                    	dataRecId.of_Attempts_to_Delete__c = (dataRecId.of_Attempts_to_Delete__c == null ? 0 : dataRecId.of_Attempts_to_Delete__c) + 1;
                        
                        dataRecIds2Up.add(dataRecId);
                    }
                }
                
                // Set the monitor variable to prevent calling the trigger on these objects on the Delete DML
                GRAXBatchToDeleteBackedUpData.is_GRAXBatchToDeleteBackedUpData_Running = true;
                
                // Delete all the identified records
                List<Database.DeleteResult> deleteResults = Database.delete(verifiedRecs2DelByDataRecId.values(), false);
                
                // Set the monitor variable that prevents calling the trigger back to false
                GRAXBatchToDeleteBackedUpData.is_GRAXBatchToDeleteBackedUpData_Running = false;
                
                List<Id> dataRecIds = new List<Id>(verifiedRecs2DelByDataRecId.keySet());
                
                // Process the delete results and store the Status of each GRAX_Data_Record_Id__c record
                for(Integer i = 0; i < deleteResults.size(); i++){
                    Database.DeleteResult dr = deleteResults[i];
                    GRAX_Data_Record_Id__c dataRecId = dataRecIdsMap.get(dataRecIds[i]);
                    
                    // Add one to the number of attempts to delete this record
                    dataRecId.of_Attempts_to_Delete__c = (dataRecId.of_Attempts_to_Delete__c == null ? 0 : dataRecId.of_Attempts_to_Delete__c) + 1;
                    
                    dataRecId.Status__c = 'Successfully Deleted';
                    
                    if(!dr.isSuccess()){
                        dataRecId.Status__c = 'Delete Error';
                        dataRecId.Error_Description__c = '';
                        
                        for(Database.Error err : dr.getErrors()) {
                            dataRecId.Error_Description__c += err.getStatusCode() + ': ' + (err.getFields() <> null && err.getFields().size() > 0? '[' + String.join(err.getFields(), ',') + '] ' : '') + err.getMessage() + '.';
                            if(err.getStatusCode() == StatusCode.ENTITY_IS_DELETED || err.getStatusCode() == StatusCode.INVALID_CROSS_REFERENCE_KEY || err.getStatusCode() == StatusCode.INSUFFICIENT_ACCESS_OR_READONLY || (err.getStatusCode() == StatusCode.DELETE_FAILED && objects2PreventCallingEmptyRecycleBin.contains(dataRecId.GRAX_Data_Record__r.Salesforce_Object__c))){
                                dataRecId.Status__c = 'Deleted with Master Parent';
                            }
                        } 
                    }else{
                        // Add the elements to be removed from the Recycle Bin. Prevent adding certain objects that will make the transaction to fail, like CaseComment (https://success.salesforce.com/issues_view?id=a1p30000000Sve0AAC)
                    	if(!objects2PreventCallingEmptyRecycleBin.contains(dataRecId.GRAX_Data_Record__r.Salesforce_Object__c)){
                    		recs2ClearRecycleBin.add(recs2DelByDataRecId.get(dataRecId.Id));
                    	}
                    }
                    
                    // If the Delete operation on this record is considered Successfull, flag it as IsDeleted in GRAX Database
                    if(dataRecId.Status__c <> 'Delete Error'){
                    	String dataRecIdExecKey = dataRecId.GRAX_Data_Record__r.GRAX_Schedule_Process__r.Execution_Unique_Key__c;
						
                        if(!deletedRecordsByExecUniqueKey.containsKey(dataRecIdExecKey)) {
                            deletedRecordsByExecUniqueKey.put(dataRecIdExecKey, new Set<Id>());
                        }
                        deletedRecordsByExecUniqueKey.get(dataRecIdExecKey).add(dataRecId.SFDC_Id__c);
                        
                        // Add the current object to the list of possible Object Types during this iteration
                        if(!deletedObjectTypesByExecUniqueKey.containsKey(dataRecIdExecKey)){
                        	deletedObjectTypesByExecUniqueKey.put(dataRecIdExecKey, new Set<String>());
                        }
                        deletedObjectTypesByExecUniqueKey.get(dataRecIdExecKey).add(dataRecId.GRAX_Data_Record__r.Salesforce_Object__c);
                    }
                    
                    dataRecIds2Up.add(dataRecId);
                }
                
                if(recs2ClearRecycleBin.size() > 0){
	            	Database.emptyRecycleBin(recs2ClearRecycleBin);
	            }
            }
            
            if(scheduleProcesses2UpById.size() > 0){
        		update scheduleProcesses2UpById.values();
        	}
                    
            update dataRecIds2Up;
        }
    }
    
    global void finish(Database.BatchableContext BC){
        try{
	        sendDeletedRecordsIds();
	
	        Map<Id, GRAX_Schedule_Process__c> gsps2Up = new Map<Id, GRAX_Schedule_Process__c>();
	        List<GRAX_Archive_Process__c> gaps2Up = new List<GRAX_Archive_Process__c>();
	
	        //String currentJobExecutionUniqueKey;
	        Boolean executeCleanDataBatchProcess = false;
	
	        // Verify the Status of the GRAX Archive Process and call the batch again if it didn't complete
	    	for(GRAX_Archive_Process__c gap : [SELECT Id, Status__c, Execution_Unique_Key__c, Records_To_Process__c, Total_SFDC_Records_Failed_to_Delete__c, GRAX_Schedule_Process__c, GRAX_Schedule_Process__r.Execution_Unique_Key__c FROM GRAX_Archive_Process__c WHERE Id IN :graxArchiveProcessIds]) {
	            if(gap.Execution_Unique_Key__c == gap.GRAX_Schedule_Process__r.Execution_Unique_Key__c){
		            if(gap.Status__c == 'Delete Process Completed' || (gap.Status__c == 'Waiting Backup to Complete' && gap.Records_To_Process__c == 0)){
				        String executionUniqueKey = gap.GRAX_Schedule_Process__r.Execution_Unique_Key__c;
	
	                	if(!Test.isRunningTest()) GRAXBackupSummary.generateExecutionSummary(gap.GRAX_Schedule_Process__c, executionUniqueKey);
	            	
				        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c(Id = gap.GRAX_Schedule_Process__c);
		            	gsp.Status__c = 'Completed';
		            	gap.Can_Delete_GRAX_Record__c = true;
		            	if(gap.Total_SFDC_Records_Failed_to_Delete__c > 0){
		            		gsp.Status__c = 'Completed - Errors deleting records';
	            	    }
		            	gsps2Up.put(gsp.Id, gsp);
		            	gaps2Up.add(gap);                
		            	
	                    //if(isExecuteNow && currentJobId == gsp.Id) {
	                    //    currentJobExecutionUniqueKey = executionUniqueKey;
	                    //}
	                    
	                    // If there is any process that completed, fire a generic CleanUp process
	                    executeCleanDataBatchProcess = true;
	                }
	            }
	    	}
	
	        if(!Test.isRunningTest()) GRAXBackupSummary.sendSummaries();
	
	        //if(currentJobExecutionUniqueKey <> null) {
	        //    if(!Test.isRunningTest()) Database.executebatch(new GRAXBatchToCleanDataRecords(0, currentJobId, currentJobExecutionUniqueKey), 500);
	        //}
	        
	        if(executeCleanDataBatchProcess){
	        	GRAXSchedulerToCleanDataRecords.executeGRAXBatchToCleanDataRecords();
	        }
	    	
	    	if(gsps2Up.size() > 0){
	    		update gsps2Up.values();
	    	}
	    	
	    	if(gaps2Up.size() > 0){
	    		update gaps2Up;
	    	}
        }catch(Exception e){
			GRAXLogs.addLogException(e, 'APEX Class: GRAXBatchToDeleteBackedUpData, Method: finish, Current processes information: ' + JSON.serialize(this));
			
			// Commented out the following line as we don't want the message to be displayed in the Setup -> APEX Jobs
            //throw new GRAXException(e.getMessage(), 0);
		}
    }
}
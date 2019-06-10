/*****************************************************************************************
Name              : GRAXBatchToCleanDataRecords
Description       : Clean records that have been sent correctly and are more than 48 hours old.
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       04/17/2018             David Mackey        https://app.asana.com/0/326600806074978/633149554508924/f
2. Leandro Brunner       09/20/2018             David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
3. Ariel Yankelevich     09/24/2018             David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
4. Leandro Brunner       12/26/2018             David Mackey        Backup/Archive UI Updates (https://app.asana.com/0/326600806074978/950283827722121/f)
5. Ariel Yankelevich     01/03/2019             David Mackey        Chatter Backup (https://app.asana.com/0/326600806074978/958019584834204/f)
6. Ariel Yankelevich     01/31/2019             David Mackey        Update GRAXBatchtoDelete Process (https://app.asana.com/0/326600806074978/999564713541979/f)
7. Ariel Yankelevich     03/13/2019             David Mackey        Updates #2 (https://app.asana.com/0/326600806074978/1114051250995685/f)
8. Ariel Yankelevich     03/14/2019             David Mackey        Oak North Issues (https://app.asana.com/0/326600806074978/1114340491893894/f)
9. Ariel Yankelevich     05/24/2019             David Mackey        Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
10. Ariel Yankelevich    05/27/2019             David Mackey        Constellation Prod Backup Issues (https://app.asana.com/0/326600806074978/1124574665749273/f)
11. Ariel Yankelevich    06/03/2019          	David Mackey        Paylocity - Heap Size (https://app.asana.com/0/326600806074978/1125518618824327/f)
12. Ariel Yankelevich    06/05/2019          	David Mackey        Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
******************************************************************************************/
global class GRAXBatchToCleanDataRecords implements Database.Batchable<sObject>, Database.Stateful {
    private Map<String, String> queryByObject = new Map<String, String>{
        'GRAX_Data_Record__c' => 'SELECT Id FROM GRAX_Data_Record__c WHERE Can_Delete_GRAX_Record__c = TRUE',
        'GRAX_Data_Record_Id__c' => 'SELECT Id FROM GRAX_Data_Record_Id__c WHERE Can_Delete_GRAX_Record__c = TRUE',
        'GRAX_Archive_Process__c' => 'SELECT Id FROM GRAX_Archive_Process__c WHERE Can_Delete_GRAX_Record__c = TRUE AND Total_SFDC_Records_Failed_to_Delete__c = 0'
    };
    public static List<String> objects2Execute = new List<String>{'GRAX_Data_Record_Id__c','GRAX_Data_Record__c','GRAX_Archive_Process__c'};
    public static List<Integer> batchSizePerObjects2Execute = new List<Integer>{500, 25, 25};
    public String query = '';
    public Boolean useChunkingIdRanges;
    public Long idNumericDistance = 0;
    
    private Integer currentIndex = 0;
    private Id graxScheduleProcessId;
    private String executionUniqueKey;
    private Integer chunkIdRangeSize = 1500000;
    private Integer currentChunkIndex = 0;
    private List<Map<String, String>> currentChunkIdRangeMap;
    
    // These are static variables used in the Constructor method to get the value from the previous run
    public static Integer currentChunkIndexStatic;
    public static List<Map<String, String>> currentChunkIdRangeMapStatic;
    public static Boolean useChunkingIdRangesStatic = true;
    public static Integer chunkIdRangeSizeStatic;
    
    public GRAXBatchToCleanDataRecords(Integer currentIndex, Id graxScheduleProcessId, String executionUniqueKey) {
        this.currentIndex = currentIndex;
        this.query = queryByObject.get(objects2Execute[currentIndex]);
        this.graxScheduleProcessId = graxScheduleProcessId;
        this.executionUniqueKey = executionUniqueKey;
        
        // Get the variable values from the respective Static variable
        this.currentChunkIndex = currentChunkIndexStatic;
        this.currentChunkIdRangeMap = currentChunkIdRangeMapStatic;
        this.useChunkingIdRanges = useChunkingIdRangesStatic;
        this.chunkIdRangeSize = chunkIdRangeSizeStatic == null? chunkIdRangeSize : chunkIdRangeSizeStatic;
    }
    
    global Database.querylocator start(Database.BatchableContext BC) {
        if(graxScheduleProcessId <> null){          
            if(objects2Execute[currentIndex] == 'GRAX_Data_Record__c' || objects2Execute[currentIndex] == 'GRAX_Archive_Process__c'){
                this.query += ' AND (GRAX_Schedule_Process__c = null OR GRAX_Schedule_Process__c = : graxScheduleProcessId)';                       
            }else if(objects2Execute[currentIndex] == 'GRAX_Data_Record_Id__c'){
                this.query += ' AND (GRAX_Data_Record__r.GRAX_Schedule_Process__c = null OR GRAX_Data_Record__r.GRAX_Schedule_Process__c = : graxScheduleProcessId)';
            }                         
        }
        
        if(executionUniqueKey <> null && (objects2Execute[currentIndex] == 'GRAX_Data_Record__c' || objects2Execute[currentIndex] == 'GRAX_Data_Record_Id__c')){
            this.query += ' AND Execution_Unique_Key__c = : executionUniqueKey';
        }
        
        if(useChunkingIdRanges){
        	// Calculate the Id ranges for the current Object, if these were not before
        	if(currentChunkIdRangeMap == null || currentChunkIdRangeMap.isEmpty()){
        		currentChunkIndex = 0;
	        	String startId = getChunkingId(objects2Execute[currentIndex], true);
	        	String endId = getChunkingId(objects2Execute[currentIndex], false);
	        	
	        	if(!String.isEmpty(startId) && !String.isEmpty(endId)){
	        		idNumericDistance = GRAXUtils.numericDistance(startId, endId);
	        		currentChunkIdRangeMap = GRAXUtils.chunkIdRange(startId, endId, chunkIdRangeSize);
	        	}
        	}
        	
        	if(currentChunkIdRangeMap <> null && currentChunkIdRangeMap.size() > 0){
	        	// Establish the initial and final Ids for this chunk execution
	        	Map<String, String> chunkIdRange = currentChunkIdRangeMap[currentChunkIndex];
	        
	        	this.query += ' AND Id >= \'' + chunkIdRange.get('first') + '\' AND Id <= \'' + chunkIdRange.get('last') + '\'';
        	}
        }
        
        System.debug('The Clean up Query is: ' + this.query);

        return Database.getQueryLocator(this.query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
    	String errorMsg = '';
    	
        try{
        	List<SObject> recs2ClearRecycleBin = new List<SObject>();
        	
        	// Check the value of the field "LogAllErrors__c" in the GRAX Settings, and add the logs
            Boolean logAllErrors = false;
            GRAXSettings__c graxSet = GRAXUtils.getGRAXSettings();
            if(graxSet <> null && graxSet.LogAllErrors__c <> null){
                logAllErrors = graxSet.LogAllErrors__c;
            }
        	
            // Delete all the identified records
            List<Database.DeleteResult> deleteResults = Database.delete(scope, false);
            
            // Process the delete results and store the Status of each GRAX_Data_Record_Id__c record
            for(Integer i = 0; i < deleteResults.size(); i++){
                Database.DeleteResult dr = deleteResults[i];
                
                if(!dr.isSuccess()){
                    for(Database.Error err : dr.getErrors()) {
                        // Ignore the Exception "DELETE_OPERATION_TOO_LARGE" as it is produced when the child records are still not completely removed from the RecycleBin
			            // In this scenario, we are assuming that these records will be successfully removed the next time this batch fires
			            if(logAllErrors || err.getStatusCode() <> StatusCode.DELETE_OPERATION_TOO_LARGE){
                        	errorMsg += 'Record Id: ' + scope[i].Id + ', Error Details: ' + err.getStatusCode() + ': ' + (err.getFields() <> null && err.getFields().size() > 0? '[' + String.join(err.getFields(), ',') + '] ' : '') + err.getMessage() + '.\n';
			            }
                    } 
                }else{
                    // Add the elements to be removed from the Recycle Bin
                	recs2ClearRecycleBin.add(scope[i]);
                }
            }
            
            if(recs2ClearRecycleBin.size() > 0){
            	Database.emptyRecycleBin(recs2ClearRecycleBin);
            }
            
            if(!String.isEmpty(errorMsg)){
            	throw new GRAXException(errorMsg, 0);
            }
        }catch(Exception e){
            GRAXLogs.addLogException(e);
        }
    }

    global void finish(Database.BatchableContext BC) {
        // Save the current value of the currentIndex
        Integer currentObjectIndex = this.currentIndex;
        
        useChunkingIdRangesStatic = this.useChunkingIdRanges;
        
        // Verify if there are more chunk Id ranges to evaluate
        if(useChunkingIdRanges && currentChunkIdRangeMap <> null && currentChunkIdRangeMap.size() > 0 && currentChunkIndex < currentChunkIdRangeMap.size() - 1){
        	currentChunkIndex++;
        	
        	// Set the Static variable values to be used in the Constructor
            currentChunkIndexStatic = this.currentChunkIndex;
            currentChunkIdRangeMapStatic = this.currentChunkIdRangeMap;
        }else{
        	// Continue evaluating the following object
        	currentIndex++;
        	
        	// Set the Static variable values to be used in the Constructor
            currentChunkIndexStatic = 0;
            currentChunkIdRangeMapStatic = null;
        }
        
        if(currentIndex < objects2Execute.size() - 1) {
            GRAXBatchToCleanDataRecords b = new GRAXBatchToCleanDataRecords(currentIndex, graxScheduleProcessId, executionUniqueKey);
            Integer scopeSize = batchSizePerObjects2Execute[currentIndex];
            
            // Schedule the process to the next object
            if(this.currentIndex <> currentObjectIndex){
            	// Schedule the clean batch process for the next object, if it is GRAX_Data_Record__c, or test if there are any GRAX_Archive_Process__c records
            	if(this.currentIndex < 2 || Database.query(b.query + ' LIMIT 1').size() > 0){
		            String jobName = 'GRAXBatchToCleanDataRecords' + currentIndex + GRAXUtils.generate20UniqueKey();
		            Integer minutesFromNow = 30;
		
		            if(!Test.isRunningTest()) System.scheduleBatch(b, jobName, minutesFromNow, scopeSize);
            	}
            }else{
            	// Execute the same batch process for the next chunk Id range
            	Database.executeBatch(b, scopeSize);
            }
        }
    }
    
    public static Id getChunkingId(String objectName, Boolean isFirst) {
    	String result;
    	
    	List<SObject> sObjList = Database.query('SELECT Id FROM ' + objectName + ' ORDER BY Id ' + (isFirst? 'ASC' : 'DESC') + ' LIMIT 1');
		if(!sObjList.isEmpty()) {
			result = sObjList[0].Id;
		}
		
		return result;
    }
}
/*****************************************************************************************
Name              : GRAXSchedulerToCleanDataRecords
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner			04/17/2018			David Mackey		https://app.asana.com/0/326600806074978/633149554508924/f
2. Ariel Yankelevich		09/24/2018			David Mackey		Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
3. Nicolas Ralero			01/04/2019			David Mackey		Chatter Backup (https://app.asana.com/0/326600806074978/958019584834204/f)
4. Ariel Yankelevich        04/16/2019          David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
5. Ariel Yankelevich     	05/29/2019          David Mackey        Optichain Issues 5/7 (https://app.asana.com/0/326600806074978/1123545225466433/f)
6. Ariel Yankelevich     	06/03/2019          David Mackey        Paylocity - Heap Size (https://app.asana.com/0/326600806074978/1125518618824327/f)
******************************************************************************************/
global class GRAXSchedulerToCleanDataRecords implements Schedulable {
    global void execute(SchedulableContext sc) {
        GRAXSchedulerToCleanDataRecords.executeGRAXBatchToCleanDataRecords();
    }
    
    public static void executeGRAXBatchToCleanDataRecords(){
    	// Verify that this process is not currently running
    	String batchesRunningQuery = 'SELECT COUNT() FROM AsyncApexJob WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = \'GRAXBatchToCleanDataRecords\') AND Status IN (\'Queued\', \'Preparing\', \'Processing\', \'Holding\') LIMIT 1';
        
        if(Database.countQuery(batchesRunningQuery) == 0) {
            // Verify if this process has failed with the error "REQUEST_RUNNING_TOO_LONG" any of the last 5 executions
            String soqlQuery = 'SELECT Id FROM AsyncApexJob WHERE Status IN (\'Failed\') AND ExtendedStatus LIKE \'%[REQUEST_RUNNING_TOO_LONG]%\' AND ApexClass.Name = \'GRAXBatchToCleanDataRecords\' ORDER BY CompletedDate DESC LIMIT 5';
            
            if(Test.isRunningTest() || Database.query(soqlQuery).size() == 0) {
            	/*
            	////////////
            	// The following code is commented out because there are chances that the Chuncking Id tecnique might time out (REQUEST_RUNNING_TOO_LONG), when getting the first and last Ids
            	////////////
            	// Verify that there are any "GRAX Data Record Id", "GRAX Data Record", or "GRAX Archive Process" records to be deleted
            	for(Integer i = 0; i < 3; i++){
            		GRAXBatchToCleanDataRecords.useChunkingIdRangesStatic = true;
            		GRAXBatchToCleanDataRecords b = new GRAXBatchToCleanDataRecords(i, null, null);
			    	
			    	Boolean executeBatchForCurrentObject = b.idNumericDistance > 0;
			    	
			    	// Verify that there are less than 200,000 records before "testing" the LIMIT 1 query
			    	if(executeBatchForCurrentObject && b.idNumericDistance < 200000){
			    		b.useChunkingIdRanges = false;
			    		
	            		// Query at least one record to confirm that there is data to be deleted on this GRAX object
	            		executeBatchForCurrentObject = Database.query(b.query + ' LIMIT 1').size() > 0;
	            	}
			    	
			    	if(executeBatchForCurrentObject){
			    		if(!Test.isRunningTest()) Database.executeBatch(b, 500);
            			break;
			    	}
            	}
            	*/
            	
            	GRAXBatchToCleanDataRecords.useChunkingIdRangesStatic = false;
        		GRAXBatchToCleanDataRecords b = new GRAXBatchToCleanDataRecords(0, null, null);
        		if(!Test.isRunningTest()) Database.executeBatch(b, GRAXBatchToCleanDataRecords.batchSizePerObjects2Execute[0]);
            }else{
            	// Call the batch to clean up GRAX records using the Chunking Id strategy
            	GRAXBatchToCleanDataRecords.useChunkingIdRangesStatic = true;
            	if(!Test.isRunningTest()) Database.executeBatch(new GRAXBatchToCleanDataRecords(0, null, null), GRAXBatchToCleanDataRecords.batchSizePerObjects2Execute[0]);
            }
        }
    }
}
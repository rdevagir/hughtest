/*****************************************************************************************
Name              : GRAXBatchToResendDataRecords
Description       : Try again to do up to 5 times the Callout of the records that were not sent correctly.
Revision History  :
Created/Modified by		Created/Modified Date		Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner			04/17/2018				David Mackey		https://app.asana.com/0/326600806074978/633149554508924/f
2. Leandro Brunner			11/06/2018				David Mackey		Minor UI Enhancements (https://app.asana.com/0/326600806074978/880565726418326/f)
3. Leandro Brunner			12/27/2018				David Mackey		Backup/Archive UI Updates (https://app.asana.com/0/326600806074978/950283827722121/f)
4. Nicolas Ralero			01/04/2019				David Mackey		Chatter Backup (https://app.asana.com/0/326600806074978/958019584834204/f)
5. Leandro Brunner          02/27/2019              David Mackey        Bug in Backup Batch (https://app.asana.com/0/326600806074978/1111746752627419/f)
6. Ariel Yankelevich      	03/14/2019          	David Mackey        Oak North Issues (https://app.asana.com/0/326600806074978/1114340491893894/f)
7. Ariel Yankelevich      	03/21/2019          	David Mackey        Oak North Updates #2 (https://app.asana.com/0/326600806074978/1114502823954369/f)
8. Ariel Yankelevich      	04/09/2019          	David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
9. Nicolas Ralero			04/11/2019				David Mackey		GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
10. Ariel Yankelevich		05/03/2019				David Mackey		GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
11. Ariel Yankelevich		05/06/2019				David Mackey		503 Errors (https://app.asana.com/0/326600806074978/1121362448820852/f)
12. Ariel Yankelevich		05/13/2019				David Mackey		Optichains Prod Backup Issues (https://app.asana.com/0/326600806074978/1122687086503529/f)
******************************************************************************************/
global class GRAXBatchToResendDataRecords implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
	public String query = '';
    public Boolean isExecuteNow = false;
    public Boolean isArchive = false;
    public Id currentJobId;
	public Map<Id, Set<String>> graxDataRecordIds2DelayStatusUpdateByScheduleProcessId;
	public Integer numberOfConsecutive503Responses;

	private Set<Id> graxScheduleProcessIds = new Set<Id>();
	
	public GRAXBatchToResendDataRecords(){
		graxDataRecordIds2DelayStatusUpdateByScheduleProcessId = new Map<Id, Set<String>>();
		numberOfConsecutive503Responses = 0;

		query = 'SELECT Id, Salesforce_Object__c, of_Times_Sent__c, GRAX_Schedule_Process__c, Status__c, GRAX_Schedule_Process__r.Status__c, GRAX_Schedule_Process__r.Type__c FROM GRAX_Data_Record__c WHERE Status__c NOT IN (\'Processing\', \'Sent Successful\') AND of_Times_Sent__c < 5 AND GRAX_Schedule_Process__r.Status__c IN (\'Running\', \'Sending data to GRAX\',\'Pending send data to GRAX\') AND GRAX_Schedule_Process__r.Status__c <> \'Aborted\'';

		if(isExecuteNow && currentJobId <> null) {
            query += ' AND GRAX_Schedule_Process__c = :currentJobId';
        
            graxScheduleProcessIds.add(currentJobId);
        }
        
        if(this.currentJobId <> null){
	        for(GRAX_Schedule_Process__c gsp : [SELECT Id, Status__c, Type__c FROM GRAX_Schedule_Process__c WHERE Id = :currentJobId LIMIT 1]) {
	            if(gsp.Status__c == 'Pending send data to GRAX'){
		            gsp.Status__c = 'Sending data to GRAX';
		            update gsp;
	            }
	        }
		}
	}

    global Database.querylocator start(Database.BatchableContext BC) {
        Set<String> processedGRAXDataRecIds = new Set<String>();
		
		if(!isExecuteNow){
			GRAXBatchToResendDataRecords.getDelayedGRAXDataRecIds(processedGRAXDataRecIds);
		}
		
		if(processedGRAXDataRecIds.size() > 0){
        	// If there are Delayed Ids for GRAX Data Records, skip them from the current execution
        	query += ' AND Id NOT IN :processedGRAXDataRecIds';
        }
        
        query += ' ORDER BY GRAX_Schedule_Process__c';

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<GRAX_Data_Record__c> scope) {
        if(this.isExecuteNow && this.currentJobId <> null && GRAXUtils.checkIfScheduleIsAborted(this.currentJobId)) {
            System.abortJob(BC.getJobId());
        } else {
            List<GRAX_Data_Record__c> dataRecords2Up = new List<GRAX_Data_Record__c>();
            Map<Id, GRAX_Schedule_Process__c> scheduleProcesses2UpById = new Map<Id, GRAX_Schedule_Process__c>();
            List<Id> graxScheduleProcessIds2GetAttachment = new List<Id>();
			
			for(GRAX_Data_Record__c dr : scope) {
				graxScheduleProcessIds.add(dr.GRAX_Schedule_Process__c);

				if(dr.GRAX_Schedule_Process__r.Type__c == 'Hierarchy' && !graxDataRecordIds2DelayStatusUpdateByScheduleProcessId.containsKey(dr.GRAX_Schedule_Process__c)){
					graxDataRecordIds2DelayStatusUpdateByScheduleProcessId.put(dr.GRAX_Schedule_Process__c, new Set<String>());
					graxScheduleProcessIds2GetAttachment.add(dr.GRAX_Schedule_Process__c);					
				}
			}

			for(Id scheduleProcessId : graxScheduleProcessIds2GetAttachment){
				// Get the existing "DelayedGraxDataRecordIdsToUpdateStatus" Attachment record, from the current GRAX Schedule Process record
				Attachment att = GRAXUtils.getSelectionAttachment(scheduleProcessId, 'DelayedGraxDataRecordIdsToUpdateStatus.txt');

				// If the Attachment record exists, then we append the set of GRAX Data Record Ids, into the map, for the current Schedule Process record
				if(att <> null){
					graxDataRecordIds2DelayStatusUpdateByScheduleProcessId.get(scheduleProcessId).addAll((Set<String>)JSON.deserialize(GRAXUtils.getSelectionJSON(att, ''), Set<String>.class));
				}
			}

            for(GRAX_Data_Record__c dr : scope) {
				// Process the "GRAX Data Record", only if the Status is NOT "Sent Successful", when running a Multi-Object process, or when running a Hierarchy process, and the record has not being delayed its Status update, in a previous execution of the batch
                if(dr.Status__c <> 'Sent Successful' && (dr.GRAX_Schedule_Process__r.Type__c == 'Multi-Object' || !graxDataRecordIds2DelayStatusUpdateByScheduleProcessId.get(dr.GRAX_Schedule_Process__c).contains(dr.Id))){	                
	                String content;
	
	                // Gets the body of the request from the "Attachment" of the Data Record.
	                for(Attachment att : [SELECT Name, Body FROM Attachment WHERE ParentId = :dr.Id LIMIT 1]) {
	                    if(att.Name.endsWithIgnoreCase('.txt')){
	                        content = att.Body.toString();
	                    }else{
	                        content = EncodingUtil.base64Encode(att.Body);
	                    }
	                    break;
	                }
	
	                if(content <> null) {
	                    GRAXCloud.sendDataRecordToGRAX('', content, dr);

	                    if(dr.Status__c == 'Error' && dr.Error_Message__c.contains('503')){
	                    	numberOfConsecutive503Responses++;
	                    }else{
	                    	numberOfConsecutive503Responses = 0;
	                    }

						// If a Hierarchy process is currently running, and the GRAX Data Record was succesfully sent, then we delay the Status update action.
						// But if there was an error when trying to send the current record, in a Hierarchy process, then we do nothing at this point. The record will be processed in a future execution.
						if(dr.GRAX_Schedule_Process__r.Status__c == 'Running' && dr.GRAX_Schedule_Process__r.Type__c == 'Hierarchy'){
							if(dr.Status__c == 'Sent Successful'){								
								graxDataRecordIds2DelayStatusUpdateByScheduleProcessId.get(dr.GRAX_Schedule_Process__c).add(dr.Id);
							}
						}else{
							dataRecords2Up.add(dr);
						}
	                }

					if(dr.GRAX_Schedule_Process__r.Status__c == 'Pending send data to GRAX'){
	                	GRAX_Schedule_Process__c schedProcess = dr.GRAX_Schedule_Process__r;
	                	schedProcess.Status__c = 'Sending data to GRAX';
	                	scheduleProcesses2UpById.put(schedProcess.Id, schedProcess);
	                }
                }

				// Once a Hierarchy GRAX Schedule Process, has finished, and the current GRAX Data Record has been delayed to update its Status, we set the "Sent Successful" Status value, accordingly
				if((dr.GRAX_Schedule_Process__r.Status__c == 'Sending data to GRAX' || dr.GRAX_Schedule_Process__r.Status__c == 'Pending send data to GRAX') && dr.GRAX_Schedule_Process__r.Type__c == 'Hierarchy' && graxDataRecordIds2DelayStatusUpdateByScheduleProcessId.get(dr.GRAX_Schedule_Process__c).contains(dr.Id)){
					dr.Status__c = 'Sent Successful';
					
					// Set the following fields to the current time, even that this record was sent in a previous iteration 
					dr.Error_Message__c = '';
					dr.Last_Sent_Date__c = System.now();
					dr.of_Times_Sent__c = 1;
					dataRecords2Up.add(dr);
				}
            }
            
            try{
            	if(scheduleProcesses2UpById.size() > 0){
            		update scheduleProcesses2UpById.values();
            	}

				if(dataRecords2Up.size() > 0){
            		update dataRecords2Up;
                }
                
                // Store the GRAX Data Record Ids that we identified to delay its Status update, into the corresponding Attachment file, in the parent GRAX Schedule Process record
				if(!graxDataRecordIds2DelayStatusUpdateByScheduleProcessId.isEmpty()){
					for(Id scheduleProcessId : graxDataRecordIds2DelayStatusUpdateByScheduleProcessId.keySet()){
						// Get the existing "DelayedGraxDataRecordIdsToUpdateStatus" Attachment record, from the current GRAX Schedule Process record
						Attachment att = GRAXUtils.getSelectionAttachment(scheduleProcessId, 'DelayedGraxDataRecordIdsToUpdateStatus.txt');
				
						if(att <> null){
							// Convert the set of GRAX Data Record Ids, into a JSON String, and save the changes in the Attachment record
							GRAXUtils.setSelectionJSON(att, JSON.serialize(graxDataRecordIds2DelayStatusUpdateByScheduleProcessId.get(scheduleProcessId)));
				    	}else{
							// If the Attachment record doesn't exist, then we create a new file, and save the set of GRAX Data Record Ids, that we delayed its Status update
							GRAXUtils.setSelectionJSON(scheduleProcessId, JSON.serialize(graxDataRecordIds2DelayStatusUpdateByScheduleProcessId.get(scheduleProcessId)), 'DelayedGraxDataRecordIdsToUpdateStatus.txt');
				    	}
					}
				}			
				
				// If the number of consecutive 503 errors is greater than 5, abort this Job and Schedule it to execute again in 2 minutes
	            if(numberOfConsecutive503Responses >= 5){
	            	// Abort the current batch Job
	            	System.abortJob(BC.getJobId());
	            	
	            	// Call the finish method in case any of the current GRAX Schedule Processes had completed
	            	System.enqueueJob(new AsyncExecToFinishResendProcess(this.graxScheduleProcessIds));
	            	
	            	// Schedule the Apex Schedule Job GRAXSchedulerToResendDataRecords to run again in 2 minutes
	            	Datetime dt = Datetime.now().addMinutes(2);
	            	String sch = '0 ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ' + ' ? ' + dt.year();
	 				System.schedule('GRAXBatchToResendDataRecords_Pause503_' + GRAXUtils.generateRandomString(10), sch, new GRAXSchedulerToResendDataRecords());
	            }
            }catch(System.DmlException ex){				    
			    for(Integer i = 0; i < ex.getNumDml(); i++){
			        if(ex.getDmlType(i) <> StatusCode.UNABLE_TO_LOCK_ROW && !ex.getDmlMessage(i).contains('UNABLE_TO_LOCK_ROW')){
                    	GRAXLogs.addLogException(ex);
                    }
		        }
			}catch(Exception e){
            	GRAXLogs.addLogException(e);
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        GRAXBatchToResendDataRecords.finishMethod(this.graxScheduleProcessIds);
    }
    
    public static void finishMethod(Set<Id> graxScheduleProcessIds){
    	List<GRAX_Schedule_Process__c> scheduleProcesses2Up = new List<GRAX_Schedule_Process__c>();
		List<Attachment> delayedGraxDataRecordIdsAttachments2Delete = new List<Attachment>();
		Boolean executeCleanDataBatchProcess = false;
		Boolean executeDeleteBatchProcess = false;
		
		// Iterate through the list of all the evaluated GRAX Schedule Processes and identify if the "Send Data to GRAX" process has completed
        for(GRAX_Schedule_Process__c gsp : [SELECT Id, Status__c, Total_Records_To_Send__c, Total_Records_Sent__c, Total_Records_Errors__c, Execution_Unique_Key__c, Archive__c, (SELECT Id FROM Attachments WHERE Name = 'DelayedGraxDataRecordIdsToUpdateStatus.txt') FROM GRAX_Schedule_Process__c WHERE Id IN :graxScheduleProcessIds]) {
            if(gsp.Status__c == 'Sending data to GRAX' || gsp.Status__c == 'Pending send data to GRAX'){
	            if(gsp.Total_Records_To_Send__c == gsp.Total_Records_Sent__c || gsp.Total_Records_To_Send__c == 0 || gsp.Total_Records_Errors__c > 0){
	                gsp.Status__c = gsp.Archive__c ? 'Starting Archive Process' : 'Completed';
	
	                if(gsp.Total_Records_Errors__c > 0) {
	                    gsp.Status__c = 'Completed - Errors sending data';
	                }
	
					if(!gsp.Archive__c) {
	                    if(!Test.isRunningTest()) GRAXBackupSummary.generateExecutionSummary(gsp.Id, gsp.Execution_Unique_Key__c);
	                    
	                    // If there is any "Backup" process that completed, fire a generic CleanUp process
	                    executeCleanDataBatchProcess = true;
	                }
	                
	                if(gsp.Archive__c && gsp.Status__c == 'Starting Archive Process'){
	                	// If there is any "Archive" process that finished sending Data to GRAX, fire a generic DeleteBackedUpData process
	                	executeDeleteBatchProcess = true;
	                }
	
	                scheduleProcesses2Up.add(gsp);
	                
	                // If the GRAX Schedule Process, has finished, and there are related "DelayedGraxDataRecordIdsToUpdateStatus" Attachment records, we delete them
					if(gsp.Attachments.size() > 0){
						delayedGraxDataRecordIdsAttachments2Delete.addAll(gsp.Attachments);
					}				
	            }				
            }
		}
        
        if(!Test.isRunningTest()) GRAXBackupSummary.sendSummaries();
        
        if(scheduleProcesses2Up.size() > 0){
    		update scheduleProcesses2Up;
    	}

		if(!delayedGraxDataRecordIdsAttachments2Delete.isEmpty()){
			delete delayedGraxDataRecordIdsAttachments2Delete;
		}

		if(executeDeleteBatchProcess){
        	GRAXSchedulerToDeleteBackedUpData.executeGRAXBatchToDeleteBackedUpData();
        }
		
		if(executeCleanDataBatchProcess){
        	GRAXSchedulerToCleanDataRecords.executeGRAXBatchToCleanDataRecords();
        }
        
        // Verify if there are more GRAX Data Records to be sent and try to execute the process right away, instead of waiting till the next half hour for the Scheduler to fire
        Set<String> processedGRAXDataRecIds = new Set<String>();
        
        GRAXBatchToResendDataRecords b = new GRAXBatchToResendDataRecords();
        
        // Get the delayed GRAX Data Records
        GRAXBatchToResendDataRecords.getDelayedGRAXDataRecIds(processedGRAXDataRecIds);
		
		if(processedGRAXDataRecIds.size() > 0){
        	// If there are Delayed Ids for GRAX Data Records, skip them from the current execution
        	b.query += ' AND Id NOT IN :processedGRAXDataRecIds';
        }
        
        b.query += ' LIMIT 1';
        
        if(Database.query(b.query).size() > 0){
        	// If the are more GRAX Data Records ready to be sent, Schedule the Apex Schedule Job GRAXSchedulerToResendDataRecords to run again in 3 minutes
        	Datetime dt = Datetime.now().addMinutes(3);
        	
        	// Do not overlap this process with the regular APEX Schedule Job set to run every hour (XX:00) and half hour (XX:30)
        	if(dt.minute() <> 0 && dt.minute() <> 30){
	        	String sch = '0 ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ' + ' ? ' + dt.year();
	 			System.schedule('GRAXBatchToResendDataRecords_Resume_' + GRAXUtils.generateRandomString(10), sch, new GRAXSchedulerToResendDataRecords());
        	}
        }
    }
    
    private static void getDelayedGRAXDataRecIds(Set<String> processedGRAXDataRecIds){
    	// Get every "Running" GRAX Schedule Process "Hierarchy" record (still preforming the backup), in order to skip the GRAX Data Records that were "Delayed" processed
		for(GRAX_Schedule_Process__c schedProc : [SELECT Id, (SELECT Id, BodyLength FROM Attachments WHERE Name = 'DelayedGraxDataRecordIdsToUpdateStatus.txt' Limit 1) FROM GRAX_Schedule_Process__c WHERE Type__c = 'Hierarchy' AND Status__c = 'Running' ORDER BY LastModifiedDate DESC LIMIT 100]){
			if(schedProc.Attachments.size() > 0 && Limits.getHeapSize() + schedProc.Attachments[0].BodyLength < Limits.getLimitHeapSize() * 0.7){
				// Get the existing "DelayedGraxDataRecordIdsToUpdateStatus" Attachment record, from the current GRAX Schedule Process record
				Attachment att = GRAXUtils.getSelectionAttachment(schedProc.Id, 'DelayedGraxDataRecordIdsToUpdateStatus.txt');

				// If the Attachment record exists, then we append the set of GRAX Data Record Ids, into the map, for the current Schedule Process record
				if(att <> null){
					processedGRAXDataRecIds.addAll((Set<String>)JSON.deserialize(GRAXUtils.getSelectionJSON(att, ''), Set<String>.class));
				}
			}
		}
    }
    
    public class AsyncExecToFinishResendProcess implements Queueable, Database.AllowsCallouts {
        private Set<Id> graxScheduleProcessIds = new Set<Id>();

        public AsyncExecToFinishResendProcess(Set<Id> graxScheduleProcessIds) {
            this.graxScheduleProcessIds = graxScheduleProcessIds;
        }

        public void execute(QueueableContext context) {
            GRAXBatchToResendDataRecords.finishMethod(this.graxScheduleProcessIds);
        }
    }
}
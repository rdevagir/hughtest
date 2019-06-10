/*****************************************************************************************
Name              : GRAXSchedulerToProcessSchedJobs
Description       : This Schedule process finds the Schedule Process jobs that are supposed to run at this moment or did not execute in the previous Schedule execution
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Ariel Yankelevich       05/08/2018           David Mackey        GRAX Audit Trail Process (https://app.asana.com/0/326600806074978/633149554508926/f)
2. Ariel Yankelevich       07/18/2018           David Mackey        Multi-Object Backup (https://app.asana.com/0/326600806074978/743044564916005/f)
3. Leandro Brunner         08/07/2018           David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
4. Leandro Brunner         08/22/2018           David Mackey        Initial Backup updates (https://app.asana.com/0/326600806074978/788118599521250/f)
5. Ariel Yankelevich       10/11/2018           David Mackey        Minor Updates (https://app.asana.com/0/326600806074978/857103514581849/f)
6. Leandro Brunner         12/26/2018           David Mackey        Backup/Archive UI Updates (https://app.asana.com/0/326600806074978/950283827722121/f)
7. Leandro Brunner         02/26/2019           David Mackey        Update Backup Process (https://app.asana.com/0/326600806074978/1109887667389108/f)
8. Ariel Yankelevich       03/22/2019           David Mackey        Oak North Updates #2 (https://app.asana.com/0/326600806074978/1114502823954369/f)
9. Ariel Yankelevich       04/03/2019           David Mackey        Latest Package Bugs (https://app.asana.com/0/326600806074978/1117046362603242/f)
10. Ariel Yankelevich      04/17/2019           David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
11. Sergio Caputo		   04/17/2019           David Mackey        GRAXSchedulerToProcessSchedJobs Error (https://app.asana.com/0/326600806074978/1118862586802334/f)
12. Ariel Yankelevich	   04/22/2019           David Mackey        Internal Salesforce Error: moving job from FlexQueue to MQ failed (https://app.asana.com/0/326600806074978/1118660079719637/f)
13. Ariel Yankelevich	   05/13/2019           David Mackey        Optichains Prod Backup Issues (https://app.asana.com/0/326600806074978/1122687086503529/f)
******************************************************************************************/
global class GRAXSchedulerToProcessSchedJobs implements Schedulable {
    public static void enqueueSchedule(GRAX_Schedule_Process__c schedProcess, Boolean isExecuteNow) {
        try {
            if(Limits.getQueueableJobs() <> Limits.getLimitQueueableJobs()) {
            	// First update the Status of the Schedule Job to "Running" in order to fire the triggers before executing the job
                schedProcess.Status__c = 'Running';
                update schedProcess;
            	
                System.enqueueJob(new AsyncExecToProcessSchedJobs(schedProcess, isExecuteNow));
            }
        } catch(Exception e) {
            System.debug(e);
        }
    }
    
    global void execute(SchedulableContext sc) {
        Map<String, GRAX_Schedule_Process__c> schedulesToCheckByJobId = new Map<String, GRAX_Schedule_Process__c>();

        // Find any Schedule Process Job that is supposed to run at the current GMT time, 
        // or that it hasn't been executed on the previous Schedule run and it's not currently executing
        for(GRAX_Schedule_Process__c schedProcess : [SELECT Id, Status__c, Is_Running__c, JobId__c FROM GRAX_Schedule_Process__c WHERE ((Next_Run_Date__c <= :System.now() AND Is_Running__c = false) OR (Status__c = 'Running' AND JobId__c <> null))]){
            if(!schedProcess.Is_Running__c) {
                enqueueSchedule(schedProcess, true);
            } else if(schedProcess.Status__c == 'Running' && !String.isBlank(schedProcess.JobId__c)){
                schedulesToCheckByJobId.put(schedProcess.JobId__c.substring(0, 15), schedProcess);
                
                if(GRAXSchedulerToProcessSchedJobs.isEmptyId(schedProcess.JobId__c)){
                	// Last attempt to execute the batch failed because of the APEX Flex Queue being full
                	schedulesToCheckByJobId.remove(schedProcess.JobId__c);
                	enqueueSchedule(schedProcess, false);
                }
            }
        }
		
		if(schedulesToCheckByJobId.size() > 0){
	        for(AsyncApexJob aaj : [SELECT Id, Status FROM AsyncApexJob WHERE Id IN :schedulesToCheckByJobId.keySet() AND Status = 'Failed']) {
	            enqueueSchedule(schedulesToCheckByJobId.get(String.valueOf(aaj.Id).substring(0, 15)), false);
	        }
		}
    }

    public class AsyncExecToProcessSchedJobs implements Queueable, Database.AllowsCallouts {
        private GRAX_Schedule_Process__c schedProcess;
        private Boolean isExecuteNow;

        public AsyncExecToProcessSchedJobs() {}
        public AsyncExecToProcessSchedJobs(GRAX_Schedule_Process__c schedProcess, Boolean isExecuteNow) {
            this.schedProcess = schedProcess;
            this.isExecuteNow = isExecuteNow;
        }

        public void execute(QueueableContext context) {
            try {
                String jobId;
                
                this.schedProcess = [SELECT Id, Status__c, Target_Report__c, Object_Name__c, Type__c, CurrentElementIndex__c, JobId__c, (SELECT Id FROM Attachments WHERE Name = 'SelectionJSON.txt' LIMIT 1) FROM GRAX_Schedule_Process__c WHERE Id =: this.schedProcess.Id];
                
                if(this.schedProcess.Attachments == null || this.schedProcess.Attachments.size() == 0){
                    throw new GRAXException('The GRAX Scheduled Process has not been created correctly. Please ensure that the Scheduled Process was created through the \'Create\' button on the \'Schedule\' tab. GRAX Schedule Process Id: \'' + schedProcess.Id + '\'', 0);
                }
                
                Integer currentIndex = 0;
                if(this.schedProcess.CurrentElementIndex__c <> null && this.schedProcess.JobId__c <> null && !this.isExecuteNow) {
                    // We need to continue the process from the object index that is failed the batch execution
                    currentIndex = schedProcess.currentElementIndex__c.intValue();
                }
                
                // Only fire the Hierarchy Schedule Process based on a Report, if the currentIndex == 0
                if(schedProcess.Target_Report__c <> null && currentIndex == 0) {
                    GRAXBatchToProcessSchedJobFromReport b = new GRAXBatchToProcessSchedJobFromReport(schedProcess.Id, null, null, isExecuteNow);
                    schedProcess.Total_Objects_To_Process__c = b.mainBatchProcess.objects2Process.size();
                    if(!Test.isRunningTest()) jobId = String.valueOf(Database.executebatch(b, GRAXUtils.getBatchMaxExecutionNumber(schedProcess.Object_Name__c)));
                }else{
                    // 'Multi-Object' or Date criteria backups
                    GRAXBatchToProcessSchedJobMainObject b = new GRAXBatchToProcessSchedJobMainObject(schedProcess.Id, isExecuteNow, schedProcess.Type__c == 'Multi-Object', currentIndex);
                    schedProcess.Total_Objects_To_Process__c = b.mainBatchProcess.objects2Process.size();
                    if(!Test.isRunningTest()) jobId = String.valueOf(Database.executebatch(b, GRAXUtils.getBatchMaxExecutionNumber(schedProcess.Object_Name__c)));
                }

                // Check that the Batch Job made it to the APEX Flex Queue
                if(!String.isEmpty(jobId) && !GRAXSchedulerToProcessSchedJobs.isEmptyId(jobId)) {
                	schedProcess.JobId__c = jobId;
                	schedProcess.Total_Objects_Processed__c = currentIndex;
                	update schedProcess;
                }else{
                	// Set the Status to "Error" in case the batch job cannot get into the Queue
                	throw new GRAXException('This SF environment has reached its maximum number of concurrent records in the APEX Flex Queue. Please try scheduling again. GRAX Schedule Process Id: \'' + schedProcess.Id + '\'', 0);
                }
            } catch(Exception e) {
                GRAXLogs.addLogException(e);
                           
                schedProcess.Status__c = 'Error';
                update schedProcess;
            }
        }
    }
    
    public static Boolean isEmptyId(String jobId){
    	return !String.isEmpty(jobId) && (jobId == '000000000000000' || jobId == '000000000000000AAA');
    }
}
/*****************************************************************************************
Name              : GRAXBatchToGetSchedJobParentRecords
Description       : This batch process gets the list of every SFDC Parent Id that was already processed in a previous iteration of the main batch in a Hierarchy GRAX Schedule Process context
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Nicolas Ralero	     04/18/2018           	David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
2. Ariel Yankelevich     04/26/2019           	David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
3. Ariel Yankelevich	 04/22/2019           	David Mackey        Internal Salesforce Error: moving job from FlexQueue to MQ failed (https://app.asana.com/0/326600806074978/1118660079719637/f)
4. Ariel Yankelevich	 05/13/2019				David Mackey		Optichains Prod Backup Issues (https://app.asana.com/0/326600806074978/1122687086503529/f)
******************************************************************************************/

public class GRAXBatchToGetSchedJobParentRecords implements Database.Batchable<sObject>, Database.Stateful {
	public String query = '';
	public List<Id> parentIds2ProcessForChild;
	public GRAXBatchToProcessSchedJob mainBatchProcess;
    
    
    public GRAXBatchToGetSchedJobParentRecords(GRAXBatchToProcessSchedJob mainBatchProcess){
        this.mainBatchProcess = mainBatchProcess;
        this.parentIds2ProcessForChild = new List<Id>();
        
        // Get the current child object structure
		GRAXBackupCtrl.ObjRelStructure sObjRelStruc = this.mainBatchProcess.objects2Process[this.mainBatchProcess.currentElementIndex];

		// Get the parent record Ids that still haven't been processed
		query = 'SELECT Id, SFDC_Id__c FROM GRAX_Data_Record_Id__c WHERE';
		query += ' ((Processed_Child_Index__c < ' + this.mainBatchProcess.currentElementIndex + ' AND Execution_Unique_Key__c = \'' + this.mainBatchProcess.executionUniqueKey + '\')';
		query += ' OR (GRAX_Data_Record__r.GRAX_Schedule_Process__r.Progressive__c = true AND Execution_Unique_Key__c <> \'' + this.mainBatchProcess.executionUniqueKey + '\'))';
		query += ' AND GRAX_Data_Record__r.GRAX_Schedule_Process__c = \'' + this.mainBatchProcess.currentJobId + '\'';
		query += ' AND GRAX_Data_Record__r.Sched_Proc_Hierarchy_Unique_Key__c = \'' + sObjRelStruc.parentUniqueKey + '\'';
		query += ' LIMIT ' + GRAXUtils.getMaxNumberOfParentsOnHierarchyBackup(sObjRelStruc.name);
		
		System.debug('The SOQL query is: ' + query);
    }
	
	public Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

	public void execute(Database.BatchableContext BC, List<GRAX_Data_Record_Id__c> scope){
		List<GRAX_Data_Record_Id__c> graxDataRecs2Up = new List<GRAX_Data_Record_Id__c>();
	            
        for(GRAX_Data_Record_Id__c grxDRId : scope){
            this.parentIds2ProcessForChild.add(grxDRId.SFDC_Id__c);
            
            // Flag all the parent Ids that are going to be processed during this execution
            grxDRId.Processed_Child_Index__c = this.mainBatchProcess.currentElementIndex;
            grxDRId.Execution_Unique_Key__c = this.mainBatchProcess.executionUniqueKey;
            graxDataRecs2Up.add(grxDRId);
        }
        
        if(graxDataRecs2Up.size() > 0){
            update graxDataRecs2Up;
        }
	}

	public void finish(Database.BatchableContext BC){
		// Continue the batch execution for the current object being process using all its parents
		this.mainBatchProcess.parentIds2ProcessForChild = this.parentIds2ProcessForChild;
		String nextJobId = this.mainBatchProcess.executeNextBatchRun(this.mainBatchProcess);
		
		if(GRAXSchedulerToProcessSchedJobs.isEmptyId(nextJobId)) {
			try{
				// Add a GRAX Log in case the batch job cannot get into the Queue
				throw new GRAXException('This SF environment has reached its maximum number of concurrent records in the APEX Flex Queue. Please try scheduling again. GRAX Schedule Process Id: \'' + this.mainBatchProcess.currentJobId + '\'', 0);
			}catch(Exception e){
				GRAXLogs.addLogException(e, 'APEX Class: GRAXBatchToGetSchedJobParentRecords, Method: finish.');
			}
		}
	}
}
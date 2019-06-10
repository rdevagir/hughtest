/*******************************************************************************
Name              : GRAXScheduleProcessTriggerHandler
Description       : 
Revision History  : - 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
----------------------------------------------------------------------------------------
1. Leandro Brunner    	08/07/2018                David Mackey          Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
2. Leandro Brunner    	12/27/2018                David Mackey          Backup/Archive UI Updates (https://app.asana.com/0/326600806074978/950283827722121/f)
3. Ariel Yankelevich    03/15/2019          	  David Mackey        	Oak North Issues (https://app.asana.com/0/326600806074978/1114340491893894/f)
4. Ariel Yankelevich  	03/19/2019          	  David Mackey        	Oak North Updates #2 (https://app.asana.com/0/326600806074978/1114502823954369/f)
5. Ariel Yankelevich    03/22/2019          	  David Mackey        	Oak North Updates #2 (https://app.asana.com/0/326600806074978/1114502823954369/f)
6. Leandro Brunner    	03/27/2018                David Mackey          GRAX Summary Issues (https://app.asana.com/0/326600806074978/1116043357503391/f)
7. Ariel Yankelevich    05/08/2019          	  David Mackey        	Delete GRAXDataRecords (https://app.asana.com/0/326600806074978/1121760476564629/f)
8. Ariel Yankelevich    05/10/2019          	  David Mackey        	Deactivate/Activate Scheduled Process (https://app.asana.com/0/326600806074978/1122644080179927/f)
*******************************************************************************/
public with sharing class GRAXScheduleProcessTriggerHandler {
    public static void triggerExecute(){        
        if(Trigger.isBefore) {
            if(Trigger.isInsert) {
                removeNextRunDateOnInactive();
            }
            if(Trigger.isUpdate) {
                addExecutionUniqueKey();
                summarizeRollupFields();
                fireCleanUpOnAbortedJob();
                removeNextRunDateOnInactive();
            }
        }

        if(Trigger.isAfter) {
            if(Trigger.isInsert) {
                addDefaultCustomName();
            }
        }
    }

    /*******************************************************************************
    Name              : addExecutionUniqueKey
    Description       : 
    Events            : before update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Leandro Brunner    	08/07/2018                David Mackey          Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
	2. Ariel Yankelevich    03/19/2019          	  David Mackey        	Oak North Updates #2 (https://app.asana.com/0/326600806074978/1114502823954369/f)
	3. Ariel Yankelevich    03/22/2019          	  David Mackey        	Oak North Updates #2 (https://app.asana.com/0/326600806074978/1114502823954369/f)
	*******************************************************************************/
    public static void addExecutionUniqueKey() {
        Boolean condition;

        for(Integer i = 0; i < Trigger.size; i++){
            GRAX_Schedule_Process__c gspNew = (GRAX_Schedule_Process__c)Trigger.new[i];
            GRAX_Schedule_Process__c gspOld = (GRAX_Schedule_Process__c)Trigger.old[i];
            
            condition = gspOld.Status__c <> gspNew.Status__c;
            condition &= gspNew.Status__c == 'Running';

            if(condition) {
                gspNew.Execution_Unique_Key__c = GRAXUtils.generate20UniqueKey();
                gspNew.Last_Start_Time__c = gspNew.Start_Time__c;
                gspNew.Start_Time__c = System.now();
                
                // Set the rollup counters to zero, every time the process runs
                gspNew.Total_Records_To_Send__c = 0;
                gspNew.Total_Records_Sent__c = 0;
                gspNew.Total_Records_Errors__c = 0;
            }
        }
    }
    
    
    /*******************************************************************************
    Name              : summarizeRollupFields
    Description       : This trigger summarizes the rollup fields from the GRAX_Data_Record__c related records
    Events            : before update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Ariel Yankelevich      	03/15/2019          David Mackey        Oak North Issues (https://app.asana.com/0/326600806074978/1114340491893894/f)
    2. Ariel Yankelevich    	03/22/2019          David Mackey        Oak North Updates #2 (https://app.asana.com/0/326600806074978/1114502823954369/f)
	*******************************************************************************/
    
    public static void summarizeRollupFields(){
        Set<String> rollupFields = new Set<String>{'Total_Records_To_Send__c', 'Total_Records_Sent__c', 'Total_Records_Errors__c'};
        
        for(Integer i = 0; i < Trigger.size; i++){
        	GRAX_Schedule_Process__c gspNew = (GRAX_Schedule_Process__c)Trigger.new[i];
            GRAX_Schedule_Process__c gspOld = (GRAX_Schedule_Process__c)Trigger.old[i];
            
            for(String fieldName : rollupFields){
            	if(GRAXDataRecordTriggerHandler.GRAXScheduleProcRollupFields.contains(fieldName)){
                    gspNew.put(fieldName, (Double)gspNew.get(fieldName) + (Double)gspOld.get(fieldName));
                }
            }
        }
    }


    /*******************************************************************************
    Name              : addDefaultCustomName
    Description       : 
    Events            : before update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Leandro Brunner    	03/27/2018              David Mackey          GRAX Summary Issues (https://app.asana.com/0/326600806074978/1116043357503391/f)
	*******************************************************************************/
    public static void addDefaultCustomName() {
        List<GRAX_Schedule_Process__c> gspToUpdateList = new List<GRAX_Schedule_Process__c>();

        for(Integer i = 0; i < Trigger.size; i++){
            GRAX_Schedule_Process__c gspNew = (GRAX_Schedule_Process__c)Trigger.new[i];

            if(String.isBlank(gspNew.Name__c) && String.isNotBlank(gspNew.type__c)) {
                GRAX_Schedule_Process__c gspToUpdate = new GRAX_Schedule_Process__c(Id=gspNew.Id);
                gspToUpdate.Name__c = GRAXBackupCtrl.getDefaultSpName(gspNew);

                gspToUpdateList.add(gspToUpdate);
            }
        }

        if(gspToUpdateList.size() > 0) {
            update gspToUpdateList;
        }
    }
    
    /*******************************************************************************
    Name              : fireCleanUpOnAbortedJob
    Description       : 
    Events            : before update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Ariel Yankelevich    	05/08/2019         	David Mackey        Delete GRAXDataRecords (https://app.asana.com/0/326600806074978/1121760476564629/f)
	*******************************************************************************/
    public static void fireCleanUpOnAbortedJob(){
        Boolean fireCleanUpBatch = false;

        for(Integer i = 0; i < Trigger.size; i++){
            GRAX_Schedule_Process__c gspNew = (GRAX_Schedule_Process__c)Trigger.new[i];
            GRAX_Schedule_Process__c gspOld = (GRAX_Schedule_Process__c)Trigger.old[i];
            
            Boolean condition = gspOld.Status__c <> gspNew.Status__c;
            condition &= gspNew.Status__c == 'Aborted';

            if(condition) {
            	// Update the Execution Unique Key on this record, in order to let the Clean Up process delete the related GRAX Data Records
            	gspNew.Execution_Unique_Key__c = GRAXUtils.generate20UniqueKey();
            	
            	fireCleanUpBatch = true;
            }
        }
        
        if(fireCleanUpBatch){
        	// Execute the Clean Up batch job
        	GRAXSchedulerToCleanDataRecords.executeGRAXBatchToCleanDataRecords();
        }
    }
    
    /*******************************************************************************
    Name              : removeNextRunDateOnInactive
    Description       : If the GRAX Schedule Process is being set to Inactive, remove the Next Run Date.
    Events            : before insert, before update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Ariel Yankelevich    05/10/2019          	  David Mackey        	Deactivate/Activate Scheduled Process (https://app.asana.com/0/326600806074978/1122644080179927/f)
	*******************************************************************************/
    public static void removeNextRunDateOnInactive(){
    	for(Integer i = 0; i < Trigger.size; i++){
            GRAX_Schedule_Process__c gspNew = (GRAX_Schedule_Process__c)Trigger.new[i];
            
            Boolean condition = gspNew.Active__c == false;
            
            if(Trigger.isUpdate){
            	GRAX_Schedule_Process__c gspOld = (GRAX_Schedule_Process__c)Trigger.old[i];
            	
            	condition &= gspOld.Active__c <> gspNew.Active__c;
            }
            
            if(condition) {
            	// If the GRAX Schedule Process is being set to Inactive, remove the Next Run Date
            	gspNew.Next_Run_Date__c = null;
            }
        }
    }
}
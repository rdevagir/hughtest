/*****************************************************************************************
Name              : GRAXDataRecordTriggerHandler
Description       : -
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Ariel Yankelevich       06/06/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
2. Ariel Yankelevich	   01/30/2019			David Mackey		Update GRAXBatchtoDelete Process (https://app.asana.com/0/326600806074978/999564713541979/f)
******************************************************************************************/

public with sharing class GRAXDataRecordTriggerHandler {
	
    public static void triggerExecute(){        
        if(Trigger.isAfter){
        	if(Trigger.isInsert){
        		rollUpTotalRecordsToProcess();
                rollUpTotalAsyncRecordsToProcess();
            }else if(Trigger.isUpdate){
                rollUpTotalRecordsSuccessfullySent();
        		rollUpTotalAsyncRecordsSuccessfullySent();
        		rollUpTotalDeleteInfo();
                rollUpTotalValuesToScheduleProcess();
        	}else if(Trigger.isDelete){
        		rollUpTotalRecordsToProcess();
                rollUpTotalAsyncRecordsToProcess();
        	}else if(Trigger.isUndelete){
        		rollUpTotalRecordsToProcess();
                rollUpTotalAsyncRecordsToProcess();
        	}            
        }
    }
    
    public static Set<String> GRAXArchiveProcRollupFields = new Set<String>();
    private static Set<String> asyncObjects2ProcessByGRAX = new Set<String>{'Attachment', 'ContentVersion'};
    public static Set<String> GRAXScheduleProcRollupFields = new Set<String>();

    /*******************************************************************************
    Name              : rollUpTotalRecordsToProcess
    Description       : Counts the total number of GRAX Data Records that will be archived
    Events            : after insert, after delete, after undelete
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Ariel Yankelevich       06/06/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
	*******************************************************************************/
    
    public static void rollUpTotalRecordsToProcess(){
        Map<Id, GRAX_Archive_Process__c> counterByArchiveProc = new Map<Id, GRAX_Archive_Process__c>();
        
        for(Integer i = 0; i < Trigger.size; i++){
            if(Trigger.isInsert || Trigger.isUndelete){
                GRAX_Data_Record__c triggerNew = (GRAX_Data_Record__c)Trigger.new[i];
                
                Boolean condition = triggerNew.GRAX_Archive_Process__c <> null;
                
                if(condition){
                    if(!counterByArchiveProc.containsKey(triggerNew.GRAX_Archive_Process__c)){
                        counterByArchiveProc.put(triggerNew.GRAX_Archive_Process__c, new GRAX_Archive_Process__c(Id = triggerNew.GRAX_Archive_Process__c, Records_To_Process__c = 0));
                    }
                    GRAX_Archive_Process__c archiveProc = counterByArchiveProc.get(triggerNew.GRAX_Archive_Process__c);
                    archiveProc.Records_To_Process__c += 1;
                }
            }else if(Trigger.isDelete){
            	GRAX_Data_Record__c triggerOld = (GRAX_Data_Record__c)Trigger.old[i];
    		
                Boolean condition = triggerOld.GRAX_Archive_Process__c <> null;
                
                if(condition){
                    if(!counterByArchiveProc.containsKey(triggerOld.GRAX_Archive_Process__c)){
                        counterByArchiveProc.put(triggerOld.GRAX_Archive_Process__c, new GRAX_Archive_Process__c(Id = triggerOld.GRAX_Archive_Process__c, Records_To_Process__c = 0));
                    }
                    GRAX_Archive_Process__c archiveProc = counterByArchiveProc.get(triggerOld.GRAX_Archive_Process__c);
                    archiveProc.Records_To_Process__c += -1;
                }
            }  
    	}
        
        if(!counterByArchiveProc.isEmpty()){
            GRAXArchiveProcRollupFields.addAll(new Set<String>{'Records_To_Process__c'});
            update counterByArchiveProc.values();
            GRAXArchiveProcRollupFields.removeAll(new Set<String>{'Records_To_Process__c'});
        }
    }
    
    
    /*******************************************************************************
    Name              : rollUpTotalAsyncRecordsToProcess
    Description       : Counts the total number of Async GRAX Data Records that will be archived
    Events            : after update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Ariel Yankelevich       06/06/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
	*******************************************************************************/
    
    public static void rollUpTotalAsyncRecordsToProcess(){
        Map<Id, GRAX_Archive_Process__c> counterByArchiveProc = new Map<Id, GRAX_Archive_Process__c>();
        
        for(Integer i = 0; i < Trigger.size; i++){
            if(Trigger.isInsert || Trigger.isUndelete){
                GRAX_Data_Record__c triggerNew = (GRAX_Data_Record__c)Trigger.new[i];
                
                Boolean condition = triggerNew.GRAX_Archive_Process__c <> null;
                condition &= asyncObjects2ProcessByGRAX.contains(triggerNew.Salesforce_Object__c);
                
                if(condition){
                    if(!counterByArchiveProc.containsKey(triggerNew.GRAX_Archive_Process__c)){
                        counterByArchiveProc.put(triggerNew.GRAX_Archive_Process__c, new GRAX_Archive_Process__c(Id = triggerNew.GRAX_Archive_Process__c, Async_Records_to_Process__c = 0));
                    }
                    GRAX_Archive_Process__c archiveProc = counterByArchiveProc.get(triggerNew.GRAX_Archive_Process__c);
                    archiveProc.Async_Records_to_Process__c += 1;    			
                }
            }else if(Trigger.isDelete){
            	GRAX_Data_Record__c triggerOld = (GRAX_Data_Record__c)Trigger.old[i];
    		
                Boolean condition = triggerOld.GRAX_Archive_Process__c <> null;
                condition &= asyncObjects2ProcessByGRAX.contains(triggerOld.Salesforce_Object__c);
                
                if(condition){
                    if(!counterByArchiveProc.containsKey(triggerOld.GRAX_Archive_Process__c)){
                        counterByArchiveProc.put(triggerOld.GRAX_Archive_Process__c, new GRAX_Archive_Process__c(Id = triggerOld.GRAX_Archive_Process__c, Async_Records_to_Process__c = 0));
                    }
                    GRAX_Archive_Process__c archiveProc = counterByArchiveProc.get(triggerOld.GRAX_Archive_Process__c);
                    archiveProc.Async_Records_to_Process__c += -1;    			
                }
            }  
    	}
        
        if(!counterByArchiveProc.isEmpty()){
            GRAXArchiveProcRollupFields.add('Async_Records_to_Process__c');
            update counterByArchiveProc.values();
            GRAXArchiveProcRollupFields.remove('Async_Records_to_Process__c');
        }
    }    
    
    
    /*******************************************************************************
    Name              : rollUpTotalRecordsSuccessfullySent
    Description       : Counts the total number of GRAX Data Records that were Successfully Sent to GRAX
    Events            : after update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Ariel Yankelevich       06/06/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
	*******************************************************************************/
    
    public static void rollUpTotalRecordsSuccessfullySent(){
        Map<Id, GRAX_Archive_Process__c> counterByArchiveProc = new Map<Id, GRAX_Archive_Process__c>();
        
        for(Integer i = 0; i < Trigger.size; i++){
            GRAX_Data_Record__c triggerNew = (GRAX_Data_Record__c)Trigger.new[i];
            GRAX_Data_Record__c triggerOld = (GRAX_Data_Record__c)Trigger.old[i];
                
            Boolean condition = triggerNew.Status__c == 'Sent Successful';
            condition |= triggerOld.Status__c == 'Sent Successful';
            condition &= triggerNew.GRAX_Archive_Process__c <> null;
            condition &= triggerNew.Status__c <> triggerOld.Status__c;            
            
            if(condition){
                Double counter = 1;
                if(triggerOld.Status__c == 'Sent Successful'){
                    counter = -1;
                }
                
                if(!counterByArchiveProc.containsKey(triggerNew.GRAX_Archive_Process__c)){
                    counterByArchiveProc.put(triggerNew.GRAX_Archive_Process__c, new GRAX_Archive_Process__c(Id = triggerNew.GRAX_Archive_Process__c, Records_Successfully_Sent__c = 0));
                }
                GRAX_Archive_Process__c archiveProc = counterByArchiveProc.get(triggerNew.GRAX_Archive_Process__c);
                archiveProc.Records_Successfully_Sent__c += counter;    			
            }
    	}
        
        if(!counterByArchiveProc.isEmpty()){
            GRAXArchiveProcRollupFields.add('Records_Successfully_Sent__c');
            update counterByArchiveProc.values();
            GRAXArchiveProcRollupFields.remove('Records_Successfully_Sent__c');
        }
    }
    
    
    /*******************************************************************************
    Name              : rollUpTotalAsyncRecordsSuccessfullySent
    Description       : Counts the total number of Asyn GRAX Data Records that were Successfully Sent to GRAX
    Events            : after update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Ariel Yankelevich       06/06/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
	*******************************************************************************/
    
    public static void rollUpTotalAsyncRecordsSuccessfullySent(){
        Map<Id, GRAX_Archive_Process__c> counterByArchiveProc = new Map<Id, GRAX_Archive_Process__c>();
        
        for(Integer i = 0; i < Trigger.size; i++){
            GRAX_Data_Record__c triggerNew = (GRAX_Data_Record__c)Trigger.new[i];
            GRAX_Data_Record__c triggerOld = (GRAX_Data_Record__c)Trigger.old[i];
                
            Boolean condition = triggerNew.Records_To_Process__c <> triggerOld.Records_To_Process__c;
            condition |= triggerNew.Records_Sent_to_GRAX__c <> triggerOld.Records_Sent_to_GRAX__c;
            condition &= triggerNew.GRAX_Archive_Process__c <> null; 
            condition &= asyncObjects2ProcessByGRAX.contains(triggerNew.Salesforce_Object__c);
            condition &= triggerNew.Records_To_Process__c == triggerNew.Records_Sent_to_GRAX__c;
            condition &= triggerNew.Records_To_Process__c > 0;
            
            if(condition){
                if(!counterByArchiveProc.containsKey(triggerNew.GRAX_Archive_Process__c)){
                    counterByArchiveProc.put(triggerNew.GRAX_Archive_Process__c, new GRAX_Archive_Process__c(Id = triggerNew.GRAX_Archive_Process__c, Async_Records_Successfully_Sent__c = 0));
                }
                GRAX_Archive_Process__c archiveProc = counterByArchiveProc.get(triggerNew.GRAX_Archive_Process__c);
                archiveProc.Async_Records_Successfully_Sent__c += 1;    			
            }
    	}
        
        if(!counterByArchiveProc.isEmpty()){
            GRAXArchiveProcRollupFields.add('Async_Records_Successfully_Sent__c');
            update counterByArchiveProc.values();
            GRAXArchiveProcRollupFields.remove('Async_Records_Successfully_Sent__c');
        }
    }
    
    /*******************************************************************************
    Name              : rollUpTotalValuesToScheduleProcess
    Description       : Counts the total number of GRAX Data Records ID to send
    Events            : after update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Ariel Yankelevich      	03/15/2019          David Mackey          Oak North Issues (https://app.asana.com/0/326600806074978/1114340491893894/f)
	*******************************************************************************/
    public static void rollUpTotalValuesToScheduleProcess(){
    	Map<Id, Map<String, GRAX_Schedule_Process__c>> counterBySchedProcByExecUniqueKey = new Map<Id, Map<String, GRAX_Schedule_Process__c>>();
        
        for(Integer i = 0; i < Trigger.size; i++){
            GRAX_Data_Record__c triggerNew = (GRAX_Data_Record__c)Trigger.new[i];
            GRAX_Data_Record__c triggerOld = (GRAX_Data_Record__c)Trigger.old[i];
                
            Boolean condition = triggerNew.GRAX_Schedule_Process__c <> null;
            condition &= triggerNew.Execution_Unique_Key__c <> null;
            
            Boolean conditionTotalRecordsToSend = condition && triggerNew.Status__c == 'Processing';
            conditionTotalRecordsToSend &= triggerNew.Records_To_Process__c <> triggerOld.Records_To_Process__c;
            
            Boolean conditionTotalRecordsSent = condition && triggerNew.Status__c == 'Sent Successful';
            conditionTotalRecordsSent &= triggerNew.Status__c <> triggerOld.Status__c;
            
            Boolean conditionTotalRecordsErrors = condition && triggerNew.of_Times_Sent__c <> triggerOld.of_Times_Sent__c;
            conditionTotalRecordsErrors &= triggerNew.of_Times_Sent__c == 5;
            conditionTotalRecordsErrors &= triggerNew.Status__c == 'Error';
            
            if(conditionTotalRecordsToSend || conditionTotalRecordsSent || conditionTotalRecordsErrors){
                if(!counterBySchedProcByExecUniqueKey.containsKey(triggerNew.GRAX_Schedule_Process__c)){
                	counterBySchedProcByExecUniqueKey.put(triggerNew.GRAX_Schedule_Process__c, new Map<String, GRAX_Schedule_Process__c>());
                }
                Map<String, GRAX_Schedule_Process__c> counterByExecUniqueKey = counterBySchedProcByExecUniqueKey.get(triggerNew.GRAX_Schedule_Process__c);
                
                if(!counterByExecUniqueKey.containsKey(triggerNew.Execution_Unique_Key__c)){
                	counterByExecUniqueKey.put(triggerNew.Execution_Unique_Key__c, new GRAX_Schedule_Process__c(Id = triggerNew.GRAX_Schedule_Process__c, Total_Records_To_Send__c = 0, Total_Records_Sent__c = 0, Total_Records_Errors__c = 0));
                }
                
				GRAX_Schedule_Process__c schedProc = counterBySchedProcByExecUniqueKey.get(triggerNew.GRAX_Schedule_Process__c).get(triggerNew.Execution_Unique_Key__c);
                
                if(conditionTotalRecordsToSend){
                	schedProc.Total_Records_To_Send__c += triggerNew.Records_To_Process__c - triggerOld.Records_To_Process__c;
                }
                
                if(conditionTotalRecordsSent){
                	schedProc.Total_Records_Sent__c += triggerNew.Records_To_Process__c;
                }
                
                if(conditionTotalRecordsErrors){
                	schedProc.Total_Records_Errors__c += triggerNew.Records_To_Process__c;
                }
            }
    	}
        
        if(!counterBySchedProcByExecUniqueKey.isEmpty()){
        	// Query these Schedule Process records and only update those that match the Execution Unique Key
        	List<GRAX_Schedule_Process__c> schedProcs2Up = new List<GRAX_Schedule_Process__c>();
        	for(GRAX_Schedule_Process__c schedProc : [SELECT Id, Execution_Unique_Key__c FROM GRAX_Schedule_Process__c WHERE Id IN :counterBySchedProcByExecUniqueKey.keySet()]){
        		if(counterBySchedProcByExecUniqueKey.containsKey(schedProc.Id) && counterBySchedProcByExecUniqueKey.get(schedProc.Id).containsKey(schedProc.Execution_Unique_Key__c)){
	        		schedProcs2Up.add(counterBySchedProcByExecUniqueKey.get(schedProc.Id).get(schedProc.Execution_Unique_Key__c));
        		}
        	}
        	
        	if(!schedProcs2Up.isEmpty()){
	            GRAXScheduleProcRollupFields.addAll(new Set<String>{'Total_Records_To_Send__c', 'Total_Records_Sent__c', 'Total_Records_Errors__c'});
	            update schedProcs2Up;
	            GRAXScheduleProcRollupFields.removeAll(new Set<String>{'Total_Records_To_Send__c', 'Total_Records_Sent__c', 'Total_Records_Errors__c'});
        	}
        }
    }


	/*******************************************************************************
    Name              : rollUpTotalDeleteInfo
    Description       : Counts the total number of GRAX Data Records Id that were successfully Deleted or failed to be deleted after th limit of attempts
    Events            : after update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Ariel Yankelevich	   01/30/2019			David Mackey		Update GRAXBatchtoDelete Process (https://app.asana.com/0/326600806074978/999564713541979/f)
	*******************************************************************************/
    
    public static void rollUpTotalDeleteInfo(){
        Map<Id, GRAX_Archive_Process__c> counterByArchiveProc = new Map<Id, GRAX_Archive_Process__c>();
        
        for(Integer i = 0; i < Trigger.size; i++){
            GRAX_Data_Record__c triggerNew = (GRAX_Data_Record__c)Trigger.new[i];
            GRAX_Data_Record__c triggerOld = (GRAX_Data_Record__c)Trigger.old[i];
                
            Boolean condition = triggerNew.Records_Successfully_Deleted__c <> triggerOld.Records_Successfully_Deleted__c;
            condition |= triggerNew.Records_Failed_to_Delete__c <> triggerOld.Records_Failed_to_Delete__c;
            condition |= triggerNew.Records_To_Process__c <> triggerOld.Records_To_Process__c;
            condition &= triggerNew.GRAX_Archive_Process__c <> null;
            
            if(condition){
                if(!counterByArchiveProc.containsKey(triggerNew.GRAX_Archive_Process__c)){
                    counterByArchiveProc.put(triggerNew.GRAX_Archive_Process__c, new GRAX_Archive_Process__c(Id = triggerNew.GRAX_Archive_Process__c, Total_SFDC_Records__c = 0, Total_SFDC_Records_Deleted__c = 0, Total_SFDC_Records_Failed_to_Delete__c = 0));
                }
                GRAX_Archive_Process__c archiveProc = counterByArchiveProc.get(triggerNew.GRAX_Archive_Process__c);                
                
                if(triggerNew.Records_To_Process__c <> triggerOld.Records_To_Process__c){
                	archiveProc.Total_SFDC_Records__c += triggerNew.Records_To_Process__c - triggerOld.Records_To_Process__c;
                }
                
                if(triggerNew.Records_Successfully_Deleted__c <> triggerOld.Records_Successfully_Deleted__c){
                	archiveProc.Total_SFDC_Records_Deleted__c += triggerNew.Records_Successfully_Deleted__c - triggerOld.Records_Successfully_Deleted__c;
                }
                
                if(triggerNew.Records_Failed_to_Delete__c <> triggerOld.Records_Failed_to_Delete__c){
                	archiveProc.Total_SFDC_Records_Failed_to_Delete__c += triggerNew.Records_Failed_to_Delete__c - triggerOld.Records_Failed_to_Delete__c;
                }   			
            }
    	}
        
        if(!counterByArchiveProc.isEmpty()){
        	GRAXArchiveProcRollupFields.addAll(new Set<String>{'Total_SFDC_Records__c', 'Total_SFDC_Records_Deleted__c', 'Total_SFDC_Records_Failed_to_Delete__c'});
            update counterByArchiveProc.values();
            GRAXArchiveProcRollupFields.removeAll(new Set<String>{'Total_SFDC_Records__c', 'Total_SFDC_Records_Deleted__c', 'Total_SFDC_Records_Failed_to_Delete__c'});
        }
    }
}
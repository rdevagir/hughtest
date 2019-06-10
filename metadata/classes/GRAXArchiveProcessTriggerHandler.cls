/*****************************************************************************************
Name              : GRAXArchiveProcessTriggerHandler
Description       : -
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Ariel Yankelevich       06/06/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
******************************************************************************************/

public with sharing class GRAXArchiveProcessTriggerHandler {
	
    public static void triggerExecute(){        
        if(Trigger.isBefore){
        	if(Trigger.isUpdate){
                summarizeRollupFields();  
        	}           
        }
    }
    
    
    /*******************************************************************************
    Name              : summarizeRollupFields
    Description       : This trigger summarizes the rollup fields on the GRAX_Archive_Process__c record
    Events            : before update
    Revision History  : - 
    Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue  
    ----------------------------------------------------------------------------------------
    1. Ariel Yankelevich       06/06/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
	*******************************************************************************/
    
    public static void summarizeRollupFields(){
        Set<String> rollupFields = new Set<String>{'Async_Records_Successfully_Sent__c', 'Async_Records_to_Process__c', 'Records_Successfully_Sent__c', 'Records_To_Process__c', 'Total_SFDC_Records__c', 'Total_SFDC_Records_Deleted__c', 'Total_SFDC_Records_Failed_to_Delete__c'};
        
        for(Integer i = 0; i < Trigger.size; i++){
            for(String fieldName : rollupFields){
                if(GRAXDataRecordTriggerHandler.GRAXArchiveProcRollupFields.contains(fieldName)){
                    Trigger.new[i].put(fieldName, (Double)Trigger.new[i].get(fieldName) + (Double)Trigger.old[i].get(fieldName));
                }
            }
        }
    }
}
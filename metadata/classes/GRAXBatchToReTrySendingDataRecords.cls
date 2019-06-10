/*****************************************************************************************
Name              : GRAXBatchToReTrySendingDataRecords
Description       : Add a new Action in the Scheduled Job table when the status is 
					"Completed - Error Sending Data to GRAX" and then fire the batch process 
					which will set the variables to re-send the records which "completed with error".
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
2. Nahuel Leiva            05/28/2019			David Mackey		  Constellation Prod Backup Issues (https://app.asana.com/0/326600806074978/1124574665749273/f)
******************************************************************************************/
public class GRAXBatchToReTrySendingDataRecords implements Database.Batchable<sObject>, Database.Stateful {
	public String query = '';
	public Id graxScheduledProcess;
	
	public GRAXBatchToReTrySendingDataRecords(Id scheduledProcessId){
		GRAX_Schedule_Process__c scheduleProcess = new GRAX_Schedule_Process__c(Id = scheduledProcessId, Status__c = 'Sending data to GRAX', Total_Records_Errors__c = 0);
		this.graxScheduledProcess = scheduledProcessId;
		update scheduleProcess;
	}
    public Database.QueryLocator start(Database.BatchableContext bc) {
    	query = 'SELECT Id, of_Times_Sent__c FROM GRAX_Data_Record__c WHERE GRAX_Schedule_Process__r.Id = \'' + graxScheduledProcess + '\'';
    	query += ' AND of_Times_Sent__c >= 5 AND Status__c = \'Error\'';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<GRAX_Data_Record__c> masterScope) {
    	List<GRAX_Data_Record__c> listDataRecord = new List<GRAX_Data_Record__c>();
        for (GRAX_Data_Record__c gdc : masterScope) {
        	GRAX_Data_Record__c newDataRecord = new GRAX_Data_Record__c(Id = gdc.Id, of_Times_Sent__c = 0);
        	listDataRecord.add(newDataRecord);
        }
        if (!listDataRecord.isEmpty()) {
        	update listDataRecord;
        }
    }
    
    public void finish(Database.BatchableContext BC) {
    	GRAXSchedulerToResendDataRecords.executeGRAXBatchToResendDataRecords();
    }
}
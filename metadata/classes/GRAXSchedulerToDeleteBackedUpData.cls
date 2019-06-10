/*****************************************************************************************
Name              : GRAXSchedulerToDeleteBackedUpData
Description       : This Schedule process deletes all the SFDC records that have been successfully sent to the GRAX Cloud
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Ariel Yankelevich       05/10/2018           David Mackey        GRAX Archiving -- Salesforce Delete (https://app.asana.com/0/326600806074978/628249897265165/f)
2. Ariel Yankelevich       04/16/2019          	David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
******************************************************************************************/
global class GRAXSchedulerToDeleteBackedUpData implements Schedulable {
	global void execute(SchedulableContext sc) {
		GRAXSchedulerToDeleteBackedUpData.executeGRAXBatchToDeleteBackedUpData();
    }
    
    public static void executeGRAXBatchToDeleteBackedUpData(){
    	// Verify that this process is not currently running
    	String batchesRunningQuery = 'SELECT COUNT() FROM AsyncApexJob WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = \'GRAXBatchToDeleteBackedUpData\') AND Status IN (\'Queued\', \'Preparing\', \'Processing\', \'Holding\') LIMIT 1';
        
        if(Database.countQuery(batchesRunningQuery) == 0) {
        	GRAXBatchToDeleteBackedUpData b = new GRAXBatchToDeleteBackedUpData();
            if(!Test.isRunningTest() && b.startToDeleteBackedUpData) Database.executeBatch(b, GRAXUtils.getBatchMaxExecutionNumber());
        }
    }
}
/*****************************************************************************************
Name              : GRAXSchedulerToResendDataRecords
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       	04/17/2018			David Mackey        https://app.asana.com/0/326600806074978/633149554508924/f
2. Leandro Brunner       	08/21/2018			David Mackey        Initial Backup updates (https://app.asana.com/0/326600806074978/788118599521250/f)
3. Ariel Yankelevich     	04/16/2019          David Mackey        GRAX Archive Error Message (https://app.asana.com/0/326600806074978/1117627231071642/f)
4. Ariel Yankelevich		05/09/2019			David Mackey		503 Errors (https://app.asana.com/0/326600806074978/1121362448820852/f)
5. Ariel Yankelevich		05/16/2019			David Mackey		Optichains Prod Backup Issues (https://app.asana.com/0/326600806074978/1122687086503529/f)
******************************************************************************************/
global class GRAXSchedulerToResendDataRecords implements Schedulable {
    global void execute(SchedulableContext sc) {
        GRAXSchedulerToResendDataRecords.executeGRAXBatchToResendDataRecords();
        
        try{
        	if(sc <> null){
	          	// If this Job was a one-time Job, delete it from the Schedule Jobs Queue
	          	for(CronTrigger ct : [SELECT Id, NextFireTime, CronJobDetail.Name FROM CronTrigger WHERE Id =: sc.getTriggerId() LIMIT 1]){
	          		if(ct.NextFireTime == null && (ct.CronJobDetail.Name.contains('_Pause503_') || ct.CronJobDetail.Name.contains('_Resume_'))){
	          			System.abortJob(ct.Id);
	          		}
	          	}
          	}
		}catch(Exception e){
			System.debug(e.getMessage());
        }
    }
    
    public static void executeGRAXBatchToResendDataRecords(){
    	// Verify that this process is not currently running
    	String batchesRunningQuery = 'SELECT COUNT() FROM AsyncApexJob WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = \'GRAXBatchToResendDataRecords\') AND Status IN (\'Queued\', \'Preparing\', \'Processing\', \'Holding\') LIMIT 1';
        
        if(Database.countQuery(batchesRunningQuery) == 0) {
            if(!Test.isRunningTest()) Database.executeBatch(new GRAXBatchToResendDataRecords(), 10);
        }
    }
}
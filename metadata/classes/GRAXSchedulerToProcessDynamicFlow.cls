/*****************************************************************************************
Name              : GRAXSchedulerToProcessDynamicFlow
Description       :
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner         08/29/2018           David Mackey          Scheduled Job to Trigger a Flow (https://app.asana.com/0/326600806074978/778127037078388/f)
******************************************************************************************/
global class GRAXSchedulerToProcessDynamicFlow implements Schedulable {
    global void execute(SchedulableContext sc) {
        String batchesRunningQuery = 'SELECT COUNT() FROM AsyncApexJob WHERE ApexClassId IN (SELECT Id FROM ApexClass WHERE Name = \'GRAXBatchToProcessDynamicFlow\') AND Status IN (\'Queued\', \'Preparing\', \'Processing\') LIMIT 1';
        
        if(Database.countQuery(batchesRunningQuery) == 0) {
            List<GRAX_Dynamic_Flow_Trigger__mdt> gdfTriggerList = [SELECT Id, Flow_Unique_Name__c, Progressive_Query__c, SOQL_Query__c, Records_Param_Name__c FROM GRAX_Dynamic_Flow_Trigger__mdt];
            
            if(gdfTriggerList.size() > 0 || Test.isRunningTest()) {
                GRAXBatchToProcessDynamicFlow b = new GRAXBatchToProcessDynamicFlow(gdfTriggerList, 0);

                if(!Test.isRunningTest()) database.executebatch(b, Test.isRunningTest() ? 2 : b.batchSize);
            }
        }
   }
}
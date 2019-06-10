/*****************************************************************************************
Name              : GRAXBatchToProcessSchedJobMainObject
Description       : This batch process executes a GRAX Schedule Process job, calling itself object by object as defined in the selected hierarchy
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Ariel Yankelevich       06/18/2018           David Mackey        Backup and Restore Notes & Attachments (https://app.asana.com/0/326600806074978/692982800286805/f)
2. Ariel Yankelevich       07/18/2018           David Mackey        Multi-Object Backup (https://app.asana.com/0/326600806074978/743044564916005/f)
3. Leandro Brunner         08/14/2018           David Mackey        Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
4. Leandro Brunner         11/06/2018           David Mackey        Minor UI Enhancements (https://app.asana.com/0/326600806074978/880565726418326/f)
5. Ariel Yankelevich       11/27/2018           David Mackey        Updates for 11/27 (https://app.asana.com/0/326600806074978/923502192371298/f)
6. Leandro Brunner         02/26/2019           David Mackey        Update Backup Process (https://app.asana.com/0/326600806074978/1109887667389108/f)
******************************************************************************************/

global class GRAXBatchToProcessSchedJobMainObject implements Database.Batchable<sObject>, Database.Stateful{
    public GRAXBatchToProcessSchedJob mainBatchProcess;
    public List<Id> parentIds2ProcessForChild;

    public GRAXBatchToProcessSchedJobMainObject(GRAXBatchToProcessSchedJob mainBatchProcess){
        this.mainBatchProcess = mainBatchProcess;
    }
	
    public GRAXBatchToProcessSchedJobMainObject(String jobId, Boolean isExecuteNow, Boolean isMultiObjectRunning, Integer currentElementIndex){
        mainBatchProcess = new GRAXBatchToProcessSchedJob(jobId, null, currentElementIndex, null, isExecuteNow, isMultiObjectRunning);
    }
    
    global Database.querylocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(mainBatchProcess.query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        mainBatchProcess.executeMethod(BC, scope);
    }
    
    global void finish(Database.BatchableContext BC){
        mainBatchProcess.finishMethod(BC);
    }
}
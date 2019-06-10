/*****************************************************************************************
Name              : GRAXBatchToProcessDynamicFlow
Description       :
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner         08/29/2018           David Mackey          Scheduled Job to Trigger a Flow (https://app.asana.com/0/326600806074978/778127037078388/f)
2. Leandro Brunner         09/20/2018           David Mackey          Agco Fixes (https://app.asana.com/0/326600806074978/770976244463043/f)
******************************************************************************************/
global class GRAXBatchToProcessDynamicFlow implements Database.Batchable<sObject>, Database.Stateful {
    private List<GRAX_Dynamic_Flow_Trigger__mdt> gdfTriggerList;

    private Integer currentIndex;
    private String query;
    private List<String> selectedFields;

    public Integer batchSize = 1;

    public GRAXBatchToProcessDynamicFlow(List<GRAX_Dynamic_Flow_Trigger__mdt> gdfTriggerList, Integer currentIndex) {
        if(gdfTriggerList.size() > 0) {
            this.gdfTriggerList = gdfTriggerList;
            this.currentIndex = currentIndex;

            this.query = gdfTriggerList[currentIndex].SOQL_Query__c;
            
            selectedFields = query.mid(7, query.indexOfIgnoreCase(' FROM ') - 7).split('\\s*,\\s*');

            if(this.gdfTriggerList[this.currentIndex].Progressive_Query__c) {
                GRAX_Dynamic_Flow_Time__c gdfTime;

                String flowId = Test.isRunningTest() ? 'TestName' : this.gdfTriggerList[this.currentIndex].Id;

                try {
                    gdfTime = [SELECT Last_Start_Time__c FROM GRAX_Dynamic_Flow_Time__c WHERE Name = :flowId LIMIT 1];
                } catch(Exception e) {
                    gdfTime = new GRAX_Dynamic_Flow_Time__c(Name = flowId);
                }

                if(gdfTime.Last_Start_Time__c <> null || Test.isRunningTest()) {
                    Datetime lastStartTime = Test.isRunningTest() ? System.now() : Datetime.newInstance(Long.valueOf(gdfTime.Last_Start_Time__c));

                    this.query += (this.query.containsIgnoreCase(' WHERE ') ? ' AND ' : ' WHERE ') + gdfTriggerList[currentIndex].Date_Field_Name__c + ' >= ' + lastStartTime.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
                }

                gdfTime.Last_Start_Time__c = String.valueOf(System.now().getTime());
                upsert gdfTime;
            }

            System.debug('Query: ' + this.query);
        }
    }

    global Database.querylocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }

    global void execute(Database.BatchableContext BC, List<SObject> scope) {
        try {
            Map<String, Object> params = new Map<String, Object>();

            for(SObject s : scope) {
                List<String> rec = new List<String>();

                for(String f : selectedFields) {
                    rec.add(String.valueOf(s.get(f)));
                }

                if(rec.size() > 0) {
                    params.put(this.gdfTriggerList[this.currentIndex].Records_Param_Name__c, rec);
                }
            }

            if(!Test.isRunningTest()) {
                Flow.Interview dynamicFlow = Flow.Interview.createInterview(this.gdfTriggerList[this.currentIndex].Flow_Unique_Name__c, params);
                dynamicFlow.start();
            }
        } catch(Exception e) {
            System.debug(e);
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        this.currentIndex++;

        if(this.currentIndex < this.gdfTriggerList.size()) {
            GRAXBatchToProcessDynamicFlow b = new GRAXBatchToProcessDynamicFlow(this.gdfTriggerList, this.currentIndex);

            if(!Test.isRunningTest()) database.executebatch(b, b.batchSize);
        }
    }
}
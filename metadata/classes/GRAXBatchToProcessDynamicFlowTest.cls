/*****************************************************************************************
Name              : GRAXBatchToProcessDynamicFlowTest
Description       :
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner         09/03/2018           David Mackey          Scheduled Job to Trigger a Flow (https://app.asana.com/0/326600806074978/778127037078388/f)
******************************************************************************************/
@isTest
public class GRAXBatchToProcessDynamicFlowTest {
    @isTest
    static void GRAXBatchToProcessDynamicFlowTest1() {
        GRAXQuery__c gq = new GRAXQuery__c();
        gq.ObjectName__c = 'GRAXQuery__c';
        insert gq;

        List<GRAX_Dynamic_Flow_Trigger__mdt> gdfTriggerList;

        String gdfTrigger1 = '';
        gdfTrigger1 += '{';
        gdfTrigger1 += '"Name": "gdfTrigger1",';
        gdfTrigger1 += '"Batch_Size__c": 1,';
        gdfTrigger1 += '"Flow_Unique_Name__c": "TestFlow",';
        gdfTrigger1 += '"Progressive_Query__c": false,';
        gdfTrigger1 += '"SOQL_Query__c": "SELECT Id FROM GRAXQuery__c"';
        gdfTrigger1 += '}';

        String gdfTrigger2 = '';
        gdfTrigger2 += '{';
        gdfTrigger2 += '"Name": "gdfTrigger2",';
        gdfTrigger2 += '"Batch_Size__c": 1,';
        gdfTrigger2 += '"Flow_Unique_Name__c": "TestFlow",';
        gdfTrigger2 += '"Progressive_Query__c": true,';
        gdfTrigger2 += '"SOQL_Query__c": "SELECT Id FROM GRAXQuery__c"';
        gdfTrigger2 += '}';


        String gdfTriggerListString = '[' + gdfTrigger1 + ',' + gdfTrigger2 + ']';

        gdfTriggerList = (List<GRAX_Dynamic_Flow_Trigger__mdt>) JSON.deserialize(gdfTriggerListString, List<GRAX_Dynamic_Flow_Trigger__mdt>.class);

        GRAXBatchToProcessDynamicFlow b = new GRAXBatchToProcessDynamicFlow(gdfTriggerList, 0);

        Test.startTest();

        Id jobId = Database.executebatch(b, 1);

        Test.stopTest();
    }
}
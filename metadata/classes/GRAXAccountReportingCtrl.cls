/*****************************************************************************************
Name              : GRAXAccountReportingCtrl
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner         06/29/2018                               GRAX Reporting VF Page (https://app.asana.com/0/326600806074978/726976189699420/f)
******************************************************************************************/
public with sharing class GRAXAccountReportingCtrl {
    List<GRAX_Account_Reporting_Setting__mdt> gars;
    public String filterValue {get;set;}

    public GRAXAccountReportingCtrl(ApexPages.StandardController stdCtrl) {
        if(!Test.isRunningTest()) stdCtrl.addFields(new List<String>{'Name'});
        
        Account acc = (Account)stdCtrl.getRecord();
        filterValue = '"' + acc.Name + '"';
    }

    public List<GRAX_Account_Reporting_Setting__mdt> getSettings() {
        List<GRAX_Account_Reporting_Setting__mdt> garsList = [SELECT Report_ID__c, size__c, cacheResults__c, Filter_Key__c, Filter_Key_Id__c, filterKeyIndex__c FROM GRAX_Account_Reporting_Setting__mdt];
        
        return garsList;
    }
}
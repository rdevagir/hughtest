/*****************************************************************************************
Name              : GRAXBackupSummary
Description       : Do a callout to GRAX, generate a summary of a specific Execution Key and save it on Elastic.
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner			02/28/2019			David Mackey		Review "Backup Stats" (https://app.asana.com/0/326600806074978/1107778902588819/f)
******************************************************************************************/
public with sharing class GRAXBackupSummary {
    public GRAXBackupSummary() {}
    
    public static List<Map<String, Object>> summariesList;

    public static void generateExecutionSummary(String gspId, String executionUniqueKey) {
        if(summariesList == null) {
        	summariesList = new List<Map<String, Object>>();
        }
        
        if(String.isNotBlank(gspId) && String.isNotBlank(executionUniqueKey)) {
            Map<String, Object> extraInfo = new Map<String, Object>();
            Map<String, Object> extraInfoByObject = new Map<String, Object>();

            extraInfo.put('executionUniqueKey', executionUniqueKey);

            for(GRAX_Schedule_Process__c gsp : [SELECT Id, Name, type__c, Name__c, Object_Name__c, Start_Time__c, Last_Run_Date__c, Progressive__c, Archive__c, OwnerId, Owner.Name, Send_Notifications__c FROM GRAX_Schedule_Process__c WHERE Id = :gspId AND Execution_Unique_Key__c = :executionUniqueKey LIMIT 1]) {
                extraInfo.put('spId', gsp.Id);
                extraInfo.put('spName', String.isNotBlank(gsp.Name__c) ? gsp.Name__c : GRAXBackupCtrl.getDefaultSpName(gsp));
                extraInfo.put('objectName', gsp.Object_Name__c);
                extraInfo.put('isProgressive', gsp.Progressive__c);
                extraInfo.put('isArchive', gsp.Archive__c);
                extraInfo.put('OwnerId', gsp.OwnerId);
                extraInfo.put('OwnerName', gsp.Owner.Name);
                extraInfo.put('sendNotification', gsp.Send_Notifications__c);

                Map<String, Object> summaryResults = new Map<String, Object>();
                summaryResults.put('startTime', gsp.Start_Time__c);
                summaryResults.put('endTime', gsp.Last_Run_Date__c);
                summaryResults.put('timeElapsed', gsp.Last_Run_Date__c.getTime() - gsp.Start_Time__c.getTime());

                Map<String, Object> summaryMap;
                for(GRAX_Data_Record__c gdr : [SELECT Id, Salesforce_Object__c, Overall_SFObject_Process_Start_Time__c, Overall_SFObject_Process_End_Time__c FROM GRAX_Data_Record__c WHERE GRAX_Schedule_Process__c = :gspId AND Execution_Unique_Key__c = :executionUniqueKey AND Overall_SFObject_Process_Start_Time__c <> null AND Overall_SFObject_Process_End_Time__c <> null]) {
                    summaryMap = new Map<String, Object>();
                    summaryMap.put('startTime', gdr.Overall_SFObject_Process_Start_Time__c);
                    summaryMap.put('endTime', gdr.Overall_SFObject_Process_End_Time__c);
                    summaryMap.put('timeElapsed', gdr.Overall_SFObject_Process_End_Time__c.getTime() - gdr.Overall_SFObject_Process_Start_Time__c.getTime());
                    
                    extraInfoByObject.put(gdr.Salesforce_Object__c, summaryMap);
                }

                extraInfo.put('summaryResults', summaryResults);
                extraInfo.put('summaryMap', extraInfoByObject);
            }
            
            summariesList.add(extraInfo);
        }
    }
    
    public static void sendSummaries() {
        if(summariesList <> null && summariesList.size() > 0) {
            GRAXSettings gxcSettings = new GRAXSettings();

            String url = gxcSettings.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake/generateBackupSummaries';
            url += '?orgid=' + UserInfo.getOrganizationId();
            url += '&sessionid=' + UserInfo.getSessionId();
            url += '&userid=' + UserInfo.getUserId();
            url += '&endpoint=' + EncodingUtil.urlencode(GRAXUtils.getExternalAPIEndpoint(), 'utf-8');

            String ns = GRAXUtils.getPureNameSpace();
            if(ns <> null) {
                url += '&ns=' + ns;
            }
            
            // DEBUG ONLY!!!
            // url += '&doInsert=false&_regenerate=true'; // DEBUG ONLY!!!
            // DEBUG ONLY!!!

            System.debug(JSON.serialize(summariesList));
                
            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(url, JSON.serialize(summariesList));
            
            System.debug(callOutRes);

            if(callOutRes.success) {
                summariesList.clear();
            }
        }
    }
    
}
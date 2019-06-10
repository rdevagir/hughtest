/*****************************************************************************************
Name              : GRAXLogs
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner       11/27/2018             David Mackey        Logs Enhancement (https://app.asana.com/0/326600806074978/861352422200250/f)
4. Leandro Brunner       12/26/2018             David Mackey        Minor Updates (https://app.asana.com/0/326600806074978/857103514581849/f)
6. Ariel Yankelevich     03/14/2019          	David Mackey        Oak North Issues (https://app.asana.com/0/326600806074978/1114340491893894/f)
7. Leandro Brunner       04/23/2019             David Mackey        Object API Change (https://app.asana.com/0/326600806074978/1119480678990075/f)
******************************************************************************************/
public with sharing class GRAXLogs {
    private class LogStructure {
        public String source {get;set;}
        // public String objecttype {get;set;}
        // public String graxid {get;set;}
        // public String modulename {get;set;}
        public String package_name {get;set;}
        public String package_version {get;set;}
        public String info {get;set;}
        public String description {get;set;}
        public String err_message {get;set;}
        public String err_stack {get;set;}
        // public String record {get;set;}

        public LogStructure() {}
    }

    public static void addLogException(Exception e, String description) {
        addLogException(e, description, true);
    }

    public static void addLogException(Exception e, String description, Boolean async) {
        try {
            LogStructure log = new LogStructure();
            log.source = 'grax-salesforce (' + (Test.isRunningTest() ? 'TEST' : UserInfo.getOrganizationId()) + ')';
            log.info = e.getTypeName();
            log.err_message = e.getMessage();
            log.err_stack = e.getStackTraceString() + ', Line Number:' + e.getLineNumber();
            log.description = description;
            
            log.package_name = GRAXUtils.getPureNameSpace();
            log.package_version = GRAXUtils.getPackageVersion();

            if(String.isBlank(log.package_name)) {
                log.package_name = 'GRAX (unmanaged)';
                log.package_version = '1.?';
            }

            sendLog(JSON.serializePretty(log, true), async);
        } catch(Exception ex) {}
    }

    public static void addLogException(Exception e) {
        addLogException(e, null, true);
    }

    public static void addLogException(Exception e, Boolean async) {
        addLogException(e, null, async);
    }

    public static void sendLog(String content, Boolean async) {
        try {
            AsyncExecToSendLog asyncExecToSendLog = new AsyncExecToSendLog(content);

            if(async && !(System.isBatch() && Limits.getQueueableJobs() == 1)) {
                System.enqueueJob(asyncExecToSendLog);
            } else {
                asyncExecToSendLog.send();
            }
        } catch(Exception e) {
            System.debug(e);
        }
    }

    public class AsyncExecToSendLog implements Queueable, Database.AllowsCallouts {
        private String content;

        public AsyncExecToSendLog(String content) {
            this.content = content;
        }

        public void send() {
            try {
                GRAXSettings gxs = new GRAXSettings();

                String url = gxs.graxConfig.GRAX_Flow_URL__c + '/grax-app/grax-data-lake/sendLog';
                GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(url, this.content);

                System.debug(callOutRes);
            } catch(Exception e) {
            	System.debug(e.getMessage());
            }
        }

        public void execute(QueueableContext context) {
            this.send();
        }
    }
}
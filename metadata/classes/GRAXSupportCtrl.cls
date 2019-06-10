public with sharing class GRAXSupportCtrl {
    public transient string exceptionlist {get;set;}
    public transient GRAXLogging GRAXLogInfo {get;set;}
    
    public transient String LoggingJSON {get;set;}
    
    public GRAXSupportCtrl() {
		  GRAXLogInfo = GRAXLogging.GetExceptions();
		  LoggingJSON = GRAXLogInfo.LogJSON;
    }
    
}
@isTest
public with sharing class GRAXUnitTest {
	
	static final String graxsetting_apitoken = 'e74b42e509a30e7c9dc5527cc73a86fbe4fd0e0fe2271dfdf83c3933dabc7268';
	static final String graxsetting_gatewaytoken = 'nlqV5TlUov6On6kgev2by3dpdwct0QGN8Vkqj4MA';
	static final String graxsetting_licensetoken = 'U2FsdGVkX19PV5qeK5Vzm1TeHv8t2srLzktZLKMzFwY7OzjR3H8NzGUYgjtFOe4DBaLFKkvXPUjwumd5vVOngF5BpsuwcRSTo6/Pf8PmnHo=';
	static final String graxsetting_graphdburl = 'https://app88135813-UPGXLo:b.U6ppfez3ulMw.CW6bwPBPi6f0eE8S@hobby-fjnmeiioglmjgbkeecngjoal.dbs.graphenedb.com:24780';
	static final String graxsetting_flowurl = 'https://grax-devops.herokuapp.com';
	static final String graxsetting_graxapp = 'grax-devops';
	static final String graxsetting_apiurl = '';
    
    @isTest
    public static GRAXSettings getSettings(){
    		GRAXSettings gxs;
    		if (!GRAXSettings.IsConfigured()){
    			gxs = new GRAXSettings();
			gxs.graxConfig.ApiToken__c = GRAXUnitTest.graxsetting_apitoken;
			gxs.graxConfig.GatewayToken__c = GRAXUnitTest.graxsetting_gatewaytoken;
			gxs.graxConfig.LicenseToken__c = GRAXUnitTest.graxsetting_licensetoken;
			gxs.graxConfig.graphdburl__c = GRAXUnitTest.graxsetting_graphdburl;
			gxs.graxConfig.GRAX_Flow_URL__c = GRAXUnitTest.graxsetting_flowurl;
			gxs.graxConfig.GRAX_API_Url__c = GRAXUnitTest.graxsetting_apiurl;
			gxs.graxConfig.Heroku_App_Name__c = GRAXUnitTest.graxsetting_graxapp;
			gxs.UpdateSettings();
    		}else{
    			gxs = new GRAXSettings();
    		}
    		return gxs;
    }
    
    @isTest
    public static List<SObject> getTestAccount(){
    		List<SObject> records = [select Id, Name From Account ORDER BY Name ASC LIMIT 1];
    		return records;
    }

	/*****************************************************************************************
    Name              : SingleRequestMock
    Description       : 
    Revision History  :
    Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
    ----------------------------------------------------------------------------------------
    1. Leandro Brunner       04/17/2018				David Mackey        https://app.asana.com/0/326600806074978/633149554508924/f
    ******************************************************************************************/
    public class SingleRequestMock implements HttpCalloutMock {
        protected Integer code;
        protected String status;
        protected String bodyAsString;
        protected Blob bodyAsBlob;
        protected Map<String, String> responseHeaders;
        
        public SingleRequestMock(Integer code, String status, String body, Map<String, String> responseHeaders) {
            this.code = code;
            this.status = status;
            this.bodyAsString = body;
            this.bodyAsBlob = null;
            this.responseHeaders = responseHeaders;
        }
        
        public SingleRequestMock(Integer code, String status, Blob body, Map<String, String> responseHeaders) {
            this.code = code;
            this.status = status;
            this.bodyAsBlob = body;
            this.bodyAsString = null;
            this.responseHeaders = responseHeaders;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse resp = new HttpResponse();
            resp.setStatusCode(code);
            resp.setStatus(status);

            if (bodyAsBlob != null) {
                resp.setBodyAsBlob(bodyAsBlob);
            } else {
                resp.setBody(bodyAsString);
            }
            
            if (responseHeaders != null) {
                for (String key : responseHeaders.keySet()) {
                    resp.setHeader(key, responseHeaders.get(key));
                }
            }

            return resp;
        }
    }
}
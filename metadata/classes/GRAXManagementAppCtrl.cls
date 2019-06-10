/*****************************************************************************************
Name              : GRAXManagementAppCtrl
Description       :
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Joe Gaska         09/20/2018           David Mackey          
2. Leandro Brunner   05/31/2019           David Mackey                Date Format should be based on user locale (https://app.asana.com/0/326600806074978/1125157851523067/f)
******************************************************************************************/
public with sharing class GRAXManagementAppCtrl {
    public String url {get;set;}
    public String graxdomain {get;set;}
    public String sessionid {get;set;}
    public String endpoint {get;set;}
    public String token {get;set;}
    public String orgid {get;set;}
    public String userId {get;set;}
    public GRAXSettings gxs {get;set;}
    public String userLocale {get;set;}
    public String userTimeZone {get;set;}

    public GRAXManagementAppCtrl() {
        gxs = new GRAXSettings();

        this.userId = UserInfo.getUserId();

        GRAXPermissions gp = new GRAXPermissions(this.userId);

        if(gp.getIsAdmin() || Test.isRunningTest()) {
			orgid = UserInfo.getOrganizationId();
			
            this.url = gxs.graxConfig.GRAX_Flow_URL__c + '/grax-app/public/grax-react/index.html';
            this.sessionid = userinfo.getSessionId();
            //this.endpoint = EncodingUtil.urlencode(System.URL.getSalesforceBaseUrl().toExternalForm(),'utf-8');
            this.endpoint = EncodingUtil.urlencode(GRAXUtils.getExternalAPIEndpoint(),'utf-8');
            // this.graxdomain = EncodingUtil.urlencode(System.Url.getOrgDomainUrl().toExternalForm(),'utf-8');
           
            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(
                gxs.graxConfig.GRAX_Flow_URL__c + '/jwt', '{"url": "' + this.url + '"}');

            System.debug(callOutRes);
            if(callOutRes.success) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callOutRes.response);
                this.token = (String)responseMap.get('token');
                System.debug('Token: ' + this.token);
            }
        }

        userLocale = EncodingUtil.urlencode(UserInfo.getLocale(), 'utf-8');
        userTimeZone = EncodingUtil.urlencode(UserInfo.getTimeZone().getID(), 'utf-8');
    }

    public Boolean getIsAuthenticated() {
        return String.isNotBlank(this.token);
    }
}
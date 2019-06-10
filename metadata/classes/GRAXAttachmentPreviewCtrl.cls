/*****************************************************************************************
Name              : GRAXAttachmentPreviewCtrl
Description       :
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner    01/29/2019           David Mackey          
******************************************************************************************/
public with sharing class GRAXAttachmentPreviewCtrl {
    public String url {get;set;}
    public String graxdomain {get;set;}
    public String sessionid {get;set;}
    public String endpoint {get;set;}
    public String token {get;set;}
    public String orgid {get;set;}
    public String userId {get;set;}

    public Integer maxDownloadSize {
        get {
            return 1000000 * 15; // 15mb in bytes
        }
    }

    public transient String graxorgid {get;set;}
    public transient String objectType {get;set;}
    public transient String recordId {get;set;}
    public transient String name {get;set;}
    public transient String mimeType {get;set;}
    public transient Integer size {get;set;}

    public static GRAXSettings gxs {
        get {
            return new GRAXSettings();
        }
    }

    public GRAXAttachmentPreviewCtrl() {
        this.userId = UserInfo.getUserId();

        GRAXPermissions gp = new GRAXPermissions(this.userId);

        if(gp.getIsDataAdmin() || Test.isRunningTest()) {
            this.orgid = UserInfo.getOrganizationId();
            this.sessionid = userinfo.getSessionId();
            this.endpoint = EncodingUtil.urlencode(GRAXUtils.getExternalAPIEndpoint(), 'utf-8');

            this.url = gxs.graxConfig.GRAX_Flow_URL__c + '/graxproxy/api/datalake/getfile';

            GRAXCloud.CallOutResponse callOutRes = GRAXCloud.calloutnow(
                gxs.graxConfig.GRAX_Flow_URL__c + '/jwt', '{"url": "' + this.url + '"}');

            System.debug(callOutRes);

            if(callOutRes.success) {
                Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(callOutRes.response);
                
                this.token = (String)responseMap.get('token');
                
                System.debug('Token: ' + this.token);
            }
        }
    }

    public String getDownloadUrl() {
        return this.url + (
            '/' + graxorgid + '/' + objectType + '/' + recordId + '/' + name
        ) + '?orgid=' + orgid + '&sessionid=' + sessionid + '&endpoint=' + endpoint + '&token=' + token + '&userid=' + userid;
    }

    public Boolean getIsAuthenticated() {
        return String.isNotBlank(this.token);
    }
}
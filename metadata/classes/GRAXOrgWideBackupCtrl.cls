/*****************************************************************************************
Name              : GRAXOrgWideBackupCtrl
Description       :
Revision History  :
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner         09/03/2018           David Mackey          Create a "Org Wide Backup" tab (https://app.asana.com/0/326600806074978/792168074245647/f)
******************************************************************************************/
public with sharing class GRAXOrgWideBackupCtrl {
    public String url {get;set;}
    public String token {get;set;}

    public GRAXOrgWideBackupCtrl() {
        GRAXPermissions gp = new GRAXPermissions(UserInfo.getUserId());

        if(gp.getIsAdmin() || Test.isRunningTest()) {
            GRAXSettings gxs = new GRAXSettings();

            this.url = gxs.graxConfig.GRAX_Flow_URL__c + '/upload.html';

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

    public Boolean getIsAuthenticated() {
        return String.isNotBlank(this.token);
    }
}
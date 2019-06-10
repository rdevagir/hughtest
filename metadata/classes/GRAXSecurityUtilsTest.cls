@isTest
public with sharing class GRAXSecurityUtilsTest {
    @isTest
    public static void GRAXSecurityUtilsTest1() {
        System.assert(GRAXSecurityUtils.checkAccess('Account', 'Name', GRAXSecurityUtils.FLSEnums.CREATE));
        System.assert(GRAXSecurityUtils.checkAccess('Account', 'Name', GRAXSecurityUtils.FLSEnums.READ));
        System.assert(GRAXSecurityUtils.checkAccess('Account', 'Name', GRAXSecurityUtils.FLSEnums.UPSRT));
        System.assert(GRAXSecurityUtils.checkAccess('Account', 'Name', GRAXSecurityUtils.FLSEnums.REMOVE));

        System.assert(!GRAXSecurityUtils.checkAccess('Account', 'Id', GRAXSecurityUtils.FLSEnums.CREATE));
        System.assert(GRAXSecurityUtils.checkAccess('Account', 'Id', GRAXSecurityUtils.FLSEnums.READ));
        System.assert(!GRAXSecurityUtils.checkAccess('Account', 'Id', GRAXSecurityUtils.FLSEnums.UPSRT));
        System.assert(GRAXSecurityUtils.checkAccess('Account', 'Id', GRAXSecurityUtils.FLSEnums.REMOVE));
    }
}
@isTest
public class GRAXOrgWideBackupCtrlTest {
    @isTest
    static void GRAXOrgWideBackupCtrlTest1() {
        String responseData = '{"token": "test123"}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', responseData, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        GRAXOrgWideBackupCtrl gowbc;

        Test.startTest();
        gowbc = new GRAXOrgWideBackupCtrl();
        Test.stopTest();

        System.assertNotEquals(null, gowbc.url);
        System.assert(gowbc.getIsAuthenticated());
        System.assertEquals('test123', gowbc.token);
    }
}
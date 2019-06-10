@isTest
public with sharing class GRAXManagementAppCtrlTest {
    @isTest
    public static void GRAXManagementAppCtrlTest1() {
        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"token": "Test Token"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        GRAXManagementAppCtrl gmac = new GRAXManagementAppCtrl();

        System.assert(gmac.getIsAuthenticated());

        Test.stopTest();
    }
}
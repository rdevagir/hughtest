@isTest
public with sharing class GRAXAttachmentPreviewCtrl_Test {
    @isTest
    public static void GRAXAttachmentPreviewCtrl_Test1() {
        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"token": "Test Token"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        GRAXAttachmentPreviewCtrl gapc = new GRAXAttachmentPreviewCtrl();

        System.assert(gapc.getIsAuthenticated());
        System.assertNotEquals(null, gapc.getDownloadUrl());

        Test.stopTest();
    }

    @isTest
    public static void GRAXAttachmentPreviewCtrl_Test2() {
        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"token": "Test Token"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        GRAXAttachmentPreviewCtrl gapc = new GRAXAttachmentPreviewCtrl();

        System.assertNotEquals(null, gapc.maxDownloadSize);

        Test.stopTest();
    }
}
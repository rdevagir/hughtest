@isTest
public with sharing class GRAXElasticRecordDisplayCtrlTest {
    @isTest
    public static void GRAXElasticRecordDisplayCtrlTest_Test1() {
        Test.startTest();
        GRAXElasticRecordDisplayCtrl gerdc = new GRAXElasticRecordDisplayCtrl();

        System.assert(gerdc.isAdmin <> null);

        Test.stopTest();
    }

    @isTest
    public static void GRAXElasticRecordDisplayCtrlTest_Test2() {
        String response = '{';
        response += '"data": [{"Name": "Test", "graxorgid": "Test"}]';
        response += '}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', response, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        GRAXElasticRecordDisplayCtrl gerdc = new GRAXElasticRecordDisplayCtrl();

        System.assert(gerdc.isAdmin <> null);

        gerdc.objName = 'Account';
        gerdc.recordId = 'Test';
        gerdc.orgId = 'Test';

        gerdc.isAdmin = true;

        System.assert(gerdc.getElasticFields().size() == 2);

        Test.stopTest();
    }
}
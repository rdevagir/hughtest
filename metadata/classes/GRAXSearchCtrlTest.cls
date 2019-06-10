@isTest
public with sharing class GRAXSearchCtrlTest {
    @isTest
    public static void GRAXSearchCtrlTest_Test1() {
        PageReference pageRef = Page.GRAXSearch;
        Test.setCurrentPage(pageRef);

        pageRef.getParameters().put('isdtp', '1');

        Test.startTest();
        GRAXSearchCtrl gsc = new GRAXSearchCtrl();

        System.assert(gsc.isEmbedded);

        Test.stopTest();
    }

    @isTest
    public static void GRAXSearchCtrlTest_changeIndexToQuery() {
        PageReference pageRef = Page.GRAXSearch;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GRAXSearchCtrl gsc = new GRAXSearchCtrl();

        System.assertEquals('', gsc.indexToQuery);

		String response = '{"Id":"String","Name": "String"}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', response, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

		pageRef.getParameters().put('indexToQueryValue', 'Account');
        gsc.changeIndexToQuery();

        System.assertEquals('Account', gsc.indexToQuery);

        Test.stopTest();
    }

    @isTest
    public static void GRAXSearchCtrlTest_getGraxIndexes1() {
        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '[{"name": "test"}]', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        GRAXSearchCtrl gsc = new GRAXSearchCtrl();

        System.assertEquals('[{"name": "test"}]', gsc.getGraxIndexes());

        Test.stopTest();
    }

    @isTest
    public static void GRAXSearchCtrlTest_getGraxIndexes2() {
        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(500, '', '{"message": "Internal Server Error"}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        GRAXSearchCtrl gsc = new GRAXSearchCtrl();

        System.assertEquals('[]', gsc.getGraxIndexes());

        Test.stopTest();
    }

    @isTest
    public static void GRAXSearchCtrlTest_retriveTableRecords() {
        PageReference pageRef = Page.GRAXSearch;
        Test.setCurrentPage(pageRef);

        String response = '{';
        response += '"results": [{"Name": "Test"}],';
        response += '"extraInfo": {';
        response += '"total": 1';
        response += '}';
        response += '}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', response, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        GRAXSearchCtrl gsc = new GRAXSearchCtrl();
        pageRef.getParameters().put('selectedFields', '["Id","Name"]');
        pageRef.getParameters().put('filterSearchTerm', 'doc.Name:Test');
        pageRef.getParameters().put('page', '1');
        pageRef.getParameters().put('sort', 'Id');
        pageRef.getParameters().put('sortOrder', 'asc');

        gsc.updateSearchDataTable();

        System.assertEquals(true, gsc.isRetrieved);
        System.assertEquals('[{"Name":"Test"}]', gsc.retrievedRecordsJSON);
        System.assertEquals(1, gsc.totalRecords);
        
        Test.stopTest();
    }

    @isTest
    public static void GRAXSearchCtrlTest_retriveTableRecords2() {
        PageReference pageRef = Page.GRAXSearch;
        Test.setCurrentPage(pageRef);

        String response = '{}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(500, '', response, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        GRAXSearchCtrl gsc = new GRAXSearchCtrl();
        pageRef.getParameters().put('selectedFields', '["Id","Name"]');
        pageRef.getParameters().put('filterSearchTerm', 'doc.Name:Test');
        pageRef.getParameters().put('page', '1');
        pageRef.getParameters().put('sort', 'Id');
        pageRef.getParameters().put('sortOrder', 'asc');

        gsc.updateSearchDataTable();

        System.assertEquals(true, gsc.isRetrieved);
        System.assertEquals('[]', gsc.retrievedRecordsJSON);
        System.assertEquals(0, gsc.totalRecords);
        
        Test.stopTest();
    }

    @isTest
    public static void GRAXSearchCtrlTest_updateSearchDataTable() {
        PageReference pageRef = Page.GRAXSearch;
        Test.setCurrentPage(pageRef);

        String response = '{';
        response += '"results": [{"Name": "Test"}],';
        response += '"extraInfo": {';
        response += '"total": 1';
        response += '}';
        response += '}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', response, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        GRAXSearchCtrl gsc = new GRAXSearchCtrl();

        pageRef.getParameters().put('selectedFields', '["Id","Name"]');
        pageRef.getParameters().put('filterSearchTerm', 'doc.Name:Test');
        pageRef.getParameters().put('page', '1');
        pageRef.getParameters().put('sort', 'Id');
        pageRef.getParameters().put('sortOrder', 'asc');

        gsc.updateSearchDataTable();

        System.assertEquals('Id,Name', gsc.selectedFields);
        System.assertEquals(2, gsc.selectedFieldsList.size());
        System.assertEquals(1, gsc.page);
        System.assertEquals('Id', gsc.pageSort);
        System.assertEquals('asc', gsc.pageSortOrder);

        System.assertEquals(true, gsc.getHasResults());
        System.assertEquals(true, gsc.getIsFieldSelected());        
        
        Test.stopTest();
    }

    @isTest
    public static void GRAXSearchCtrlTest_getFieldsJSON() {
        String response = '{"Id":"String","Name": "String"}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', response, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        GRAXSearchCtrl gsc = new GRAXSearchCtrl();

        System.assertEquals(response, gsc.getFieldsJSON());
        
        Test.stopTest();
    }

    @isTest
    public static void GRAXSearchCtrlTest_getFieldsJSON2() {
        String response = '{"Id":"String","Name": "String"}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(500, '', response, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        GRAXSearchCtrl gsc = new GRAXSearchCtrl();

        System.assertEquals('{}', gsc.getFieldsJSON());
        
        Test.stopTest();
    }

    @isTest
    public static void GRAXSearchCtrlTest_previewRecord() {
        PageReference pageRef = Page.GRAXSearch;
        Test.setCurrentPage(pageRef);

        Test.startTest();
        GRAXSearchCtrl gsc = new GRAXSearchCtrl();

        pageRef.getParameters().put('objName', 'Account');
        pageRef.getParameters().put('recordId', 'Test');
        pageRef.getParameters().put('orgId', 'Test');

        gsc.previewRecord();

        System.assertEquals('Account', gsc.previewRecordObjName);
        System.assertEquals('Test', gsc.previewRecordId);
        System.assertEquals('Test', gsc.previewRecordOrgId);

        Test.stopTest();
    }

}
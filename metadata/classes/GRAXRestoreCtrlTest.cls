/*****************************************************************************************
Name              : GRAXRestoreCtrlTest
Description       : 
Revision History  :
Created/Modified by   Created/Modified Date     Requested by        Related Task/Issue     
----------------------------------------------------------------------------------------
1. Leandro Brunner    		05/22/2018          David Mackey        "Restore" Button for Backup/Archive (https://app.asana.com/0/326600806074978/665432711419635/f)
2. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
******************************************************************************************/
@isTest
public class GRAXRestoreCtrlTest {

    private static void insertAccounts() {
        Account acc = new Account(Name='TestAccount');
        insert acc;

        Account pacc = new Account(Name='TestAccount2', ParentId=acc.Id);
        insert pacc;
    }

    @isTest
    static void GRAXRestoreCtrlConstructorTest() {
        insertAccounts();

        PageReference pageRef = Page.GRAXRestore;
        Test.setCurrentPage(pageRef);

        Id accId;

        for(Account acc : [SELECT Id FROM Account WHERE Name = 'TestAccount2']) {
            accId = acc.Id;
        }

        pageRef.getParameters().put('Id', String.valueOf(accId));

        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();

        System.assertEquals('', grc.objToQuery);
        System.assertNotEquals(null, grc.fieldMap);
        System.assertNotEquals(null, grc.objectMap);
        System.assertNotEquals(null, grc.tableRecords);
        
        System.assertNotEquals(null, grc.parentId);
        System.assertEquals(accId, grc.parentId);
        System.assertEquals(accId.getSObjectType().getDescribe().getName(), grc.parentType);
    }

    @isTest
    static void GRAXRestoreCtrlPermissionsTest() {
        System.assertNotEquals(null, GRAXRestoreCtrl.gp);
    }

    @isTest
    static void changeObjToQueryTest() {
        PageReference pageRef = Page.GRAXRestore;
        Test.setCurrentPage(pageRef);

        pageRef.getParameters().put('Id', '001J0000020re5wIAA'); // Account

        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();

        grc.parentType = 'Account';
        
        String relatedJson = grc.getRelatedJSON();

        System.assertNotEquals(0, grc.childRelatedMap.size());
        System.assertNotEquals('[]', relatedJson);

        for(String i: grc.childRelatedMap.keySet()) {
            pageRef.getParameters().put('objToQueryValue', i);
            grc.changeObjToQuery();

            System.assertEquals(grc.childRelatedMap.get(i).name, grc.objToQuery);
            System.assertEquals(grc.childRelatedMap.get(i).value, grc.relToQuery);
        }

        System.assertNotEquals(0, grc.getSObjectFields().size());
        // System.assertNotEquals('[]', grc.getFieldsJSON());
    }

    @isTest
    static void retriveTableRecordsTest() {
        PageReference pageRef = Page.GRAXRestore;
        Test.setCurrentPage(pageRef);

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(500, '', '{}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();
        grc.isPersonAccountEnabled = true;
        grc.objToQuery = 'Account';
        grc.filterSearchTerm = 'doc.Name:test';
        grc.isPersonAccount = false;

        Test.startTest();
        grc.retriveTableRecords();
        Test.stopTest();
    }

    @isTest
    static void updateDataTableTest() {
        insertAccounts();

        PageReference pageRef = Page.GRAXRestore;
        Test.setCurrentPage(pageRef);

        Id accId;
        String accName;

        for(Account acc : [SELECT Id, Name, OwnerId FROM Account WHERE Name = 'TestAccount']) {
            accId = acc.Id;
            accName = acc.Name;
        }

        pageRef.getParameters().put('Id', String.valueOf(accId));

        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();

        pageRef.getParameters().put('selectedFields', 'Name');
        pageRef.getParameters().put('page', '0');
        pageRef.getParameters().put('sort', 'Name');
        pageRef.getParameters().put('sortOrder', 'asc');

        String responseData = '{"status":"success","extraInfo":{"total":1},"data":[{"Id":"' + String.valueOf(accId) + '","Name":"' + accName + '"}],"message":"queryBackup"}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', responseData, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        grc.isEmbeddedRelatedList = true;

        Test.startTest();
        grc.updateDataTable();
        Test.stopTest();

        System.assertEquals(true, grc.getIsFieldSelected());
        System.assertEquals(false, grc.getIsTableRecordsEmpty());

        for(Map<String, GRAXRestoreCtrl.KeyVal> kvMap : grc.objectMap.values()) {
            System.assertEquals(accId, kvMap.get('Id').val);
            System.assertEquals(accName, kvMap.get('Name').val);
        }
    }

    @isTest
    static void fieldsTest() {
        PageReference pageRef = Page.GRAXRestore;
        Test.setCurrentPage(pageRef);

        Test.startTest();

        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();
        
        pageRef.getParameters().put('objToQueryValue', 'Account');
        grc.changeObjToQuery();

        for(GRAXRestoreCtrl.Field f : grc.fieldMap.values()) {
            if(f.name.endsWith('Id') && !f.isCustom) {
                System.assertEquals(f.name.removeEnd('Id'), f.getCleanName());
            } else {
                System.assertEquals(f.name, f.getCleanName());
            }

            if(f.isNameField) {
                System.assertEquals(f.name == 'Attachment', f.getIsAttachmentLink());
                System.assertEquals(f.name == 'ContentVersion', f.getIsContentVersionLink());
            }

            if(f.name == 'CreatedDate') {
                System.assertEquals(true, f.getIsModalExluded());
            }

            if(f.name == 'Id') {
                System.assertEquals(true, f.getIsSortable());
            }
        }

        /*System.assertNotEquals('{}', grc.getFieldVsTypeJSON());

        grc.fieldMap = null;
        System.assertEquals('{}', grc.getFieldVsTypeJSON());*/

        Test.stopTest();
    }

    @isTest
    static void saveSObjectToRestoreTest() {
        PageReference pageRef = Page.GRAXRestore;
        Test.setCurrentPage(pageRef);

        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'GRAX_Schedule_Process__c';
        insert gsp;

        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();

        grc.objToQuery = 'GRAX_Schedule_Process__c';
        grc.updateSObjectFields('Account');
        grc.createSObject('Account', null);
        grc.createObjectMap(null, true);

        pageRef.getParameters().put('soToRestore', String.valueOf(gsp.Id));
        pageRef.getParameters().put('isReadOnlyMode', 'false');

        String responseData = '{"status":"success","data":[{"Object_Name__c":"GRAX_Schedule_Process__c"}],"message":"queryBackup"}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', responseData, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        grc.changeSObjectToRestore();

        System.assertNotEquals(null, grc.getisSobjectToRestoreSelected());

        pageRef.getParameters().put('GRAXRestore_Object_Name__c', 'GRAX_Data_Record__c');

        grc.saveSObjectToRestore();
        grc.saveHistory();
        Test.stopTest();

        //System.assertEquals(1, Database.countQuery('SELECT COUNT() FROM GRAX_Schedule_Process__c WHERE Object_Name__c = \'GRAX_Data_Record__c\''));
    }
    
    @isTest
    static void saveSObjectToRestoreTest2() {
        PageReference pageRef = Page.GRAXRestore;
        Test.setCurrentPage(pageRef);

        GRAX_Schedule_Process__c gsp = new GRAX_Schedule_Process__c();
        gsp.Object_Name__c = 'GRAX_Schedule_Process__c';
        insert gsp;

        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();

        grc.objToQuery = 'GRAX_Schedule_Process__c';
        grc.updateSObjectFields('Attachment');

        pageRef.getParameters().put('soToRestore', String.valueOf(gsp.Id));
        pageRef.getParameters().put('isReadOnlyMode', 'false');

        String responseData = '{"status":"success","data":[{"Object_Name__c":"GRAX_Schedule_Process__c"}],"message":"queryBackup"}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', responseData, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        grc.changeSObjectToRestore();

        System.assertNotEquals(null, grc.getisSobjectToRestoreSelected());

        pageRef.getParameters().put('GRAXRestore_Object_Name__c', 'GRAX_Data_Record__c');
        
        grc.saveSObjectToRestore();
        grc.restoreAttachments = true;
        grc.restoreAttachmentsCallout();
        
        Test.stopTest();

        //System.assertEquals(1, Database.countQuery('SELECT COUNT() FROM GRAX_Schedule_Process__c WHERE Object_Name__c = \'GRAX_Data_Record__c\''));
    }
    
    @isTest
    static void restoreSObjectTest() {
        PageReference pageRef = Page.GRAXRestore;
        Test.setCurrentPage(pageRef);
        
        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();
        
        pageRef.getParameters().put('recordId', '1');
        pageRef.getParameters().put('graxorgid', '00D4600000172yZ');
        
        String responseData = '{"status":"success","data":[{"Object_Name__c":"GRAX_Schedule_Process__c"}],"message":"queryBackup"}';
        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', responseData, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        Test.startTest();
        GRAXCloud.CallOutResponse response = GRAXRestoreCtrl.restoreSObject('Account', '1', '00D4600000172yZ');
        try {
            grc.restoreSObjectCallout();
        } catch (Exception e) {
            
        }
        grc.objToQuery = 'Account';
        grc.getExportToCsvUrl();
        grc.getElasticFieldsMapping();
        Test.stopTest();
        System.assertEquals(true, response <> null);
    }

    @isTest
    static void getItemsTest() {
        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();

        Test.startTest();

        System.assertNotEquals(Schema.getGlobalDescribe().size(), grc.getItems().size() - 1);

        Test.stopTest();        
    }

    @isTest
    static void changeIdToGetRelatedTest() {
        PageReference pageRef = Page.GRAXRestore;
        Test.setCurrentPage(pageRef);

        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();

        Test.startTest();

        pageRef.getParameters().put('idToGetRelated', 'test');
        grc.changeIdToGetRelated();

        System.assertEquals('test', grc.idToGetRelated);

        Test.stopTest();
    }

    @isTest
    static void getRelatedIframeUrlTest() {
        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();
        
        Test.startTest();

        System.assertEquals('javascript:void(0);', grc.getRelatedIframeUrl());

        grc.idToGetRelated = 'test';
        System.assertEquals('/apex/GRAXRestore?Id=test&isRR=1', grc.getRelatedIframeUrl());

        Test.stopTest();
    }

    @isTest
    static void previewAttachmentTest() {
        PageReference pageRef = Page.GRAXRestore;
        Test.setCurrentPage(pageRef);

        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();

        Test.startTest();

        pageRef.getParameters().put('graxorgid', 'test');
        pageRef.getParameters().put('objectType', 'test');
        pageRef.getParameters().put('recordId', 'test');
        pageRef.getParameters().put('name', 'test');
        pageRef.getParameters().put('mimeType', 'test');
        pageRef.getParameters().put('size', 'test');
        grc.previewAttachment();

        System.assertEquals('test', grc.previewAttGraxOrgId);
        System.assertEquals('test', grc.previewAttObjectType);
        System.assertEquals('test', grc.previewAttRecordId);
        System.assertEquals('test', grc.previewAttName);
        System.assertEquals('test', grc.previewAttMimeType);
        System.assertEquals('test', grc.previewAttSize);

        Test.stopTest();
    }

    @isTest
    public static void getRestoreItemsJSONTest() {
        GRAXRestoreCtrl grc = new GRAXRestoreCtrl();

        String retJSON = grc.getRestoreItemsJSON();

        System.assertNotEquals(null, retJSON);
        System.assertNotEquals('[]', retJSON);
    }
}
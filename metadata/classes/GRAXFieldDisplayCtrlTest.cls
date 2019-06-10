/***************************************************************************************
Name              : GRAXFieldDisplayCtrlTest
Description       : 
Revision History  : - 
Created/Modified by   Created/Modified Date     Requested by          Related Task/Issue             
----------------------------------------------------------------------------------------
1. Leandro Brunner 			07/30/2017          David Mackey        Display Archived Records (https://app.asana.com/0/326600806074978/749901377818173/f)
2. Ariel Yankelevich     	05/07/2019          David Mackey        Remove Reference to GRAX Query Object (https://app.asana.com/0/326600806074978/1121760476564626/f)
*****************************************************************************************/
@isTest
public with sharing class GRAXFieldDisplayCtrlTest {
    
    @isTest
    public static void GRAXFieldDisplayCtrlTest1() {
        String objName = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';
        String fieldName = GRAXUtils.getNameSpacePrefix() + 'Object_Name__c';
        String currentValue = GRAXUtils.getNameSpacePrefix() + 'GRAX_Schedule_Process__c';

        GRAXFieldDisplayCtrl gfdc = new GRAXFieldDisplayCtrl();
        gfdc.objName = objName;
        gfdc.fieldName = fieldName;
        gfdc.currentValue = currentValue;
        gfdc.isEdit = true;

        GRAXFieldDisplayCtrl.GRAXCustomFieldDisplay cSObj = gfdc.getcSObj();

        System.assertNotEquals(null, cSObj);
        System.assertEquals(objName, cSObj.sObjectName);
        System.assert(cSObj.cSObjectFields.containsKey(fieldName));
        System.assertEquals(currentValue, cSObj.cSObjectFields.get(fieldName).fValue);
    }

    @isTest
    public static void GRAXFieldDisplayCtrlTest2() {
        String objName = 'Account';
        String fieldName = 'AccountSource';
        String currentValue = 'Other';

        GRAXFieldDisplayCtrl gfdc = new GRAXFieldDisplayCtrl();
        gfdc.objName = objName;
        gfdc.fieldName = fieldName;
        gfdc.currentValue = currentValue;
        gfdc.isEdit = true;

        GRAXFieldDisplayCtrl.GRAXCustomFieldDisplay cSObj = gfdc.getcSObj();

        System.assertEquals(Account.getSObjectType(), cSObj.sObjectType);
    }

    @isTest
    public static void GRAXFieldDisplayCtrlTest3() {
        Account acc = new Account(Name = 'Test acc1', BillingCity = 'USA');
        insert acc;

        String objName = 'Asset';
        String fieldName = 'AccountId';
        String currentValue = acc.Id;

        GRAXFieldDisplayCtrl gfdc = new GRAXFieldDisplayCtrl();
        gfdc.objName = objName;
        gfdc.fieldName = fieldName;
        gfdc.currentValue = currentValue;
        gfdc.isEdit = true;

        GRAXFieldDisplayCtrl.GRAXCustomFieldDisplay cSObj = gfdc.getcSObj();

        System.assertEquals(Asset.getSObjectType(), cSObj.sObjectType);
    }

    @isTest
    public static void GRAXFieldDisplayCtrlTest4() {
        String objName = 'Account';
        String fieldName = 'CreatedDate';
        String currentValue = '';

        GRAXFieldDisplayCtrl gfdc = new GRAXFieldDisplayCtrl();
        gfdc.objName = objName;
        gfdc.fieldName = fieldName;
        gfdc.currentValue = currentValue;
        gfdc.isEdit = true;

        GRAXFieldDisplayCtrl.GRAXCustomFieldDisplay cSObj = gfdc.getcSObj();

        System.assertEquals(Account.getSObjectType(), cSObj.sObjectType);
    }

    @isTest
    public static void GRAXFieldDisplayCtrlTest5() {
        String objName = 'Asset';
        String fieldName = 'Description';
        String currentValue = 'test';

        GRAXFieldDisplayCtrl gfdc = new GRAXFieldDisplayCtrl();
        gfdc.objName = objName;
        gfdc.fieldName = fieldName;
        gfdc.currentValue = currentValue;
        gfdc.isEdit = true;

        GRAXFieldDisplayCtrl.GRAXCustomFieldDisplay cSObj = gfdc.getcSObj();

        System.assertEquals(Asset.getSObjectType(), cSObj.sObjectType);
    }

    @isTest
    public static void GRAXFieldDisplayCtrlTest6() {
        String objName = 'Asset';
        String fieldName = 'InstallDate';
        String currentValue = String.valueOf(Date.Today());

        GRAXFieldDisplayCtrl gfdc = new GRAXFieldDisplayCtrl();
        gfdc.objName = objName;
        gfdc.fieldName = fieldName;
        gfdc.currentValue = currentValue;
        gfdc.isEdit = true;

        GRAXFieldDisplayCtrl.GRAXCustomFieldDisplay cSObj = gfdc.getcSObj();

        System.assertEquals(Asset.getSObjectType(), cSObj.sObjectType);
    }

    @isTest
    public static void GRAXFieldDisplayCtrlTest7() {
    	Account acc = new Account(Name = 'Test acc1', BillingCity = 'USA');
        insert acc;
        
        Task varTask = new Task(WhatId = acc.Id, Subject = '');
        insert varTask;
        
        String objName = 'Task';
        String fieldName = 'WhatId';
        String currentValue = acc.Id;

        GRAXFieldDisplayCtrl gfdc = new GRAXFieldDisplayCtrl();
        gfdc.objName = objName;
        gfdc.fieldName = fieldName;
        gfdc.currentValue = currentValue;
        gfdc.isEdit = true;

        GRAXFieldDisplayCtrl.GRAXCustomFieldDisplay cSObj = gfdc.getcSObj();
	}
}
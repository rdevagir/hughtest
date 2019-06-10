@isTest
public with sharing class GRAXConnectUT {

   @isTest
    static void ConstructorTest() {
		GRAXSettings gxs = GRAXUnitTest.getSettings();
     	PageReference pageRef = Page.GRAXConnect;
    		Test.setCurrentPage(pageRef); 
     	GRAXConnect connect = new GRAXConnect();
     	connect.getPropURLToDisplay();
     	connect.connect();
    }
}
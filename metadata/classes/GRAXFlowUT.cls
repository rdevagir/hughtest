@isTest
public with sharing class GRAXFlowUT {

	@isTest
    static void ConstructorTest() {
		GRAXSettings gxs = GRAXUnitTest.getSettings();
     	PageReference pageRef = Page.GRAXFlow;
    		Test.setCurrentPage(pageRef); 
     	GRAXFlow flow = new GRAXFlow();
     	flow.getPropURLToDisplay();
     	flow.connect();
    }
}
@isTest
public class GRAXSummaryChartsCtrlTest {
    @isTest
    static void getIsAuthenticated_Test() {
		GRAXSettings gxs = GRAXUnitTest.getSettings();

		GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{"message": "Test successful", "token": "TestToken123445"}', null);

		GRAXSummaryChartsCtrl summaryCharts = new GRAXSummaryChartsCtrl();

		Test.startTest();

		Test.setMock(HttpCalloutMock.class, fakeResponse);
		Boolean isAuthenticated = summaryCharts.getIsAuthenticated();

		Test.stopTest();

		System.assertEquals(true, isAuthenticated);
	}
}
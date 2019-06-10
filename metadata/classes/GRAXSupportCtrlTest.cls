@isTest
public class GRAXSupportCtrlTest {
    @isTest
    public static void GRAXSupportCtrlTestConstructor() {
        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{}', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        GRAXSupportCtrl gsc = new GRAXSupportCtrl();
    }
}
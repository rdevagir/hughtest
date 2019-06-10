@isTest
public class GRAXAuditTrailTest {
    @isTest
    static void GetTimeMachineFileTest() {
        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', '{}', null);
        
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        Test.startTest();
        String retValue = GRAXAuditTrail.GetTimeMachine('User', '1', '', '', 1, 1, false, false);
        String fileContent = GRAXAuditTrail.GetTimeMachineFile('Account', '0011700000jOE03AAG', 'Test.json');

        Test.stopTest();
    }
}
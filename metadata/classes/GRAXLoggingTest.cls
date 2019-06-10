@isTest
public class GRAXLoggingTest {
    @isTest
    static void GRAXLoggingTest() {
        String logJSON = '{"Items":[{"logging-timestamp":{"S":"2018-08-16T09:25:10.875Z"},"organizationid":{"S":"00000000-0000-0000-0000-000000000000"},"request":{"S":"{\\\"error\\\":\\\"\\\"** DANGER : Basic Authentication is OFF !! ** \\\"\\\"}"},"error":{"S":"\\\"** DANGER : Basic Authentication is OFF !! ** \\\""}}],"Count":1,"ScannedCount":1,"LastEvaluatedKey":{"logging-timestamp":{"S":"2018-08-16T09:25:10.875Z"},"organizationid":{"S":"00000000-0000-0000-0000-000000000000"}}}';

        GRAXUnitTest.SingleRequestMock fakeResponse = new GRAXUnitTest.SingleRequestMock(200, 'OK', logJSON, null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        GRAXLogging.GetExceptions();
    }

    @isTest
    static void GRAXLogRecordTest() {
        GRAXLogRecord glr = new GRAXLogRecord();
        
        System.assertEquals(null, glr.source);
        System.assertEquals(null, glr.information);
    }
}
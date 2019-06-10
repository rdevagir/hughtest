@isTest
public class GRAXAccountTest implements HttpCalloutMock {
    private static HttpRequest request;
    private static HttpResponse response;

    public HTTPResponse respond(HTTPRequest req) {
        request = req;
        response = new HttpResponse();
        response.setStatusCode(200);
        return response;
    }

    @isTest static void testTrigger() {
        Test.setMock(HttpCalloutMock.class, new GRAXAccountTest());

        SObject o = GRAXApi.mock('Account');

        Test.startTest();
        insert o;
        update o;
        delete o;
        Test.stopTest();

        System.assertEquals(200, response.getStatusCode());
        System.assertEquals('', request.getEndpoint());

        if (request != null) {
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());
            System.assertNotEquals(null, jsonResponse.get('userId'));
        }
    }

}
public with sharing class Neo4jClient {

    private HttpRequest request;

    public Neo4jClient() {

        GRAXSettings__c settings = GRAXSettings__c.getOrgDefaults();

        String basicAuthentication = settings.Graph_DB_Username__c + ':' + settings.Graph_DB_Password__c;
        basicAuthentication = EncodingUtil.base64Encode(Blob.valueOf(basicAuthentication));

        request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        request.setHeader('Authorization', 'Basic ' + basicAuthentication);
        request.setEndpoint(settings.Graph_DB_URL__c + '/db/data/cypher');
    }

    public HttpResponse query(String data) {

        request.setBody(data);
        return send();
    }

    private HttpResponse send() {

        System.debug(request.getBody());
        return (new Http()).send(request);
    }

}
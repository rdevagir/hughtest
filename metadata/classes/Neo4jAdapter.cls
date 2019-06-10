public with sharing class Neo4jAdapter {

	private static final String ACCOUNT_QUERY = 'MATCH (n:Account) WHERE n.name="<<ACCOUNTNAME>>" RETURN ID(n), n';
	private static final String OPPORTUNITY_QUERY = 'MATCH (n:Opportunity) -[:Account]-> (a:Account) WHERE ID(a) IN [<<NODES>>] RETURN n';
	private static final String CONTACT_QUERY = 'MATCH (n:Contact) -[:Account]-> (a:Account) WHERE ID(a) IN [<<NODES>>] RETURN n';
	private static final String CASE_QUERY = 'MATCH (n:Case) -[:Account]-> (a:Account) WHERE ID(a) IN [<<NODES>>] RETURN n';

	public static Map<String, Object> getAccountsByName(String name) {

		Map<String, Object> result = new Map<String, Object>();

		Map<String, Object> data = new Map<String, Object>();
		data.put('query', (Object) ACCOUNT_QUERY.replace('<<ACCOUNTNAME>>', name));

		HttpResponse response = (new Neo4jClient()).query(JSON.serialize(data));

		if (response.getStatusCode() == 200) {
			result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
		}
		else {
			result.put('error', response.getBody());
		}

		return result;
	}

	public static Map<String, Object> getAccountOpportunities(String[] nodeIds) {

		Map<String, Object> result = new Map<String, Object>();

		Map<String, Object> data = new Map<String, Object>();
		data.put('query', (Object) OPPORTUNITY_QUERY.replace('<<NODES>>', String.join(nodeIds, ',')));

		HttpResponse response = (new Neo4jClient()).query(JSON.serialize(data));

		if (response.getStatusCode() == 200) {
			result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
		}
		else {
			result.put('error', response.getBody());
		}

		return result;
	}

	public static Map<String, Object> getAccountCases(String[] nodeIds) {

		Map<String, Object> result = new Map<String, Object>();

		Map<String, Object> data = new Map<String, Object>();
		data.put('query', (Object) CASE_QUERY.replace('<<NODES>>', String.join(nodeIds, ',')));

		HttpResponse response = (new Neo4jClient()).query(JSON.serialize(data));

		if (response.getStatusCode() == 200) {
			result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
		}
		else {
			result.put('error', response.getBody());
		}

		return result;
	}

	public static Map<String, Object> getAccountContacts(String[] nodeIds) {

		Map<String, Object> result = new Map<String, Object>();

		Map<String, Object> data = new Map<String, Object>();
		data.put('query', (Object) CONTACT_QUERY.replace('<<NODES>>', String.join(nodeIds, ',')));

		HttpResponse response = (new Neo4jClient()).query(JSON.serialize(data));

		if (response.getStatusCode() == 200) {
			result = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
			System.debug(JSON.serializePretty(result));
		}
		else {
			result.put('error', response.getBody());
		}

		return result;
	}

	private static String[] getLinkedOrganizations() {

		String[] result = new String[] {};

		Map<String, Grax_Linked_Organizations__c> linkedOrganizations = Grax_Linked_Organizations__c.getAll();

		for (Grax_Linked_Organizations__c linkedOrganization :linkedOrganizations.values()) {

			if (linkedOrganization.Organization_Id__c != null) {
				result.add(linkedOrganization.Organization_Id__c);
			}
		}

		return result;
	}

}
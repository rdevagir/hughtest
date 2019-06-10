public with sharing class GraxRemoteAccountController {

	@AuraEnabled
	public static Map<String, Object> getAccounts(Id accountId) {

		Account account = getAccount(accountId);

		Map<String, Object> result = null;

		if (account != null && account.Name != null) {

			result = Neo4jAdapter.getAccountsByName(account.Name);
		}

		return result;
	}

	@AuraEnabled
	public static GRAXSettings__c getMainSettings() {

		// return Grax_General_Settings__c.getOrgDefaults();
		return GRAXSettings__c.getOrgDefaults();
	}

	@AuraEnabled
	public static Map<Id, String> getLinkedOrganizations() {

		Map<Id, String> result = new Map<Id, String>();

		Map<String, Grax_Linked_Organizations__c> linkedOrganizations = Grax_Linked_Organizations__c.getAll();

		for (Grax_Linked_Organizations__c linkedOrganization :linkedOrganizations.values()) {

			if (linkedOrganization.Organization_Id__c != null) {
				result.put(linkedOrganization.Organization_Id__c, linkedOrganization.Name);
			}
		}

		return result;
	}

	@AuraEnabled
	public static Map<String, Object> getAccountOpportunities(String[] nodeIds) {
		Map<String, Object> result = Neo4jAdapter.getAccountOpportunities(nodeIds);
		System.debug(JSON.serializePretty(result));
		return result;
	}

	@AuraEnabled
	public static Map<String, Object> getAccountContacts(String[] nodeIds) {
		Map<String, Object> result = Neo4jAdapter.getAccountContacts(nodeIds);
		return result;
	}

	@AuraEnabled
	public static Map<String, Object> getAccountCases(String[] nodeIds) {
		Map<String, Object> result = Neo4jAdapter.getAccountCases(nodeIds);
		return result;
	}

	@AuraEnabled
	public static Map<String, Grax_Object_Mapping__c[]> getColumnLabels() {

		Map<String, Grax_Object_Mapping__c[]> result = new Map<String, Grax_Object_Mapping__c[]>();

		Grax_Object_Mapping__c[] labels = new Grax_Object_Mapping__c[] {};
		labels = [SELECT
						Api_Name__c,
						Label__c,
						Object__c,
						Order__c,
						Type__c
					FROM Grax_Object_Mapping__c
					ORDER BY Object__c, Order__c];

		for (Grax_Object_Mapping__c label :labels) {

			if (!result.containsKey(label.Object__c)) {
				result.put(label.Object__c, new Grax_Object_Mapping__c[] {});
			}

			// labeling with lowercase
			label.Api_Name__c = label.Api_Name__c.toLowerCase();
			result.get(label.Object__c).add(label);
		}

		return result;
	}

	private static Account getAccount(Id accountId) {

		Account[] result = new Account[] {};
		result = [SELECT Name FROM Account WHERE Id = :accountId];
		return result.isEmpty() ? null : result[0];
	}

}
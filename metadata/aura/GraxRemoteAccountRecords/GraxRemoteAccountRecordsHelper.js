({

	loadMainSettings : function(component, helper) {

		var action = component.get('c.getMainSettings');

		action.setCallback(this, function (response) {

			if (component.isValid() && response.getState() === 'SUCCESS') {

				if (response.getReturnValue()) {

					component.set('v.mainSettings', response.getReturnValue());
					console.log(response.getReturnValue());
				}
			}
			else {
				console.error(response);
			}
		});

		$A.enqueueAction(action);
	},

	loadLinkedOrganizations : function(component) {

		var action = component.get('c.getLinkedOrganizations');

		action.setCallback(this, function (response) {

			if (component.isValid() && response.getState() === 'SUCCESS') {

				var organization = response.getReturnValue();

				if (organization) {

					component.set('v.organizations', organization);
				}
			}
			else {
				console.error(response);
			}
		});

		$A.enqueueAction(action);
	},

	getGraphAccounts : function(component, helper) {

		var accountId = component.get('v.recordId') ? component.get('v.recordId') : '0011N00001Cj2RO';

		var action = component.get('c.getAccounts');
		action.setParams({
			accountId: accountId
		});

		action.setCallback(this, function (response) {

			if (component.isValid() && response.getState() === 'SUCCESS') {

				var accounts = response.getReturnValue();
				var nodeIds = [];

				for (var i = 0; i < accounts.data.length; i++) {
					var nodeId = accounts.data[i][0];
					nodeIds.push(nodeId.toString());
				}

				if (nodeIds && nodeIds.length > 0) {

					helper.getGraphOpportunities(component, nodeIds);
					helper.getGraphContacts(component, nodeIds);
					helper.getGraphCases(component, nodeIds);
				}

			}
			else {
				console.error(response);
			}
		});

		$A.enqueueAction(action);
	},

	getGraphOpportunities : function(component, nodeIds) {

		var action = component.get('c.getAccountOpportunities');
		action.setParams({
			nodeIds: nodeIds
		});

		action.setCallback(this, function (response) {

			if (component.isValid() && response.getState() === 'SUCCESS') {

				var responseValue = response.getReturnValue();

				if (responseValue.data) {

					var opportunityRecords = [];

					for (var i = 0; i < responseValue.data.length; i++) {

						var data = responseValue.data[i][0].data;

						if (component.get('v.mainSettings').Display_Organization_Name__c === true) {
							data.orgname = component.get('v.organizations')[data.sfdcorgid];
						}

						var key = Object.keys(data);
						var keys = Object.keys(data);
						var n = keys.length;

						var newobj = {};

						while (n--) {

							key = keys[n];
							newobj[key.toLowerCase()] = data[key];
						}

						opportunityRecords.push(data);
					}

					component.set('v.opportunityRecords', opportunityRecords);
				}
			}
			else {
				console.error(response);
			}
		});

		$A.enqueueAction(action);
	},

	getGraphContacts : function(component, nodeIds) {

		var action = component.get('c.getAccountContacts');
		action.setParams({
			nodeIds: nodeIds
		});

		action.setCallback(this, function (response) {

			if (component.isValid() && response.getState() === 'SUCCESS') {

				var responseValue = response.getReturnValue();

				if (responseValue.data) {

					var contactRecords = [];

					for (var i = 0; i < responseValue.data.length; i++) {

						var data = responseValue.data[i][0].data;

						if (component.get('v.mainSettings').Display_Organization_Name__c === true) {
							data.orgname = component.get('v.organizations')[data.sfdcorgid];
						}

						var key = Object.keys(data);
						var keys = Object.keys(data);
						var n = keys.length;

						var newobj = {};

						while (n--) {

							key = keys[n];
							newobj[key.toLowerCase()] = data[key];
						}

						contactRecords.push(newobj);
					}

					component.set('v.contactRecords', contactRecords);
				}
			}
			else {
				console.error(response);
			}
		});

		$A.enqueueAction(action);
	},

	getGraphCases : function(component, nodeIds) {

		var action = component.get('c.getAccountCases');
		action.setParams({
			nodeIds: nodeIds
		});

		action.setCallback(this, function (response) {

			if (component.isValid() && response.getState() === 'SUCCESS') {

				var responseValue = response.getReturnValue();

				if (responseValue.data) {

					var caseRecords = [];

					for (var i = 0; i < responseValue.data.length; i++) {

						var data = responseValue.data[i][0].data;

						if (component.get('v.mainSettings').Display_Organization_Name__c === true) {
							data.orgname = component.get('v.organizations')[data.sfdcorgid];
						}

						var key = Object.keys(data);
						var keys = Object.keys(data);
						var n = keys.length;

						var newobj = {};

						while (n--) {

							key = keys[n];
							newobj[key.toLowerCase()] = data[key];
						}

						caseRecords.push(data);
					}

					component.set('v.caseRecords', caseRecords);

					console.log(component.get('v.organizations'));
					console.log(caseRecords);
				}
			}
			else {
				console.error(response);
			}
		});

		$A.enqueueAction(action);
	},

	loadLabels: function(component) {

		var action = component.get('c.getColumnLabels');

		action.setCallback(this, function (response) {

			if (component.isValid() && response.getState() === 'SUCCESS') {

				var responseValue = response.getReturnValue();

				if (responseValue.Contact) {

					var contactLabels = [];

					for (var i = 0; i < responseValue.Contact.length; i++) {
						contactLabels.push({
							label: responseValue.Contact[i].Label__c,
							fieldName: responseValue.Contact[i].Api_Name__c,
							type: responseValue.Contact[i].Type__c,
						});
					}

					if (component.get('v.mainSettings').Display_Organization_Name__c === true) {
						contactLabels.push({label: "Organization Name", fieldName: "orgname", type: "text"});
					}

					component.set('v.contactLabels', contactLabels);
				}

				if (responseValue.Case) {

					var caseLabels = [];

					for (var i = 0; i < responseValue.Case.length; i++) {
						caseLabels.push({
							label: responseValue.Case[i].Label__c,
							fieldName: responseValue.Case[i].Api_Name__c,
							type: responseValue.Case[i].Type__c,
						});
					}

					if (component.get('v.mainSettings').Display_Organization_Name__c === true) {
						caseLabels.push({label: "Organization Name", fieldName: "orgname", type: "text"});
					}

					component.set('v.caseLabels', caseLabels);
				}

				if (responseValue.Opportunity) {

					var opportunityLabels = [];

					for (var i = 0; i < responseValue.Opportunity.length; i++) {
						opportunityLabels.push({
							label: responseValue.Opportunity[i].Label__c,
							fieldName: responseValue.Opportunity[i].Api_Name__c,
							type: responseValue.Opportunity[i].Type__c,
						});
					}

					if (component.get('v.mainSettings').Display_Organization_Name__c === true) {
						opportunityLabels.push({label: "Organization Name", fieldName: "orgname", type: "text"});
					}

					component.set('v.opportunityLabels', opportunityLabels);
				}

			}
			else {
				console.error(response);
			}
		});

		$A.enqueueAction(action);

	}
})
({

	onInit : function(component, event, helper) {

		console.log('init loaded');

		helper.loadMainSettings(component, helper);
		helper.loadLabels(component);		
		helper.loadLinkedOrganizations(component);

		helper.getGraphAccounts(component, helper);
	},

})
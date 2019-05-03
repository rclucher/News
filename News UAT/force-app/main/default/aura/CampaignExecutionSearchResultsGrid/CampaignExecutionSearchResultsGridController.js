({
	doInit : function(component, event, helper) {
		console.log('CampaignExecutionSearchResultsGridController :: doInit');
		helper.checkColumnsVisibility(component);		
	},
	openCampaignMemberSubTab: function (component, event, helper) {
		helper.openCampaignMemberSubTab(component, event, helper);
	},
	openContactLeadSubTab: function (component, event, helper) {
		helper.openContactLeadSubTab(component, event, helper);
	}
})
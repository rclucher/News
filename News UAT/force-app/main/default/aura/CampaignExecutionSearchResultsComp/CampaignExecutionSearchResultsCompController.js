({
	doInit : function(component, event, helper) {
		console.log('CampaignExecutionSearchResultsCompController :: doInit');
		
		helper.initSearchResults(component);		
	},
	onChooseClassification : function(component, event, helper) {

		//helper.resetDeliverabilityCheck(component);
		helper.onChooseClassification(component);
	}
})
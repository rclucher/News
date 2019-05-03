({
	doInit : function(component, event, helper) {
		console.log('CampaignExecutionCompController :: doInit');		
		helper.initCampaignExecution(component);
		document.title = "Campaign Execution";		
        // sforce.console.setTabTitle('Campaign Execution');
		// helper.setFocusedTabTitle(component, event, helper);
	},
	onSearch : function(component, event, helper) {
		helper.onSearch(component, event);
	},
	onResetSearch : function(component, event, helper) {
		helper.onResetSearch(component, event);
	},
	onClose : function(component, event, helper) {
		//helper.onClose(component, event);
	},
})
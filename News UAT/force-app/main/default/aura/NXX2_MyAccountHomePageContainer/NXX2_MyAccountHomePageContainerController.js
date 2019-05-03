({
	openAccountRelatedCustomerActivity : function(component, event, helper) {
		
		var parentRecordId = event.getParam('parentRecordId');
		//alert('tesgting....' + parentRecordId);
		/**
         * Calling Aura:Method mentioned in NXX2_GoogleDriveFileViewer Results Component
         */
        var customerActivitiesListViewComponent = component.find("customerActivitiesListView");
        var auraMethodResult = customerActivitiesListViewComponent.loadCustomerActivities(parentRecordId);
        console.log("auraMethodResult: " + auraMethodResult);
	}
})
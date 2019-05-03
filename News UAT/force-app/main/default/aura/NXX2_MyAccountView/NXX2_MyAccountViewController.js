({
	loadTasks : function(component, event, helper) {
	    /**
        * Pass the Account Id to the event, and load the tasks.
		*/
       
		var loadRelatedCustomerActivity = component.getEvent("loadRelatedCustomerActivity");
         loadRelatedCustomerActivity.setParams({
            "parentRecordId" : component.get("v.account.id"),
         });
		loadRelatedCustomerActivity.fire();

	},
	redirectToAccountPage : function(component, event, helper){
		var navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({
			"recordId": component.get("v.account.Id")
			});
		navEvt.fire();
		
	}
	
})
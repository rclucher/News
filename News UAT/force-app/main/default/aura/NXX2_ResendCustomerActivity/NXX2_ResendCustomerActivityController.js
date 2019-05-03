({
	cancel : function(component, event, helper) {
		var dismissActionPanel = $A.get("e.force:closeQuickAction");
        dismissActionPanel.fire();
	},
    save : function(component, event, helper) {
		var action = component.get("c.resendMailForActivity");
        action.setParams({
            activityId : component.get("v.recordId")
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Activity Send",
                    "message": "This Activity has been send to customer."
                });
                $A.get("e.force:closeQuickAction").fire();
                resultsToast.fire();
                $A.get("e.force:refreshView").fire();
            }else{
                var errors = actionResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        var resultsToast = $A.get("e.force:showToast");
                        resultsToast.setParams({
                            "title": "Server side error",
                            "message": errors[0].message
                        });
                        $A.get("e.force:closeQuickAction").fire();
                        resultsToast.fire();
                    }
                }
            }
        });
        $A.enqueueAction(action);
	}
})
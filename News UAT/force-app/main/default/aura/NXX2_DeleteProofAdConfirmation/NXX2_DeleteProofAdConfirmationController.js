({
	deleteAd : function(component, event, helper) {
        component.set('v.displaySpinner',true);
		var action = component.get("c.markAdAsDeleted"); 
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            component.set('v.displaySpinner',false);
            if(state == 'SUCCESS') {
                component.find('notifLib').showNotice({
                    "variant": "success",
                    "header": "Operation successful!",
                    "message": "Ad has been deleted successfully.",
                    "closeCallback": function() {
                        var appEvent = $A.get("e.c:NXX2_CloseModal");
        				appEvent.fire();
                    }
                });
                var appEvent = $A.get("e.c:NXX2_AdHasBeenUpdated");
                appEvent.fire();
            }else{
                var errors = actionResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Operation failed!",
                            "message": errors[0].message,
                            "closeCallback": function() {
                                component.find("overlayLib").notifyClose();
                            }
                        });
                    }
                }
            }
        });
        $A.enqueueAction(action);
	},
    cancelAd : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
	}
})
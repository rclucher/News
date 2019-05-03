({
    approve : function(component, event, helper) {
        //var appEvent = $A.get("e.c:NXX2_CloseFeedbackForm");
        //appEvent.fire();
        var action = component.get("c.updateProofStatus");
        action.setParams({
            proofId : component.get("v.recordId"),
            proofStatus : 'In Review',
            comments : component.get("v.comments")
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                component.find('overlayLib').showCustomModal({
                    body: "Thank you for submitting your request. View Account Proofs.",
                    showCloseButton: true,
                    closeCallback: function() {
                        location.reload();
                    }
                });
            }else{
                var errors = actionResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Operation failed!",
                            "message": errors[0].message
                        });
                    }
                }
            }
            component.find("overlayLib").notifyClose();
        });
        $A.enqueueAction(action);
    },
    cancel : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    }
})
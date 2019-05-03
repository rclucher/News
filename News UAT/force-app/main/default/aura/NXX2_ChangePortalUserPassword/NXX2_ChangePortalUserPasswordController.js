({
    matchPassword : function(component, event, helper) {
        var inputCmp = component.find("reEnterNewPasswordField");
        var value = inputCmp.get("v.value");
        if (value !== component.get("v.newPassword")) {
            inputCmp.setCustomValidity("Password doesn't match!");
        } else {
            inputCmp.setCustomValidity("");
        }
        inputCmp.reportValidity();
    },
    handleCancel : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    },
    handleSubmit : function(component, event, helper) {
        var action = component.get("c.changePortalUserPassword"); 
        action.setParams({
            oldPassword : component.get("v.oldPassword"),
            newPassword : component.get("v.newPassword")
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                component.find('notifLib').showNotice({
                    "variant": "info",
                    "header": "Operation Successful!",
                    "message": "Password has been changed successfully!"
                });
                component.find("overlayLib").notifyClose();
            }else{
                var errors = actionResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Error Occured!!",
                            "message": errors[0].message
                        });
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }
})
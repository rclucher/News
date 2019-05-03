({
	handleClodeModal : function(component, event, helper) {
		component.get('v.overlay').close();
	},
    refreshComp : function(component, event, helper) {
        component.find('socialProofLoader').reloadRecord(true)
    },
    requestChange: function(component, event, helper) {
        var modalBody;
        $A.createComponent("c:NXX2_FeedbackFormForRequestChange", {recordId : component.get("v.recordId")},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Anything else you would like to share/add?",
                                       body: modalBody, 
                                       showCloseButton: true
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });
    },
    approve : function(component, event, helper) {
        var action = component.get("c.updateProofStatus");
        action.setParams({
            proofId : component.get("v.recordId"),
            proofStatus : 'Approved',
            comments : ''
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                component.find('overlayLib').showCustomModal({
                    body: "Thank you for approving. View Account Proofs",
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
        });
        $A.enqueueAction(action);
    }
})
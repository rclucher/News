({
	doInit : function(component, event, helper) {
        var allPromises = [];
        allPromises.push(helper.getUserDetails(component));
        Promise.all(allPromises).then($A.getCallback(function(results){
			helper.populateAllAds(component,helper);
        }),$A.getCallback(function(ErrorMessage){
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Unable to get logged in user details!",
                "message": ErrorMessage
            });
        }));
	},
    viewLink : function(component, event, helper){
        var link = event.target.dataset.link;
        window.open(link);
    },
    handleClodeModal : function(component, event, helper) {
		if(!$A.util.isUndefined(component.get('v.overlay')) && component.get('v.overlay') !== null){
			component.get('v.overlay').close();
        }
	},
    deleteDisplayAd : function(component, event, helper) {
		var index = event.currentTarget.dataset.adindex;
        var allAds = component.get('v.allAds');
        var action = component.get("c.markAdAsDeleted"); 
        action.setParams({
            recordId: allAds[index].Id
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                allAds.splice(index,1);
                component.set('v.allAds',allAds);
                component.find('notifLib').showNotice({
                    "variant": "success",
                    "header": "Operation successful!",
                    "message": "Ad has been deleted successfully.",
                    "closeCallback": function() {
                        var appEvent = $A.get("e.c:NXX2_CloseModal");
        				appEvent.fire();
                    }
                });
            }else{
                var errors = actionResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Operation failed!",
                            "message": errors[0].message,
                            "closeCallback": function() {
                                var appEvent = $A.get("e.c:NXX2_CloseModal");
                                appEvent.fire();
                            }
                        });
                    }
                }
            }
        });
        $A.enqueueAction(action);
	},
    editAd : function(component, event, helper) {
		var index = event.currentTarget.dataset.adindex;
        var allAds = component.get('v.allAds');
        var modalBody;
        $A.createComponent("c:NXX2_CreateEditDisplayAd", {adDetails : allAds[index],campaignId : component.get('v.recordId')},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Edit Facebook Ad",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       cssClass: "custom-modal-for-social-ad"
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });
	},
    createAd : function(component, event, helper) {
        var allAds = component.get('v.allAds');
        var modalBody;
        var proof  = component.get('v.proof');
        var proofDetails = {};
        if(proof !== null){
            proofDetails = {'Start_Date__c' : proof.Campaign_Start_Date__c,'End_Date__c' : proof.Campaign_End_Date__c};
        }
        $A.createComponent("c:NXX2_CreateEditDisplayAd", {campaignId : component.get('v.recordId'),proofDetails : proofDetails},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Create Facebook Ad",
                                       body: modalBody, 
                                       showCloseButton: true,
                                       cssClass: "custom-modal-for-social-ad"
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });
	}
})
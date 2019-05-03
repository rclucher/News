({
    doInit : function(component, event, helper) {
        var proofDetails = component.get('v.proofDetails');
    },
    cancelAd : function(component, event, helper) {
        var appEvent = $A.get("e.c:NXX2_CloseModal");
        appEvent.fire();
    },
    saveAd : function(component, event, helper) {
        var allValid = component.find('field').checkValidity();
        if (allValid) {
            var requestMessage = 'Creating Ad...';
            var adDetails = component.get('v.adDetails');
            var adDetailsObject = {
                Start_Date__c : adDetails.Start_Date__c,
                End_Date__c : adDetails.End_Date__c,
                Display_Ad_Link__c : adDetails.Display_Ad_Link__c,
                Social_Campaign__c : component.get('v.campaignId')
            };
            if(!$A.util.isUndefined(adDetails.Id)){
                adDetailsObject.Id = adDetails.Id;
                requestMessage = 'Updating Ad...';
            }
            component.set('v.requestMessage',requestMessage);
            component.set('v.processingRequest',true);
            var action = component.get("c.saveAdDetails"); 
            action.setParams({
                adDetails: adDetailsObject,
                recordType: 'Display Ad'
            });
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                component.set('v.processingRequest',false);
                if(state == 'SUCCESS') {
                    adDetails.Id = actionResult.getReturnValue().Id;
                    component.set('v.adDetails',adDetails);
                    component.find('notifLib').showNotice({
                        "variant": "success",
                        "header": "Operation successful!",
                        "message": "Display Ad has been saved successfully.",
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
                                "message": ErrorMessage,
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
        }
    }
})
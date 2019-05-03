({
    updateProofRecordTypeId : function(component,productOrderId) {
        component.set("v.displaySpinner",true);
        var action = component.get("c.getProductOrder"); 
        action.setParams({
            recordId: productOrderId
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                var productOrder = actionResult.getReturnValue();
                var action = component.get("c.getProofRecordTypeId"); 
                action.setParams({
                    recordType: productOrder.Fulfillment_Type__c
                });
                action.setCallback(this, function(actionResult) {
                    var state = actionResult.getState();
                    if(state == 'SUCCESS') {
                        component.set('v.recordTypeId',actionResult.getReturnValue());
                        component.set("v.displaySpinner",false);
                    }else{
                        component.set("v.displaySpinner",false);
                    }
                });
                $A.enqueueAction(action);
            }else{
                component.set("v.displaySpinner",false);
            }
        });
        $A.enqueueAction(action);
    },
    navigateBack : function(cmp) {
		var navService = cmp.find("navService");
        var pageReference = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'SocialCampaign__c',
                actionName: 'list'
            },
            state: {
                filterName: "Recent"
            }
        };
        navService.navigate(pageReference,true);
	}
})
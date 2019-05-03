({
	populateCommentsToTypeMap : function(component) {
        return new Promise(function(resolve, reject) {
        	var action = component.get("c.getAllCommentsLinkedToType");
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if(state == 'SUCCESS') {
                    component.set('v.mapOfTypeAndComments', actionResult.getReturnValue());
                    resolve.call(this, actionResult.getReturnValue());
                }else{
                    var errors = actionResult.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            reject.call(this, errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action); 
        });
	},
    updateActivityRecordTypeId : function(component) {
        return new Promise(function(resolve, reject) {
            var action = component.get("c.getCustomerTaskRecordType");
            action.setParams({
                recordId: component.get("v.recordId")
            });
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if(state == 'SUCCESS') {
                    var response = actionResult.getReturnValue();
                    component.set('v.recordTypeId',response[1]);
                    if(response[0] == 'Order__c'){
                        component.find('campaignOrderLookup').set('v.value', component.get("v.recordId"));
                    }else{
                        component.find('productOrderLookup').set('v.value', component.get("v.recordId"));
                    }
                    resolve.call(this, actionResult.getReturnValue());
                }else{
                    var errors = actionResult.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            reject.call(this, errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action); 
        });
    }
})
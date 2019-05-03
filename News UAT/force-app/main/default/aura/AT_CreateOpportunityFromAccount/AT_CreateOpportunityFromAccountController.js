({
	doInit: function(component, event, helper) {
		var getRecordTypes = component.get('c.getRecordTypes');
        
        getRecordTypes.setParams({
            objectName: component.get('v.objectName')
        });
        
        getRecordTypes.setCallback(this, function(response) {
            var state = response.getState();

            if (state === 'SUCCESS') {
                var data = response.getReturnValue();
                
                component.set('v.recordTypes', data);
                
                if (data.length == 1) {
                    component.set('v.recordTypeId', data[0].id);
                    
                    helper.newOpportunity(component, helper);
                } else {
                    for (var i = 0; i < data.length; i++) {
                        if (data[i].isDefault) {
                            component.set('v.recordTypeId', data[i].id);
                        }
                    }
                }
            } else if (state === 'INCOMPLETE') {
                console.log('Incomplete: ' + response);
            } else if (state === 'ERROR') {
                console.log('Error: ' + response);
            }
        });
        
        $A.enqueueAction(getRecordTypes);
	},
    selectRecordType: function(component, event, helper) {
        component.set("v.recordTypeId", event.getSource().get("v.value"));
    },
    cancel: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
	},
    next: function(component, event, helper) {
        helper.newOpportunity(component, event);
    }
})
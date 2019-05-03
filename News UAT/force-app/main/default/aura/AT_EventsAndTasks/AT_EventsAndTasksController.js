({
	doInit: function(component, event, helper) {
		var action = component.get('c.getEventsAndTasks');
            
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state == 'SUCCESS') {
                var et = response.getReturnValue();
                
                console.log('Events and tasks:');
                console.log(et);
                
                component.set('v.eventsTasks', et);
                
            }
        });
        
        $A.enqueueAction(action);
	},
    viewCalendar: function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "#/sObject/Event/home"
        });
        urlEvent.fire();
    }
})
({
    display : function(component, event, helper) {
        helper.toggleHelper(component, event);
    },
    
    displayOut : function(component, event, helper) {
        helper.toggleHelper(component, event);
    },
    stopEvent : function(component, event, helper) {
        event.stopPropagation();
    } 
})
({
	handleSubmit : function(component, event, helper) {
        component.set("v.displaySpinner",true);
    },
    cancel : function(component, event, helper) {
        component.set("v.editing",false);
    },
    handleSuccess : function(component, event, helper) {
        component.set("v.displaySpinner",false);
        component.set("v.editing",false);
    },
    edit : function(component, event, helper) {
        component.set("v.editing",true);
    }
})
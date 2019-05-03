({
    save : function(component, event, helper) {
        component.find("edit").get("e.recordSave").fire();
        component.set("v.displaySpinner",true);
    },
    cancel : function(component, event, helper) {
        component.set("v.editing",false);
    },
    refreshComp : function(component, event, helper) {
        helper.initialize(component);
    },
    saved : function(component, event, helper) {
        component.set("v.displaySpinner",false);
        component.set("v.editing",false);
        var appEvent = $A.get("e.c:NXX2_AdHasBeenUpdated");
        appEvent.fire();
    },
    handleError1 : function(component, event, helper) {
        component.set("v.displaySpinner",false);
    },
    edit : function(component, event, helper) {
        component.set("v.editing",true);
    }
})
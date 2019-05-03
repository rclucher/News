({
    save : function(component, event, helper) {
        component.find("edit").get("e.recordSave").fire();
        component.set("v.displaySpinner",true);
    },
    cancel : function(component, event, helper) {
        component.find("overlayLib").notifyClose();
    },
    saved : function(component, event, helper) {
        component.set("v.displaySpinner",false);
        component.set("v.editing",false);
        var appEvent = $A.get("e.c:NXX2_CustomerActivityUpdated");
        appEvent.fire();
    },
    handleError1 : function(component, event, helper) {
        component.set("v.displaySpinner",false);
    }
})
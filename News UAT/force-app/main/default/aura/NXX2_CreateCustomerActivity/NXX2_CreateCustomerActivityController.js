({
    doInit : function(component, event, helper) {
        component.set("v.displaySpinner",true);
        var allPromises = [];
        allPromises.push(helper.populateCommentsToTypeMap(component));
        allPromises.push(helper.updateActivityRecordTypeId(component));
        Promise.all(allPromises).then($A.getCallback(function(results){
            component.set("v.displaySpinner",false);
        }),$A.getCallback(function(ErrorMessage){
            component.set("v.displaySpinner",false);
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Initialization Failed!",
                "message": ErrorMessage,
                "closeCallback": function() {
        			$A.get("e.force:closeQuickAction").fire();
                }
            });
        }));
    },
    getComments : function (component, event, helper){
        var type=component.find('type').get("v.value");
        var typeCommentsmap = component.get("v.mapOfTypeAndComments");
        var value;
        component.find("comments").set("v.value", '');
        if(typeCommentsmap!=undefined){
            Object.keys(typeCommentsmap).forEach(function(key) {
                value = typeCommentsmap[key];
                if(key==type){
                    component.find("comments").set("v.value", value);                
                }
            });
        }
    },
    closeModal  : function(component, event, helper) {
        component.set("v.displaySpinner",false);
        $A.get("e.force:closeQuickAction").fire();
    },
    handleSuccess  : function(component, event, helper) {
        var payload = event.getParams().response;
        var navService = component.find("navService");
        var pageReference = {
            type: "standard__recordPage",
            attributes: {
                recordId: payload.id,
                objectApiName: "Customer_Task__c",
                actionName: "view"
            }
        };
        navService.navigate(pageReference,true);
    },
    handleLoad  : function(component, event, helper) {
        component.set("v.displaySpinner",false);
    },
    handleError  : function(component, event, helper) {
        component.set("v.displaySpinner",false);
    },
    handleSubmit  : function(component, event, helper) {
        component.set("v.displaySpinner",true);
    }
})
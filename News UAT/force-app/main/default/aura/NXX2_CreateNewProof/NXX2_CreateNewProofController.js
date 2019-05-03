({
    doInit : function(component, event, helper) {
        if(!component.get("v.displayInModal")){
            helper.updateProofRecordTypeId(component,component.get("v.recordId"));
            component.set("v.disabled",true);
        }
    },
    closeModal  : function(component, event, helper) {
        /*component.set("v.displaySpinner",false);
        if(component.get("v.displayInModal")){
            component.find("overlayLib").notifyClose();
        }else{
            $A.get("e.force:closeQuickAction").fire();
        }*/
        //location.reload();
        var navService = component.find("navService");
        var pageReference = {
            type: "standard__recordRelationshipPage",
            attributes: {
                recordId: component.get("v.recordId"),
                objectApiName: "Product_Order__c",
                relationshipApiName: "Social_Campaigns__r",
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
        if(component.get("v.displayInModal")){
            helper.navigateBack(component);
        }
    },
    onPOChange  : function(component, event, helper) {
        var productOrderId = event.getParam('value');
        if(productOrderId !== null && productOrderId.length > 0){
            helper.updateProofRecordTypeId(component,productOrderId[0]);
        }
    }
})
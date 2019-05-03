({
    handleFbAdDetailsChangedEvent : function(component, event, helper) {
        component.set("v.adDetails",event.getParam("adDetails"));
        var childComponent = component.find("previewComp");
        if(childComponent !== undefined){
            childComponent.updateAdDetails(event.getParam("adDetails"));
        }
    },
    handleInitialiseFileUploadEvent : function(component, event, helper) {
        var files = event.getParam("files");
        var recordId = event.getParam("recordId");
        var childComponent = component.find("fileUploader");
        if(childComponent !== undefined){
            childComponent.UploadFiles(files,recordId);
        }
    },
    handleRequestingServerEvent : function(component, event, helper) {
        component.set("v.requestMessage",event.getParam("requestMessage"));
        component.set("v.processingRequest",true);
    },
    handleServerRespondedEvent : function(component, event, helper) {
        component.set("v.processingRequest",false);
    },
    cancelAd : function(component, event, helper) {
        var appEvent = $A.get("e.c:NXX2_CloseModal");
        appEvent.fire();
    },
    createNewVersion : function(component, event, helper) {
        component.set('v.createNewVersion',true);
    },
    test : function(component, event, helper){
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/view-fb-ad?campaignId=Test'
        });
        urlEvent.fire();
    }
})
({
    doInit : function(component, event, helper) {
        helper.showProcessing(component);
        var mimeType=component.get("v.filePreview.mimeType");
        if(mimeType.indexOf('image')!=-1){
             component.set("v.isVideo", 'false');          
        }else{
            component.set("v.isVideo", 'true');  
        }
    }, 
    hideFileViewerModal : function(component, event, helper) {
        helper.hideModal(component);
    },
    
    showFileViewerModal : function(component, event, helper) {
        helper.showExampleModal(component);
    },
    openFileViewer : function(component, event, helper) {
        var params = event.getParam('arguments');
        console.log("File: " + params.file);
        component.set("v.filePreview", params.file);
        var mimeType=component.get("v.filePreview.mimeType");
        if(mimeType.indexOf('image')!=-1){
             component.set("v.isVideo", 'false');          
        }else{
            component.set("v.isVideo", 'true');  
        }
        helper.showModal(component);
        helper.showProcessing(component);
        return "search complete.";
    },
    handleFileOnLoad : function(component, event, helper) { 
       helper.hideProcessing(component);
    } 
})
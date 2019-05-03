({
    doInit : function(component, event, helper) { 
        var recordId = component.get("v.recordId");
        helper.getProofNumber(component, event, helper);       
    },
    onFilePreview : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var fileTitle = event.getParam("fileTitle");
        var isModelToClose = event.getParam("closeFileViewer");
        var previewUrl = event.getParam("previewUrl");
        var file = event.getParam("file");
        /**
         * Calling Aura:Method mentioned in NXX2_GoogleDriveFileViewer Results Component
         */
        var googleDriveFileViewerComponent = component.find("googleDriveFileViewer");
        console.log("File Information" + file);
        var auraMethodResult = googleDriveFileViewerComponent.openFileViewer(file,isModelToClose);
        console.log("auraMethodResult: " + auraMethodResult);
        
    },
    /*
    handleFilesChange: function(component, event, helper) {
        var fileName = 'No File Selected..';
        if (event.getSource().get("v.files").length > 0) {
            fileName = event.getSource().get("v.files")[0]['name'];
        }
        component.set("v.fileName", fileName);
    },*/
    onFileDelete : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var fileId = event.getParam("fileId");
        var fileName = event.getParam("fileName");
        component.set("v.fileIdToBeDeleted",fileId);
        component.set("v.fileNameToBeDeleted",fileName);
        helper.showModal(component,fileName);
       // helper.deleteFile(component,event,fileId,recordId);
    },
    cancleFileDeleteOperation: function(component, event, helper) {
        helper.hideModal(component);
    },
    confirmFileDeleteOperation : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        var fileId = component.get("v.fileIdToBeDeleted");
        helper.deleteFile(component,event,fileId,recordId);
    },
    
    UploadFileInGoogleDrive: function(component, event, helper) {
      helper.uploadHelper(component, event);
    },
    onFileUpload : function(component, event, helper) {
      //alert('File Uploaded...Hurray');
      helper.handleFileUpload(component, event);
    },
    showOrHideUploadSpinner: function(component, event, helper) {
        component.set("v.fileUploadSpinner", event.getParam("showProcessingImage"));
       // component.set("v.fileUploadSpinner", true); 
    },
    
    hideUploadSpinner : function(component,event,helper){
        component.set("v.fileUploadSpinner", false);
    },
    
})
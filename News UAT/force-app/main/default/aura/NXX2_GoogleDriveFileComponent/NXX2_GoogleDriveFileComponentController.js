({
	handleFileDownLoadOperation : function(component, event, helper) {
        helper.downloadFile(component);
	},
 
    handleFilePreview : function(component, event, helper) {
        //alert(component.get("v.files.id"));
       /*
        var action = component.get("c.downloadFile");
        var fileId = component.get("v.files.id");
        var downloadURL = component.get("v.files.downloadUrl");
        action.setParams({
            fileId: fileId,
        });
        action.setCallback(this, function(a) {
           // console.log(a.getReturnValue());
            var fileContent = a.getReturnValue();
            var url  = window.URL.createObjectURL(new Blob([fileContent], {type: component.get("v.files.mimeType")})); 
            console.log(url)
            
         });
        $A.enqueueAction(action);
        
        */ 
       /* var file = component.get("v.files");
        //Call Event to inform main component to open file preview
        var fileViewerEvent = component.getEvent("googleDriveFileViewerEvent");
         fileViewerEvent.setParams({
            "fileTitle" : component.get("v.files.title"),
            "closeFileViewer": "true",
            "previewUrl":component.get("v.files.downloadUrl"),
            "file":component.get("v.files")
         });
        fileViewerEvent.fire();
        
        */
       
        var modalBody;
        $A.createComponent("c:NXX2_GoogleDriveFileViewer", {filePreview : component.get("v.files")},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: component.get("v.files").title,
                                       body: modalBody, 
                                       showCloseButton: true,
                                       cssClass: "custom-modal-for-social-ad"
                                   }).then(function (overlay) {
                                       component.set('v.overlay',overlay);
                                   });
                               }                               
                           });

	},
    handleFileDeleteOperation : function(component, event, helper) {
        var file = component.get("v.files");
        //Call Event to inform main component to delete file preview
        var fileDeleteEvent = component.getEvent("googleDriveFileDeleteEvent");
         fileDeleteEvent.setParams({
            "fileId" : component.get("v.files.id"),
            "fileName" : component.get("v.files.title")
         });
		fileDeleteEvent.fire();
    } 
})
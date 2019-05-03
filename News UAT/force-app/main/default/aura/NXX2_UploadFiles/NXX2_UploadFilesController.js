({
	uploadFiles : function(component, event, helper) {
        var files = event.getParam("arguments").files;
        var recordId = event.getParam("arguments").recordId;
        if(files.length !== 0 && !$A.util.isUndefined(recordId) && recordId !== ''){
        	component.set("v.filesUploadStatus",[]);
            component.set('v.totalFiles',files.length);
            component.set('v.uploading',true);
        	helper.startUpload(component,helper,files,recordId,0);
        }else{
            var appEvent = $A.get("e.c:NXX2_FileUploadCompleted");
            appEvent.setParams({ "filesUploadStatus" : component.get('v.filesUploadStatus')});
            appEvent.fire();
        }
	}
})
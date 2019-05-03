({
	populateAdDetails : function(component,helper) {
        return new Promise(function(resolve, reject) {
            var action = component.get("c.getAdDetails"); 
            action.setParams({
                socialAdRecordId : component.get("v.recordId")
            });
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if(state == 'SUCCESS') {
                    var rawData = actionResult.getReturnValue();
                    var adDetails = rawData.socialAd;
                    adDetails.uploadedFiles = rawData.contents;
                    component.set('v.adDetails', adDetails);
                    resolve.call(this, actionResult.getReturnValue());
                }else{
                    var errors = actionResult.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            reject.call(this, errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action); 
        });
	},
    saveFiles : function(component,adDetails) {
        var files = [];
        for(var i = 0;i < adDetails.uploadedFiles.length; i++){
            if($A.util.isUndefined(adDetails.uploadedFiles[i].GoogleDriveFileId) || adDetails.uploadedFiles[i].GoogleDriveFileId == ''){
                files.push(adDetails.uploadedFiles[i]);
            }
        }
        var childComponent = component.find("fileUploader");
        if(childComponent !== undefined){
            childComponent.UploadFiles(files,component.get("v.parentSocialAdId"));
        }
    }
})
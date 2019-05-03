({
    doInit : function(component, event, helper) {
        if(component.get('v.adStatus') == 'Edit'){
            component.set('v.requestMessage','Initializing...');
        	component.set('v.processingRequest',true);
            var allPromises = [];
            allPromises.push(helper.populateAdDetails(component,helper));
            Promise.all(allPromises).then($A.getCallback(function(results){
        		component.set('v.processingRequest',false);
            }),$A.getCallback(function(ErrorMessage){
        		component.set('v.processingRequest',false);
                component.find('notifLib').showNotice({
                    "variant": "error",
                    "header": "Initialization Failed!",
                    "message": ErrorMessage
                });
            }));
        }
    },
    UploadFiles : function(component, event, helper) {
        var files = event.getSource().get("v.files");
        var adDetails = component.get('v.adDetails');
        for(var i = 0; i < files.length; i++){
            adDetails.uploadedFiles.push(files[i]);
            files[i].fileURL = URL.createObjectURL(files[i]);
            //adDetails.uploadedFiles.push(files[i]);
        }
        component.set('v.adDetails',adDetails);
    },
    removeImage : function(component, event, helper) {
        var index = event.currentTarget.dataset.adindex;
        var adDetails = component.get('v.adDetails');
        adDetails.uploadedFiles.splice(index,1);
        component.set('v.adDetails',adDetails);
    },
    cancelAd : function(component, event, helper) {
        var appEvent = $A.get("e.c:NXX2_CloseModal");
        				appEvent.fire();
    },
    saveAd : function(component, event, helper) {
        var requestMessage = 'Creating Ad Form...';
        var adDetails = component.get('v.adDetails');
        var adType = component.get('v.adType');
        var adDetailsObject = {};
        if(adType == 'Lead Generation'){
            adDetailsObject = {
                Form_Name__c : adDetails.Form_Name__c ,
                Form_Privacy_Policy_Link__c : adDetails.Form_Privacy_Policy_Link__c,
                Form_Thank_You_Page_Link__c : adDetails.Form_Thank_You_Page_Link__c,
                Form_Client_Specified_Criteria__c : adDetails.Form_Client_Specified_Criteria__c
            };
        }else{
            adDetailsObject = {
                Greetings_Card__c : adDetails.Greetings_Card__c ,
                Quick_Replies__c : adDetails.Quick_Replies__c
            };
        }
        if(!$A.util.isUndefined(adDetails.Id)){
            adDetailsObject.Id = adDetails.Id;
            requestMessage = 'Updating Ad Form...';
        }else{
            adDetailsObject.Social_Campaign__c = component.get('v.campaignId');
            adDetailsObject.Parent_Social_Ad__c = component.get('v.parentSocialAdId');
        }
        component.set('v.requestMessage',requestMessage);
        component.set('v.processingRequest',true);
        var action = component.get("c.saveAdDetails"); 
        action.setParams({
            adDetails: adDetailsObject,
            recordType: 'Social Form'
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
        	component.set('v.processingRequest',false);
            if(state == 'SUCCESS') {
                adDetails.Id = actionResult.getReturnValue().Id;
                component.set('v.adDetails',adDetails);
                helper.saveFiles(component,adDetails);
            }else{
                var errors = actionResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Operation failed!",
                            "message": ErrorMessage
                        });
                    }
                }
            }
        });
        $A.enqueueAction(action);
    },
    postUploadHandler : function(component, event, helper) {
        var filesUploadStatus = event.getParam("filesUploadStatus");
        component.set('v.requestMessage',"Saving Screenshot Details...");
        component.set('v.processingRequest',true);
        var adDetails = component.get('v.adDetails');
        var adContentsObject = [];
        for(var i = 0;i < adDetails.uploadedFiles.length; i++){
            var socialAdContent = {};
            if($A.util.isUndefined(adDetails.uploadedFiles[i].GoogleDriveFileId) || adDetails.uploadedFiles[i].GoogleDriveFileId == ''){
                var fileStatus = filesUploadStatus.splice(0,1);
                if(fileStatus[0].status  == 'SUCCESS'){
                    socialAdContent = {
                        GoogleDrive_File_Id__c : fileStatus[0].fileId,
                        File_Name__c : adDetails.uploadedFiles[i].name,
                        File_Size__c : adDetails.uploadedFiles[i].size,
                        File_Type__c : adDetails.uploadedFiles[i].type
                    }
                    adDetails.uploadedFiles[i].GoogleDriveFileId = fileStatus[0].fileId;
                }
            }
            if(!$A.util.isUndefined(adDetails.uploadedFiles[i].id)){
                socialAdContent.id = adDetails.uploadedFiles[i].id;
            }
            socialAdContent.Display_Order__c = i;
            adContentsObject.push(socialAdContent);
        }
        var action = component.get("c.saveAdContent"); 
        action.setParams({
            adContentsString: JSON.stringify(adContentsObject),
            socialAdId: adDetails.Id,
            mode: 'Edit'
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            component.set('v.processingRequest',false);
            if(state == 'SUCCESS') {
                component.find('notifLib').showNotice({
                    "variant": "success",
                    "header": "Operation successful!",
                    "message": "Ad Form has been saved successfully.",
                    "closeCallback": function() {
                        var appEvent = $A.get("e.c:NXX2_CloseModal");
        				appEvent.fire();
                    }
                });
                var appEvent = $A.get("e.c:NXX2_AdHasBeenUpdated");
                appEvent.fire();
                var adContents = actionResult.getReturnValue();
                for(var i = 0;i < adContents.length; i++){
                    adDetails.uploadedFiles[i].id = adContents[i].id;
                }
                component.set('v.adDetails',adDetails);
            }else{
                var errors = actionResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Operation failed!",
                            "message": ErrorMessage
                        });
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }
})
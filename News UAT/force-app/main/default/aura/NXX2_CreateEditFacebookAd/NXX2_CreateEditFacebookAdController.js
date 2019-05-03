({
    doInit : function(component, event, helper) {
        var spinner = component.find("mySpinner");
        $A.util.toggleClass(spinner, "slds-hide");
        var allPromises = [];
        allPromises.push(helper.populateAdTypes(component));
        if(component.get('v.adStatus') != 'Create'){
            allPromises.push(helper.populateAdDetails(component,helper));
        }else{
            var proofDetails = component.get('v.proofDetails');
        }
        Promise.all(allPromises).then($A.getCallback(function(results){
            $A.util.toggleClass(spinner, "slds-hide");
        }),$A.getCallback(function(ErrorMessage){
            $A.util.toggleClass(spinner, "slds-hide");
            component.find('notifLib').showNotice({
                "variant": "error",
                "header": "Initialization Failed!",
                "message": ErrorMessage,
                "closeCallback": function() {
                    var appEvent = $A.get("e.c:NXX2_CloseModal");
                    appEvent.fire();
                }
            });
        }));
    },
    adDetailsChangedHandler : function(component, event, helper) {
        var appEvent = component.getEvent("fbAdDetailsChanged");
        appEvent.setParams({ "adDetails" : component.get('v.adDetails')});
        appEvent.fire();
    },
    updateView : function(component, event, helper) {
        component.set('v.adDetails',component.get('v.adDetails'));
    },
    selectAdType : function(component, event, helper) {
        component.set('v.selectedCreativeType',{});
        if(!$A.util.isUndefined(component.find('selectCreativeType'))){
            component.find('selectCreativeType').set("v.value","");
        }
        var adDetailsCopy = JSON.parse(JSON.stringify(component.get('v.adDetails')));
        var adDetails = {
            Start_Date__c : adDetailsCopy.Start_Date__c,
            End_Date__c : adDetailsCopy.End_Date__c
        };
        var adTypes = component.get('v.adTypes');
        adDetails['Ad_Type__c'] = component.find('selectAdType').get("v.value");
        var index = adTypes.map(function(x) {return x.adType; }).indexOf(adDetails['Ad_Type__c']);
        component.set('v.selectedAdType',adTypes[index]);
        component.set('v.creativeTypes',adTypes[index].creativeTypes);
        component.set('v.adDetails',adDetails);
    },
    selectCreativeType : function(component, event, helper) {
        var uploadConfig = component.get('v.uploadConfig');
        var adDetails = component.get('v.adDetails');
        var creativeTypes = component.get('v.selectedAdType').creativeTypes;
        adDetails['uploadedFiles'] = [];
        adDetails['Creative_Type__c'] = component.find('selectCreativeType').get("v.value");
        var index = creativeTypes.map(function(x) {return x.creativeTypeName; }).indexOf(adDetails['Creative_Type__c']);
        if(adDetails['Creative_Type__c'] == 'Carousel' || adDetails['Creative_Type__c'] == 'Slideshow'){
            adDetails['uploadedFiles'] = [
                {
                    type : 'Text',
                    content : 'Nothing to display'
                },
                {
                    type : 'Text',
                    content : 'Nothing to display'
                },
                {
                    type : 'Text',
                    content : 'Nothing to display'
                }
            ]
        }
        if(adDetails['Creative_Type__c'] == 'Video'){
            uploadConfig.label = 'Upload Video';
            uploadConfig.accept = 'video/*';
        }else{
            uploadConfig.label = 'Upload Image';
            uploadConfig.accept = ['.jpg','.png','.jpeg'];
        }
        component.set('v.uploadConfig',uploadConfig);
        component.set('v.currentFileIndex',0);
        component.set('v.selectedCreativeType',creativeTypes[index]);
        component.set('v.adDetails',adDetails);
    },
    UploadFile : function(component, event, helper) {
        var file = event.getSource().get("v.files")[0];
        var adDetails = component.get('v.adDetails');
        var currentFileIndex = component.get('v.currentFileIndex');
        if($A.util.isUndefined(adDetails.uploadedFiles[currentFileIndex])){
            adDetails.uploadedFiles[currentFileIndex] = {};
        }
        adDetails.uploadedFiles[currentFileIndex].type = file.type;
        adDetails.uploadedFiles[currentFileIndex].file = file;
        adDetails.uploadedFiles[currentFileIndex].name = file.name;
        adDetails.uploadedFiles[currentFileIndex].fileURL = URL.createObjectURL(file);
        component.set('v.adDetails',adDetails);
    },
    changeCurrentFileIndex : function(component, event, helper) {
        var index = event.currentTarget.dataset.index;
        var elements = document.getElementsByClassName("file-count");
        for(var i = 0; i < elements.length; i++){
            $A.util.removeClass(elements[i], 'active');
        }
        $A.util.addClass(elements[index], 'active');
        component.set('v.currentFileIndex',parseInt(index));
    },
    addFileCount : function(component, event, helper) {
        var adDetails = component.get('v.adDetails');
        adDetails.uploadedFiles.push({
            type : 'Text',
            content : 'Nothing to display'
        });
        component.set('v.adDetails',adDetails);
    },
    removeSubDetail : function(component, event, helper) {
        var index = component.get('v.currentFileIndex');
        var adDetails = component.get('v.adDetails');
        adDetails.uploadedFiles.splice(index,1);
        component.set('v.adDetails',adDetails);
        component.set('v.currentFileIndex',0);
    },
    removeImage : function(component, event, helper) {
        var index = component.get('v.currentFileIndex');
        var adDetails = component.get('v.adDetails');
        adDetails.uploadedFiles[index] = {
            type : 'Text',
            content : 'Nothing to display',
            adHeadline : adDetails.uploadedFiles[index].adHeadline,
            adNewsfeedDesc : adDetails.uploadedFiles[index].adNewsfeedDesc,
            adLink : adDetails.uploadedFiles[index].adLink
        };
        component.set('v.adDetails',adDetails);
    },
    cancelAd : function(component, event, helper) {
        var appEvent = $A.get("e.c:NXX2_CloseModal");
        appEvent.fire();
    },
    saveAd : function(component, event, helper) {
        var allValid = true;
        var allLinks = component.find('field');
        if(Array.isArray(allLinks)){
            for(var i = 0; i < allLinks.length; i++){
                if(!allLinks[i].checkValidity()){
                    allValid = false;
                }
            }
        }else{
            allValid = allLinks.checkValidity();
        }
        if (allValid) {
            var requestMessage = 'Creating Ad...';
            //var params = helper.getURLParameters();
            var adDetails = component.get('v.adDetails');
            var adDetailsObject = {
                Button_Type__c : adDetails.Button_Type__c ,
                Ad_Headline__c : adDetails.Ad_Headline__c,
                Ad_Link__c : adDetails.Ad_Link__c,
                Ad_Newsfeed_Link_Description__c : adDetails.Ad_Newsfeed_Link_Description__c,
                Ad_Text__c : adDetails.Ad_Text__c,
                Ad_Type__c : adDetails.Ad_Type__c,
                Start_Date__c : adDetails.Start_Date__c,
                End_Date__c : adDetails.End_Date__c,
                Event_Name__c : adDetails.Event_Name__c,
                Creative_Type__c : adDetails.Creative_Type__c,
                Social_Campaign__c : component.get('v.campaignId')//params.campaignId
            };
            if(!$A.util.isUndefined(adDetails.Id)){
                if(component.get('v.adStatus') == 'Edit'){
                    adDetailsObject.Id = adDetails.Id;
                    requestMessage = 'Updating social Ad...';
                }else{
                    adDetailsObject.Version_Number__c = parseInt(adDetails.Version_Number__c) + 1;
                    adDetailsObject.Parent_Social_Ad__c = $A.util.isUndefined(adDetails.Parent_Social_Ad__c) ? adDetails.Id : adDetails.Parent_Social_Ad__c;
                    requestMessage = 'Creating new version of Ad...';
                }
            }
            var appEvent = component.getEvent("requestingServer");
            appEvent.setParams({ "requestMessage" : requestMessage});
            appEvent.fire();
            var action = component.get("c.saveAdDetails"); 
            action.setParams({
                adDetails: adDetailsObject,
                recordType: 'Social Ad'
            });
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if(state == 'SUCCESS') {
                    adDetails.Id = actionResult.getReturnValue().Id;
                    adDetails.Version_Number__c = actionResult.getReturnValue().Version_Number__c;
                    component.set('v.adDetails',adDetails);
                    var appEvent = component.getEvent("serverResponded");
                    appEvent.fire();
                    helper.saveFiles(component,adDetails);
                }else{
                    var errors = actionResult.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            component.find('notifLib').showNotice({
                                "variant": "error",
                                "header": "Operation failed!",
                                "message": errors[0].message,
                                "closeCallback": function() {
                                    var appEvent = $A.get("e.c:NXX2_CloseModal");
                                    appEvent.fire();
                                }
                            });
                            var appEvent = component.getEvent("serverResponded");
                            appEvent.fire();
                        }
                    }
                }
            });
            $A.enqueueAction(action);
        }
    },
    postUploadHandler : function(component, event, helper) {
        var filesUploadStatus = event.getParam("filesUploadStatus");
        var appEvent = component.getEvent("requestingServer");
        appEvent.setParams({ "requestMessage" : "Saving Ad Details..."});
        appEvent.fire();
        var adDetails = component.get('v.adDetails');
        var adContentsObject = [];
        for(var i = 0;i < adDetails.uploadedFiles.length; i++){
            var socialAdContent = {
                File_Type__c : adDetails.uploadedFiles[i].type
            }
            if(!$A.util.isUndefined(adDetails.uploadedFiles[i].GoogleDriveFileId)){
                socialAdContent.GoogleDrive_File_Id__c = adDetails.uploadedFiles[i].GoogleDriveFileId;
                socialAdContent.File_Name__c = adDetails.uploadedFiles[i].name;
                socialAdContent.File_Size__c = adDetails.uploadedFiles[i].size;
            }else if(!$A.util.isUndefined(adDetails.uploadedFiles[i].file)){
                var fileStatus = filesUploadStatus.splice(0,1);
                if(fileStatus[0].status  == 'SUCCESS'){
                    socialAdContent.GoogleDrive_File_Id__c = fileStatus[0].fileId;
                    socialAdContent.File_Name__c = adDetails.uploadedFiles[i].file.name;
                    socialAdContent.File_Size__c = adDetails.uploadedFiles[i].file.size;
                    adDetails.uploadedFiles[i].GoogleDriveFileId = fileStatus[0].fileId;
                }
            }
            if(!$A.util.isUndefined(adDetails.uploadedFiles[i].id) && component.get('v.adStatus') == 'Edit'){
                socialAdContent.id = adDetails.uploadedFiles[i].id;
            }
            socialAdContent.Display_Order__c = i;
            socialAdContent.Ad_Headline__c = adDetails.uploadedFiles[i].adHeadline;
            socialAdContent.Ad_Link__c = adDetails.uploadedFiles[i].adLink;
            socialAdContent.Ad_Newsfeed_Link_Description__c = adDetails.uploadedFiles[i].adNewsfeedDesc;
            adContentsObject.push(socialAdContent);
        }
        var action = component.get("c.saveAdContent"); 
        action.setParams({
            adContentsString: JSON.stringify(adContentsObject),
            socialAdId: adDetails.Id,
            mode: component.get('v.adStatus')
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                var message = "New Ad Version has been created successfully.";
                if(component.get('v.adStatus') == 'Edit'){
                    message = "Ad has been updated successfully."
                }else if(component.get('v.adStatus') == 'Create'){
                    message = "Ad has been saved successfully.";
                }
                component.find('notifLib').showNotice({
                    "variant": "success",
                    "header": "Operation successful!",
                    "message": message,
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
                var appEvent = component.getEvent("serverResponded");
                appEvent.fire();
                if(component.get('v.adStatus') == 'CreateNewVersion'){
                    //location.reload();
                }
            }else{
                var errors = actionResult.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.find('notifLib').showNotice({
                            "variant": "error",
                            "header": "Operation failed!",
                            "message": errors[0].message,
                            "closeCallback": function() {
                                var appEvent = $A.get("e.c:NXX2_CloseModal");
                                appEvent.fire();
                            }
                        });
                        var appEvent = component.getEvent("serverResponded");
                        appEvent.fire();
                    }
                }
            }
        });
        $A.enqueueAction(action);
    }
})
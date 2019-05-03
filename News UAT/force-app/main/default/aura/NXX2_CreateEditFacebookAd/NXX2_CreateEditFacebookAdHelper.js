({
	populateAdTypes : function(component) {
        return new Promise(function(resolve, reject) {
            var action = component.get("c.getCreateAdConfigData"); 
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if(state == 'SUCCESS') {
                    component.set('v.adTypes', actionResult.getReturnValue());
                    resolve.call(this, actionResult.getReturnValue());
                }else{
                    var errors = actionResult.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            component.set("v.message",errors[0].message);
                            reject.call(this, errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action); 
        });
	},
    populateAdDetails : function(component,helper) {
        return new Promise(function(resolve, reject) {
            //var params = helper.getURLParameters();
            var action = component.get("c.getAdDetails"); 
            action.setParams({
                socialAdRecordId : component.get("v.recordId")//params.socialAdRecordId
            });
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if(state == 'SUCCESS') {
                    var rawData = actionResult.getReturnValue();
                    var adDetails = rawData.socialAd;
                    adDetails.uploadedFiles = rawData.contents;
                    if(component.get('v.adStatus') != 'Edit' && $A.util.isUndefined(adDetails.Parent_Social_Ad__c)){
                        adDetails.Parent_Social_Ad__c = component.get("v.recordId");
                    }
                    component.set('v.adDetails', adDetails);
                    resolve.call(this, actionResult.getReturnValue());
                }else{
                    var errors = actionResult.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            component.set("v.message",errors[0].message);
                            reject.call(this, errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action); 
        });
	},
    initializeDropdown : function(component) {
        var adDetails = component.get('v.adDetails');
        var adTypes = component.get('v.adTypes');
        var adTypeIndex = adTypes.map(function(x) {return x.adType; }).indexOf(adDetails['Ad_Type__c']);
        component.set('v.selectedAdType',adTypes[adTypeIndex]);
        component.set('v.creativeTypes',adTypes[adTypeIndex].creativeTypes);
        var uploadConfig = component.get('v.uploadConfig');
        var creativeTypes = adTypes[adTypeIndex].creativeTypes;
        var index = creativeTypes.map(function(x) {return x.creativeTypeName; }).indexOf(adDetails['Creative_Type__c']);
        if(adDetails['Creative_Type__c'] == 'Video'){
            uploadConfig.label = 'Upload Video';
            uploadConfig.accept = ['.mp4'];
        }else{
            uploadConfig.label = 'Upload Image';
            uploadConfig.accept = ['.jpg','.png','.jpeg'];
        }
       	component.set('v.uploadConfig',uploadConfig);
        component.set('v.currentFileIndex',0);
        component.set('v.selectedCreativeType',creativeTypes[index]);
        component.find('selectCreativeType').set("v.value",adDetails['Creative_Type__c']);
        if(adDetails['Ad_Type__c'] !== 'Video Views'){
            component.find('selectButtonType').set("v.value",adDetails['Button_Type__c']);
        }
	},
    populateCreativeTypes : function(component) {
        component.set("v.creativeTypes",['Single Image','Video','SlideShow','Carousel']);
	},
    populateButtonTypes : function(component) {
        component.set("v.buttonTypes",['Shop Now','Book Now','Learn More','Sign Up']);
	},
    processImage : function(index,totalCount,component,images,imageURLs,helper){
        var adDetails = component.get('v.adDetails');
        if(totalCount == index){
            adDetails["imageURLs"] = imageURLs;
            component.set("v.adDetails",adDetails);
        }else{
            var reader = new FileReader();
            adDetails.imageNames = adDetails.imageNames.push(images[index].name);
            reader.onload = function() {
                index++;
                var fileContent = reader.result;
                if(adDetails.creativeType == 'Video'){
                    adDetails.videoURL = URL.createObjectURL(images[index - 1]);
                    component.set("v.adDetails",adDetails);
                }else{
                    imageURLs.push(fileContent);
                	helper.processImage(index,totalCount,component,images,imageURLs,helper);
                }
            };
            reader.readAsDataURL(images[index]);
        }
    },
    getFileContent : function(file,callback){
            var reader = new FileReader();
            reader.onload = function() {
                callback(reader.result);
            };
            reader.readAsDataURL(file);
    },
    getURLParameters : function(component) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split('&'),
            sParameters = {},
            i;
        for (i = 0; i < sURLVariables.length; i++) {
            var sParameterList = sURLVariables[i].split('=');
            sParameters[sParameterList[0]] = sParameterList[1];
        }
        return sParameters;
	},
    saveFiles : function(component,adDetails) {
        var files = [];
        for(var i = 0;i < adDetails.uploadedFiles.length; i++){
            if(!$A.util.isUndefined(adDetails.uploadedFiles[i].file) && ($A.util.isUndefined(adDetails.uploadedFiles[i].GoogleDriveFileId) || adDetails.uploadedFiles[i].GoogleDriveFileId !== '')){
                files.push(adDetails.uploadedFiles[i].file);
            }
        }
        var appEvent = component.getEvent("initialiseFileUpload");
        appEvent.setParams({ "files" : files,
                            "recordId" : $A.util.isUndefined(adDetails.Parent_Social_Ad__c) ? adDetails.Id : adDetails.Parent_Social_Ad__c});
        appEvent.fire();
    }
})
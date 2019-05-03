({
    getProofNumber : function(component, event, helper){

        component.set("v.Spinner",true);
        var action = component.get("c.fetchProofNumberForGoogleDriveRecord"); 
        action.setParams({
            recordId : component.get("v.recordId")
        });
        action.setCallback(this, function(a) {
            var state = action.getState();
                if(state == 'SUCCESS') {
                    console.log(a.getReturnValue());
                    component.set("v.proofRecorNumber", a.getReturnValue());
                    helper.loadFilesList(component, event, helper);
                }else{
                    component.set("v.Spinner",false);
                    var errors = action.getError();
                    console.log(errors);
                    if (errors) {
                    }
                }
            
        });
        $A.enqueueAction(action);        
    },/*
    getFileContent : function(file,callback){
        var reader = new FileReader();
        
        reader.onload = $A.getCallback(function() {
            callback(reader.result);
        });
        reader.readAsDataURL(file);
    },*/
    loadFilesList : function(component, event, helper) { 
        component.set("v.Spinner",true);
        var action = component.get("c.loadFilesFromGoogleDrive"); 
        action.setParams({
            recordId : component.get("v.recordId"),
            folderId : component.get("v.proofRecorNumber") 
        });
        action.setCallback(this, function(a) {
            console.log(a.getReturnValue());
            component.set("v.gdriveFilesList", a.getReturnValue());
            console.log('gdriveFilesList' + component.get("v.gdriveFilesList"));
            component.set("v.Spinner",false);
            
        });
        $A.enqueueAction(action); 
    },
    showUploadSpinner: function(component, event, helper) {
        component.set("v.Spinner", true); 
    },
    
    hideUploadSpinner : function(component,event,helper){
        component.set("v.Spinner", false);
    },
    deleteFile: function(component,event,fileId,folderId){
        var action = component.get("c.deleteFilesInGoogleDrive"); 
        this.hideModal(component);
        action.setParams({
            fileIdToBeDeletedFromDrive: fileId,
        });
        action.setCallback(this, function(response) {
            var deleteFileResponse = response.getReturnValue();
            if(deleteFileResponse!=undefined  && deleteFileResponse.indexOf('ERROR') !==-1){
                this.showErrorToast(deleteFileResponse);
            }else{
                
            var gdriveFilesList = component.get('v.gdriveFilesList');
			var gdriveFilesUpdatedList = [];
            if(gdriveFilesList != null && gdriveFilesList != undefined) {
                if(Array.isArray(gdriveFilesList)) {
                        for(var i=0; i<gdriveFilesList.length; i++) {
                            if(gdriveFilesList[i].id != fileId) {
                                gdriveFilesUpdatedList.push(gdriveFilesList[i]);
                            }
                        }
                }
            }
			component.set('v.gdriveFilesList',gdriveFilesUpdatedList);
            console.log(response.getReturnValue());
                //this.loadFilesList(component, folderId);  
            }
            
        });
        $A.enqueueAction(action); 
    },
    showErrorToast : function(errorMessage) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Error Message',
            message:errorMessage,
            duration:' 5000',
            key: 'info_alt',
            type: 'error',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    showModal : function(component,fileName) {      
        var modal = component.find("confirmModel");
        $A.util.removeClass(modal, 'hideConfirmDiv');        
    },
    
    hideModal : function(component) {
        var modal = component.find("confirmModel");
        component.set("v.fileIdToBeDeleted",'');
        component.set("v.fileNameToBeDeleted",'');
        $A.util.addClass(modal, 'hideConfirmDiv');
    },
    MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 524288,      //Chunk Max size 750Kb 
    
    uploadHelper: function(component, event) {
        component.set("v.Spinner",true);
        // start/show the loading spinner   
        // get the selected files using aura:id [return array of files]
        //var fileInput = component.find("fileId").get("v.files");
        // get the first file using array index[0]  
       // var file = fileInput[0];
        var recordId = component.get("v.recordId");
        var file = event.getSource().get("v.files")[0];
        var self = this;
        // check the selected file size, if select file size greter then MAX_FILE_SIZE,
        // then show a alert msg to user,hide the loading spinner and return from function  
        //if (file.size > self.MAX_FILE_SIZE) {
        //    component.set("v.fileName", 'Alert : File size cannot exceed ' + self.MAX_FILE_SIZE + ' bytes.\n' + ' Selected file size: ' + file.size);
        //    return;
        //}
 
        // create a FileReader object 
        var objFileReader = new FileReader();
        // set onload function of FileReader object   
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
            fileContents = fileContents.substring(dataStart);
              fileContents = atob(fileContents)
            // call the uploadProcess method 
            self.uploadProcess(component, file, fileContents);
        });
 
        objFileReader.readAsDataURL(file);
    },
    uploadProcess: function(component, file, fileContents) {
        // set a default size or startpostiton as 0 
        var startPosition = 0;
        // calculate the end size or endPostion using Math.min() function which is return the min. value   
        var endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
        var minusEndPosition = endPosition - 1;
        var fileSize=""+file.size;
        // start with the initial chunk, and set the attachId(last parameter)is null in begin
        this.uploadInChunk(component, file, fileContents, startPosition, minusEndPosition,endPosition, '');
    },
    uploadInChunk: function(component, file, fileContents, startPosition, minusEndPosition,endPosition, attachId) {
        // call the apex method 'saveChunk'
        console.log(fileContents.length);
        var getchunk = btoa(fileContents.substring(startPosition, endPosition));
        //var getchunk = fileContents.substring(startPosition, endPosition);
        console.log('testing..'+fileContents.substring(startPosition, endPosition).length);
        var action = component.get("c.saveChunk");
        action.setParams({
            parentId: component.get("v.recordId"),
            fileName: file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type,
            fileId: attachId,
            fileSize: fileContents.length.toString(),
            startPosition: startPosition.toString(),
            endPosition: minusEndPosition.toString()
        });
 
        // set call back 
        action.setCallback(this, function(response) {
            // store the response / Attachment Id   
            attachId = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                // update the start position with end postion
                startPosition = endPosition;
                endPosition = Math.min(fileContents.length, startPosition + this.CHUNK_SIZE);
                minusEndPosition = endPosition - 1;
                // check if the start postion is still less then end postion 
                // then call again 'uploadInChunk' method , 
                // else, diaply alert msg and hide the loading spinner
                if (startPosition < endPosition) {
                    this.uploadInChunk(component, file, fileContents, startPosition, minusEndPosition,endPosition,attachId);
                } else {
                    //alert('your File is uploaded successfully');
                    component.set("v.Spinner",false);
                    this.loadFilesList(component);
                    //component.set("v.showLoadingSpinner", false);
                }
                // handel the response errors        
            } else if (state === "INCOMPLETE") {
                alert("From server: " + response.getReturnValue());
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },
    handleFileUpload : function(component,event){
        
        var googleDrivefileID = event.getParam("googleDriveFileId");
        var errorMessage = event.getParam("errorMessage");
        if(googleDrivefileID!=null && googleDrivefileID!=undefined){
          //this.loadFilesList(component, component.get("v.recordId")); 
          this.readUploadedFileMetaData(component, googleDrivefileID);
        }else if(errorMessage!=null && errorMessage!=undefined){
            this.showErrorToast(errorMessage);
        }
          
    },
    readUploadedFileMetaData: function(component, fileId) {
        component.set("v.Spinner",true);
        var action = component.get("c.readUploadedFilesFromGoogleDrive"); 
        action.setParams({
            fileId: fileId,
        });
        action.setCallback(this, function(a) {
            console.log(a.getReturnValue());
            component.set("v.Spinner",false);
            var gdriveFilesList = component.get("v.gdriveFilesList");
            var uploadedRecord = a.getReturnValue();
            gdriveFilesList.push(uploadedRecord);
            component.set("v.gdriveFilesList", gdriveFilesList);
           // this.loadFilesList(component);
        });
        $A.enqueueAction(action); 
    },

    
    
})
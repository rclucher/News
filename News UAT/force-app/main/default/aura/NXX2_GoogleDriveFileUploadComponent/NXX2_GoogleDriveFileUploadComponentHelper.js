({
    MAX_FILE_SIZE: 4500000, //Max file size 4.5 MB 
    CHUNK_SIZE: 524288,      //Chunk Max size 750Kb  2361600
   // CHUNK_SIZE: 1048576, 
    
    uploadHelper: function(component, event) {
        //debugger;
        /* 
         * start/show the loading spinner   
         */
        var recordId = component.get("v.recordId");
        var file = event.getSource().get("v.files")[0];
        var self = this;
        /*check the selected file size, if select file size greter then MAX_FILE_SIZE,
         *then show a alert msg to user,hide the loading spinner and return from function
         */
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
        // start with the initial chunk, and set the resumableLocation of File (last parameter)is null in begin
        this.uploadInChunk(component, file, fileContents, startPosition, minusEndPosition,endPosition, '');
    },
    uploadInChunk: function(component, file, fileContents, startPosition, minusEndPosition,endPosition, resumableLocation) {
        
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
            fileId: resumableLocation,
            fileSize:fileContents.length.toString(),
            startPosition:startPosition.toString(),
            endPosition: minusEndPosition.toString(),
            recordNumber : component.get("v.proofRecorNumber")
        });
        // set call back 
        action.setCallback(this, function(response) {
            // store the response / Attachment Id   
            resumableLocation = response.getReturnValue();
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
                    this.uploadInChunk(component, file, fileContents, startPosition, minusEndPosition,endPosition,resumableLocation);
                } else {
                    //alert('your File is uploaded successfully');
                    /**
                     * Once the file upload is completed the response will come as 
                     * DTO Object, so inform parent Component with this DTO and stop processing
                     */ 
                    //component.set("v.Spinner",false);
                    //googleDrivefileID
                    component.set("v.googleDriveFileId",resumableLocation);
                    component.set("v.isUpdateIsInProgress","false");
                    //this.loadFilesList(component);
                    this.fireFileUpdateEvent(component);
                    //component.set("v.showLoadingSpinner", false);
                }
                // handel the response errors        
            } else if (state === "INCOMPLETE") {
                component.set("v.isUpdateIsInProgress","false");
                component.set("v.errorMessage","From server: " + response.getReturnValue());
                this.fireFileUpdateEvent(component);
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        component.set("v.errorMessage","Error message: " + errors[0].message);
                    }
                } else {
                    component.set("v.isUpdateIsInProgress","false");
                    console.log("Unknown error");
                    component.set("v.errorMessage","Unknown error");
                }
                component.set("v.isUpdateIsInProgress","false");
                this.fireFileUpdateEvent(component);
            }
        });
        // enqueue the action
        $A.enqueueAction(action);
    },
    fireFileUpdateEvent:function(component){
        //alert('fireFileUpdateEvent ...Fired.....');
        this.fireshowOrHideUploadSpinnerProcessingEvent(component);
        //Call Event to inform main component to open file preview
        var googleDriveFileUploadEvent = component.getEvent("googleDriveFileUploadEvent");
        googleDriveFileUploadEvent.setParams({
            "googleDriveFileId" : component.get("v.googleDriveFileId"),
            "errorMessage":component.get("v.errorMessage")
        });
        googleDriveFileUploadEvent.fire();
    },
    fireshowOrHideUploadSpinnerProcessingEvent : function(component){
        //alert("Start Processing...");
        var parentEvent =  component.getEvent("callShowUploadSpinnerMethodOfParent");
        parentEvent.setParams({"showProcessingImage":component.get("v.isUpdateIsInProgress")});       
        parentEvent.fire(); 
    }
})
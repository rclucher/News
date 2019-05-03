({
    MAX_FILE_SIZE: 3000000,
    //CHUNK_SIZE: 1966080,
    CHUNK_SIZE: 1048576, 

    PROGRESS_CONTROLLER: null,
    TIME_INERVAL: 200,
	showProgress: function (component,helper) {
        helper.PROGRESS_CONTROLLER = setInterval($A.getCallback(function () {
            var progress = component.get('v.progress');
            component.set('v.progress', progress === 90 ? clearInterval(helper.PROGRESS_CONTROLLER) : progress + 10);
        }), helper.TIME_INERVAL);
    },
    startUpload: function (component,helper,files,recordId,index) {
        component.set('v.progress',10);
        if(index >= files.length){
            component.set('v.uploading',false);
            var appEvent = $A.get("e.c:NXX2_FileUploadCompleted");
            appEvent.setParams({ "filesUploadStatus" : component.get('v.filesUploadStatus')});
            appEvent.fire();
        }else{
            component.set('v.currentFileCount',index);
            if(files[index].size < helper.MAX_FILE_SIZE){
                helper.TIME_INERVAL = 500;
                helper.showProgress(component,helper);
                helper.uploadSingleFile(component,files[index],recordId,function(response){
                    helper.updateUploadStatus(component,helper,files[index],response);
                    helper.startUpload(component,helper,files,recordId,index + 1);
                });
            }else{
                helper.TIME_INERVAL = 2000;
                helper.showProgress(component,helper);
                helper.uploadFileInChunk(component,helper,files[index],recordId,function(response){
                    helper.updateUploadStatus(component,helper,files[index],response);
                    helper.startUpload(component,helper,files,recordId,index + 1);
                });
            }
        }
    },
    uploadSingleFile: function (component,file,recordId,callback) {
        var reader = new FileReader();   
        reader.onload = $A.getCallback(function() {
            var fileContent = reader.result;
            var base64 = 'base64,';
            var dataStart = fileContent.indexOf(base64) + base64.length;
            fileContent = fileContent.substring(dataStart);
            var action = component.get("c.saveSingleFile");
            action.setParams({
                recordId: recordId,
                fileName: file.name,
                fileContent: encodeURIComponent(fileContent),
                fileType: file.type
            });
            action.setCallback(this, function(response) {
                callback(response);
            });
            $A.enqueueAction(action);
        });
        reader.readAsDataURL(file);
    },
    uploadFileInChunk: function (component,helper,file,recordId,callback) {
        var reader = new FileReader();   
        reader.onload = $A.getCallback(function() {
            var fileContent = reader.result;
            var base64 = 'base64,';
            var dataStart = fileContent.indexOf(base64) + base64.length;
            fileContent = atob(fileContent.substring(dataStart));
            var startPosition = 0;  
        	var endPosition = Math.min(fileContent.length, startPosition + helper.CHUNK_SIZE);
            helper.uploadNextChunk(component,helper, file, fileContent, startPosition, endPosition - 1,'',callback,recordId);
        });
        reader.readAsDataURL(file);
    },
    uploadNextChunk : function (component,helper, file, fileContent, startPosition, endPosition, attachId,callback,recordId) {
        var getchunk = btoa(fileContent.substring(startPosition, endPosition + 1));
        var action = component.get("c.saveFileInChunk");
        action.setParams({
            recordId: recordId,
            fileName: file.name,
            fileContent: encodeURIComponent(getchunk),
            fileType: file.type,
            fileId: attachId,
            fileSize: fileContent.length.toString(),
            startPosition: startPosition.toString(),
            endPosition: endPosition.toString()
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                attachId = response.getReturnValue();
                startPosition = endPosition + 1;
                endPosition = Math.min(fileContent.length, startPosition + this.CHUNK_SIZE);
                if (startPosition < endPosition) {
                    helper.uploadNextChunk(component,helper, file, fileContent, startPosition, endPosition - 1,attachId,callback,recordId);
                } else {
                    callback(response);
                }       
            } else if (state === "ERROR") {
                callback(response);
            }
        });
        $A.enqueueAction(action);
    },
    updateUploadStatus : function(component,helper,file,response){
        var filesUploadStatus = component.get("v.filesUploadStatus");
        var state = response.getState();
        var status;
        if (state === "SUCCESS") {
            status = {
                status : 'SUCCESS',
                fileName : file.name,
                fileId : response.getReturnValue()
            };
        } else if (state === "ERROR") {
            status = {
                status : 'ERROR',
                fileName : file.name,
                errorMessage : 'Server side error occured!'
            };
            var errors = response.getError();
            if (errors) {
                if (errors[0] && errors[0].message) {
                    status.errorMessage = errors[0].message;
                }
            }
        }
        filesUploadStatus.push(status);
        component.set("v.filesUploadStatus",filesUploadStatus);
        component.set('v.progress',100);
        clearInterval(helper.PROGRESS_CONTROLLER);
    }
})
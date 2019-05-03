({
    UploadFileInGoogleDrive: function(component, event, helper) {
      //alert('Started with Independent Component' + component.get("v.recordId"));
      /**
       * This event will trigger the Processing Icon in Parent Controller
       */ 
      component.set("v.isUpdateIsInProgress","true");
      helper.fireshowOrHideUploadSpinnerProcessingEvent(component);
      /**
       * This method will start the actual upload of the file
       */ 
      helper.uploadHelper(component, event);
    }
    
})
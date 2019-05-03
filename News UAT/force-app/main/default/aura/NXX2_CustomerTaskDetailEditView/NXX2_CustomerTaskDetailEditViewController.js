({
doInit : function(component, event, helper){
    var action = component.get("c.getAllCommentsLinkedToType"); 
    action.setCallback(this, function(a) {
        console.log(a.getReturnValue()); 
        component.set("v.mapOfTypeAndComments",a.getReturnValue());
    });
    $A.enqueueAction(action);
},
handleSaveRecord: function(component, event, helper) {
  //  if(helper.validateContactForm(component)) {
        component.set("v.simpleNewCustomerActivity.RecordType ", '0120l000000LPGRAA4');
        component.set("v.simpleNewCustomerActivity.Social_Campaign__c", 'a700l0000004EgyAAE');
        component.find("customerActivityRecordCreator").saveRecord(function(saveResult) {
            if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
                // record is saved successfully
                var resultsToast = $A.get("e.force:showToast");
                if(resultsToast!=undefined){
                resultsToast.setParams({
                    "title": "Saved",
                    "message": "The record was saved."
                });
                resultsToast.fire();
                 //Call Event to inform main component to refresh the view
    var handleCustomerActivityRefreshListEvent = component.getEvent("handleCustomerActivityRefreshListEvent");
    handleCustomerActivityRefreshListEvent.setParams({
        "refreshParentView" : true,
    });
    handleCustomerActivityRefreshListEvent.fire();
            }
            } else if (saveResult.state === "INCOMPLETE") {
                // handle the incomplete state
                console.log("User is offline, device doesn't support drafts.");
            } else if (saveResult.state === "ERROR") {
                // handle the error state
                console.log('Problem saving contact, error: ' + 
                             JSON.stringify(saveResult.error));
            } else {
                console.log('Unknown problem, state: ' + saveResult.state +
                            ', error: ' + JSON.stringify(saveResult.error));
            }
        });
   // }
    /*
    component.find("recordEditor").saveRecord($A.getCallback(function(saveResult) {
        if (saveResult.state === "SUCCESS" || saveResult.state === "DRAFT") {
            console.log("Save completed successfully.");
            component.set("v.isEdit",false);
        } else if (saveResult.state === "INCOMPLETE") {
            console.log("User is offline, device doesn't support drafts.");
        } else if (saveResult.state === "ERROR") {
            console.log('Problem saving record, error: ' + 
                        JSON.stringify(saveResult.error));
        } else {
            console.log('Unknown problem, state: ' + saveResult.state + ', error: ' + JSON.stringify(saveResult.error));
        }
    })); 
    */
},

handleRecordUpdated: function(component, event, helper) {
    var eventParams = event.getParams();
    if(eventParams.changeType === "CHANGED") {
        // get the fields that are changed for this record
        var changedFields = eventParams.changedFields;
        console.log('Fields that are changed: ' + JSON.stringify(changedFields));
        // record is changed so refresh the component (or other component logic)
        var resultsToast = $A.get("e.force:showToast");
        if(resultsToast!=undefined){
            resultsToast.setParams({
            "title": "Saved",
            "message": "The record was updated."
        });
        resultsToast.fire();
        }
        //Call Event to inform main component to refresh the view
    var handleCustomerActivityRefreshListEvent = component.getEvent("handleCustomerActivityRefreshListEvent");
    handleCustomerActivityRefreshListEvent.setParams({
        "refreshParentView" : true,
    });
    handleCustomerActivityRefreshListEvent.fire(); 

    } else if(eventParams.changeType === "LOADED") {
        console.log("Record is loaded successfully.");
    } else if(eventParams.changeType === "REMOVED") {
        var resultsToast = $A.get("e.force:showToast");
        resultsToast.setParams({
            "title": "Deleted",
            "message": "The record was deleted."
        });
        resultsToast.fire();
        helper.hideModal(component);
    } else if(eventParams.changeType === "ERROR") {
        console.log('Error: ' + component.get("v.error"));
    }
},
openCustomerActivityDetailViewer : function(component, event, helper){
    var params = event.getParam('arguments');
    console.log("customerTask: " + params.customerTaskRecord);
    
    component.set("v.iconName", params.objectIcon);
    //component.set("v.customerTaskRecordData", params.customerTaskRecord);
    // component.set("v.record", params.customerTaskRecord);
    component.set("v.recordId", params.customerTaskRecord.id);
    
    //component.set("v.customerTask", params.isModelPopUpOpen);
    helper.showModal(component);
    return "search complete.";
},
closeCustomerTaskDetailView : function(component, event, helper){
    helper.hideModal(component);
    component.set("v.isEdit1", false);
    component.set("v.recordId", '');
},
editCustomerTaskDetailView : function(component, event, helper){
    //alert('testing edit2222222222');
    component.set("v.showSpinner", false);
    
}  
,
handleSubmit : function(component, event, helper){
    component.set("v.showSpinner", true);
   // component.find("createActivityForm").submit();
    
} 
,
handleSuccess : function(component, event, helper){
   // alert('testing edit4');
    component.set("v.showSpinner", false);
    //Call Event to inform main component to refresh the view
    var handleCustomerActivityRefreshListEvent = component.getEvent("handleCustomerActivityRefreshListEvent");
    handleCustomerActivityRefreshListEvent.setParams({
        "refreshParentView" : true,
    });
    handleCustomerActivityRefreshListEvent.fire();
    
} ,
handleLoad: function(component, event, helper){
    //alert('testing edit load');
    component.set("v.showSpinner", false); 
    var type=component.find('type').get("v.value");
    component.find("comments").set("v.value", '');

        var typeCommentsmap = component.get("v.mapOfTypeAndComments");
        if(typeCommentsmap!=undefined){
            var value;
            Object.keys(typeCommentsmap).forEach(function(key) {
                value = typeCommentsmap[key];
                if(key==type){
                    component.find("comments").set("v.value", value);
                }
            });
        }
       
    
    
}
,
handleError: function(component, event, helper){
    console.log('Inside Error handling');
    component.set("v.showSpinner", false);
    var eventName = event.getName();
    var eventDetails = event.getParam("error");
    console.log('Error Event received' + eventName);
    
},
    onChange: function (cmp, evt, helper) {
        alert(cmp.find('select').get("v.value"));
    },
    getComments : function (component, event, helper){
        var type=component.find('type').get("v.value");
        var typeCommentsmap = component.get("v.mapOfTypeAndComments");
        var value;
        component.find("comments").set("v.value", '');
        if(typeCommentsmap!=undefined){
            Object.keys(typeCommentsmap).forEach(function(key) {
                value = typeCommentsmap[key];
                if(key==type){
                    component.find("comments").set("v.value", value);                
                }
            });
        }
        

    } 
})
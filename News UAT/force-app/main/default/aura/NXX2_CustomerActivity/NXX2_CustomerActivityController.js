({
	loadDetails : function(component,event,helper){
        //Call Event to inform main component to open file preview
        var handleCustomerActivitiesDetailView = component.getEvent("handleCustomerActivitiesDetailView");
         handleCustomerActivitiesDetailView.setParams({
            "customerTask" : component.get("v.customerTask"),
            "closeTaskViewer" : true
         });
		handleCustomerActivitiesDetailView.fire();
    },
    handleMenuSelect : function(component,event,helper){
        var selectedMenuItemValue = event.getParam("value");
        if(selectedMenuItemValue == 'Completed'){
            helper.markStatusCompleted(component,event,helper);
        }else if(selectedMenuItemValue == 'Edit'){
            helper.editActivityDetails(component);
        }else{
            helper.resendToCustomer(component);
        }
    },
    redirectToProofPage : function(component, event, helper){
      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
        "recordId": component.get("v.customerTask.Social_Campaign__c")
        });
      navEvt.fire();
      
    },
    showActivityDetails : function(component, event, helper){
        var modalBody;
        $A.createComponent("c:NXX2_CustomerActivityDetails", {recordId : component.get("v.customerTask").Id},
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   modalBody = content;
                                   component.find('overlayLib').showCustomModal({
                                       header: "Customer Activity",
                                       body: modalBody, 
                                       showCloseButton: true
                                   });
                               }                               
                           });
    },
    redirectToAccountPage : function(component, event, helper){
      var navEvt = $A.get("e.force:navigateToSObject");
      navEvt.setParams({
        "recordId": component.get("v.customerTask.Account__c")
        });
      navEvt.fire();
      
    }
})
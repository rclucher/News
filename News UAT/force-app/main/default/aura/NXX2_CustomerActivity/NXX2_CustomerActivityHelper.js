({
	markStatusCompleted : function(component,event,helper) {
		var taskId = component.get("v.customerTask.Id");
		var action = component.get("c.updateCustomerTaskStatus"); 
        action.setParams({
            customerTaskId : component.get("v.customerTask.Id")
       });
        action.setCallback(this, function(a) {
			component.set("v.customerTask.Status__c",'Completed');
        });
        $A.enqueueAction(action); 
	},
    resendToCustomer : function(component) {
		var action = component.get("c.resendMailForActivity"); 
        action.setParams({
            activity : component.get("v.customerTask")
       });
        action.setCallback(this, function(a) {
			component.find('notifLib').showNotice({
                "variant": "info",
                "header": "Operation Successful!",
                "message": "The customer activity has been sent to customer again."
            });
        });
        $A.enqueueAction(action); 
	},
    editActivityDetails : function(component){
      var modalBody;
        $A.createComponent("c:NXX2_CustomerActivityDetails", {recordId : component.get("v.customerTask").Id,editing : true},
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
    }
})
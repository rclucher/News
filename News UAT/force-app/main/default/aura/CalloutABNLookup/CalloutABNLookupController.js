({
    doInit: function(component, event, helper) {
        
        var action = component.get("c.ValidateABN");
        var id = component.get("v.recordId");
        //alert('v.recordId ' + id);
        action.setParams({ acctId: id });

        // Create a callback that is executed after 
        // the server-side action returns
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(state);

            var resultsToast = $A.get("e.force:showToast");

            if (state === "SUCCESS") {
                // Alert the user with the value returned 
                // from the server
                //alert("From server: " + response.getReturnValue());
                var acc = response.getReturnValue();

                if (acc != null) {
                    console.log("acc " + acc);
                    // You can set a new property on a copy
                    var accT = JSON.parse(JSON.stringify(acc));
                    console.log("accT parse " + accT);
                    
                    var ABN = accT.AccountNumber;
                    var status = accT.ABN_Status__c;
                    var toastType = "success";
                    
                    if (status === "Invalid ABN Number") {
                        toastType = "error";
                    }

                    var title = "Validate ABN: " + ABN;
                    var message = "ABN Status: " + status;
                    
                    helper.showToastDialog(title,toastType,message);
                }

                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();
                $A.get('e.force:refreshView').fire();

                //helper.showToastDialog('hello','succes','message goes here');

                // You would typically fire a event here to trigger 
                // client-side notification that the server-side 
                // action is complete
            } else if (state === "INCOMPLETE") {
                // do something
            } else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " +
                            errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });

     	$A.get("e.force:closeQuickAction").fire();
        $A.get('e.force:refreshView').fire();
        $A.enqueueAction(action);
    }
   
})
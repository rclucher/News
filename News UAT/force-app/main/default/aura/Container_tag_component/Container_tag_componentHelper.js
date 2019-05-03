({
    updateStatus : function(component , event) {
        var action = component.get("c.containertagmethod"),
		orderId = component.get("v.recordId");
        action.setParams({ "OrderId" : orderId });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            var flag = response.getReturnValue();
			console.log('tu sam 2');
            if (state === "SUCCESS") {
                  if(flag != null){
                      alert(flag);
                  } else {
               		alert('Container tag process has been initiated');  
                  }
        
            }
            else if (state === "INCOMPLETE") {
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                } else {
                    console.log('Burek');
                }
        });
        var close = $A.get("e.force:closeQuickAction"); 
           close.fire();
               $A.enqueueAction(action);

            

          $A.get('e.force:refreshView').fire();    

  
    }
    
})
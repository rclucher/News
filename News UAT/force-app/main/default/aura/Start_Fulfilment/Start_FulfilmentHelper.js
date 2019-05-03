({
    updateStatus : function(cmp , event) {
        var action = cmp.get("c.Start_Fulfilment_mtd");
        action.setParams({ OrderId : cmp.get("v.recordId") });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
              var flag= response.getReturnValue();  
              alert(flag);       
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
                }
        });
        
        var close = $A.get("e.force:closeQuickAction"); 
        close.fire();
        $A.enqueueAction(action);
        $A.get('e.force:refreshView').fire();    

  
    }
    
})
({
    updateStatus : function(cmp , event) {
        var action = cmp.get("c.updateOrder");
        var flag = false;
        action.setParams({ OrderId : cmp.get("v.recordId") });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            flag = response.getReturnValue();
            
            if (state === "SUCCESS") {
            
                
                  if(flag == true){
              alert('Campaign Status is already "Return Campaign to Sales"');
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
                }
        });
        var close = $A.get("e.force:closeQuickAction"); 
        close.fire();
        $A.enqueueAction(action);
        $A.get('e.force:refreshView').fire();    
    },
    // NXRIII-347 Begins
    initClass : function(cmp , event){
        //call apex class method
        var action = cmp.get('c.initClass');
        action.setParams({ OrderId : cmp.get('v.recordId') });
        action.setCallback(this,function(response){
        //store state of response
        var state = response.getState();
        if (state === "SUCCESS") {
            //set response value in objClassController attribute on component
            cmp.set('v.objClassController', response.getReturnValue());
               }
        });
        $A.enqueueAction(action);
    }
    // NXRIII-347 Ends
    
})
({
    //function to call schedulePayments from the Client-Side Controller to the Server-Side Controller
    "schedulePayments": function(cmp){
        var action = cmp.get("c.schedulePayment");
        action.setParams({OpportunityId : cmp.get("v.recordId")});
        action.setCallback(this, function(response){
            var state = response.getState();   
            //alert(state);
            if(state==="SUCCESS"){
                cmp.set("v.messageType", 'success');
                var retval = response.getReturnValue();
                if (retval=='Successful')
                {
                	cmp.set("v.message",'Update Order Payment - Succesfull!');                    
                }
                else
                {
                    cmp.set("v.message",retval);
                }
            }else{
                //alert("Not successful");
                cmp.set("v.messageType", 'error');
                cmp.set("v.message",response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
        /*
        var close = $A.get("e.force:closeQuickAction"); 
		close.fire();
        */
    },
    
    /*openModel: function(component, event, helper) {
        component.set("v.isOpen", true);
    },
    
    closeModel: function(component, event, helper) {
        component.set("v.isOpen", false);
        var close = $A.get("e.force:closeQuickAction"); 
        close.fire(); 
        
    },
    
    doUpdate: function(component, event, helper) {
        
        component.set("v.isOpen", false);
        helper.updateStatus(component , event);
        
    },*/
})
({
    getProofsForAccount : function(component, event, helper){
        var action = component.get("c.getProofsForAccount"); 
        action.setParams({ 
            "accountId" : component.get('v.recordId')
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if(state == 'SUCCESS') {
                component.set("v.proofList", response.getReturnValue());
            }else{
                
            }
            component.set('v.Spinner',false);
        });
        $A.enqueueAction(action); 
    }
})
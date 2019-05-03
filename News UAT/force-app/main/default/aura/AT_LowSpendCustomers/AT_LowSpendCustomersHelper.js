({
	getSpending : function(component) {
		// get current userId        
		var listSize = component.get("v.listSize");
        
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        //console.log('Current userid ' + userId);
        
        var action = component.get('c.getSpending');
        action.setParams({ ownerID : userId, count: listSize});
        
        //console.log('Low Spend Customers params: ');
        //console.log({ ownerID : userId, count: listSize});
        
        action.setCallback(this, $A.getCallback(function (response) {

            var state = response.getState();
            //console.log('Low Spend Customers response: ' + state);
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                
                //cmp.set('v.mydata', response.getReturnValue());
                //console.log('Low Spend Customers: ');
              	//console.log(response.getReturnValue());
                
                component.set("v.spendingData", data);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(errors);
            }
            
            component.set('v.loading', false);
        }));
        //console.log('enqueuing action');
        $A.enqueueAction(action);
        //console.log('action queued');
	}
})
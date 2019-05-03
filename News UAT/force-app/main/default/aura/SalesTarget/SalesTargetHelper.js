({
	getData : function(cmp) {
		// get current userId        
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        console.log('Current userid ' + userId);
        
        var action = cmp.get('c.getRevenueForecast');
        action.setParams({ ownerId : userId});
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var data = response.getReturnValue();
                
              	console.log(response.getReturnValue());
                
                cmp.set("v.total", data.Total);
                cmp.set("v.targetData", data.targets);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(errors);
            }
        }));
        $A.enqueueAction(action);
	}
})
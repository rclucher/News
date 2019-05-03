({
	createOpportunity : function(component) {

		var action = component.get("c.createOpportunity");

		action.setParams({ accountId : component.get("v.recordId") });

		action.setCallback(this, function(response) {

			var state = response.getState();

			if (state === "SUCCESS") {

				var opportunityId = response.getReturnValue();
				console.log("opportunityId:", opportunityId);

				var urlEvent = $A.get("e.force:navigateToURL");

				urlEvent.setParams({
					"url": "/apex/csmso__OpportunitySalesOrderActions?id="+opportunityId
				});

				urlEvent.fire();
			}
			else if (state === "ERROR") {

				var errors = response.getError();

				if (errors) {
					if (errors[0] && errors[0].message) {
						console.log("Error message: " + errors[0].message);
					}
				} 
				else {
					console.log("Unknown error");
				}
			}
		});

		$A.enqueueAction(action);
	}
})
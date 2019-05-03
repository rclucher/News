({
	doInit : function(component, event, helper) {

		var isFieldSet = component.get("v.isFieldSet");

		if (isFieldSet == true) {

			var action = component.get("c.getFieldSet");

			action.setParams({ 
				sObjectName : component.get("v.sObjectName"),
				fieldsetName : component.get("v.field")
			});

			action.setCallback(this, function(response) {

				var state = response.getState();

				if (state === "SUCCESS") {
					
					var fields = response.getReturnValue();

					console.log("fields", fields);

					component.set("v.fields", fields);
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

			$A.enqueueAction(action);
		}
	}
})
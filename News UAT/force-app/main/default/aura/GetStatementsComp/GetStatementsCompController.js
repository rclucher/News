({
	doInit : function(component, event, helper) {

		var action = component.get("c.accessComputershare");

		action.setParams({ recordId : component.get("v.recordId") });

		action.setCallback(this, function(response) {

			var state = response.getState();

			if (state === "SUCCESS") {

				var token = response.getReturnValue();

//				console.log("token", token);

				token = token.replace(/(\r\n|\n|\r)/gm,"");
				component.set("v.token", token);

				window.setTimeout(
					$A.getCallback(function(component) {
						document.TokenLoginForm.submit();
						$A.get("e.force:closeQuickAction").fire();
						}), 10
				);

/*
				setTimeout(function(component) {
					document.TokenLoginForm.submit();
					$A.get("e.force:closeQuickAction").fire();
				}, 10);
				*/
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
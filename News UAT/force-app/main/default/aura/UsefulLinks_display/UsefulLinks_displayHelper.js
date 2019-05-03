({
      // Fetch the Useful Links from the Apex controller
      getUsefulLinkList: function(component) {
        var action = component.get('c.getUsefulLinks');
          action.setParams({
        	HomePageRef : component.get("v.HomePageRef")
	    	});

        // Set up the callback
        var self = this;
        action.setCallback(this, function(actionResult) {
         component.set('v.usefullinks', actionResult.getReturnValue());
        });
        $A.enqueueAction(action);
      }
    })
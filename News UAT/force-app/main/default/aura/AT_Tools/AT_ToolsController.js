({
	openIncentiveCalculator: function(component, event, helper) {
		var evt = $A.get("e.force:navigateToComponent");
        evt.setParams({
            componentDef : "c:AT_IncentiveTool"
        });
        evt.fire();
	},
	openQuickQuote: function(component, event, helper) {
    	var evt = $A.get("e.force:navigateToComponent");
    	evt.setParams({
        	componentDef : "c:AT_QuickQuote",
    	});
    	evt.fire();
	//component.set("v.showQuickQuote", true);
	},
    closeQuickQuote: function(component, event, helper) {
        component.set("v.showQuickQuote", false);
	}
})
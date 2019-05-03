({
	doInit: function(component, event, helper) {
		var headings = component.get('v.headings');
        
        if (headings) component.set('v.headingCount', headings.length);
	}
})
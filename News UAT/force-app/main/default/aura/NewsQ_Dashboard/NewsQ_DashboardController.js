({
	afterScriptsLoaded: function(component, event, helper) {
        var username = component.get("v.pageReference").state.username;
        
        helper.loadForUsername(component, helper, (username == undefined) ? null : username);
	}
})
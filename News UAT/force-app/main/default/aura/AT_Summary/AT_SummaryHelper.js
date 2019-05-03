({
	getSummary: function(component, helper, configNames, index) {
        if (index >= configNames.length) return;
        
		var action = component.get('c.getSummary');
        
        action.setParams({
            configName: configNames[index]
        });
            
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state == 'SUCCESS') {
                var configs = component.get('v.configs');

                var config = response.getReturnValue();
                
                //if (config.title == 'Customer Account Credit Status') config.class = 'selected';
                
                configs.push(config);
                
                component.set('v.configs', configs);
                
                if (config.count > 0) {
                    component.set('v.selectedConfig', config.name);
                }
                
                helper.getSummary(component, helper, configNames, index + 1);
            }
        });
        
        $A.enqueueAction(action);
	}
})
({
	doInit: function(component, event, helper) {
        var configList = component.get('v.configList');
        
        if (configList && configList.trim()) {
            var configNames = configList.split(',');
            
            component.set('v.configNames', configNames);
            component.set('v.configCount', configNames.length);
            component.set('v.width', (configNames.length / 100));
            
            if (configNames) {
                //for (var i = 0; i < configNames.length; i++) {
                    helper.getSummary(component, helper, configNames, 0);
                //}
            }
        }
        
		//var action = component.get('c.getConfigs');
            
        //action.setCallback(this, function(response) {
            //var state = response.getState();
            
            //if (state == 'SUCCESS') {
                //var configNames = response.getReturnValue();
                
            //}
        //});
        
        //$A.enqueueAction(action);
	},
    select: function(component, event, helper) {
        component.set('v.selectedConfig', null);
        
        var configName = event.getSource().get("v.name");
        var configs = component.get('v.configs');

        component.set('v.selectedConfig', configName);

        if (configs && (configs.length > 0)) {
            for (var i = 0; i < configs.length; i++) {
                if (configName == configs[i].name) {
                    component.set("v.allowViewAll", !configs[i].compactOnly);
                    break;
                }
            }
        }
        
        //$A.get("e.force:refreshView").fire();
    },
    viewAll: function(component, event, helper) {
        var fullView = $A.get("e.force:navigateToComponent");
        fullView.setParams({
            componentDef : "c:AT_ListView",
            componentAttributes: {
                mode: 'full',
                config: component.get('v.selectedConfig'),
                pageSize: 20,
                maxCount: 50000,
            }
        });
        fullView.fire();
    }
})
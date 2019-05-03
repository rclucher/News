({
	doInit : function(component, event, helper) {
        var action = component.get("c.getIconName");
        action.setParams({ "sObjectName" : component.get("v.sObjectName") });
        action.setCallback(this, function(response) {
           component.set("v.iconName", response.getReturnValue() );
           helper.getSocialAddHistoryRecords(component, event, helper);
        });
        $A.enqueueAction(action);     
        
    },
})
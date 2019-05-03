({
    doInit : function(component, event, helper) {
        var action = component.get("c.getCommunityBaseUrl");
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                component.set('v.communityBaseUrl',actionResult.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    }
})
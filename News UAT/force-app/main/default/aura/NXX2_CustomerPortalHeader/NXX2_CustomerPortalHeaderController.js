({
	handleSelect : function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        if(selectedMenuItemValue == 'Home'){
            window.location.replace(component.get('v.communityBaseUrl') + "/s/");
        }else if(selectedMenuItemValue == 'Logout'){
            window.location.replace(component.get('v.communityBaseUrl') + "/secur/logout.jsp");
        }else if(selectedMenuItemValue == 'ChangePassword'){
            var modalBody;
            $A.createComponent("c:NXX2_ChangePortalUserPassword", {},
                               function(content, status) {
                                   if (status === "SUCCESS") {
                                       modalBody = content;
                                       component.find('overlayLib').showCustomModal({
                                           body: modalBody, 
                                           showCloseButton: true
                                       }).then(function (overlay) {
                                           
                                       });
                                   }                               
                               });
        }
	},
    doInit : function(component, event, helper){
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
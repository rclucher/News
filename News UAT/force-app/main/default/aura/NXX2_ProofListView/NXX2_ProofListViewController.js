({
	doInit : function(component, event, helper) {
        component.set('v.Spinner',true);
        var action = component.get("c.getIconName");
        action.setParams({ "sObjectName" : 'SocialCampaign__c' });
        action.setCallback(this, function(response) {
           component.set("v.iconName", response.getReturnValue() );
           helper.getProofsForAccount(component, event, helper);
        });
        $A.enqueueAction(action);  
    },
	redirectToProofPage : function(component, event, helper){
        var proofId = event.currentTarget.dataset.proofid;
		var navEvt = $A.get("e.force:navigateToSObject");
		navEvt.setParams({
			"recordId": proofId
			});
		navEvt.fire();
		
	}
})
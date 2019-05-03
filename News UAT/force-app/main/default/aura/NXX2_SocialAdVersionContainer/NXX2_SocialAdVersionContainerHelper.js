({
	populateAllAds : function(component,helper) {
		var action = component.get("c.getAllVersionForSocialAd");
        action.setParams({
            parentSocialAdId : component.get("v.parentSocialAdId")
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                var rawData = actionResult.getReturnValue();
                var allAds = [];
                for(var i =0;i< rawData.length;i++){
                    allAds.push(rawData[i].socialAd);
                    allAds[i].loadingDetails = true;
                }
                component.set('v.allAds', allAds);
                component.set('v.displaySpinner', false);
                helper.fetchAdContent(component,helper,0,allAds);
            }else{
                var errors = actionResult.getError();
                component.set('v.displaySpinner', false);
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        component.set("v.message",errors[0].message);
                    }
                }
            }
        });
        $A.enqueueAction(action);
	},
    fetchAdContent : function(component,helper,index,allAds) {
        if(index < allAds.length){
            var action = component.get("c.getContentForSocialAd");
            action.setParams({
                socialAdRecordId : allAds[index].Id,
                parentSocialAd : allAds[index].Parent_Social_Ad__c
            });
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if(state == 'SUCCESS') {
                    var rawData = actionResult.getReturnValue();
                    allAds[index].uploadedFiles = rawData;
                    allAds[index].loadingDetails = false;
                    component.set('v.allAds', allAds);
                    helper.fetchAdContent(component,helper,index + 1,allAds);
                }else{
                    var errors = actionResult.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            component.set("v.message",errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action);
        }
	}
})
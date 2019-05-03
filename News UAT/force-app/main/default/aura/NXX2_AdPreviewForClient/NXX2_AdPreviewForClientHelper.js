({
	getUserDetails : function(component) {
        return new Promise(function(resolve, reject) {
            var action = component.get("c.isExternalUser"); 
            action.setCallback(this, function(actionResult) {
                var state = actionResult.getState();
                if(state == 'SUCCESS') {
                    component.set('v.isExternalUser', actionResult.getReturnValue());
                    resolve.call(this, actionResult.getReturnValue());
                }else{
                    var errors = actionResult.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            component.set("v.message",errors[0].message);
                            reject.call(this, errors[0].message);
                        }
                    }
                }
            });
            $A.enqueueAction(action); 
        });
	},
    populateAllAds : function(component,helper) {
		var action = component.get("c.getAllAds");
        //var params = helper.getURLParameters();
        action.setParams({
            campaignOrderId : component.get("v.recordId")//params.campaignId
        });
        action.setCallback(this, function(actionResult) {
            var state = actionResult.getState();
            if(state == 'SUCCESS') {
                var rawData = actionResult.getReturnValue();
                var allAds = [];
                for(var i =0;i< rawData.length;i++){
                    rawData[i].socialAd.socialForm = rawData[i].socialForm;
                    allAds.push(rawData[i].socialAd);
                    allAds[i].loadingDetails = true
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
        }else{
            helper.fetchFormContent(component,helper,0,allAds);
        }
    },
    fetchFormContent : function(component,helper,index,allAds) {
        if(index < allAds.length){
            if(!$A.util.isUndefined(allAds[index].socialForm)){
                var action = component.get("c.getContentForSocialAd");
                action.setParams({
                    socialAdRecordId : allAds[index].socialForm.Id,
                    parentSocialAd : allAds[index].socialForm.Parent_Social_Ad__c
                });
                action.setCallback(this, function(actionResult) {
                    var state = actionResult.getState();
                    if(state == 'SUCCESS') {
                        var rawData = actionResult.getReturnValue();
                        allAds[index].socialForm.uploadedFiles = rawData;
                        allAds[index].socialForm.loadingDetails = false;
                        component.set('v.allAds', allAds);
                        helper.fetchFormContent(component,helper,index + 1,allAds);
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
            }else{
                helper.fetchFormContent(component,helper,index + 1,allAds);
            }
        }
	},
    getURLParameters : function(component) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split('&'),
            sParameters = {},
            i;
        for (i = 0; i < sURLVariables.length; i++) {
            var sParameterList = sURLVariables[i].split('=');
            sParameters[sParameterList[0]] = sParameterList[1];
        }
        return sParameters;
	}
})
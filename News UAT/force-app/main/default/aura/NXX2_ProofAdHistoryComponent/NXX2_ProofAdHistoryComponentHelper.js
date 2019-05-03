({
    getSocialAddHistoryRecords : function(component, event, helper){
        var socialAdHistoryAction = component.get("c.getSocialAdHistory"); 
        socialAdHistoryAction.setParams({ "ParentId" : component.get("v.ParentId") });
        socialAdHistoryAction.setCallback(this, function(socialAdHistoryListResult) {
            var state = socialAdHistoryListResult.getState();
            if(state == 'SUCCESS') {
                var socialAdHistoryData = socialAdHistoryListResult.getReturnValue();
                component.set("v.socialAdHistoryList", socialAdHistoryData);
            }
            component.set("v.displaySpinner", false);
        });
        $A.enqueueAction(socialAdHistoryAction); 
    }
})
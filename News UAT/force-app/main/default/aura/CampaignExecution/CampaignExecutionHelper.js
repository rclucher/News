({
    getCampaignState: function(cmp, userId, campaignId) {

        var action = cmp.get('c.getCampaignState');
        var campaignId = cmp.get("v.recordId");
        action.setParams({
            "campaignId": campaignId
        });
        var retStr = {};
        var campaign = {};

        action.setCallback(this, function(response) {
            retStr = response.getReturnValue();
            console.log(retStr);

            campaign = JSON.parse(JSON.stringify(retStr));
            console.log(campaign.Status);

            // Call the UserHasEditAccess check

            this.getUserHasEditAccess(cmp, userId, campaignId, campaign);
        });

        $A.enqueueAction(action);

    },
    getUserHasEditAccess: function(cmp, userId, campaignId, Campaign) {
        
        // create a one-time use instance of the userHasEditAccess action
        // in the server-side controller
        var action = cmp.get("c.userHasEditAccess");
        action.setParams({
            UserId: userId,
            RecordId: campaignId
        });

        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var retStr = response.getReturnValue();

                if (retStr == true) {

                    if (Campaign.Status == 'Launched' && Campaign.IsActive == true) {
                        if (typeof(srcUp) == 'function') {
                            srcUp("/apex/Campaign?id={!Campaign.Id}&isdtp=vw");

                        // } else {
                        //     //window.location = "/apex/Campaign?id={!Campaign.Id}";

                        //     var urlEvent = $A.get("e.force:navigateToURL");
                        //     urlEvent.setParams({
                        //         "url": ("/apex/Campaign?id=" + campaignId),
                        //         // "url": ("/apex/CampaignActionPage?id=00v0l000001IEYkAAO"),
                        //         "isredirect": "true"
                        //     });
                        //     urlEvent.fire();
                        // }
                       } else {
                                var evt = $A.get("e.force:navigateToComponent");
                                evt.setParams({
                                    componentDef : "c:CampaignExecutionComp",
                                    componentAttributes: {
                                        recordId : campaignId
                                    }
                                });
                                evt.fire();
                                // }
                        }

                    } else if (Campaign.Status != 'Launched' && !Campaign.IsActive != true) {
                        alert("Campaign is not Launched and not Active!");
                    } else if (Campaign.Status != 'Launched') {
                        alert("Campaign is not Launched!");
                    } else if (Campaign.IsActive != true) {
                        alert("Campaign is not Active!");
                    } else {
                        alert("Unable to access Campaign Execution!");
                    }
                } else {
                    alert("You have no access to Campaign Execution!"); 
                }
            }
        });
        
        $A.get("e.force:closeQuickAction").fire();
        $A.enqueueAction(action);
    }
})
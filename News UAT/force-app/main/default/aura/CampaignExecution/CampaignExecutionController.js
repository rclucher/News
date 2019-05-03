({
    doInit: function(cmp, event, helper) {

        var campaignId = cmp.get("v.recordId");
        var userId = $A.get("$SObjectType.CurrentUser.Id");
        console.log(userId);

        var callback = {};
        helper.getCampaignState(cmp, userId, campaignId);
        document.title = "Campaign Execution";
        //sforce.console.setTabTitle('Campaign Execution');
    }
})
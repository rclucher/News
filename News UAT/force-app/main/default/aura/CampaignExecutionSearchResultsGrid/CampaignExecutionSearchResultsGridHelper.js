({
	openCampaignMemberSubTab: function (component, event, helper) {
        // var recordId = component.get("v.recordId");
        //var campaignMemberId = event.currentTarget.dataset.campaignMemberId;
        var etarget = event.currentTarget;
    	var campaignMemberId = etarget.dataset.campaignmemberid;
        console.log("CampaignExecutionSearchResultsGridHelper :: openCampaignMemberSubTab :: campaignMemberId :: ", campaignMemberId);
        var url = '/apex/CampaignActionPage2?Id=' + campaignMemberId;
        console.log("CampaignExecutionSearchResultsGridHelper :: openCampaignMemberSubTab :: url :: ", url);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
 	},
 	openContactLeadSubTab: function (component, event, helper) {
        var etarget = event.currentTarget;
    	var memberId = etarget.dataset.memberid;
        console.log("CampaignExecutionSearchResultsGridHelper :: openContactLeadSubTab :: memberId :: ", memberId);
        var url = '/' + memberId;
        console.log("CampaignExecutionSearchResultsGridHelper :: openContactLeadSubTab :: url :: ", url);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": url
        });
        urlEvent.fire();
 	},
 	checkColumnsVisibility : function(component){
 		var campaign = component.get("v.campaign");
 		var sColumnsvisibility = "";
 		console.log("CampaignExecutionSearchResultsGridHelper :: checkColumnsVisibility :: 1");
 		if(campaign){
 			sColumnsvisibility = campaign.Hide_Column_from_Campaign_Exec__c;
 		}
 		if(sColumnsvisibility == undefined){
 			sColumnsvisibility = "";
 		}
		var campaignMemberClassificationOption = component.get("v.campaignMemberClassificationOption");
		if(sColumnsvisibility.indexOf("Type")>=0){
			component.set("v.hideColumnType", true);
		}
		console.log("CampaignExecutionSearchResultsGridHelper :: checkColumnsVisibility :: 2");
		if(sColumnsvisibility.indexOf("Name")>=0){
			component.set("v.hideColumnName", true);
		}
		if(sColumnsvisibility.indexOf("Last Booking Value")>=0){
			component.set("v.hideColumnLast_Booking_Value", true);
		}
		if(sColumnsvisibility.indexOf("Last Booking Line Item Publication Divs")>=0){
			component.set("v.hideColumnLast_Booking_Line_Item_Publication_Divs", true);
		}
		if(sColumnsvisibility.indexOf("CompanyOrAccount")>=0){
			component.set("v.hideColumnCompanyOrAccount", true);
		}
		console.log("CampaignExecutionSearchResultsGridHelper :: checkColumnsVisibility :: 2.5");
		if(sColumnsvisibility.indexOf("In Progress")>=0 || campaignMemberClassificationOption == "MyCompleted" || campaignMemberClassificationOption == "AllCompleted"){
			component.set("v.hideColumnIn_Progress", true);
			component.set("v.hideColumnCall_Back_Date", true);
			component.set("v.hideColumnLocked_By", true);
		}
		console.log("CampaignExecutionSearchResultsGridHelper :: checkColumnsVisibility :: 3");
		if(sColumnsvisibility.indexOf("Call Count")>=0){
			component.set("v.hideColumnCall_Count", true);
		}
		if(sColumnsvisibility.indexOf("Execution Status")>=0){
			component.set("v.hideColumnExecution_Status", true);
		}
		if(sColumnsvisibility.indexOf("Status column")>=0){
			component.set("v.hideColumnStatus", true);
		}
		if(sColumnsvisibility.indexOf("Last Response Datetime")>=0){
			component.set("v.hideColumnLast_Response_Datetime", true);
		}
		// if(sColumnsvisibility.indexOf("In Progress")>=0 || campaignMemberClassificationOption == 'MyCompleted' || campaignMemberClassificationOption == 'AllCompleted'){
		// 	component.set("v.hideColumnCall_Back_Date", true);
		// }
		// if(sColumnsvisibility.indexOf("Type")>=0){
		// 	component.set("v.hideColumnLocked_By", true);
		// }
		if(sColumnsvisibility.indexOf("Age in List")>=0){
			component.set("v.hideColumnAge_in_List", true);
		}
		if(campaignMemberClassificationOption != "MyCompleted" && campaignMemberClassificationOption != "AllCompleted"){
			component.set("v.hideColumnCompleted_By", true);
			component.set("v.hideColumnCompleted_Date", true);
		}
		// if(sColumnsvisibility.indexOf("Type")>=0){
		// 	component.set("v.hideColumnCompleted_Date", true);
		// }
		if(sColumnsvisibility.indexOf("Created Date")>=0){
			component.set("v.hideColumnCreated_Date", true);
		}
		// console.log("CampaignExecutionSearchResultsGridHelper :: checkColumnsVisibility :: hideColumnCompleted_By :: ", component.get("v.hideColumnCompleted_By");
 	}
})
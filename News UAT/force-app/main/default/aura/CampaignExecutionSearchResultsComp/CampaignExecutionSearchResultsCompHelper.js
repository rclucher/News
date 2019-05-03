({
	initSearchResults : function(component) {
		//this.hasInProgressCampaignMember(component);
		this.onChooseClassification(component);
	},
	onChooseClassification: function(component) {		
		console.log('CampaignExecutionSearchResultsCompHelper :: onChooseClassification');
        var campaignMemberClassificationOption = component.get("v.campaignMemberClassificationOption");
        var campaignMembersGrid;
        console.log('CampaignExecutionSearchResultsCompHelper :: onChooseClassification :: campaignMemberClassificationOption :: ', campaignMemberClassificationOption);
        if(campaignMemberClassificationOption){
        	if(campaignMemberClassificationOption == 'NotStarted'){
        		campaignMembersGrid = component.get("v.campaignMembersNotStarted");
        	} else if(campaignMemberClassificationOption == 'MyCallsToDo'){
        		campaignMembersGrid = component.get("v.campaignMembersMyCallsToDo");
        	} else if(campaignMemberClassificationOption == 'AllCallsToDo'){
        		campaignMembersGrid = component.get("v.campaignMembersAllCallsToDo");
        	} else if(campaignMemberClassificationOption == 'MyCompleted'){
        		campaignMembersGrid = component.get("v.campaignMembersMyCompleted");
        	} else if(campaignMemberClassificationOption == 'AllCompleted'){
        		campaignMembersGrid = component.get("v.campaignMembersAllCompleted");
        	} else if(campaignMemberClassificationOption == 'All'){
        		campaignMembersGrid = component.get("v.campaignMembersAll");
        	} else { //ToDo
        		campaignMembersGrid = component.get("v.campaignMembersToDo");
        	} 
        }
        else{
        	campaignMembersGrid = component.get("v.campaignMembersToDo");
        }
        console.log('CampaignExecutionSearchResultsCompHelper :: onChooseClassification :: campaignMembersGrid :: ', campaignMembersGrid);
        component.set("v.campaignMembersGrid", campaignMembersGrid);	
	}
})
({
	initCampaignExecution : function(component) {

		console.log('CampaignExecutionCompHelper :: initCampaignExecution');
		var sFilterOptions = ["equals", "not equals to", "less than", "greater than", "less or equal", "greater or equal"];
		component.set("v.filterOptions", sFilterOptions);

		this.initExecutionStatus(component);
		this.initStatus(component);
		this.resetCampaignExecutionSearchWrapper(component);
		this.getCurrentUserId(component);

		var action = component.get("c.getCampaign");
        component.set("v.spinner", true);
        // this.fireRemoveAllAlertsEvent(component);
        var campaignId = component.get("v.recordId");
        console.log("CampaignExecutionCompHelper :: initCampaignExecution :: campaignId 1 :" + campaignId);
        
        console.log("CampaignExecutionCompHelper :: initCampaignExecution :: campaignId 2 :" + campaignId);
        action.setParams({
                "campaignId": campaignId
           });
      	action.setCallback(this, function(response) {
	        var state = response.getState();
	        console.log("state is:" + state);
	        console.log("CampaignExecutionCompHelper :: initCampaignExecution :: response.getReturnValue():" + response.getReturnValue());
	        if (component.isValid() && state === "SUCCESS") {
	            component.set("v.campaign", response.getReturnValue());
	            this.onSearch(component);
	            //this.initCampaignMemberClassification(component);
	        }
	        component.set("v.spinner", false);
        });
        $A.enqueueAction(action);

	},
	initExecutionStatus: function(component) {
		
		console.log('CampaignExecutionCompHelper :: initExecutionStatus');
        var action = component.get("c.getExecutionStatus");
        component.set("v.spinner", true);
        action.setCallback(this, function(response) {
	        var state = response.getState();
	        console.log("state is:" + state);
	        
	        if (component.isValid() && state === "SUCCESS") {
	            component.set("v.executionStatusList", response.getReturnValue());
	        }
	        component.set("v.spinner", false);
        });
        $A.enqueueAction(action);
	},
	initStatus: function(component) {
		console.log('CampaignExecutionCompHelper :: initStatus');
        var action = component.get("c.getStatus");
        component.set("v.spinner", true);
        
        action.setCallback(this, function(response) {
	        var state = response.getState();
	        console.log("state is:" + state);
	        if (component.isValid() && state === "SUCCESS") {
	            component.set("v.statusList", response.getReturnValue());
	        }
	        component.set("v.spinner", false);
        });
        $A.enqueueAction(action);
	},
	onSearch: function(component, event) {
		
		console.log('CampaignExecutionCompHelper :: getSearchResults');
		var campaign = component.get("v.campaign");
		console.log("CampaignExecutionCompHelper :: getSearchResults :: campaign:" + campaign);

		//Search Criteria Population
		var searchLead_Contact_Name = component.get("v.searchLead_Contact_Name");
		var searchCompanyOrAccount = component.get("v.searchCompanyOrAccount"); 
		var searchExecution_Status = component.get("v.searchExecution_Status"); 
		var searchLast_Booking_Line_Item_Publication_Divs = component.get("v.searchLast_Booking_Line_Item_Publication_Divs"); 
		var searchStatus = component.get("v.searchStatus"); 
		var filterCall_Count = component.get("v.filterCall_Count"); 
		var searchCall_Count = component.get("v.searchCall_Count"); 
		var filterAge_In_List = component.get("v.filterAge_In_List"); 
		var searchAge_In_List = component.get("v.searchAge_In_List"); 
		var filterLast_Booking_Value = component.get("v.filterLast_Booking_Value"); 
		var searchLast_Booking_Value = component.get("v.searchLast_Booking_Value"); 
		var filterResponse_DateTime = component.get("v.filterResponse_DateTime"); 
		var filterCall_Back_Date = component.get("v.filterCall_Back_Date"); 
		var searchCall_Back_Date = component.get("v.searchCall_Back_Date"); 
		var searchResponse_DateTime = component.get("v.searchResponse_DateTime"); 
		
		var campaignExecutionSearchWrapper = component.get("v.campaignExecutionSearchWrapper");
		campaignExecutionSearchWrapper.includeFilterOptions = false;

		if(searchLead_Contact_Name != undefined && searchLead_Contact_Name != ""){
			campaignExecutionSearchWrapper.searchLead_Contact_Name = searchLead_Contact_Name;
			campaignExecutionSearchWrapper.includeFilterOptions = true;
		}
		else{
				campaignExecutionSearchWrapper.searchLead_Contact_Name = "";
		}

		if(searchCompanyOrAccount != undefined && searchCompanyOrAccount != ""){
			campaignExecutionSearchWrapper.searchCompanyOrAccount = searchCompanyOrAccount;
			campaignExecutionSearchWrapper.includeFilterOptions = true;
		}
		else{
				campaignExecutionSearchWrapper.searchCompanyOrAccount = "";
		}
		if(searchExecution_Status != undefined && searchExecution_Status != ""){
			campaignExecutionSearchWrapper.searchExecution_Status = searchExecution_Status;
			campaignExecutionSearchWrapper.includeFilterOptions = true;
		}
		else{
				campaignExecutionSearchWrapper.searchExecution_Status = "";
		}
		if(searchLast_Booking_Line_Item_Publication_Divs != undefined && searchLast_Booking_Line_Item_Publication_Divs != ""){
			campaignExecutionSearchWrapper.searchLast_Booking_Line_Item_Publication_Divs = searchLast_Booking_Line_Item_Publication_Divs;
			campaignExecutionSearchWrapper.includeFilterOptions = true;
		}
		else{
				campaignExecutionSearchWrapper.searchLast_Booking_Line_Item_Publication_Divs = "";
		}
		if(searchStatus != undefined && searchStatus != ""){
			campaignExecutionSearchWrapper.searchStatus = searchStatus;
			campaignExecutionSearchWrapper.includeFilterOptions = true;
		}
		else{
				campaignExecutionSearchWrapper.searchStatus = "";
		}
		if(searchCall_Count != undefined && searchCall_Count != ""){
			campaignExecutionSearchWrapper.searchCall_Count = searchCall_Count;
			campaignExecutionSearchWrapper.filterCall_Count = filterCall_Count;
			campaignExecutionSearchWrapper.includeFilterOptions = true;
		}
		else{
				campaignExecutionSearchWrapper.searchCall_Count = "";
		}
		if(searchAge_In_List != undefined && searchAge_In_List != ""){
			campaignExecutionSearchWrapper.searchAge_In_List = searchAge_In_List;
			campaignExecutionSearchWrapper.filterAge_In_List = filterAge_In_List;
			campaignExecutionSearchWrapper.includeFilterOptions = true;
		}
		else{
				campaignExecutionSearchWrapper.searchAge_In_List = "";
		}
		if(searchLast_Booking_Value != undefined && searchLast_Booking_Value != ""){
			campaignExecutionSearchWrapper.searchLast_Booking_Value = searchLast_Booking_Value;
			campaignExecutionSearchWrapper.filterLast_Booking_Value = filterLast_Booking_Value;
			campaignExecutionSearchWrapper.includeFilterOptions = true;
		}
		else{
				campaignExecutionSearchWrapper.searchLast_Booking_Value = "";
		}
		if(searchCall_Back_Date != undefined && searchCall_Back_Date != ""){
			campaignExecutionSearchWrapper.searchCall_Back_Date = searchCall_Back_Date;
			campaignExecutionSearchWrapper.filterCall_Back_Date = filterCall_Back_Date;
			campaignExecutionSearchWrapper.includeFilterOptions = true;
		}
		else{
				campaignExecutionSearchWrapper.searchCall_Back_Date = null;
		}
		if(searchResponse_DateTime != undefined && searchResponse_DateTime != ""){
			campaignExecutionSearchWrapper.searchResponse_DateTime = searchResponse_DateTime;
			campaignExecutionSearchWrapper.filterResponse_DateTime = filterResponse_DateTime;
			campaignExecutionSearchWrapper.includeFilterOptions = true;
		}
		else{
				campaignExecutionSearchWrapper.searchResponse_DateTime = null;
		}
		
		console.log("CampaignExecutionCompHelper :: getSearchResults :: campaignExecutionSearchWrapper is:" + JSON.stringify(campaignExecutionSearchWrapper));
		//Search Criteria Population

        var action = component.get("c.getSearchResults");
        action.setParams({
            "campaign": campaign,
            "campaignExecutionSearchWrapperJSON" : JSON.stringify(campaignExecutionSearchWrapper),
            "sortField": '',
            "sortDir": ''
       });
        component.set("v.spinner", true);
      	action.setCallback(this, function(response) {
	        var state = response.getState();
	        console.log("state is:" + state);
	         console.log("CampaignExecutionCompHelper :: getSearchResults :: response.getReturnValue() is:" + JSON.stringify(response.getReturnValue()));
	        if (component.isValid() && state === "SUCCESS") {
	            component.set("v.campaignMemberListMap", response.getReturnValue());
	            campaignMemberListMap = component.get("v.campaignMemberListMap");
	            component.set("v.campaignMembersToDo", campaignMemberListMap["ToDo"]);
	            component.set("v.campaignMembersNotStarted", campaignMemberListMap["NotStarted"]);
	            component.set("v.campaignMembersMyCallsToDo", campaignMemberListMap["MyCallsToDo"]);
	            component.set("v.campaignMembersAllCallsToDo", campaignMemberListMap["AllCallsToDo"]);
	            component.set("v.campaignMembersMyCompleted", campaignMemberListMap["MyCompleted"]);
	            component.set("v.campaignMembersAllCompleted", campaignMemberListMap["AllCompleted"]);
	            component.set("v.campaignMembersAll", campaignMemberListMap["All"]);

	            component.set("v.campaignMembersGrid", campaignMemberListMap["ToDo"]);
	            this.initCampaignMemberClassification(component);
	        }
	        component.set("v.spinner", false);
        });
        $A.enqueueAction(action);        
	},
	onResetSearch: function(component, event) {
		component.set("v.searchLead_Contact_Name", "");
		component.set("v.searchCompanyOrAccount", ""); 
		component.set("v.searchExecution_Status", ""); 
		component.set("v.searchLast_Booking_Line_Item_Publication_Divs", ""); 
		component.set("v.searchStatus", ""); 
		component.set("v.filterCall_Count", "equals"); 
		component.set("v.searchCall_Count", ""); 
		component.set("v.filterAge_In_List", "equals"); 
		component.set("v.searchAge_In_List", ""); 
		component.set("v.filterLast_Booking_Value", "equals"); 
		component.set("v.searchLast_Booking_Value", ""); 
		component.set("v.filterResponse_DateTime", "equals"); 
		component.set("v.filterCall_Back_Date", "equals"); 
		component.set("v.searchCall_Back_Date", null); 
		component.set("v.searchResponse_DateTime", null); 
		this.resetCampaignExecutionSearchWrapper(component);
		this.onSearch(component);
	},
	initCampaignMemberClassification: function(component) {
		
		console.log('CampaignExecutionCompHelper :: initCampaignMemberClassification');
        var action = component.get("c.getCampaignMemberClassification");
        component.set("v.spinner", true);
      	action.setCallback(this, function(response) {
	        var state = response.getState();
	        console.log("state is:" + state);
	        //console.log("CampaignExecutionCompHelper :: initCampaignMemberClassification :: campaignMemberClassificationList ::" + JSON.stringify(response.getReturnValue()));
	        // console.log("CampaignExecutionCompHelper :: initCampaignMemberClassification :: component.isValid() ::" + component.isValid());
	        if (component.isValid() && state === "SUCCESS") {
	        	campaignMemberListMap = component.get("v.campaignMemberListMap");
	        	console.log("CampaignExecutionCompHelper :: initCampaignMemberClassification :: campaignMemberListMap ::" + JSON.stringify(campaignMemberListMap));
	        	campaignMemberClassificationList = response.getReturnValue();
	        	// console.log("CampaignExecutionCompHelper :: initCampaignMemberClassification :: campaignMemberClassificationList.length ::" + campaignMemberClassificationList.length);
	        	if(campaignMemberListMap){
		        	for(var i=0; i<campaignMemberClassificationList.length; i++){
		        		var campaignMemberList = campaignMemberListMap[campaignMemberClassificationList[i].optionValue];
		        		// console.log("CampaignExecutionCompHelper :: initCampaignMemberClassification :: campaignMemberList.length ::" + campaignMemberList.length);
		        		if(campaignMemberList.length > 0){
		        			campaignMemberClassificationList[i].optionLabel += ' (' + campaignMemberList.length + ')'; 
		        		}
		        	}
		        }
	            component.set("v.campaignMemberClassificationList", campaignMemberClassificationList);
	            this.hasInProgressCampaignMember(component);
	            //this.onChooseClassification(component);
	        }
	        component.set("v.spinner", false);
        });
        $A.enqueueAction(action);
	},
	getCurrentUserId: function(component) {
		
		console.log('CampaignExecutionCompHelper :: getCurrentUserId');
        var action = component.get("c.getCurrentUserId");
        component.set("v.spinner", true);
        action.setCallback(this, function(response) {
	        var state = response.getState();
	        console.log("state is:" + state);
	        if (component.isValid() && state === "SUCCESS") {
	            component.set("v.currentUserId", response.getReturnValue());
	        }
	        component.set("v.spinner", false);
        });
        $A.enqueueAction(action);
	},
	hasInProgressCampaignMember: function(component) {		
		console.log('CampaignExecutionCompHelper :: hasInProgressCampaignMember');
        var bInProgressCampaignMember = false;
        var currentUserId = component.get("v.currentUserId");
        campaignMembersAll = component.get("v.campaignMembersAll");
        console.log('CampaignExecutionCompHelper :: hasInProgressCampaignMember :: campaignMembersAll :: ', campaignMembersAll);
	    if(campaignMembersAll){
		    for(var i = 0; i<campaignMembersAll.length; i++){
		    	console.log('CampaignExecutionCompHelper :: hasInProgressCampaignMember :: campaignMembersAll[i] :: ', campaignMembersAll[i]);
		    	if(campaignMembersAll[i].Locked_By__c){
		    		console.log('CampaignExecutionCompHelper :: hasInProgressCampaignMember :: campaignMembersAll[i].Locked_By__c :: ', campaignMembersAll[i].Locked_By__c);
		    		console.log('CampaignExecutionCompHelper :: hasInProgressCampaignMember :: campaignMembersAll[i].Execution_Status__c :: ', campaignMembersAll[i].Execution_Status__c);

		    		if (campaignMembersAll[i].Locked_By__c == currentUserId && campaignMembersAll[i].Execution_Status__c != 'Call to Do'){		    			
		    			bInProgressCampaignMember = true;
		    			console.log('CampaignExecutionCompHelper :: hasInProgressCampaignMember :: bInProgressCampaignMember :: ', bInProgressCampaignMember);
		    			break;
		    		}
		    	}
		    }		    
		}
		component.set("v.bInProgressCampaignMember", bInProgressCampaignMember);
	},
	resetCampaignExecutionSearchWrapper: function(component) {
		
		console.log('CampaignExecutionCompHelper :: resetCampaignExecutionSearchWrapper');
        var action = component.get("c.resetCampaignExecutionSearchWrapper");
        component.set("v.spinner", true);
        action.setCallback(this, function(response) {
	        var state = response.getState();
	        console.log("state is:" + state);
	        if (component.isValid() && state === "SUCCESS") {
	            component.set("v.campaignExecutionSearchWrapper", response.getReturnValue());
	        }
	        component.set("v.spinner", false);
        });
        $A.enqueueAction(action);
	}//,
	// setFocusedTabTitle : function(component, event, helper) {
 //        var workspaceAPI = component.find("workspace");
 //        workspaceAPI.getFocusedTabInfo().then(function(response) {
 //            var focusedTabId = response.tabId;
 //                workspaceAPI.setTabIcon({
 //                tabId: focusedTabId,
 //                //icon: "action:campaign",
 //                //iconAlt: "Approval",
 //                title: "Campaign Execution"
 //            });
 //        })
 //        .catch(function(error) {
 //            console.log(error);
 //        });
 //    }
})
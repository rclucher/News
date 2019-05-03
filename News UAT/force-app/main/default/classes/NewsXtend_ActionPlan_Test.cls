@isTest (seeAllData=false)
private class NewsXtend_ActionPlan_Test {

    // 2015-07-23 louis.wang@bluewolf.com
    //    This class provides test coverage for 
    //		- NewsXtend_ActionPlan 			83%
    //		- NewsXtend_ActionPlan_Helper 	97%
    //		- ActionTask.trigger			89%
	public static Action_Plan__c actionPlan;
	public static Action_Plan__c actionPlan2;

	@testSetup
    public static void setup()
    {
    	actionPlan = new Action_Plan__c();
    	actionPlan.Start_Date__c = System.today();
    	actionPlan.Action_Plan_Period__c = '2 months';
    	insert actionPlan;

    	actionPlan2 = new Action_Plan__c();
    	insert actionPlan2;

		map<string,string> recordTypeMap = NewsXtend_ActionPlan_Helper.fetch_RecordTypeMap();

    	Action_Task__c at1 = new Action_Task__c();
    	at1.Action_Task_Group__c = 'Campaign Management';
    	at1.Action_Task_Sub_Group__c = 'Setup Task';
    	at1.Action_Task_Name__c = 'CampMgmt-Setup Step 1';
    	at1.Step_Number__c = 1;
    	at1.Due_Date_SLA__c = 12;
    	at1.RecordTypeId = recordTypeMap.get('Action_Task__c-Admin_Data');

    	Action_Task__c at2 = new Action_Task__c();
    	at2.Action_Task_Group__c = 'Campaign Management';
    	at2.Action_Task_Sub_Group__c = 'Setup Task';
    	at2.Action_Task_Name__c = 'CampMgmt-Setup Step 2';
    	at2.Step_Number__c = 2;
    	at2.Due_Date_SLA__c = 12;
    	at2.RecordTypeId = recordTypeMap.get('Action_Task__c-Admin_Data');

    	Action_Task__c at3 = new Action_Task__c();
    	at3.Action_Task_Group__c = 'Campaign Management';
    	at3.Action_Task_Sub_Group__c = 'Month-Month Task';
    	at3.Action_Task_Name__c = 'CampMgmt-Monthly Step 1';
    	at3.Step_Number__c = 1;
    	at3.Due_Date_SLA__c = 12;
    	at3.RecordTypeId = recordTypeMap.get('Action_Task__c-Admin_Data');

    	Action_Task__c at4 = new Action_Task__c();
    	at4.Action_Task_Group__c = 'Campaign Management';
    	at4.Action_Task_Sub_Group__c = 'Month-Month Task';
    	at4.Action_Task_Name__c = 'CampMgmt-Monthly Step 2';
    	at4.Step_Number__c = 2;
    	at4.Due_Date_SLA__c = 12;
    	at4.RecordTypeId = recordTypeMap.get('Action_Task__c-Admin_Data');

    	List<Action_Task__c> atList = new List<Action_Task__c>{at1, at2, at3, at4};
    	insert atList;

    	/* Queue is visible to test class, so no need to create
		Group q = new Group();
		q.Name = 'NewsXtend_Queue';
		q.DeveloperName = 'NewsXtend_Queue';
		q.Type = 'Queue';
		insert q;
		*/    	
    }

	static testMethod void populate_default_CampaignTasks_then_Save_test() 
	{
		// Scenario - user starts the Action Plan. Click Save to auto-create "General Data". 
		//				Then modify "Geneneral Data" then save.
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// populate default CampaignTasks
		PageReference pr2 = nap.click_Save_button();
		Test.setCurrentPage(pr2);
		ApexPages.StandardController ctr2 = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap2 = new NewsXtend_ActionPlan(ctr2);

		// modify action plan record and save
		nap2.campMgmt_Setup_List[0].Action_Task_Status__c = 'In Progress';
		nap2.campMgmt_Setup_List[0].OwnerId = UserInfo.getUserId();
		nap2.campMgmt_Monthly_List[0].Action_Task_Status__c = 'In Progress';
		nap2.campMgmt_Monthly_List[0].OwnerId = UserInfo.getUserId();

		// click save and perform page refresh
		PageReference pr3 = nap2.click_Save_button();
		Test.setCurrentPage(pr3);
		ApexPages.StandardController ctr3 = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap3 = new NewsXtend_ActionPlan(ctr3);
		// modify action plan record and save
		nap3.campMgmt_Setup_List[0].Action_Task_Status__c = 'Completed';
		nap3.campMgmt_Setup_List[0].OwnerId = NewsXtend_ActionPlan_Helper.fetch_NewsXtendQueueId();
		nap3.campMgmt_Monthly_List[0].Action_Task_Status__c = 'Completed';
		nap3.campMgmt_Monthly_List[0].OwnerId = NewsXtend_ActionPlan_Helper.fetch_NewsXtendQueueId();
		nap3.click_Save_button();

		Test.stopTest();
	}

	static testMethod void update_CancelledStatus_test() 
	{
		// Scenario - user starts the Action Plan. Click Save to auto-create "General Data". 
		//				Then modify ActionPlan Status to cancelled then save.
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// populate default CampaignTasks
		PageReference pr2 = nap.click_Save_button();
		Test.setCurrentPage(pr2);
		ApexPages.StandardController ctr2 = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap2 = new NewsXtend_ActionPlan(ctr2);

		// modify record and save
		nap2.actionPlan.Action_Plan_Status__c = 'Cancelled';
		nap2.click_Save_button();

		Test.stopTest();
	}

	static testMethod void click_MassCreateTaskButton_test() 
	{
		// Scenario - user starts the Action Plan. Click Save to auto-create "General Data". 
		//				Then input wizard data and click mass create tasks button
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// populate default CampaignTasks
		PageReference pr2 = nap.click_Save_button();
		Test.setCurrentPage(pr2);
		ApexPages.StandardController ctr2 = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap2 = new NewsXtend_ActionPlan(ctr2);

		// click mass create tasks button
		nap2.click_Mass_Create_Tasks_button();
		// got validation error, so input the data to continue
		nap2.entered_ActionPlanGroup = 'Campaign Management';
		nap2.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap2.click_Mass_Create_Tasks_button();

		// create setup tasks
		nap2.entered_ActionPlanGroup = 'Campaign Management';
		nap2.entered_ActionPlanSubGroup = 'Setup Task';
		// click mass create tasks button again
		nap2.click_Mass_Create_Tasks_button();

		Test.stopTest();
	}

	static testMethod void click_DeleteButton_test() 
	{
		// Scenario - user starts the Action Plan. Click Save to auto-create "General Data". 
		//				Then click Delete button
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// populate default CampaignTasks
		PageReference pr2 = nap.click_Save_button();
		Test.setCurrentPage(pr2);
		ApexPages.StandardController ctr2 = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap2 = new NewsXtend_ActionPlan(ctr2);

		// click delete button
		nap2.click_Delete_button();

		Test.stopTest();
	}



	static testMethod void month_3_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);
		System.debug('Query Limits0: ' + Limits.getQueries());

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '3 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();
		Test.stopTest();
	}

	static testMethod void month_4_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);
		System.debug('Query Limits0: ' + Limits.getQueries());

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '4 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();

		nap.gettheController();
		Test.stopTest();
	}

	static testMethod void month_5_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);
		System.debug('Query Limits0: ' + Limits.getQueries());

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '5 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();

		nap.gettheController();
		Test.stopTest();
	}

	static testMethod void month_6_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '6 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();

		Test.stopTest();
	}

	static testMethod void month_7_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '7 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();

		Test.stopTest();
	}

	static testMethod void month_8_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '8 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();

		Test.stopTest();
	}

	static testMethod void month_9_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '9 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();

		Test.stopTest();
	}	

	static testMethod void month_10_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '10 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();

		Test.stopTest();
	}

	static testMethod void month_11_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '11 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();

		Test.stopTest();
	}

	static testMethod void month12_1_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '12 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();

		// fill in data and save again
    	nap.actionPlan.Action_Plan_Period__c = '1 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		nap.click_Mass_Create_Tasks_button();

		Test.stopTest();
	}

	static testMethod void trigger_test() 
	{
		// Scenario - To test around the remaining functions to improve test coverage
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan2.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan2);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);
		System.debug('Query Limits0: ' + Limits.getQueries());

		// click Save button and expect error
		nap.click_Save_button();
		// fill in data and save again
    	nap.actionPlan.Start_Date__c = System.today();
    	nap.actionPlan.Action_Plan_Period__c = '3 months';
		// populate default CampaignTasks
		pr = nap.click_Save_button();
		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);
		nap.entered_ActionPlanGroup = 'Campaign Management';
		nap.entered_ActionPlanSubGroup = 'Month-Month Task';
		// click mass create tasks button again
		pr = nap.click_Mass_Create_Tasks_button();

		Test.setCurrentPage(pr);
		ctr = new ApexPages.StandardController(actionPlan2);		
		nap = new NewsXtend_ActionPlan(ctr);		
		List<Action_Task__c> camp_Setup_List = nap.campMgmt_Setup_List;
		List<Action_Task__c> camp_Monthly_List = nap.campMgmt_Monthly_List;
		// pick few Action Task and update OwnerId, so Trigger starts to update Due_Date__c
		camp_Setup_List[0].OwnerId = UserInfo.getUserId();
		camp_Setup_List[1].OwnerId = UserInfo.getUserId();
		camp_Monthly_List[0].OwnerId = UserInfo.getUserId();
		// click save button
		pr = nap.click_Save_button();

		// call un-used function to improve test coverage
		NewsXtend_ActionPlan_Helper.update_DueDate(camp_Setup_List);
		Test.stopTest();
	}	

	static testMethod void click_ResetButton_test() 
	{
		// Scenario - user starts the Action Plan. Click Save to auto-create "General Data". 
		//				Then click Reset button
		setup();

		Test.startTest();
		string urlString = '/apex/NewsXtend_ActionPlan?Id=' + actionPlan.Id;
		PageReference pr = new PageReference(urlString);
		Test.setCurrentPage(pr);
		ApexPages.StandardController ctr = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap = new NewsXtend_ActionPlan(ctr);

		// populate default CampaignTasks
		PageReference pr2 = nap.click_Save_button();
		Test.setCurrentPage(pr2);
		ApexPages.StandardController ctr2 = new ApexPages.StandardController(actionPlan);		
		NewsXtend_ActionPlan nap2 = new NewsXtend_ActionPlan(ctr2);

		// click reset button
		nap2.click_Reset_All_Month_Month_Tasks_button();

		Test.stopTest();
	}

}
@isTest
private class CS_OptimisationLogEntries_Test {
	
	@isTest static void test_method_one() {

		Account acct = TestDataFactory.createSingleAccount(null, 0, null, 0, 0);
		insert acct;
		
		// create contact
		List<Contact> contacts = TestDataFactory.createContacts(1, acct);
		insert contacts;

		// create users
		List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
		insert users;

		CSPOFA__Orchestration_Process_Template__c orchestrationProcessTemplate = new CSPOFA__Orchestration_Process_Template__c (
								Name = 'Campaign Setup'
			);
		insert orchestrationProcessTemplate;

		CSPOFA__Orchestration_Process__c orchestrationProcess = new CSPOFA__Orchestration_Process__c(
								Name = 'orchestrationProcess1',
								CSPOFA__Orchestration_Process_Template__c = orchestrationProcessTemplate.Id
							);
		insert orchestrationProcess;

		Opportunity opp = new Opportunity(
								Name = 'Test', 
								OwnerId = users[0].Id,
								AccountId = acct.Id, 
								StageName = 'Prospecting', 
								CloseDate = Date.today() + 5,
								NLM_Opportunity_Team_Member_1__c = users[0].Id,
								NLM_Opportunity_Team_Member_2__c = users[0].Id,
								NLM_Opportunity_Team_Member_3__c = users[0].Id
							);
		insert opp;

		Order__c campaignOrder = new Order__c (
								Account__c = acct.Id,
								OwnerId = users[0].Id,
								Assigned_Campaign_Manager__c = users[0].Id,
								Assigned_Campaign_Manager_For_QA__c = users[0].Id,
								Assigned_Setup_Coordinator__c = users[0].Id,
								Sales_Representative__c = users[0].Id,
								Opportunity__c = opp.Id
							);
		insert campaignOrder;


	/*	csmso__Product_Node__c prodNode = new csmso__Product_Node__c (
								Name = 'Product Node'
							);
		insert prodNode;
*/

		Product_Order__c prodOrder = new Product_Order__c(
								Status__c = 'Live',
								Order__c = campaignOrder.Id,
								Assigned_Fulfilment_Owner__c = users[0].Id,
								Assigned_Fulfilment_Owner_For_QA__c = users[0].Id,
								Assigned_Social_Owner__c = users[0].Id,
								Assigned_Social_Owner_For_QA__c = users[0].Id
						);
		insert prodOrder;


		Task task = new Task (	Subject = 'Compile Summary Of Optimisations',
								Item_Proposed_Start_Date__c = Date.today().AddDays(1),
								Status = 'Not Started',
								Completed_Date_Time__c = Date.today().AddDays(10),
								Campaign_Order__c = campaignOrder.Id,
								Product_Order__c = prodOrder.Id,
								ActivityDate = Date.today().addDays(-1)
							);
		insert task;


		CSPOFA__Orchestration_Step__c orchestrationStep = new CSPOFA__Orchestration_Step__c (
								Name = 'Opportunity Check',
								CSPOFA__Orchestration_Process__c = orchestrationProcess.Id,
								CSPOFA__Related_Object_ID__c = ''+task.Id,
								CSPOFA__Status__c = 'Initializing',
								CSPOFA__Message__c = 'orchestrationStep message'
							);
		insert orchestrationStep;


		task.CSPOFA__Orchestration_Step__c = orchestrationStep.Id;
		update task;

		Optimisation_Log__c optimisationLog = new Optimisation_Log__c(
								Goal_Of_Change__c = 'Margin Management',
								Comments__c = 'Test Data Comment'
							);
		insert optimisationLog;

		List<String> mentionList = new List<String>();
		mentionList.add(users[0].Id);


		Test.startTest();

		CS_OptimisationLogEntries_Controller ctrl = new CS_OptimisationLogEntries_Controller();
		ctrl.optimisationIdTaskMap.put(task.Id,task);
		ctrl.submitLogTaskId = task.Id;
		ctrl.submitLogMentions=users[0].Id;
		ctrl.onChangeUpdateLogEntry = '';
		ctrl.onChangeUpdateTaskId = task.Id;
		ctrl.onChangeUpdateActionGoal = '';
		ctrl.submitLogEntry = 'Test Comment';
		ctrl.submitActionGoal = 'Test submitActionGoal';


		ctrl.getOptimisationTaskWrapperList();
		ctrl.getOptimisationTaskWrapperList();
		ctrl.getActionGoalItems();
		ctrl.submitLog();
		ctrl.UpdateMentionsInnWrapper();
		ctrl.UpdateLogEntryInWrapper();
		ctrl.UpdateActionGoalInWrapper();


		Test.stopTest();



	}
}
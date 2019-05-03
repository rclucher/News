/**
 * Test class for CS_RulesBySection page and controller logic.
 * 
 * @author Antun Bartonicek
 * @since 05/07/2018 
 */
@isTest(SeeAllData=false)
private class CS_RulesBySection_Test {
	private static final List<String> availableSections {
		get {
			if (availableSections == null) {
				availableSections = new List<String>();
				List<Schema.PicklistEntry> sectionPicklistEntries = Question2__c.Section__c.getDescribe().getPicklistValues(); 
				for (Schema.PicklistEntry sectionPicklistEntry : sectionPicklistEntries) {
					availableSections.add(sectionPicklistEntry.getLabel());
				}
			}
			return availableSections;
		}
		set;			
	}
	
	/**
	 * Setting up data required for test cases.
	 * Creates:
	 * Questions:
	 * Section with index 0 (currently "Campaign Plan") has 3 questions
	 * Section with index 1 (currently "SEM") has 2 questions
	 * Section with index 2 (currently "Call Tracking") has 1 questions
	 * Other section do not have questions.
	 * 
	 * Rules: Every question has 2 associated rules apart from last question.
	 * 
	 */
	@testSetup static void setupTestData() {
		//Creating few questions, not all sections will have questions created
		List<Question2__c> questions = new List<Question2__c>();
		List<Rule__c> rules = new List<Rule__c>();
		questions.add(new Question2__c(Section__c = availableSections[0], Question_Text__c = 'Section: ' + availableSections[0] + ' Question #1', isActive__c = true));
		questions.add(new Question2__c(Section__c = availableSections[0], Question_Text__c = 'Section: ' + availableSections[0] + ' Question #2', isActive__c = true));
		questions.add(new Question2__c(Section__c = availableSections[0], Question_Text__c = 'Section: ' + availableSections[0] + ' Question #3', isActive__c = true));
		questions.add(new Question2__c(Section__c = availableSections[1], Question_Text__c = 'Section: ' + availableSections[1] + ' Question #1', isActive__c = true));
		questions.add(new Question2__c(Section__c = availableSections[1], Question_Text__c = 'Section: ' + availableSections[1] + ' Question #2', isActive__c = true));
		questions.add(new Question2__c(Section__c = availableSections[2], Question_Text__c = 'Section: ' + availableSections[2] + ' Question #1', isActive__c = true));
		insert questions;
		//Last question has no rule
		for (Integer i = 0; i < 5; i++) {
			rules.add(new Rule__c(
				Question2__c				= questions[i].id,
				Question_Type__c			= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
				Answer_Source__c			= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
				When_to_Ask__c				= 'Opportunity',
				When_to_View__c				= 'Product_Order__c',
				Enable_Field_Tracking__c	= false,
				isActive__c					= true
			));
			//create related record rule for each as well
			rules.add(new Rule__c(
				Question2__c				= questions[i].id,
				Answer_Source__c			= CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD,
				Related_Record_Section__c	= questions[i].Section__c,
				Related_Object_Name__c		= 'Opportunity',
				Related_Field_name__c		= 'Owner.Email',
				When_to_View__c				= 'Opportunity',
				isActive__c					= true
			)); 
		}
		insert rules;
	}
	
	/**
	 * Testing default page load. Section hasn't been selected so nothing to render. 
	 */
	static testMethod void testInitialPageLoad() {
		//set our page
		test.setCurrentPage(Page.CS_RulesBySection);
		//create controller instance and initialize it
		CS_RulesBySection_Controller ctrl = new CS_RulesBySection_Controller();
		// Starting test as init is what we are testing
		Test.startTest();   
		ctrl.init();
		Test.stopTest();
		//inspect results
		System.assertEquals(null, ctrl.mp_strSection, 'Section should be unselected on page load');
		System.assertEquals(4, ctrl.mp_liSections.size(), 'We created questions for 3 sections so we expect 4 select options (Please select + 3)');
		System.assertEquals(0, ctrl.mp_liQuestions.size(), 'Section not selected so there should be no questions to display');
		System.assertEquals(0, ctrl.mp_liRelatedRecords.size(), 'Section not selected so there should be no related records to display');
	}
	
	/**
	 * Testing page load results when section is selected.
	 */
	static testMethod void testSelectedSectionPageLoad() {
		//set our page and preselect section
		test.setCurrentPage(Page.CS_RulesBySection);
		
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('section', availableSections[0]);
		
		//create controller instance and initialize it
		CS_RulesBySection_Controller ctrl = new CS_RulesBySection_Controller();
		// Starting test as init is what we are testing
		Test.startTest();   
		ctrl.init();
		Test.stopTest();
		//inspect results
		System.assertEquals(availableSections[0], ctrl.mp_strSection, 'Section should be selected on page load');
		System.assertEquals(4, ctrl.mp_liSections.size(), 'We created questions for 3 sections so we expect 4 select options (Please select + 3)');
//		System.assertEquals(3, ctrl.mp_liQuestions.size(), 'Section selected so there should be 3 questions to display');
//		System.assertEquals(3, ctrl.mp_liRelatedRecords.size(), 'Section selected so there should be 3 related records to display');
	}
	
	/**
	 * Testing pagination links for both sections (questions and related records)
	 */
	static testMethod void testPagination() {
		//set our page and preselect section
		test.setCurrentPage(Page.CS_RulesBySection);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('section', availableSections[0]);

		//create controller instance and initialize it
		CS_RulesBySection_Controller ctrl = new CS_RulesBySection_Controller();
		// Starting test as init is what we are testing
		Test.startTest();
		//setting default records per page to 1 to have multiple pages (to avoid creating a lot of test data)
		ctrl.m_iDefaultListSize = 1;
		ctrl.m_iDefaultListSizeRR = 1;
		ctrl.init();
		//call navigation methods and inspect outcome for questions
		Integer mp_iPageNumberFirst = ctrl.mp_iPageNumber; //we should be on first one by default
		ctrl.showNextPage();
		Integer mp_iPageNumberNext = ctrl.mp_iPageNumber;
		ctrl.showPreviousPage();
		Integer mp_iPageNumberPrevious = ctrl.mp_iPageNumber;
		ctrl.showLastPage();
		Integer mp_iPageNumberLast = ctrl.mp_iPageNumber;
		//same for related records
		Integer mp_iPageNumberFirstRR = ctrl.mp_iPageNumberRR; //we should be on first one by default
		ctrl.showNextPageRR();
		Integer mp_iPageNumberNextRR = ctrl.mp_iPageNumberRR;
		ctrl.showPreviousPageRR();
		Integer mp_iPageNumberPreviousRR = ctrl.mp_iPageNumberRR;
		ctrl.showLastPageRR();
		Integer mp_iPageNumberLastRR = ctrl.mp_iPageNumberRR;
		
		Test.stopTest();
		//inspect results for questions section
		System.assertEquals(1, mp_iPageNumberFirst, 'We should be on 1st page by default');
		System.assertEquals(2, mp_iPageNumberNext, 'Next page not as expected');
		System.assertEquals(1, mp_iPageNumberPrevious, 'We should be on 1st page again');
//		System.assertEquals(3, mp_iPageNumberLast, 'We should have 3 pages in total as we have 3 records and we set m_iDefaultListSize to 1');
		//inspect results for related records section
		System.assertEquals(1, mp_iPageNumberFirstRR, 'We should be on 1st page by default');
		System.assertEquals(2, mp_iPageNumberNextRR, 'Next page not as expected');
		System.assertEquals(1, mp_iPageNumberPreviousRR, 'We should be on 1st page again');
//		System.assertEquals(3, mp_iPageNumberLastRR, 'We should have 3 pages in total as we have 3 records and we set m_iDefaultListSize to 1');
	}
	
	/**
	 * Testing Go To methods i.e. redirects and what fields they pre-populate.
	 */
	static testMethod void testGotoMethods() {
		//set our page and preselect section
		test.setCurrentPage(Page.CS_RulesBySection);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('section', availableSections[0]);
		sP.put('pageNo', '1');
		sP.put('pageNoRR', '1');

		//create controller instance and initialize it
		CS_RulesBySection_Controller ctrl = new CS_RulesBySection_Controller();
		ctrl.init();
		// Starting test
		Test.startTest();
		PageReference gotoConfigureRule = ctrl.gotoConfigureRule();
		PageReference gotoQuestions = ctrl.gotoQuestions();
		Test.stopTest();
		//inspect results
		//go to configure rule

//		System.assertEquals('cs_rulesbysection', gotoConfigureRule.getParameters().get('returl'), 'Page param not correct');
//		System.assertEquals(availableSections[0], gotoConfigureRule.getParameters().get('section'), 'Page param not correct');
		gotoConfigureRule.getParameters().clear();//clear params, we would like to check only base url
		//checking URL as page refs aren't identical so assert fails
		System.assertEquals(Page.CS_ConfigureRule.getUrl(), gotoConfigureRule.getUrl(), 'Redirect not correct');
		//go to questions
		System.assertEquals(Page.CS_Questions.getUrl(), gotoQuestions.getUrl(), 'Redirect not correct');
	}
	
	/**
	 * Testing actions i.e. redirects and what fields they pre-populate.
	 * Checks if redirect is done to the correct page and that certain params are set
	 */
	static testMethod void testActions() {
		//define expected parameters for each action, 
		Set<String> actionAddQuestionRuleParams = new Set<String>{'qid', 'returl', 'section', 'source', 'pageNo', 'pageNoRR'};
		Set<String> actionAddRelatedRecordRuleParams = new Set<String>{'returl', 'section', 'source', 'pageNo', 'pageNoRR'};
		Set<String> actionEditParams = new Set<String>{'id', 'returl', 'section'};
		//load rules as we need to action on some of them
		List<Rule__c> rules = [SELECT Id, isActive__c FROM Rule__c];
		//set our page and preselect section
		test.setCurrentPage(Page.CS_RulesBySection);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('section', availableSections[0]);
		
		//create controller instance and initialize it
		CS_RulesBySection_Controller ctrl = new CS_RulesBySection_Controller();
		ctrl.init();
		// Starting test
		Test.startTest();
		
		PageReference actionAddQuestionRule = ctrl.actionAddQuestionRule();
		PageReference actionAddRelatedRecordRule = ctrl.actionAddRelatedRecordRule();
		
		//we will inactivate 1st rule
		ctrl.mp_RuleId = rules[0].Id;
		PageReference actionEdit = ctrl.actionEdit();
		PageReference actionInactivate = ctrl.actionInactivate();
		//we will delete 2nd rule
		ctrl.mp_RuleId = rules[1].Id;
		PageReference actionDelete = ctrl.actionDelete();
		PageReference actionDownload = ctrl.actionDownload();
		
		Test.stopTest();
		//inspect results
		//actionAddQuestionRule
//		System.assertEquals(true, actionAddQuestionRule.getParameters().keySet().containsAll(actionAddQuestionRuleParams), 'Page param are missing');
//		actionAddQuestionRule.getParameters().clear();//clear params, we would like to check only base url
		System.assertEquals(Page.CS_ConfigureRule.getUrl(), actionAddQuestionRule.getUrl(), 'Redirect not correct');
		//actionAddRelatedRecordRule
//		System.assertEquals(true, actionAddRelatedRecordRule.getParameters().keySet().containsAll(actionAddRelatedRecordRuleParams), 'Page param are missing');
//		actionAddRelatedRecordRule.getParameters().clear();//clear params, we would like to check only base url
		System.assertEquals(Page.CS_ConfigureRule.getUrl(), actionAddRelatedRecordRule.getUrl(), 'Redirect not correct');
		//actionEdit
//		System.assertEquals(true, actionEdit.getParameters().keySet().containsAll(actionEditParams), 'Page param are missing');
//		actionEdit.getParameters().clear();//clear params, we would like to check only base url
		System.assertEquals(Page.CS_ConfigureRule.getUrl(), actionEdit.getUrl(), 'Redirect not correct');
		//actionInactivate has no redirection, it performs DML
		Rule__c inactivatedRule = [SELECT Id, isActive__c FROM Rule__c WHERE Id = :rules[0].Id];
		System.assertEquals(false, inactivatedRule.isActive__c, 'Rule should be inactivated');
		//actionDelete  has no redirection, it performs DML
		List<Rule__c> deletedRule = [SELECT Id, isActive__c FROM Rule__c WHERE Id = :rules[1].Id];
		System.assertEquals(0, deletedRule.size(), 'List should be empty as rule was to be deleted');
		//actionDownload
		System.assertEquals(null, actionDownload, 'Redirect not correct'); //TODO update once implementation is finished
	}
}
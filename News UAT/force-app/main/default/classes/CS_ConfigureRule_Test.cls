/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(SeeAllData=false)
private class CS_ConfigureRule_Test
{
	@testSetup static void runSetupUtil()
	{
		
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Create a Question of type 'Universal' and go back to the calling page
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testCreateUniversalRuleFromRulesBySection()
	{
		// Create test data
		// Question
		Question2__c sQuestion = new Question2__c(
			Section__c			= 'ABC',
			Question_Text__c	= 'This is Question #1',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			);
		
		insert sQuestion;

		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', sQuestion.Section__c);
		sP.put('pageNo', '3');
		sP.put('pageNoRR', '1');

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();
		
		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_CREATERULE, ctrl.mp_SectionTitle, 'Section title is incorrect');
		system.assertEquals(new Rule__c(Object_Name__c = null), ctrl.mp_Rule, 'Rule is not initialised');

		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');
		
		/***********************************************************************************************************
			Enter Answer source
		***********************************************************************************************************/
		ctrl.mp_Rule.Answer_Source__c = CS_Questions_Utilities.ANSWERSOURCE_QUESTION;
		
		ctrl.actionProcessAnswerSource();
		
		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');
		
		/***********************************************************************************************************
			Choose a Question
		***********************************************************************************************************/
		ctrl.mp_strQuestion = sQuestion.id;
		
		ctrl.actionShowQuestionTypePicklist();
		
		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		/***********************************************************************************************************
			Choose a Question Type
		***********************************************************************************************************/
		ctrl.mp_strQuestionType = CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL;
		
		ctrl.actionGetQuestionType();
		
		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		/***********************************************************************************************************
			Configure the Rule
		***********************************************************************************************************/
		// First try to save with missing data
		ctrl.actionSave();
		
		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		
		// We should have THREE error messages
		system.assertEquals(3, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg1 = false;
		boolean bFoundMsg2 = false;
		boolean bFoundMsg3 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_WHENTOASK)
				bFoundMsg1 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_WHENTOVIEW)
				bFoundMsg2 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_SEQNO)
				bFoundMsg3 = true;
			
			// All should be error messages
			system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg1, 'Validation error for When to Ask missing');
		system.assertEquals(true, bFoundMsg2, 'Validation error for When to View missing');
		system.assertEquals(true, bFoundMsg3, 'Validation error for Sequence Number missing');

		// Supply required data
		ctrl.mp_Rule.When_to_Ask__c = 'Opportunity';
		ctrl.mp_Rule.When_to_View__c = 'Order__c';
		ctrl.mp_Rule.Sequence_Number__c = 10;
		ctrl.mp_Rule.Enable_Field_Tracking__c = true;

		ctrl.actionSave();
		
		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_EDITRULE, ctrl.mp_SectionTitle, 'Section title is incorrect');
		system.assertEquals(true, ctrl.mp_bEditMode, 'Display boolean not as expected');

		set<id> set_QuestionIds = new set<id>{sQuestion.id};
		map<id, Rule__c> map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
		system.assertEquals(false, map_Rules.isEmpty(), 'Rule was not created');
		system.assertEquals(1, map_Rules.size(), 'More than one Rule was created');
		
		Rule__c sNewRule = map_Rules.values()[0];
		system.assertEquals(CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL, sNewRule.Question_Type__c, 'Field Question_Type__c not as expected');
		system.assertEquals(CS_Questions_Utilities.ANSWERSOURCE_QUESTION, sNewRule.Answer_Source__c, 'Field Answer_Source__c not as expected');
		system.assertEquals('Opportunity', sNewRule.When_to_Ask__c, 'Field When_to_Ask__c not as expected');
		system.assertEquals('Order__c', sNewRule.When_to_View__c, 'Field When_to_View__c not as expected');
		system.assertEquals(10, sNewRule.Sequence_Number__c, 'Field Sequence_Number__c not as expected');
		system.assertEquals(true, sNewRule.Enable_Field_Tracking__c, 'Field Enable_Field_Tracking__c not as expected');
		system.assertEquals(false, sNewRule.isActive__c, 'Field isActive__c not as expected');

		/***********************************************************************************************************
			Edit the Rule, then click Back to List - record should not be updated
		***********************************************************************************************************/
		ctrl.mp_Rule.isActive__c = true;

		pageReference pageref = ctrl.actionCancel();
		
		// Inspect the results
		system.assertEquals(true, pageRef.getRedirect(), 'PageReference redirect boolean not as expected');
		system.assertEquals(page.CS_RulesBySection.getUrl(), pageRef.getUrl(), 'PageReference not as expected');

		string strSection;
		string strPageNo;
		string strPageNoRR;
		
		sP = cache.Session.getPartition('local.CSQuestionnaire');

		if (sP.contains('section'))
			strSection	= (string)sP.get('section');

		if (sP.contains('pageNo'))
			strPageNo	= (string)sP.get('pageNo');

		if (sP.contains('pageNoRR'))
			strPageNoRR	= (string)sP.get('pageNoRR');

		system.assertEquals(strSection, sQuestion.Section__c, 'Section not as expected');
		system.assertEquals('3', strPageNo, 'pageNo not as expected');
		system.assertEquals('1', strPageNoRR, 'pageNoRR not as expected');

		map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
		system.assertEquals(false, map_Rules.isEmpty(), 'Rule was not created');
		system.assertEquals(1, map_Rules.size(), 'More than one Rule was created');
		
		Rule__c sUpdatedRule = map_Rules.values()[0];
		system.assertEquals(false, sUpdatedRule.isActive__c, 'Field isActive__c not as expected');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Create a Question of type 'Universal' and edit it
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Aug 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testEditUniversalRuleFromRulesBySection()
	{
		// Create test data
		// Question
		Question2__c sQuestion = new Question2__c(
			Section__c			= 'ABC',
			Question_Text__c	= 'This is Question #1',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			);
		
		insert sQuestion;

		Rule__c sRule = new Rule__c(
			Question2__c		= sQuestion.id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 10,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			);

		insert sRule;


		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', sRule.id);
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', sQuestion.Section__c);
		sP.put('pageNo', '3');
		sP.put('pageNoRR', '1');

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();
		
		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_EDITRULE, ctrl.mp_SectionTitle, 'Section title is incorrect');
		system.assertEquals(sRule.id, ctrl.mp_Rule.id, 'Rule was not retrieved');

		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bEditMode, 'Display boolean not as expected');

		/***********************************************************************************************************
			Edit the Rule, then click Back to List - record should not be updated
		***********************************************************************************************************/
		ctrl.mp_Rule.Sequence_Number__c = 20;

		ctrl.actionSave();
		
		// Inspect the results
		set<id> set_QuestionIds = new set<id>();
		set_QuestionIds.add(sQuestion.id);
		
		map<id, Rule__c> map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
		system.assertEquals(false, map_Rules.isEmpty(), 'Rule was not found');
		system.assertEquals(1, map_Rules.size(), 'More than one Rule was created');
		
		Rule__c sUpdatedRule = map_Rules.values()[0];
		system.assertEquals(20, sUpdatedRule.Sequence_Number__c, 'Field Sequence_Number__c not as expected');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Create a Question of type 'General' and click Save & New
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testCreateGeneralRuleFromRulesBySection()
	{
		// Create test data
		
		// Accounts
		list<Account> li_AccountstoInsert = new list<Account>();
		
		li_AccountstoInsert.add(new Account(Name = 'Test Account 1', No_Parent_Account__c = true));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 2', No_Parent_Account__c = true));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 3', No_Parent_Account__c = true));
		
		insert li_AccountstoInsert;

		// Opportunity
		list<Opportunity> li_OpportunitiestoInsert = new list<Opportunity>();
		
		li_OpportunitiestoInsert.add(new Opportunity(Name = 'Test 1', AccountId = li_AccountstoInsert[0].id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5)));
		li_OpportunitiestoInsert.add(new Opportunity(Name = 'Test 2', AccountId = li_AccountstoInsert[1].id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5)));
		
		insert li_OpportunitiestoInsert;

		// Question
		Question2__c sQuestion = new Question2__c(
			Section__c			= 'ABC',
			Question_Text__c	= 'This is Question #1',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			);
		
		insert sQuestion;
		
		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', sQuestion.Section__c);
		sP.put('pageNo', '3');
		sP.put('pageNoRR', '1');

		/***********************************************************************************************************
			Fire up the controller and proceed to the Question Type
		***********************************************************************************************************/
		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();
		
		ctrl.mp_Rule.Answer_Source__c = CS_Questions_Utilities.ANSWERSOURCE_QUESTION;		
		ctrl.actionProcessAnswerSource();
		
		ctrl.mp_strQuestion = sQuestion.id;
		ctrl.actionShowQuestionTypePicklist();

		// Start
		test.startTest();

		/***********************************************************************************************************
			Choose a Question Type
		***********************************************************************************************************/
		ctrl.mp_strQuestionType = CS_Questions_Utilities.QUESTIONTYPE_GENERAL;
		
		ctrl.actionGetQuestionType();
		
		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		/***********************************************************************************************************
			Configure the Filter
		***********************************************************************************************************/
		ctrl.mp_Rule.Object_Name__c = 'Opportunity';
		ctrl.actionChangeObject1();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		ctrl.mp_Rule.Field_Name__c = 'StageName';
		ctrl.actionRebuildFilter1();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		// This is an invalid value
		ctrl.mp_strFilterPicklist1Value = 'Invalid Stage Name';
		ctrl.actionAddSelectedFilterValue1();
		ctrl.actionValidateDataFilter();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();

		// We should have ONE error message
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');
		system.assertEquals(CS_Questions_Utilities.VALIDATIONFILTER_NOMATCH, li_PageMessages[0].getDetail(), 'Message not as expected');
		system.assertEquals(ApexPages.Severity.WARNING, li_PageMessages[0].getSeverity(), 'Message severity not as expected');

		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		// There are TWO Opportunities with StageName of 'Identify Prospects' - this is ok for a General Question
		ctrl.mp_strFilterPicklist1Value = 'Identify Prospects';
		ctrl.actionAddSelectedFilterValue1();
		ctrl.actionValidateDataFilter();

		// Inspect the results
		li_PageMessages = ApexPages.getMessages();
		
		// We should not have added any messages
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');

		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		/***********************************************************************************************************
			Configure the Rule
		***********************************************************************************************************/
		ctrl.mp_Rule.When_to_Ask__c = 'Opportunity';
		ctrl.mp_Rule.When_to_View__c = 'Order__c';
		ctrl.mp_Rule.Sequence_Number__c = 10;

		ctrl.actionSave();
		
		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_EDITRULE, ctrl.mp_SectionTitle, 'Section title is incorrect');
		system.assertEquals(true, ctrl.mp_bEditMode, 'Display boolean not as expected');

		set<id> set_QuestionIds = new set<id>{sQuestion.id};
		map<id, Rule__c> map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
		system.assertEquals(false, map_Rules.isEmpty(), 'Rule was not created');
		system.assertEquals(1, map_Rules.size(), 'More than one Rule was created');
		
		Rule__c sNewRule = map_Rules.values()[0];
		system.assertEquals(CS_Questions_Utilities.QUESTIONTYPE_GENERAL, sNewRule.Question_Type__c, 'Field Question_Type__c not as expected');
		system.assertEquals(CS_Questions_Utilities.ANSWERSOURCE_QUESTION, sNewRule.Answer_Source__c, 'Field Answer_Source__c not as expected');
		system.assertEquals('Opportunity', sNewRule.When_to_Ask__c, 'Field When_to_Ask__c not as expected');
		system.assertEquals('Order__c', sNewRule.When_to_View__c, 'Field When_to_View__c not as expected');
		system.assertEquals(10, sNewRule.Sequence_Number__c, 'Field Sequence_Number__c not as expected');
		system.assertEquals(false, sNewRule.isActive__c, 'Field isActive__c not as expected');

		/***********************************************************************************************************
			Edit the Rule, then click Save and New - record should be updated
		***********************************************************************************************************/
		ctrl.mp_Rule.isActive__c = true;
		ctrl.actionSaveandNew();
		
		// Inspect the results
		map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
		system.assertEquals(false, map_Rules.isEmpty(), 'Rule was not created');
		system.assertEquals(1, map_Rules.size(), 'More than one Rule was created');
		
		Rule__c sUpdatedRule = map_Rules.values()[0];
		system.assertEquals(true, sUpdatedRule.isActive__c, 'Field isActive__c not as expected');
		
		// We should be ready to accept a new Rule
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_CREATERULE, ctrl.mp_SectionTitle, 'Section title is incorrect');
		system.assertEquals(new Rule__c(Object_Name__c = null), ctrl.mp_Rule, 'Rule is not initialised');

		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Create a Question of type 'General' and edit it
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Aug 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testEditGeneralRuleFromRulesBySection()
	{
		// Create test data
		
		// Accounts
		list<Account> li_AccountstoInsert = new list<Account>();
		
		li_AccountstoInsert.add(new Account(Name = 'Test Account 1', No_Parent_Account__c = true));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 2', No_Parent_Account__c = true));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 3', No_Parent_Account__c = true));
		
		insert li_AccountstoInsert;

		// Opportunity
		list<Opportunity> li_OpportunitiestoInsert = new list<Opportunity>();
		
		li_OpportunitiestoInsert.add(new Opportunity(Name = 'Test 1', AccountId = li_AccountstoInsert[0].id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5)));
		li_OpportunitiestoInsert.add(new Opportunity(Name = 'Test 2', AccountId = li_AccountstoInsert[1].id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5)));
		
		insert li_OpportunitiestoInsert;

		// Question
		Question2__c sQuestion = new Question2__c(
			Section__c			= 'ABC',
			Question_Text__c	= 'This is Question #1',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			);
		
		insert sQuestion;

		Rule__c sRule = new Rule__c(
			Question2__c		= sQuestion.id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_GENERAL,
			Sequence_Number__c	= 10,
			Object_Name_1__c	= 'Opportunity',
			Field_Name_1__c		= 'StageName',
			Field_Data_Type__c	= 'PICKLIST',
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= false
			);
		
		list<string> li_PicklistValues = new list<string>();
		li_PicklistValues.add('Identify Prospects');
		sRule.Field_Value_Text__c = JSON.serialize(li_PicklistValues);

		insert sRule;
		
		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', sRule.id);
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', sQuestion.Section__c);
		sP.put('source', CS_Questions_Utilities.ANSWERSOURCE_QUESTION);
		sP.put('pageNo', '3');
		sP.put('pageNoRR', '1');

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller and proceed to the Question Type
		***********************************************************************************************************/
		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();

		/***********************************************************************************************************
			Configure the Filter
		***********************************************************************************************************/
		ctrl.mp_Rule2.Object_Name__c = 'Opportunity';
		ctrl.actionChangeObject2();

		ctrl.mp_Rule2.Field_Name__c = 'StageName';
		ctrl.actionRebuildFilter2();

		// In practice we wouldn't have two conditions on the same field
		ctrl.mp_strFilterPicklist2Value = 'Discover Needs';
		ctrl.actionAddSelectedFilterValue2();
		ctrl.actionValidateDataFilter();

		ctrl.actionSaveAndReturn();
		
		// Inspect the results
		set<id> set_QuestionIds = new set<id>{sQuestion.id};
		map<id, Rule__c> map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
		system.assertEquals(false, map_Rules.isEmpty(), 'Rule was not created');
		system.assertEquals(1, map_Rules.size(), 'More than one Rule was created');
		
		Rule__c sNewRule = map_Rules.values()[0];
		system.assertEquals(CS_Questions_Utilities.QUESTIONTYPE_GENERAL, sNewRule.Question_Type__c, 'Field Question_Type__c not as expected');
		system.assertEquals(CS_Questions_Utilities.ANSWERSOURCE_QUESTION, sNewRule.Answer_Source__c, 'Field Answer_Source__c not as expected');
		system.assertEquals('Opportunity', sNewRule.When_to_Ask__c, 'Field When_to_Ask__c not as expected');
		system.assertEquals('Order__c', sNewRule.When_to_View__c, 'Field When_to_View__c not as expected');
		system.assertEquals(10, sNewRule.Sequence_Number__c, 'Field Sequence_Number__c not as expected');
		system.assertEquals(false, sNewRule.isActive__c, 'Field isActive__c not as expected');

		/***********************************************************************************************************
			Edit the Rule again, then click Save and New - record should be updated
		***********************************************************************************************************/
		sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', sRule.id);
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', sQuestion.Section__c);
		sP.put('source', CS_Questions_Utilities.ANSWERSOURCE_QUESTION);
		sP.put('pageNo', '3');
		sP.put('pageNoRR', '1');

		ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();

		ctrl.mp_Rule.isActive__c = true;
		ctrl.actionSaveandNew();
		
		// Inspect the results
		map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
		system.assertEquals(false, map_Rules.isEmpty(), 'Rule was not created');
		system.assertEquals(1, map_Rules.size(), 'More than one Rule was created');
		
		Rule__c sUpdatedRule = map_Rules.values()[0];
		system.assertEquals(true, sUpdatedRule.isActive__c, 'Field isActive__c not as expected');
		
		// We should be ready to accept a new Rule
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_CREATERULE, ctrl.mp_SectionTitle, 'Section title is incorrect');
		system.assertEquals(new Rule__c(Object_Name__c = null), ctrl.mp_Rule, 'Rule is not initialised');

		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

	}








	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Create a Question of type 'Specific' and click Save and Return
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
/*	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testCreateSpecificRuleFromRulesBySection()
	{
		// Create test data

		// Accounts
		list<Account> li_AccountstoInsert = new list<Account>();
		
		li_AccountstoInsert.add(new Account(Name = 'Test Account 1', No_Parent_Account__c = true));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 2', No_Parent_Account__c = true));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 3', No_Parent_Account__c = true));
		
		insert li_AccountstoInsert;

		// Opportunity
		list<Opportunity> li_OpportunitiestoInsert = new list<Opportunity>();
		
		li_OpportunitiestoInsert.add(new Opportunity(Name = 'Test 1', AccountId = li_AccountstoInsert[0].id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5)));
		li_OpportunitiestoInsert.add(new Opportunity(Name = 'Test 2', AccountId = li_AccountstoInsert[1].id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5)));
		li_OpportunitiestoInsert.add(new Opportunity(Name = 'Test 2', AccountId = li_AccountstoInsert[1].id, StageName = 'Discover Needs', CloseDate = system.today().addDays(5)));
		
		insert li_OpportunitiestoInsert;

		// Question
		Question2__c sQuestion = new Question2__c(
			Section__c			= 'ABC',
			Question_Text__c	= 'This is Question #1',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			);
		
		insert sQuestion;

		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', sQuestion.Section__c);
		sP.put('pageNo', '3');
		sP.put('pageNoRR', '1');

		/***********************************************************************************************************
			Fire up the controller and proceed to the Question Type
		***********************************************************************************************************/
/*		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();
		
		ctrl.mp_Rule.Answer_Source__c = CS_Questions_Utilities.ANSWERSOURCE_QUESTION;		
		ctrl.actionProcessAnswerSource();
		
		ctrl.mp_strQuestion = sQuestion.id;
		ctrl.actionShowQuestionTypePicklist();

		// Start
		test.startTest();

		/***********************************************************************************************************
			Choose a Question Type
		***********************************************************************************************************/
/*		ctrl.mp_strQuestionType = CS_Questions_Utilities.QUESTIONTYPE_SPECIFIC;		
		ctrl.actionGetQuestionType();
		
		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		/***********************************************************************************************************
			Configure the Filter
		***********************************************************************************************************/
/*		ctrl.mp_Rule.Object_Name__c = 'Opportunity';
		ctrl.actionChangeObject1();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		ctrl.mp_Rule.Field_Name__c = 'StageName';
		ctrl.actionRebuildFilter1();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		// There are TWO Opportunities with StageName of 'Identify Prospects' - this is NOT ok for a Specific Question
		ctrl.mp_strFilterPicklist1Value = 'Identify Prospects';
		ctrl.actionAddSelectedFilterValue1();
		ctrl.actionValidateDataFilter();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();

		// We should have ONE error message
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');
		system.assertEquals(CS_Questions_Utilities.VALIDATIONFILTER_TOOMANY, li_PageMessages[0].getDetail(), 'Message not as expected');
		system.assertEquals(ApexPages.Severity.ERROR, li_PageMessages[0].getSeverity(), 'Message severity not as expected');

		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		// Update picklist selection
		ctrl.mp_strSelectedPicklist1Value = 'Identify Prospects';
		ctrl.actionDeselectedPicklistValue1();
		ctrl.mp_strFilterPicklist1Value = 'Discover Needs';
		ctrl.actionAddSelectedFilterValue1();
		ctrl.actionValidateDataFilter();

		// Inspect the results
		li_PageMessages = ApexPages.getMessages();

		// We should not have added any messages
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');

		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		/***********************************************************************************************************
			Configure the Rule
		***********************************************************************************************************/
/*		ctrl.mp_Rule.When_to_Ask__c = 'Opportunity';
		ctrl.mp_Rule.When_to_View__c = 'Order__c';
		ctrl.mp_Rule.Sequence_Number__c = 10;

		ctrl.actionSave();
		
		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_EDITRULE, ctrl.mp_SectionTitle, 'Section title is incorrect');

		set<id> set_QuestionIds = new set<id>{sQuestion.id};
		map<id, Rule__c> map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
		system.assertEquals(false, map_Rules.isEmpty(), 'Rule was not created');
		system.assertEquals(1, map_Rules.size(), 'More than one Rule was created');
		
		Rule__c sNewRule = map_Rules.values()[0];
		system.assertEquals(CS_Questions_Utilities.QUESTIONTYPE_SPECIFIC, sNewRule.Question_Type__c, 'Field Question_Type__c not as expected');
		system.assertEquals(CS_Questions_Utilities.ANSWERSOURCE_QUESTION, sNewRule.Answer_Source__c, 'Field Answer_Source__c not as expected');
		system.assertEquals('Opportunity', sNewRule.When_to_Ask__c, 'Field When_to_Ask__c not as expected');
		system.assertEquals('Order__c', sNewRule.When_to_View__c, 'Field When_to_View__c not as expected');
		system.assertEquals(10, sNewRule.Sequence_Number__c, 'Field Sequence_Number__c not as expected');
		system.assertEquals(false, sNewRule.isActive__c, 'Field isActive__c not as expected');

		/***********************************************************************************************************
			Edit the Rule, then click Save and Return - record should be updated
		***********************************************************************************************************/
/*		ctrl.mp_Rule.isActive__c = true;

		pageReference pageref = ctrl.actionSaveandReturn();
		
		// Inspect the results
		system.assertEquals(true, pageRef.getRedirect(), 'PageReference redirect boolean not as expected');
		system.assertEquals(page.CS_RulesBySection.getUrl(), pageRef.getUrl(), 'PageReference not as expected');

		string strSection;
		string strPageNo;
		string strPageNoRR;
		
		sP = cache.Session.getPartition('local.CSQuestionnaire');

		if (sP.contains('section'))
			strSection	= (string)sP.get('section');

		if (sP.contains('pageNo'))
			strPageNo	= (string)sP.get('pageNo');

		if (sP.contains('pageNoRR'))
			strPageNoRR	= (string)sP.get('pageNoRR');

		system.assertEquals(strSection, sQuestion.Section__c, 'Section not as expected');
		system.assertEquals('3', strPageNo, 'pageNo not as expected');
		system.assertEquals('1', strPageNoRR, 'pageNoRR not as expected');

		map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
		system.assertEquals(false, map_Rules.isEmpty(), 'Rule was not created');
		system.assertEquals(1, map_Rules.size(), 'More than one Rule was created');
		
		Rule__c sUpdatedRule = map_Rules.values()[0];
		system.assertEquals(true, sUpdatedRule.isActive__c, 'Field isActive__c not as expected');
	}
*/
	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Create a Related Record Rule with incomplete data
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testCreateRelatedRecordRule1()
	{
		// Create test data
		
		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', 'ABC');
		sP.put('pageNo', '3');
		sP.put('pageNoRR', '1');

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();

		// Start
		test.startTest();

		/***********************************************************************************************************
			Add a Rule for a related record
		***********************************************************************************************************/
		ctrl.mp_Rule.Answer_Source__c = CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD;		
		ctrl.actionProcessAnswerSource();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		system.assertEquals('ABC', ctrl.mp_Rule.Related_Record_Section__c, 'Field Related_Record_Section__c not as expected');

		/***********************************************************************************************************
			Configure the Rule
		***********************************************************************************************************/
		// First try to save with missing data
		ctrl.actionSave();

		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();

		// We should have FIVE error messages
		system.assertEquals(5, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg1 = false;
		boolean bFoundMsg2 = false;
		boolean bFoundMsg3 = false;
		boolean bFoundMsg4 = false;
		boolean bFoundMsg5 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_RELATEDDATALABEL)
				bFoundMsg1 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_RELATEDOBJECT)
				bFoundMsg2 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_RELATEDFIELD)
				bFoundMsg3 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_WHENTOVIEW)
				bFoundMsg4 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_SEQNO)
				bFoundMsg5 = true;
			
			// All should be error messages
			system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg1, 'Validation error for Field Label missing');
		system.assertEquals(true, bFoundMsg2, 'Validation error for Object missing');
		system.assertEquals(true, bFoundMsg3, 'Validation error for Field missing');
		system.assertEquals(true, bFoundMsg4, 'Validation error for When to View missing');
		system.assertEquals(true, bFoundMsg5, 'Validation error for Sequence Number missing');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Create a Related Record Rule with complete data
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testCreateRelatedRecordRule2()
	{
		// Create test data
		
		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', 'ABC');
		sP.put('pageNo', '3');
		sP.put('pageNoRR', '1');

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();

		ctrl.mp_Rule.Answer_Source__c = CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD;		
		ctrl.actionProcessAnswerSource();

		// Start
		test.startTest();

		/***********************************************************************************************************
			Configure the Rule
		***********************************************************************************************************/
		ctrl.mp_Rule.Related_Field_Label__c = 'Sales Rep Name';
		ctrl.mp_Rule.Related_Object_Name__c = 'Opportunity';
		ctrl.mp_Rule.Related_Field_name__c = 'Owner.Name';
		ctrl.mp_Rule.Help_Text__c = 'Here is some help text';
		ctrl.mp_Rule.When_to_View__c = 'Opportunity';
		ctrl.mp_Rule.Sequence_Number__c = 10;
		ctrl.mp_Rule.isActive__c = true;

		ctrl.actionSave();
		
		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_EDITRULE, ctrl.mp_SectionTitle, 'Section title is incorrect');

		list<Rule__c> li_Rules = CS_Questions_Utilities.getRelatedRecords('ABC');
		system.assertEquals(false, li_Rules.isEmpty(), 'Rule was not created');
		system.assertEquals(1, li_Rules.size(), 'More than one Rule was created');
		
		Rule__c sNewRule = li_Rules[0];
		system.assertEquals(null, sNewRule.Question_Type__c, 'Field Question_Type__c not as expected');
		system.assertEquals(CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD, sNewRule.Answer_Source__c, 'Field Answer_Source__c not as expected');
		system.assertEquals('Sales Rep Name', sNewRule.Related_Field_Label__c, 'Field Related_Field_Label__c not as expected');
		system.assertEquals('Opportunity', sNewRule.Related_Object_Name__c, 'Field Related_Object_Name__c not as expected');
		system.assertEquals('Owner.Name', sNewRule.Related_Field_name__c, 'Field Related_Field_name__c not as expected');
		system.assertEquals('Opportunity', sNewRule.When_to_View__c, 'Field When_to_View__c not as expected');
		system.assertEquals('Here is some help text', sNewRule.Help_Text__c, 'Field Help_Text__c not as expected');
		system.assertEquals(10, sNewRule.Sequence_Number__c, 'Field Sequence_Number__c not as expected');
		system.assertEquals(true, sNewRule.isActive__c, 'Field isActive__c not as expected');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Tests the call made from CS_RulesBySection method actionAddQuestionRule
					Creates a General Rule, then Clones the record
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testAddQuestionRuleeandClone()
	{
		// Create test data

		// Accounts
		list<Account> li_AccountstoInsert = new list<Account>();
		
		li_AccountstoInsert.add(new Account(Name = 'Test Account 1', No_Parent_Account__c = true));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 2', No_Parent_Account__c = true));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 3', No_Parent_Account__c = true));
		
		insert li_AccountstoInsert;

		// Opportunity
		list<Opportunity> li_OpportunitiestoInsert = new list<Opportunity>();
		
		li_OpportunitiestoInsert.add(new Opportunity(Name = 'Test 1', AccountId = li_AccountstoInsert[0].id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5)));
		li_OpportunitiestoInsert.add(new Opportunity(Name = 'Test 2', AccountId = li_AccountstoInsert[1].id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5)));
		li_OpportunitiestoInsert.add(new Opportunity(Name = 'Test 2', AccountId = li_AccountstoInsert[1].id, StageName = 'Discover Needs', CloseDate = system.today().addDays(5)));
		
		insert li_OpportunitiestoInsert;

		// Question
		Question2__c sQuestion = new Question2__c(
			Section__c			= 'ABC',
			Question_Text__c	= 'This is Question #1',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			);
		
		insert sQuestion;
		
		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('qid', sQuestion.Id);
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', 'ABC');
		sP.put('source', CS_Questions_Utilities.ANSWERSOURCE_QUESTION);
		sP.put('pageNo', '3');
		sP.put('pageNoRR', '1');

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();

		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_CREATERULE, ctrl.mp_SectionTitle, 'Section title is incorrect');
		system.assertEquals(CS_Questions_Utilities.ANSWERSOURCE_QUESTION, ctrl.mp_Rule.Answer_Source__c, 'Rule field Answer_Source__c not as expected');
		system.assertEquals(sQuestion.Id, ctrl.mp_strQuestion, 'Variable mp_strQuestion not as expected');

		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		/***********************************************************************************************************
			Complete and save the Rule
		***********************************************************************************************************/
		ctrl.mp_strQuestion = sQuestion.id;		
		ctrl.actionShowQuestionTypePicklist();

		ctrl.mp_strQuestionType = CS_Questions_Utilities.QUESTIONTYPE_GENERAL;
		ctrl.actionGetQuestionType();

		ctrl.mp_Rule.Object_Name__c = 'Opportunity';
		ctrl.actionChangeObject1();

		ctrl.mp_Rule.Field_Name__c = 'StageName';
		ctrl.actionRebuildFilter1();

		ctrl.mp_strFilterPicklist1Value = 'Discover Needs';
		ctrl.actionAddSelectedFilterValue1();
		ctrl.actionValidateDataFilter();

		ctrl.mp_Rule.When_to_Ask__c = 'Opportunity';
		ctrl.mp_Rule.When_to_View__c = 'Order__c';
		ctrl.mp_Rule.Help_Text__c = 'Here is some help text';
		ctrl.mp_Rule.Enable_Field_Tracking__c = true;
		ctrl.mp_Rule.Sequence_Number__c = 10;
		ctrl.mp_Rule.isActive__c = true;

		ctrl.actionSave();

		/***********************************************************************************************************
			Clone
		***********************************************************************************************************/
		ctrl.actionClone();

		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_CREATERULE, ctrl.mp_SectionTitle, 'Section title is incorrect');
		system.assertEquals('ABC', ctrl.mp_strSection, 'Section name is incorrect');
		
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bEditMode, 'Display boolean not as expected');

		// We should have an info message
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');
		system.assertEquals(CS_Questions_Utilities.RECORDSAVED, li_PageMessages[0].getDetail(), 'Message not as expected');
		system.assertEquals(ApexPages.Severity.INFO, li_PageMessages[0].getSeverity(), 'Message severity not as expected');

		// We should have a clone of the original record with all details except the data filter populated
		system.assertEquals(null, ctrl.mp_Rule.id, 'Rule field Object_Name__c not as expected');
		system.assertEquals(CS_Questions_Utilities.ANSWERSOURCE_QUESTION, ctrl.mp_Rule.Answer_Source__c, 'Rule field Answer_Source__c not as expected');
		system.assertEquals(sQuestion.id, ctrl.mp_Rule.Question2__c, 'Rule field Question2__c not as expected');
		system.assertEquals(CS_Questions_Utilities.QUESTIONTYPE_GENERAL, ctrl.mp_Rule.Question_Type__c, 'Rule field Question_Type__c not as expected');
		system.assertEquals(null, ctrl.mp_Rule.Object_Name__c, 'Rule field Object_Name__c not as expected');
		system.assertEquals(null, ctrl.mp_Rule.Field_Name__c, 'Rule field Field_Name__c not as expected');
		system.assertEquals(null, ctrl.mp_Rule.Field_Value_text__c, 'Rule field Field_Value_text__c not as expected');
		system.assertEquals('Opportunity', ctrl.mp_Rule.When_to_Ask__c, 'Rule field When_to_Ask__c not as expected');
		system.assertEquals('Order__c', ctrl.mp_Rule.When_to_View__c, 'Rule field When_to_View__c not as expected');
		system.assertEquals('Here is some help text', ctrl.mp_Rule.Help_Text__c, 'Rule field Help_Text__c not as expected');
		system.assertEquals(true, ctrl.mp_Rule.Enable_Field_Tracking__c, 'Rule field Enable_Field_Tracking__c not as expected');
		system.assertEquals(true, ctrl.mp_Rule.isActive__c, 'Rule field isActive__c not as expected');

		/***********************************************************************************************************
			Hit Clone again - this should fail as we haven't completed the data filter
		***********************************************************************************************************/
		ctrl.actionClone();

		// Inspect the results
		li_PageMessages = ApexPages.getMessages();

		// We should have one info and THREE error messages
		system.assertEquals(4, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg1 = false;
		boolean bFoundMsg2 = false;
		boolean bFoundMsg3 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_OBJECT)
			{
				bFoundMsg1 = true;
				system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
			}
			else if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_FIELD)
			{
				bFoundMsg2 = true;
				system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
			}
			else if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_VALUE)
			{
				bFoundMsg3 = true;
				system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
			}
		}

		system.assertEquals(true, bFoundMsg1, 'Validation error for Object missing');
		system.assertEquals(true, bFoundMsg2, 'Validation error for Field missing');
		system.assertEquals(true, bFoundMsg3, 'Validation error for Value missing');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Tests the call made from CS_RulesBySection method actionAddRelatedRecordRule, then Clones the record
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testAddRelatedRecordRule()
	{
		// Create test data

		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', 'ABC');
		sP.put('source', CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD);
		sP.put('pageNo', '3');
		sP.put('pageNoRR', '1');

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();

		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_CREATERULE, ctrl.mp_SectionTitle, 'Section title is incorrect');
		system.assertEquals(CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD, ctrl.mp_Rule.Answer_Source__c, 'Rule field Answer_Source__c not as expected');
		system.assertEquals(null, ctrl.mp_strQuestion, 'Variable mp_strQuestion not as expected');

		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bEditMode, 'Display boolean not as expected');

		/***********************************************************************************************************
			Complete and save the Rule
		***********************************************************************************************************/
		ctrl.mp_Rule.Related_Field_Label__c = 'Sales Rep Name';
		ctrl.mp_Rule.Related_Object_Name__c = 'Opportunity';
		ctrl.mp_Rule.Related_Field_name__c = 'Owner.Name';
		ctrl.mp_Rule.Help_Text__c = 'Here is some help text';
		ctrl.mp_Rule.When_to_View__c = 'Opportunity';
		ctrl.mp_Rule.Sequence_Number__c = 10;
		ctrl.mp_Rule.isActive__c = true;

		ctrl.actionSave();

		/***********************************************************************************************************
			Clone
		***********************************************************************************************************/
		ctrl.actionClone();

		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_CREATERULE, ctrl.mp_SectionTitle, 'Section title is incorrect');
		system.assertEquals('ABC', ctrl.mp_strSection, 'Section name is incorrect');
		
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bEditMode, 'Display boolean not as expected');

		// We should have an info message
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');
		system.assertEquals(CS_Questions_Utilities.RECORDSAVED, li_PageMessages[0].getDetail(), 'Message not as expected');
		system.assertEquals(ApexPages.Severity.INFO, li_PageMessages[0].getSeverity(), 'Message severity not as expected');

		// We should have a clone of the original record with all details except the data filter populated
		system.assertEquals(null, ctrl.mp_Rule.id, 'Rule id not as expected');
		system.assertEquals(CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD, ctrl.mp_Rule.Answer_Source__c, 'Rule field Answer_Source__c not as expected');
		system.assertEquals(null, ctrl.mp_Rule.Question2__c, 'Rule field Question2__c not as expected');
		system.assertEquals(null, ctrl.mp_Rule.Question_Type__c, 'Rule field Question_Type__c not as expected');
		system.assertEquals(null, ctrl.mp_Rule.Related_Object_Name__c, 'Rule field Related_Object_Name__c not as expected');
		system.assertEquals(null, ctrl.mp_Rule.Related_Field_Name__c, 'Rule field Related_Field_Name__c not as expected');
		system.assertEquals(null, ctrl.mp_Rule.Field_Value_text__c, 'Rule field Field_Value_text__c not as expected');
		system.assertEquals(null, ctrl.mp_Rule.When_to_Ask__c, 'Rule field When_to_Ask__c not as expected');
		system.assertEquals('Opportunity', ctrl.mp_Rule.When_to_View__c, 'Rule field When_to_View__c not as expected');
		system.assertEquals('Here is some help text', ctrl.mp_Rule.Help_Text__c, 'Rule field Help_Text__c not as expected');
		system.assertEquals(false, ctrl.mp_Rule.Enable_Field_Tracking__c, 'Rule field Enable_Field_Tracking__c not as expected');
		system.assertEquals(true, ctrl.mp_Rule.isActive__c, 'Rule field isActive__c not as expected');

		/***********************************************************************************************************
			Hit Clone again - this should fail as we haven't completed the data filter
		***********************************************************************************************************/
		ctrl.actionClone();

		// Inspect the results
		li_PageMessages = ApexPages.getMessages();

		system.debug('*** li_PageMessages ***' + li_PageMessages);

		// We should have one info and THREE error messages
		system.assertEquals(4, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg1 = false;
		boolean bFoundMsg2 = false;
		boolean bFoundMsg3 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_RELATEDDATALABEL)
			{
				bFoundMsg1 = true;
				system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
			}
			else if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_RELATEDOBJECT)
			{
				bFoundMsg2 = true;
				system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
			}
			else if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_RELATEDFIELD)
			{
				bFoundMsg3 = true;
				system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
			}
		}

		system.assertEquals(true, bFoundMsg1, 'Validation error for Field Label missing');
		system.assertEquals(true, bFoundMsg2, 'Validation error for Object missing');
		system.assertEquals(true, bFoundMsg3, 'Validation error for Field missing');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Tests the call made from CS_RulesBySection method actionEdit
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
/*	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testEditGeneralQuestionRule()
	{
		// Create test data

		// Accounts
		list<Account> li_AccountstoInsert = new list<Account>();
		
		li_AccountstoInsert.add(new Account(Name = 'Test Account 1', No_Parent_Account__c = true, Industry = 'Electronics'));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 2', No_Parent_Account__c = true, Industry = 'Electronics'));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 3', No_Parent_Account__c = true, Industry = 'Chemicals'));
		
		insert li_AccountstoInsert;

		// Question
		Question2__c sQuestion = new Question2__c(
			Section__c			= 'ABC',
			Question_Text__c	= 'This is Question #1',
			isActive__c			= true
			);
		
		insert sQuestion;
		
		// Rule
		Rule__c sRule = new Rule__c(
			Question2__c				= sQuestion.id,
			Question_Type__c			= CS_Questions_Utilities.QUESTIONTYPE_GENERAL,
			Answer_Source__c			= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Field_Name__c				= 'StageName',
			Field_Data_Type__c			= 'PICKLIST',
			Field_Value_Text__c			= 'Closed Won',
			Object_Name__c				= 'Opportunity',
			When_to_Ask__c				= 'Opportunity',
			When_to_View__c				= 'Order__c',
			Help_Text__c				= 'Here is some help text',
			Enable_Field_Tracking__c	= true,
			isActive__c					= true
			);
		
		insert sRule;

		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', sRule.Id);
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', 'ABC');

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
/*		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bEditMode, 'Display boolean not as expected');

		// Check that the existing data is displayed correctly
		system.assertEquals(sRule.id, ctrl.mp_Rule.id, 'Rule not as expected');
		system.assertEquals(sRule.Answer_Source__c, ctrl.mp_Rule.Answer_Source__c, 'Rule field Answer_Source__c not as expected');

		system.assertEquals(sRule.Question2__c, ctrl.mp_Rule.Question2__c, 'Rule field Question2__c not as expected');
		system.assertEquals(sQuestion.Question_Text__c, ctrl.mp_strQuestion, 'mp_strQuestion not as expected');

		system.assertEquals(sRule.Question_Type__c, ctrl.mp_Rule.Question_Type__c, 'Rule field Question_Type__c not as expected');
		system.assertEquals(sRule.Question_Type__c, ctrl.mp_strQuestionType, 'mp_strQuestionType not as expected');

		system.assertEquals(sRule.Object_Name__c, ctrl.mp_Rule.Object_Name__c, 'Rule field Object_Name__c not as expected');
		system.assertEquals(sRule.Field_Name__c, ctrl.mp_Rule.Field_Name__c, 'Rule field Field_Name__c not as expected');
		
		system.assertEquals(sRule.Field_Value_Text__c, ctrl.mp_Rule.Field_Value_Text__c, 'Rule field Field_Value_Text__c not as expected');
		system.assertEquals(sRule.Field_Value_Text__c, ctrl.mp_strFilterPicklist1Value, 'mp_strFilterPicklist1Value not as expected');

		system.assertEquals(sRule.Related_Object_Name__c, ctrl.mp_Rule.Related_Object_Name__c, 'Rule field Related_Object_Name__c not as expected');
		system.assertEquals(sRule.Related_Field_Name__c, ctrl.mp_Rule.Related_Field_Name__c, 'Rule field Related_Field_Name__c not as expected');

		system.assertEquals(sRule.Field_Value_text__c, ctrl.mp_Rule.Field_Value_text__c, 'Rule field Field_Value_text__c not as expected');
		system.assertEquals(sRule.When_to_Ask__c, ctrl.mp_Rule.When_to_Ask__c, 'Rule field When_to_Ask__c not as expected');
		system.assertEquals(sRule.When_to_View__c, ctrl.mp_Rule.When_to_View__c, 'Rule field When_to_View__c not as expected');
		system.assertEquals(sRule.Help_Text__c, ctrl.mp_Rule.Help_Text__c, 'Rule field Help_Text__c not as expected');
		system.assertEquals(sRule.Enable_Field_Tracking__c, ctrl.mp_Rule.Enable_Field_Tracking__c, 'Rule field Enable_Field_Tracking__c not as expected');
		system.assertEquals(sRule.isActive__c, ctrl.mp_Rule.isActive__c, 'Rule field isActive__c not as expected');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Tests the call made from CS_RulesBySection method actionEdit
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
/*	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testEditUniversalQuestionRule()
	{
		// Create test data

		// Accounts
		list<Account> li_AccountstoInsert = new list<Account>();
		
		li_AccountstoInsert.add(new Account(Name = 'Test Account 1', No_Parent_Account__c = true, Industry = 'Electronics'));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 2', No_Parent_Account__c = true, Industry = 'Electronics'));
		li_AccountstoInsert.add(new Account(Name = 'Test Account 3', No_Parent_Account__c = true, Industry = 'Chemicals'));
		
		insert li_AccountstoInsert;

		// Question
		Question2__c sQuestion = new Question2__c(
			Section__c			= 'ABC',
			Question_Text__c	= 'This is Question #1',
			isActive__c			= true
			);
		
		insert sQuestion;
		
		// Rule
		Rule__c sRule = new Rule__c(
			Question2__c				= sQuestion.id,
			Question_Type__c			= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Answer_Source__c			= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			When_to_Ask__c				= 'Opportunity',
			When_to_View__c				= 'Order__c',
			Help_Text__c				= 'Here is some help text',
			Enable_Field_Tracking__c	= true,
			isActive__c					= true
			);
		
		insert sRule;

		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', sRule.Id);
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', 'ABC');

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
/*		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bEditMode, 'Display boolean not as expected');

		// Check that the existing data is displayed correctly
		system.assertEquals(sRule.id, ctrl.mp_Rule.id, 'Rule not as expected');
		system.assertEquals(sRule.Answer_Source__c, ctrl.mp_Rule.Answer_Source__c, 'Rule field Answer_Source__c not as expected');

		system.assertEquals(sRule.Question2__c, ctrl.mp_Rule.Question2__c, 'Rule field Question2__c not as expected');
		system.assertEquals(sQuestion.Question_Text__c, ctrl.mp_strQuestion, 'mp_strQuestion not as expected');

		system.assertEquals(sRule.Question_Type__c, ctrl.mp_Rule.Question_Type__c, 'Rule field Question_Type__c not as expected');
		system.assertEquals(sRule.Question_Type__c, ctrl.mp_strQuestionType, 'mp_strQuestionType not as expected');

		system.assertEquals(sRule.Object_Name__c, ctrl.mp_Rule.Object_Name__c, 'Rule field Object_Name__c not as expected');
		system.assertEquals(sRule.Field_Name__c, ctrl.mp_Rule.Field_Name__c, 'Rule field Field_Name__c not as expected');
		
		system.assertEquals(sRule.Field_Value_Text__c, ctrl.mp_Rule.Field_Value_Text__c, 'Rule field Field_Value_Text__c not as expected');
		system.assertEquals(sRule.Field_Value_Text__c, ctrl.mp_strFilterPicklist1Value, 'mp_strFilterPicklist1Value not as expected');

		system.assertEquals(sRule.Related_Object_Name__c, ctrl.mp_Rule.Related_Object_Name__c, 'Rule field Related_Object_Name__c not as expected');
		system.assertEquals(sRule.Related_Field_Name__c, ctrl.mp_Rule.Related_Field_Name__c, 'Rule field Related_Field_Name__c not as expected');

		system.assertEquals(sRule.Field_Value_text__c, ctrl.mp_Rule.Field_Value_text__c, 'Rule field Field_Value_text__c not as expected');
		system.assertEquals(sRule.When_to_Ask__c, ctrl.mp_Rule.When_to_Ask__c, 'Rule field When_to_Ask__c not as expected');
		system.assertEquals(sRule.When_to_View__c, ctrl.mp_Rule.When_to_View__c, 'Rule field When_to_View__c not as expected');
		system.assertEquals(sRule.Help_Text__c, ctrl.mp_Rule.Help_Text__c, 'Rule field Help_Text__c not as expected');
		system.assertEquals(sRule.Enable_Field_Tracking__c, ctrl.mp_Rule.Enable_Field_Tracking__c, 'Rule field Enable_Field_Tracking__c not as expected');
		system.assertEquals(sRule.isActive__c, ctrl.mp_Rule.isActive__c, 'Rule field isActive__c not as expected');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Tests the call made from CS_RulesBySection method actionEdit
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
/*	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testEditRelatedRecordRule()
	{
		// Create test data
		
		// Rule
		Rule__c sRule = new Rule__c(
			Question2__c				= null,
			Question_Type__c			= null,
			Answer_Source__c			= CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD,
			Related_Object_Name__c		= 'Opportunity',
			Related_Field_name__c		= 'Owner.Name',
			When_to_View__c				= 'Opportunity',
			Help_Text__c				= 'Here is some help text',
			Enable_Field_Tracking__c	= true,
			isActive__c					= true
			);
		
		insert sRule;

		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureRule);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', sRule.Id);
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', 'ABC');

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
/*		CS_ConfigureRule_Controller ctrl = new CS_ConfigureRule_Controller();
		ctrl.init();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowAnswerSource, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestions, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowQuestionTypes, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowRelatedObjectFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowDataFilter, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_bShowValue1, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowConfig, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bEditMode, 'Display boolean not as expected');

		// Check that the existing data is displayed correctly
		system.assertEquals(sRule.id, ctrl.mp_Rule.id, 'Rule not as expected');
		system.assertEquals(sRule.Answer_Source__c, ctrl.mp_Rule.Answer_Source__c, 'Rule field Answer_Source__c not as expected');

		system.assertEquals(sRule.Question2__c, ctrl.mp_Rule.Question2__c, 'Rule field Question2__c not as expected');
		system.assertEquals(null, ctrl.mp_strQuestion, 'mp_strQuestion not as expected');

		system.assertEquals(sRule.Question_Type__c, ctrl.mp_Rule.Question_Type__c, 'Rule field Question_Type__c not as expected');
		system.assertEquals(sRule.Question_Type__c, ctrl.mp_strQuestionType, 'mp_strQuestionType not as expected');

		system.assertEquals(sRule.Object_Name__c, ctrl.mp_Rule.Object_Name__c, 'Rule field Object_Name__c not as expected');
		system.assertEquals(sRule.Field_Name__c, ctrl.mp_Rule.Field_Name__c, 'Rule field Field_Name__c not as expected');
		
		system.assertEquals(sRule.Field_Value_Text__c, ctrl.mp_Rule.Field_Value_Text__c, 'Rule field Field_Value_Text__c not as expected');
		system.assertEquals(sRule.Field_Value_Text__c, ctrl.mp_strFilterPicklist1Value, 'mp_strFilterPicklist1Value not as expected');

		system.assertEquals(sRule.Related_Object_Name__c, ctrl.mp_Rule.Related_Object_Name__c, 'Rule field Related_Object_Name__c not as expected');
		system.assertEquals(sRule.Related_Field_Name__c, ctrl.mp_Rule.Related_Field_Name__c, 'Rule field Related_Field_Name__c not as expected');

		system.assertEquals(sRule.Field_Value_text__c, ctrl.mp_Rule.Field_Value_text__c, 'Rule field Field_Value_text__c not as expected');
		system.assertEquals(sRule.When_to_Ask__c, ctrl.mp_Rule.When_to_Ask__c, 'Rule field When_to_Ask__c not as expected');
		system.assertEquals(sRule.When_to_View__c, ctrl.mp_Rule.When_to_View__c, 'Rule field When_to_View__c not as expected');
		system.assertEquals(sRule.Help_Text__c, ctrl.mp_Rule.Help_Text__c, 'Rule field Help_Text__c not as expected');
		system.assertEquals(sRule.Enable_Field_Tracking__c, ctrl.mp_Rule.Enable_Field_Tracking__c, 'Rule field Enable_Field_Tracking__c not as expected');
		system.assertEquals(sRule.isActive__c, ctrl.mp_Rule.isActive__c, 'Rule field isActive__c not as expected');
	}
*/
}
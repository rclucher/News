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
private class CS_ConfigureAction_Test
{
	@testSetup static void runSetupUtil()
	{
		
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testNewAction()
	{
		// Test data
		// Questions
		list<Question2__c> li_QuestionstoInsert = new list<Question2__c>();
		
		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= 'Campaign Goals',
			Question_Text__c	= 'What is the target Postcode?',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= 'Campaign Goals',
			Question_Text__c	= 'Radius in km',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_NUMBER,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= 'Campaign Goals',
			Question_Text__c	= 'Geotargetting Postcodes',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			));
		
		insert li_QuestionstoInsert;
		
		// Rules
		list<Rule__c> li_RulestoInsert = new list<Rule__c>();
		
		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[0].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 10,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[1].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 20,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[2].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 30,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		insert li_RulestoInsert;

		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureAction);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_ConfigureAction_Controller ctrl = new CS_ConfigureAction_Controller();
		ctrl.init();
		
		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_CREATEACTION, ctrl.mp_SectionTitle, 'Page title not as expected');
		system.assertEquals(new Questionnaire_Action__c(), ctrl.mp_Action, 'Action not as expected');
		system.assertEquals(true, ctrl.mp_bEditAction, 'mp_bEditAction not as expected');
		system.assertEquals(false, ctrl.mp_bEditParameters, 'mp_bEditParameters not as expected');
		system.assertEquals(false, ctrl.mp_bEditRule, 'mp_bEditRule not as expected');
		system.assertEquals(null, ctrl.mp_RuleId, 'mp_RuleId not as expected');

		/***********************************************************************************************************
			Validation
		***********************************************************************************************************/
		pageReference pageRef = ctrl.actionSaveAction();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		
		// We should have THREE error messages
		system.assertEquals(3, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg1 = false;
		boolean bFoundMsg2 = false;
		boolean bFoundMsg3 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_ACTIONNAME)
				bFoundMsg1 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_CLASSNAME)
				bFoundMsg2 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_METHODNAME)
				bFoundMsg3 = true;
			
			// All should be error messages
			system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg1, 'Validation error for Action Name missing');
		system.assertEquals(true, bFoundMsg2, 'Validation error for Service Class name missing');
		system.assertEquals(true, bFoundMsg3, 'Validation error for Service Method name missing');

		// Supply required data
		ctrl.mp_Action.Name					= 'GeoNames';
		ctrl.mp_Rule.Service_Class_Name__c	= 'CS_GeoNames_Utilities';
		ctrl.mp_Rule.Service_Method_Name__c	= 'findNearbyPostalCodes';

		pageRef = ctrl.actionSaveAction();

		// Inspect the results
		li_PageMessages = ApexPages.getMessages();
		
		// We should have the pre-existing error messages plus a success message
		system.assertEquals(4, li_PageMessages.size(), 'Number of messages not as expected');

		boolean bFoundMsg4 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() != CS_Questions_Utilities.RECORDSAVED)
				continue;

			bFoundMsg4 = true;
			
			// Should be info message
			system.assertEquals(ApexPages.Severity.INFO, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg4, 'Success message for Save Action missing');

		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_EDITACTION, ctrl.mp_SectionTitle, 'Page title not as expected');
		system.assertNotEquals(new Questionnaire_Action__c(), ctrl.mp_Action, 'Action not as expected');
		system.assertEquals(false, ctrl.mp_bEditAction, 'mp_bEditAction not as expected');
		system.assertEquals(true, ctrl.mp_bEditParameters, 'mp_bEditParameters not as expected');
		system.assertEquals(false, ctrl.mp_bEditRule, 'mp_bEditRule not as expected');
		system.assertEquals(null, ctrl.mp_RuleId, 'mp_RuleId not as expected');

		/***********************************************************************************************************
			Add a Rule
		***********************************************************************************************************/
		ctrl.mp_InputOutput = 'Input';
		ctrl.actionAddRule();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bEditRule, 'mp_bEditRule not as expected');
		system.assertEquals(ctrl.mp_Action.id, ctrl.mp_liInputs[0].Rule.Questionnaire_Action__c, 'Rule Action id not as expected');
		system.assertEquals('CS_GeoNames_Utilities', ctrl.mp_liInputs[0].Rule.Service_Class_Name__c, 'Rule Class Name not as expected');
		system.assertEquals('findNearbyPostalCodes', ctrl.mp_liInputs[0].Rule.Service_Method_Name__c, 'Rule Method Name not as expected');
		system.assertEquals('Input', ctrl.mp_liInputs[0].Rule.Input_Output__c, 'Rule Input / Output not as expected');
		system.assertEquals(true, ctrl.mp_liInputs[0].li_Questions.isEmpty(), 'Question picklist not initialised');

		/***********************************************************************************************************
			Validation
		***********************************************************************************************************/
		ctrl.mp_RuleId = null;
		ctrl.actionSaveRule();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages2 = ApexPages.getMessages();
		
		// We should have SEVEN error messages
		system.assertEquals(7, li_PageMessages2.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg5 = false;
		boolean bFoundMsg6 = false;
		boolean bFoundMsg7 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages2)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_ACTIONRULESECTION)
			{
				bFoundMsg5 = true;
				system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
			}

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_ACTIONRULEQUESTION)
			{
				bFoundMsg6 = true;
				system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
			}

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_ACTIONRULELABEL)
			{
				bFoundMsg7 = true;
				system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
			}
		}

		system.assertEquals(true, bFoundMsg5, 'Validation error for Rule Section missing');
		system.assertEquals(true, bFoundMsg6, 'Validation error for Rule Question missing');
		system.assertEquals(true, bFoundMsg7, 'Validation error for Rule Parameter name missing');

		/***********************************************************************************************************
			Enter correct data and save
		***********************************************************************************************************/
		// Define the Section
		ctrl.mp_liInputs[0].Section = 'Campaign Goals';
		
		ctrl.actionRebuildQuestionPicklist();
		
		// Inspect the results
		system.assertEquals(false, ctrl.mp_liInputs[0].li_Questions.isEmpty(), 'Question picklist not populated');
		system.assertEquals(4, ctrl.mp_liInputs[0].li_Questions.size(), 'Question picklist does not have correct number of Questions');
		
		// Pick a Question and complete the Rule
		ctrl.mp_liInputs[0].QuestionId = li_QuestionstoInsert[0].id;
		ctrl.mp_liInputs[0].Rule.Parameter_Label__c = 'postcode';
		ctrl.mp_liInputs[0].Rule.isActive__c = true;
		
		ctrl.actionSaveRule();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages3 = ApexPages.getMessages();
		
		// We should still have SEVEN error messages
		system.assertEquals(7, li_PageMessages3.size(), 'Number of messages not as expected');
		
		// Get the record
		list<Rule__c> li_Rules =	[	select	id,
												Questionnaire_Action__c,
												Question2__c,
												Input_Output__c,
												Service_Class_Name__c,
												Service_Method_Name__c,
												Parameter_Label__c,
												isActive__c
										from	Rule__c
										where	Question2__c = : li_QuestionstoInsert[0].id
										and		Answer_Source__c = null
									];
		
		system.assertEquals(false, li_Rules.isEmpty(), 'Rule was not created / linked to the Question');
		system.assertEquals(ctrl.mp_Action.id, li_Rules[0].Questionnaire_Action__c, 'Rule field Questionnaire_Action__c not as expected');
		system.assertEquals('Input', li_Rules[0].Input_Output__c, 'Rule field Input_Output__c not as expected');
		system.assertEquals('CS_GeoNames_Utilities', li_Rules[0].Service_Class_Name__c, 'Rule field Service_Class_Name__c not as expected');
		system.assertEquals('findNearbyPostalCodes', li_Rules[0].Service_Method_Name__c, 'Rule field Service_Method_Name__c not as expected');
		system.assertEquals('postcode', li_Rules[0].Parameter_Label__c, 'Rule field Parameter_Label__c not as expected');
		system.assertEquals(true, li_Rules[0].isActive__c, 'Rule field isActive__c not as expected');

		/***********************************************************************************************************
			Click on Cancel button
		***********************************************************************************************************/
		pageReference pageRef2 = ctrl.actionCancel();

		// Inspect the results
		system.assertEquals(true, pageRef2.getRedirect(), 'PageReference redirect boolean not as expected');
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testEditAction()
	{
		// Create some test data
		// Questions
		list<Question2__c> li_QuestionstoInsert = new list<Question2__c>();
		
		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= 'Campaign Goals',
			Question_Text__c	= 'What is the target Postcode?',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= 'Campaign Goals',
			Question_Text__c	= 'Radius in km',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_NUMBER,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= 'Campaign Goals',
			Question_Text__c	= 'Geotargetting Postcodes',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			));
		
		insert li_QuestionstoInsert;
		
		// Questionnaire Action
		Questionnaire_Action__c sQuestionnaireAction = new Questionnaire_Action__c(
			Name = 'GeoNames',
			isActive__c = true
			);
		
		insert sQuestionnaireAction;
		
		// Rules
		list<Rule__c> li_RulestoInsert = new list<Rule__c>();
		
		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[0].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 10,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[1].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 20,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[2].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 30,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[0].id,
			Questionnaire_Action__c	= sQuestionnaireAction.id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'postcode',
			Input_Output__c			= 'Input',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[1].id,
			Questionnaire_Action__c	= sQuestionnaireAction.id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'radius',
			Input_Output__c			= 'Input',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[2].id,
			Questionnaire_Action__c	= sQuestionnaireAction.id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'postcodes',
			Input_Output__c			= 'Output',
			isActive__c				= true
			));
		
		insert li_RulestoInsert;

		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureAction);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', sQuestionnaireAction.id);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_ConfigureAction_Controller ctrl = new CS_ConfigureAction_Controller();
		ctrl.init();

		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_EDITACTION, ctrl.mp_SectionTitle, 'Page title not as expected');
		system.assertNotEquals(new Questionnaire_Action__c(), ctrl.mp_Action, 'Action not as expected');
		system.assertEquals(false, ctrl.mp_bEditAction, 'mp_bEditAction not as expected');
		system.assertEquals(true, ctrl.mp_bEditParameters, 'mp_bEditParameters not as expected');
		system.assertEquals(false, ctrl.mp_bEditRule, 'mp_bEditRule not as expected');
		system.assertEquals(null, ctrl.mp_RuleId, 'mp_RuleId not as expected');
		
		system.assertEquals(false, ctrl.mp_liInputs.isEmpty(), 'Input Rules list not populated');
		system.assertEquals(2, ctrl.mp_liInputs.size(), 'Input Rules list size not as expected');
		system.assertEquals(false, ctrl.mp_liOutputs.isEmpty(), 'Output Rules list not populated');
		system.assertEquals(1, ctrl.mp_liOutputs.size(), 'Output Rules list size not as expected');		
		
		/***********************************************************************************************************
			Edit a Rule
		***********************************************************************************************************/
		ctrl.mp_InputOutput = 'Input';
		ctrl.mp_RuleId = li_RulestoInsert[3].id;
		ctrl.actionEditRule();
		
		// Inspect the results
		system.assertEquals(true, ctrl.mp_bEditRule, 'mp_bEditRule not as expected');

		/***********************************************************************************************************
			Cancel
		***********************************************************************************************************/
		ctrl.actionCancelEditRule();

		// Inspect the results
		system.assertEquals(false, ctrl.mp_bEditRule, 'mp_bEditRule not as expected');

		/***********************************************************************************************************
			Edit and save
		***********************************************************************************************************/
		ctrl.mp_InputOutput = 'Output';
		ctrl.mp_RuleId = li_RulestoInsert[5].id;
		ctrl.actionEditRule();
		
		// Inspect the results
		system.assertEquals(true, ctrl.mp_bEditRule, 'mp_bEditRule not as expected');
		system.assertEquals(false, ctrl.mp_liOutputs[0].bReadOnly, 'Read-only flag not as expected');
		
		ctrl.mp_liOutputs[0].Rule.isActive__c = false;

		ctrl.actionSaveRule();

		// Inspect the results
		// Get the record
		list<Rule__c> li_Rules =	[	select	id,
												Questionnaire_Action__c,
												Question2__c,
												Input_Output__c,
												Service_Class_Name__c,
												Service_Method_Name__c,
												Parameter_Label__c,
												isActive__c
										from	Rule__c
										where	Question2__c = : li_QuestionstoInsert[2].id
										and		Answer_Source__c = null
									];
		
		system.assertEquals(false, li_Rules.isEmpty(), 'Rule was not created / linked to the Question');
		system.assertEquals(ctrl.mp_Action.id, li_Rules[0].Questionnaire_Action__c, 'Rule field Questionnaire_Action__c not as expected');
		system.assertEquals('Output', li_Rules[0].Input_Output__c, 'Rule field Input_Output__c not as expected');
		system.assertEquals('CS_GeoNames_Utilities', li_Rules[0].Service_Class_Name__c, 'Rule field Service_Class_Name__c not as expected');
		system.assertEquals('findNearbyPostalCodes', li_Rules[0].Service_Method_Name__c, 'Rule field Service_Method_Name__c not as expected');
		system.assertEquals('postcodes', li_Rules[0].Parameter_Label__c, 'Rule field Parameter_Label__c not as expected');
		system.assertEquals(false, li_Rules[0].isActive__c, 'Rule field isActive__c not as expected');

		/***********************************************************************************************************
			Delete a Rule
		***********************************************************************************************************/
		ctrl.mp_InputOutput = 'Input';
		ctrl.mp_RuleId = li_RulestoInsert[4].id;
		ctrl.actionDeleteRule();
		
		// Inspect the results
		system.assertEquals(1, ctrl.mp_liInputs.size(), 'Input Rules list size not as expected');
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testDuplicatedOutput()
	{
		// Create some test data
		// Questions
		list<Question2__c> li_QuestionstoInsert = new list<Question2__c>();
		
		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= 'Campaign Goals',
			Question_Text__c	= 'Geotargetting Postcodes #1',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= 'Campaign Goals',
			Question_Text__c	= 'Geotargetting Postcodes #2',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			));
		
		insert li_QuestionstoInsert;
		
		// Questionnaire Actions
		list<Questionnaire_Action__c> li_QAstoInsert = new list<Questionnaire_Action__c>();
		
		li_QAstoInsert.add(new Questionnaire_Action__c(
			Name = 'GeoNames 1',
			isActive__c = true
			));

		li_QAstoInsert.add(new Questionnaire_Action__c(
			Name = 'GeoNames 2',
			isActive__c = true
			));
		
		insert li_QAstoInsert;
		
		// Rules
		list<Rule__c> li_RulestoInsert = new list<Rule__c>();
		
		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[0].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 10,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[0].id,
			Questionnaire_Action__c	= li_QAstoInsert[0].id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'postcodes',
			Input_Output__c			= 'Output',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[1].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 20,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[1].id,
			Questionnaire_Action__c	= li_QAstoInsert[1].id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'postcodes',
			Input_Output__c			= 'Output',
			isActive__c				= true
			));
		
		insert li_RulestoInsert;

		// Set up the page
		test.setCurrentPage(Page.CS_ConfigureAction);

		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', li_QAstoInsert[1].id);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_ConfigureAction_Controller ctrl = new CS_ConfigureAction_Controller();
		ctrl.init();

		/***********************************************************************************************************
			Edit and save
		***********************************************************************************************************/
		ctrl.mp_InputOutput = 'Output';
		ctrl.mp_RuleId = li_RulestoInsert[3].id;
		ctrl.actionEditRule();
		
		// Point to the same Question (and therefore Answer) as the first Action
		ctrl.mp_liOutputs[0].QuestionId = li_QuestionstoInsert[0].id;

		ctrl.actionSaveRule();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		
		// We should have one error message
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg1 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == 'The Action GeoNames 1 is already populating the Answer to the Question Geotargetting Postcodes #1')
				bFoundMsg1 = true;

			system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg1, 'Validation error missing');
	}

}
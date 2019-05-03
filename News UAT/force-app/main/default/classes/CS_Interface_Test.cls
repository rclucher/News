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
private class CS_Interface_Test
{
	@testSetup static void runSetupUtil()
	{
		
	}

	/***********************************************************************************************************
		General
	***********************************************************************************************************/
	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Run the clearAnswers method
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void test_ClearAnswers()
	{
		// Create test data

		// First we need to get an active value from the Section picklist on the Question2 object
		map<string, SObjectType> map_ObjectToSObjectTypes = Schema.getGlobalDescribe();
		SObjectType sObjType = map_ObjectToSObjectTypes.get('question2__c');
		SObjectField sObjField = sObjType.getDescribe().fields.getMap().get('section__c');
		DescribeFieldResult descFieldResult = SObjField.getDescribe();

		list<string> li_ActiveSectionNames = new list<string>();
		
		for (schema.PicklistEntry sPLE : descFieldResult.getPicklistValues())
		{
			if (sPLE.isActive())
				li_ActiveSectionNames.add(sPLE.getValue());
		}

		// Accounts
		Account sAccount = new Account(Name = 'Test Account 1', No_Parent_Account__c = true);
		insert sAccount;

		// Opportunity
		Opportunity sOpportunity = new Opportunity(Name = 'Test 1', AccountId = sAccount.id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5));
		insert sOpportunity;

		// Questions
		list<Question2__c> li_QuestionstoInsert = new list<Question2__c>();
		
		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'What is the target Postcode?',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'Radius in km',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_NUMBER,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
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
		
		// Fire up the controller
		CS_QuestionnaireService ctrl = new CS_QuestionnaireService();

		ctrl.buildQuestionsForDisplay(sOpportunity.id, true);

		// Provide some answers
		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : ctrl.mp_liQuestions)
		{
			if (SectionWrapper.SectionName == li_ActiveSectionNames[0])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'Geotargetting Postcodes')
					{
						QuestionWrapper.Answer.Answer_Long_Text__c = '2111 - Gladesville,2112 - Denistone East,2113 - North Ryde';
						
						upsert QuestionWrapper.Answer;
					}
				}
			}
		}

		/***********************************************************************************************************
			Start the test
		***********************************************************************************************************/
		test.startTest();
		
		Answer2__c sAnswer2Before = [select id, Answer_Long_Text__c from Answer2__c where Question2__c = : li_QuestionstoInsert[2].id];

		system.assertEquals(false, string.isBlank(sAnswer2Before.Answer_Long_Text__c), 'Answer not as expected');

		// Run the Interface code to clear existing answers
		CS_Interface_Utilities.clearAnswers(ctrl.mp_liQuestions);
		
		Answer2__c sAnswer2After = [select id, Answer_Long_Text__c from Answer2__c where Question2__c = : li_QuestionstoInsert[2].id];

		system.assertEquals(true, string.isBlank(sAnswer2After.Answer_Long_Text__c), 'Answer text was not cleared');

		/***********************************************************************************************************
			Populate the Answer, then call again with the same parameters - should not be cleared
		***********************************************************************************************************/
		sAnswer2After.Answer_Long_Text__c = 'Here is some long text';
		update sAnswer2After;

		// Create a result record (have to do this manually as we can't call the web service)
		map<string, string> map_Inputs = new map<string, string>();
		map_Inputs.put('postcode', '2000');
		map_Inputs.put('radius', '10');
		 
		Questionnaire_Action_Result__c sQAR = new Questionnaire_Action_Result__c(
			Questionnaire_Action__c	= sQuestionnaireAction.id,
			Opportunity__c			= sOpportunity.id,
			Parameters__c			= JSON.serialize(map_Inputs),
			Success__c				= true);
		
		insert sQAR;

		// Fire up the controller
		CS_QuestionnaireService ctrl2 = new CS_QuestionnaireService();

		ctrl2.buildQuestionsForDisplay(sOpportunity.id, true);

		// Provide some answers
		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : ctrl2.mp_liQuestions)
		{
			if (SectionWrapper.SectionName == li_ActiveSectionNames[0])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'What is the target Postcode?')
					{
						QuestionWrapper.Answer.Answer_Text__c = '2000';
					}
					else if (QuestionWrapper.QuestionText == 'Radius in km')
					{
						QuestionWrapper.Answer.Answer_Numeric__c = 10;
					}
				}
			}
		}
		
		// Run the Interface code again - should NOT clear existing answers
		CS_Interface_Utilities.clearAnswers(ctrl2.mp_liQuestions);
		
		Answer2__c sAnswer2After2 = [select id, Answer_Long_Text__c from Answer2__c where Question2__c = : li_QuestionstoInsert[2].id];

		system.assertEquals(false, string.isBlank(sAnswer2After2.Answer_Long_Text__c), 'Answer text should not have been cleared');
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Makes two calls to the same Service Method
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void test_MultipleCalls()
	{
		// Create test data

		// First we need to get an active value from the Section picklist on the Question2 object
		map<string, SObjectType> map_ObjectToSObjectTypes = Schema.getGlobalDescribe();
		SObjectType sObjType = map_ObjectToSObjectTypes.get('question2__c');
		SObjectField sObjField = sObjType.getDescribe().fields.getMap().get('section__c');
		DescribeFieldResult descFieldResult = SObjField.getDescribe();

		list<string> li_ActiveSectionNames = new list<string>();
		
		for (schema.PicklistEntry sPLE : descFieldResult.getPicklistValues())
		{
			if (sPLE.isActive())
				li_ActiveSectionNames.add(sPLE.getValue());
		}

		// Accounts
		Account sAccount = new Account(Name = 'Test Account 1', No_Parent_Account__c = true);
		insert sAccount;

		// Opportunity
		Opportunity sOpportunity = new Opportunity(Name = 'Test 1', AccountId = sAccount.id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5));
		insert sOpportunity;

		// Questions
		list<Question2__c> li_QuestionstoInsert = new list<Question2__c>();
		
		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'What is the target Postcode?',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'Radius in km',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_NUMBER,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'Geotargetting Postcodes',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[1],
			Question_Text__c	= 'What is the target Postcode?',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[1],
			Question_Text__c	= 'Radius in km',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_NUMBER,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[1],
			Question_Text__c	= 'Geotargetting Postcodes',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			));
		
		insert li_QuestionstoInsert;
		
		// Questionnaire Actions
		list<Questionnaire_Action__c> li_QARs = new list<Questionnaire_Action__c>();
		
		li_QARs.add(new Questionnaire_Action__c(
			Name = 'GeoNames for Section 1',
			isActive__c = true
			));

		li_QARs.add(new Questionnaire_Action__c(
			Name = 'GeoNames for Section 2',
			isActive__c = true
			));
		
		insert li_QARs;
		
		// Rules
		list<Rule__c> li_RulestoInsert = new list<Rule__c>();

		// Section 1		
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
			Questionnaire_Action__c	= li_QARs[0].id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'postcode',
			Input_Output__c			= 'Input',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[1].id,
			Questionnaire_Action__c	= li_QARs[0].id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'radius',
			Input_Output__c			= 'Input',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[2].id,
			Questionnaire_Action__c	= li_QARs[0].id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'postcodes',
			Input_Output__c			= 'Output',
			isActive__c				= true
			));
		
		// Section 2
		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[3].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 10,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[4].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 20,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[5].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 30,
			When_to_Ask__c			= 'Opportunity',
			When_to_View__c			= 'Order__c',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[3].id,
			Questionnaire_Action__c	= li_QARs[1].id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'postcode',
			Input_Output__c			= 'Input',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[4].id,
			Questionnaire_Action__c	= li_QARs[1].id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'radius',
			Input_Output__c			= 'Input',
			isActive__c				= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[5].id,
			Questionnaire_Action__c	= li_QARs[1].id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'postcodes',
			Input_Output__c			= 'Output',
			isActive__c				= true
			));
		
		insert li_RulestoInsert;
		
		// Fire up the controller
		CS_QuestionnaireService ctrl = new CS_QuestionnaireService();

		ctrl.buildQuestionsForDisplay(sOpportunity.id, true);

		// Provide some answers
		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : ctrl.mp_liQuestions)
		{
			if (SectionWrapper.SectionName == li_ActiveSectionNames[0])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'What is the target Postcode?')
					{
						QuestionWrapper.Answer.Answer_Text__c = '2000';
					}
					else if (QuestionWrapper.QuestionText == 'Radius in km')
					{
						QuestionWrapper.Answer.Answer_Numeric__c = 10;
					}
				}
			}
			else if (SectionWrapper.SectionName == li_ActiveSectionNames[1])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'What is the target Postcode?')
					{
						QuestionWrapper.Answer.Answer_Text__c = '2000';
					}
					else if (QuestionWrapper.QuestionText == 'Radius in km')
					{
						QuestionWrapper.Answer.Answer_Numeric__c = 10;
					}
				}
			}
		}
		
		// Set the mock callout class
		test.setMock(HttpCalloutMock.class, new CS_Mockable_Utilities());

		/***********************************************************************************************************
			Start the test
		***********************************************************************************************************/
		test.startTest();

		// Run the Interface code
		CS_Interface_Utilities.makeInterfaceCalls(ctrl.mp_liQuestions);

		/***********************************************************************************************************
			Inspect the result
		***********************************************************************************************************/
		test.stopTest();
		
		set<id> set_QuestionIds = new set<id>();
		set_QuestionIds.add(li_QuestionstoInsert[2].id);
		set_QuestionIds.add(li_QuestionstoInsert[5].id);
		
		map<id, Answer2__c> map_Answers = new map<id, Answer2__c>();
		
		for (Answer2__c sAnswer2 :	[	select	id,
												Question2__c,
												Answer_Long_Text__c
										from	Answer2__c
										where	Question2__c in : set_QuestionIds
									])
		{
			map_Answers.put(sAnswer2.Question2__c, sAnswer2);
		}

		system.assertEquals(false, map_Answers.isEmpty(), 'Answers not found');
		system.assertEquals(2, map_Answers.size(), 'Number of Answers not as expected');
		system.assertEquals(true, map_Answers.containsKey(li_QuestionstoInsert[2].id), 'Answers for first data set not found');
		system.assertEquals(true, map_Answers.containsKey(li_QuestionstoInsert[5].id), 'Answers for second data set not found');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Checks that an Interface Rule marked as inactive is ignored
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Oct 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void test_inActiveRule()
	{
		// Create test data

		// First we need to get an active value from the Section picklist on the Question2 object
		map<string, SObjectType> map_ObjectToSObjectTypes = Schema.getGlobalDescribe();
		SObjectType sObjType = map_ObjectToSObjectTypes.get('question2__c');
		SObjectField sObjField = sObjType.getDescribe().fields.getMap().get('section__c');
		DescribeFieldResult descFieldResult = SObjField.getDescribe();

		list<string> li_ActiveSectionNames = new list<string>();
		
		for (schema.PicklistEntry sPLE : descFieldResult.getPicklistValues())
		{
			if (sPLE.isActive())
				li_ActiveSectionNames.add(sPLE.getValue());
		}

		// Accounts
		Account sAccount = new Account(Name = 'Test Account 1', No_Parent_Account__c = true);
		insert sAccount;

		// Opportunity
		Opportunity sOpportunity = new Opportunity(Name = 'Test 1', AccountId = sAccount.id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5));
		insert sOpportunity;

		// Questions
		list<Question2__c> li_QuestionstoInsert = new list<Question2__c>();
		
		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'What is the target Postcode?',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'Radius in km',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_NUMBER,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
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
			isActive__c				= false
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
		
		// Fire up the controller
		CS_QuestionnaireService ctrl = new CS_QuestionnaireService();

		ctrl.buildQuestionsForDisplay(sOpportunity.id, true);

		// Provide some answers
		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : ctrl.mp_liQuestions)
		{
			if (SectionWrapper.SectionName == li_ActiveSectionNames[0])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'What is the target Postcode?')
					{
						QuestionWrapper.Answer.Answer_Text__c = '2000';
					}
					else if (QuestionWrapper.QuestionText == 'Radius in km')
					{
						QuestionWrapper.Answer.Answer_Numeric__c = 10;
					}
				}
			}
		}
		
		// Set the mock callout class
		test.setMock(HttpCalloutMock.class, new CS_Mockable_Utilities());

		/***********************************************************************************************************
			Start the test
		***********************************************************************************************************/
		test.startTest();

		// Run the Interface code
		CS_Interface_Utilities.makeInterfaceCalls(ctrl.mp_liQuestions);

		/***********************************************************************************************************
			Inspect the result
		***********************************************************************************************************/
		list<Questionnaire_Action_Result__c> li_QARs =	[	select	id,
																	Opportunity__c,
																	Parameters__c,
																	Success__c,
																	Error_Message__c
															from	Questionnaire_Action_Result__c
														];

		system.assertEquals(false, li_QARs.isEmpty(), 'Could not find any QAR records');
		system.assertEquals(false, li_QARs[0].Success__c, 'QAR record not marked as a failure');
	}

	
	/***********************************************************************************************************
		GeoNames
	***********************************************************************************************************/
	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Call the GeoNames method directly with different parameters
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void test_inputParameters()
	{
		// Set the mock callout class
		test.setMock(HttpCalloutMock.class, new CS_Mockable_Utilities());

		CS_GeoNames_Utilities util = new CS_GeoNames_Utilities();

		/***********************************************************************************************************
			Start the test
		***********************************************************************************************************/
		test.startTest();

		// null request
		CS_Interface_Utilities.Response res1 = util.process(null);
		
		system.assertEquals(false, res1.success, 'Call did not return an error');
		system.assertEquals(false, res1.messages.isEmpty(), 'Call did not return an error message');
		system.assertEquals('Missing Request', res1.messages[0], 'Error message not as expected');
		
		// No method name
		CS_Interface_Utilities.Request req2 = new CS_Interface_Utilities.Request();
		CS_Interface_Utilities.Response res2 = util.process(req2);

		system.assertEquals(false, res2.success, 'Call did not return an error');
		system.assertEquals(false, res2.messages.isEmpty(), 'Call did not return an error message');
		system.assertEquals('No method name provided', res2.messages[0], 'Error message not as expected');

		// Invalid method name
		CS_Interface_Utilities.Request req3 = new CS_Interface_Utilities.Request('doSomething');
		CS_Interface_Utilities.Response res3 = util.process(req3);

		system.assertEquals(false, res3.success, 'Call did not return an error');
		system.assertEquals(false, res3.messages.isEmpty(), 'Call did not return an error message');
		system.assertEquals('Method dosomething not found', res3.messages[0], 'Error message not as expected');

		// No input parameters
		CS_Interface_Utilities.Request req4 = new CS_Interface_Utilities.Request('findNearbyPostalCodes');
		CS_Interface_Utilities.Response res4 = util.process(req4);

		system.assertEquals(false, res4.success, 'Call did not return an error');
		system.assertEquals(false, res4.messages.isEmpty(), 'Call did not return an error message');
		system.assertEquals('No input parameters provided', res4.messages[0], 'Error message not as expected');		

		// Required parameters missing
		map<string, string> map_Values = new map<string, string>();
		map_Values.put('rubbish', 'rubbish');
		CS_Interface_Utilities.Request req5 = new CS_Interface_Utilities.Request('findNearbyPostalCodes', map_Values);
		CS_Interface_Utilities.Response res5 = util.process(req5);

		system.assertEquals(false, res5.success, 'Call did not return an error');
		system.assertEquals(false, res5.messages.isEmpty(), 'Call did not return an error message');
		system.assertEquals('One or more of these required parameters is missing: postcode, radius', res5.messages[0], 'Error message not as expected');

		// Ok let's make a valid call and include a country code
		map_Values.put('postcode', '2577');
		map_Values.put('radius', '10');
		CS_Interface_Utilities.Request req6 = new CS_Interface_Utilities.Request('findNearbyPostalCodes', map_Values);
		CS_Interface_Utilities.Response res6 = util.process(req6);

		system.assertEquals(true, res6.success, 'Call was not successful');
		system.assertEquals(true, res6.messages.isEmpty(), 'Call should not return an error message');
		system.assertEquals(true, util.HttpRequest.getEndpoint().contains('&country=AU'), 'Default contry code was not used');

		// Override the default
		map_Values.put('country', 'NZ');
		CS_Interface_Utilities.Request req7 = new CS_Interface_Utilities.Request('findNearbyPostalCodes', map_Values);
		CS_Interface_Utilities.Response res7 = util.process(req7);

		system.assertEquals(true, res7.success, 'Call was not successful');
		system.assertEquals(true, res7.messages.isEmpty(), 'Call should not return an error message');
		system.assertEquals(true, util.HttpRequest.getEndpoint().contains('&country=NZ'), 'Default contry code was not overridden');
	}

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Configure and execute a call to the GeoNames utility class via the Interface utilities
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void test_findNearbyPostalCodes()
	{
		// Create test data

		// First we need to get an active value from the Section picklist on the Question2 object
		map<string, SObjectType> map_ObjectToSObjectTypes = Schema.getGlobalDescribe();
		SObjectType sObjType = map_ObjectToSObjectTypes.get('question2__c');
		SObjectField sObjField = sObjType.getDescribe().fields.getMap().get('section__c');
		DescribeFieldResult descFieldResult = SObjField.getDescribe();

		list<string> li_ActiveSectionNames = new list<string>();
		
		for (schema.PicklistEntry sPLE : descFieldResult.getPicklistValues())
		{
			if (sPLE.isActive())
				li_ActiveSectionNames.add(sPLE.getValue());
		}

		// Accounts
		Account sAccount = new Account(Name = 'Test Account 1', No_Parent_Account__c = true);
		insert sAccount;

		// Opportunity
		Opportunity sOpportunity = new Opportunity(Name = 'Test 1', AccountId = sAccount.id, StageName = 'Identify Prospects', CloseDate = system.today().addDays(5));
		insert sOpportunity;

		// Questions
		list<Question2__c> li_QuestionstoInsert = new list<Question2__c>();
		
		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'What is the target Postcode?',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'Radius in km',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_NUMBER,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'Geotargetting Postcodes',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'Geotargetting Place Names',
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
			Question2__c			= li_QuestionstoInsert[3].id,
			Answer_Source__c		= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c		= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c		= 40,
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

		li_RulestoInsert.add(new Rule__c(
			Question2__c			= li_QuestionstoInsert[3].id,
			Questionnaire_Action__c	= sQuestionnaireAction.id,
			Service_Class_Name__c	= 'CS_GeoNames_Utilities',
			Service_Method_Name__c	= 'findNearbyPostalCodes',
			Parameter_Label__c		= 'placenames',
			Input_Output__c			= 'Output',
			isActive__c				= true
			));
		
		insert li_RulestoInsert;
		
		// Fire up the controller
		CS_QuestionnaireService ctrl = new CS_QuestionnaireService();

		ctrl.buildQuestionsForDisplay(sOpportunity.id, true);

		// Provide some answers
		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : ctrl.mp_liQuestions)
		{
			if (SectionWrapper.SectionName == li_ActiveSectionNames[0])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'What is the target Postcode?')
					{
						QuestionWrapper.Answer.Answer_Text__c = '2000';
					}
					else if (QuestionWrapper.QuestionText == 'Radius in km')
					{
						QuestionWrapper.Answer.Answer_Numeric__c = 10;
					}
				}
			}
		}
		
		// Set the mock callout class
		test.setMock(HttpCalloutMock.class, new CS_Mockable_Utilities());

		/***********************************************************************************************************
			Start the test
		***********************************************************************************************************/
		test.startTest();

		// Run the Interface code
		CS_Interface_Utilities.makeInterfaceCalls(ctrl.mp_liQuestions);

		/***********************************************************************************************************
			Inspect the result
		***********************************************************************************************************/
		// Target postcodes
		Answer2__c sAnswer2A =	[	select	id,
											Question2__c,
											Question_Text__c,
											Section__c,
											Answer_Long_Text__c
									from	Answer2__c
									where	Question2__c = : li_QuestionstoInsert[2].id
								];
		
		system.assertEquals('Geotargetting Postcodes', sAnswer2A.Question_Text__c, 'Field Question_Text__c not as expected');
		system.assertEquals(li_ActiveSectionNames[0], sAnswer2A.Section__c, 'Field Section__c not as expected');
		
		list<string> li_Output = sAnswer2A.Answer_Long_Text__c.split('\n');
		
		system.assertEquals(3, li_Output.size(), 'Number of returned postcodes not as expected');
		system.assertEquals('2111', li_Output[0], 'Postcode order not as expected');
		system.assertEquals('2112', li_Output[1], 'Postcode order not as expected');
		system.assertEquals('2113', li_Output[2], 'Postcode order not as expected');

		// Target plave names
		Answer2__c sAnswer2B =	[	select	id,
											Question2__c,
											Question_Text__c,
											Section__c,
											Answer_Long_Text__c
									from	Answer2__c
									where	Question2__c = : li_QuestionstoInsert[3].id
								];
		
		system.assertEquals('Geotargetting Place Names', sAnswer2B.Question_Text__c, 'Field Question_Text__c not as expected');
		system.assertEquals(li_ActiveSectionNames[0], sAnswer2B.Section__c, 'Field Section__c not as expected');
		
		list<string> li_Output2 = sAnswer2B.Answer_Long_Text__c.split('\n');
		
		system.assertEquals(3, li_Output2.size(), 'Number of returned placenames not as expected');
		system.assertEquals('Denistone East', li_Output2[0], 'Placename order not as expected');
		system.assertEquals('Gladesville', li_Output2[1], 'Placename order not as expected');
		system.assertEquals('North Ryde', li_Output2[2], 'Placename order not as expected');
		
		/***********************************************************************************************************
			Run it a second time - the parameters haven't changed so should not do the callout
		***********************************************************************************************************/
		CS_Interface_Utilities.makeInterfaceCalls(ctrl.mp_liQuestions);
		
		// We don't need an assert here - if a second callout is made, it will cause an exception ;)
	}

}
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
private class CS_QuestionnaireService_Test
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
	Aug 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testAccessfromOpportunity()
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
			Question_Text__c	= 'This is Question #1',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			));

		list<CS_Questions_Utilities.PicklistWrapper> li_PicklistWrappers = new list<CS_Questions_Utilities.PicklistWrapper>();
		li_PicklistWrappers.add(new CS_Questions_Utilities.PicklistWrapper('A', 'A'));
		li_PicklistWrappers.add(new CS_Questions_Utilities.PicklistWrapper('B', 'B'));
		li_PicklistWrappers.add(new CS_Questions_Utilities.PicklistWrapper('C', 'C'));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[0],
			Question_Text__c	= 'This is Question #2',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_PICKLIST,
			Answer_Picklist_Values__c = JSON.serialize(li_PicklistWrappers),
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[1],
			Question_Text__c	= 'This is Question #3',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[1],
			Question_Text__c	= 'This is Question #4',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_LONGTEXT,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[2],
			Question_Text__c	= 'This is Question #5',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_CHECKBOX,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[2],
			Question_Text__c	= 'This is Question #6',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_CURRENCY,
			Minimum_Length__c	= 12,
			Maximum_Length__c	= 20,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[2],
			Question_Text__c	= 'This is Question #7',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_DATE,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[2],
			Question_Text__c	= 'This is Question #8',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_EMAIL,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[2],
			Question_Text__c	= 'This is Question #9',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_NUMBER,
			Minimum_Length__c	= 12,
			Maximum_Length__c	= 20,
			isActive__c			= true
			));

/*		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[2],
			Question_Text__c	= 'This is Question #10',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_PERCENT,
			isActive__c			= true
			));
*/
		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[2],
			Question_Text__c	= 'This is Question #11',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_PHONE,
			Minimum_Length__c	= 12,
			Maximum_Length__c	= 20,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[2],
			Question_Text__c	= 'This is Question #12',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			Minimum_Length__c	= 12,
			Maximum_Length__c	= 20,
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[2],
			Question_Text__c	= 'This is Question #13',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_URL,
			isActive__c			= true
			));
		
		insert li_QuestionstoInsert;

		// Rules
		list<Rule__c> li_RulestoInsert = new list<Rule__c>();
		
		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[0].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 10,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		list<string> li_PicklistValues = new list<string>();
		li_PicklistValues.add('Identify Prospects');

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[1].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_GENERAL,
			Sequence_Number__c	= 20,
			Object_Name_1__c	= 'Opportunity',
			Field_Name_1__c		= 'StageName',
			Field_Data_Type__c	= 'PICKLIST',
			Field_Value_Text__c	= JSON.serialize(li_PicklistValues),
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[2].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 10,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			Enable_Field_Tracking__c = true,
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[3].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 20,
			When_to_Ask__c		= 'Order__c',
			When_to_View__c		= 'Opportunity',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD,
			Related_Record_Section__c = li_ActiveSectionNames[1],
			Related_Field_Label__c = 'Sales Rep Name',
			Related_Object_Name__c = 'Opportunity',
			Related_Field_name__c = 'Owner.Name',
			Help_Text__c		= 'Here is some help text',
			Sequence_Number__c	= 30,
			When_to_View__c		= 'Opportunity',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[4].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 10,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[5].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 20,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[6].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 30,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[7].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 40,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[8].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 50,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[9].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 60,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[10].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 70,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[11].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 80,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		insert li_RulestoInsert;

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_QuestionnaireService ctrl = new CS_QuestionnaireService();
		ctrl.buildQuestionsForDisplay(sOpportunity.id, true);
		
		system.debug('*** mp_liQuestions ***' + ctrl.mp_liQuestions);

		/***********************************************************************************************************
			Provide some answers
		***********************************************************************************************************/
		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : ctrl.mp_liQuestions)
		{
			if (SectionWrapper.SectionName == li_ActiveSectionNames[0])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'This is Question #1')
					{
						QuestionWrapper.Answer.Answer_Text__c = 'This is Answer #1';
					}
					else if (QuestionWrapper.QuestionText == 'This is Question #2')
					{
						QuestionWrapper.Answer.Answer_Text__c = 'B';
					}
				}
			}
			else if (SectionWrapper.SectionName == li_ActiveSectionNames[1])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'This is Question #3')
					{
						QuestionWrapper.Answer.Answer_Long_Text__c = 'This is the first answer text';
					}
					
					// Question 4 is read-only
				}
			}
			else if (SectionWrapper.SectionName == li_ActiveSectionNames[2])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'This is Question #5')
					{
						
					}
					else if (QuestionWrapper.QuestionText == 'This is Question #6')
					{
						QuestionWrapper.Answer.Answer_Currency__c = 123;
					}
					else if (QuestionWrapper.QuestionText == 'This is Question #7')
					{
						
					}
					else if (QuestionWrapper.QuestionText == 'This is Question #8')
					{
						
					}
					else if (QuestionWrapper.QuestionText == 'This is Question #9')
					{
						QuestionWrapper.Answer.Answer_Numeric__c = 123;
					}
					else if (QuestionWrapper.QuestionText == 'This is Question #10')
					{
						
					}
					else if (QuestionWrapper.QuestionText == 'This is Question #11')
					{
						QuestionWrapper.Answer.Answer_Phone__c = '111222';
					}
					else if (QuestionWrapper.QuestionText == 'This is Question #12')
					{
						QuestionWrapper.Answer.Answer_Text__c = 'Too short';
					}
					else if (QuestionWrapper.QuestionText == 'This is Question #13')
					{
						
					}
				}
			}
		}
		
		system.debug('*** mp_liQuestions ***' + ctrl.mp_liQuestions);

		ctrl.validateAnswers();
		
		
		ctrl.saveAnswers();


		ctrl.rebuildQuestionWrappers();


		/***********************************************************************************************************
			Call the wizard again to retrieve the Answers
		***********************************************************************************************************/
		CS_QuestionnaireService ctrl2 = new CS_QuestionnaireService();
		ctrl2.buildQuestionsForDisplay(sOpportunity.id, true);

		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : ctrl2.mp_liQuestions)
		{
			if (SectionWrapper.SectionName == li_ActiveSectionNames[1])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'This is Question #3')
					{
						QuestionWrapper.Answer.Answer_Long_Text__c = 'This is the second answer text';
					}
				}
			}
		}

		ctrl2.validateAnswers();
		ctrl2.saveAnswers();

		/***********************************************************************************************************
			Call the wizard once more to exercise the field tracking code to retrieve the Answers
		***********************************************************************************************************/
		CS_QuestionnaireService ctrl3 = new CS_QuestionnaireService();
		ctrl3.buildQuestionsForDisplay(sOpportunity.id, true);
		
		/***********************************************************************************************************
			Finally, run the download code
		***********************************************************************************************************/
		CS_AnswersDownload_Controller ctrl4 = new CS_AnswersDownload_Controller();
		ctrl4.init();
		
		system.debug('*** mp_liAnswers ***' + ctrl4.mp_liAnswers);
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
	static testMethod void testInactiveQuestion()
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
			Question_Text__c	= 'This is Question #1',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
			isActive__c			= true
			));
		
		insert li_QuestionstoInsert;

		// Rules
		list<Rule__c> li_RulestoInsert = new list<Rule__c>();
		
		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[0].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 10,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		insert li_RulestoInsert;


		/***********************************************************************************************************
			Use the wizard to create an Answer
		***********************************************************************************************************/
		CS_QuestionnaireService ctrl = new CS_QuestionnaireService();
		ctrl.buildQuestionsForDisplay(sOpportunity.id, true);
		
		system.debug('*** mp_liQuestions ***' + ctrl.mp_liQuestions);

		/***********************************************************************************************************
			Provide some answers
		***********************************************************************************************************/
		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : ctrl.mp_liQuestions)
		{
			if (SectionWrapper.SectionName == li_ActiveSectionNames[0])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'This is Question #1')
					{
						QuestionWrapper.Answer.Answer_Text__c = 'This is Answer #1';
					}
				}
			}
		}
		
		system.debug('*** mp_liQuestions ***' + ctrl.mp_liQuestions);

		ctrl.validateAnswers();
		ctrl.saveAnswers();
		
		// Inactivate the Question
		li_QuestionstoInsert[0].isActive__c = false;
		update li_QuestionstoInsert[0];
		
		// And the Rule
		li_RulestoInsert[0].isActive__c = false;
		update li_RulestoInsert[0];

		/***********************************************************************************************************
			Start the test
		***********************************************************************************************************/
		test.startTest();

		/***********************************************************************************************************
			Call the wizard again to retrieve the Answers
		***********************************************************************************************************/
		CS_QuestionnaireService ctrl2 = new CS_QuestionnaireService();
		ctrl2.buildQuestionsForDisplay(sOpportunity.id, true);

		/***********************************************************************************************************
			Stop the test
		***********************************************************************************************************/
		test.stopTest();

		// Inspect the results
		system.assertEquals(false, ctrl2.mp_liQuestions.isEmpty(), 'Existing Answer to inactivated Question was not displayed');

		boolean bQuestionFound = false;

		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : ctrl2.mp_liQuestions)
		{
			if (SectionWrapper.SectionName == li_ActiveSectionNames[0])
			{
				for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
				{
					if (QuestionWrapper.QuestionText == 'This is Question #1')
					{
						bQuestionFound = true;
						
						system.assertEquals('This is Answer #1', QuestionWrapper.Answer.Answer_Text__c, 'Existing Answer to inactivated Question was not displayed');
					}
				}
			}
		}
		
		system.assertEquals(true, bQuestionFound, 'Expected Question was not found');
	}
    
}
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
private class CS_AnswerHistoryDownload_Test
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
	static testMethod void testDownloadfromOpportunity()
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
			isActive__c			= true
			));

		li_QuestionstoInsert.add(new Question2__c(
			Section__c			= li_ActiveSectionNames[2],
			Question_Text__c	= 'This is Question #12',
			Answer_Type__c		= CS_Questions_Utilities.ANSWERTYPE_TEXT,
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

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[1].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 20,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[2].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 30,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			Enable_Field_Tracking__c = true,
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[3].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 40,
			When_to_Ask__c		= 'Order__c',
			When_to_View__c		= 'Opportunity',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[4].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 50,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[5].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 60,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[6].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 70,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[7].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 80,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[8].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 90,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[9].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 100,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[10].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 110,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		li_RulestoInsert.add(new Rule__c(
			Question2__c		= li_QuestionstoInsert[11].id,
			Answer_Source__c	= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
			Question_Type__c	= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
			Sequence_Number__c	= 120,
			When_to_Ask__c		= 'Opportunity',
			When_to_View__c		= 'Order__c',
			isActive__c			= true
			));

		insert li_RulestoInsert;

		// Answers
		list<Answer2__c> li_AnswerstoInsert = new list<Answer2__c>();
		list<Answer_to_Rule__c> li_AnswertoRulestoInsert = new list<Answer_to_Rule__c>();

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[0].id,
			Question_Text__c	= li_QuestionstoInsert[0].Question_Text__c,
			Section__c			= li_QuestionstoInsert[0].Section__c,
			Answer_Text__c		= 'some text'
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[1].id,
			Question_Text__c	= li_QuestionstoInsert[1].Question_Text__c,
			Section__c			= li_QuestionstoInsert[1].Section__c,
			Answer_Text__c		= 'A'
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[2].id,
			Question_Text__c	= li_QuestionstoInsert[2].Question_Text__c,
			Section__c			= li_QuestionstoInsert[2].Section__c,
			Answer_Text__c		= 'some long text'
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[3].id,
			Question_Text__c	= li_QuestionstoInsert[3].Question_Text__c,
			Section__c			= li_QuestionstoInsert[3].Section__c,
			Answer_Text__c		= 'some more long text'
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[4].id,
			Question_Text__c	= li_QuestionstoInsert[4].Question_Text__c,
			Section__c			= li_QuestionstoInsert[4].Section__c,
			Answer_Checkbox__c	= true
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[5].id,
			Question_Text__c	= li_QuestionstoInsert[5].Question_Text__c,
			Section__c			= li_QuestionstoInsert[5].Section__c,
			Answer_Currency__c	= 123.45
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[6].id,
			Question_Text__c	= li_QuestionstoInsert[6].Question_Text__c,
			Section__c			= li_QuestionstoInsert[6].Section__c,
			Answer_Date__c		= system.today()
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[7].id,
			Question_Text__c	= li_QuestionstoInsert[7].Question_Text__c,
			Section__c			= li_QuestionstoInsert[7].Section__c,
			Answer_Email__c		= 'homer.simpson@gmail.com'
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[8].id,
			Question_Text__c	= li_QuestionstoInsert[8].Question_Text__c,
			Section__c			= li_QuestionstoInsert[8].Section__c,
			Answer_Numeric__c		= 12345
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[9].id,
			Question_Text__c	= li_QuestionstoInsert[9].Question_Text__c,
			Section__c			= li_QuestionstoInsert[9].Section__c,
			Answer_Phone__c		= '0412345678'
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[10].id,
			Question_Text__c	= li_QuestionstoInsert[10].Question_Text__c,
			Section__c			= li_QuestionstoInsert[10].Section__c,
			Answer_Text__c		= 'some text'
			));

		li_AnswerstoInsert.add(new Answer2__c(
			Question2__c		= li_QuestionstoInsert[11].id,
			Question_Text__c	= li_QuestionstoInsert[11].Question_Text__c,
			Section__c			= li_QuestionstoInsert[11].Section__c,
			Answer_Url__c		= 'https://google.com'
			));

		insert li_AnswerstoInsert;

		for (integer i = 0; i < li_RulestoInsert.size()-1; i++)
		{
			li_AnswertoRulestoInsert.add(new Answer_to_Rule__c(
				Rule__c			= li_RulestoInsert[i].id,
				Answer2__c		= li_AnswerstoInsert[i].id,
				Opportunity__c	= sOpportunity.id
				));
		}

		insert li_AnswertoRulestoInsert;

		// Run the wizard so we can update some answers
		CS_QuestionnaireService ctrlq = new CS_QuestionnaireService();
		ctrlq.buildQuestionsForDisplay(sOpportunity.id, true);

//		Update some answers
		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : ctrlq.mp_liQuestions)
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
		
		ctrlq.saveAnswers();

		/***********************************************************************************************************
			Start
		***********************************************************************************************************/
		test.setCurrentPage(Page.CS_AnswerHistoryDownload);
		ApexPages.currentPage().getParameters().put('id', sOpportunity.id);

		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_AnswerHistoryDownload_Controller ctrl = new CS_AnswerHistoryDownload_Controller();
		ctrl.init();
		
		// Inspect the results
		system.assertEquals(false, ctrl.mp_liAnswers.isEmpty(), 'No Answers were found');
		system.assertEquals(3, ctrl.mp_liAnswers.size(), 'Number of Sections not as expected');
		system.assertEquals(4, ctrl.mp_liAnswers[0].AnswerWrappers.size(), 'Number of Answers in first Section not as expected');
		system.assertEquals(3, ctrl.mp_liAnswers[1].AnswerWrappers.size(), 'Number of Answers in second Section not as expected');
		system.assertEquals(12, ctrl.mp_liAnswers[2].AnswerWrappers.size(), 'Number of Answers in third Section not as expected');
	}

}
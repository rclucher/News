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
private class CS_Questions_Test
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
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testNoQuestions()
	{
		// No test data
		
		// Set up the page
		test.setCurrentPage(Page.CS_Questions);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_Questions_Controller ctrl = new CS_Questions_Controller();
		ctrl.init();
		
		// Inspect the results
		system.assertEquals(false, ctrl.mp_bQuestionsExist, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_liQuestions.isEmpty(), 'The Question list is not empty');

		/***********************************************************************************************************
			Click on New button
		***********************************************************************************************************/
		pageReference pageRef = ctrl.actionNew();

		// Inspect the results
		system.assertEquals(true, pageRef.getRedirect(), 'PageReference redirect boolean not as expected');
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testCommandLinks()
	{
		// Create some test data
		// Questions
		list<Question2__c> li_Questions = new list<Question2__c>();
		
		for (integer i=0; i < 200; i++)
		{
			li_Questions.add(new Question2__c(
				Section__c			= 'ABC',
				Question_Text__c	= 'This is Question #' + i,
				Answer_Type__c		= 'Text',
				isActive__c			= true
			));
		}
		
		insert li_Questions;
		
		// Rules
		// First some questions
		list<Rule__c> li_Rules = new list<Rule__c>();
		
		for (integer i=0; i < 10; i++)
		{
			li_Rules.add(new Rule__c(
				Question2__c				= li_Questions[i].id,
				Question_Type__c			= CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL,
				Answer_Source__c			= CS_Questions_Utilities.ANSWERSOURCE_QUESTION,
				When_to_Ask__c				= 'Opportunity',
				When_to_View__c				= 'Product_Order__c',
				Enable_Field_Tracking__c	= false,
				isActive__c					= true
			));
		}

		insert li_Rules;
		
		// Add some Answers
		list<Answer2__c> li_Answers = new list<Answer2__c>();
		
		for (integer i=0; i < 2; i++)
		{
			li_Answers.add(new Answer2__c(
				Answer_Text__c	= 'Answer #' + i
				));
		}
			
		insert li_Answers;
		
		// Link to Rules
		list<Answer_to_Rule__c> li_AnswertoRules = new list<Answer_to_Rule__c>();
		
		for (integer i=0; i < 2; i++)
		{
			li_AnswertoRules.add(new Answer_to_Rule__c(
				Rule__c		= li_Rules[i].id,
				Answer2__c	= li_Answers[i].id
				));
		}

		insert li_AnswertoRules;

		// Set up the page
		test.setCurrentPage(Page.CS_Questions);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_Questions_Controller ctrl = new CS_Questions_Controller();
		ctrl.init();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bQuestionsExist, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_liQuestions.isEmpty(), 'The Question list is empty');
		
		// Get the first Question and check the display booleans
		// First Question has a related answer so cannot be deleted
		system.assertEquals(true, ctrl.mp_liQuestions[0].bShowEdit, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_liQuestions[0].bShowDelete, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_liQuestions[0].bShowInactivate, 'Display boolean not as expected');

		// Third Question (this is Question #10 because the records are sorted by Question Text) has no related answer
		system.assertEquals(true, ctrl.mp_liQuestions[2].bShowEdit, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_liQuestions[2].bShowDelete, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_liQuestions[2].bShowInactivate, 'Display boolean not as expected');

		/***********************************************************************************************************
			Click on Inactivate
		***********************************************************************************************************/
		ctrl.mp_QuestionId = ctrl.mp_liQuestions[0].Question.id;
		
		ctrl.actionInactivate();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		
		// We should have ONE message
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg1 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.QUESTION_INACTIVED)
				bFoundMsg1 = true;

			// Check severity
			system.assertEquals(ApexPages.Severity.INFO, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg1, 'Info message missing');

		// Check the record was updated
		Question2__c sUpdatedQuestion = [select isActive__c from Question2__c where id = : ctrl.mp_QuestionId];
		system.assertEquals(false, sUpdatedQuestion.isActive__c, 'Updated Question not as expected');

		/***********************************************************************************************************
			Click on Delete - Question with no Rules
		***********************************************************************************************************/
		ctrl.mp_QuestionId = ctrl.mp_liQuestions[2].Question.id;
		
		ctrl.actionDelete();

		// Inspect the results
		li_PageMessages = ApexPages.getMessages();
		
		// We should have two messages (message list cannot be cleared in a test class)
		system.assertEquals(2, li_PageMessages.size(), 'Number of messages not as expected');
		
		bFoundMsg1 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.QUESTION_DELETED)
			{
				bFoundMsg1 = true;

				// Check severity
				system.assertEquals(ApexPages.Severity.INFO, pageMsg.getSeverity(), 'Message severity not as expected');
			}
		}

		system.assertEquals(true, bFoundMsg1, 'Info message missing');

		// Check the record was updated
		list<Question2__c> li_DeletedQuestions = [select id from Question2__c where id = : ctrl.mp_QuestionId];
		system.assertEquals(true, li_DeletedQuestions.isEmpty(), 'Question not deleted');

		/***********************************************************************************************************
			Click on Delete - Question with Rules
		***********************************************************************************************************/
		list<id> li_QuestionsIds = new list<id>(ctrl.m_mapQuestiontoRules.keyset());
		ctrl.mp_QuestionId = li_QuestionsIds[0];
		
		ctrl.actionDelete();

		// Check the record was updated
		list<Question2__c> li_DeletedQuestions2 = [select id from Question2__c where id = : ctrl.mp_QuestionId];
		system.assertEquals(true, li_DeletedQuestions2.isEmpty(), 'Question not deleted');

		/***********************************************************************************************************
			Click on Edit
		***********************************************************************************************************/
		ctrl.mp_QuestionId = ctrl.mp_liQuestions[1].Question.id;
		
		pageReference pageRef = ctrl.actionEdit();
		
		// Inspect the results
		system.assertEquals(true, pageRef.getRedirect(), 'PageReference redirect boolean not as expected');

		/***********************************************************************************************************
			Test Pagination
		***********************************************************************************************************/
		system.debug('*** m_iDefaultListSize ***' + ctrl.m_iDefaultListSize);
		
		ctrl.showNextPage();
		system.assertEquals(2, ctrl.mp_iPageNumber, 'Page number not as expected');
		system.assertEquals(0 + ctrl.m_iDefaultListSize, ctrl.m_iStartList, 'Start list index not as expected');

		ctrl.showPreviousPage();
		system.assertEquals(1, ctrl.mp_iPageNumber, 'Page number not as expected');
		system.assertEquals(0, ctrl.m_iStartList, 'Start list index not as expected');

		ctrl.showLastPage();
		integer iStartList = (ctrl.mp_iTotalPages - 1) * ctrl.m_iDefaultListSize;
		system.assertEquals(ctrl.mp_iTotalPages, ctrl.mp_iPageNumber, 'Page number not as expected');
		system.assertEquals(iStartList, ctrl.m_iStartList, 'Start list index not as expected');

		ctrl.showFirstPage();
		system.assertEquals(1, ctrl.mp_iPageNumber, 'Page number not as expected');
		system.assertEquals(0, ctrl.m_iStartList, 'Start list index not as expected');

		/***********************************************************************************************************
			Click on View Rules
		***********************************************************************************************************/
		pageRef = ctrl.gotoViewRules();
		
		// Inspect the results
		system.assertEquals(true, pageRef.getRedirect(), 'PageReference redirect boolean not as expected');

		/***********************************************************************************************************
			Test return from the Question page
		***********************************************************************************************************/
		test.setCurrentPage(Page.CS_Questions);
		
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('pageNo', '7');

		ctrl = new CS_Questions_Controller();
		ctrl.init();
		
		// Inspect the results
		system.assertEquals(7, ctrl.mp_iPageNumber, 'Page number not as expected');
	}

}
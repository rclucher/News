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
private class CS_Question_Test
{
	@testSetup static void runSetupUtil()
	{
		
	}


	/*------------------------------------------------------------
	Author:		Mike Jupp
	Company:		CloudSense
	Description:	
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testNew1()
	{
		test.setCurrentPage(Page.CS_Question);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_Question_Controller ctrl = new CS_Question_Controller();
		ctrl.init();
		
		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_CREATE, ctrl.mp_SectionTitle, 'Section title is incorrect');
//		system.assertEquals(false, ctrl.mp_bShowReturntoList, 'Display boolean not as expected');
		system.assertEquals(new Question2__c(), ctrl.mp_Question, 'The Question record is not initialised');

		/***********************************************************************************************************
			Attempt to save a blank record
		***********************************************************************************************************/
		pageReference pageRef = ctrl.actionSave();

		// Stop
		test.stopTest();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		
		// We should have TWO error messages
		system.assertEquals(3, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg1 = false;
		boolean bFoundMsg2 = false;
		boolean bFoundMsg3 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_SECTION)
				bFoundMsg1 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_QUESTION)
				bFoundMsg2 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_ANSWERTYPE)
				bFoundMsg3 = true;

			// All should be error messages
			system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg1, 'Validation error for Section missing');
		system.assertEquals(true, bFoundMsg2, 'Validation error for Question missing');
		system.assertEquals(true, bFoundMsg3, 'Validation error for Answer Type missing');
		system.assertEquals(new Question2__c(), ctrl.mp_Question, 'The Question record is not initialised');
		system.assertEquals(null, pageRef, 'PageReference not null');
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testNew2()
	{
		test.setCurrentPage(Page.CS_Question);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_Question_Controller ctrl = new CS_Question_Controller();
		ctrl.init();

		/***********************************************************************************************************
			Provide a value for Section
		***********************************************************************************************************/
		ctrl.mp_Question.Section__c = 'ABC';
		pageReference pageRef = ctrl.actionSave();

		// Stop
		test.stopTest();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		
		// We should have TWO error messages
		system.assertEquals(2, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg2 = false;
		boolean bFoundMsg3 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_QUESTION)
				bFoundMsg2 = true;

			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_ANSWERTYPE)
				bFoundMsg3 = true;
			
			// Should be an error message
			system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg2, 'Validation error for Question missing');
		system.assertEquals(true, bFoundMsg3, 'Validation error for Answer Type missing');
		system.assertEquals('ABC', ctrl.mp_Question.Section__c, 'The Question field Section is not as expected');
		system.assertEquals(null, ctrl.mp_Question.Question_Text__c, 'The Question field Question Text is not as expected');
		system.assertEquals(false, ctrl.mp_Question.isActive__c, 'The Question field Active is not as expected');
		system.assertEquals(null, pageRef, 'PageReference not null');
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testNew3()
	{
		test.setCurrentPage(Page.CS_Question);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_Question_Controller ctrl = new CS_Question_Controller();
		ctrl.init();

		/***********************************************************************************************************
			Provide a value for Question
		***********************************************************************************************************/
		ctrl.mp_Question.Section__c = 'ABC';
		ctrl.mp_Question.Question_Text__c = 'Some question text';
		pageReference pageRef = ctrl.actionSave();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		
		// We should have ONE error message
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg3 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.VALIDATIONERROR_ANSWERTYPE)
				bFoundMsg3 = true;
			
			// Should be an error message
			system.assertEquals(ApexPages.Severity.ERROR, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg3, 'Validation error for Answer Type missing');
		system.assertEquals('ABC', ctrl.mp_Question.Section__c, 'The Question field Section is not as expected');
		system.assertEquals('Some question text', ctrl.mp_Question.Question_Text__c, 'The Question field Question Text is not as expected');
		system.assertEquals(false, ctrl.mp_Question.isActive__c, 'The Question field Active is not as expected');
		system.assertEquals(null, pageRef, 'PageReference not null');
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testNew4()
	{
		test.setCurrentPage(Page.CS_Question);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_Question_Controller ctrl = new CS_Question_Controller();
		ctrl.init();

		/***********************************************************************************************************
			Provide a value for Question
		***********************************************************************************************************/
		ctrl.mp_Question.Section__c = 'ABC';
		ctrl.mp_Question.Question_Text__c = 'Some question text';
		ctrl.mp_Question.Answer_Type__c = CS_Questions_Utilities.ANSWERTYPE_TEXT;
		
		ctrl.actionProcessAnswerType();
		
		// Inspect the results
		system.assertEquals(true, ctrl.mp_bShowMinMaxLength, 'MinMaxLength display boolean not as expected');
		
		
		/***********************************************************************************************************
			Save
		***********************************************************************************************************/
		pageReference pageRef = ctrl.actionSave();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		
		// We should have NO error messages and ONE info message
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg1 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.RECORDSAVED)
				bFoundMsg1 = true;
			
			// Should be an error message
			system.assertEquals(ApexPages.Severity.INFO, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg1, 'Info message missing');
		system.assertEquals('ABC', ctrl.mp_Question.Section__c, 'The Question field Section is not as expected');
		system.assertEquals('Some question text', ctrl.mp_Question.Question_Text__c, 'The Question field Question Text is not as expected');
		system.assertEquals(false, ctrl.mp_Question.isActive__c, 'The Question field Active is not as expected');
		
		// Should still be on the same page
		system.assertEquals(null, pageRef, 'PageReference not null');
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_EDIT, ctrl.mp_SectionTitle, 'Section title is incorrect');

		/***********************************************************************************************************
			Click on Save & New button
		***********************************************************************************************************/
		pageRef = ctrl.actionSaveandNew();

		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_CREATE, ctrl.mp_SectionTitle, 'Section title is incorrect');
//		system.assertEquals(false, ctrl.mp_bShowReturntoList, 'Display boolean not as expected');
		// Section should be prepopulated
		system.assertEquals('ABC', ctrl.mp_Question.Section__c, 'The Question field Section is not as expected');
		// Question should be blank
		system.assertEquals(null, ctrl.mp_Question.Question_Text__c, 'The Question field Question Text is not as expected');
		
		system.assertEquals(null, pageRef, 'PageReference not null');
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testEdit()
	{
		// Create some test data
		Question2__c sQuestion = new Question2__c(
			Section__c = 'ABC',
			Question_Text__c = 'A simple question',
			Answer_Type__c = CS_Questions_Utilities.ANSWERTYPE_TEXT
			);
		
		insert sQuestion;
		
		// Set up the page
		test.setCurrentPage(Page.CS_Question);
		
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', sQuestion.Id);
		sP.put('pageNo', '2');

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_Question_Controller ctrl = new CS_Question_Controller();
		ctrl.init();

		// Inspect the results
		system.assertEquals(CS_Questions_Utilities.SECTIONTITLE_EDIT, ctrl.mp_SectionTitle, 'Section title is incorrect');
//		system.assertEquals(true, ctrl.mp_bShowReturntoList, 'Display boolean not as expected');
		system.assertEquals(sQuestion.id, ctrl.mp_Question.id, 'The Question id is not as expected');
		system.assertEquals(sQuestion.Section__c, ctrl.mp_Question.Section__c, 'The Question field Section__c is not as expected');
		system.assertEquals(sQuestion.Question_Text__c, ctrl.mp_Question.Question_Text__c, 'The Question field Question_Text__c is not as expected');

		/***********************************************************************************************************
			Update Question and return to list
		***********************************************************************************************************/
		ctrl.mp_Question.Question_Text__c = 'Some updated question text';
		pageReference pageRef = ctrl.actionSaveandReturn();

		// Stop
		test.stopTest();

		// Inspect the results

		// Check the record was updated
		Question2__c sUpdatedQuestion = [select Question_Text__c from Question2__c where id = : sQuestion.Id];
		system.assertEquals('Some updated question text', sUpdatedQuestion.Question_Text__c, 'Updated Question not as expected');
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	static testMethod void testPicklist()
	{
		// Create some test data

		// Set up the page
		test.setCurrentPage(Page.CS_Question);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_Question_Controller ctrl = new CS_Question_Controller();
		ctrl.init();

		/***********************************************************************************************************
			Create a Question that is answered with a value from a picklist
		***********************************************************************************************************/
		ctrl.mp_Question.Section__c = 'ABC';
		ctrl.mp_Question.Question_Text__c = 'Some question text';
		ctrl.mp_Question.Answer_Type__c = CS_Questions_Utilities.ANSWERTYPE_PICKLIST;
		
		ctrl.actionProcessAnswerType();

		// Inspect the results
		system.assertEquals(false, ctrl.mp_bShowMinMaxLength, 'MinMaxLength display boolean not as expected');
		system.assertEquals(true, ctrl.mp_bShowAnswerPicklistValues, 'ShowAnswerPicklistValues display boolean not as expected');

		/***********************************************************************************************************
			Define picklist values
		***********************************************************************************************************/
		ctrl.mp_NewAnswerValue = 'A';
		ctrl.actionAdd();
		
		system.assertEquals(true, string.isBlank(ctrl.mp_NewAnswerValue), 'Picklist value not cleared as expected');
		system.assertEquals(1, ctrl.mp_liAnswerPicklistValues.size(), 'Picklist size not as expected');

		ctrl.mp_NewAnswerValue = 'B';
		ctrl.actionAdd();
		system.assertEquals(2, ctrl.mp_liAnswerPicklistValues.size(), 'Picklist size not as expected');

		ctrl.mp_NewAnswerValue = 'C';
		ctrl.actionAdd();
		system.assertEquals(3, ctrl.mp_liAnswerPicklistValues.size(), 'Picklist size not as expected');
		
		// Check the order
		system.assertEquals('A', ctrl.mp_liAnswerPicklistValues[0].getValue(), 'Picklist value not as expected');
		system.assertEquals('B', ctrl.mp_liAnswerPicklistValues[1].getValue(), 'Picklist value not as expected');
		system.assertEquals('C', ctrl.mp_liAnswerPicklistValues[2].getValue(), 'Picklist value not as expected');
		
		// Move values around
		ctrl.mp_strAnswerPicklistValue = 'C';
		ctrl.actionMoveUp();

		// Check the order
		system.assertEquals('A', ctrl.mp_liAnswerPicklistValues[0].getValue(), 'Picklist value not as expected');
		system.assertEquals('C', ctrl.mp_liAnswerPicklistValues[1].getValue(), 'Picklist value not as expected');
		system.assertEquals('B', ctrl.mp_liAnswerPicklistValues[2].getValue(), 'Picklist value not as expected');

		ctrl.mp_strAnswerPicklistValue = 'C';
		ctrl.actionMoveUp();

		// Check the order
		system.assertEquals('C', ctrl.mp_liAnswerPicklistValues[0].getValue(), 'Picklist value not as expected');
		system.assertEquals('A', ctrl.mp_liAnswerPicklistValues[1].getValue(), 'Picklist value not as expected');
		system.assertEquals('B', ctrl.mp_liAnswerPicklistValues[2].getValue(), 'Picklist value not as expected');

		ctrl.mp_strAnswerPicklistValue = 'A';
		ctrl.actionMoveDown();

		// Check the order
		system.assertEquals('C', ctrl.mp_liAnswerPicklistValues[0].getValue(), 'Picklist value not as expected');
		system.assertEquals('B', ctrl.mp_liAnswerPicklistValues[1].getValue(), 'Picklist value not as expected');
		system.assertEquals('A', ctrl.mp_liAnswerPicklistValues[2].getValue(), 'Picklist value not as expected');

		ctrl.mp_strAnswerPicklistValue = 'C';
		ctrl.actionDelete();

		// Check the size and order
		system.assertEquals(2, ctrl.mp_liAnswerPicklistValues.size(), 'Picklist size not as expected');
		system.assertEquals('B', ctrl.mp_liAnswerPicklistValues[0].getValue(), 'Picklist value not as expected');
		system.assertEquals('A', ctrl.mp_liAnswerPicklistValues[1].getValue(), 'Picklist value not as expected');

		ctrl.actionSaveandReturn();

		// Stop
		test.stopTest();

		// Inspect the results

		// Check the record was updated
//		Question2__c sUpdatedQuestion = [select Question_Text__c from Question2__c where id = : sQuestion.Id];
//		system.assertEquals('Some updated question text', sUpdatedQuestion.Question_Text__c, 'Updated Question not as expected');
	}

}
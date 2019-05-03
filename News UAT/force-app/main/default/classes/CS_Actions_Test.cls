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
private class CS_Actions_Test
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
	static testMethod void testNoActions()
	{
		// No test data
		
		// Set up the page
		test.setCurrentPage(Page.CS_Actions);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_Actions_Controller ctrl = new CS_Actions_Controller();
		ctrl.init();
		
		// Inspect the results
		system.assertEquals(false, ctrl.mp_bActionsExist, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_liActions.isEmpty(), 'The Action list is not empty');

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
		// Actions
		list<Questionnaire_Action__c> li_Actions = new list<Questionnaire_Action__c>();
		
		li_Actions.add(new Questionnaire_Action__c(Name	= 'GeoNames', isActive__c = true));
		li_Actions.add(new Questionnaire_Action__c(Name	= 'SomethingElse', isActive__c = true));
		
		insert li_Actions;
		
		// Results
		list<Questionnaire_Action_Result__c> li_Results = new list<Questionnaire_Action_Result__c>();
		
		li_Results.add(new Questionnaire_Action_Result__c(Questionnaire_Action__c	= li_Actions[1].id));
		
		insert li_Results;

		// Set up the page
		test.setCurrentPage(Page.CS_Actions);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_Actions_Controller ctrl = new CS_Actions_Controller();
		ctrl.init();

		// Inspect the results
		system.assertEquals(true, ctrl.mp_bActionsExist, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_liActions.isEmpty(), 'The Action list is empty');
		
		// Get the first Action and check the display booleans
		// First Action has no related result so can be deleted
		system.assertEquals(true, ctrl.mp_liActions[0].bShowEdit, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_liActions[0].bShowDelete, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_liActions[0].bShowInactivate, 'Display boolean not as expected');

		// Second Action can only be inactivated
		system.assertEquals(true, ctrl.mp_liActions[1].bShowEdit, 'Display boolean not as expected');
		system.assertEquals(false, ctrl.mp_liActions[1].bShowDelete, 'Display boolean not as expected');
		system.assertEquals(true, ctrl.mp_liActions[1].bShowInactivate, 'Display boolean not as expected');

		/***********************************************************************************************************
			Click on Inactivate
		***********************************************************************************************************/
		ctrl.mp_ActionId = ctrl.mp_liActions[1].Action.id;
		
		ctrl.actionInactivate();

		// Inspect the results
		list<ApexPages.Message> li_PageMessages = ApexPages.getMessages();
		
		// We should have ONE message
		system.assertEquals(1, li_PageMessages.size(), 'Number of messages not as expected');
		
		boolean bFoundMsg1 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.ACTION_INACTIVED)
				bFoundMsg1 = true;

			// Check severity
			system.assertEquals(ApexPages.Severity.INFO, pageMsg.getSeverity(), 'Message severity not as expected');
		}

		system.assertEquals(true, bFoundMsg1, 'Info message missing');

		// Check the record was updated
		Questionnaire_Action__c sUpdatedAction = [select isActive__c from Questionnaire_Action__c where id = : ctrl.mp_ActionId];
		system.assertEquals(false, sUpdatedAction.isActive__c, 'Updated Action not as expected');

		/***********************************************************************************************************
			Click on Delete - Action with no Rules
		***********************************************************************************************************/
		ctrl.mp_ActionId = ctrl.mp_liActions[0].Action.id;
		
		ctrl.actionDelete();

		// Inspect the results
		li_PageMessages = ApexPages.getMessages();
		
		// We should have two messages (message list cannot be cleared in a test class)
		system.assertEquals(2, li_PageMessages.size(), 'Number of messages not as expected');
		
		bFoundMsg1 = false;
		
		for (ApexPages.Message pageMsg : li_PageMessages)
		{
			if (pageMsg.getDetail() == CS_Questions_Utilities.ACTION_DELETED)
			{
				bFoundMsg1 = true;

				// Check severity
				system.assertEquals(ApexPages.Severity.INFO, pageMsg.getSeverity(), 'Message severity not as expected');
			}
		}

		system.assertEquals(true, bFoundMsg1, 'Info message missing');

		// Check the record was updated
		list<Questionnaire_Action__c> li_DeletedActions = [select id from Questionnaire_Action__c where id = : ctrl.mp_ActionId];
		system.assertEquals(true, li_DeletedActions.isEmpty(), 'Action not deleted');

		/***********************************************************************************************************
			Click on Edit
		***********************************************************************************************************/
		ctrl.mp_ActionId = ctrl.mp_liActions[0].Action.id;
		
		pageReference pageRef = ctrl.actionEdit();
		
		// Inspect the results
		system.assertEquals(true, pageRef.getRedirect(), 'PageReference redirect boolean not as expected');

		/***********************************************************************************************************
			Test return from the Action page
		***********************************************************************************************************/
		test.setCurrentPage(Page.CS_Actions);
		
		pageReference pageRef2 = ctrl.gotoQuestions();
		
		// Inspect the results
		system.assertEquals(true, pageRef2.getRedirect(), 'PageReference redirect boolean not as expected');

	}

}
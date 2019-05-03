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
private class CS_QuestionsDownload_Test
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
	static testMethod void testDownload()
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

		test.setCurrentPage(Page.CS_QuestionsDownload);

		// Start
		test.startTest();

		/***********************************************************************************************************
			Fire up the controller
		***********************************************************************************************************/
		CS_QuestionsDownload_Controller ctrl = new CS_QuestionsDownload_Controller();
		ctrl.init();
	}
}
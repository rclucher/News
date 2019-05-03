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
 * See the Apex Language Reference for more information about Testing and Code Coverage
 */
@isTest(seeAllData=false)
public with sharing class New_Creative_Ctrl_Test
{
	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Tests the button redirect code in class New_Creative_Ctrl
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jun 18		Mike Jupp			Created
	------------------------------------------------------------*/
	static testMethod void testButtonRedirect()
	{
		// Set up test data
		Account sAccount = TestDataSetupClass.createAccount();
		insert sAccount;

		Contact sContact = TestDataSetupClass.createContact(sAccount);
		insert sContact;

		Opportunity sOpportunity = TestDataSetupClass.createOpportunity(sAccount, sContact);
		insert sOpportunity;

		Order__c sOrder = TestDataSetupClass.createOrder(sOpportunity);
		insert sOrder;

		Product_Order__c sProductOrder = new Product_Order__c(
			Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
			Order__c = sOrder.Id,
			Status__c = 'In Progress');

		insert sProductOrder;

		ApexPages.StandardController ctr = new ApexPages.StandardController(sProductOrder);
		
		PageReference pageRef = new ApexPages.StandardController(sProductOrder).view();
		pageRef.getParameters().put('id', String.valueOf(sProductOrder.Id));
		test.setCurrentPage(pageRef);
		
		// Start the test
		test.startTest();
		
		// Instantiate the controller
		New_Creative_Ctrl controller = new New_Creative_Ctrl(ctr);

		Pagereference pageRefOut = controller.New_Creative_Method();
		
		// Stop the test and inspect the results
		test.stopTest();
		
		string strUrl = pageRefOut.getUrl();
		boolean bRedirect = pageRefOut.getRedirect();
		
		// Should be a redirect
		system.assertEquals(true, bRedirect, 'Button did not do a redirect');
		
		// We should have a slash followed by a Creative record id
		system.assertEquals(true, strUrl.startsWith('/'), 'Url does not begin with a slash');
		
		// Get the record id
		id CreativeId = strUrl.substring(1, strUrl.length());
		
		// Check the record exists
		list<Creative__c> li_Creatives = [select id from Creative__c where id = : CreativeId];
		
		system.assertEquals(1, li_Creatives.size(), 'Creative record was not created');
	}		
}
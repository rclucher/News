@isTest(seeAllData=false)
public with sharing class View_Briefing_Form_ctrl_test
{

	static testMethod void test()
	{
		// Set up test data
		Account sAccount = TestDataSetupClass.createAccount();
		insert sAccount;

		Contact sContact = TestDataSetupClass.createContact(sAccount);
		insert sContact;

		Opportunity sOpportunity = TestDataSetupClass.createOpportunity(sAccount, sContact);
		insert sOpportunity;
        
         Briefing_Form__c b = new Briefing_Form__c();
        b.Status__c = 'Test';
        insert b;
        
		Order__c sOrder = TestDataSetupClass.createOrder(sOpportunity);
		insert sOrder;
        sOrder.Briefing_Form__c = b.id;
        sOrder.Opportunity__c = sOpportunity.id;
        update sOrder;
              
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
		View_Briefing_Form_ctrl controller = new View_Briefing_Form_ctrl(ctr);

		Pagereference pageRefOut = controller.View_Briefing_mthd();
		
		// Stop the test and inspect the results
		test.stopTest();
		
		string strUrl = pageRefOut.getUrl();
		boolean bRedirect = pageRefOut.getRedirect();
		
		// Should be a redirect
		system.assertEquals(true, bRedirect, 'Button did not do a redirect');
		
		// We should have a slash followed by a Creative record id
		system.assertEquals(true, strUrl.startsWith('/'), 'Url does not begin with a slash');
				
		
	}		
}
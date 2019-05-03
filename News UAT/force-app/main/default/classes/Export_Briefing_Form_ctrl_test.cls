@isTest(seeAllData=false)
public with sharing class Export_Briefing_Form_ctrl_test
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
              
		ApexPages.StandardController ctr = new ApexPages.StandardController(sOrder);
		
		PageReference pageRef = new ApexPages.StandardController(sOrder).view();
		pageRef.getParameters().put('id', String.valueOf(sOrder.Id));
		test.setCurrentPage(pageRef);
		
		// Start the test
		test.startTest();
		
		// Instantiate the controller
		Export_Briefing_Form_ctrl controller = new Export_Briefing_Form_ctrl(ctr);

		Pagereference pageRefOut = controller.Export_Briefing_mthd();
		
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
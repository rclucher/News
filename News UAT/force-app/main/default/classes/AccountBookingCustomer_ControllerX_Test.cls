@isTest
private class AccountBookingCustomer_ControllerX_Test {
	
	@isTest static void test_method_one() {

		list<Account> accts = TestDataFactory.createAccounts(1, true);
		insert accts;

		system.debug('accts:' + accts);

		ApexPages.StandardController ctr = new ApexPages.StandardController(new Account());
		AccountBookingCustomer_ControllerX controllerX = new AccountBookingCustomer_ControllerX(ctr);        

    	PageReference pageRef = Page.AccountBookingCustomer;
		Test.setCurrentPage(pageRef);

		controllerX.nameSearch = 'Test Account';
		controllerX.doSearch();
		controllerX.searchResults.add(accts[0]);
		controllerX.ac = controllerX.searchResults[0].Clone();
		controllerX.privatePartyFlg = true;
		controllerX.setPersonAccount();
		controllerX.save();
	}		
}
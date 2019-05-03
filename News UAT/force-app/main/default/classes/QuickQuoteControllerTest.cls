@isTest
private class QuickQuoteControllerTest {
	
	@isTest static void test_createOpportunity() {
		Account account = new Account();
		account.Name = 'test';
		account.No_Parent_Account__c = true;

		insert account;

		Test.startTest();

		QuickQuoteController.createOpportunity(account.Id);

		Test.stopTest();
	}
}
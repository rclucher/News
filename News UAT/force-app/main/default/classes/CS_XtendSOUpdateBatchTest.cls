@isTest private class CS_XtendSOUpdateBatchTest {
	
    @isTest static void runTest() {

		Account acc	= TestDataSetupClass.createAccount();
		acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId(); 
		insert acc;

		Contact contact = TestDataSetupClass.createContact(acc);
		contact.Email = 'test@test.com';
		insert contact;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, contact);
		insert opp;

		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		so.Platform_Set__c = '';
		so.csmso__Total_Price__c = 100.00;
		insert so;

		// do tests
    	Test.startTest();

        Database.executeBatch(new CS_XtendSOUpdateBatch(true));

        Test.stopTest();
    }
	
}
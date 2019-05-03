@isTest private class CS_XtendSOEndDateUpdateBatchTest {
	
    @isTest static void runTest() {

		Account acc	= TestDataSetupClass.createAccount();
		acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId(); 
		insert acc;

		Contact contact = TestDataSetupClass.createContact(acc);
		contact.Email = 'test@test.com';
		insert contact;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, contact);
		insert opp;

		csmso__Sales_Order__c so1 = TestDataSetupClass.createSalesOrder(acc, opp);
		so1.Platform_Set__c = '';
		so1.Campaign_End_Date__c = System.today()-100;
		insert so1;

		csmso__Sales_Order__c so2 = TestDataSetupClass.createSalesOrder(acc, opp);
		so2.Platform_Set__c = '';
		so2.Campaign_End_Date__c = null;
		so2.Campaign_Start_Date__c = System.today()-100;
		so2.Campaign_Length__c = 6;
		insert so2;

		// do tests
    	Test.startTest();

        Database.executeBatch(new CS_XtendSOEndDateUpdateBatch(true));

        Test.stopTest();
    }
	
}
@isTest
private class BatchDeleteProcess_Test {

	@testSetup static void Setup() {
		Portfolio_Staging__c port = new Portfolio_Staging__c();
		port.Portfolio_Code__c = '01';

		insert port;

		Portfolio_Account_Staging__c psa = new Portfolio_Account_Staging__c();
		psa.Account_Name__c = 'Sample';

		insert psa;
	}

	/**
	* Delete the Portfolio_S
	 */
	@isTest static void batchDelete_Test() {
		
		Test.startTest();

		BatchDeleteProcess d = new BatchDeleteProcess();
		Database.executeBatch(d);

		Test.stopTest();

		System.assertEquals(0,[select count() from Portfolio_Account_Staging__c],'Portfolio_Account_Staging__c should be empty');
	}


	@isTest static void batchDeletePortStaging_Test() {
		Test.startTest();

		BatchDeleteProcess d = new BatchDeleteProcess(true);
		Database.executeBatch(d);

		Test.stopTest();
		System.assertEquals(0,[select count() from Portfolio_Staging__c],'Portfolio_Staging__c should be empty');
	}
}
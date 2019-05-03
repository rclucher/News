@isTest
private class AccountCloneDeleteBatchTest {
	
	@isTest static void test_method_one() {
	
	 AccountReport__c testAccount = new AccountReport__c(name = 'testAccountForSalesOrderSupportTest',
                                          Billing_Status__c = 'Green',
                                          No_Parent_Account__c = true,
                                          Is_Digital__c = true,
                                          Adpoint_Id__c = '99999',
                                          Status__c='Inactive');
  
 		insert testAccount;

 		Test.startTest();

        AccountCloneDeleteBatch obj = new AccountCloneDeleteBatch();
        DataBase.executeBatch(obj); 
            
        Test.stopTest();             
	
	}
	
		
}
@isTest
private class OpportunityCloneDeleteBatchTest {
	
	@isTest static void test_method_one() {
	
	 OpportunityReport__c testOpportunity = new OpportunityReport__c(name = 'testAccountForSalesOrderSupportTest',
                                          Stage__c='Qualify Opportunity',Close_Date__c=System.today().addYears(4));

  
 		insert testOpportunity;

 		Test.startTest();

        OpportunityCloneDeleteBatch obj = new OpportunityCloneDeleteBatch();
        DataBase.executeBatch(obj); 
            
        Test.stopTest();   



		// Implement test code
	}
	
	
	
}
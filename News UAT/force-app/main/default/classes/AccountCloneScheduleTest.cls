@isTest
private class AccountCloneScheduleTest {
	
	@testSetup static void prepareTest() {

	Account acc = TestDataSetupClass.createAccount();
		insert acc;
}
@isTest static void runTest() {
        Test.startTest();

        AccountCloneUpdateBatch obj = new AccountCloneUpdateBatch();
        DataBase.executeBatch(obj); 
            
        Test.stopTest();             
	}
	
}
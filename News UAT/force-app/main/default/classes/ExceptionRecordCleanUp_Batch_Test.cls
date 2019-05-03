/*---------------------------------------------------------
 * Author: Bluewolf
 * Company: Bluewolf.com
 * Description: This is the test class for ExceptionRecordCleanUp_Batch batch class
 * History:
 * 24/11/2015  Blueworlf Created
 * 2015-12-18  Atul Gupta  Updated
 // 2016-01-15 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - ExceptionRecordCleanUp_Batch   80%
---------------------------------------------------------*/
@isTest
private class ExceptionRecordCleanUp_Batch_Test { 
	
	static testMethod void exceptionRecordMethod(){
		
		//create Accounts
		List<Account> createParentAccount = TestDataFactory.createAccounts(1, false);
		insert createParentAccount;
		
		//create Accounts
		List<Account> accounts = TestDataFactory.createAccounts(10, false);
		for(Account acc : accounts){
			acc.Account_Last_Modified__c = system.now();
			acc.Ultimate_Parent_Id__c = createParentAccount[0].Id;
		}
		insert accounts;
		
		Batch_Run_Start_Datetime__c bat = new Batch_Run_Start_Datetime__c();
		bat.Run_Start_Datetime__c = system.now() - 1;
		bat.Name = 'Account TGS Update Batch';
		insert bat;
		
		//call TestDataFactory method to create exception records
		List<Exception_Record__c> exceptionRecords = TestDataFactory.createExceptionRecords(100, 'TCSTAS');
		insert exceptionRecords;
		
		//query Exception Records
		List<Exception_Record__c> queryRecords = [Select id from Exception_Record__c where Action_Type__c = 'TCSTAS'];
		
		//assert that there are 100 records inserted
		System.assertEquals(queryRecords.size(), 100);
		
        Test.startTest();
        ExceptionRecordCleanUp_Batch exceptionBatch = new ExceptionRecordCleanUp_Batch('TCSTAS');
        Database.executeBatch(exceptionBatch);
        Test.stopTest();

        //Verify that exception records are deleted
        Integer i = [SELECT COUNT() FROM Exception_Record__c where Action_Type__c = 'TCSTAS'];
        System.assertEquals(i,0);
	}
	
	static testMethod void exceptionRecordMethod_For_TGS(){
		
		//create Accounts
		List<Account> createParentAccount = TestDataFactory.createAccounts(1, false);
		insert createParentAccount;
		
		//create Accounts
		List<Account> accounts = TestDataFactory.createAccounts(10, false);
		for(Account acc : accounts){
			acc.Account_Last_Modified__c = system.now();
			acc.Ultimate_Parent_Id__c = createParentAccount[0].Id;
		}
		insert accounts;
		
		Batch_Run_Start_Datetime__c bat = new Batch_Run_Start_Datetime__c();
		bat.Run_Start_Datetime__c = system.now() - 1;
		bat.Name = 'Account TGS Update Batch';
		insert bat;
		
		//call TestDataFactory method to create exception records
		List<Exception_Record__c> exceptionRecords = TestDataFactory.createExceptionRecords(100, 'TGS');
		insert exceptionRecords;
		
		//query Exception Records
		List<Exception_Record__c> queryRecords = [Select id from Exception_Record__c where Action_Type__c = 'TGS'];
		
		//assert that there are 100 records inserted
		System.assertEquals(queryRecords.size(), 100);
		
        Test.startTest();
        ExceptionRecordCleanUp_Batch exceptionBatch = new ExceptionRecordCleanUp_Batch('TGS');
        Database.executeBatch(exceptionBatch);
        Test.stopTest();

        //Verify that exception records are deleted
        Integer i = [SELECT COUNT() FROM Exception_Record__c where Action_Type__c = 'TGS'];
        System.assertEquals(i,0);
	}
}
/*
* Author: Paul Kang
* Test to Rollup the worst colour from the Account's External_Account__c Credit_Status__c
*/

@isTest
private class BookingSystemAccount_HelperTest {

	public static Integer accounts = 10;
	public static Integer bookingAccounts = 10;
	

	@testSetup static void setup() {

		// Ignore the deduplication rules and save the records anyway
		Database.DMLOptions dml = new Database.DMLOptions(); 
		dml.DuplicateRuleHeader.allowSave = true;

        // Create common test accounts
        List<Account> testAccts = new List<Account>();
        for(Integer i=0;i < accounts;i++) {
            Account newAcct = new Account(Name = 'TestAcct'+ string.valueof(i) );
            newAcct.No_Parent_Account__c = true;
            testAccts.add(newAcct);
        }

  		List<Database.SaveResult> sr = Database.insert(testAccts, dml);   

  		System.debug('@save result ' + sr);

        	  // Create Booking System Accounts
		List<External_Account__c> testBSAs = new List<External_Account__c>();
        
        for (Account acct : testAccts) {

	        for(Integer i=0; i < bookingAccounts; i++) {
	        	External_Account__c newBSA = new External_Account__c();

	        	System.debug('@acct.id ' + acct.Id);
	        	newBSA.Customer_Account__c = acct.Id;

	        	if (math.mod(i, 2) == 0) {
	        		newBSA.Credit_Status__c = 'Amber';
	        	} else {
	        		newBSA.Credit_Status__c = 'Orange';
	        	}

	        	newBSA.External_Id__c = 'GBA_T' + acct.Id + String.valueof(i);

	        	testBSAs.add(newBSA);
	        }
    	}

    	List<Database.SaveResult> result = Database.Insert(testBSAs, dml);    
		System.debug('@save result BSAs' + result);

    }


    /*
    * Initial setup, the worst Credit_Status__c colour is Orange, this will check if the additional External_Account__c 'Red' will 
    * override the Account.Billing_Status__c as the worst colour    
    * 
    */
	@isTest static void test_assignCreditStatus() {

			System.debug('@BookingSystemAccount_HelperTest.test_assignCreditStatus START');

			Account acct = [Select Id, Billing_Status__c from Account Limit 1];


			Test.startTest();
			External_Account__c ext = new External_Account__c(External_Id__c = 'GBA_T234234', 
											Customer_Account__c=acct.Id, 
											Credit_Status__c = 'Red',
											Account_Type__c = 'Established');
			insert ext;

			

			BookingSystemAccount_Helper.assignCreditStatus(new External_Account__c[]{ext});
			Test.stopTest();

			acct = [Select Id, Billing_Status__c from Account Limit 1];
			System.assertEquals('Red', acct.Billing_Status__c);


       
	}

	
}
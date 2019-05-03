/** 
 *
 * @author      Paul Kang, Bluewolf 
 * @description Batch Apex to process from Portfolio_Account_Staging__c to Junction Objects Test class
 * @description Modified 2018-02-05 Paul Kang 
 *				
 **/
@isTest
public class PortfolioAccountMappingProcess_Test {
	private static Integer numOfRecords = 5;


	@testSetup static void Setup() {
		// adpoint accounts
		List<Account> accounts = new List<Account>();
		for(Integer i = 0; i < numOfRecords; i++) {
			// create Accounts
			Account newAccount = new Account();
			newAccount.AccountNumber = '47 007 871 171';
			newAccount.AdPoint_Id__c = '100' + i;
			newAccount.Name = 'account name' + i;
			newAccount.No_Parent_Account__c = true;			
			
			accounts.add(newAccount);
		}
		insert accounts;

		List<Portfolio2__c> portfolioList = new List<Portfolio2__c>();
		for(Integer i=0;i<numOfRecords;i++) {
			Portfolio2__c port = new Portfolio2__c();
			port.Portfolio_Code__c = '1' + i;
			port.Name = 'Random' + i;
			portfolioList.add(port);
		}
		insert portfolioList;

		List<External_Account__c> bsaList = new List<External_Account__c>();
		for(Integer i=0;i<numOfRecords;i++) {
			External_Account__c bsa = new External_Account__c();
			bsa.External_ID__c = 'GBA_T' + i;
			bsa.Customer_Account__c = accounts[0].Id;
			bsaList.add(bsa);
		}
		insert bsaList;


  		// Load all the staging objects
        List<Portfolio_Account_Staging__c> stagingList = new List<Portfolio_Account_Staging__c>();
        
        for(Integer y = 0; y < numOfRecords; y++) {
        	Portfolio_Account_Staging__c portStaging = new Portfolio_Account_Staging__c();
        	portStaging.Account_Number__c =  (math.mod(y, 2) == 0) ? '100' + y : 'GBA_T' + y;
        	portStaging.Account_Name__c = 'name' + y;
        	portStaging.Account_Source_Type__c  = (math.mod(y, 2) == 0) ? 'ADPT' : 'GNRA';
        	portStaging.New_Portfolio_Code__c = '1' + y;
        	portStaging.Relationship_Type__c = 'National';
        	portStaging.External_ID__c = portStaging.Account_Number__c + '|' + portStaging.Relationship_Type__c + '|' + portStaging.New_Portfolio_Code__c;
        	stagingList.add(portStaging);

        }

        insert stagingList;

	}

	
	
	@isTest static void test_GetAccountId() {
		// Implement test code
		Test.startTest();

		PortfolioAccountMappingProcess process = new PortfolioAccountMappingProcess();
		process.GetAccountId('GBA_T178745','GNRA');

		Test.stopTest();
	}


	// Copy records over to junction objects
	@isTest static void test_execute() {

		Account_Portfolio_Relationship__c acctPortJunction = new Account_Portfolio_Relationship__c();
		acctPortJunction.Account__c = [Select Id from Account limit 1].Id;
		acctPortJunction.Portfolio__c = [Select Id from Portfolio2__c limit 1].Id;
		acctPortJunction.ExternalID__c = [Select External_ID__c from Portfolio_Account_Staging__c limit 1].External_ID__c;
		insert acctPortJunction;

		

		Test.startTest();
		PortfolioAccountMappingProcess process = new PortfolioAccountMappingProcess();
		Database.executeBatch(process,200);
		
		AccountPortfolioRelationshipBatch process1 = new AccountPortfolioRelationshipBatch();
		Database.executeBatch(process1,200);

		
		Test.stopTest();

		System.assertEquals(3, [Select count() from Account_Portfolio_Relationship__c]);
		System.assertEquals(2, [Select count() from Booking_System_Portfolio_Junction__c]);
		BookingSystemPortfolioJunctionBatch process2 = new BookingSystemPortfolioJunctionBatch();
		Database.executeBatch(process2,200);

	}



	


	
}
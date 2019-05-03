/** 
 *
 * @author      Paul Kang 
 * @description Test class for Portfolio Picker
 * @description Modified 2018-01-29 Paul Kang changed the Portfolio2__c fields to text to minimise lookups
 *				
 **/

@isTest
private class OpportunityPortfolioPicker_Ctrl_Test {
	private static Integer numOfRecords = 5;
	private static String defaultPortfolioCode = '03';

	@testSetup static void Setup() {

		List<Account> accounts = new List<Account>();
		for(Integer i = 0; i < numOfRecords; i++) {
			// create Accounts
			Account newAccount = new Account();
			newAccount.AccountNumber = '47 007 871 171';
			newAccount.AdPoint_Id__c = 'adpointId ' + i;
			newAccount.Name = 'account name' + i;
			newAccount.No_Parent_Account__c = true;			
			
			accounts.add(newAccount);
		}
		insert accounts;

		List<Opportunity> oppts = new List<Opportunity>();
		for(Integer i = 0; i < numOfRecords; i++) {
			// create Accounts
			Opportunity newOpp = new Opportunity(
				Name = 'testOpp' + i,
				StageName = 'Prospect' + i,
				Portfolio_Code__c = defaultPortfolioCode,
				CloseDate = Date.today(),
				AccountId = accounts[0].Id,
				OwnerId = UserInfo.getUserId()
			);
			
			oppts.add(newOpp);
		}
		insert oppts;

			External_Account__c bsa = new External_Account__c();
			bsa.Customer_Account__c = accounts[0].Id;
			bsa.External_Id__c = 'GBA_T1772723';
					
		insert bsa;


		// insert new Portfolio2__c
		Portfolio2__c newPort = new Portfolio2__c();
		newPort.Portfolio_Code__c = '100';
		newPort.Conformed_Name__c = 'SME NSW ADM City and East 1';
		newPort.Conformed_Owner__c = UserInfo.getUserId();

		insert newPort;

		// insert the Account Portfolio relationship
		Account_Portfolio_Relationship__c apr = new Account_Portfolio_Relationship__c();
		
		apr.Account__c = accounts[0].Id;
		apr.Start_Date__c = Date.today();
		apr.Portfolio__c = newPort.Id;

		insert apr;

		// insert the BSA junction
		Booking_System_Portfolio_Junction__c bsp = new Booking_System_Portfolio_Junction__c();
		bsp.Portfolio__c = newPort.Id;
		bsp.Booking_System_Account__c = bsa.Id;

		insert bsp;

		Portfolio_Owners__c newOwner = new Portfolio_Owners__c();
    	newOwner.Portfolio2__c = newPort.Id;
    	newOwner.Portfolio_Owner__c = UserInfo.getUserId();
    	insert newOwner;
	}

	@isTest static void test_getPortfolios() {
		
		List<Opportunity> opps = [Select Id from Opportunity];
		List<SelectItems> resOptions = OpportunityPortfolioPicker_Controller.getPortfolios(opps[1].Id);

		System.debug(resOptions);
		System.assert(resOptions.size() > 0);
	}
    
    @isTest static void test_getPortfolioByOwner (){

    	Id owner = UserInfo.getUserId();
    	Test.startTest();
    	Set<Id> resId = OpportunityPortfolioPicker_Controller.getPortfoliosByOwner(owner);
    	Test.stopTest();

    	System.assert(resId.size() > 0);        
    }


    @isTest static void test_getDefaultPortfolio() {

    	String oppId = [Select Id From Opportunity where Name = 'testOpp0'].Id;
		OpportunityPortfolioPicker_Controller.PortfolioResponse res = OpportunityPortfolioPicker_Controller.getOpptyPortfolio(oppId);
	
		System.assertEquals(UserInfo.getUserId(), res.opportunityOwner);
		System.assertEquals(defaultPortfolioCode, res.defaultPortfolio);
    }
	
}
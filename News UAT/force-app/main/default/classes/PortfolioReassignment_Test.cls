/** 
 *
 * @author      Paul Kang, Bluewolf 
 * @description Update all Opened Opportunities Portfolio Codes with the updated code from the parent Account
 * @description Modified 2018-02-11 Paul Kang 
 **/
@isTest
private class PortfolioReassignment_Test {
	
	static Integer numOfRecords = 5;

	//static Portfolio2__c port {get; set;}

	private static Product2 SetupProducts() {

		Product2 prod = new Product2();
		prod.isTest__c = true;
		prod.Name = 'test Prod';

		insert prod;

		Pricebook2 pb2 = new Pricebook2();
		pb2.Name = 'sample pricebook';
		pb2.IsActive = true;
		insert pb2;


		PricebookEntry pbe = new PricebookEntry();
		pbe.UnitPrice = 10.0;
		pbe.Product2Id = prod.id;
		pbe.Pricebook2Id = pb2.id;
		pbe.UseStandardPrice = true;
		
		insert pbe;

		return prod;
	}

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


		Portfolio2__c oldPort = new Portfolio2__c();
		oldPort.Portfolio_Code__c = '04';
		oldPort.Conformed_Name__c = 'previous portfolio code';
		insert oldPort;


		List<Opportunity> oppts = new List<Opportunity>();
		for(Integer i=0; i < numOfRecords; i++) {
			Opportunity newOppt = new Opportunity();
			newOppt.AccountId = accounts[1].Id;
			newOppt.Name = 'randomName' + i;
			newOppt.Portfolio_Code__c = oldPort.Portfolio_Code__c;
			newOppt.StageName = 'Discover Needs';
			newOppt.CloseDate = System.today();
			oppts.add(newOppt);
		}
		insert oppts;

		//List<OpportunityLineItem> opptProds = new List<OpportunityLineItem>();
		//for(Opportunity opp : oppts) {
		
		//	for(Integer i=0; i<numOfRecords; i++) {
		//		OpportunityLineItem op = new OpportunityLineItem();
		//		op.OpportunityId = opp.id;
		//		op.TotalPrice = Math.random();
		//		op.Quantity = Math.random();
		//		//op.Product2Id = SetupProducts().Id;
		//		opptProds.add(op);
		//	}
		//}

		//insert opptProds;

	 	Portfolio2__c port = new Portfolio2__c();
		port.Portfolio_Code__c = '02';
		port.Conformed_Name__c = 'test name';
		insert port;


	}

	@isTest static void test_PortfolioCodeChange() {

		Account account = [Select Id, AdPoint_Id__c from Account where AdPoint_Id__c=:'1001'];
		Portfolio2__c oldPort = [Select Id from Portfolio2__c where Portfolio_Code__c ='04'];
		Portfolio2__c port = [Select Id from Portfolio2__c where Portfolio_Code__c ='02'];

		// Load sample account portfolios
		
		List<Account_Portfolio_Relationship__c> acctPorts = new List<Account_Portfolio_Relationship__c>();
		for(Integer i=0; i < numOfRecords; i++) {
			Account_Portfolio_Relationship__c apr = new Account_Portfolio_Relationship__c();
			apr.Account__c = account.Id;
			apr.Portfolio__c = port.Id;
			apr.ExternalID__c = '1001';
			acctPorts.add(apr);
		}
		insert acctPorts;

		External_Account__c bsaAcct = new External_Account__c();
		bsaAcct.Customer_Account__c = account.Id;
		bsaAcct.External_Id__c = 'GBA_T001';
		insert bsaAcct;


		// Load sample bsa to portfolios
		List<Booking_System_Portfolio_Junction__c> bsaPorts = new List<Booking_System_Portfolio_Junction__c>();
		for(Integer i=0; i < numOfRecords; i++) {
			Booking_System_Portfolio_Junction__c bsa = new Booking_System_Portfolio_Junction__c();
			bsa.Booking_System_Account__c = bsaAcct.Id;
			bsa.Portfolio__c = port.Id;
			bsa.BSA_Portfolio_Id__c = 'GBA_T00' + i;
			bsaPorts.add(bsa);
		}
		insert bsaPorts;


		System.assertEquals(numOfRecords, [Select count() from Opportunity where Portfolio_Code__c ='04']);


		Test.startTest();

		PortfolioReassignmentProcess process = new PortfolioReassignmentProcess();
		Database.executeBatch(process, 2000);

		Test.stopTest();

		System.assertEquals(numOfRecords, [Select count() from Opportunity where Portfolio_Code__c ='02']);
		
	}


	
	@isTest static void test_SendReminder() {
		Integer invocations = 0;

		List<Opportunity> oppts = [Select Id, OwnerId, Portfolio_Code__c from Opportunity];

		Test.startTest();
		PortfolioReassignmentProcess process = new PortfolioReassignmentProcess();

		process.SendReminder(oppts);	

		invocations = Limits.getEmailInvocations();	

		Test.stopTest();

		System.assertEquals(1, invocations, 'One email was sent due to more than 1 portfolio to opportunity');
	}

	
}
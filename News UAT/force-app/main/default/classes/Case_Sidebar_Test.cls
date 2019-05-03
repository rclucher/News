@isTest
private class Case_Sidebar_Test 
{
    // 2015-02-11 louis.wang@bluewolf.com
    //    This class provides test coverage for 
    //		- Case_AccountInfo - 91% coverage
    //		- Case_EnhancedAccountSearch - 88%  coverage
    //		- Case_NewAccountContact - 90% coverage
    //		- Case_Sidebar_Helper - 88% coverage
	
    public static Case case_unsaved;
    public static Case case1_withoutAccount;
    public static Case case2_withAccount;
    public static Booking__c booking;

	public static void setup() 
	{
		// create Account records
		list<Account> acctList = TestDataFactory.createAccounts(1, false);
		insert acctList;

		// create Case records
		list<Case> caseList = TestDataFactory.createCases(5, null, null);
		insert caseList;
		case1_withoutAccount = caseList[0];		

		case2_withAccount = caseList[1];
		case2_withAccount.AccountId = acctList[0].Id;
		update case2_withAccount;

		case_unsaved = new Case();

		// create Contact records
		list<Contact> contList = TestDataFactory.createContacts(5, acctList[0]);
		contList[0].LastName = 'Test';
		insert contList;

		// create custom setting
		SystemParameters__c param = new SystemParameters__c();
		param.Name = 'Default Sales Rep';
		param.External_Id__c = 'Default Sales Rep';
		param.Value__c = UserInfo.getUserId();
		insert param;

		// create SalesOrder records (alread inserted in TestDataFactory)
		Sales_Order__c so = TestDataFactory.createSalesOrder('CyberAd');

		// create booking records (alread inserted in TestDataFactory)
		booking  = TestDataFactory.createBooking(so);
	}

	@isTest
	public static void case_AccountInfo_noCase_Test()
	{
		setup();

    	// test 
    	Test.startTest();
		PageReference pr = Page.Case_AccountInfo;
		Test.SetCurrentPage(pr);
    	ApexPages.StandardController ctr = new ApexPages.StandardController(case_unsaved);
        Case_AccountInfo cai = new Case_AccountInfo(ctr);
		cai.init();
		Test.stopTest();
	}

	@isTest
	public static void case_AccountInfo_noAccount_Test()
	{
		setup();		

    	// test 
    	Test.startTest();
		PageReference pr = Page.Case_AccountInfo;
		pr.getParameters().put('Id', case1_withoutAccount.Id);
		Test.SetCurrentPage(pr);
    	ApexPages.StandardController ctr = new ApexPages.StandardController(case1_withoutAccount);
        Case_AccountInfo cai = new Case_AccountInfo(ctr);
		cai.init();
		Test.stopTest();
	}

	@isTest
	public static void case_AccountInfo_withAccount_Test()
	{
		setup();

    	// test 
    	Test.startTest();
		PageReference pr = Page.Case_AccountInfo;
		pr.getParameters().put('Id', case2_withAccount.Id);
        Test.SetCurrentPage(pr);
    	ApexPages.StandardController ctr = new ApexPages.StandardController(case2_withAccount);
        Case_AccountInfo cai = new Case_AccountInfo(ctr);
		cai.init();
		cai.createNewContact();

		cai.applySelection();

		cai.AddVfMessage('Test');
		Test.stopTest();
	}

	@isTest
	public static void case_EnhancedAccountSearch_noCase_Test()
	{
		setup();

    	// test 
    	Test.startTest();
		PageReference pr = Page.Case_EnhancedAccountSearch;
		Test.SetCurrentPage(pr);
    	ApexPages.StandardController ctr = new ApexPages.StandardController(case_unsaved);
        Case_EnhancedAccountSearch ceas = new Case_EnhancedAccountSearch(ctr);
		ceas.init();
		Test.stopTest();
	}

	@isTest
	public static void case_EnhancedAccountSearch_Test()
	{
		setup();

    	// test 
    	Test.startTest();
		PageReference pr = Page.Case_EnhancedAccountSearch;
		pr.getParameters().put('Id', case1_withoutAccount.Id);
        Test.SetCurrentPage(pr);
    	ApexPages.StandardController ctr = new ApexPages.StandardController(case1_withoutAccount);
        Case_EnhancedAccountSearch ceas = new Case_EnhancedAccountSearch(ctr);
		ceas.init();

		// search for contact
		ceas.searchNow_Booking();
		ceas.keywordString = 'Test';
		ceas.searchNow_Booking();
		ceas.searchNow_Case();
		ceas.searchNow_Account();
		ceas.searchNow_Contact();
		ceas.createNewAccount();
		ceas.applySelection();

		pr.getParameters().put('selectedType', 'booking');
        Test.SetCurrentPage(pr);
		ceas.applySelection();

		pr.getParameters().put('selectedType', 'case');
        Test.SetCurrentPage(pr);
		ceas.applySelection();

		pr.getParameters().put('selectedType', 'account');
        Test.SetCurrentPage(pr);
		ceas.applySelection();

		pr.getParameters().put('selectedType', 'contact');
        Test.SetCurrentPage(pr);
        ceas.applySelection();

        // search for booking
        string bookingNumber = [SELECT Name FROM Booking__c WHERE Id =: booking.Id].Name;
		ceas.keywordString = bookingNumber;
		ceas.searchNow_Booking();

		pr.getParameters().put('selectedType', 'booking');
        Test.SetCurrentPage(pr);
		ceas.applySelection();

		// search for case
		string caseNumber = [SELECT CaseNumber FROM Case WHERE Id =: case1_withoutAccount.Id].CaseNumber;
		ceas.keywordString = caseNumber;
		ceas.searchNow_Case();

		pr.getParameters().put('selectedType', 'case');
        Test.SetCurrentPage(pr);
		ceas.applySelection();

		ceas.gotoAccountInfoPage();
		Test.stopTest();
	}	

	@isTest
	public static void Case_NewAccountContact_noCase_Test()
	{
		setup();

    	// test 
    	Test.startTest();
		PageReference pr = Page.Case_NewAccountContact;
		Test.SetCurrentPage(pr);
    	ApexPages.StandardController ctr = new ApexPages.StandardController(case_unsaved);
        Case_NewAccountContact cnac = new Case_NewAccountContact(ctr);
		cnac.init();
		Test.stopTest();		
	}

	@isTest
	public static void Case_NewAccountContact_AccountType_Test()
	{
		setup();

    	// test 
    	Test.startTest();
		PageReference pr = Page.Case_NewAccountContact;
		pr.getParameters().put('id', case1_withoutAccount.Id);
		pr.getParameters().put('type', 'account');
		Test.SetCurrentPage(pr);
    	ApexPages.StandardController ctr = new ApexPages.StandardController(case1_withoutAccount);
        Case_NewAccountContact cnac = new Case_NewAccountContact(ctr);
		cnac.init();

		cnac.acct.FirstName = 'Test';
		cnac.acct.LastName = 'LastName';
		cnac.saveAccount();
		cnac.recordTypeSelected = cnac.personAccountRTId;
		cnac.saveAccount();		
		cnac.refreshPage();
		cnac.cancelNewRecord();

		Test.stopTest();		
	}

	@isTest
	public static void Case_NewAccountContact_ContactType_Test()
	{
		setup();

    	// test 
    	Test.startTest();
		PageReference pr = Page.Case_NewAccountContact;
		pr.getParameters().put('id', case2_withAccount.Id);
		pr.getParameters().put('type', 'contact');
		Test.SetCurrentPage(pr);
    	ApexPages.StandardController ctr = new ApexPages.StandardController(case2_withAccount);
        Case_NewAccountContact cnac = new Case_NewAccountContact(ctr);
		cnac.init();

		cnac.cont.FirstName = 'Test';
		cnac.saveContact();
		cnac.cont.LastName = 'LastName';		
		cnac.saveContact();

		Test.stopTest();		
	}	
}
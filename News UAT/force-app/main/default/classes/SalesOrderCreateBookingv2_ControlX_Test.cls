/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * 2015-12-18  Atul Gupta  Updated
 * 2016-01-14 atul.gupta@bluewolfgroup.com
 * 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
 *
 *  This class provides test coverage for
 *      - SalesOrderCreateBookingv2_ControllerX.cls     81%
 ---------------------------------------------------------*/
@isTest
public class SalesOrderCreateBookingv2_ControlX_Test 
{
	@isTest
    static void newSOUnitTest() 
    {
    	TestDataFactory.createCustomPricebookData_Standard();
    	TestDataFactory.createFaxSystemParameters();
    	
    	List<Account> accounts = TestDataFactory.createAccounts(24, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

        PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Sales_Order__c so = new Sales_Order__c();

       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');        
        
        controller.so.Booking_Type__c = 'Direct';
        controller.so.Source_System__c = 'CyberAd';
        controller.so.Booking_Division__c = 'NWN';

        boolean isCyber = controller.getIsCyber();
        system.assert(isCyber); 
        
        boolean isDirect = controller.getIsDirect();
        system.assert(isDirect);        
        
        boolean isAgency = controller.getIsAgency();
        system.assert(!isAgency);         
        
        
        boolean hasSearched = controller.hasSearched;
        system.assert(!hasSearched); 
        

        ComponentControllerBase co = controller.getComponentController();
        PageControllerBase pcb = controller.getThis();       
        controller.setComponentController(co); 

        AccountSearch_Controller AccountSearchController = new AccountSearch_Controller();
        controller.setComponentControllerMap('accountSearch', AccountSearchController);
        AccountSearchController.pageController = pcb;
        AccountSearchController.key = 'accountSearch';

        AccountSearch_Controller SearchAccountComponentController = controller.SearchAccountComponentController;
        SearchAccountComponentController = controller.SearchAccountComponentController;
        SearchAccountComponentController.minCharLength = 1;
        integer SearchListSize = SearchAccountComponentController.getSearchListSize();

        SearchAccountComponentController.searchAccountNameText = accounts[0].Name;
        SearchAccountComponentController.searchPhoneText = '610212';
        SearchAccountComponentController.isAndCondition = true;        
        SearchAccountComponentController.doAccountQuery();

        SearchAccountComponentController.isAndCondition = false;        
        SearchAccountComponentController.doAccountQuery();
        
        SearchAccountComponentController.findAccountResults = [Select id, Name, Phone, BillingStreet, BillingCountry, BillingPostalCode, BillingState, BillingCity from Account where id IN :accounts];
        
        ApexPages.StandardSetController setCon = SearchAccountComponentController.setCon; 
        
        List<Account> getAccounts = SearchAccountComponentController.getAccounts();
        integer getAccountListSize = SearchAccountComponentController.getAccountListSize();
        integer getAccountListCurrentPage = SearchAccountComponentController.getAccountListCurrentPage();

        boolean getAccountListHasNext = SearchAccountComponentController.getAccountListHasNext();
        SearchAccountComponentController.accountNextPage();

        boolean getAccountListHasPrevious = SearchAccountComponentController.getAccountListHasPrevious();
        SearchAccountComponentController.accountPreviousPage();
        
        ApexPages.currentPage().getParameters().put('selectedAccountId',SearchAccountComponentController.findAccountResults[0].id);
        SearchAccountComponentController.doSelectAccount();
        
        SearchAccountComponentController.selectedAccount = SearchAccountComponentController.findAccountResults[0];
        
        Account selectedAdvertiser = controller.selectedAdvertiser;
        
		boolean showHeaderAndSidebar = controller.showHeaderAndSidebar;
		system.assert(showHeaderAndSidebar); 
        
        AccountCreate_Controller AccountCreateController = new AccountCreate_Controller();
        controller.setComponentControllerMap('accountCreate', AccountCreateController);
        AccountCreate_Controller CreateAccountComponentController = controller.CreateAccountComponentController;
        
        CreateAccountComponentController.showAddnewAccount();
        CreateAccountComponentController.cancelAddnewAccount();
        
        CreateAccountComponentController.showAddnewAccount();
        
        List<selectOption> accountRecordTypeOptions = CreateAccountComponentController.accountRecordTypeOptions;
        
        string rtID = accountRecordTypeOptions[0].getValue();//[SELECT Id, Name, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName != 'Agency_Account_Type' LIMIT 1].id;
        CreateAccountComponentController.setAccountSelectedRectype(rtID);
        string  getAccountSelectedRectype = CreateAccountComponentController.getAccountSelectedRectype();
        String accountSelectedRectypeName = CreateAccountComponentController.accountSelectedRectypeName;
        
        CreateAccountComponentController.contactProxy.FirstName = 'John';
        CreateAccountComponentController.contactProxy.LastName = 'Smith';
        CreateAccountComponentController.newAccount.Name = 'Foo Biz';
        CreateAccountComponentController.newAccount.Phone ='555-5555';
        
        CreateAccountComponentController.saveAddnewAccount();
        selectedAdvertiser = controller.selectedAdvertiser;

        system.assert(selectedAdvertiser!=null);

        External_account__c externalAccount = TestDataFactory.createExternalAccount(selectedAdvertiser,'Billing_Account', 'BA123456',null);
        External_account__c externalAccount2 = TestDataFactory.createExternalAccount(selectedAdvertiser,'Billing_Account', 'BA123457',null);

        controller.payerPicklistSelection = 'new';
        controller.onChangePicklistSelection();

        controller.payerPicklistSelection = selectedAdvertiser.id; 
        controller.onChangePicklistSelection();

        controller.onChangePayerAccount();
        
        controller.so.Contact__c = contacts[0].id;

        controller.so.External_Account__c = externalAccount.id;
        List<SelectOption> billingAccounts = controller.getBillingAccounts();

        controller.doBook();

        controller.cancelAndRedirectToSource();
		
        // Added by Tim Fabros 23 / 05 / 2014 
        // Additional method calls to increase test coverage
        // BEGIN:
        controller.doResetAdvertiserAccount();
        controller.getIsGenera();
        Boolean testBooleanValue = controller.isMakingOrderSuccess;
        //controller.getSalesOrderOwnerId();
        // END:
		//controller.showAddNewGBA();
		List<SelectOption> getBookingAccounts = controller.getBookingAccounts();
    }
    
    
 	static testMethod void existingSOUnitTest() {
 		
 		TestDataFactory.createFaxSystemParameters();
 		List<CyberAd_User_Credential__c> extSysCredential = TestDataFactory.createdCyberAdUserCredentials();
 		
    	
    	insert new Pricebook2(Name = 'Standard Price Book');
    	
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

       	PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');        
        
        controller.so.Booking_Type__c = 'Direct';
        controller.so.Source_System__c = 'Cyber$ell';
        controller.onChangeBookingType();

        controller.so.Advertiser_Account__c = accounts[0].id;
        controller.so.Payer_Account__c = accounts[0].id; 
        controller.so.Contact__c = contacts[0].id;

        controller.onChangePayerAccount();

        controller.doBook();

        controller.cancelAndRedirectToSource();
        
        SystemMessages__c sysMsg = new SystemMessages__c();
        sysMsg.name = 'No Booking System Account';
        sysMsg.External_Id__c = 'Test112'+ String.valueOf(math.random());
        sysMsg.Message__c = 'Test Message';
        insert sysMsg;
        
        //controller.adPointWebserviceHelper;
        Boolean createGBA = controller.canCreateGBA;
        String bookSystem = controller.noBookingSystemAccountMessage;
        
        AccountCreate_Controller AccountCreateController = new AccountCreate_Controller();
        Account acc = AccountCreateController.newAccount;
        acc.name = 'test account';
        acc.No_Parent_Account__c = true;
        insert acc;
        controller.setComponentControllerMap('accountCreate', AccountCreateController);
        AccountCreate_Controller CreateAccountComponentController = controller.CreateAccountComponentController;
        
        controller.populateSelectedAdvertiser();
 	}

    private static  List<Product2> gproducts; 
    private static  List<Pricebook2> gpricebooks;
    private static  list<PricebookEntry> gpricebookEntries;

 	static testMethod void testForAccountSearchController() {
 		
 		TestDataFactory.createFaxSystemParameters();
 		List<CyberAd_User_Credential__c> extSysCredential = TestDataFactory.createdCyberAdUserCredentials();
 		
    	
    	insert new Pricebook2(Name = 'Standard Price Book');
    	
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

       	PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');        
        
        controller.so.Booking_Type__c = 'Direct';
        controller.so.Source_System__c = 'AdPoint';
        controller.onChangeBookingType();

        controller.so.Advertiser_Account__c = accounts[0].id;
        controller.so.Payer_Account__c = accounts[0].id; 
        controller.so.Contact__c = contacts[0].id;

        controller.cancelAndRedirectToSource();
        
        SystemMessages__c sysMsg = new SystemMessages__c();
        sysMsg.name = 'No Booking System Account';
        sysMsg.External_Id__c = 'Test113'+ String.valueOf(math.random());
        sysMsg.Message__c = 'Test Message';
        insert sysMsg;

        Boolean createGBA = controller.canCreateGBA;
        String bookSystem = controller.noBookingSystemAccountMessage;
        
        AccountSearch_Controller accSearch = new AccountSearch_Controller();
        Account acc = accSearch.selectedAccount;
        acc.Name = 'TestAccount';
        acc.No_Parent_Account__c = true;
        insert acc;

        AccountSearch_Controller searchAccountComponentController = controller.SearchAccountComponentController;
        
        controller.populateSelectedAdvertiser();
        
        boolean isMakPayer = controller.isMakingPayerAccountDigital;
        boolean isPayAcc = controller.isPayerAccountDigital;
        boolean isCont = controller.isContactDigital;
 	}
	
	@isTest
    public static void createPriceBookentry()
    {
        gproducts = TestDataFactory.createProducts(10);
        gpricebooks = TestDataFactory.createCustomPricebookData_Standard();
        gpricebookEntries = TestDataFactory.createPricebookEntryData(null, gproducts);
    }

 	@isTest
 	static void existingOppytUnitTest() {
    	
    	TestDataFactory.createFaxSystemParameters();
    	Pricebook2 pb2 = new Pricebook2(Name = 'Standard Price Book');
    	insert pb2; 

    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
    	for(Account acc : accounts){
    		acc.Digital_Status__c = 'InActive';
    	}
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

        createPriceBookentry();

        for(Product2 p : gproducts)
        {
            p.Booking_System__c = 'Cyber$ell';

        }

        update gproducts;

    	list<Opportunity> oppts = TestDataFactory.createOpportunities(1, null/*gpricebooks[0] */, accounts[0]);
    	
    	oppts[0].Payer_Account__c = accounts[0].id;
    	oppts[0].AccountId = accounts[0].id;
    	oppts[0].Contact__c = contacts[0].id;
    	insert oppts[0];
    	
        list<OpportunityLineItem> opptyLineItems = TestDataFactory.createOpportunityLineItems(oppts, gproducts, gpricebookEntries, null);
        insert opptyLineItems;


       	PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Sales_Order__c so = new Sales_Order__c();
        
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('opptyId', oppts[0].id);
        

       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);

        
        ApexPages.currentPage().getParameters().put('s','true');        

        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        ExternalAccountForm_Controller ExternalAccountFormController = new ExternalAccountForm_Controller();
        controller.setComponentControllerMap('externalAccountForm', ExternalAccountFormController);
        ExternalAccountForm_Controller ExternalAccountFormComponentController = controller.ExternalAccountFormComponentController;
        
        controller.so.Booking_Type__c = 'Direct';
        controller.so.Source_System__c = 'Cyber$ell';
        controller.onChangeBookingType();


        controller.doBook();
		
        controller.cancelAndRedirectToSource();
        
        Boolean isAdv = controller.isAdvertiserAccountDigital;
        Boolean isMak = controller.isMakingAdvertiserAccountDigital;
        system.debug('##so advertiser : '+ controller.so.Advertiser_Account__c);
        controller.so.Advertiser_Account__c = null;
        Boolean isAdv1 = controller.isAdvertiserAccountDigital;
        Boolean isMak1 = controller.isMakingAdvertiserAccountDigital;
        
 	} 	
 
    static testMethod void existingcampaignMemberUnitTest() {
    	
        List<CyberAd_User_Credential__c> extSysCredential = TestDataFactory.createdCyberAdUserCredentials();
    	
    	
        insert new Pricebook2(Name = 'Standard Price Book');
    	
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
        
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        insert campaigns;
        
		List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(1, contacts, campaigns[0]);        
		insert campaignMembers;
    	
       	PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Sales_Order__c so = new Sales_Order__c();
        
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('campaignMemberId', campaignMembers[0].id);
        

       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);

        
        ApexPages.currentPage().getParameters().put('s','true');        

        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        ExternalAccountForm_Controller ExternalAccountFormController = new ExternalAccountForm_Controller();
        controller.setComponentControllerMap('externalAccountForm', ExternalAccountFormController);
        ExternalAccountForm_Controller ExternalAccountFormComponentController = controller.ExternalAccountFormComponentController;
        
        controller.so.Booking_Type__c = 'Direct';
        controller.so.Source_System__c = 'Cyber$ell';
        controller.onChangeBookingType();

		controller.so.Advertiser_Account__c = accounts[0].id;
        controller.so.Payer_Account__c = accounts[0].id; 
        controller.so.Contact__c = contacts[0].id;

        controller.onChangePayerAccount();

        controller.showAddNewGBA();

        controller.cancelAndRedirectToSource();
        
 	} 	
    
     static testMethod void existingCaseUnitTest() {
     	
        List<CyberAd_User_Credential__c> extSysCredential = TestDataFactory.createdCyberAdUserCredentials();
     	
        
        insert new Pricebook2(Name = 'Standard Price Book');
        
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
        
        list<Case> cases = TestDataFactory.createCases(1,null,null);
        cases[0].AccountId = accounts[0].id;
        insert cases;

        PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Sales_Order__c so = new Sales_Order__c();
        
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('caseId', cases[0].id);
        

        ApexPages.StandardController stdController = new ApexPages.StandardController(so);

        
        ApexPages.currentPage().getParameters().put('s','false');        

        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        ExternalAccountForm_Controller ExternalAccountFormController = new ExternalAccountForm_Controller();
        controller.setComponentControllerMap('externalAccountForm', ExternalAccountFormController);
        ExternalAccountForm_Controller ExternalAccountFormComponentController = controller.ExternalAccountFormComponentController;
        
        controller.so.Booking_Type__c = 'Direct';
        controller.so.Source_System__c = 'Cyber$ell';
        controller.onChangeBookingType();

        controller.so.Advertiser_Account__c = accounts[0].id;
        controller.so.Payer_Account__c = accounts[0].id; 
        controller.so.Contact__c = contacts[0].id;

        controller.onChangePayerAccount();
        
        controller.showAddNewGBA();

        controller.cancelAndRedirectToSource();

    } 


     static testMethod void existingAccountUnitTest() {
     	
 	    List<CyberAd_User_Credential__c> extSysCredential = TestDataFactory.createdCyberAdUserCredentials();
     	
        
        insert new Pricebook2(Name = 'Standard Price Book');
        
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

        External_account__c externalAccount = TestDataFactory.createExternalAccount(accounts[0],'Booking_Account', 'T123456',null);
        External_account__c externalAccount2 = TestDataFactory.createExternalAccount(accounts[0],'Booking_Account', 'T123457',null);
        External_account__c externalAccountChild = TestDataFactory.createExternalAccount(accounts[0],'Booking_Account', 'T123458',externalAccount2);

        PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Sales_Order__c so = new Sales_Order__c();
        
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('acctId', accounts[0].id);

        ApexPages.StandardController stdController = new ApexPages.StandardController(so);

        
        ApexPages.currentPage().getParameters().put('s','false');        

        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        ExternalAccountForm_Controller ExternalAccountFormController = new ExternalAccountForm_Controller();
        controller.setComponentControllerMap('externalAccountForm', ExternalAccountFormController);
        ExternalAccountForm_Controller ExternalAccountFormComponentController = controller.ExternalAccountFormComponentController;
        
        controller.so.Booking_Type__c = 'Agency';
        controller.onChangeBookingType();
        
        controller.so.Source_System__c = 'Cyber$ell';
        controller.onChangeTargetSystem();

        controller.so.Advertiser_Account__c = accounts[0].id;
        
        controller.payerPicklistSelection = 'new';
        controller.onChangePicklistSelection();


        controller.payerPicklistSelection = accounts[0].id; 
        controller.onChangePicklistSelection();

        controller.onChangePayerAccount();
        
        controller.so.Contact__c = contacts[0].id;
		so.Booking_Division__c = 'NWN';
        controller.showAddNewGBA();
        
        list<SelectOption> targetSystems = controller.targetSystems;
        list<SelectOption> cyberAdDivisions = controller.cyberAdDivisions;
        List<SelectOption> getPayerAccounts = controller.getPayerAccounts();
        List<SelectOption> getBookingAccounts = controller.getBookingAccounts();
        List<SelectOption> getBillingAccounts = controller.getBillingAccounts();

        controller.tNumberSearch = 'T123456';
        controller.doTNumberSearch();

        ApexPages.currentPage().getParameters().put('selectedExternalAccountId', 'T123456');

        controller.doSelectTNumber();

        Contact newPayerContact = controller.newPayerContact;

        controller.showAddNewPayerContactFlag();
        boolean showAddNewPayerContactFlag = controller.showAddNewPayerContactFlag;
        controller.cancelAddNewPayerContact();
		
		controller.newPayerContact.FirstName = 'test first name';
        controller.newPayerContact.LastName = 'test last name';
        controller.saveAddNewPayerContact();

        controller.cancelAndRedirectToSource();
		boolean isPay = controller.isPayerAccountDigital;
    }
    
    // AdPoint test class
    static testMethod void adPointBookingUiTest() 
    {
        // create sample data
        CyberAd_User_Credential__c userCredential = new CyberAd_User_Credential__c();
        userCredential.AdPoint_User_Id__c = '123456';
        userCredential.User__c = UserInfo.getUserId();
        userCredential.Login_Access__c = true;
        userCredential.RecordTypeId = Global_Helper.getRecordTypeIdByName('AdPoint', 'CyberAd_User_Credential__c');
        insert userCredential;
        
        
        Pricebook2 pb2 = new Pricebook2(Name = 'Standard Price Book');
        insert pb2; 
        
        Id agencyAcctRecordTypeId = Global_Helper.getRecordTypeIdByName('Agency Account', 'Account');
        Id businessAcctRecordTypeId = Global_Helper.getRecordTypeIdByName('Business Account', 'Account');
        
        Industry_Code__c industryCode = TestDataFactory.createIndustryCode();
        insert industryCode;

        List<Account> accounts = new List<Account>();
        List<Account> agencyAccts = TestDataFactory.createAccounts(1, agencyAcctRecordTypeId);
        agencyAccts[0].Industry_Code__c = industryCode.Id;
        accounts.addAll(agencyAccts);
        List<Account> businessAccts = TestDataFactory.createAccounts(1, businessAcctRecordTypeId);
        businessAccts[0].Industry_Code__c = industryCode.Id;
        accounts.addAll(businessAccts);
        List<Account> nonSpecifiedAccts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        Sales_Order__c so = new Sales_Order__c();
        
        // create contacts
        List<Contact> contacts = new List<Contact>();
        
        List<Contact> nonSpecifiedContacts = TestDataFactory.createContacts(1, nonSpecifiedAccts[0]);
        contacts.addAll(nonSpecifiedContacts);
        List<Contact> agencyContacts = TestDataFactory.createContacts(1, agencyAccts[0]);
        contacts.addAll(agencyContacts);
        List<Contact> businessContacts = TestDataFactory.createContacts(1, businessAccts[0]);
        contacts.addAll(businessContacts);
        insert contacts;

        agencyAccts[0].Is_Digital__c = true;
        agencyAccts[0].Digital_Status__c = 'Active';
        agencyAccts[0].AdPoint_Id__c = '123457';
        update agencyAccts[0];

        system.debug('===businessContacts=== ' + businessContacts);
        
        Test.startTest();
        
        system.debug('adPointBookingUiTest @SalesOrderCreateBookingv2_ControlX_Test 0: ' + limits.getQueries()); // 0
        
        PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('acctId', businessAccts[0].id);
        ApexPages.currentPage().getParameters().put('s','false');        
        ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        controller.so.Booking_Type__c = 'Agency';
        controller.onChangeBookingType();
        
        controller.so.Source_System__c = 'AdPoint';
        controller.onChangeTargetSystem();
        
        system.debug('adPointBookingUiTest @SalesOrderCreateBookingv2_ControlX_Test 1: ' + limits.getQueries()); // 9
        
        system.assertEquals(businessAccts[0].id, controller.so.Advertiser_Account__c);
        system.assertEquals(null, controller.so.Payer_Account__c);
        system.assertEquals(null, controller.so.Placer_Account__c);
        system.assertEquals(null, controller.so.Contact__c);

        // fill payer account
        controller.so.Payer_Account__c = agencyAccts[0].Id;
        controller.onChangePayerAccount();
        
        // verify that placer account is as same as payer account
        system.assertEquals(controller.so.Payer_Account__c, controller.so.Placer_Account__c);
        
        // verify that make digital button is disabled
        // check make digital disable attribute on visualforce page 
        system.assertEquals(false, (controller.isReadyToMakeDigital));

        // provide contact to be the contact of payer account
        controller.so.Contact__c = agencyContacts[0].Id;
        controller.onChangeContact();
        
        // verify that error message disappear
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        Boolean hasMessage = false;
        
        system.debug(logginglevel.error, '===msgs=== ' + msgs);
        system.debug('===businessAccts[0].id=== ' + businessAccts[0].id);
        system.debug('===controller.so.Contact__c=== ' + controller.so.Contact__c);
        
        for(Apexpages.Message msg:msgs)
        {
            if (msg.getDetail().contains(SalesOrderCreateBookingv2_ControllerX.INVALID_ACCOUNT_CONTACT_REL_MSG))
                hasMessage = true;
                
            if (msg.getDetail().contains(SalesOrderCreateBookingv2_ControllerX.NON_DIGITAL_ADVERTISER_ACCT_MSG))
                hasMessage = true;
        }
        
        system.debug('adPointBookingUiTest @SalesOrderCreateBookingv2_ControlX_Test 2: ' + limits.getQueries()); // 23
        
        system.assert(hasMessage);

        // provide contact which not related to advertiser account
        controller.so.Contact__c = nonSpecifiedContacts[0].Id;
        controller.onChangeContact();

        // verify that error message display properly
        msgs = ApexPages.getMessages();
        hasMessage = false;
        
        for(Apexpages.Message msg:msgs)
        {
            if (msg.getDetail().contains(SalesOrderCreateBookingv2_ControllerX.INVALID_ACCOUNT_CONTACT_REL_MSG))
                hasMessage = true;
        }
        
        system.assert(hasMessage);
        
        controller.so.Contact__c = businessContacts[0].Id;
        controller.onChangeContact();
        
        system.assertEquals(true, controller.isAdPointBookingSystem);
        system.assertEquals(true, controller.isPayerAccountDigital);
        system.assertEquals(false, controller.isAdvertiserAccountDigital);

        controller.onChangePayerAccount();
        
        system.assertEquals(true, controller.isPayerAccountDigital);
        
        // Case 1: simulate that webservice call fails
        // In this case, we assume make advertiser account digital
        // and contact digital 
        
        Boolean hasMessageForAdvertiserAccount = false;
        Boolean hasMessageForContact = false;
        
        system.debug('adPointBookingUiTest @SalesOrderCreateBookingv2_ControlX_Test 3: ' + limits.getQueries()); // 54
        
        controller.makeDigital();

        // testing messages    
        msgs = ApexPages.getMessages();  
        for(Apexpages.Message msg:msgs)
        {
            if (msg.getDetail().contains(SalesOrderCreateBookingv2_ControllerX.WS_CREATE_DIGITAL_ADVERTISER_ERROR))
                hasMessageForAdvertiserAccount = true;
                
            if (msg.getDetail().contains(SalesOrderCreateBookingv2_ControllerX.WS_CREATE_DIGITAL_CONTACT_ERROR))
                hasMessageForContact = true;
        }
        
        system.assert(hasMessageForAdvertiserAccount);
        
        // TODO: recheck assertion below
        //system.assert(hasMessageForContact);
        
        // Case 2: simulate that webservice call succeed
        controller.isMakingAcctDigitalSuccess = true;
        controller.isMakingContactDigitalSuccess = true;
        
        system.debug('adPointBookingUiTest @SalesOrderCreateBookingv2_ControlX_Test 4: ' + limits.getQueries()); //77
        
        controller.makeDigital();
        
        system.debug('adPointBookingUiTest @SalesOrderCreateBookingv2_ControlX_Test 5: ' + limits.getQueries()); //
        
        // Verify that account and contact has been made digital successfully in SFDC
        Contact contact = [Select Id, Digital_Status__c, AdPoint_Id__c 
                            From Contact 
                            Where Id =: controller.so.Contact__c Limit 1];
                            
        Account advertiserAccount = [Select Digital_Status__c, is_Digital__c, AdPoint_Id__c 
                                    From Account 
                                    Where Id =: controller.so.Advertiser_Account__c Limit 1];
        
        Account placerAccount = [Select Id, Is_Digital__c, Digital_Status__c, AdPoint_Id__c 
                                From Account 
                                Where Id =: controller.so.Placer_Account__c Limit 1];
                                
        // verify is contact digital
        system.assertEquals('Active', contact.Digital_Status__c);
        system.assertNotEquals(null, contact.AdPoint_Id__c);
        
        // verify is advertiser account digital
        system.assertEquals('Active', advertiserAccount.Digital_Status__c);
        system.assertEquals(true, advertiserAccount.is_Digital__c);
        system.assertNotEquals(null, advertiserAccount.AdPoint_Id__c);
        
        // verify is placer account digital
        system.assertEquals('Active', placerAccount.Digital_Status__c);
        system.assertEquals(true, placerAccount.is_Digital__c);
        system.assertNotEquals(null, placerAccount.AdPoint_Id__c);
        

        //system.assertEquals(true, controller.isPlacerContactDigital);
        system.assertEquals(true, controller.isPayerAccountDigital);
        //system.assertEquals(true, controller.isPlacerAccountDigital);
        system.assertEquals(true, controller.isAdvertiserAccountDigital);
        
        Test.stopTest();
    }
    
    @isTest
    static void adPointBookingTest()
    {
    	TestDataFactory.createCustomPricebookData_Standard();
    	
    	TestDataFactory.createFaxSystemParameters();
    	List<User> users = TestDataFactory.createUsers(2, 'System Administrator', null, null, false);
    	insert users;
    	
    	// create sample data
        CyberAd_User_Credential__c userCredential1 = new CyberAd_User_Credential__c();
        userCredential1.AdPoint_User_Id__c = '123456';
        userCredential1.User__c = users[0].Id;
        userCredential1.RecordTypeId = Global_Helper.getRecordTypeIdByName('AdPoint', 'CyberAd_User_Credential__c');
        userCredential1.Login_Access__c = true;
        insert userCredential1;

        // create sample data
        CyberAd_User_Credential__c userCredential2 = new CyberAd_User_Credential__c();
        userCredential2.AdPoint_User_Id__c = '123457';
        userCredential2.User__c = users[1].Id;
        userCredential2.RecordTypeId = Global_Helper.getRecordTypeIdByName('AdPoint', 'CyberAd_User_Credential__c');
        userCredential2.Login_Access__c = true;
        insert userCredential2;

        // 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
        Industry_Code__c indCode = TestDataFactory.createIndustryCode();
        insert indCode;
                
        Id agencyAcctRecordTypeId = Global_Helper.getRecordTypeIdByName('Agency Account', 'Account');
        Id businessAcctRecordTypeId = Global_Helper.getRecordTypeIdByName('Business Account', 'Account');
        
        system.debug(logginglevel.error, '@agencyAcctRecordTypeId: ' + agencyAcctRecordTypeId);
        system.debug(logginglevel.error, '@businessAcctRecordTypeId: ' + businessAcctRecordTypeId);
        

        List<Account> accounts = new List<Account>();
        List<Account> agencyAccts = TestDataFactory.createAccounts(1, agencyAcctRecordTypeId);
        accounts.addAll(agencyAccts);
        List<Account> businessAccts = TestDataFactory.createAccounts(1, businessAcctRecordTypeId);
        accounts.addAll(businessAccts);
        List<Account> nonSpecifiedAccts = TestDataFactory.createAccounts(1, false);
        
        Integer i = 1000;
        for(Account acct : accounts)
        {
        	acct.Digital_Status__c = 'Active';
        	acct.Is_Digital__c = true;
        	acct.AdPoint_Id__c = String.valueOf(i);
            acct.Industry_Code__c = indCode.Id;
        	i++;
        }
        
        system.runAs(users[0])
        {  
	        insert accounts;
        }
        
        // create contacts
        List<Contact> contacts = new List<Contact>();
        
        List<Contact> nonSpecifiedContacts = TestDataFactory.createContacts(1, nonSpecifiedAccts[0]);
        contacts.addAll(nonSpecifiedContacts);
        List<Contact> agencyContacts = TestDataFactory.createContacts(1, agencyAccts[0]);
        contacts.addAll(agencyContacts);
        List<Contact> businessContacts = TestDataFactory.createContacts(1, businessAccts[0]);
        contacts.addAll(businessContacts);
        
        i = 1000;
        for(Contact con : contacts)
        {
            con.Digital_Status__c = 'Active';
            con.AdPoint_Id__c = String.valueOf(i);
            i++;
        }
	        
        system.runAs(users[0])
        { 
	        insert contacts;
        }
        
        Test.startTest();
        
        system.debug('adPointBookingUiTest @SalesOrderCreateBookingv2_ControlX_Test 0: ' + limits.getQueries()); // 0
        
        system.runAs(users[1])
        {
	        PageReference pageRef = Page.SalesOrderCreateBooking;
	        
	        Test.setCurrentPage(pageRef);
	        ApexPages.currentPage().getParameters().put('acctId', businessAccts[0].id);
	        ApexPages.currentPage().getParameters().put('s','false');   
	        Sales_Order__c so = new Sales_Order__c();     
	        ApexPages.StandardController stdController = new ApexPages.StandardController(so);
	        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
	        
	        controller.so.Booking_Type__c = 'Agency';
	        controller.onChangeBookingType();
	    
	        controller.so.Source_System__c = 'AdPoint';
	        controller.onChangeTargetSystem();
	        
	        // fill payer account
	        controller.so.Payer_Account__c = agencyAccts[0].Id;
	        controller.onChangePayerAccount();
	
	        // provide contact to be the contact of advertiser account
	        //controller.so.Contact__c = businessContacts[0].Id;
	        
            // provide contact to be the contact of agency account
	        controller.so.Contact__c = agencyContacts[0].Id;
	        controller.onChangeContact();
	        
	        system.debug('adPointBookingUiTest @SalesOrderCreateBookingv2_ControlX_Test 5: ' + limits.getQueries()); //
	        
	        // Verify that account and contact has been made digital successfully in SFDC
	        Contact contact = [Select Id, Digital_Status__c, AdPoint_Id__c 
	                            From Contact 
	                            Where Id =: controller.so.Contact__c Limit 1];
	                            
	        Account advertiserAccount = [Select Digital_Status__c, is_Digital__c, AdPoint_Id__c 
	                                    From Account 
	                                    Where Id =: controller.so.Advertiser_Account__c Limit 1];
	        
	        Account placerAccount = [Select Id, Is_Digital__c, Digital_Status__c, AdPoint_Id__c 
	                                From Account 
	                                Where Id =: controller.so.Placer_Account__c Limit 1];
	                                
	        // verify is contact digital
	        system.assertEquals('Active', contact.Digital_Status__c);
	        system.assertNotEquals(null, contact.AdPoint_Id__c);
	        
	        // verify is advertiser account digital
	        system.assertEquals('Active', advertiserAccount.Digital_Status__c);
	        system.assertEquals(true, advertiserAccount.is_Digital__c);
	        system.assertNotEquals(null, advertiserAccount.AdPoint_Id__c);
	        
	        // verify is placer account digital
	        system.assertEquals('Active', placerAccount.Digital_Status__c);
	        system.assertEquals(true, placerAccount.is_Digital__c);
	        system.assertNotEquals(null, placerAccount.AdPoint_Id__c);
	        
	
	        //system.assertEquals(true, controller.isPlacerContactDigital);
	        system.assertEquals(true, controller.isPayerAccountDigital);
	        //system.assertEquals(true, controller.isPlacerAccountDigital);
	        system.assertEquals(true, controller.isAdvertiserAccountDigital);
	        
	        // verify that error message disappear
	        List<Apexpages.Message> msgs = ApexPages.getMessages();
	        
	        system.debug('@adPointBookingTest msgs' + msgs);
	        
	        system.assertEquals(0, msgs.size());
	        
	        // make book and create sales order in SFDC
	        controller.doBook();
	        
	        system.debug('sales order @SalesOrderCreateBookingv2_ControlX_Test: ' + controller.so.Id);
	        
	        
	        // make book and create sales order in AdPoint
	        SalesOrderCreateBookingv2_ControllerX.createOrderInAdPoint(controller.so.Advertiser_Account__c, controller.so.Payer_Account__c, controller.so.Contact__c, controller.so.Id, true);
        }
        Test.stopTest();        
        
        // TODO: verify sales order adpoint id
        
        // TODO: verify booking record being created
    }
    
    static testMethod void changeBookingSystemTest() 
    {
        // create sample data
        Pricebook2 pb2 = new Pricebook2(Name = 'Standard Price Book');
        insert pb2; 
        
        Id agencyAcctRecordTypeId = Global_Helper.getRecordTypeIdByName('Agency Account', 'Account');
        Id businessAcctRecordTypeId = Global_Helper.getRecordTypeIdByName('Business Account', 'Account');
        
        List<Account> accounts = new List<Account>();
        List<Account> agencyAccts = TestDataFactory.createAccounts(1, agencyAcctRecordTypeId);
        accounts.addAll(agencyAccts);
        List<Account> businessAccts = TestDataFactory.createAccounts(1, businessAcctRecordTypeId);
        accounts.addAll(businessAccts);
        List<Account> nonSpecifiedAccts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        Sales_Order__c so = new Sales_Order__c();
        
        // create contacts
        List<Contact> contacts = new List<Contact>();
        
        List<Contact> nonSpecifiedContacts = TestDataFactory.createContacts(1, nonSpecifiedAccts[0]);
        contacts.addAll(nonSpecifiedContacts);
        List<Contact> agencyContacts = TestDataFactory.createContacts(1, agencyAccts[0]);
        contacts.addAll(agencyContacts);
        List<Contact> businessContacts = TestDataFactory.createContacts(1, businessAccts[0]);
        contacts.addAll(businessContacts);
        insert contacts;
        
        system.debug('===businessContacts=== ' + businessContacts);
        
        Test.startTest();
        
        PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('acctId', businessAccts[0].id);
        ApexPages.currentPage().getParameters().put('s','false');        
        ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        controller.so.Booking_Type__c = 'Agency';
        controller.onChangeBookingType();
        
        controller.so.Source_System__c = 'AdPoint';
        controller.onChangeTargetSystem();

        // fill payer account
        controller.so.Payer_Account__c = agencyAccts[0].Id;
        controller.onChangePayerAccount();
        
        // provide contact to be the contact of advertiser account
        controller.so.Contact__c = businessContacts[0].Id;
        controller.onChangeContact();

        // verify that error message display
        List<Apexpages.Message> msgs = ApexPages.getMessages();

        Boolean hasMessageForAdvertiserAccount = false;
        Boolean hasMessageForPayerAccount = false;
        Boolean hasMessageForContact = false;
        
        // testing messages    
        for(Apexpages.Message msg:msgs)
        {
            if (msg.getDetail().contains(SalesOrderCreateBookingv2_ControllerX.NON_DIGITAL_ADVERTISER_ACCT_MSG))
                hasMessageForAdvertiserAccount = true;
                
            if (msg.getDetail().contains(SalesOrderCreateBookingv2_ControllerX.NON_DIGITAL_AGENCY_PAYER_ACCT_MSG))
                hasMessageForPayerAccount = true;
                
            if (msg.getDetail().contains(SalesOrderCreateBookingv2_ControllerX.NON_DIGITAL_CONTACT_MSG))
                hasMessageForContact = true;
        }
        
        system.assert(hasMessageForAdvertiserAccount);
        system.assert(hasMessageForPayerAccount);
        system.assert(hasMessageForContact);
        
        Test.stopTest();
    }
    
    //Atul Test method created : 12/11/2015
    static testMethod void testgetSalesOrderOwnerId() {
	
    	TestDataFactory.createCustomPricebookData_Standard();
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

        
        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        PageReference pageRef = Page.SalesOrderCreateBooking;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');        
        
        controller.so.Booking_Type__c = 'Direct';
        controller.so.Source_System__c = 'Cyber$ell';
        controller.onChangeBookingType();

        controller.so.Advertiser_Account__c = accounts[0].id;
        controller.so.Payer_Account__c = accounts[0].id; 
        controller.so.Contact__c = contacts[0].id;
		controller.so.OwnerId = null;

        controller.getSalesOrderOwnerId();
        
        Boolean validRel = controller.isValidRelationship;
        Boolean makingAdv = controller.isMakingAdvertiserAccountDigital;
 	}
 	
 	//Atul Test method created : 12/11/2015
    static testMethod void testisAdvertiserAccountDigital() {

    	TestDataFactory.createCustomPricebookData_Standard();
    	
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

        
        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        PageReference pageRef = Page.SalesOrderCreateBooking;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');        
        
        controller.so.Booking_Type__c = 'Direct';
        controller.so.Source_System__c = 'Cyber$ell';
        controller.onChangeBookingType();

        controller.so.Payer_Account__c = accounts[0].id; 
        controller.so.Contact__c = contacts[0].id;
		controller.so.OwnerId = null;

        controller.getSalesOrderOwnerId();
        
        Boolean isPayerAcc = controller.isPayerAccountOnBlacklist;
        Boolean isPayerPrivate = controller.isPayerAccountPrivateParty;
        Boolean isAdvAccount = controller.isAdvertiserAccountDigital;
        Boolean isMakDigi = controller.isMakingAdvertiserAccountDigital;
 	}
 	
 	//Atul Test method created : 12/11/2015
    static testMethod void testisReadyDigital() {
 		
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
        
    	for(Account acc : accounts){
    		acc.Digital_Status__c = 'InActive';
    		acc.AdPoint_Id__c = '';
    	}
    	insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        for(Contact con : contacts){
        	con.Digital_Status__c = 'InActive';
        	con.AdPoint_Id__c = '';
        }
        insert contacts;

        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        so.Booking_Type__c = 'Direct';
        so.Source_System__c = 'AdPoint';

        so.Advertiser_Account__c = accounts[0].id;
        so.Payer_Account__c = accounts[0].id; 
        so.Contact__c = contacts[0].id;
        update so;
        
        Test.startTest();
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        PageReference pageRef = Page.SalesOrderCreateBooking;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');
        ApexPages.currentPage().getParameters().put('opptyId','1234');
        SalesOrderCreateBookingv2_ControllerX controller;
        try{
        	controller = new SalesOrderCreateBookingv2_ControllerX(stdController);
        }catch(Exception ex){
        	system.debug('@@ex : '+ ex);
        }
        Test.stopTest();
 	}
 	
 	//Atul Test method created : 12/11/2015
    static testMethod void testIsContactNull() {
 		
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

        
        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        so.Booking_Type__c = 'Direct';
        so.Source_System__c = 'AdPoint';

        so.Advertiser_Account__c = accounts[0].id;
        so.Payer_Account__c = accounts[0].id;
        update so;
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        PageReference pageRef = Page.SalesOrderCreateBooking;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');
        ApexPages.currentPage().getParameters().put('campaignMemberID','12345');
        try{
        	SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController);
        }catch(Exception ex){
        	system.debug('@@ex : '+ ex);
        }
 	}
 	
 	//Atul Test method created : 12/11/2015
    static testMethod void isCaseNull() {
 		
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

        
        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        so.Booking_Type__c = 'Direct';
        so.Source_System__c = 'AdPoint';

        so.Advertiser_Account__c = accounts[0].id;
        so.Payer_Account__c = accounts[0].id; 
        //so.Contact__c = contacts[0].id;
        update so;
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        PageReference pageRef = Page.SalesOrderCreateBooking;
        Test.setCurrentPage(pageRef);
        
        //ApexPages.currentPage().getParameters().put('s','true');
        ApexPages.currentPage().getParameters().put('caseId','12345');
        try{
        	SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController);
        }catch(Exception ex){
        	system.debug('@@ex : '+ ex);
        }
 	}
 	
 	//Atul Test method created : 12/11/2015
    static testMethod void isAccountNull() {
 		
 		List<Product2> products = TestDataFactory.createProducts(1);
    	for(Product2 pro : products){
    		pro.Name = 'Dummy';
    		pro.isActive = false;
    	}
    	update products;
    	
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        so.Booking_Type__c = 'Agency';
        so.Source_System__c = 'AdPoint';

        so.Payer_Account__c = accounts[0].id;
        update so;
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        PageReference pageRef = Page.SalesOrderCreateBooking;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('acctId','12345');
        SalesOrderCreateBookingv2_ControllerX controller;
        try{
        	controller = new SalesOrderCreateBookingv2_ControllerX(stdController);
        }catch(Exception ex){
        	system.debug('@@ex : '+ ex);
        }
 	}
 	
 	//Atul Test method created : 12/11/2015
    static testMethod void testOtherTests() {
 		
 		TestDataFactory.createCustomPricebookData_Standard();
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
    	for(Account acc : accounts){
    		acc.RecordtypeId = 	Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency Account').getRecordTypeId();
    	}
        insert accounts;
    	
    	External_account__c externalAccount = TestDataFactory.createExternalAccount(accounts[0],'Booking_Account', 'T123456',null);
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        so.Booking_Type__c = 'testAg';
        so.Source_System__c = 'AdPoint';

        so.Advertiser_Account__c = accounts[0].id;
        so.Payer_Account__c = accounts[0].id; 
        so.Contact__c = contacts[0].id;
        update so;
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        PageReference pageRef = Page.SalesOrderCreateBooking;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');
        ApexPages.currentPage().getParameters().put('acctId',accounts[0].Id);
        ApexPages.currentPage().getParameters().put('selectedExternalAccountId', externalAccount.Id);
        
    	SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController);
        
        List<SelectOption> optionList = controller.bookingTypes;
        list<SelectOption> cyberAdDivisions = controller.cyberAdDivisions;
        List<SelectOption> getPayerAccounts = controller.getPayerAccounts();

        controller.onChangeBookingDivision();
        controller.onChangePlacerAccount();
        
        controller.onChangeBookingType();
        
        boolean showTN = controller.showTNumberSearchFlag;
        controller.tNumberSearch = 'T123456';
        controller.doTNumberSearch();
        controller.doSelectTNumber();
 	}
 	
 	//Atul Test method created : 12/11/2015
    static testMethod void testExternalAccountStatusActive() {
 		
 		TestDataFactory.createCustomPricebookData_Standard();
 		List<Account> accounts1 = TestDataFactory.createAccounts(1, false);
        insert accounts1;
        
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
    	for(Account acc : accounts){
    		acc.RecordtypeId = 	Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency Account').getRecordTypeId();
    	}
        insert accounts;
    	
    	External_account__c parentExtAccount = TestDataFactory.createExternalAccount(accounts1[0],'Booking_Account', 'T2345',null);
    	parentExtAccount.Status__c = 'InActive';
    	update parentExtAccount;
    	
    	External_account__c externalAccount = TestDataFactory.createExternalAccount(accounts[0],'Booking_Account', 'T123456', parentExtAccount);
    	externalAccount.Customer_Account__c = accounts[0].Id;
    	update externalAccount;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        so.Booking_Type__c = 'testAg';
        so.Source_System__c = 'AdPoint';

        so.Advertiser_Account__c = accounts[0].id;
        so.Payer_Account__c = accounts[0].id; 
        so.Contact__c = contacts[0].id;
        update so;
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        PageReference pageRef = Page.SalesOrderCreateBooking;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');
        ApexPages.currentPage().getParameters().put('acctId',accounts[0].Id);
        ApexPages.currentPage().getParameters().put('selectedExternalAccountId', externalAccount.Id);
        
    	SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController);

        try{
        controller.doSelectTNumber();
        }catch(Exception ex){
        	system.assertEquals(ex.getMessage().contains('The parent of the selected booking system account is inactive.'), true);
        }
 	}
 	
 	//Created By : Atul Gupta,  Test for isPersonAccount in populateSelectedAdvertiser method
    static testMethod void testAdvertiserAccount_IsPersonAccount() {
 		
 		TestDataFactory.createCustomPricebookData_Standard();
 		TestDataFactory.createFaxSystemParameters();
 		List<CyberAd_User_Credential__c> extSysCredential = TestDataFactory.createdCyberAdUserCredentials();
 		
    	
    	insert new Pricebook2(Name = 'Standard Price Book');
    	
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

       	PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');        
        
        controller.so.Booking_Type__c = 'Direct';
        controller.so.Source_System__c = 'Cyber$ell';
        controller.onChangeBookingType();

        controller.so.Advertiser_Account__c = accounts[0].id;
        controller.so.Payer_Account__c = accounts[0].id; 
        controller.so.Contact__c = contacts[0].id;

        controller.onChangePayerAccount();

        controller.doBook();

        controller.cancelAndRedirectToSource();
        
        SystemMessages__c sysMsg = new SystemMessages__c();
        sysMsg.name = 'No Booking System Account';
        sysMsg.External_Id__c = 'Test112'+ String.valueOf(math.random());
        sysMsg.Message__c = 'Test Message';
        insert sysMsg;
        
        //controller.adPointWebserviceHelper;
        Boolean createGBA = controller.canCreateGBA;
        String bookSystem = controller.noBookingSystemAccountMessage;
        
        AccountCreate_Controller AccountCreateController = new AccountCreate_Controller();
        Account acc = AccountCreateController.newAccount;
        acc.FirstName = 'FirstName';
        acc.LastName = 'test account';
        acc.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Private Party').getRecordTypeId();
        acc.PersonMailingStreet='test@yahoo.com';
  		acc.PersonMailingPostalCode='12345';
  		acc.PersonMailingCity='SFO';
  		acc.PersonEmail='test@yahoo.com';
  		acc.PersonHomePhone='1234567';
  		acc.PersonMobilePhone='12345678';
        insert acc;
        controller.setComponentControllerMap('accountCreate', AccountCreateController);
        AccountCreate_Controller CreateAccountComponentController = controller.CreateAccountComponentController;
        
        controller.populateSelectedAdvertiser();
 	}
 	
 	//Created By : Atul Gupta,  Test for isPersonAccount for AccountSearch_Controller in populateSelectedAdvertiser method
 	static testMethod void testForAccountSearchController_IsPersonAccount() {
 		
 		TestDataFactory.createFaxSystemParameters();
 		List<CyberAd_User_Credential__c> extSysCredential = TestDataFactory.createdCyberAdUserCredentials();
 		
    	
    	insert new Pricebook2(Name = 'Standard Price Book');
    	
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;

       	PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('s','true');        
        
        controller.so.Booking_Type__c = 'Direct';
        controller.so.Source_System__c = 'AdPoint';
        controller.onChangeBookingType();

        controller.so.Advertiser_Account__c = accounts[0].id;
        controller.so.Payer_Account__c = accounts[0].id; 
        controller.so.Contact__c = contacts[0].id;

        controller.cancelAndRedirectToSource();
        
        SystemMessages__c sysMsg = new SystemMessages__c();
        sysMsg.name = 'No Booking System Account';
        sysMsg.External_Id__c = 'Test113'+ String.valueOf(math.random());
        sysMsg.Message__c = 'Test Message';
        insert sysMsg;
        
        //controller.adPointWebserviceHelper;
        Boolean createGBA = controller.canCreateGBA;
        String bookSystem = controller.noBookingSystemAccountMessage;
        
        AccountSearch_Controller accSearch = new AccountSearch_Controller();
        Account acc = accSearch.selectedAccount;
        acc.FirstName = 'FirstName';
        acc.LastName = 'TestAccount';
        acc.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Private Party').getRecordTypeId();
        acc.PersonMailingStreet='test@yahoo.com';
  		acc.PersonMailingPostalCode='12345';
  		acc.PersonMailingCity='SFO';
  		acc.PersonEmail='test@yahoo.com';
  		acc.PersonHomePhone='1234567';
  		acc.PersonMobilePhone='12345678';
        insert acc;
        
        AccountSearch_Controller searchAccountComponentController = controller.SearchAccountComponentController;
        
        controller.populateSelectedAdvertiser();
        
        boolean isMakPayer = controller.isMakingPayerAccountDigital;
        boolean isPayAcc = controller.isPayerAccountDigital;
        boolean isCont = controller.isContactDigital;
 	}
 	                                          
    //Created By : Atul Gupta,  Test for webservice method createOrderInAdPointFromAddBookingButton
 	static testMethod void testForCreateOrderPoint() {
 		
 		TestDataFactory.createFaxSystemParameters();
 		List<CyberAd_User_Credential__c> extSysCredential = TestDataFactory.createdCyberAdUserCredentials();
 		
    	
    	insert new Pricebook2(Name = 'Standard Price Book');
    	
    	List<Account> accounts1 = TestDataFactory.createAccounts(1, false);
    	for(Account acc : accounts1){
    		acc.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Agency Account').getRecordTypeId();
    		acc.Digital_Status__c = 'Active';
    	}
        insert accounts1;
        
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
    	for(Account acc : accounts){
    		acc.RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
    		acc.Media_Agency_For_Digital_Customer__c = accounts1[0].Id;
    	}
        insert accounts;
        
        list<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
		
		list<Case> cases = TestDataFactory.createCases(1,null,null);
        cases[0].AccountId = accounts[0].id;
        cases[0].Opportunity__c = null;
        insert cases;
        
       	PageReference pageRef = Page.SalesOrderCreateBooking;
        
        Sales_Order__c so = TestDataFactory.createSalesOrder('AdPoint');
        
       	ApexPages.StandardController stdController = new ApexPages.StandardController(so);
        
        SalesOrderCreateBookingv2_ControllerX controller = new SalesOrderCreateBookingv2_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('caseId',cases[0].Id);        
        
        String bookingButton = SalesOrderCreateBookingv2_ControllerX.createOrderInAdPointFromAddBookingButton(accounts[0].Id, accounts1[0].Id, contacts[0].Id, so.Id, true);
 	}
}
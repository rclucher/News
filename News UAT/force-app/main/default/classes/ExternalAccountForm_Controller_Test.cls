/*---------------------------------------------------------
 * Author: Bluewolf
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * 2015-12-16  Atul Gupta Updated
 // 2015-12-16 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - ExternalAccountForm_Controller 84%
 */
@isTest
private class ExternalAccountForm_Controller_Test {

	static testMethod void isAgencyFalse_NON_AdminUser() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;
			
			External_Account__c extAcct = TestDataFactory.createExternalAccount();

			Account acctAdvertiser = accountList[0];
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c		
									from Account
									Where id=:extAcct.Customer_Account__c];
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = acctPayer;
			eaf.phoneCountryCode = '43214';
			eaf.phoneAreaCode = '123';
			eaf.phone = '9876543212';

	        //TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
	        //TestDataFactory.createdCyberAdUserCredentialOne(UserInfo.getUserId());	
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();
			TestDataFactory.createCustomSettingGeneraRevenueGroups();

			User userTest = TestDataFactory.createUser('News IT Administration', 'testUser101', 'lastName101', null, true, true);
			insert userTest;

			System.runAs(userTest){
				
				TestDataFactory.createdCyberAdUserCredentialOne(userTest.id);//UserInfo.getUserId());
				
				map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
				list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			}
			
	}

	static testMethod void isAgencyFalseTest() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;
			
			External_Account__c extAcct = TestDataFactory.createExternalAccount();

			Account acctAdvertiser = accountList[0];
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c		
									from Account
									Where id=:extAcct.Customer_Account__c];
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = acctPayer;
			eaf.phoneCountryCode = '43214';
			eaf.phoneAreaCode = '123';
			eaf.phone = '9876543212';

	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());	
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();	
			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	}

    static testMethod void indirectTest() { 
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;
			
			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			//External_Account__c extAcct1 = TestDataFactory.createExternalAccount();

			Account acctAdvertiser = accountList[0];
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c		
									from Account
									Where id=:extAcct.Customer_Account__c];
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
	        eaf.isAgency = true;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = acctPayer;
			eaf.phoneCountryCode = '43214';
			eaf.phoneAreaCode = '123';
			eaf.phone = '9876543212';

	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());	
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();	
			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();
	
			eaf.init();
			eaf.redirectToPage = false;
			system.debug('@@eaf.gbaAccount :'+ eaf.gbaAccount);
			eaf.gbaAccount.External_Account__c = extAcct.id;
			eaf.gbaAccount.GBA_Phone_Area_Code__c = 1;
			eaf.gbaAccount.Default_Revenue_Group__c = 'Amusements';
			eaf.gbaAccount.Email_Confirmation_Address__c = 'test@sfdc.com';
			eaf.onParentAccountSelection();
	
	
			eaf.gbaAccount.Account_Type__c = 'Client of Ad Agency';
			eaf.onAccountTypeSelection();
	
			PageReference pr = eaf.saveNewGBAAndRedirect();

    }
    
    static testMethod void directTest() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;

			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c,
										Revenue_Group__c
									from Account
									Where id=:extAcct.Customer_Account__c];
			
			Account acctAdvertiser = acctPayer;	
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
	        eaf.isAgency = true;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = accountList[0];
	
			eaf.init();

	        eaf.selectedPayer = acctPayer;
	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();

			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();
			
			eaf.init();
			
			eaf.redirectToPage = true;
			
			eaf.gbaAccount.External_Account__c = extAcct.id;
			eaf.onParentAccountSelection();
	
			eaf.gbaAccount.Account_Type__c = 'Ad Agency';
			eaf.onAccountTypeSelection();
	
			PageReference pr = eaf.saveNewGBAAndRedirect();

			eaf.cancelNewGBA();

    }
    
    //test for validation account type needs parent account
    static testMethod void testParentAccountValidation() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;

			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c,
										Revenue_Group__c,
										IsPersonAccount
									from Account
									Where id=:extAcct.Customer_Account__c];
			
			Account acctAdvertiser = acctPayer;	
			
			//ExternalAccountCreateBookingAccount
			PageReference pageRef = Page.ExternalAccountCreateBookingAccount;
			Test.setCurrentPage(pageRef);
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
			//atul
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = accountList[0];
	
			eaf.init();

	        eaf.selectedPayer = acctPayer;
	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();

			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();

			eaf.redirectToPage = true;
			
			eaf.onParentAccountSelection();
	
			eaf.gbaAccount.Account_Type__c = 'Client of Ad Agency';
			
			eaf.onAccountTypeSelection();
	
			PageReference pr = eaf.saveNewGBAAndRedirect();
			List<Apexpages.Message> msgs = ApexPages.getMessages();
			system.assertEquals(msgs[0].getDetail().contains('Account Type Client of Ad Agency needs parent account'), true);

    }
    
    //test for validation account type needs parent account
    static testMethod void testPhoneNumberValidation() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;

			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c,
										Revenue_Group__c,
										IsPersonAccount
									from Account
									Where id=:extAcct.Customer_Account__c];
			
			Account acctAdvertiser = acctPayer;	
			
			PageReference pageRef = Page.ExternalAccountCreateBookingAccount;
			Test.setCurrentPage(pageRef);
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
			
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = accountList[0];
	
			eaf.init();

	        eaf.selectedPayer = acctPayer;
	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();

			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();

			eaf.redirectToPage = true;
			eaf.gbaAccount.External_Account__c = extAcct.id;
			eaf.onParentAccountSelection();
			eaf.gbaAccount.Account_Type__c = 'Client of Ad Agency';
			eaf.gbaAccount.GBA_Phone__c = '9876543212345';
			
			
			PageReference prNew = eaf.saveNewGBAAndRedirect();
			List<Apexpages.Message> msgs1 = ApexPages.getMessages();
			system.assertEquals(msgs1[0].getDetail().contains('Phone number is too long'), true);
    }
    
    //test for validation account type needs parent account
    static testMethod void testAccountTypeRequiredValidation() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;

			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c,
										Revenue_Group__c,
										IsPersonAccount
									from Account
									Where id=:extAcct.Customer_Account__c];
			
			Account acctAdvertiser = acctPayer;	
			
			PageReference pageRef = Page.ExternalAccountCreateBookingAccount;
			Test.setCurrentPage(pageRef);
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
			
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = accountList[0];
	
			eaf.init();

	        eaf.selectedPayer = acctPayer;
	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();

			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();

			eaf.redirectToPage = true;
			eaf.gbaAccount.External_Account__c = extAcct.id;
			eaf.onParentAccountSelection();
			eaf.gbaAccount.Account_Type__c = null;
			eaf.gbaAccount.GBA_Phone__c = '8765432123';
			
			PageReference pr = eaf.saveNewGBAAndRedirect();
			List<Apexpages.Message> msgs = ApexPages.getMessages();
			system.assertEquals(msgs[0].getDetail().contains('Account Type is required'), true);
			
    }
    
    
    //test for gbaaccount special characters in suburb field
    static testMethod void testSpecialChar_Suburb_Validation() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;

			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c,
										Revenue_Group__c,
										IsPersonAccount
									from Account
									Where id=:extAcct.Customer_Account__c];
			
			Account acctAdvertiser = acctPayer;	
			
			PageReference pageRef = Page.ExternalAccountCreateBookingAccount;
			Test.setCurrentPage(pageRef);
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
			
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = accountList[0];
	
			eaf.init();

	        eaf.selectedPayer = acctPayer;
	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();

			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();

			eaf.redirectToPage = true;
			
			eaf.gbaAccount.External_Account__c = extAcct.id;
			eaf.onParentAccountSelection();
	
			eaf.gbaAccount.Account_Type__c = 'Client of Ad Agency';
			
			eaf.onAccountTypeSelection();
			
			eaf.gbaAccount.Suburb__c = 'abc%12';
			try{
				PageReference pr = eaf.saveNewGBAAndRedirect();
			}catch(Exception ex){
				system.assertEquals(ex.getMessage().contains('Please remove special characters from Suburb field'), true);
			}
    }
    
    //test for gbaaccount special characters in Name field
    static testMethod void testSpecialChar_Name_Validation() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;

			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c,
										Revenue_Group__c,
										IsPersonAccount
									from Account
									Where id=:extAcct.Customer_Account__c];
			
			Account acctAdvertiser = acctPayer;	
			
			PageReference pageRef = Page.ExternalAccountCreateBookingAccount;
			Test.setCurrentPage(pageRef);
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
			
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = accountList[0];
	
			eaf.init();

	        eaf.selectedPayer = acctPayer;
	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();

			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();

			eaf.redirectToPage = true;
			
			eaf.gbaAccount.External_Account__c = extAcct.id;
			eaf.onParentAccountSelection();
	
			eaf.gbaAccount.Account_Type__c = 'Client of Ad Agency';
			
			eaf.onAccountTypeSelection();
			
			eaf.gbaAccount.Name = 'abc%12';
			eaf.gbaAccount.Suburb__c = 'test';
			try{
				PageReference pr1 = eaf.saveNewGBAAndRedirect();
			}catch(Exception ex){
				system.assertEquals(ex.getMessage().contains('Please remove special characters from Name field'), true);
			}
    }
    
    //test for gbaaccount special characters in Street field
    static testMethod void testSpecialChar_Street_Validation() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;

			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c,
										Revenue_Group__c,
										IsPersonAccount
									from Account
									Where id=:extAcct.Customer_Account__c];
			
			Account acctAdvertiser = acctPayer;	
			
			PageReference pageRef = Page.ExternalAccountCreateBookingAccount;
			Test.setCurrentPage(pageRef);
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
			
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = accountList[0];
	
			eaf.init();

	        eaf.selectedPayer = acctPayer;
	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();

			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();

			eaf.redirectToPage = true;
			
			eaf.gbaAccount.External_Account__c = extAcct.id;
			eaf.onParentAccountSelection();
	
			eaf.gbaAccount.Account_Type__c = 'Client of Ad Agency';
			
			eaf.onAccountTypeSelection();
			
			eaf.gbaAccount.Name = 'test';
			eaf.gbaAccount.Street__c = 'abc%12';
			eaf.gbaAccount.Suburb__c = 'test';
			try{
				PageReference pr = eaf.saveNewGBAAndRedirect();
			}catch(Exception ex){
				system.debug('@@ex : '+ ex.getMessage());
				system.assertEquals(ex.getMessage().contains('Please remove special characters from Street field'), true);
			}
    }
    
    //test for gbaaccount special characters in Country field
    static testMethod void testSpecialChar_Country_Validation() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;

			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c,
										Revenue_Group__c,
										IsPersonAccount
									from Account
									Where id=:extAcct.Customer_Account__c];
			
			Account acctAdvertiser = acctPayer;	
			
			PageReference pageRef = Page.ExternalAccountCreateBookingAccount;
			Test.setCurrentPage(pageRef);
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
			
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = accountList[0];
	
			eaf.init();

	        eaf.selectedPayer = acctPayer;
	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();

			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();

			eaf.redirectToPage = true;
			
			eaf.gbaAccount.External_Account__c = extAcct.id;
			eaf.onParentAccountSelection();
	
			eaf.gbaAccount.Account_Type__c = 'Client of Ad Agency';
			
			eaf.onAccountTypeSelection();
			
			eaf.gbaAccount.Name = 'test';
			eaf.gbaAccount.Street__c = 'streettest';
			eaf.gbaAccount.Suburb__c = 'test';
			eaf.gbaAccount.Country__c = 'abc%12';
			
			try{
				PageReference pr = eaf.saveNewGBAAndRedirect();
			}catch(Exception ex){
				system.assertEquals(ex.getMessage().contains('Please remove special characters from Country field'), true);
			}
    }
    
    //test for gbaaccount insert exception
    static testMethod void testInsertException() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;

			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c,
										Revenue_Group__c,
										IsPersonAccount
									from Account
									Where id=:extAcct.Customer_Account__c];
			
			Account acctAdvertiser = acctPayer;	
			
			PageReference pageRef = Page.ExternalAccountCreateBookingAccount;
			Test.setCurrentPage(pageRef);
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
			
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = accountList[0];
	
			eaf.init();

	        eaf.selectedPayer = acctPayer;
	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();

			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();

			eaf.redirectToPage = true;
			
			eaf.gbaAccount.External_Account__c = extAcct.id;
			eaf.onParentAccountSelection();
	
			eaf.gbaAccount.Account_Type__c = 'Client of Ad Agency';
			
			eaf.onAccountTypeSelection();

	        ABNLookupMockTest fakeResponse = new ABNLookupMockTest(200,
	                                                 'Complete',
	                                                 '[{"Name": "sForceTest1"}]',
	                                                 null);
			Test.setMock(HttpCalloutMock.class, fakeResponse);
	        eaf.doABNLookup();
	       
    }
    
    
    //test for createAccount
    static testMethod void testCreateAccount() {
			
			list<Account> accountList = TestDataFactory.createAccounts(1,false);
			insert accountList;

			External_Account__c extAcct = TestDataFactory.createExternalAccount();
			
			Account acctPayer = [select id, 
										Name,
										BillingPostalCode,
										BillingCountry,
										BillingState,
										BillingCity,
										BillingStreet,
										DPID_Primary_Address__c,
										AccountNumber,
										Phone,
										No_Parent_Account__c,
										Revenue_Group__c,
										IsPersonAccount
									from Account
									Where id=:extAcct.Customer_Account__c];
			
			Account acctAdvertiser = acctPayer;	
			
			PageReference pageRef = Page.ExternalAccountCreateBookingAccount;
			Test.setCurrentPage(pageRef);
			
	        ExternalAccountForm_Controller eaf = new ExternalAccountForm_Controller();
			
	        eaf.isAgency = false;
	        eaf.selectedAdvertiser = acctAdvertiser;
	        eaf.selectedPayer = accountList[0];
	
			eaf.init();

	        eaf.selectedPayer = acctPayer;
	        TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());
			TestDataFactory.createCustomSettingGeneraAccountTypeMapping();

			map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap = eaf.availableGBATypeMap;
	        list<selectOption> gbaAccountTypeOptionsForSelectAdvertiser = eaf.gbaAccountTypeOptionsForSelectAdvertiser;
			list<selectOption> gbadefaultRevenueGroupGeneraOptions = eaf.gbadefaultRevenueGroupGeneraOptions;
			list<selectOption> gbaDivisionOptions = eaf.gbaDivisionOptions;
			list<SelectOption> ParentBookingAccounts = eaf.getParentBookingAccounts();

			eaf.redirectToPage = true;
			
			eaf.gbaAccount.External_Account__c = extAcct.id;
			eaf.gbaAccount.GBA_Phone_Area_Code__c = 9;
			eaf.onParentAccountSelection();
	
			eaf.gbaAccount.Account_Type__c = 'Client of Ad Agency';
			
			eaf.onAccountTypeSelection();
			
			eaf.gbaAccount.Country__c = 'testCountry';
            eaf.gbaAccount.Name = 'test';
            eaf.gbaAccount.Title__c = 'test';
            eaf.gbaAccount.Email_Address__c = 'test@email.com';
            eaf.gbaAccount.Post_Code__c = '1234';
            eaf.gbaAccount.State__c = '2345';
            eaf.gbaAccount.Street__c = 'abc';
            eaf.gbaAccount.Suburb__c = 'subtest';
            eaf.gbaAccount.GBA_Phone_Country_Code__c = 12;
            eaf.gbaAccount.GBA_Phone__c = '9876543212';
            eaf.gbaAccount.Account_Type__c = 'typeTest';
            eaf.gbaAccount.ABN_Number__c = 'abnNo';
            eaf.gbaAccount.First_Name__c = 'testFirstName';
            eaf.gbaAccount.Last_Name__c = 'testLastName';
            eaf.gbaAccount.DPID__c = 'testDPID';
            eaf.gbaAccount.Default_Revenue_Group__c = 'revenueTest';
            eaf.gbaAccount.Email_Confirmation_Address__c = 'test1@email.com';
            eaf.gbaAccount.Division__c = 'testDivision';
            eaf.gbaAccount.Owning_Credit_Division__c = 'testCredit';
            
            Test.startTest();
            Test.setMock(WebServiceMock.class, new CreateAccountResponseMockTest());
            
	        string createdAccountString = eaf.createAccount();
	        Test.stopTest();
	        //system.debug('@@createdAccountString : '+ createdAccountString);
	        
    }
    
    //create general account type mapping
    public static list<Genera_Account_Type_Mapping__c> createGenAccountTypeMapping() {
    	
        list<Genera_Account_Type_Mapping__c> gatm = new list<Genera_Account_Type_Mapping__c>();
        
        gatm.add(  new Genera_Account_Type_Mapping__c ( Name = 'Client of Ad Agency',
                                                       Value__c = 'CL',
                                                       CreatedByNFSS__c = true,
                                                       CreatedBySales__c = true,
                                                       Parent__c = 'Ad Agency',
                                                       isABNrequired__c = false,
                                                       Owning_Credit_Division__c = 'N',
                                                       Request_Account_Divisions__c = 'N'));
        insert gatm;                                             
        return gatm;
    }
}
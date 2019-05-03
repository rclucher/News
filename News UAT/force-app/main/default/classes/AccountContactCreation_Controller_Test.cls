/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * History:
 * 2015-11-25   Darshan G   Updated
 
    // 2015-11-25 darshan.gosar@bluewolfgroup.com 
        // This class provides test coverage for
        //  - AccountContactCreation_Controller 88%
 */
@isTest
private class AccountContactCreation_Controller_Test {

    static testMethod void inboundCallCaseWithNoAccountNoContactNoCLI() {
        Case tCase = new Case(Origin='Call - Inbound');
        insert tCase;

        ApexPages.StandardController ctr = new ApexPages.StandardController(tCase);
        AccountContactCreation_Controller controller = new AccountContactCreation_Controller(ctr);
    }

    static testMethod void inboundCallCaseWithAccountNoContactNoCLI() {
        
        List<Account> accounts =  TestDataFactory.createAccounts(1,false);
        insert accounts;

        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        contacts[0].phone = '+61411309999';
        insert contacts;

        Case tCase = new Case(Origin='Call - Inbound', accountId = accounts[0].id);
        insert tCase;

        ApexPages.StandardController ctr = new ApexPages.StandardController(tCase);
        AccountContactCreation_Controller controller = new AccountContactCreation_Controller(ctr);


        PageReference pageRef = Page.AccountContactCreation;
        Test.setCurrentPage(pageRef);

        ComponentControllerBase co = controller.getComponentController();
        PageControllerBase pcb = controller.getThis();       
        controller.setComponentController(co); 

        AccountSearch_Controller AccountSearchController = new AccountSearch_Controller();
        controller.setComponentControllerMap('accountSearch', AccountSearchController);
        AccountSearchController.pageController = pcb;
        AccountSearchController.key = 'accountSearch';
        AccountSearch_Controller asctl = controller.SearchAccountComponentController; 

        AccountCreate_Controller AccountCreateController = new AccountCreate_Controller();
        controller.setComponentControllerMap('accountCreate', AccountCreateController);
        AccountCreate_Controller CreateAccountComponentController = controller.CreateAccountComponentController;
        
        CreateAccountComponentController.showAddnewAccount();
        CreateAccountComponentController.cancelAddnewAccount();
        
        CreateAccountComponentController.showAddnewAccount();

        list<Contact> contactsFound = controller.getcontactsFound();



        CreateAccountComponentController.contactProxy.FirstName = 'John';
        CreateAccountComponentController.contactProxy.LastName = 'Smith';
        CreateAccountComponentController.newAccount.Name = 'Foo Biz';
        CreateAccountComponentController.newAccount.Phone ='555-5555';
        
        controller.saveAddnewAccount();
        Case c = controller.currCase;

        controller.showAddNewContactFlag();
        controller.cancelAddNewContact();

        controller.showAddNewContactFlag();
        controller.newContact.accountId = accounts[0].id;
        controller.newContact.FirstName = 'jil';
        controller.newContact.LastName = 'lambe';
        controller.newContact.Phone = '+614113456789';
        controller.newContact.Email = 'email@email.com';
        controller.saveAddNewContact();

        ApexPages.currentPage().getParameters().put('selectedContactId', CreateAccountComponentController.newAccount.id);

        controller.doSelectContact();
    }

    static testMethod void inboundCallCaseWithNoAccountNoContactCLI() {
        list<id> fixedIds = new list<id>();
        List<Account> accounts =  TestDataFactory.createAccounts(3,false);
        insert accounts;

        for(Account a :accounts)
        {
            a.phone = '61411309990';
            fixedIds.add(a.id);
        }
        update accounts;



        List<Contact> contacts = TestDataFactory.createContacts(10, accounts[0]);
        insert contacts;
        
        for(Contact c :contacts)
        {
            c.phone = '61411309999';
            fixedIds.add(c.id);
        }
        update contacts;

        Case tCase = new Case(Origin='Call - Inbound', cLI__c = '61411');
        insert tCase;

        Test.setFixedSearchResults(fixedIds);
        ApexPages.StandardController ctr = new ApexPages.StandardController(tCase);
        AccountContactCreation_Controller controller = new AccountContactCreation_Controller(ctr);

        PageReference pageRef = Page.AccountContactCreation;
        Test.setCurrentPage(pageRef);


        //controller.setcontactsFound(contacts);
        list<Contact> contactsFound = controller.getcontactsFound();
        system.debug('@ inboundCallCaseWithNoAccountNoContactCLI() contactsFound.size():' + contactsFound.size());

        //controller.setaccountsFound(accounts);
        list<Account> accountsFound = controller.getaccountsFound();
        system.debug('@ inboundCallCaseWithNoAccountNoContactCLI() accountsFound.size():' + accountsFound.size());



        controller.getContactListSize();
        controller.getContactListCurrentPage();
        controller.getContactListHasNext();
        controller.contactNextPage();
        controller.getContactListHasPrevious();
        controller.contactPreviousPage();


        ApexPages.currentPage().getParameters().put('selectedAccountId', accounts[0].id);
        controller.doSelectContact();


        controller.getAccountListSize();
        controller.getAccountListCurrentPage();
        controller.getAccountListHasNext();
        controller.accountNextPage();
        controller.getAccountListHasPrevious();
        controller.accountPreviousPage();
    }

    static testMethod void inboundCallCaseWithAccountNoContactCLI() {
        
        List<Account> accounts =  TestDataFactory.createAccounts(1,false);
        accounts[0].phone = '+61411309998';
        insert accounts;

        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        contacts[0].phone = '+61411309999';
        insert contacts;

        Case tCase = new Case(Origin='Call - Inbound', accountId=accounts[0].id, cLI__c = '61411');
        insert tCase;

        ApexPages.StandardController ctr = new ApexPages.StandardController(tCase);
        AccountContactCreation_Controller controller = new AccountContactCreation_Controller(ctr);
    }

    static testMethod void inboundEmailCaseWithNoAccountNoContactCLI() {
        
        List<Account> accounts =  TestDataFactory.createAccounts(1,false);
        insert accounts;

        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        contacts[0].Email = 'test@tmail.com';
        insert contacts;

        Case tCase = new Case(Origin='Email - Inbound', SuppliedFromEmail_Text__c = 'test@tmail.co');
        insert tCase;

        ApexPages.StandardController ctr = new ApexPages.StandardController(tCase);
        AccountContactCreation_Controller controller = new AccountContactCreation_Controller(ctr);
    }
    
    // SFE-766 2015-11-25 darshan.gosar@bluewolfgroup.com 
        // New test methods were added to increase code coverage
    static testMethod void testCancelMethod() {
        
        List<Account> accounts =  TestDataFactory.createAccounts(1,false);
        insert accounts;

        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        contacts[0].Email = 'test@tmail.com';
        insert contacts;

        Case tCase = new Case(Origin='Email - Inbound', SuppliedFromEmail_Text__c = 'test@tmail.co');
        insert tCase;
        
        PageReference pageRef = Page.AccountContactCreation;
        Test.setCurrentPage(pageRef);
        
        ApexPages.currentPage().getParameters().put('refTabId','Test');
        ApexPages.currentPage().getParameters().put('isVf','true');        
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(tCase);
        AccountContactCreation_Controller controller = new AccountContactCreation_Controller(ctr);
        AccountCreate_Controller createAccountComponentController = controller.CreateAccountComponentController;
        
        controller.cancel();
    }  
    
    static testMethod void populatingcurrCaseMethod() {
        
        List<Account> accounts =  TestDataFactory.createAccounts(1,false);
        insert accounts;

        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        contacts[0].Email = 'test@tmail.com';
        insert contacts;

        Case tCase = new Case(Origin='Email - Inbound', SuppliedFromEmail_Text__c = 'test@tmail.co');
        insert tCase;

        Case tCase2 = new Case(accountId = accounts[0].Id, contactId = contacts[0].Id, Origin='Email - Inbound', SuppliedFromEmail_Text__c = 'test@tmail.co');
        insert tCase2;
                
        PageReference pageRef = Page.AccountContactCreation;
        Test.setCurrentPage(pageRef);               
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(tCase);
        AccountContactCreation_Controller controller = new AccountContactCreation_Controller(ctr);
        
        controller.cancel();
        controller.currCase.accountId = accounts[0].Id;
        controller.currCase.contactId = contacts[0].Id;
        controller.showAddNewContactFlag();
        
        ApexPages.StandardController ctr2 = new ApexPages.StandardController(tCase2);
        AccountContactCreation_Controller controller2 = new AccountContactCreation_Controller(ctr2);
        
        controller2.setaccountsFound(accounts);        
        controller2.setcontactsFound(contacts);
    }      
}
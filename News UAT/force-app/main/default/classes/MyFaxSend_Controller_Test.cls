// 2015-12-01 darshan.gosar@bluewolfgroup.com 
// 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    // This class provides test coverage for
    //  - MyFaxSend_Controller                     90%
    //  - TaskManagement.trigger                  100%
@isTest
private class MyFaxSend_Controller_Test 
{
    static testMethod void sendFaxForAccountTest() 
    {
        // create system parameters
        TestDataFactory.createFaxSystemParameters();
        
        // create an account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        PageReference sendFaxPage = Page.MyFaxSend;
        sendFaxPage.getParameters().put('relatedToId', accounts[0].Id);
        Test.setCurrentPage(sendFaxPage);
        
        ApexPages.StandardController stdCtr = new ApexPages.StandardController(accounts[0]);
        MyFaxSend_Controller myfaxSendCtr = new MyFaxSend_Controller(stdCtr);
        
        myfaxSendCtr.getRelatedToList();
    }
        
    static testMethod void sendFaxForContactTest() 
    {
        // create system parameters
        TestDataFactory.createFaxSystemParameters();
        
        // create an account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create a contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        PageReference sendFaxPage = Page.MyFaxSend;
        sendFaxPage.getParameters().put('relatedToId', contacts[0].Id);
        Test.setCurrentPage(sendFaxPage);
        
        ApexPages.StandardController stdCtr = new ApexPages.StandardController(contacts[0]);
        MyFaxSend_Controller myfaxSendCtr = new MyFaxSend_Controller(stdCtr);
    }

    // SFE-766 2015-12-01 darshan.gosar@bluewolfgroup.com
        // To cover test scenarios without seeAllData condition    
    @isTest
    static void sendFaxForCaseTest() 
    {
        // create system parameters
        TestDataFactory.createFaxSystemParameters();
        
        Account account = TestDataFactory.createAccounts(1, false).get(0);
        insert account;
        Contact contact = TestDataFactory.createContacts(1, account).get(0);
        contact.Fax = '612999999992';
        insert contact;

        // create a case
        List<Case> cases = TestDataFactory.createCases(1, null, null);
        cases[0].ContactId = contact.Id;
        insert cases;
        
        // create dummy document folder
        //Folder folder = [SELECT Id FROM Folder Limit 1];//[SELECT Id FROM Folder Where Name = 'Ad Proofing' Limit 1];

        

        // create dummy document
        Document document = new Document();
        document.Body = blob.valueOf('Test Body aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaabbbbbbbbbbbbbbbbbbbbbbbbbbbb');
        document.Name = 'Test Document';
        document.FolderId =UserInfo.getUserId(); //folder.Id;
        document.ContentType = 'text';
        //document.Type = 'HTML';
        insert document;

        

        document = [Select Body, Name, FolderId, BodyLength, ContentType From Document Where Id =: document.Id Limit 1];
        document = document.clone();

        PageReference sendFaxPage = Page.MyFaxSend;
        sendFaxPage.getParameters().put('relatedToId', cases[0].Id);
        Test.setCurrentPage(sendFaxPage);

        //ApexPages.StandardController stdCtr = new ApexPages.StandardController(cases[0]);
        ApexPages.StandardController stdCtr = new ApexPages.StandardController(document);
        MyFaxSend_Controller myfaxSendCtr = new MyFaxSend_Controller(stdCtr);

        

        List<SelectOption> options = myfaxSendCtr.getMyPersonalTemplateOptions();
        for (SelectOption selectOption : options)
        {
            if (selectOption.getValue() != '')
            {
                myfaxSendCtr.selectedTemplateId = selectOption.getValue();
                break;
            }
        }

        myfaxSendCtr.setEmailBody();
        
        // set document search value
        myfaxSendCtr.searchString = 'Test Body';

        myfaxSendCtr.InitiateDocumentList();
        //System.assertEquals(myfaxSendCtr.documentList[0].Name, document.Name);


        myfaxSendCtr.onChangeContact();

        myfaxSendCtr.attachFile();

        myfaxSendCtr.faxNumber = '612999999992';      
        myfaxSendCtr.doSendFax();
        
        Test.startTest();
        Test.setMock(WebServiceMock.class, new wsMyfaxComMock());
        myfaxSendCtr.doSendFax();

        Test.stopTest();

        myfaxSendCtr.removeAttachedFile();

        myfaxSendCtr.doCancel();
    }

    // SFE-766 2015-12-01 darshan.gosar@bluewolfgroup.com
        // Removed SalesRep user creation since its added to createFaxSystemParameters method    
    static testMethod void sendFaxForBookingTest() 
    {
        // create users
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;

        // create system parameters
        TestDataFactory.createFaxSystemParameters();
        
        // create sales order
        Sales_Order__c salesOrder = TestDataFactory.createSalesOrder('AdPoint');
        
        // create a booking
        Booking__c booking = TestDataFactory.createBooking(salesOrder);
        
        PageReference sendFaxPage = Page.MyFaxSend;
        sendFaxPage.getParameters().put('relatedToId', booking.Id);
        Test.setCurrentPage(sendFaxPage);
        
        ApexPages.StandardController stdCtr = new ApexPages.StandardController(booking);
        MyFaxSend_Controller myfaxSendCtr = new MyFaxSend_Controller(stdCtr);
    }
    
    // SFE-766 2015-12-01 darshan.gosar@bluewolfgroup.com
        // To cover test scenarios without seeAllData condition    
    @isTest
    static void sendFaxForOpportunityTest() 
    {
        // create system parameters
        TestDataFactory.createFaxSystemParameters();

        // create account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        insert accts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
        insert contacts;
        
        // create an opportunity
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        //TestDataFactory.createPricebookEntryData(pricebooks[0], pricebooks[1], products);
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, pricebooks[0].Id, accts[0], contacts[0]);
        insert opportunities;
        
        PageReference sendFaxPage = Page.MyFaxSend;
        sendFaxPage.getParameters().put('relatedToId', opportunities[0].Id);
        Test.setCurrentPage(sendFaxPage);
        
        ApexPages.StandardController stdCtr = new ApexPages.StandardController(opportunities[0]);
        MyFaxSend_Controller myfaxSendCtr = new MyFaxSend_Controller(stdCtr);
    }
    
    static testMethod void initTest() 
    {
        // create system parameters
        TestDataFactory.createFaxSystemParameters();
        // create an account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        PageReference sendFaxPage = Page.MyFaxSend;
        sendFaxPage.getParameters().put('relatedToId', accounts[0].Id);
        Test.setCurrentPage(sendFaxPage);
        
        MyFaxSend_Controller myfaxSendCtr = new MyFaxSend_Controller();
    }
}
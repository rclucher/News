/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * 
 * History:
 * 18/10/2013  Bohao Chen  Created
 * 10/03/2014  Bohao Chen  Commented Out
 * 2015-11-28 darshan.gosar@bluewolfgroup.com 
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c   
 *    This class provides test coverage for
 *      - BookingQuoteConfirmationVF_Ext.cls        83% 
 * ---------------------------------------------------------*/
@isTest
private class BookingQuoteConfirmation_Ext_Test 
{

    // SFE-766 2015-11-28 darshan.gosar@bluewolfgroup.com
        // To cover test scenarios without seeAllData condition
            
    static public List<Case> cases;
    static public Document doc;
    static public List<Booking__c> bookings;
    
    static public void setupData(){
        // setup test data
        // create user credentials
        List<CyberAd_User_Credential__c> userCredentials = TestDataFactory.createdCyberAdUserCredentials(UserInfo.getUserId());

        // create different types of accounts
        List<Account> accounts = new List<Account>();
        
        Account payerAccount = TestDataFactory.createSingleAccount(null, null, null, 0, 0);
        Account advertiserAccount = TestDataFactory.createSingleAccount(null, null, null, 0, 0);
        Account placerAccount = TestDataFactory.createSingleAccount(null, null, null, 0, 0);
        
        accounts.add(payerAccount);
        accounts.add(advertiserAccount);
        accounts.add(placerAccount);
        insert accounts;
  
        try{
             insert new SystemParameters__c(Name = 'Default Sales Rep', Value__c = UserInfo.getUserId(), External_Id__c = '1234');
        }catch(System.DmlException dmlex){

        }
        
        // create a contact for placer account
        List<Contact> contacts = TestDataFactory.createContacts(1, placerAccount);
        insert contacts;
        
        // create sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, payerAccount, advertiserAccount, 
                                                                            placerAccount, contacts[0], null);
        insert salesOrders;
        
        // create bookings for each sales order
        bookings = new List<Booking__c>();
        
        for(Sales_Order__c so : salesOrders)
        {
            bookings.addAll(TestDataFactory.createBookings(1, so, 'NWN', 'CyberAd'));
        }
        
        system.debug('===bookings=== ' + bookings);
        insert bookings;
        

        cases = new List<Case>();
        for(Booking__c b : bookings)
        {   
          for(Case c  : TestDataFactory.createCases(1, null, b))
          {
            c.AccountId = b.Advertiser_Account__c;
            c.ContactId = b.Placer_Contact__c;
           cases.add(c);
          }
        }
        
        insert cases;
        
        list<Group> groups = new list<Group>();
        groups.add(new Group (Email='first@test.eml' ,Type = 'Queue', Name='first@test.eml'));
        groups.add(new Group (Email='secondfirst@test.eml' ,Type = 'Queue', Name='secondfirst@test.eml'));
        groups.add(new Group (Email='secondsecond@test.eml' ,Type = 'Queue', Name='secondsecond@test.eml'));
        insert groups;
          

        // create products
        List<Product2> products = TestDataFactory.createProducts(10,'NWN');
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, pricebooks[0].Id, null, contacts[0]);
        insert opportunities;
        
        // create product mappings
        // testing publications one
        List<String> publications = TestDataFactory.createStringList(20, 'pub');
    
        // testing publication codes
        List<String> publicationCodes = TestDataFactory.createStringList(20, 'pubC');
    
        // testing ad types
        List<String> adTypes = TestDataFactory.createStringList(20, 'adType');
         
        //List<Publication_Product__c> publicationProducts = TestDataFactory.createPublicationProducts(publications, adTypes, products, publicationCodes);
        //List<Publication_Product__c> publicationProducts = TestDataFactory.createPublicationProducts(products, publications, publicationCodes, adTypes);
        List<Publication_Product__c> publicationProducts = TestDataFactory.createPublicationProducts(publications, 'Classified', products, publicationCodes);
        for(Publication_Product__c p: publicationProducts){
            //p.Division__c = bookings[0].CyberAd_Division__c;
            p.Show_In_Booking_Confirmation_Pub_Screen__c = true;
        }
        insert publicationProducts;


        id folderId = [Select Id from Folder where Name='CyberAd Proofs' limit 1].id;
        
        doc = new Document();
        doc.AuthorId = UserInfo.getUserId();
        doc.FolderId = folderId;
        doc.name = 'CyberAd Proofs';
        doc.DeveloperName = bookings[0].Source_System__c + '_' + bookings[0].CyberAd_Division__c + '_' + bookings[0].Name + '_1234567890';
        doc.body = Blob.valueOf('My image');
        insert doc; 
           
    }
    
    
    static testMethod void bookingQuoteConfirmationVfTest() 
    {
        
        setupData();
        Test.startTest();        

        ApexPages.StandardController ctr = new ApexPages.StandardController(cases[0]);
        BookingQuoteConfirmationVF_Ext controller = new BookingQuoteConfirmationVF_Ext(ctr);


        PageReference pageRef = Page.BookingQuoteConfirmationVF;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('refTabId','a-s-123');
        controller.resetFields();

        List<SelectOption> bookingOptions = controller.bookingOptions;
        //System.Assert(bookingOptions.size()>0);

        Boolean hasBookings = controller.hasBookings;
        System.Assert(hasBookings);

        controller.changeBooking();
        
        List<SelectOption> fromEmailAddressOptions = controller.fromEmailAddressOptions;


        controller.filterFromEmail =  'first';
        controller.doFilterFromEmailAddressOptions();
        fromEmailAddressOptions = controller.fromEmailAddressOptions;
        System.Assert(fromEmailAddressOptions.size()==2);


        controller.filterFromEmail =  'secondfirst';
        controller.doFilterFromEmailAddressOptions();
        fromEmailAddressOptions = controller.fromEmailAddressOptions;
        System.Assert(fromEmailAddressOptions.size()==1);
        
        // verify confirmation/quote message changes when changing checkbox
        // AdProof Required, dropdown list 'Quote/Confirmation?' and Booking
        
        String quoteConfirmationMessage = controller.booking.Quote_Confirmation_Message__c;
        controller.booking.Quote_Confirmation__c = 'Confirmation';
        

        controller.booking.AdProof_Required__c = true;
        controller.booking.Ad_Proof_Document__c = doc.id;
        controller.changeFieldValueOnPage();
        System.Assert(quoteConfirmationMessage != controller.booking.Quote_Confirmation_Message__c);
        quoteConfirmationMessage = controller.booking.Quote_Confirmation_Message__c;

        controller.booking.Quote_Confirmation__c = 'Quote';
        controller.changeFieldValueOnPage();
        System.Assert(quoteConfirmationMessage != controller.booking.Quote_Confirmation_Message__c);
        quoteConfirmationMessage = controller.booking.Quote_Confirmation_Message__c;

        List<BookingQuoteConfirmationVF_Ext.publicationWrapper> publicationWrappers = controller.publications;
        for(BookingQuoteConfirmationVF_Ext.publicationWrapper pw : publicationWrappers)
        {
            pw.isSelect = true;
        }

        controller.booking.Send_Email__c = true;
        controller.save();

        

        controller.cancel();

        // verify resend is visible after email being sent
        
        
        // verify choosing resend dropdown list option will uncheck adProof required, send email
        // and send fax checkboxes

        Test.stopTest();
        
    }
    
    // SFE-766 2015-11-28 darshan.gosar@bluewolfgroup.com
        // To cover more test scenarios in order to increase code coverage
    static testMethod void bookingQuoteConfirmationVFHelperMethodsTest()
    {
        
        setupData();
        Test.startTest();        
                
        List<Task> tempTask = new List<Task>();
        tempTask.addAll(TestDataFactory.createTasks(1,'Email - Outbound', bookings[0].Id ,false));
        tempTask.addAll(TestDataFactory.createTasks(1,'Fax - Outbound', bookings[0].Id,false));
        insert  tempTask;
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(cases[0]);
        BookingQuoteConfirmationVF_Ext controller = new BookingQuoteConfirmationVF_Ext(ctr);
        
        System.AssertEquals(controller.hasPreviouslySentFax, true, 'Previously Sent Fax Flag should not be set');
        System.AssertEquals(controller.hasPreviouslySentEmail, true, 'Previously Sent Email Flag should not be set');
        
        PageReference pageRef = Page.BookingQuoteConfirmationVF;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('refTabId','a-s-123');

        String quoteConfirmationMessage = controller.booking.Quote_Confirmation_Message__c;
        controller.booking.Quote_Confirmation__c = 'Confirmation';        

        controller.booking.AdProof_Required__c = true;
        controller.booking.Ad_Proof_Document__c = doc.id;
        controller.changeFieldValueOnPage();
        System.Assert(quoteConfirmationMessage != controller.booking.Quote_Confirmation_Message__c);
        quoteConfirmationMessage = controller.booking.Quote_Confirmation_Message__c;

        controller.booking.Quote_Confirmation__c = 'Quote';
        controller.booking.Resend_Pick__c = 'Resend Immediately';        
        controller.resetFields();
        
        controller.booking.Resend_Pick__c = 'Resend with Booking Change';
        controller.resetFields();

        controller.booking.Send_Email__c = true;
        controller.booking.Send_Channel__c = 'Fax';

        controller.onChnageSelectedMedia();
        controller.save();
        Test.stopTest();
        
    }    
    
    static testMethod void getFromEmailTest()
    {
        insert new SystemParameters__c(Name='Quote_Confirmation_From_Email', Value__c = 'test.test@test.com', External_Id__c = 'Quote_Confirmation_From_Email', Description__c = 'Test Email');
        setupData();
        Test.startTest();        

        ApexPages.StandardController ctr = new ApexPages.StandardController(cases[0]);
        BookingQuoteConfirmationVF_Ext controller = new BookingQuoteConfirmationVF_Ext(ctr);
        
        controller.getFromEmail();
        Test.stopTest();    
    }
}
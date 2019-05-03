//
//  Test Coverage
// 2015-11-26 darshan.gosar@bluewolfgroup.com 
// 2016-03-01 darshan.gosar@bluewolfgroup.com 
// 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
// This class provides test coverage for
//  - BookingManagement_Trigger_Helper.cls          90% / 86
//  - OpportunityScheduleManagement_Controller.cls  79%
//  - BookingLineItemManagement.trigger             85%  _  
//  - BookingLineItemManagement.trigger             86%
//
// 2018-03-21 LA Changes made: Added assets 
//  - Moved asserts outside test.startTest and test.stopTest
//  - BookingManagement_Trigger_Helper.cls           86%

@isTest
private class BookingManagement_Trigger_Helper_Test {
    
    static public Set<Id> bookingIds;
    static public List<Booking__c> bookings;
    static public List<Opportunity> opportunities;
    static public List<Account> accounts;
    static public List<Product2> products;
    static public List<Contact> contacts;
    static public User u;
    static public List<Pricebook2> pricebooks;
    static public List<PricebookEntry> pricebookEntries;
    static public void setupData(){    
        // 2015-11-24 SFE-766 louis.wang@bluewolf.com 
        //  - Fix Test User by creating new one, so it won't rely on one random existing user, and causes error.
        
        // SFE-766 2015-11-26 darshan.gosar@bluewolfgroup.com
        // To cover test scenarios without seeAllData condition
        u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        TestDataFactory.createFaxSystemParameters();
        
        List<Booking_Oppty_Status_Map__c> bookingOpptyStatusMap = new List<Booking_Oppty_Status_Map__c>();
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Reservation', OpptyStatus__c='Reservation'));
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Cancelled', OpptyStatus__c='Closed Lost', OpptyReason__c = 'Withdrawn'));
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Active', OpptyStatus__c='Closed Won', OpptyReason__c = 'Masthead Reputation'));
        insert bookingOpptyStatusMap;
        // create account
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
        // create contact
        contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
        // create 10 products
        products = TestDataFactory.createProducts(2);
        
        // create pricebooks
        pricebooks = TestDataFactory.createCustomPricebookData();
        pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        Id stdPricebookId = Test.getStandardPricebookId();
        
        
        // create opportunities
        opportunities = TestDataFactory.createOpportunities_withContact(2,stdPricebookId,accounts[0], contacts[0]);
        for (Opportunity o : opportunities)
        {
            o.OwnerId = u.Id;
            o.Competitor__c = 'Test'; // To bypass Opprtunity Validation Rule
        }
        insert opportunities;
        
    } 
    
    static public void setupData2() 
    {
        // create 2 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        List<Sales_Order__c> salesOrders1 = new List<Sales_Order__c>();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1.add(so);
        }
        insert salesOrders1;
        
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, salesOrders1[0].Id);
        insert olis;
        
        List<OpportunityLineItemSchedule> oliSchedules = TestDataFactory.createOpportunityLineItemSchedules(2, olis, Date.today());
        insert oliSchedules;
        
        // create case associated with the booking.
        List<Case> cases = TestDataFactory.createCases(1, opportunities[0], null);
        for  (Case c : cases)
        {
            c.Apex_Fax_Body__c = 'Test Value';
        }
        insert cases;
        
        Blob sampleBody = Blob.valueOf('Test body');
        Document sampleBookingDoc = new Document(Name='Test Doc', Type='text', ContentType='text');
        sampleBookingDoc.body = sampleBody;
        sampleBookingDoc.folderId = UserInfo.getUserId();
        sampleBookingDoc.AuthorId = UserInfo.getUserId();
        insert sampleBookingDoc;
        // create bookings
        bookings = new List<Booking__c>();
        
        Integer i;
        for(Sales_Order__c so : salesOrders1)
        {
            String randomNum = String.valueOf(math.random() * 1000);
            Booking__c booking = new Booking__c();
            booking.Sales_Order__c = so.Id;
            booking.Booking_Number__c = randomNum;
            booking.External_Id__c = randomNum;
            booking.Advertiser_Account__c = so.Advertiser_Account__c;
            booking.Sales_Order_Owner__c = u.Id;
            booking.Modified_By_Copy__c = u.Id;
            booking.Apex_Case_ID__c = cases[0].Id;
            booking.Quote_Confirmation_bcc__c = 'test.test@test.com';
            booking.Quote_Confirmation_cc__c = 'test.test@test.com';
            booking.AdProof_Required__c = true;
            booking.Ad_Proof_Document__c = sampleBookingDoc.Id; 
            
            booking.Quote_or_Confirmation_Flag_Send_Date__c = null;
            booking.Quote_Confirmation_waiting_msg_sent__c = null;           
            bookings.add(booking);
        }
        
        insert bookings;  
        // Create booking line items
        List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>();
        
        i = 0;
        for(Sales_Order__c so : salesOrders1)
        {
            for(Integer j = 0; j < 1; j++)
            {
                bookingLineItems.addAll(TestDataFactory.createBookingLineItems(2, bookings[i*2+j], null, products));
            }
            i++;
        }        
        insert bookingLineItems;          
    }
    
    static testMethod void updateOpportunityStageNameTestReservationWithCyberCell() {
        setupData();
        
        // create 2 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        List<Sales_Order__c> salesOrders1 = new List<Sales_Order__c>();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1.add(so);
        }
        insert salesOrders1;
        
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, salesOrders1[0].Id);
        insert olis;
        
        // create bookings
        bookings = new List<Booking__c>();
        
        Integer i;
        for(Sales_Order__c so : salesOrders1)
        {
            String randomNum = String.valueOf(math.random() * 1000);
            Booking__c booking = new Booking__c();
            booking.Sales_Order__c = so.Id;
            booking.Booking_Number__c = randomNum;
            booking.External_Id__c = randomNum;
            booking.Advertiser_Account__c = so.Advertiser_Account__c;
            booking.Sales_Order_Owner__c = u.Id;
            booking.Modified_By_Copy__c = u.Id;
            booking.Quote_Confirmation_bcc__c = 'test.test@test.com';
            booking.Quote_Confirmation_cc__c = 'test.test@test.com';
            booking.AdProof_Required__c = true;
            bookings.add(booking);
        }
        
        insert bookings;  
        
        Test.startTest();
        //setupData2();
        opportunities[0].StageName = 'Reservation';
        update opportunities;
        
        Map<Id, Booking__c> oldMap = new Map<Id, Booking__c>();
        Map<Id, Booking__c> newMap = new Map<Id, Booking__c>();
        
        for (Booking__c booking : bookings){
            oldMap.put(booking.Id, booking);
            Booking__c tempBooking = booking.clone(true);
            tempBooking.Status__c = 'Active';
            tempBooking.Source_System__c = 'Cyber$ell';
            newMap.put(tempBooking.Id, tempBooking);
        }
        BookingManagement_Trigger_Helper.updateOpportunityStageName(newMap,oldMap);
        Test.stopTest();
        
        List<Opportunity> extractedOpportunities = [Select Id, StageName, Reason_Won_Lost__c from Opportunity where Id = :opportunities[0].Id Limit 1];
        System.assertEquals('Closed Won', extractedOpportunities[0].StageName, 'Stage should get updated as its Reservation Opportunity');               
    }    
    static testMethod void bookingManagementTriggerHelper_updateSalesOrderOwnerAndAdTakerTest() {
        
        // Create specific test data as setupdata is giving SOQL101 error.
        //setupData();
        //setupData2();
         u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        
        
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
         contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        Sales_Order__c salesOrders1 = new Sales_Order__c();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1 = so;
        }
        insert salesOrders1;
        
        TestDataFactory.createFaxSystemParameters();
              
        Booking__c booking = TestDataFactory.createBooking(salesOrders1);
        Map<Id, Booking__c> validBookingIdMap = new Map<Id, Booking__c>();
        bookingIds = new Set<Id>();
        
        bookingIds.add(booking.Id);
        if(booking.Sales_Order__c!=null) 
            validBookingIdMap.put(booking.Sales_Order__c, booking);
        
        Test.startTest();
        // SFE-794 2016-03-01 darshan.gosar@bluewolfgroup.com 
        // Updated method definition to pass map of booking instead of set of id.         
        BookingManagement_Trigger_Helper.updateSalesOrderOwnerAndAdTaker(validBookingIdMap);
        Test.stopTest();
        Sales_Order__c s = [Select OwnerId, Ad_Taker__c From Sales_Order__c Where Id IN: validBookingIdMap.keySet() LIMIT 1];
        System.assertEquals(u.Id,s.OwnerId);
    }
    static testMethod void bookingManagementTriggerHelper_updateBookingSendDateFlagNonFutureTest() {
        // Create specific test data as setupdata is giving SOQL101 error.
        //setupData2();
             u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        
        
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
         contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        Sales_Order__c salesOrders1 = new Sales_Order__c();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1 = so;
        }
        insert salesOrders1;
        
        TestDataFactory.createFaxSystemParameters();
              
        Booking__c booking = TestDataFactory.createBooking(salesOrders1);
        Map<Id, Booking__c> validBookingIdMap = new Map<Id, Booking__c>();
        bookingIds = new Set<Id>();
        
        bookingIds.add(booking.Id);
        Test.startTest();
        // SFE-794 2016-03-01 darshan.gosar@bluewolfgroup.com 
        // Updated method definition to pass map of booking instead of set of id.   
        BookingManagement_Trigger_Helper.updateBookingSendDateFlagNonFuture(bookingIds);
        //
        Test.stopTest();
        Booking__c testBooking = [Select Id,Quote_or_Confirmation_Flag_Send_Date__c, 
                                         Quote_Confirmation_waiting_msg_sent__c,Apex_Adproof_Previously_Sent__c
                                         From Booking__c Where Id IN: bookingIds LIMIT 1];
        System.assert(testBooking.Quote_or_Confirmation_Flag_Send_Date__c!=null);
        System.assert(testBooking.Quote_Confirmation_waiting_msg_sent__c!=null);
    }
    static testMethod void bookingManagementTriggerHelper_updateBookingWaitingMessageTest() {
        // Create specific test data as setupdata is giving SOQL101 error.
        //setupData();
            u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        
        
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
         contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        Sales_Order__c salesOrders1 = new Sales_Order__c();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1 = so;
        }
        insert salesOrders1;
        
        TestDataFactory.createFaxSystemParameters();
              
        Booking__c booking = TestDataFactory.createBooking(salesOrders1);
        Map<Id, Booking__c> validBookingIdMap = new Map<Id, Booking__c>();
        bookingIds = new Set<Id>();
        
        bookingIds.add(booking.Id);
        Test.startTest();
        // SFE-794 2016-03-01 darshan.gosar@bluewolfgroup.com 
        // Updated method definition to pass map of booking instead of set of id.   
        BookingManagement_Trigger_Helper.updateBookingWaitingMessageSentFlag(bookingIds);
        Booking__c testBooking = [Select Id,Quote_or_Confirmation_Flag_Send_Date__c, 
                                         Quote_Confirmation_waiting_msg_sent__c,Apex_Adproof_Previously_Sent__c
                                         From Booking__c Where Id IN: bookingIds LIMIT 1];
        System.assert(testBooking.Quote_or_Confirmation_Flag_Send_Date__c!=null);
        System.assert(testBooking.Quote_Confirmation_waiting_msg_sent__c!=null);
        //
        Test.stopTest();
    }
    static testMethod void bookingManagementTriggerHelper_BookingQuoteConfirmationFaxTest() {
        // Create specific test data as setupdata is giving SOQL101 error.
        //setupData();
        u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
        contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
        Id stdPricebookId = Test.getStandardPricebookId();
        
        // create opportunities
        opportunities = TestDataFactory.createOpportunities_withContact(2,stdPricebookId,accounts[0], contacts[0]);
        for (Opportunity o : opportunities)
        {
            o.OwnerId = u.Id;
            o.Competitor__c = 'Test'; // To bypass Opprtunity Validation Rule
        }
        insert opportunities;
        
        TestDataFactory.createFaxSystemParameters();
        
        List<Case> cases = TestDataFactory.createCases(1, opportunities[0], null);
        for  (Case c : cases)
        {
            c.Apex_Fax_Body__c = 'Test Value';
        }
        insert cases;
        
        Blob sampleBody = Blob.valueOf('Test body');
        Document sampleBookingDoc = new Document(Name='Test Doc', Type='text', ContentType='text');
        sampleBookingDoc.body = sampleBody;
        sampleBookingDoc.folderId = UserInfo.getUserId();
        sampleBookingDoc.AuthorId = UserInfo.getUserId();
        insert sampleBookingDoc;

        Test.startTest();
        //setupData2();
        // SFE-794 2016-03-01 darshan.gosar@bluewolfgroup.com 
        // Updated method definition to pass map of booking instead of set of id. 
        BookingManagement_Trigger_Helper.BookingQuoteConfirmationFaxChunk(bookingIds);
        Test.stopTest();
    }
    
    static testMethod void bookingManagementTriggerHelper_subStringByCharacterLengthTest() {
        // Create specific test data as setupdata is giving SOQL101 error.
        //setupData();
        
         u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        
        
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
         contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        Sales_Order__c salesOrders1 = new Sales_Order__c();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1 = so;
        }
        insert salesOrders1;
        
         TestDataFactory.createFaxSystemParameters();
         
         Blob sampleBody = Blob.valueOf('Test body');
        Document sampleBookingDoc = new Document(Name='Test Doc', Type='text', ContentType='text');
        sampleBookingDoc.body = sampleBody;
        sampleBookingDoc.folderId = UserInfo.getUserId();
        sampleBookingDoc.AuthorId = UserInfo.getUserId();
        insert sampleBookingDoc;
              
        Booking__c booking = TestDataFactory.createBooking(salesOrders1);
        booking.CyberAd_Classification__c = 'test cyber ad classification text';
        update booking;
        Test.startTest();
        BookingManagement_Trigger_Helper.subStringByCharacterLength(booking.CyberAd_Classification__c,5);//Added for Backlog item 1127
        Test.stopTest();
        
        System.assertEquals('test cyber ad classification text',booking.CyberAd_Classification__c);
    }
    
    static testMethod void bookingManagementTriggerHelper_sendBookingQuoteConfirmationEmailTest() {
        // Create specific test data as setupdata is giving SOQL101 error.
        //setupData();
         u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        
        
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
         contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        Sales_Order__c salesOrders1 = new Sales_Order__c();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1 = so;
        }
        insert salesOrders1;
        
         TestDataFactory.createFaxSystemParameters();
              
        Booking__c booking = TestDataFactory.createBooking(salesOrders1);
        bookings = new List<Booking__c>();
        bookings.add(booking);
        update bookings;
        Integer count;
        Test.startTest();
        //setupData2();
        // SFE-794 2016-03-01 darshan.gosar@bluewolfgroup.com 
        // Updated method definition to pass map of booking instead of set of id.
         BookingManagement_Trigger_Helper.sendBookingQuoteConfirmationEmail(bookings);
         count = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(2,count);
    }
    
    static testMethod void bookingManagementTriggerHelper_sendBookingQuoteConfirmationFaxTest() { 
        // Create specific test data as setupdata is giving SOQL101 error.
        //setupData();
       u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        TestDataFactory.createFaxSystemParameters();
        
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
        // create contact
        contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
         Id stdPricebookId = Test.getStandardPricebookId();
        
        
        // create opportunities
        opportunities = TestDataFactory.createOpportunities_withContact(2,stdPricebookId,accounts[0], contacts[0]);
        for (Opportunity o : opportunities)
        {
            o.OwnerId = u.Id;
            o.Competitor__c = 'Test'; // To bypass Opprtunity Validation Rule
        }
        insert opportunities;
        
         List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        List<Sales_Order__c> salesOrders1 = new List<Sales_Order__c>();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1.add(so);
        }
        insert salesOrders1;
        
         List<Case> cases = TestDataFactory.createCases(1, opportunities[0], null);
        for  (Case c : cases)
        {
            c.Apex_Fax_Body__c = 'Test Value';
        }
        insert cases;
        
        Blob sampleBody = Blob.valueOf('Test body');
        Document sampleBookingDoc = new Document(Name='Test Doc', Type='text', ContentType='text');
        sampleBookingDoc.body = sampleBody;
        sampleBookingDoc.folderId = UserInfo.getUserId();
        sampleBookingDoc.AuthorId = UserInfo.getUserId();
        insert sampleBookingDoc;
        // create bookings
        bookings = new List<Booking__c>();
        
        Integer i;
        for(Sales_Order__c so : salesOrders1)
        {
            String randomNum = String.valueOf(math.random() * 1000);
            Booking__c booking = new Booking__c();
            booking.Sales_Order__c = so.Id;
            booking.Booking_Number__c = randomNum;
            booking.External_Id__c = randomNum;
            booking.Advertiser_Account__c = so.Advertiser_Account__c;
            booking.Sales_Order_Owner__c = u.Id;
            booking.Modified_By_Copy__c = u.Id;
            booking.Apex_Case_ID__c = cases[0].Id;
            booking.Quote_Confirmation_bcc__c = 'test.test@test.com';
            booking.Quote_Confirmation_cc__c = 'test.test@test.com';
            booking.AdProof_Required__c = true;
            booking.Ad_Proof_Document__c = sampleBookingDoc.Id;            
            bookings.add(booking);
        }
        
        insert bookings;  
        Test.startTest();
        //setupData2();
        // SFE-794 2016-03-01 darshan.gosar@bluewolfgroup.com 
        // Updated method definition to pass map of booking instead of set of id.
        BookingManagement_Trigger_Helper.sendBookingQuoteConfirmationFax(bookings);
        Test.stopTest();
    }
    
    static testMethod void updateOpportunityStageNameTestClosedWon() {
        // Create specific test data as setupdata is giving SOQL101 error.
        //setupData();
        
         u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        TestDataFactory.createFaxSystemParameters();
        
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
        // create contact
        contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(2);
        
        // create pricebooks
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        
         Id stdPricebookId = Test.getStandardPricebookId();
        
        
        // create opportunities
        opportunities = TestDataFactory.createOpportunities_withContact(2,stdPricebookId,accounts[0], contacts[0]);
        for (Opportunity o : opportunities)
        {
            o.OwnerId = u.Id;
            o.Competitor__c = 'Test'; // To bypass Opprtunity Validation Rule
        }
        insert opportunities;
        
         List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        List<Sales_Order__c> salesOrders1 = new List<Sales_Order__c>();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1.add(so);
        }
        insert salesOrders1;
        
        
        // create bookings
        bookings = new List<Booking__c>();
        
        Integer i;
        for(Sales_Order__c so : salesOrders1)
        {
            String randomNum = String.valueOf(math.random() * 1000);
            Booking__c booking = new Booking__c();
            booking.Sales_Order__c = so.Id;
            booking.Booking_Number__c = randomNum;
            booking.External_Id__c = randomNum;
            booking.Advertiser_Account__c = so.Advertiser_Account__c;
            booking.Sales_Order_Owner__c = u.Id;
            booking.Modified_By_Copy__c = u.Id;
            //booking.Apex_Case_ID__c = cases[0].Id;
            booking.Quote_Confirmation_bcc__c = 'test.test@test.com';
            booking.Quote_Confirmation_cc__c = 'test.test@test.com';
            booking.AdProof_Required__c = true;
            //booking.Ad_Proof_Document__c = sampleBookingDoc.Id;            
            bookings.add(booking);
        }
        
        insert bookings;
        
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, salesOrders1[0].Id);
        insert olis;
        
        opportunities[0].StageName = 'Closed Won';
        update opportunities;
        
        List<Booking_Oppty_Status_Map__c> bookingOpptyStatusMap = new List<Booking_Oppty_Status_Map__c>();
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Reservation', OpptyStatus__c='Reservation'));
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Cancelled', OpptyStatus__c='Closed Lost', OpptyReason__c = 'Withdrawn'));
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Active', OpptyStatus__c='Closed Won', OpptyReason__c = 'Masthead Reputation'));
        insert bookingOpptyStatusMap;
        
        Map<Id, Booking__c> oldMap = new Map<Id, Booking__c>();
        Map<Id, Booking__c> newMap = new Map<Id, Booking__c>();
        
        for (Booking__c booking : bookings){
            oldMap.put(booking.Id, booking);
            Booking__c tempBooking = booking.clone(true);
            tempBooking.Status__c = 'Reservation';
            tempBooking.Source_System__c = 'Cyber$ell';
            newMap.put(tempBooking.Id, tempBooking);
        }
        
        Test.startTest();
         // setupData2();
        
        BookingManagement_Trigger_Helper.updateOpportunityStageName(newMap,oldMap);
        Test.stopTest();
        
        List<Opportunity> extractedOpportunities = [Select Id, StageName, Reason_Won_Lost__c from Opportunity where Id = :opportunities[0].Id Limit 1];
        System.assertEquals('Closed Won', extractedOpportunities[0].StageName, 'Stage should not be changed as its Closed Won Opportunity');               
    }
    
    static testMethod void updateOpportunityStageNameTestClosedLost() {
        // Create specific test data as setupdata is giving SOQL101 error.
        //setupData();
        u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        TestDataFactory.createFaxSystemParameters();
        
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
        // create contact
        contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
         Id stdPricebookId = Test.getStandardPricebookId();
        
        
        // create opportunities
        opportunities = TestDataFactory.createOpportunities_withContact(2,stdPricebookId,accounts[0], contacts[0]);
        for (Opportunity o : opportunities)
        {
            o.OwnerId = u.Id;
            o.Competitor__c = 'Test'; // To bypass Opprtunity Validation Rule
        }
        insert opportunities;
        
         List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        List<Sales_Order__c> salesOrders1 = new List<Sales_Order__c>();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1.add(so);
        }
        insert salesOrders1;
        
        
        // create bookings
        bookings = new List<Booking__c>();
        
        Integer i;
        for(Sales_Order__c so : salesOrders1)
        {
            String randomNum = String.valueOf(math.random() * 1000);
            Booking__c booking = new Booking__c();
            booking.Sales_Order__c = so.Id;
            booking.Booking_Number__c = randomNum;
            booking.External_Id__c = randomNum;
            booking.Advertiser_Account__c = so.Advertiser_Account__c;
            booking.Sales_Order_Owner__c = u.Id;
            booking.Modified_By_Copy__c = u.Id;
            //booking.Apex_Case_ID__c = cases[0].Id;
            booking.Quote_Confirmation_bcc__c = 'test.test@test.com';
            booking.Quote_Confirmation_cc__c = 'test.test@test.com';
            booking.AdProof_Required__c = true;
            //booking.Ad_Proof_Document__c = sampleBookingDoc.Id;            
            bookings.add(booking);
        }
        
        insert bookings;
        opportunities[0].StageName = 'Closed Lost';
        update opportunities;
        
        List<Booking_Oppty_Status_Map__c> bookingOpptyStatusMap = new List<Booking_Oppty_Status_Map__c>();
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Reservation', OpptyStatus__c='Reservation'));
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Cancelled', OpptyStatus__c='Closed Lost', OpptyReason__c = 'Withdrawn'));
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Active', OpptyStatus__c='Closed Won', OpptyReason__c = 'Masthead Reputation'));
        insert bookingOpptyStatusMap;
        
        Map<Id, Booking__c> oldMap = new Map<Id, Booking__c>();
        Map<Id, Booking__c> newMap = new Map<Id, Booking__c>();
        
        for (Booking__c booking : bookings){
            oldMap.put(booking.Id, booking);
            Booking__c tempBooking = booking.clone(true);
            tempBooking.Status__c = 'Reservation';
            tempBooking.Source_System__c = 'Cyber$ell';
            newMap.put(tempBooking.Id, tempBooking);
        }
        
        
        Test.startTest();
        //setupData2();
        BookingManagement_Trigger_Helper.updateOpportunityStageName(newMap,oldMap);
        Test.stopTest();
        
        List<Opportunity> extractedOpportunities = [Select Id, StageName, Reason_Won_Lost__c from Opportunity where Id = :opportunities[0].Id Limit 1];
        System.assertEquals('Closed Lost', extractedOpportunities[0].StageName, 'Stage should not be changed as its Closed Lost Opportunity');               
    }        
    
    static testMethod void updateOpportunityStageNameTestReservationWithoutCyberCell() {
        // Create specific test data as setupdata is giving SOQL101 error.
        //setupData();
        u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        TestDataFactory.createFaxSystemParameters();
        
        accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
        // create contact
        contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
         Id stdPricebookId = Test.getStandardPricebookId();
        
        
        // create opportunities
        opportunities = TestDataFactory.createOpportunities_withContact(2,stdPricebookId,accounts[0], contacts[0]);
        for (Opportunity o : opportunities)
        {
            o.OwnerId = u.Id;
            o.Competitor__c = 'Test'; // To bypass Opprtunity Validation Rule
        }
        insert opportunities;
        
         List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        List<Sales_Order__c> salesOrders1 = new List<Sales_Order__c>();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1.add(so);
        }
        insert salesOrders1;
        
        
        // create bookings
        bookings = new List<Booking__c>();
        
        Integer i;
        for(Sales_Order__c so : salesOrders1)
        {
            String randomNum = String.valueOf(math.random() * 1000);
            Booking__c booking = new Booking__c();
            booking.Sales_Order__c = so.Id;
            booking.Booking_Number__c = randomNum;
            booking.External_Id__c = randomNum;
            booking.Advertiser_Account__c = so.Advertiser_Account__c;
            booking.Sales_Order_Owner__c = u.Id;
            booking.Modified_By_Copy__c = u.Id;
            //booking.Apex_Case_ID__c = cases[0].Id;
            booking.Quote_Confirmation_bcc__c = 'test.test@test.com';
            booking.Quote_Confirmation_cc__c = 'test.test@test.com';
            booking.AdProof_Required__c = true;
            //booking.Ad_Proof_Document__c = sampleBookingDoc.Id;            
            bookings.add(booking);
        }
        
        insert bookings;
        
        opportunities[0].StageName = 'Reservation';
        update opportunities;
        
        List<Booking_Oppty_Status_Map__c> bookingOpptyStatusMap = new List<Booking_Oppty_Status_Map__c>();
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Reservation', OpptyStatus__c='Reservation'));
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Cancelled', OpptyStatus__c='Closed Lost', OpptyReason__c = 'Withdrawn'));
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Active', OpptyStatus__c='Closed Won', OpptyReason__c = 'Masthead Reputation'));
        insert bookingOpptyStatusMap;
        
        Map<Id, Booking__c> oldMap = new Map<Id, Booking__c>();
        Map<Id, Booking__c> newMap = new Map<Id, Booking__c>();
        
        for (Booking__c booking : bookings){
            oldMap.put(booking.Id, booking);
            Booking__c tempBooking = booking.clone(true);
            tempBooking.Status__c = 'Active';
            newMap.put(tempBooking.Id, tempBooking);
        }
        
        Test.startTest();
        //setupData2();
        BookingManagement_Trigger_Helper.updateOpportunityStageName(newMap,oldMap);
        Test.stopTest();
        
        List<Opportunity> extractedOpportunities = [Select Id, StageName, Reason_Won_Lost__c from Opportunity where Id = :opportunities[0].Id Limit 1];
        System.assertEquals('Reservation',extractedOpportunities[0].StageName, 'Stage should not changed since its non Cyber$ell booking update');               
    }    
    
    static testMethod void getUserIdMapTest() {
        
        User u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);  
        u.Network_Username__c = 'Network User 1';     
        User salesRepuser = TestDataFactory.createUser('News Integration', 'IntegratorLast', 'IntegratorFirst', null, false, false);
        salesRepuser.UserName = 'IntegratorLast@test.com';
        salesRepuser.CommunityNickname = 'IntegratorLast';
        salesRepuser.Network_Username__c = 'Network User 2';
        List<User> userList = new List<User>();
        userList.add(u);        
        userList.add(salesRepuser);
        
        insert userList;
        
        Set<String> networkUsernames = new Set<String>{'Network User 1', 'Network User 2'};
            
        Test.startTest();
        //Map<String, Id> testMap = BookingManagement_Trigger_Helper.getUserIdMap(networkUsernames);
		Map<String, user> testMap = BookingManagement_Trigger_Helper.getUserIdMap(networkUsernames);
        Test.stopTest();
        
        System.assertEquals(testMap.size(), networkUsernames.size(), 'User Map not set correctly');
        //System.assertEquals(testMap.get('NETWORK USER 1'), userList[0].Id, 'User Map not set correctly');
        //System.assertEquals(testMap.get('NETWORK USER 2'), userList[1].Id, 'User Map not set correctly');
		
    }
}
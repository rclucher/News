/**
 * Author: Bohao Chen
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes and triggers.
 * test requirement R-0804 / R-0573
 * 29/08/2013  Bohao Chen  Created
 // 2015-11-26 louis.wang@bluewolf.com
    //    This class provides test coverage for 
    //    - BookingLineItemManagement.trigger          88%
    //    - OpportunityLineItemManagement.trigger      82%
    //    - OpportunityScheduleManagement_Controller   94% 
    //    - ActionTask.trigger      89%
// 2015-11-26 darshan.gosar@bluewolfgroup.com 
    // This class provides test coverage for
    //    - BookingLineItemManagement.trigger          86%
    //    - OpportunityLineItemManagement.trigger      82%
    //    - Opportunity_Helper                         84%
    //    - OpportunityScheduleManagement_Controller   94%   
 */
@isTest
private class BookingLineItemManagement_Trigger_Test 
{
    @isTest
    static void createOscaBookingTest() 
    {        
        // SFE-766 2015-11-26 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition hence created dummy products & pricebook enteries       
        TestDataFactory.createFaxSystemParameters();
            
        // create products
        List<Pricebook2> pricebooks  = TestDataFactory.createCustomPricebookData();
        List<Product2> products = TestDataFactory.createProducts(4);        
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
        List<Product2> dummyProducts = TestDataFactory.createProducts(1);
        Product2 prod = dummyProducts[0];
        prod.Name = 'Dummy';
        update prod;
        TestDataFactory.createPricebookEntryData(pricebooks[0], dummyProducts);
                
        system.debug(loggingLevel.Error, '===query check 1 ===' + Limits.getQueries());
        
        // set up accounts
        List<Account> allAccounts = new List<Account>(); 
        
        List<Account> advertiserAccounts = TestDataFactory.createAccounts(2, false);
        List<Account> payerAccounts = TestDataFactory.createAccounts(2, false);
        List<Account> placerAccounts = TestDataFactory.createAccounts(1, false);
                
        allAccounts.addAll(advertiserAccounts);
        allAccounts.addAll(payerAccounts);
        allAccounts.addAll(placerAccounts);
        insert allAccounts;
        
        system.debug(loggingLevel.Error, '===query check 2 ===' + Limits.getQueries());
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, placerAccounts[0]);
        insert contacts;

        system.debug(loggingLevel.Error, '===query check 3 ===' + Limits.getQueries());
        
        // create sales order with booking system marked as 'OSCA'
        List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();
        
        for(Integer i = 0; i < 2; i++)
        {
           salesOrders.addAll(TestDataFactory.createSalesOrders(1, payerAccounts[i], advertiserAccounts[i], placerAccounts[0], contacts[0], 'OSCA'));
        }
        
        insert salesOrders;

        //create testing emma records
        List<EMMA_Readership_and_Circulation_Data__c> emmaRecords =  TestDataFactory.createEmmaRecords(10);
        insert emmaRecords;

        system.debug(loggingLevel.Error, '===query check 4 ===' + Limits.getQueries());
        /*
        // verify a 'dummy' opportunity line item has been created for each sales order as opportunity line item place holder
        List<OpportunityLineItem> opportItems = [Select o.Sales_Order__c, o.PricebookEntry.Name, 
                                               (Select Revenue, ScheduleDate From OpportunityLineItemSchedules) 
                                                From OpportunityLineItem o 
                                                Where o.Sales_Order__c IN: salesOrders];
        
        Integer k = 0;
        // verify that opportunity line item schedules have been created
        for(OpportunityLineItem oppotLineItem : opportItems)
        {
            system.debug(loggingLevel.Error, '===oppotLineItem.OpportunityLineItemSchedules ' + k + ' ==== ' + oppotLineItem.OpportunityLineItemSchedules);
            k++;
        }
        
        system.assertEquals(2, opportItems.size());
        
        for(OpportunityLineItem oppt : opportItems)
        {
            system.assertEquals('Dummy', oppt.PricebookEntry.Name);
        }
        */
        // create 'OSCA' booking for each 'OSCA' sales order
        List<Booking__c> bookings = new List<Booking__c>();
        
        for(Sales_Order__c so : salesOrders)
        {
            bookings.addAll(TestDataFactory.createBookings(2, so));
        }
        insert bookings;
        
        system.debug(loggingLevel.Error, '===query check 5 ===' + Limits.getQueries());

        system.debug(loggingLevel.Error, '===query check 6 ===' + Limits.getQueries());
        
        //system.debug(loggingLevel.Error, '===bookings=== ' + bookings);
        Test.startTest();
        // create 'OSCA' booking line item for each 'OSCA' booking
        List<Booking_Line_Item__c> bookinglines = new List<Booking_Line_Item__c>();
        
        Integer i = 0;
        for(Booking__c booking : bookings)
        {
            if(products.size() > 0)
            {
                bookinglines.addAll(TestDataFactory.createBookingLineItems(11, booking, products[math.mod(i, products.size())], null));
            }
            i++;
        }
        
        system.debug(loggingLevel.Error, '===size of booking line items=== ' + bookinglines.size());
        
        insert bookinglines;
        update bookinglines;

        
        system.debug(loggingLevel.Error, '===query check 7 ===' + Limits.getQueries());
        
        // verify that opportunity line items have been created
        /*opportItems.clear();
        opportItems = [Select o.Sales_Order__c, o.PricebookEntry.Name, o.PricebookEntryId,
                        (Select Revenue, ScheduleDate From OpportunityLineItemSchedules) 
                        From OpportunityLineItem o 
                        Where o.Sales_Order__c IN: salesOrders];
        
        system.assertEquals(20, opportItems.size());
        
        Integer j = 0;
        // verify that opportunity line item schedules have been created
        for(OpportunityLineItem oppotLineItem : opportItems)
        {
            system.assertEquals(1, oppotLineItem.OpportunityLineItemSchedules.size());
            
            for(OpportunityLineItemSchedule opptLiSch : oppotLineItem.OpportunityLineItemSchedules)
            {
                system.assertEquals(11000, opptLiSch.Revenue);
            }
            
            j++;
        }*/
        
        Test.stopTest();
        
    }
    
    // Test requirement R-0822
    static testMethod void populateProductOnBookingLineItemTest() 
    {
        // SFE-766 2015-11-26 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition hence created dummy products & pricebook enteries       
        TestDataFactory.createFaxSystemParameters();        
   
        // create products
        List<Product2> products = TestDataFactory.createProducts(10);
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        
        // testing publications
        List<String> publications = TestDataFactory.createStringList(10, 'pub');
        
        system.debug('===publications=== ' + publications);
        
        // testing publication codes
        List<String> publicationCodes = TestDataFactory.createStringList(10, 'pubC');
        
        system.debug(loggingLevel.Error, '===publicationCodes=== ' + publicationCodes);
        
        // create publication product (product mappings)
        List<Publication_Product__c> publicationProducts = TestDataFactory.createPublicationProducts(publications, 'Classified', products, publicationCodes);
        
        system.debug(loggingLevel.Error, '===publicationProducts=== ' + publicationProducts);
        
        insert publicationProducts;
        
        // create testing accounts
        List<Account> allAccounts = TestDataFactory.createAccounts(3, false);
        insert allAccounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, allAccounts[2]);
        insert contacts;
        
        // create testing sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, allAccounts[0], allAccounts[1], allAccounts[2], contacts[0], null);
        insert salesOrders;

        //create testing emma records
        List<EMMA_Readership_and_Circulation_Data__c> emmaRecords =  TestDataFactory.createEmmaRecords(10);
        insert emmaRecords;
         
        // create testing booking
        Booking__c booking = TestDataFactory.createBooking(salesOrders[0]);
        
        Test.startTest();
        
        // create testing booking line item
        List<Booking_Line_Item__c> bookingLineItems = TestDataFactory.createBookingLineItems(10, booking);
        
        system.debug(loggingLevel.Error, '===bookingLineItems== ' + bookingLineItems);
        
        insert bookingLineItems;

        // to verify that value on product lookup has been populated
        Integer i = 0;
        for(Booking_Line_Item__c bli : [Select Product__c, Run_Day_of_Week__c From Booking_Line_Item__c Where Id IN: bookingLineItems])
        {
            system.assertEquals(products[i].Id, bli.Product__c);
            i++;
        }
        
        update bookingLineItems;
        delete bookingLineItems;

        Test.stopTest();
         
    }

}
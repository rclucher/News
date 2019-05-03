/*
 * History:
 * 2015-11-27   Darshan G   Updated
 // 2015-11-27 darshan.gosar@bluewolfgroup.com 
    // This class provides test coverage for
    //  - Booking_Refresh_YTD_Revenue_Batch 97%
    //  - AccountUpdateTcsTas_Batch         80%     
 */
@isTest
private class Booking_Refresh_YTD_Revenue_Batch_Test {
    
    @isTest static void bookingRefreshYTDRevenueBatchTest() {

        Batch_Run_Start_Datetime__c lastRunDateTimeTgs = new Batch_Run_Start_Datetime__c();
        lastRunDateTimeTgs.Name = 'Account TGS Update Batch';
        lastRunDateTimeTgs.Run_Start_Datetime__c = datetime.now().addDays(-1);        
        insert lastRunDateTimeTgs;
                
        // set up custom setting for last success run date time
        Batch_Run_Start_Datetime__c lastRunDateTime = new Batch_Run_Start_Datetime__c();
        lastRunDateTime.Name = 'Booking_Refresh_YTD_Revenue_Batch';
        lastRunDateTime.Run_Start_Datetime__c = datetime.now().addDays(-1);
        insert lastRunDateTime;

        // SFE-766 2015-11-27 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition & increase code coverage
        User u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        u.Bypass_Triggers__c = 'BookingLineItemManagement';
        insert u;

        TestDataFactory.createFaxSystemParameters();
        
        // Create booking line items
        List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>();
                
        /* End of Darshan Gosar code */
        system.runAs(u){
            // create account
            List<Account> accounts = TestDataFactory.createAccounts(1, false);
            insert accounts;
            
            // create contact
            List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
            insert contacts;
            
            // create 10 products
            List<Product2> products = TestDataFactory.createProducts(2);
            
            // create pricebooks
            List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
            List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
            
            // create 10 sales orders
            List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(2, accounts[0], accounts[0], accounts[0], contacts[0], null);
            insert salesOrders;
            
            // create bookings
            List<Booking__c> bookings = new List<Booking__c>();
    
            Integer i;
            for(Sales_Order__c so : salesOrders)
            {
                for(i = 0; i < 2; i++)
                {
                    String randomNum = String.valueOf(math.random() * 1000);
                    Booking__c booking = new Booking__c();
                    // added by Tim Fabros 02 / 09 / 2014 - SFE-581
                    booking.Name = '2132' + i;
                    booking.Sales_Order__c = so.Id;
                    booking.Booking_Number__c = randomNum;
                    booking.External_Id__c = randomNum;
                    booking.Advertiser_Account__c = so.Advertiser_Account__c;
                    bookings.add(booking);
                }
            }
    
            insert bookings;
    
            i = 0;
            for(Sales_Order__c so : salesOrders)
            {
                for(Integer j = 0; j < 2; j++)
                {
                    bookingLineItems.addAll(TestDataFactory.createBookingLineItems(2, bookings[i*2+j], null, products));
                }
                i++;
            }

            bookingLineItems[0].Gross_Price_YTD__c = 50;
            bookingLineItems[0].Gross_Price__c = null;
    
            bookingLineItems[1].Gross_Price_YTD__c = null;
            bookingLineItems[1].Gross_Price__c = 50;
                    
            bookingLineItems[2].Gross_Price_YTD__c = null;
            bookingLineItems[2].Gross_Price__c = null;
                    
            bookingLineItems[3].Gross_Price_YTD__c = 50;
            bookingLineItems[3].Run_Date__c = date.today().addyears(-2);
                                      
            insert bookingLineItems;
        }
        
        Test.startTest();

        // exceute the batch class
        ID batchprocessid = Database.executeBatch(new Booking_Refresh_YTD_Revenue_Batch(bookingLineItems));

        Test.stopTest();


        // validate results
        // method should have created opportunity, opportunity line item and line item schedules
        // opportunity line item should have sales order

        // Implement test code
    }    
}
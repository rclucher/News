/*---------------------------------------------------------
* Author:  Darshan Gosar
* Description: This class contains unit tests for validating the behavior of AccountCalculateTcsTas_Batch
* Company: Salesforce.com
* History:
* 2015-11-24   Darshan Gosar       Created
// SFE-766 2015-11-24 darshan.gosar@bluewolfgroup.com
    // This class provides test coverage for 
    //  - AccountCalculateTcsTas_Batch             93% 
---------------------------------------------------------*/
@isTest
private class AccountCalculateTcsTas_Batch_Test 
{

    static List<User> users;
    static List<Account> allAccounts;
    static List<Account> advertiserAccounts;
    static List<Account> payerAccounts;
    static List<Account> placerAccounts;
    static List<Sales_Order__c> allSalesOrders;
    
    static public void setupTestData(){
    
        // create users
        users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
        
        // set default sales rep
        // treat last user in the list as default sales rep
        SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert salesRep;        
        // set up accounts
        advertiserAccounts = TestDataFactory.createAccounts(10, false);
        payerAccounts = TestDataFactory.createAccounts(10, false);        
        placerAccounts = TestDataFactory.createAccounts(1, false);        
        
        allAccounts = new List<Account>(); 
        allAccounts.addAll(advertiserAccounts);
        allAccounts.addAll(payerAccounts);
        allAccounts.addAll(placerAccounts);
        insert allAccounts;
        
        List<Exception_Record__c> createExceptionRecords = TestDataFactory.createExceptionRecords(1, 'TCSTAS', allAccounts[0].Id);
        insert createExceptionRecords;
        // set up custom setting for last success run date time
        List<Batch_Run_Start_Datetime__c> lastRunDatetimeList = new List<Batch_Run_Start_Datetime__c>();
                
        Batch_Run_Start_Datetime__c lastRunDateTimeTcsTas = new Batch_Run_Start_Datetime__c();
        lastRunDateTimeTcsTas.Name = 'Account TCSTAS Update Batch';
        lastRunDateTimeTcsTas.Run_Start_Datetime__c = datetime.now().addDays(-1);
        lastRunDatetimeList.add(lastRunDateTimeTcsTas);
        
        Batch_Run_Start_Datetime__c lastRunDateTimeTgs = new Batch_Run_Start_Datetime__c();
        lastRunDateTimeTgs.Name = 'Account TGS Update Batch';
        lastRunDateTimeTgs.Run_Start_Datetime__c = datetime.now().addDays(-1);
        lastRunDatetimeList.add(lastRunDateTimeTgs);        
        
        insert lastRunDatetimeList;
        // set up sales orders and link sales order with accounts
        List<Sales_Order__c> salesOrderWithSamePayerAdvertiser = new List<Sales_Order__c>();
        List<Sales_Order__c> salesOrderWithDifferentPayerAdvertiser = new List<Sales_Order__c>();
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, placerAccounts[0]);
        insert contacts;
        
        Integer i = 0;
        for(Account acct : advertiserAccounts)
        {
            salesOrderWithSamePayerAdvertiser.addAll(TestDataFactory.createSalesOrders(1, acct, acct, placerAccounts[0], contacts[0], null));
            salesOrderWithDifferentPayerAdvertiser.addAll(TestDataFactory.createSalesOrders(1, payerAccounts[i], acct, placerAccounts[0], contacts[0], null));
            i++;
        }
        
        allSalesOrders = new List<Sales_Order__c>();
        allSalesOrders.addAll(salesOrderWithSamePayerAdvertiser);
        allSalesOrders.addAll(salesOrderWithDifferentPayerAdvertiser);

        insert allSalesOrders;

        // bookings
        List<Booking__c> bookings = TestDataFactory.createBookings(20, allSalesOrders);
        insert bookings;
        
        // booking line items
        List<Booking_Line_Item__c> bookingLines = new List<Booking_Line_Item__c>(); 
        for(i = 0; i < bookings.size(); i++)
        {
            bookingLines.addAll(TestDataFactory.createBookingLineItems(20, bookings[i]));
        }
        insert bookingLines;
        /*
        for(Booking_Line_Item__c bookingLine : [Select Gross_Price_YTD__c 
                                                From Booking_Line_Item__c 
                                                Where Id IN: bookingLines])
        {
            system.assertEquals(1000, bookingLine.Gross_Price_YTD__c);
        }
        
        for(Booking__c booking : [Select Line_Item_Gross_Price_YTD__c
                                  From Booking__c 
                                  Where Id IN: bookings])
        {
            system.assertEquals(20000, booking.Line_Item_Gross_Price_YTD__c);
        }
        
        for(Sales_Order__c so : [Select Total_Gross_Price_Ytd__c 
                                 From Sales_Order__c 
                                 Where Id IN: allSalesOrders])
        {
            system.assertEquals(20000, so.Total_Gross_Price_Ytd__c);
        }
        */
        // manually reset total spendings on accounts
        for(Account a : allAccounts)
        {
            a.Total_Agency_Spend__c = 0;
            a.Total_Customer_Spend__c = 0;
            a.Total_Group_Spend__c = 0;
        }
        
        Update allAccounts;    
    
    }
    

    static testMethod void AccountCalculateTcsTasBatchMultipleAccountIdTest() 
    {
        setupTestData();        
        Test.startTest();
        AccountCalculateTcsTas_Batch testJob = new AccountCalculateTcsTas_Batch();
        Database.executebatch(testJob);
        Test.stopTest();                
    }
    
    static testMethod void AccountCalculateTcsTasBatchSingleAccountIdTest() 
    {
        setupTestData();        
        Test.startTest();
        AccountCalculateTcsTas_Batch testJob = new AccountCalculateTcsTas_Batch(allAccounts[0].Id, null);
        Database.executebatch(testJob);
        Test.stopTest();        
    }  
    
    static testMethod void AccountCalculateTcsTasBatchSingleAccountIdWithQueryTest() 
    {
        setupTestData();        
        Test.startTest();
        String queryString = 'Select s.Total_Gross_Price_Ytd__c, s.Payer_Account__c, s.Advertiser_Account__c ' 
                + 'From Sales_Order__c s '
                + 'Where (s.Payer_Account__c = \'' + allAccounts[0].Id + '\''
                + 'Or s.Advertiser_Account__c =\'' + allAccounts[0].Id + '\') ';
        AccountCalculateTcsTas_Batch testJob = new AccountCalculateTcsTas_Batch(allAccounts[0].Id, queryString);
        Database.executebatch(testJob);
        Test.stopTest();                
    }            
}
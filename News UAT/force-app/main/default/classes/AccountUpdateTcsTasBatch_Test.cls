/*---------------------------------------------------------
* Author:  Bohao Chen
* Description: This class contains unit tests for validating the behavior of AccountUpdateTcsTas_Batch
* Company: Salesforce.com
* Date: 23/07/2013
* History:
* 23/07/2013   Bohao Chen       Created
* 09/04/2018 - LA - Refactored class. Create TestMethod. 
                AccountUpdateTcsTasBatch - 82%
---------------------------------------------------------*/
@isTest
private class AccountUpdateTcsTasBatch_Test 
{
    static List<Account> advertiserAccounts ;
    static List<Account> payerAccounts ;
    static void createTestData(){
        
        // create users
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
        
        // set default sales rep
        // treat last user in the list as default sales rep
        SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert salesRep;
        
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
        
        // set up accounts
        advertiserAccounts = TestDataFactory.createAccounts(5, false);
        payerAccounts = TestDataFactory.createAccounts(5, false);
        
        List<Account> placerAccounts = TestDataFactory.createAccounts(1, false);
        
        
        List<Account> allAccounts = new List<Account>(); 
        allAccounts.addAll(advertiserAccounts);
        allAccounts.addAll(payerAccounts);
        allAccounts.addAll(placerAccounts);
        insert allAccounts;
        
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
        
        List<Sales_Order__c> allSalesOrders = new List<Sales_Order__c>();
        allSalesOrders.addAll(salesOrderWithSamePayerAdvertiser);
        allSalesOrders.addAll(salesOrderWithDifferentPayerAdvertiser);
        
        system.debug('===size of allSalesOrders=== ' + allSalesOrders.size());
        insert allSalesOrders;
        /*insert salesOrderWithSamePayerAdvertiser;
insert salesOrderWithDifferentPayerAdvertiser;*/
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
    
    static testMethod void accountTcsTasTest() 
    {
        
        createTestData(); 
        // run batch to populate TCS and TAS on accounts
        String query = 'Select s.Total_Gross_Price_Ytd__c, s.Payer_Account__c, s.Payer_Account__r.RecordType.Name, '
            + 's.Advertiser_Account__c, s.Advertiser_Account__r.RecordType.Name, s.Total_Gross_Price_YTD_Last_Modified__c ' 
            + 'From Sales_Order__c s';
        AccountUpdateTcsTas_Batch accountUpdateTcsTas = new AccountUpdateTcsTas_Batch(null, query);
        
        Test.startTest();
        
        /*AccountSpendingReset_Batch AccountSpendingResetBatch = new AccountSpendingReset_Batch();
ID batchProcessId = Database.executeBatch(AccountSpendingResetBatch);
System.debug(logginglevel.error, 'Returned batch process ID: ' + batchProcessId);*/
        
        
        ID batchProcessId = Database.executeBatch(accountUpdateTcsTas);
        System.debug(logginglevel.error, 'Returned batch process ID: ' + batchProcessId);
        Test.stopTest();   
        
        for(Account a : [Select Total_Customer_Spend__c, Total_Agency_Spend__c 
                         From Account 
                         Where Id IN: advertiserAccounts])
        {
            system.assertEquals(40000, a.Total_Customer_Spend__c);
        }
        
        for(Account a : [Select Total_Customer_Spend__c, Total_Agency_Spend__c 
                         From Account 
                         Where Id IN: payerAccounts])
        {
            system.assertEquals(20000, a.Total_Agency_Spend__c);
        } 
    }
}
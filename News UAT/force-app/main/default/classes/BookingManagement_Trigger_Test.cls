/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * 28/08/2013  Bohao Chen  Created
 * 16/01/2014  Bohao Chen  Created
 * 2016-01-14  Atul Gupta  Updated 
 // 2016-01-14 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - BookingManagement Trigger        91%
    //  - BookingLineItemManagement_Helper 86%
    //  - BookingLineItemManagement        20%
 ---------------------------------------------------------*/
@isTest
public class BookingManagement_Trigger_Test 
{
    static testMethod void updateSalesOrderOwnerTest() 
    {
    	// create account
    	Account acct = TestDataFactory.createSingleAccount(null, 0, null, 0, 0);
    	insert acct;
    	
    	// create contact
    	List<Contact> contacts = TestDataFactory.createContacts(1, acct);
    	insert contacts;
    	
    	// create users
    	List<User> users = TestDataFactory.createUsers(51, 'News Direct Sales Inbound', null, null, false);
        insert users;
        
    	// set default sales rep
    	// treat last user in the list as default sales rep
    	SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[50].Id, External_Id__c = '1234');
    	insert salesRep;
    	
    	system.debug('@default sales rep user id: ' + users[50].Id);
    	
    	// create sales orders
    	List<Sales_Order__c> salesOrders = new List<Sales_Order__c>();
    	
    	List<Sales_Order__c> salesOrdersBatch1 = TestDataFactory.createSalesOrders(10, acct, acct, acct, contacts[0], null);
    	List<Sales_Order__c> salesOrdersBatch2 = TestDataFactory.createSalesOrders(10, acct, acct, acct, contacts[0], null);
    	

    	salesOrders.addAll(salesOrdersBatch1);
    	salesOrders.addAll(salesOrdersBatch2);
        
    	insert salesOrders;
    	
    	List<Case> cases=TestDataFactory.createCases(1,null,null);
    	cases[0].Sales_Order__c=salesOrdersBatch1[0].Id;
    	insert cases[0];
    	
    	Test.startTest();
    	
    	system.debug('====salesOrders1=== ' + salesOrders);
    	system.debug('====salesOrdersBatch1=== ' + salesOrdersBatch1);
    	system.debug('====salesOrdersBatch2=== ' + salesOrdersBatch2);
    	
    	// create bookings
    	List<Booking__c> bookings = new List<Booking__c>();
    	
    	Integer i = 0;
    	
    	List<User> usersBatch1 = new List<User>();
    	List<User> usersBatch2 = new List<User>();
    	List<User> usersBatch3 = new List<User>();
    	
    	for(; i < 10; i++)
    	{
    		usersBatch1.add(users.get(i));
    	}
    	
    	for(; i < 20; i++)
    	{
    		usersBatch2.add(users.get(i));
    	}
    	
        for(; i < 30; i++)
        {
            usersBatch3.add(users.get(i));
        }
        
    	List<Booking__c> bookingWithNetworkUser1 = TestDataFactory.createBookings(10, salesOrdersBatch1, usersBatch1);
        List<Booking__c> bookingWithNetworkUser2 = TestDataFactory.createBookings(10, salesOrdersBatch2, usersBatch2);
    	bookings.addAll(bookingWithNetworkUser1);
    	bookings.addAll(bookingWithNetworkUser2);
    	insert bookings;

        Product2 prod = new Product2(name='prod');
        insert prod;
        list<Booking_line_Item__c> blis = TestDataFactory.createBookingLineItems(5,bookingWithNetworkUser1[0], prod, null);
        insert blis;
    	
        system.debug('====bookings=== ' + bookings);
        system.debug('====bookingWithNetworkUser1=== ' + bookingWithNetworkUser1);
    	system.debug('====bookingWithNetworkUser2 1=== ' + bookingWithNetworkUser2);
    	
    	// verify owner on sales order
    	i = 0;
    	
    	for(Sales_Order__c so : [Select OwnerId, Ad_Taker__c From Sales_Order__c Where Id IN: salesOrdersBatch1])
    	{
    		system.assertEquals(users[i].Id, so.OwnerId);
    		system.assertEquals(users[i].Id, so.Ad_Taker__c);
    		i++;
    	}
    	
        for(Sales_Order__c so : [Select OwnerId, Ad_Taker__c From Sales_Order__c Where Id IN: salesOrdersBatch2])
        {
            system.debug('1. @users[i].Id: ' + users[i].Id + ' so.OwnerId: ' + so.OwnerId);
        	
            system.assertEquals(users[i].Id, so.OwnerId);
            system.assertEquals(users[i].Id, so.Ad_Taker__c);
            i++;
        }
    	
    	// update sales rep field on bookings
    	bookingWithNetworkUser2 = BookingManagement_Trigger_Test.updateBookings(bookingWithNetworkUser2, usersBatch3);
    	update bookingWithNetworkUser2;
    	
        system.debug('====bookingWithNetworkUser2 2=== ' + bookingWithNetworkUser2);
    	
    	
    	// verify sales order owner when booking has sales rep updated
        for(Sales_Order__c so : [Select OwnerId, Ad_Taker__c From Sales_Order__c Where Id IN: salesOrdersBatch2])
        {
            system.debug('2. @users[i].Id: ' + users[i].Id + ' so.OwnerId: ' + so.OwnerId);
        	
            system.assertEquals(users[i].Id, so.OwnerId);
            system.assertEquals(users[i].Id, so.Ad_Taker__c);
            i++;
        }
        

        bookingWithNetworkUser1[0].Integration_Date__c = System.now();
        update bookingWithNetworkUser1[0];

    	Test.stopTest(); 
    }
    
    static testMethod void updateBookingSendDateFlagTest() 
    {
        // create users
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
            	
        // set default sales rep
        // treat last user in the list as default sales rep
        SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert salesRep;
        
    	// create booking
    	Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber$ell');
    	List<Booking__c> bookings = TestDataFactory.createBookings(10, so);
    	insert bookings;
    	
    	Set<Id> bookingIds = new Set<Id>();

    	Test.startTest();
	
        system.debug('@bookingmanagement_trigger_helper_test bookingIds: ' + bookingIds);
        
    	//BookingManagement_Trigger_Helper.updateBookingSendDateFlag(bookingIds);
    	
    	BookingManagement_Trigger_Helper.updateBookingSendDateFlagNonFuture(bookingIds);
    	
    	// verify that all booking's send date flag has been set to true
    	bookings = [Select Quote_or_Confirmation_Flag_Send_Date__c 
                                      From Booking__c 
                                      Where Id IN: bookingIds];
                                          
    	Test.stopTest();
    }
    
    public static List<Booking__c> updateBookings(List<Booking__c> bookings, List<User> users)
    {
    	Integer i = 0;
    	
    	for(Booking__c b : bookings)
    	{
    	   b.Sales_Rep__c = users[i].Network_Username__c;
    	   b.Ad_Taker__c = users[i].Network_Username__c;
    	   i++;
    	}
    	
    	return bookings;
    }

    static testMethod void updateBookingLastExpiry(){
		
		// create users
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
            	
        // set default sales rep
        // treat last user in the list as default sales rep
        SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert salesRep;
        
    	// create booking
    	Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber$ell');
    	List<Booking__c> bookings = TestDataFactory.createBookings(10, so);
    	insert bookings;
		
		List<Booking_line_Item__c> booklineItems = new List<Booking_line_Item__c>();
		
		Product2 prod = new Product2(name='prod', Family='Digital');
        insert prod;
        list<Booking_line_Item__c> blis = TestDataFactory.createBookingLineItems(5,bookings[0], prod, null);
        
        Product2 prod1 = new Product2(name='prod1', Family='Magazine');
        insert prod1;
        list<Booking_line_Item__c> blis1 = TestDataFactory.createBookingLineItems(5,bookings[1], prod1, null);
        
        booklineItems.addAll(blis);
        booklineItems.addAll(blis1);
        insert booklineItems;
		
		for(Booking_line_Item__c bitem : blis){
			bitem.Cancelled__c = false;
			bitem.Run_Date__c = date.today() +1;
		}
		update blis;
		
		List<Account> acctList = [select id,Last_Booking_Number__c from Account where id =: bookings[0].Advertiser_Account__c];
		system.assertEquals(acctList[0].Last_Booking_Number__c, bookings[0].Name);
	}
	
	static testMethod void updateBooking_CheckQuote(){
		
		// create users
        List<User> users = TestDataFactory.createUsers(1, 'News Integration', null, null, false);
        insert users;
            	
        // set default sales rep
        // treat last user in the list as default sales rep
        SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert salesRep;
        
    	// create booking
    	Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber$ell');
    	so.External_Id__c = 'orderId';
    	update so;
    	
    	List<Booking__c> bookings = TestDataFactory.createBookings(10, so);
    	for(Booking__c book : bookings){
    		book.External_Sales_Order_Id__c = 'orderId';
    	}
    	insert bookings;
		
		system.assertEquals(bookings[0].Sales_Order__c, so.id);
		
		for(Booking__c book : bookings){
			book.Send_Channel__c = 'Email';
			book.AdProof_Required__c = true;
			book.Quote_Confirmation_waiting_msg_sent__c = false;
		}
		update bookings;

	}
	
	static testMethod void updateBooking_CheckAdProof(){
		
		// create users
        List<User> users = TestDataFactory.createUsers(1, 'News Integration', null, null, false);
        insert users;
            	
        // set default sales rep
        // treat last user in the list as default sales rep
        SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert salesRep;
        
    	// create booking
    	Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber$ell');
    	
    	List<Booking__c> bookings = TestDataFactory.createBookings(10, so);
    	insert bookings;
		
		for(Booking__c book : bookings){
			book.Send_Channel__c = 'Email';
			book.AdProof_Required__c = true;
			book.Quote_Confirmation_waiting_msg_sent__c = false;
			book.Quote_or_Confirmation_User__c = users[0].Id;
		}
		update bookings;

	}
    
}
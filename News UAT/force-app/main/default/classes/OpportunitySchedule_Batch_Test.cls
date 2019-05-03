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
private class OpportunitySchedule_Batch_Test {
    	
	static testMethod void scheduleTestMethod(){
    	// create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);

		insert accounts;
		
		// create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
		insert contacts;
		
		// create 10 products
		List<Product2> products = TestDataFactory.createProducts(10);
		
		//call TestDataFactory method to create Opportunity records
		Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
    	// create sales order
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(2, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        User userTest = TestDataFactory.createUser('News IT Administration', 'testUser101', 'lastName101', null, true, true);
		insert userTest;
		
        SystemParameters__c param = new SystemParameters__c();
        param.Name = 'Default Sales Rep';
        param.External_Id__c = 'Default Sales Rep';
        param.value__c = userTest.Id;
        insert param;
        
        
        system.runAs(userTest){
        	
	        // create booking
	        List<Booking__c> bookings = TestDataFactory.createBookings(2, salesOrders);
	        insert bookings;
	        
	        // create booking line items
	        List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>();
	        
	        for(Integer i = 0; i < bookings.size(); i++){
	            bookingLineItems.addAll(TestDataFactory.createBookingLineItems(5, bookings[i]));
	        }
	        
	        Integer i = 0;
	        for(Booking_Line_Item__c bookingLineItem : bookingLineItems){
	            bookingLineItem.Product__c = products[i].Id;
	            i++;
	            
	            if(i >= products.size())
	            {
	                i = 0;
	            }
	        }
	        
	        insert bookingLineItems;
	        
	        Test.startTest();
        
	        // run batch to populate TCS and TAS on accounts
	        OpportunitySchedule_Batch opportunityScheduleBatch = new OpportunitySchedule_Batch(null);
	        ID batchProcessId = Database.executeBatch(opportunityScheduleBatch);
	        System.debug('Returned batch process ID: ' + batchProcessId);
	        
	        Test.stopTest();
        }
	}
}
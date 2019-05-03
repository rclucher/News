/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * 2016-01-15  Atul Gupta  Updated
 * 2016-01-15 atul.gupta@bluewolfgroup.com
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
 *	 This class provides test coverage for
 *	  - SalesOrderDetails_Helper 90%
 ---------------------------------------------------------*/
@isTest
private class SalesOrderDetailsHelper_Test
{
	
	static testMethod void createOpportunityAndLineItemsTest()
	{
		// create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(10);
        
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
        // create 10 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'Default Sales Rep';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = Userinfo.getUserId();
        insert faxParam;

        List<User> users = TestDataFactory.createUsers(21, 'System Administrator', null, null, false);
        insert users;
        
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
	            booking.Sales_Rep__c = users[0].Network_Username__c;//'Sales_Rep';
	            bookings.add(booking);
	        }
    	}

        insert bookings;

		// Create booking line items
		List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>();

		i = 0;
		for(Sales_Order__c so : salesOrders)
		{
	        for(Integer j = 0; j < 2; j++)
	        {
				bookingLineItems.addAll(TestDataFactory.createBookingLineItems(10, bookings[i*2+j], null, products));
			}
			i++;
		}

		insert bookingLineItems;

		Test.startTest();
        
        for(Sales_Order__c so : salesOrders)
        {
            try{
                SalesOrderDetails_Helper.createOpportunityAndLineItems(so.Id);
            }catch(SalesOrderDetails_Helper.CreateOpportunityException dEx){
                //Webservice method will attemptn to create opportunity with blank amount and run into new validation
                //new validation rule https://newscorpaustralia--testfixes.cs72.my.salesforce.com/03d90000001Hmgi?setupid=OpportunityValidations
                //Expected behaviour as per David
                system.debug(dEx.getMessage());
            }
        }

		Test.stopTest();

	}
	
	static testMethod void createOpportunityAndLineItemsTest1()
	{
		// create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(10);
        
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
        // create 10 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'Default Sales Rep';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = Userinfo.getUserId();
        insert faxParam;
        
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

		// Create booking line items
		List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>();

		i = 0;
		for(Sales_Order__c so : salesOrders)
		{
	        for(Integer j = 0; j < 2; j++)
	        {
				bookingLineItems.addAll(TestDataFactory.createBookingLineItems(10, bookings[i*2+j], null, products));
			}
			i++;
		}

		insert bookingLineItems;

		Test.startTest();

		for(Sales_Order__c so : salesOrders)
		{
            try{
                SalesOrderDetails_Helper.createOpportunityAndLineItems(so.Id);
            }catch(SalesOrderDetails_Helper.CreateOpportunityException dEx){
                //Webservice method will attempt to create opportunity with blank amount and run into new validation
                //new validation rule https://newscorpaustralia--testfixes.cs72.my.salesforce.com/03d90000001Hmgi?setupid=OpportunityValidations
                //Expected behaviour as per David
                system.debug(dEx.getMessage());
            }
        }
        
        Test.stopTest();

	}
	
	//test for sales orders upsert
	static testMethod void testUpsertSalesOrders(){
		
		// create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;

        // create 10 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        //create campaign records
        List<Campaign> campaignsList = TestDataFactory.createCampaigns(5);
        insert campaignsList;
        
        //TestDataFactory.createFaxSystemParameters();
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'Default Sales Rep';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = Userinfo.getUserId();
        insert faxParam;
        
        //create booking record
        Booking__c bookRec = TestDataFactory.createBooking(salesOrders[0]);
        bookRec.Third_Party_Created__c = null;
        update bookRec;
        
        Map<string, string> wrapMap = new Map<string, string>();
        wrapMap.put('salesOrderSFID', salesOrders[0].Id);
        wrapMap.put('bookingSFID', bookRec.Id);
        wrapMap.put('campaignSFID', campaignsList[0].Id);
        
        SalesOrderDetails_Helper.SalesOrderDetail sOrder = new SalesOrderDetails_Helper.SalesOrderDetail();
        sOrder.bookingID = '1234567890';
        sOrder.totalCost = '3033';
        
		SalesOrderDetails_Helper.SalesOrderWrapper swrap = new SalesOrderDetails_Helper.SalesOrderWrapper();
		swrap.salesOrder = sOrder;
		swrap.parameter = wrapMap;

		
		SalesOrderDetails_Helper.upsertSalesOrderDertails(swrap);
		
	}
	
	static testMethod void testBookingError(){
		
		// create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
		
		//create case record
		String caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
		Case caseRecord = TestDataFactory.createSingleCase(caseRT, accounts[0].Id);
		insert caseRecord;
		
        // create 10 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        //create campaign records
        List<Campaign> campaignsList = TestDataFactory.createCampaigns(5);
        insert campaignsList;
        
        //TestDataFactory.createFaxSystemParameters();
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'Default Sales Rep';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = Userinfo.getUserId();
        insert faxParam;

        Map<string, string> wrapMap = new Map<string, string>();
        wrapMap.put('salesOrderSFID', salesOrders[0].Id);
        wrapMap.put('campaignSFID', campaignsList[0].Id);
        wrapMap.put('caseSourceSFID', caseRecord.Id);
        
        SalesOrderDetails_Helper.SalesOrderDetail sOrder = new SalesOrderDetails_Helper.SalesOrderDetail();
        sOrder.bookingID = '1234567890';
        sOrder.totalCost = '3033';
        sOrder.bookingDivision = 'test';
		sOrder.bookingNum = 'test';
		sOrder.placerConId = 'test';
		sOrder.salesOrderID = 'test';
		sOrder.billingAccountID = 'test';
		sOrder.orderId = 'test';
		sOrder.divisionName = 'test';
		sOrder.publicationName = 'test';
		sOrder.adType = 'test';
		sOrder.placerContact = 'test';
		sOrder.payerAccount = 'test';
		sOrder.bookingprofile = 'test';
		sOrder.placerFName = 'test';
		sOrder.placerLName = 'test';
		sOrder.intgID = 'test';
		sOrder.main = 'test';
		sOrder.address = 'test';
		sOrder.city = 'test';
		sOrder.postCode = 'test';
		sOrder.bpType = 'test';
		sOrder.baType = 'test';
		sOrder.baNumber = 'test';
		sOrder.accountName = 'test';
		sOrder.localNumber = 'test';
		sOrder.areaCode = 'test';
		sOrder.createdDate = 'test';
		sOrder.baName = 'test';
		sOrder.state = 'test';
		sOrder.country = 'test';
		sOrder.status = 'test';
		sOrder.sourceSystem = 'test';
		sOrder.bookingContact = 'test';
		sOrder.newsLines = 'test';
		sOrder.searchDate = 'test';
		sOrder.productID = 'test';
		sOrder.startDate = 'test';
		sOrder.lastDate = 'test';
		sOrder.runSchedule = 'test';
		sOrder.classificationCode = 'test';
		sOrder.newsDepth = 'test';
		sOrder.newsCaption = 'test';
		sOrder.bookingAccount = 'test';
		sOrder.bookedPoint = 'test';
		sOrder.salesOrderSFID = 'test';
		sOrder.bookingSFID = 'test';
        
		SalesOrderDetails_Helper.SalesOrderWrapper swrap = new SalesOrderDetails_Helper.SalesOrderWrapper();
		swrap.salesOrder = sOrder;
		swrap.parameter = wrapMap;
		swrap.message = 'messageTest';
		swrap.orderId = 'orderIdTest';

		try{		
			SalesOrderDetails_Helper.upsertSalesOrderDertails(swrap);
		}catch(Exception ex){
			system.assertEquals(true, ex.getMessage().contains('Booking could not be created'));
		}
		
	}
	
	//test if sales order passed is null
	static testMethod void testSalesOrderIdIsNULL()
	{
		// create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(10);
        
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
        // create 10 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
		
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'Default Sales Rep';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = Userinfo.getUserId();
        insert faxParam;
        
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

		// Create booking line items
		List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>();

		i = 0;
		for(Sales_Order__c so : salesOrders)
		{
	        for(Integer j = 0; j < 2; j++)
	        {
				bookingLineItems.addAll(TestDataFactory.createBookingLineItems(10, bookings[i*2+j], null, products));
			}
			i++;
		}

		insert bookingLineItems;

		Test.startTest();
		try{
			for(Sales_Order__c so : salesOrders)
			{
				SalesOrderDetails_Helper.createOpportunityAndLineItems(null);
			}
		}catch(Exception ex){
			system.debug('@@ex : '+ex.getMessage());
			system.assertEquals(true, ex.getMessage().contains('Sales order id cannot be null'));
		}
		Test.stopTest();

	}
	
	//test if bookinglineitems are not created
	static testMethod void testBookingLineItemsNull()
	{
		// create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(10);
        
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
        // create 10 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
		
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'Default Sales Rep';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = Userinfo.getUserId();
        insert faxParam;
        
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
		
		Test.startTest();
		try{
			for(Sales_Order__c so : salesOrders)
			{
				SalesOrderDetails_Helper.createOpportunityAndLineItems(so.Id);
			}
		}catch(Exception ex){
			system.debug('@@ex : '+ex.getMessage());
			
			system.assertEquals(true, ex.getMessage().contains('exist for this sales order.'));
		}
		Test.stopTest();

	}
	
	//test if noFiscalCalendarFound is true
	static testMethod void testnoFiscalCalendarFound()
	{
		// create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(10);
        
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
        // create 10 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
		
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'Default Sales Rep';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = Userinfo.getUserId();
        insert faxParam;
        
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
        
        Date runDate;
        
		List<FiscalYearSettings> fySettingList = [Select f.WeekStartDay, f.StartDate, f.EndDate 
														From FiscalYearSettings f 
														Where f.IsStandardYear = false 
														ORDER BY f.startdate];
		if(!fySettingList.isEmpty()){
			
			Integer previousYear = fySettingList[0].StartDate.year() - 1 ;
			system.debug('@@previousYear :'+ previousYear);
			
			runDate = Date.newInstance(previousYear, 2, 17);
		}
		
		// Create booking line items
		List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>();

		i = 0;
		for(Sales_Order__c so : salesOrders)
		{
	        for(Integer j = 0; j < 2; j++)
	        {
				bookingLineItems.addAll(TestDataFactory.createBookingLineItems(10, bookings[i*2+j], null, products));
			}
			i++;
		}

		insert bookingLineItems;

		Test.startTest();
		try{
			for(Sales_Order__c so : salesOrders)
			{
				SalesOrderDetails_Helper.createOpportunityAndLineItems(so.Id);
			}
		}catch(Exception ex){
			
		}
		Test.stopTest();

	}
	
	//
	static testMethod void testNOBookingIsCreatedException(){
		
		// create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;

        // create 10 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        //create campaign records
        List<Campaign> campaignsList = TestDataFactory.createCampaigns(5);
        insert campaignsList;
        
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'Default Sales Rep';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = Userinfo.getUserId();
        insert faxParam;
        
        //create booking record
        Booking__c bookRec = TestDataFactory.createBooking(salesOrders[0]);
        bookRec.Third_Party_Created__c = null;
        update bookRec;
        
        Map<string, string> wrapMap = new Map<string, string>();
        wrapMap.put('abc', 'testabc');
        
        SalesOrderDetails_Helper.SalesOrderDetail sOrder = new SalesOrderDetails_Helper.SalesOrderDetail();
        sOrder.bookingID = '1234567890';
        sOrder.totalCost = '3033';
        
		SalesOrderDetails_Helper.SalesOrderWrapper swrap = new SalesOrderDetails_Helper.SalesOrderWrapper();
		swrap.salesOrder = sOrder;
		swrap.parameter = wrapMap;

		try{
			SalesOrderDetails_Helper.upsertSalesOrderDertails(swrap);
		}catch(Exception ex){
			system.assertEquals(true, ex.getMessage().contains('Booking could not be created'));
		}
	}
	
	//test coverage for convertSalesOrderWrapperToBookingLineItem method
	static testMethod void testCovertSales(){
        
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'Default Sales Rep';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = Userinfo.getUserId();
        insert faxParam;
        
        // create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        List<Product2> products = TestDataFactory.createProducts(1);
        
        for(Product2 pro : products){
        	pro.Name = 'Dummy';
        }
        update products;
        
        List<Pricebook2> priceBookList = TestDataFactory.createCustomPricebookData_Standard();
        
        List<PricebookEntry> entryList = TestDataFactory.createPricebookEntryData(priceBookList[0], products);
        
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2, priceBookList[0].Id, accounts[0], contacts[0]);
        insert opportunities;
        
        // create 10 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        Booking__c bookRec = TestDataFactory.createBooking(salesOrders[0]);
        
        Map<string, string> wrapMap = new Map<string, string>();
        wrapMap.put('abc', 'testabc');
        
        SalesOrderDetails_Helper.SalesOrderDetail sOrder = new SalesOrderDetails_Helper.SalesOrderDetail();
        sOrder.bookingID = '1234567890';
        sOrder.totalCost = '3033';
        sOrder.startDate = '31/5/2013';
        sOrder.newsLines = '2.2';
        sOrder.productID = '1234';
        sOrder.classificationCode = '1234';
        sOrder.newsDepth = '1234';
        sOrder.newsCaption = '1234';
        sOrder.publicationName = '1234';
        sOrder.divisionName = '1234';
        sOrder.adType = '1234';
        sOrder.status = '1234';
        
		SalesOrderDetails_Helper.SalesOrderWrapper swrap = new SalesOrderDetails_Helper.SalesOrderWrapper();
		swrap.salesOrder = sOrder;
		swrap.parameter = wrapMap;
		
		Booking_Line_Item__c item = SalesOrderDetails_Helper.convertSalesOrderWrapperToBookingLineItem(swrap);
		
		OpportunityLineItem lineItem = SalesOrderDetails_Helper.createDummyOpportunityLineItem(salesOrders[0], opportunities[0]);
		
		String extId = SalesOrderDetails_Helper.formatBookingExternalId(swrap, bookRec);
	}
	
}
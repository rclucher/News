@isTest
private class BookingUpdate_Test 
{
    // 2015-09-08 louis.wang@bluewolf.com
    //    This class provides test coverage for 
    //      - BookingUpdate_Batch - 100% coverage
    //      - BookingUpdate_Schedule - 100% coverage

    private static void setupData()
    {
    	// create account
    	Account acct = TestDataFactory.createSingleAccount(null, 0, null, 0, 0);
    	insert acct;
    	
    	// create contact
    	List<Contact> contacts = TestDataFactory.createContacts(1, acct);
    	insert contacts;

        // create users
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
        
        // set default sales rep
        // treat last user in the list as default sales rep
        SystemParameters__c sysParam = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert sysParam;
   	
    	// create sales orders
    	List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(10, acct, acct, acct, contacts[0], null);        
    	insert salesOrders;

    	// create bookings
		List<Booking__c> bookings = TestDataFactory.createBookings(10, salesOrders);
    	insert bookings;

    	// create campaigns
    	List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
    	insert campaigns;

    	for(Sales_Order__c s : salesOrders)
    	{
    		s.Campaign__c = campaigns[0].Id;
    	}
    	update salesOrders;

    }	

	private static testmethod void BookingUpdateBatch_Test() 
	{
    	setupData();

        // Before the batch - there are 10 bookings not having Campaign__c value
        List<Booking__c> bookingResultList = [SELECT Id, Campaign__c FROM Booking__c 
                                                WHERE Campaign__c=null
                                                AND Sales_Order__r.Campaign__c!=null];
        system.assertEquals(10,bookingResultList.size());                                                

    	Test.startTest();		

        BookingUpdate_Batch updateProcess = new BookingUpdate_Batch();
        ID idBatch = Database.executeBatch(updateProcess);

		Test.stopTest();  	

        // After the batch - there are 0 bookings not having Campaign__c value
        bookingResultList = [SELECT Id, Campaign__c FROM Booking__c 
                                                WHERE Campaign__c=null
                                                AND Sales_Order__r.Campaign__c!=null];
        system.assertEquals(0,bookingResultList.size()); 
	}


    private static testmethod void BookingUpdateSchedule_Test() 
    {
        //arbitrary cron setting  
        String CRON_EXP = '0 0 0 15 3 ? 2022';

        Test.startTest();
      
        // Schedule the test job 
        String jobId = System.schedule('BookingUpdate Schedule',
                                    CRON_EXP, 
                                    new BookingUpdate_Schedule());
         
        // Get the information from the CronTrigger API object 
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime
                            FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same 
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run     
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run     
        System.assertEquals('2022-03-15 00:00:00', String.valueOf(ct.NextFireTime));
 
        Test.stopTest();
    }
}
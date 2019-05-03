/*
 * 2015-11-30   Darshan Gosar    Updated
 *  2015-11-30 darshan.gosar@bluewolfgroup.com 
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    // This class provides test coverage for
    //  - Csr_Opportunity_Batch.cls               85%    
    //  - CustomRevenueSchedule_Scheduler.cls    100%
 ---------------------------------------------------------*/
@isTest
private class CustomRevenueSchedule_Scheduler_Test {
    
    @isTest static void customRevenueScheduleSchedulerTest() {
        
        // SFE-766 2015-11-30 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition    
        Batch_Run_Start_Datetime__c lastRunDateTime = new Batch_Run_Start_Datetime__c();
        lastRunDateTime.Name = 'Booking_Refresh_YTD_Revenue_Batch';
        lastRunDateTime.Run_Start_Datetime__c = datetime.now().addDays(-1);
        insert lastRunDateTime;

        Batch_Run_Start_Datetime__c lastRunDateTime1 = new Batch_Run_Start_Datetime__c();
        lastRunDateTime1.Name = 'CRS Opportunity Batch';
        lastRunDateTime1.Run_Start_Datetime__c = datetime.now().addDays(-1);
        insert lastRunDateTime1;    
        // create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(2);

        // SFE-766 2015-11-30 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition        
        // create pricebooks
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        
        // create opportunities
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,pricebooks[0].Id,accounts[0],contacts[0]);
        insert opportunities;

        final String CRON_EXP = '0 0 0 3 9 ? 2022';

        Test.startTest();
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new CustomRevenueSchedule_Scheduler());

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        System.assertEquals(CRON_EXP, ct.CronExpression);

        Test.stopTest();
    }
}
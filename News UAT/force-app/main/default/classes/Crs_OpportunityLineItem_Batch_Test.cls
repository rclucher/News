/*
 * 2015-12-18  Darshan G   Created
     //  Added new test class to get code coverage
// SFE-766 2015-12-18 darshan.gosar@bluewolfgroup.com 
// 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    // This class provides test coverage for 
    //  - Crs_OpportunityLineItem_Batch           100%
    //  - OpportunityLineItemManagement.trigger    79% 
 ---------------------------------------------------------*/
@isTest
private class Crs_OpportunityLineItem_Batch_Test {
    
    @isTest static void crsOpportunityBatchLineItenTest() {
        Batch_Run_Start_Datetime__c lastRunDateTime = new Batch_Run_Start_Datetime__c();
        lastRunDateTime.Name = 'Booking_Refresh_YTD_Revenue_Batch';
        lastRunDateTime.Run_Start_Datetime__c = datetime.now().addDays(-1);
        insert lastRunDateTime;

        Batch_Run_Start_Datetime__c lastRunDateTime1 = new Batch_Run_Start_Datetime__c();
        lastRunDateTime1.Name = 'CRS Opportunity Line Item Batch';
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
        
        // create pricebooks
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        
        // create opportunities
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,null,accounts[0],contacts[0]);
        insert opportunities;
        
        // create opportunity line items for opportunities
        List<OpportunityLineItem> opportunityLineItems = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, null);
        insert opportunityLineItems;
                
        Test.startTest();

        // exceute the batch class
        ID batchprocessid = Database.executeBatch(new Crs_OpportunityLineItem_Batch());
        Test.stopTest();
    }
}
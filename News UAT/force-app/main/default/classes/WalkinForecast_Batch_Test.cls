/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * this is the test class for walkin forecast scheduler
 *             Bohao Chen  Created
 * 2015-12-21  Atul Gupta  Updated 
 * 2016-01-15 atul.gupta@bluewolfgroup.com
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
 *      This class provides test coverage for
 *          - WalkinForecast_Batch   89%
 ---------------------------------------------------------*/
@isTest
private class WalkinForecast_Batch_Test 
{
    static testmethod void test() 
    {
        String RECORD_TYPE_NAME = 'Walk-In Forecast';
        
        // create account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        insert accts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
        insert contacts;
        
        List<Product2> products = TestDataFactory.createProducts(3);
    
        Pricebook2 customPriceBook = TestDataFactory.customPriceBook();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryDataNew(products, customPriceBook);

        // create test opportunities
        Id stdPricebookId = Test.getStandardPricebookId();
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, stdPricebookId, accts[0], contacts[0]);
        
        for(Opportunity oppty : opportunities)
        {
            oppty.Name = 'Walk-in Forecast-Week-';
            oppty.CloseDate = date.today().addDays(-5);
            oppty.StageName = 'Awaiting Bookings';
            oppty.RecordTypeId = Global_Helper.getRecordTypeIdByName(RECORD_TYPE_NAME, 'Opportunity');
            oppty.Probability = 90;
        }
        
        insert opportunities;
        
        List<OpportunityLineItem> opportunityLineItems = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, null);

        insert opportunityLineItems;
    
        Test.startTest();
    
    
        opportunities = [Select StageName, Probability, (Select Id from OpportunityLineItems) From Opportunity Where Id IN: opportunities];

        WalkinForecast_Batch forecastBatch = new WalkinForecast_Batch();
        
        ID batchprocessid = Database.executeBatch(forecastBatch);
        
        Test.stopTest();
        
        // verify all opportunities have been updated
        for(Opportunity oppty : [Select StageName, Probability From Opportunity Where Id IN: opportunities])
        {
            system.assertEquals('Closed Lost', oppty.StageName);
            system.assertEquals(0, oppty.Probability);
        }

    }
    
    static testmethod void testWalkInForecastOpportunities() 
    {
        String RECORD_TYPE_NAME = 'Walk-In Forecast';

        // create account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        insert accts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
        insert contacts;        
        
        List<Product2> products = TestDataFactory.createProducts(3);
    
        Pricebook2 customPriceBook = TestDataFactory.customPriceBook();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryDataNew(products, customPriceBook);

        // create test opportunities
        Id stdPricebookId = Test.getStandardPricebookId();
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, stdPricebookId, accts[0], contacts[0]);
        
        for(Opportunity oppty : opportunities)
        {
            oppty.Name = 'Walk-in Forecast-Week-';
            oppty.CloseDate = date.today();
            oppty.StageName = 'Awaiting Bookings';
            oppty.RecordTypeId = Global_Helper.getRecordTypeIdByName(RECORD_TYPE_NAME, 'Opportunity');
            oppty.Probability = 90;
        }
        
        insert opportunities;
        
        List<OpportunityLineItem> opportunityLineItems = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, null);

        insert opportunityLineItems;
    
        Test.startTest();
    
    
        opportunities = [Select StageName, Probability, (Select Id from OpportunityLineItems) From Opportunity Where Id IN: opportunities];

        WalkinForecast_Batch forecastBatch = new WalkinForecast_Batch();
        
        ID batchprocessid = Database.executeBatch(forecastBatch);
        
        Test.stopTest();
        
        // verify all opportunities have been updated
        for(Opportunity oppty : [Select StageName, Probability From Opportunity Where Id IN: opportunities])
        {
            system.assertEquals('Closed Lost', oppty.StageName);
            system.assertEquals(0, oppty.Probability);
        }

    }
}
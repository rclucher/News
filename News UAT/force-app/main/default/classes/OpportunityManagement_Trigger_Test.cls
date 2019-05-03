/*---------------------------------------------------------
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This is test class for trigger 'OpportunityManagement'
 * History:
 * 13/06/2013  Bohao Chen  Created
 * 2015-12-01 darshan.gosar@bluewolfgroup.com 
 *   Upadated to remove seeAllData condition
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    // This class provides test coverage for 
    //  - OpportunityLineItemManagement.trigger    79%
    //  - OpportunityManagement.trigger            86% 
 * 16/03/2018  Pratyush Chalasani (Ativa) - added tests for updating contact role records
 * 17/10/2018  David Scullion - reduced number of opportunities created to resolve error System.LimitException: Too many SOQL queries: 101
 ---------------------------------------------------------*/
@isTest
private class OpportunityManagement_Trigger_Test 
{
    static List<Opportunity> opportunities;
    static List<OpportunityLineItem> opportunityLineItems;
    static List<Contact> contacts;
    static List<Account> accts;
    
    @isTest
    static void testContactRoleInsert() {
        // check whether a contact role is created when a new opportunity is inserted
        
        OpportunityManagement_Trigger_Test.initTestData();
        
        Test.startTest();
        
        List<OpportunityContactRole> roles = [SELECT Id, ContactId, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :opportunities[0].Id];
        
        System.assertNotEquals(null, roles, 'Should have data in roles');
        System.assertEquals(1, roles.size(), 'Should have 1 record in roles');
        System.assertEquals(true, roles[0].IsPrimary, 'Role should be primary');
        System.assertEquals(contacts[0].Id, roles[0].ContactId, 'Role should be linked to existing contact');
        
        Test.stopTest();
    }
    
    @isTest
    static void testContactRoleUpdate() {
        // update contact on opportunity and check if a new contact role is created
        
        OpportunityManagement_Trigger_Test.initTestData();
        
        Test.startTest();
        
        Contact newCnt = TestDataFactory.createContacts(1, accts[0])[0];
        
        insert newCnt;
        
        opportunities[0].Contact__c = newCnt.Id;
        
        /*
         * 03-11-2018: Mohsin Ali (Ative)
         * Adding this to revert the flag of before & after update to false.
		*/
        News_TriggerHelper.OpportunityManagement_Before_Update_Executing = !News_TriggerHelper.OpportunityManagement_Before_Update_Executing;
    	News_TriggerHelper.OpportunityManagement_After_Update_Executing = !News_TriggerHelper.OpportunityManagement_After_Update_Executing;

        update opportunities[0];
        
        List<OpportunityContactRole> roles = [SELECT Id, ContactId, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :opportunities[0].Id ORDER BY Id];
        
        System.assertNotEquals(null, roles, 'Should have data in roles');
        System.assertEquals(2, roles.size(), 'Should have 2 records in roles');
        System.assertEquals(false, roles[0].IsPrimary, '1st role should not be primary');
        System.assertEquals(true, roles[1].IsPrimary, '2nd role should be primary');
        System.assertEquals(newCnt.Id, roles[1].ContactId, '2nd role should be linked to new contact');
        
        Test.stopTest();
    }
    
    @isTest
    static void testContactRoleRevert() {
        // update contact on opportunity, revert to original contact, and check if a new contact role is created
        
        OpportunityManagement_Trigger_Test.initTestData();
        
        Test.startTest();
        
        Id originalCnt = opportunities[0].Contact__c;
        
        Contact newCnt = TestDataFactory.createContacts(1, accts[0])[0];
        
        insert newCnt;
        
        opportunities[0].Contact__c = newCnt.Id;

        /*
         * 03-11-2018: Mohsin Ali (Ative)
         * Adding this to revert the flag of before & after update to false.
		*/
        News_TriggerHelper.OpportunityManagement_Before_Update_Executing = !News_TriggerHelper.OpportunityManagement_Before_Update_Executing;
    	News_TriggerHelper.OpportunityManagement_After_Update_Executing = !News_TriggerHelper.OpportunityManagement_After_Update_Executing;
        
        update opportunities[0];
        
        opportunities[0].Contact__c = originalCnt;

        /*
         * 03-11-2018: Mohsin Ali (Ative)
         * Adding this to revert the flag of before & after update to false.
		*/
        News_TriggerHelper.OpportunityManagement_Before_Update_Executing = !News_TriggerHelper.OpportunityManagement_Before_Update_Executing;
    	News_TriggerHelper.OpportunityManagement_After_Update_Executing = !News_TriggerHelper.OpportunityManagement_After_Update_Executing;
        
        update opportunities[0];
        
        List<OpportunityContactRole> roles = [SELECT Id, ContactId, IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :opportunities[0].Id ORDER BY Id];
        
        System.assertNotEquals(null, roles, 'Should have data in roles');
        System.assertEquals(2, roles.size(), 'Should have 2 records in roles');
        System.assertEquals(true, roles[0].IsPrimary, '1st role should be primary');
        System.assertEquals(false, roles[1].IsPrimary, '2nd role should not be primary');
        System.assertEquals(originalCnt, roles[0].ContactId, '1st role should be linked to new contact');
        
        Test.stopTest();
    }
    
    static testMethod void revenueAtCloseLostTest() 
    {
        OpportunityManagement_Trigger_Test.initTestData();
        
        Test.startTest();
        
        for(Opportunity opportunity : opportunities)
        {
            opportunity.StageName = 'Closed Lost';
            opportunity.Reason_Won_Lost__c = 'Other';
            opportunity.Probability = 0;
            opportunity.Competitor__c = 'Direct Mail';
            opportunity.Closure_Summary__c = 'testing';
        }

        /*
         * 03-11-2018: Mohsin Ali (Ative)
         * Adding this to revert the flag of before & after update to false.
		*/
        News_TriggerHelper.OpportunityManagement_Before_Update_Executing = !News_TriggerHelper.OpportunityManagement_Before_Update_Executing;
    	News_TriggerHelper.OpportunityManagement_After_Update_Executing = !News_TriggerHelper.OpportunityManagement_After_Update_Executing;

        update opportunities;
                
        for(OpportunityLineItem o : [Select o.UnitPrice, o.Revenue_AtClose__c, o.PricebookEntryId, o.OpportunityId 
                                    From OpportunityLineItem o Where o.OpportunityId IN: opportunities])
        {
            system.assertEquals(2000, o.Revenue_AtClose__c);
        }
        
        for(Opportunity oppt : [Select Revenue_Close__c From Opportunity Where Id IN: opportunities])
        {
            system.assertEquals(20000, oppt.Revenue_Close__c);
        }
        
        for(Opportunity opportunity : opportunities)
        {
            opportunity.StageName = 'Qualified Opportunity';
        }

        /*
         * 03-11-2018: Mohsin Ali (Ative)
         * Adding this to revert the flag of before & after update to false.
		*/
        News_TriggerHelper.OpportunityManagement_Before_Update_Executing = !News_TriggerHelper.OpportunityManagement_Before_Update_Executing;
    	News_TriggerHelper.OpportunityManagement_After_Update_Executing = !News_TriggerHelper.OpportunityManagement_After_Update_Executing;
        
        update opportunities;
                
        for(OpportunityLineItem o : [Select o.UnitPrice, o.Revenue_AtClose__c, o.PricebookEntryId, o.OpportunityId 
                                    From OpportunityLineItem o Where o.OpportunityId IN: opportunities])
        {
            system.assertEquals(null, o.Revenue_AtClose__c);
        }
        
        for(Opportunity oppt : [Select Revenue_Close__c From Opportunity Where Id IN: opportunities])
        {
            system.assertEquals(0, oppt.Revenue_Close__c);
        }
        
        Test.stopTest();
    }
    
    static testMethod void revenueAtCloseWonTest() 
    {
        
        OpportunityManagement_Trigger_Test.initTestData();
        Test.startTest();
        
        for(Opportunity opportunity : opportunities)
        {
            opportunity.StageName = 'Closed Won';
            opportunity.Reason_Won_Lost__c = 'Other';
            opportunity.Probability = 0;
            opportunity.Competitor__c = 'Direct Mail';
            opportunity.Closure_Summary__c = 'testing';
            opportunity.OpportunityGroup__c = 'Other';
        }
        
        update opportunities[0];
        
        Test.stopTest();
        /*
        for(OpportunityLineItem o : [Select o.UnitPrice, o.Revenue_AtClose__c, o.PricebookEntryId, o.OpportunityId 
                                    From OpportunityLineItem o Where o.OpportunityId IN: opportunities])
        {
            system.assertEquals(2000, o.Revenue_AtClose__c);
        }
        
        for(Opportunity oppt : [Select Revenue_Close__c From Opportunity Where Id IN: opportunities])
        {
            system.assertEquals(20000, oppt.Revenue_Close__c);
        }*/
    }
    
    static void initTestData()
    {
        // create account
        OpportunityManagement_Trigger_Test.accts = TestDataFactory.createAccounts(1, false);
        insert OpportunityManagement_Trigger_Test.accts;
        
        // create contact
        OpportunityManagement_Trigger_Test.contacts = TestDataFactory.createContacts(1, accts[0]);
        insert OpportunityManagement_Trigger_Test.contacts;
        // SFE-766 2015-12-01 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition    
        List<Product2> products = TestDataFactory.createProducts(10);
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
 //       OpportunityManagement_Trigger_Test.opportunities = TestDataFactory.createOpportunities_withContact(30, null, accts[0], contacts[0]); // Updated by Bohao Chen on 30/05/2014
        OpportunityManagement_Trigger_Test.opportunities = TestDataFactory.createOpportunities_withContact(5, null, accts[0], contacts[0]); // Updated by David Scullion on 17/10/2018
        insert OpportunityManagement_Trigger_Test.opportunities;
        
        OpportunityManagement_Trigger_Test.opportunityLineItems = TestDataFactory.createOpportunityLineItems(OpportunityManagement_Trigger_Test.opportunities, products, pricebookEntries, null);
        insert OpportunityManagement_Trigger_Test.opportunityLineItems;
    }
    
}
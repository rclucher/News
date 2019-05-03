// 2015-11-30 darshan.gosar@bluewolfgroup.com 
// 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    // This class provides test coverage for
    //  - CampaignInfluenceManagement_Helper.cls    100%
    //  - CampaignInfluenceManagement.trigger       100%
//
@isTest
private class CampaignInfluenceManagement_Helper_Test {
    
    @isTest static void testSetPrimaryCampaign() {
        // create test data
        // BEGIN:
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;

        // create a contact for account
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // SFE-766 2015-11-30 darshan.gosar@bluewolfgroup.com        
            // To cover test scenarios without seeAllData condition
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();

        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, pricebooks[0].Id, accounts[0], contacts[0]);
        insert opportunities;

        List<Campaign> campaigns = TestDataFactory.createCampaigns(3);
        insert campaigns;
        // END:

        
        Campaign_Influence__c campaignInfluence = TestDataFactory.createCampaignInfluence(campaigns[0].Id, opportunities[0].Id, true);
        insert campaignInfluence;

        campaignInfluence = TestDataFactory.createCampaignInfluence(campaigns[1].Id, opportunities[0].Id, true);
        insert campaignInfluence;

        Opportunity opportunity = [SELECT CampaignId FROM Opportunity WHERE Id =: opportunities[0].Id LIMIT 1];
        System.debug('opportunity: ' + opportunity);
        Campaign_Influence__c ciUpdated = [SELECT Is_Primary_Campaign__c FROM Campaign_Influence__c WHERE Opportunity__c =: opportunities[0].Id AND Campaign__c =: campaigns[1].Id LIMIT 1];
        System.debug('ciUpdated: ' + ciUpdated);

        System.assertEquals(campaigns[1].Id, opportunity.CampaignId);
        System.assertEquals(true, ciUpdated.Is_Primary_Campaign__c);

        
    }

    @isTest static void testUnsetPrimaryCampaign() {
        // create test data
        // BEGIN:
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;

        // create a contact for account
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;        

        // SFE-766 2015-11-30 darshan.gosar@bluewolfgroup.com        
            // To cover test scenarios without seeAllData condition
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();

        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, pricebooks[0].Id, accounts[0], contacts[0]);
        insert opportunities;

        List<Campaign> campaigns = TestDataFactory.createCampaigns(3);
        insert campaigns;
        // END:

        
        Campaign_Influence__c campaignInfluence = TestDataFactory.createCampaignInfluence(campaigns[0].Id, opportunities[0].Id, true);
        insert campaignInfluence;

        campaignInfluence = TestDataFactory.createCampaignInfluence(campaigns[1].Id, opportunities[0].Id, true);
        insert campaignInfluence;

        Opportunity opportunity = [SELECT CampaignId FROM Opportunity WHERE Id =: opportunities[0].Id LIMIT 1];
        System.debug('opportunity: ' + opportunity);
        Campaign_Influence__c ciUpdated = [SELECT Is_Primary_Campaign__c FROM Campaign_Influence__c WHERE Opportunity__c =: opportunities[0].Id AND Campaign__c =: campaigns[0].Id LIMIT 1];
        System.debug('ciUpdated: ' + ciUpdated);

        System.assertEquals(campaigns[1].Id, opportunity.CampaignId);
        System.assertEquals(false, ciUpdated.Is_Primary_Campaign__c);
    }
}
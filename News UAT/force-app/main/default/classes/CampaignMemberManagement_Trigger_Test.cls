/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This is test class for trigger 'CampaignMemberManagement'
 * History:
 * 02/07/2013  Bohao Chen  Created
 */
@isTest
private class CampaignMemberManagement_Trigger_Test {

    static testMethod void createAndUpdateCampaignTest() 
    {
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        insert campaigns;
        
        List<Contact> contacts = new List<Contact>();
        List<Contact> contacts1 = TestDataFactory.createContacts(40, accounts[0]);
        List<Contact> contacts2 = TestDataFactory.createContacts(40, accounts[1]);
        contacts.addAll(contacts1);
        contacts.addAll(contacts2);
        insert contacts;
        
        Test.startTest();
        
        List<CampaignMember> campainMembers = new List<CampaignMember>();
        List<CampaignMember> campainMembersToContacts1 = new List<CampaignMember>();
        List<CampaignMember> campainMembersToContacts2 = new List<CampaignMember>();
        
        campainMembersToContacts1.addAll(TestDataFactory.createCampaignMembers(40, contacts1, campaigns[0]));
        campainMembersToContacts2.addAll(TestDataFactory.createCampaignMembers(40, contacts2, campaigns[0]));
        campainMembers.addAll(campainMembersToContacts1);
        campainMembers.addAll(campainMembersToContacts2);
        insert campainMembers;
        
        // check if account of each campaign member is the parent account of contact of same campaign member
      /*  for(CampaignMember cm : [Select c.Contact.AccountId, c.ContactId, c.Account__c 
                                From CampaignMember c 
                                Where c.Id IN: campainMembers])   
        {
            system.assert(cm.Account__c == cm.Contact.AccountId);
        }
        
        CampaignMemberManagement_Trigger_Test.updateCampaignMembers(campainMembersToContacts1, contacts2);
        CampaignMemberManagement_Trigger_Test.updateCampaignMembers(campainMembersToContacts2, contacts1);
        
        update campainMembers;
        
        for(CampaignMember cm : [Select c.Contact.AccountId, c.ContactId, c.Account__c 
                                From CampaignMember c 
                                Where c.Id IN: campainMembers])   
        {
            system.assert(cm.Account__c == cm.Contact.AccountId);
        }*/
        
        Test.stopTest();
    }
    
   /* static void updateCampaignMembers(List<CampaignMember> campaignMembers, List<Contact> contacts)
    {
        Integer size = 0;
        
        if(campaignMembers.size() < contacts.size())
        {
            size = campaignMembers.size();
        }
        else
        {
            size = contacts.size();
        }
        
        for(Integer i = 0; i < size; i++)
        {
            CampaignMember campaignMember = campaignMembers[i];
            campaignMember.ContactId = contacts[i].Id;
        }
    }*/
}
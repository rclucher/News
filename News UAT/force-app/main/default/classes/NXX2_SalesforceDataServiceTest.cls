@isTest
public class NXX2_SalesforceDataServiceTest{
    public static testMethod void testUtility() {
        Test.startTest();
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        List<Account> accounts = TestDataFactory.createAccounts(1,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1,Test.getStandardPricebookId(),accounts[0],contacts[0]);
        Order__c campaignOrder = NXX2_TestUtility.createCampaignOrder(opportunities[0].Id, contacts[0].Id, accounts[0].Id);
        List<Product_Order__c> pos = NXX2_TestUtility.createProductOrder(1, campaignOrder.Id);
        SocialCampaign__c proof = NXX2_TestUtility.createProof(pos[0].Id);
        List<Customer_Task__c> activityForCO = NXX2_TestUtility.createCustomerActivityForCampaignOrder(new List<Order__c>{campaignOrder});
        Test.stopTest();
        NXX2_SalesforceDataService.getSocialAdTypes();
        NXX2_SalesforceDataService.getSocialAdCreativeTypes();
        NXX2_SalesforceDataService.findMataDataIsConfiguredForRespectiveObjectOrNot(proof.Id);
        NXX2_SalesforceDataService.getCustomerTaskLists(activityForCO[0].Id, 'SocialCampaign__c', true);
        NXX2_SalesforceDataService.getCustomerTaskLists(activityForCO[0].Id, 'SocialCampaign__c', false);
        NXX2_SalesforceDataService.getCustomerTaskLists(activityForCO[0].Id, 'Order__c', true);        
        NXX2_SalesforceDataService.getCustomerTaskLists(activityForCO[0].Id, 'Product_Order__c', true);
        NXX2_SalesforceDataService.getCustomerTaskLists(activityForCO[0].Id, 'Account', true);
        NXX2_SalesforceDataService.getCustomerTaskLists(activityForCO[0].Id, 'Account', false);
        NXX2_SalesforceDataService.getCustomerTaskLists(activityForCO[0].Id, 'CommunityHomeTasks', true);
        NXX2_SalesforceDataService.getAccountsLists(new List<Id>{accounts[0].Id});
        NXX2_SalesforceDataService.fetchLoggedInUsersDetails();
        NXX2_SalesforceDataService.getMyAccounts(UserInfo.getUserId());
        NXX2_SalesforceDataService.updateCustomerTask(activityForCO[0].Id);
        NXX2_SalesforceDataService.getProofNumber(proof.Id);
        NXX2_SalesforceDataService.getPayerAccountOpportunities(new List<Id>{accounts[0].Id});
        NXX2_SalesforceDataService.getPrimareyAccountOpportunities(new List<Id>{accounts[0].Id});
        NXX2_SalesforceDataService.getProofRecordsAssocatedToAccounts(new Set<String>{accounts[0].Id});
        NXX2_SalesforceDataService.fetchAllContactRolesLinkedToContact(contacts[0].Id);
        NXX2_SalesforceDataService.fetchContactsDetails(new List<Id>{contacts[0].Id});
    }
}
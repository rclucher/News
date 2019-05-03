@isTest
public class NXX2_OverrideButtonControllerTest{
    public static testMethod void testUtility() {
        Test.startTest();
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        List<Account> accounts = TestDataFactory.createAccounts(1,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        insert contacts;
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1,Test.getStandardPricebookId(),accounts[0],contacts[0]);
        insert opportunities;
        Order__c campaignOrder = NXX2_TestUtility.createCampaignOrder(opportunities[0].Id, contacts[0].Id, accounts[0].Id);
        List<Product_Order__c> pos = NXX2_TestUtility.createProductOrder(1,campaignOrder.Id);
        List<SocialCampaign__c> proofs = NXX2_TestUtility.createProofs(pos);
        List<Customer_Task__c> activityForPO = NXX2_TestUtility.createCustomerActivity(proofs);
        Test.stopTest();
        NXX2_OverrideButtonController.getProofRecordTypeId('Social');
        NXX2_OverrideButtonController.getProductOrder(pos[0].Id);
        NXX2_OverrideButtonController.getAllCommentsLinkedToType();
        NXX2_OverrideButtonController.getCustomerTaskRecordType(activityForPO[0].Id);
        try {
            NXX2_OverrideButtonController.resendMailForActivity(activityForPO[0].Id);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid status of the activity to share with the customer!'));
        }
        NXX2_OverrideButtonController.resendMailForActivity(activityForPO[2].Id);
        try {
            NXX2_OverrideButtonController.markActivityAsCompleted(null);
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Server side issue, Please contact to admin.'));
        }
        NXX2_OverrideButtonController.markActivityAsCompleted(activityForPO[2].Id);
    }
}
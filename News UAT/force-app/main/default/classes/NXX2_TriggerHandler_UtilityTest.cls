@isTest
public class NXX2_TriggerHandler_UtilityTest{
    public static testMethod void testTriggerHandler() {
        Test.startTest();
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
        contacts[0].Email = 'NXX2Test123@News.com';
        contacts[0].NewsXtend_My_Account_Access__c = true;
        insert contacts;
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,Test.getStandardPricebookId(),accounts[0],contacts[0]);
        opportunities[0].Payer_Account__c = accounts[1].Id;
        opportunities[1].Payer_Account__c = accounts[2].Id;
        insert opportunities;
        List<String> roles = new List<String>();
        Schema.DescribeFieldResult fieldResult = Contact_Role__c.Role__c.getDescribe();
   		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            roles.add(f.getValue());
        }       
        List<Customer_Role_Access__c> roleAccess = NXX2_TestUtility.createCustomerRoleAccess(roles);
        roleAccess[1].Account_Access__c = 'Public Read/Write';
        insert roleAccess;
        List<Contact_Role__c> contactRoles = NXX2_TestUtility.createContactRole(contacts[0].Id,accounts,roleAccess[0].Contact_Role__c);
        Order__c campaignOrder = NXX2_TestUtility.createCampaignOrder(opportunities[0].Id, contacts[0].Id, accounts[0].Id);
        List<Product_Order__c> pos = NXX2_TestUtility.createProductOrder(1,campaignOrder.Id);
        List<SocialCampaign__c> proofs = NXX2_TestUtility.createProofs(pos);
        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
        name = 'Test');
        insert template;
        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
        name = 'Test',CSPOFA__Orchestration_Process_Template__c = template.Id);
        insert process;
        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
        name = 'Test',CSPOFA__Orchestration_Process__c = process.Id);
        insert step;
        Task task = new Task(
            ActivityDate = Date.today(),
            whatId = pos[0].Id,
            subject = 'Send the content plan to client for approval',
            CSPOFA__Orchestration_Step__c = step.Id
        );
        insert task;
        List<Customer_Task__c> activityForCO = NXX2_TestUtility.createCustomerActivityForCampaignOrder(new List<Order__c>{campaignOrder});
        List<Customer_Task__c> activityForPO = NXX2_TestUtility.createCustomerActivityForProductOrder(pos);
        List<Customer_Task__c> activityForProof = NXX2_TestUtility.createCustomerActivity(proofs);
        Test.stopTest();
        NXX2_OpportunityTriggerHandler handler = new  NXX2_OpportunityTriggerHandler();
        Map<Id, Opportunity> newItems = new Map<Id, Opportunity>();
        newItems.put(opportunities[0].Id, opportunities[0]);
        Map<Id, Opportunity> oldItems = new Map<Id, Opportunity>();
        oldItems.put(opportunities[0].Id, opportunities[1]);
        handler.AfterInsert(newItems);
        handler.AfterUpdate(newItems, oldItems);
        NXX2_ProofTriggerHandler handler1 = new  NXX2_ProofTriggerHandler();
        proofs = [SELECT Status__c,Visible_To_Customer__c,Product_Order__c FROM SocialCampaign__c];
        Map<Id, SocialCampaign__c> newItems1 = new Map<Id, SocialCampaign__c>();
        Map<Id, SocialCampaign__c> oldItems1 = new Map<Id, SocialCampaign__c>();
        newItems1.put(proofs[1].Id, proofs[1]);
        oldItems1.put(proofs[1].Id, proofs[0]);
        newItems1.put(proofs[2].Id, proofs[2]);
        oldItems1.put(proofs[2].Id, proofs[0]);
        handler1.AfterUpdate(newItems1, oldItems1);
        NXX2_CustomerActivityTriggerHandler handler2 = new  NXX2_CustomerActivityTriggerHandler();
        Map<Id, Customer_Task__c> newItems2 = new Map<Id, Customer_Task__c>();
        newItems2.put(activityForCO[0].Id, activityForCO[0]);
        newItems2.put(activityForPO[0].Id, activityForPO[0]);
        newItems2.put(activityForProof[0].Id, activityForProof[0]);
        newItems2.put(activityForProof[1].Id, activityForProof[1]);
        handler2.AfterInsert(newItems);
    }
}
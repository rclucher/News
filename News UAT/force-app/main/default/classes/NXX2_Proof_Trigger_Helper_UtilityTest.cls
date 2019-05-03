@isTest
public class NXX2_Proof_Trigger_Helper_UtilityTest{
    public static testMethod void testTriggerHandler() {
        Test.startTest();
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        NXX2_TestUtility.insertProofSetting();
        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;
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
        List<csmso__Product_Node__c> nodes = NXX2_TestUtility.createProductNodes(2);
        List<Product_Order__c> pos = NXX2_TestUtility.createProductOrderWithProductNodes(campaignOrder.Id,nodes);
        NXX2_TestUtility.createCreative(pos[1].Id,'Premedia');
        List<SocialCampaign__c> proofs = NXX2_TestUtility.createProofs(pos);
        Test.stopTest();
        
        NXX2_ProofTriggerHandler handler = new  NXX2_ProofTriggerHandler();
        proofs = [SELECT Status__c,Visible_To_Customer__c,Product_Order__c FROM SocialCampaign__c];
        Map<Id, SocialCampaign__c> newItems = new Map<Id, SocialCampaign__c>();
        Map<Id, SocialCampaign__c> oldItems = new Map<Id, SocialCampaign__c>();
        newItems.put(proofs[1].Id, proofs[1]);
        oldItems.put(proofs[1].Id, proofs[0]);
        newItems.put(proofs[2].Id, proofs[2]);
        oldItems.put(proofs[2].Id, proofs[0]);
        newItems.put(proofs[4].Id, proofs[4]);
        oldItems.put(proofs[4].Id, proofs[3]);
        newItems.put(proofs[5].Id, proofs[5]);
        oldItems.put(proofs[5].Id, proofs[3]);
        handler.AfterUpdate(newItems, oldItems);
    }
}
@isTest
public class NXX2_CustomerActivityTriggerHandlerTest{
    public static testMethod void testTriggerHandler() {
        Test.startTest();
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        NXX2_TestUtility.insertProofSetting();
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
        List<Product_Order__c> pos = NXX2_TestUtility.createProductOrder(1, campaignOrder.Id);
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
        SocialCampaign__c proof = NXX2_TestUtility.createProof(pos[0].Id);
        List<Customer_Task__c> activityForCO = NXX2_TestUtility.createCustomerActivityForCampaignOrder(new List<Order__c>{campaignOrder});
        List<Customer_Task__c> activityForPO = NXX2_TestUtility.createCustomerActivityForProductOrder(pos);
        List<Customer_Task__c> activityForProof = NXX2_TestUtility.createCustomerActivity(new List<SocialCampaign__c>{proof});
        Test.stopTest();
        NXX2_CustomerActivityTriggerHandler handler = new  NXX2_CustomerActivityTriggerHandler();
        Map<Id, Customer_Task__c> newItems = new Map<Id, Customer_Task__c>();
        newItems.put(activityForCO[0].Id, activityForCO[0]);
        newItems.put(activityForPO[0].Id, activityForPO[0]);
        newItems.put(activityForProof[0].Id, activityForProof[0]);
        newItems.put(activityForProof[1].Id, activityForProof[1]);
        handler.IsDisabled();
        handler.AfterDelete(null);
        handler.AfterInsert(newItems);
        handler.AfterUndelete(null);
        handler.AfterUpdate(null, null);
        handler.BeforeDelete(null);
        handler.BeforeInsert(null);
        handler.BeforeUpdate(null, null);
    }
}
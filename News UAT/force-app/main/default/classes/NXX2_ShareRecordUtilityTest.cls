@isTest
public class NXX2_ShareRecordUtilityTest{
    public static testMethod void testTriggerHandler() {
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        User currentUser = TestDataFactory.createUser('System Administrator','Test','Demo',null,false,false);
        System.runAs(currentUser){
            Test.startTest();
            UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
            Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
            User portalAccountOwner1 = new User(
                UserRoleId = portalRole.Id,
                ProfileId = profile1.Id,
                Username = System.now().millisecond() + 'test2@test.com',
                Alias = 'batman',
                Email='test@testSalesforce.com',
                EmailEncodingKey='UTF-8',
                Firstname='Bruce',
                Lastname='Wayne',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='America/Chicago'
            );
            insert portalAccountOwner1;
            List<Account> accounts = TestDataFactory.createAccounts(3,false);
            accounts[0].ownerId = portalAccountOwner1.Id;
            accounts[1].ownerId = portalAccountOwner1.Id;
            accounts[2].ownerId = portalAccountOwner1.Id;
            insert accounts;
            List<Contact> contacts = TestDataFactory.createContacts(2,accounts[0]);
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
            SocialCampaign__c proof = NXX2_TestUtility.createProof(pos[0].Id);
            List<Customer_Task__c> activityForCO = NXX2_TestUtility.createCustomerActivityForCampaignOrder(new List<Order__c>{campaignOrder});
            List<Customer_Task__c> activityForPO = NXX2_TestUtility.createCustomerActivityForProductOrder(pos);
            List<Customer_Task__c> activityForProof = NXX2_TestUtility.createCustomerActivity(new List<SocialCampaign__c>{proof});
            
            Test.stopTest();
            NXX2_Contact_Role_TriggerHandler handler = new  NXX2_Contact_Role_TriggerHandler();
            Map<Id, Contact_Role__c> newItems = new Map<Id, Contact_Role__c>();
            Map<Id, Contact_Role__c> oldItems = new Map<Id, Contact_Role__c>();
            newItems.put(contactRoles[0].Id, contactRoles[0]);
            oldItems.put(contactRoles[0].Id, contactRoles[1]);
            handler.AfterDelete(oldItems);
            handler.AfterInsert(newItems);
            handler.AfterUpdate(newItems, oldItems);
            handler.BeforeInsert(newItems.values());
            
            NXX2_AccountTriggerHandler handler1 = new  NXX2_AccountTriggerHandler();
            Map<Id, Account> newItems1 = new Map<Id, Account>();
            Map<Id, Account> oldItems1 = new Map<Id, Account>();
            newItems1.put(accounts[0].Id, accounts[0]);
            oldItems1.put(accounts[0].Id, accounts[2]);
            handler1.AfterUpdate(newItems1, oldItems1);
            
            NXX2_Contact_TriggerHandler handler2 = new NXX2_Contact_TriggerHandler();
            Map<Id, Contact> newItems2 = new Map<Id, Contact>();
            Map<Id, Contact> oldItems2 = new Map<Id, Contact>();
            newItems2.put(contacts[0].Id, contacts[0]);
            oldItems2.put(contacts[0].Id, contacts[1]);
            newItems2.put(contacts[1].Id, contacts[1]);
            oldItems2.put(contacts[1].Id, contacts[0]);
            handler2.AfterUpdate(newItems2, oldItems2);
            NXX2_ShareRecordUtility nXX2_ShareRecordUtility =  new NXX2_ShareRecordUtility(new Set<Id>{contacts[0].Id,contacts[1].Id},newItems2);
        	System.enqueueJob(nXX2_ShareRecordUtility);
            
            Map<Id, Contact> contactItems = new Map<Id, Contact>();
            contactItems.put(contacts[0].Id, contacts[0]);
            NXX2_ShareRecordUtility utility = new NXX2_ShareRecordUtility(new Set<Id>{contacts[0].Id},contactItems);
            List<AccountShare> accountShareList = [SELECT Id From AccountShare];
            List<Customer_Task__Share> customerTaskShareList = [SELECT Id From Customer_Task__Share];
            List<SocialCampaign__Share> socialCampaignShareList = [SELECT Id From SocialCampaign__Share];
            
            utility.deleteAccountShareRecords(accountShareList);
            utility.deleteCustomerTaskShareRecords(customerTaskShareList);
            utility.deleteProofShareRecords(socialCampaignShareList);
        }
    }
}
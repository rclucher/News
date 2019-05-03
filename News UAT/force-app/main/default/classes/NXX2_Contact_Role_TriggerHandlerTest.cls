@isTest
public class NXX2_Contact_Role_TriggerHandlerTest{
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
            
            Test.stopTest();
            NXX2_Contact_Role_TriggerHandler handler = new  NXX2_Contact_Role_TriggerHandler();
            Map<Id, Contact_Role__c> newItems = new Map<Id, Contact_Role__c>();
            Map<Id, Contact_Role__c> oldItems = new Map<Id, Contact_Role__c>();
            newItems.put(contactRoles[0].Id, contactRoles[0]);
            oldItems.put(contactRoles[0].Id, contactRoles[1]);
            handler.IsDisabled();
            handler.AfterDelete(oldItems);
            handler.AfterInsert(newItems);
            handler.AfterUndelete(null);
            handler.AfterUpdate(newItems, oldItems);
            handler.BeforeDelete(null);
            handler.BeforeInsert(newItems.values());
            handler.BeforeUpdate(null, null);
        }
    }
}
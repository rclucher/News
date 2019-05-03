@isTest
public class NXX2_CustomerRAccessTriggerHandlerTest{
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
        Test.stopTest();
        NXX2_CustomerRoleAccessTriggerHandler handler = new  NXX2_CustomerRoleAccessTriggerHandler();
        Map<Id, Customer_Role_Access__c> newItems = new Map<Id, Customer_Role_Access__c>();
        newItems.put(roleAccess[0].Id, roleAccess[0]);
        Map<Id, Customer_Role_Access__c> oldItems = new Map<Id, Customer_Role_Access__c>();
        oldItems.put(roleAccess[0].Id, roleAccess[1]);
        handler.IsDisabled();
        handler.AfterDelete(null);
        handler.AfterInsert(newItems);
        handler.AfterUndelete(null);
        handler.AfterUpdate(newItems, oldItems);
        handler.BeforeDelete(null);
        handler.BeforeInsert(null);
        handler.BeforeUpdate(null, null);
    }
}
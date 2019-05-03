@isTest
public class NXX2_Contact_TriggerHandlerTest{
    public static testMethod void testTriggerHandler() {
        Test.startTest();
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        List<Account> accounts = TestDataFactory.createAccounts(3,false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(2,accounts[0]);
        contacts[0].Email = 'NXX2Test123@News.com';
        contacts[0].NewsXtend_My_Account_Access__c = true;
        insert contacts;
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
        NXX2_Contact_TriggerHandler handler = new NXX2_Contact_TriggerHandler();
        Map<Id, Contact> newItems = new Map<Id, Contact>();
        Map<Id, Contact> oldItems = new Map<Id, Contact>();
        newItems.put(contacts[0].Id, contacts[0]);
        oldItems.put(contacts[0].Id, contacts[1]);
        newItems.put(contacts[1].Id, contacts[1]);
        oldItems.put(contacts[1].Id, contacts[0]);
        handler.IsDisabled();
        handler.AfterDelete(null);
        handler.AfterInsert(null);
        handler.AfterUndelete(null);
        handler.AfterUpdate(newItems, oldItems);
        handler.BeforeDelete(null);
        handler.BeforeInsert(null);
        handler.BeforeUpdate(null, null);
    }
}
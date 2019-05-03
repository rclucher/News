@isTest
public class NXX2_ProcessMyAccountUserTest{
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
            List<Account> accounts = TestDataFactory.createAccounts(1,false);
            accounts[0].ownerId = portalAccountOwner1.Id;
            insert accounts;
            List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
            contacts[0].Email = 'NXX2Test123@News.com';
            contacts[0].NewsXtend_My_Account_Access__c = true;
            insert contacts;
            User user = NXX2_TestUtility.createPortalUser(contacts[0]);
            Map<Id, Contact> newItems = new Map<Id, Contact>();
            newItems.put(contacts[0].Id, contacts[0]);
            NXX2_ProcessMyAccountUser myAccount = new NXX2_ProcessMyAccountUser(
                new List<User>{user},new Set<Id>{contacts[0].Id},newItems
            );
            System.enqueueJob(myAccount);
            Test.stopTest();
        }
    }
}
@isTest
public class NXX2_AccountTriggerHandlerTest{
    public static testMethod void testTriggerHandler() {
        Test.startTest();
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        List<Account> accounts = TestDataFactory.createAccounts(1,false);
        insert accounts;
        Test.stopTest();
        NXX2_AccountTriggerHandler handler = new  NXX2_AccountTriggerHandler();
        Map<Id, Account> newItems = new Map<Id, Account>();
        Map<Id, Account> oldItems = new Map<Id, Account>();
        newItems.put(accounts[0].Id, accounts[0]);
        oldItems.put(accounts[0].Id, accounts[0]);
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
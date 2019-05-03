@isTest
public class UpdateECommerceIdTest {
    @isTest
    public static void testECommerceIdbatch() {
        No_Triggers__c setting = new No_Triggers__c();
        setting.SetupOwnerId = UserInfo.getUserId();
        setting.Flag__c = true;
        insert setting;
        Account acc = TestDataSetupClass.createAccount();
        acc.AdPoint_Id__c = 'TestId';
        acc.csb2c__E_Commerce_Customer_Id__c = null;
        insert acc;
        
        Test.startTest();
        UpdateECommerceId ber = new UpdateECommerceId();
        Database.executeBatch(ber);
        Test.stopTest();
        system.debug(acc);
        
        Account acco = [select id, csb2c__E_Commerce_Customer_Id__c from account where id =: acc.Id limit 1];
        system.assert (acco.csb2c__E_Commerce_Customer_Id__c == 'TestId', 'Incorrect E Commerce Customer Id');
    }

}
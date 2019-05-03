@isTest
public class AT_ListView_Test {
	@isTest
    static void testObjectInfo() {
        AT_ListView.ObjectInfo info = AT_ListView.getObjectInfo('Customer_Account_Credit_Status');
        
        System.AssertEquals('Account', info.name);
    }
    
    @isTest
    static void testConfigs() {
        List<String> configs = AT_ListView.getConfigs();
        
        System.assertNotEquals(null, configs);
        System.assertNotEquals(0, configs.size());
    }
    
    @isTest
    static void testCustomerAccountCreditStatus() {
        RecordType accountRT = [SELECT Id FROM RecordType WHERE (SObjectType = 'Account') AND (DeveloperName = 'SME') LIMIT 1];
        
        Account acc1 = new Account(Name = 'Test', No_Parent_Account__c = true, RecordTypeId = accountRT.Id);
        
        insert acc1;
        
        AT_ListView.getSummary('Customer_Account_Credit_Status');
        
        AT_ListView.getRecords('Customer_Account_Credit_Status', 'compact', 10, 10, 1);
    }
    
    @isTest
    static void testDatasource() {
        AT_ListView lv = new AT_ListView();
        lv.getDefaultValue();
        lv.getValues();
    }
}
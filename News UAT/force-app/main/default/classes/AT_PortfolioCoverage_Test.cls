@isTest
public class AT_PortfolioCoverage_Test {
	@isTest
    static void testPortfolioCoverage() {
        RecordType accountRT = [SELECT Id FROM RecordType WHERE (SObjectType = 'Account') AND (DeveloperName = 'SME') LIMIT 1];
        
        Account acc = new Account(Name = 'Test', No_Parent_Account__c = true, RecordTypeId = accountRT.Id);
        insert acc;
        
        Portfolio2__c port = new Portfolio2__c(Name = 'test');
        insert port;
        
        Portfolio_Owners__c owner = new Portfolio_Owners__c(Portfolio2__c = port.Id, Portfolio_Owner__c = UserInfo.getUserId());
        insert owner;
        
        Account_Portfolio_Relationship__c apr = new Account_Portfolio_Relationship__c(Account__c = acc.Id, Portfolio__c = port.Id);
        insert apr;
        
        AT_PortfolioCoverage.getCoverage();
    }
}
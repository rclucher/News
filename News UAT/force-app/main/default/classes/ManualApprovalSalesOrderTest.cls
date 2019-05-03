@isTest(seeAllData=false)
public class ManualApprovalSalesOrderTest {
    
    @isTest 
    public static void ManualApprovalSO_MarginTooLowTest(){
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'Draft';
        so.Platform_Set__c  = '{Xtend}';
        so.Basket_Products__c  = '[News Xtend]';
        so.Margin__c = 0.1;
        insert so;
        
        Test.startTest();        
        ManualApprovalSalesOrder masoClass = new ManualApprovalSalesOrder();
        String str = so.Id;
        String paStr = masoClass.performAction(str);
        Test.stopTest();
    }
    
    @isTest 
    public static void ManualApprovalSO_CompleteTest(){
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'Draft';
        so.Platform_Set__c  = '{Xtend}';
        so.Basket_Products__c  = '[News Xtend]';
         so.Margin__c = 0.80;
        insert so;
        
        Test.startTest();        
        ManualApprovalSalesOrder masoClass = new ManualApprovalSalesOrder();
        String str = so.Id;
        String paStr = masoClass.performAction(str);
        Test.stopTest();
    }
    
        @isTest 
    public static void ManualApprovalSO_totalImp(){
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'Draft';
            so.Platform_Set__c  = '{Xtend}';
            so.Basket_Products__c  = '[News Xtend]';
        so.Margin__c = 0.80;
        so.Total_Impressions__c = 3.5;
        insert so;
        
        Test.startTest();        
        ManualApprovalSalesOrder masoClass = new ManualApprovalSalesOrder();
        String str = so.Id;
        String paStr = masoClass.performAction(str);
        Test.stopTest();
    }
    
}
@isTest(seeAllData=false)
public class StandardSalesOrderStateManagerTest {

    @isTest 
    public static void validateChangeTest(){
        
        Account acc = TestDataSetupClass.createAccount();
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        insert so;
        
        Test.startTest();
        StandardSalesOrderStateManager ssomClass = new StandardSalesOrderStateManager();
        ssomClass.validateChange(so);
        Test.stopTest();
    }
    
    @isTest 
    public static void getFieldAttributesForSalesOrder_AgencyTest(){
        
        Account acc = TestDataSetupClass.createAccount();
        //acc.Type_of_Account__c = 'Agency';
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        //so.Billed_to_Account__c = acc.Id;
       //so.Billed_to_Account_Type__c = 'Agency';
        so.csmso__Status__c = 'Draft';
        insert so;
        //so = [Select csmso__Status__c,csmso__Booking_Contact__c from csmso__Sales_Order__c where Billed_to_Account__c=:acc.Id];
        
        
        Test.startTest();
        StandardSalesOrderStateManager ssomClass = new StandardSalesOrderStateManager();
        ssomClass.getFieldAttributesForSalesOrder(so);
        Test.stopTest();
    }
    
    @isTest 
    public static void getFieldAttributesForSalesOrder_AdvertiserTest(){
        
        Account acc = TestDataSetupClass.createAccount();
        //acc.Type_of_Account__c = 'Advertiser';
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
       // so.Billed_to_Account__c = acc.Id;
       //so.Billed_to_Account_Type__c = 'Agency';
        so.csmso__Status__c = 'Draft';
        insert so;
        //so = [Select csmso__Status__c,csmso__Booking_Contact__c from csmso__Sales_Order__c where Billed_to_Account__c=:acc.Id];
        
        Test.startTest();
        StandardSalesOrderStateManager ssomClass = new StandardSalesOrderStateManager();
        ssomClass.getFieldAttributesForSalesOrder(so);
        Test.stopTest();
    }
}
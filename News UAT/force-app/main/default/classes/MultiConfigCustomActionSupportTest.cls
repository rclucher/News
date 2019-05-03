@isTest(seeAllData=false)
public class MultiConfigCustomActionSupportTest {

    
    @isTest 
    public static void MultiConfig_ProdBasketTest(){
        
        Account acc = TestDataSetupClass.createAccount();
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        insert so;
        
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        Test.startTest();        
        MultiConfigurationCustomActionSupport bpcarClass = new MultiConfigurationCustomActionSupport();
        String str = so.Id;
        String paStr = bpcarClass.performAction(str);
        Test.stopTest();
    }
    
    @isTest 
    public static void MultiConfig_NoProdBasketTest(){
        
        Account acc = TestDataSetupClass.createAccount();
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        insert so;
        
        //cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        //insert prodBasket;
        
        Test.startTest();        
        MultiConfigurationCustomActionSupport bpcarClass = new MultiConfigurationCustomActionSupport();
        String str = so.Id;
        String paStr = bpcarClass.performAction(str);
        Test.stopTest();
    }
}
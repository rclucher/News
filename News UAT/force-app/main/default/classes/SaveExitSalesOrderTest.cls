@isTest
public class SaveExitSalesOrderTest {
    
    @isTest 
    public static void SaveExitSalesOrder_InvalidTest(){
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc,opp);
        //so.csmso__Opportunity__c = null;       
        insert so;
        
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        cscfga__Product_Configuration__c prodConfig1 = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig1.cscfga__Configuration_Status__c = 'Incomplete';
        insert prodConfig1;
        
        cscfga__Product_Configuration__c prodConfig2 = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig2.cscfga__Configuration_Status__c = 'Incomplete';
        insert prodConfig2;
        
        Test.startTest();        
        SaveExitSalesOrder sesoClass = new SaveExitSalesOrder();
        String str = so.Id;
        so = [Select id, (Select Id from csmso__Product_Baskets__r)from csmso__Sales_Order__c where id =: so.id ];
        Integer numOfInvalidConfig=[select count () from cscfga__Product_Configuration__c where cscfga__Configuration_Status__c !='Valid' and cscfga__Product_Basket__c=:so.csmso__Product_Baskets__r.get(0).Id];
        System.assertEquals(numOfInvalidConfig,2);
        String paStr = sesoClass.performAction(str);
        Test.stopTest();
    }
    
    @isTest(seeAllData=true)
    public static void SaveExitSalesOrder_validTest(){
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc,opp);
        //so.csmso__Opportunity__c = null;       
        insert so;
        
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
            
        cscfga__Product_Configuration__c prodConfig1 = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig1.cscfga__Configuration_Status__c = 'Valid';
        prodConfig1.cscfga__Product_Definition__c = testProDef.id;
        insert prodConfig1;
        
        cscfga__Product_Configuration__c prodConfig2 = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig2.cscfga__Configuration_Status__c = 'Valid';
        prodConfig2.cscfga__Product_Definition__c = testProDef.id;
        insert prodConfig2;
        
        
        
        
        
        
        Test.startTest();        
        SaveExitSalesOrder sesovClass = new SaveExitSalesOrder();
        String str = so.Id;
        
        String paStr = sesovClass.performAction(str);
        Test.stopTest();
    }
}
@isTest(seeAllData=true)
public class CS_AllProductBasketTriggersTest {

    @isTest 
    public static void fieldTest(){
        /* Get data created in TestDataSetupClass class
        call the required methods from TestDataSetupClass class*/
        
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        insert so;
        
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig.Bundle_Name__c = 'Test Bundle Name';
        insert prodConfig;

        cscfga__Product_Configuration__c prodConfig2 = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig2.cscfga__Parent_Configuration__c = prodConfig.Id;
        insert prodConfig2;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;        
    
    }
    
}
//Marko comment
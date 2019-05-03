@isTest(seeAllData=true)
public class AttachIOSalesOrderTest {
    
    @isTest(seeAllData=true)
    public static void AttachIOSalesOrder_validTest(){
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
        AttachIOSalesOrder attachIO = new AttachIOSalesOrder();
        String str = so.Id;
        
        String paStr = attachIO.performAction(str);
        Test.stopTest();
    }
}
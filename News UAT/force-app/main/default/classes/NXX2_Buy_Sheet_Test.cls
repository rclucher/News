/*------------------------------------------------------------
Author:        Rinaldo Clucher
Company:       Salesforce
Description:   Test Class to test NXX2_Buy_Sheet which populates
			    BuySheet specific fields in the Product Order Object.

History
<Date>      <Authors Name>     <Brief Description of Change>
13/11/2018  Rinaldo Clucher        Created
------------------------------------------------------------*/

@isTest(seeAllData=false)
public class NXX2_Buy_Sheet_Test  {

    // Setup all the objects to enable the operation of Reset Busy SHeet Extracted Flag process
    // This will in turn execute NXX2 Buy SHeet class. 
    @testSetup static void buySheetDataSetup()
    {
        System.debug('*** Create List bhs');

        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        System.assert(bhs.size() == 1);

        System.debug('*** Create Sales Order API');

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        System.debug('*** Inserted Sales Order API');

        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
        insert bu;

        csmso__Product_Node__c pn = TestDataSetupClass.createProductNode('TestPNName', bu);
        insert pn;

        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'Externally Approved';
        insert so;

        Order__c order = TestDataSetupClass.createOrder(opp);
        order.Proposed_Start_Date__c = Date.Today();
        order.Sales_Order__c = so.Id;
        insert order;

        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig.Platform__c = 'Xtend';
        insert prodConfig;

        Product_Order__c pOrd = new Product_Order__c(Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
                                                     Order__c = order.Id,
                                                     Product_Configuration__c = prodConfig.id,
                                                     Product_Node__c = pn.id,
                                                     Status__c = 'In Progress');
        insert pOrd;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Attribute_Definition__c testAttrDef1 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef1.Name= 'Product Groups For IO';
        insert testAttrDef1;
        
        cscfga__Attribute_Definition__c testAttrDef2 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef2.Name= 'Product Type Name';
        insert testAttrDef2;
        
        cscfga__Attribute_Definition__c testAttrDef3 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef3.Name= 'Network Name';
        insert testAttrDef3;
        
        cscfga__Attribute_Definition__c testAttrDef4 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef4.Name= 'Discount';
        insert testAttrDef4;
        
        cscfga__Attribute__c testAttr1 = new cscfga__Attribute__c(name = 'Product Groups For IO', cscfga__Product_Configuration__c= prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef1.Id, cscfga__Value__c = '1000');
        insert testAttr1;
        
        cscfga__Attribute__c testAttr2 = new cscfga__Attribute__c(name = 'Product Type Name', cscfga__Product_Configuration__c= prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef2.Id, cscfga__Value__c = 'Catch Up TV');
        insert testAttr2;
        
        cscfga__Attribute__c testAttr3 = new cscfga__Attribute__c(name = 'Network Name', cscfga__Product_Configuration__c= prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef3.Id, cscfga__Value__c = 'The Trade Desk');
        insert testAttr3;
        
        cscfga__Attribute__c testAttr4 =new cscfga__Attribute__c(name = 'Discount', cscfga__Product_Configuration__c= prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef4.Id, cscfga__Value__c = '0.00');
        insert testAttr4;
        
        cscfga__Product_Basket__c prodBasketUpdate = [Select Id, csmso__Sales_Order__c from cscfga__Product_Basket__c];
        prodBasketUpdate.csmso__Sales_Order__c = so.Id;
        update prodBasketUpdate;
        

}

    // Tests operation of NXX2 Buy Sheet Class
    @isTest
    public static void processBuysheet() {
        
        
        System.debug('*** Product Orders Before Setup');                
        
        // Set campaign to Live

        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        list <Id> poIds = new list <Id> ();
        for (Product_Order__c po : [SELECT Id FROM Product_Order__c ]){
            poIds.add(po.id);
        }
        
        Test.startTest();
        
        NXX2_Buy_Sheet.SetProductFields(poIds);

        Test.stopTest();

        List <Product_Order__c> poOutput = [Select Id, status__c, Product_Node__c, Proposed_Start_Date__c, 
                                     Discount__c, Product_Type_Name__c, Product_Name__c, Network_Name__c,
                                     Cost_Model__c, Product_Configuration__c from Product_Order__c];
        System.debug('*** Number of Product Orders : ' + poOutput.size());
        System.debug('*** Product Order Details : ' + poOutput);
        
        System.assert(poOutput[0].Product_Type_Name__c == 'Catch Up TV'); 
        System.assert(poOutput[0].Network_Name__c == 'The Trade Desk'); 
        System.assert(poOutput[0].Discount__c == '0.00'); 

     }     
   
}
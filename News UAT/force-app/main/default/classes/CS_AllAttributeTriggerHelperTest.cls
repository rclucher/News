@isTest(seeAllData=false)
public class CS_AllAttributeTriggerHelperTest {
    @isTest
    private static void addAttrTest() {
    
        /* Get data created in TestDataSetupClass class
        call the required methods from TestDataSetupClass class*/
        
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

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
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket );
        insert prodConfig;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);  
        testAttrDef.cscfga__Data_Type__c = 'Decimal';
        testAttrDef.cscfga__configuration_output_mapping__c = 'Total_Cost__c';
        insert testAttrDef;
        testAttrDef = [Select cscfga__Data_Type__c from cscfga__Attribute_Definition__c where id =: testAttrDef.Id];
        System.debug('**data type' + testAttrDef.cscfga__Data_Type__c);
        
        cscfga__Attribute__c testAttr = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr.cscfga__Product_Configuration__c = prodConfig.Id;   
        
        testAttr.cscfga__Value__c = '1000';
        insert testAttr;       
    }
    
    @isTest
    private static void beforeUpdateInsertTest() {
    
        /* Get data created in TestDataSetupClass class
        call the required methods from TestDataSetupClass class*/
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        Map<Id, cscfga__Attribute__c> testSnewAttMap = new Map<Id, cscfga__Attribute__c>();
        Map<Id, cscfga__Attribute__c> testSoldAttMap = new Map<Id, cscfga__Attribute__c>();
     
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
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket );
        insert prodConfig;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);  
        testAttrDef.cscfga__Data_Type__c = 'Decimal';
        testAttrDef.cscfga__configuration_output_mapping__c = 'Total_Cost__c';
        insert testAttrDef;
        testAttrDef = [Select cscfga__Data_Type__c from cscfga__Attribute_Definition__c where id =: testAttrDef.Id];
        System.debug('**data type' + testAttrDef.cscfga__Data_Type__c);


        cscfga__Attribute_Definition__c testAttrDef2 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef2.cscfga__Data_Type__c = 'String';
        testAttrDef2.cscfga__configuration_output_mapping__c = 'Product_ID__c';
        insert testAttrDef2;
        testAttrDef2 = [Select cscfga__Data_Type__c from cscfga__Attribute_Definition__c where id =: testAttrDef2.Id];
        System.debug('**data type' + testAttrDef2.cscfga__Data_Type__c);
        
         // COMMENTED FOR UPGRADE, SHABU
        News_Xtend_Product_Ref__c testNewsXtendIORef1 = TestDataSetupClass.createNewsXtendProductRef();
        insert testNewsXtendIORef1;

        csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
        insert bu;

        csmso__Product_Node__c testProductNode1 = TestDataSetupClass.createProductNode('Prod Node 1', bu);
        insert testProductNode1;
        
         // COMMENTED FOR UPGRADE, SHABU
        //News_Xtend_Product_Ref__c testNewsXtendIORef2 = TestDataSetupClass.createNewsXtendProductRef();
        //insert testNewsXtendIORef2;
        csmso__Product_Node__c testProductNode2 = TestDataSetupClass.createProductNode('Prod Node 2', bu);
        insert testProductNode2;
        
        cscfga__Attribute__c testAttr = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr.cscfga__Product_Configuration__c = prodConfig.Id;           
        testAttr.cscfga__Value__c = '1000';
        testAttr.Name = 'Quantity or Invoice Price';
        insert testAttr;        
       
        cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef2);
        testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;           
        testAttr1.cscfga__Value__c = testProductNode1.Id;
        testAttr1.Name = 'Product';
        insert testAttr1;

        cscfga__Attribute__c testAttr2 = testAttr1.clone();
        testAttr2.cscfga__Value__c =  String.valueOf(testProductNode2.Id);



        cscfga__Attribute__c testAttr3 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef2);
        testAttr3.cscfga__Product_Configuration__c = prodConfig.Id;
        testAttr3.cscfga__Value__c = testNewsXtendIORef1.Id;
        testAttr3.Name = 'Provider';
        insert testAttr3;

        testSoldAttMap.put(testAttr1.id,testAttr2);
        testSoldAttMap.put(testAttr3.id,testAttr2);

        testSnewAttMap.put(testAttr.id,testAttr);
        testSnewAttMap.put(testAttr1.id,testAttr1);
        testSnewAttMap.put(testAttr3.id,testAttr3);



        Test.startTest();
        CS_AllAttributeTriggerHelper asoClass = new CS_AllAttributeTriggerHelper();
        CS_AllAttributeTriggerHelper.AddAttr(new list<cscfga__Attribute__c> {testAttr1});
        CS_AllAttributeTriggerHelper.beforeUpdate(testSnewAttMap,testSoldAttMap);
        Test.stopTest();
        
    }
    
    @isTest
    private static void beforeUpdateInsertTest_Int() {
    
        /* Get data created in TestDataSetupClass class
        call the required methods from TestDataSetupClass class*/
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;
        
        Map<Id, cscfga__Attribute__c> testSnewAttMap = new Map<Id, cscfga__Attribute__c>();
        Map<Id, cscfga__Attribute__c> testSoldAttMap = new Map<Id, cscfga__Attribute__c>();
     
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
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket );
        insert prodConfig;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);  
        testAttrDef.cscfga__Data_Type__c = 'Integer';
        testAttrDef.cscfga__configuration_output_mapping__c = 'Total_Impressions__c';
        insert testAttrDef;
        testAttrDef = [Select cscfga__Data_Type__c from cscfga__Attribute_Definition__c where id =: testAttrDef.Id];
        System.debug('**data type' + testAttrDef.cscfga__Data_Type__c);
        
        // COMMENTED FOR UPGRADE, SHABU
        //News_Xtend_Product_Ref__c testNewsXtendIORef1 = TestDataSetupClass.createNewsXtendProductRef();
        //insert testNewsXtendIORef1;

        csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
        insert bu;


        csmso__Product_Node__c testProductNode1 = TestDataSetupClass.createProductNode('Product Node 1', bu);
        insert testProductNode1;
        
         // COMMENTED FOR UPGRADE, SHABU
        //News_Xtend_Product_Ref__c testNewsXtendIORef2 = TestDataSetupClass.createNewsXtendProductRef();
        //insert testNewsXtendIORef2;
        csmso__Product_Node__c testProductNode2 = TestDataSetupClass.createProductNode('Product Node 2', bu);
        insert testProductNode2;
        
        cscfga__Attribute__c testAttr = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr.cscfga__Product_Configuration__c = prodConfig.Id;           
        testAttr.cscfga__Value__c = '1000';
        testAttr.Name = 'Quantity or Invoice Price';
        insert testAttr;        
       
        cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;           
        testAttr1.cscfga__Value__c = '1001';
        testAttr1.Name = 'Product';
        insert testAttr1; 
     
        testSnewAttMap.put(testAttr.id,testAttr);
        testSnewAttMap.put(testAttr1.id,testAttr1);
        
        cscfga__Attribute__c testAttr2 = testAttr1.clone();
        testAttr1.cscfga__Value__c =  String.valueOf(testProductNode2.Id);
        
        testSoldAttMap.put(testAttr1.id,testAttr1);
        Test.startTest();
        CS_AllAttributeTriggerHelper asoClass = new CS_AllAttributeTriggerHelper();
        CS_AllAttributeTriggerHelper.beforeUpdate(testSnewAttMap,testSoldAttMap);
        CS_AllAttributeTriggerHelper.AddAttr(new list<cscfga__Attribute__c> {testAttr1});
        //cover trigger
        update testAttr1;
        Test.stopTest();
        
    }
    
}
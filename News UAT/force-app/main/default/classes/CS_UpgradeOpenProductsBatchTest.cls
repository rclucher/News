@isTest
private class CS_UpgradeOpenProductsBatchTest {
    
    @testSetup static void prepareTest() {

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
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig.cscfga__Product_Definition__c = testProDef.Id;
        insert prodConfig;

        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);  
        testAttrDef.cscfga__Data_Type__c = 'String';
        insert testAttrDef;
        
        cscfga__Attribute_Definition__c testAttrDef1 = TestDataSetupClass.createAttrDef(testProDef);  
        testAttrDef1.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef1;     
        
          cscfga__Attribute_Definition__c testAttrDef3 = TestDataSetupClass.createAttrDef(testProDef);  
        testAttrDef3.cscfga__Data_Type__c = 'Integer';
        insert testAttrDef3;     
        
                cscfga__Attribute_Definition__c testAttrDef4 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef4.cscfga__Data_Type__c = 'String';
        insert testAttrDef4;  
        
                        cscfga__Attribute_Definition__c testAttrDef5 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef5.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef5;    
        
                         cscfga__Attribute_Definition__c testAttrDef6 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef6.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef6;


                cscfga__Attribute_Definition__c testAttrDef7 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef7.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef7;


        cscfga__Attribute_Definition__c testAttrDef8 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef8.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef8;

        cscfga__Attribute_Definition__c testAttrDef9 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef9.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef9;

        cscfga__Attribute_Definition__c testAttrDef10 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef10.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef10;


        cscfga__Attribute_Definition__c testAttrDef11 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef11.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef11;

        cscfga__Attribute_Definition__c testAttrDef12 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef12.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef12;

        cscfga__Attribute_Definition__c testAttrDef13 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef13.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef13;

        cscfga__Attribute_Definition__c testAttrDef14 = TestDataSetupClass.createAttrDef(testProDef);
        testAttrDef14.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef14;


        News_Xtend_Product_Ref__c testNewsXtendProductRef = new News_Xtend_Product_Ref__c();
        testNewsXtendProductRef.Name = 'Something';
        insert testNewsXtendProductRef;
        
        list<cscfga__Attribute__c> atts = new list<cscfga__Attribute__c>();

        cscfga__Attribute__c testAttr = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef);
        testAttr.cscfga__Value__c = testNewsXtendProductRef.Id;
        testAttr.Name = 'Product';
           atts.add(testAttr);
           
         cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef1);
        testAttr1.cscfga__Value__c = '1';
        testAttr1.Name = 'Quantity';
           atts.add(testAttr1);   
           
           cscfga__Attribute__c testAttr3 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef3);
        testAttr3.cscfga__Value__c = '1.3';
        testAttr3.Name = 'Total Number';
           atts.add(testAttr3);           
          
             cscfga__Attribute__c testAttr4 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef4);
        testAttr4.cscfga__Value__c = 'CPM';
        testAttr4.Name = 'Cost Model';
           atts.add(testAttr4); 
 
              cscfga__Attribute__c testAttr5 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef5);
        testAttr5.cscfga__Value__c = '1.3777';
        testAttr5.Name = 'CPM';
           atts.add(testAttr5); 
           
              cscfga__Attribute__c testAttr6 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef6);
        testAttr6.cscfga__Value__c = '1.3777';
        testAttr6.Name = 'Cost CPM';
           atts.add(testAttr6);

        // final util update
        cscfga__Attribute__c testAttr7 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef7);
        testAttr7.cscfga__Value__c = '100';
        testAttr7.Name = 'Total Impressions';
        atts.add(testAttr7);

        cscfga__Attribute__c testAttr8 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef8);
        testAttr8.cscfga__Value__c = '100';
        testAttr8.Name = 'Basic Price';
        atts.add(testAttr8);


        cscfga__Attribute__c testAttr9 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef9);
        testAttr9.cscfga__Value__c = '100';
        testAttr9.Name = 'Discount';
        atts.add(testAttr9);

        cscfga__Attribute__c testAttr10 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef10);
        testAttr10.cscfga__Value__c = '100';
        testAttr10.Name = 'Quantity or Invoice Price';
        atts.add(testAttr10);

        cscfga__Attribute__c testAttr11 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef11);
        testAttr11.cscfga__Value__c = '10';
        testAttr11.Name = 'Invoice Price Discount Calculation';
        atts.add(testAttr11);

        cscfga__Attribute__c testAttr12 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef12);
        testAttr12.cscfga__Value__c = 'Invoice Price';
        testAttr12.Name = 'Price';
        atts.add(testAttr12);

        cscfga__Attribute__c testAttr13 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef13);
        testAttr13.cscfga__Value__c = '100';
        testAttr13.Name = 'Total Number';
        atts.add(testAttr13);

        cscfga__Attribute__c testAttr14 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef14);
        testAttr14.cscfga__Value__c = '100';
        testAttr14.Name = 'Total Cost';
        atts.add(testAttr14);

        insert atts;


        // new definition records

        cscfga__Product_Definition__c testProDef2 = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef2;

        cscfga__Product_Configuration__c prodConfig2 = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig2.cscfga__Product_Definition__c = testProDef2.Id;
        insert prodConfig2;

        cscfga__Attribute_Definition__c testAttrDef2 = TestDataSetupClass.createAttrDef(testProDef2);
        testAttrDef2.cscfga__Data_Type__c = 'Decimal';
        insert testAttrDef2;



        cscfga__Attribute__c testAttr2 = TestDataSetupClass.createAttr(prodConfig2, so, testAttrDef2);
        testAttr2.Name = 'Price';
        insert testAttr2;

        // ---

        cscfga__Product_Definition_Version__c testProdDefVersion = new cscfga__Product_Definition_Version__c();
        testProdDefVersion.cscfga__Original_Definition__c = testProDef.Id;
        testProdDefVersion.cscfga__Replacement_Definition__c = testProDef2.Id;
        insert testProdDefVersion;

        cscfga__rule__c rule = new cscfga__rule__c(cscfga__grouping__c = 'QuantityUpdate', cscfga__Product_Definition__c = testProDef2.Id);
        insert rule;

    }



    @isTest static void runTest() {
        Test.startTest();

        CS_UpgradeOpenProductsBatch obj = new CS_UpgradeOpenProductsBatch();
        DataBase.executeBatch(obj); 
            
        Test.stopTest();             
    }

    @isTest static void runUpgradeOpenProductsBatchWithArguments() {
        List<cscfga__Product_Configuration__c> prodConfigs = [SELECT Id, (SELECT Id FROM cscfga__Attributes__r where Name = 'Product') FROM cscfga__Product_Configuration__c];

        List<id> prodConfigIDs = new List<Id>();

        for (cscfga__Product_Configuration__c prodConf : prodConfigs) 
        {
        if (prodConf.cscfga__Attributes__r.isEmpty()) continue;
            prodConfigIDs.add(prodConf.Id);
        }

        Test.startTest();

        CS_UpgradeOpenProductsBatch obj = new CS_UpgradeOpenProductsBatch(prodConfigIDs);
        DataBase.executeBatch(obj); 
            
        Test.stopTest();             
    }

    @isTest static void runSessionTest() {
        Test.startTest();

        Database.executeBatch(new CS_UpgradeBasketSessionBatch());

        Test.stopTest();
    }

    @isTest static void runFinalizeTest() {
        Test.startTest();

        Database.executeBatch(new CS_UpgradeFinalizeProdDefBatch());

        Test.stopTest();
    }

}
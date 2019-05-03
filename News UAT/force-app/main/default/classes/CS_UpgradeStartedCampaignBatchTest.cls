@isTest
private class CS_UpgradeStartedCampaignBatchTest {
    
    @testSetup static void prepareTest() {

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        Industry_Code__c indCode = TestDataFactory.createIndustryCode();
        insert indCode;
        acc.RecordTypeId = rtypes.Id;
        acc.Is_Digital__c = true;
        acc.Adpoint_Id__c = '1';
        acc.Industry_Code__c = indCode.Id;
        acc.Digital_Status__c = 'Active';
        insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        opp.OpportunityGroup__c = 'NewsXtend'; 
        insert opp;
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'Externally Approved';
        insert so;

        // create Pricebooks, Products and Opportunity Line Items - needed to be able to 'Close - Won' the Opprortunity
        List<Product2> products = TestDataFactory.createProducts(1);
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(new List<Opportunity>{opp},
                                                                                    products, pricebookEntries, null);
        insert olis;
        
        Briefing_Form__c bf = new Briefing_Form__c(Status__c = 'Completed');
        insert bf;

        // Close Won the Opportunity to meet the batch query, add fields required by validation rules
        opp.Classification__c = 'New Business';
        opp.Competitor__c = 'Magazines - Bauer';
        opp.Description = 'This is a test Opportunity.';
        opp.Has_an_Approved_SO__c = true;
        opp.Payer_Account__c = acc.Id;
        opp.Briefing_Form__c = bf.Id;
        opp.Campaign_Brief_Form_Completed__c = true;
        opp.StageName = 'Closed Won';                       // commenting out this makes the
        update opp;

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
                   
        insert atts;       

        cscfga__Product_Definition_Version__c testProdDefVersion = new cscfga__Product_Definition_Version__c();
        testProdDefVersion.cscfga__Original_Definition__c = testProDef.Id;
        testProdDefVersion.cscfga__Replacement_Definition__c =  testProDef.Id;
        insert testProdDefVersion;
        
        cscfga__rule__c rule = new cscfga__rule__c(cscfga__grouping__c = 'QuantityUpdate', cscfga__Product_Definition__c = testProDef.Id);
        insert rule;

        /*
        System.debug('UT - Account: ' + acc);
        System.debug('UT - Contact: ' + con);
        System.debug('UT - Opportunity: ' + opp);
        System.debug('UT - Sales Order: ' + so);
        System.debug('UT - Product Basket: ' + prodBasket);
        System.debug('UT - Product Config: ' + prodConfig);
        System.debug('UT - Product Category: ' + testProdCateg);
        System.debug('UT - Product Definition: ' + testProDef);
        System.debug('UT - Attribute Def: ' + testAttrDef);
        System.debug('UT - Xtend Prod Def: ' + testNewsXtendProductRef);
        System.debug('UT - Attribute: ' + testAttr);
        System.debug('UT - ProdDefVersion: ' + testProdDefVersion);
        System.debug('UT - Products: ' + products);
        System.debug('UT - Pricebooks: ' + pricebooks);
        System.debug('UT - Pricebook Entries: ' + pricebookEntries);
        System.debug('UT - Opportunity Line Items: ' + olis);

        cscfga__Product_Configuration__c test = [SELECT cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.StageName,
                                                    cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c,
                                                    cscfga__Product_Definition__c,
                                                    (SELECT Id, cscfga__Value__c, cscfga__Attribute_Definition__c
                                                     FROM cscfga__Attributes__r)
                                                     FROM cscfga__Product_Configuration__c];
        System.debug(test);
        */
    }

    @isTest static void runTest() {
        Test.startTest();

        CS_UpgradeStartedCampaignBatch obj = new CS_UpgradeStartedCampaignBatch();
        DataBase.executeBatch(obj); 
            
        Test.stopTest();             
    }
    
     @isTest static void runUpgradStartedCampaignBatchWithArguments() {
        List<cscfga__Product_Configuration__c> prodConfigs = [SELECT Id, (SELECT Id FROM cscfga__Attributes__r where Name = 'Product') FROM cscfga__Product_Configuration__c];

        List<id> prodConfigIDs = new List<Id>();

        for (cscfga__Product_Configuration__c prodConf : prodConfigs) 
        {
        if (prodConf.cscfga__Attributes__r.isEmpty()) continue;
            prodConfigIDs.add(prodConf.Id);
        }

        Test.startTest();

        CS_UpgradeStartedCampaignBatch obj = new CS_UpgradeStartedCampaignBatch(prodConfigIDs);
        DataBase.executeBatch(obj); 
            
        Test.stopTest();             
    }   
}
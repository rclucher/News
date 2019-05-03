@isTest
private class PostRulesExecutionObserverTest {
    static  cscfga__Product_Category__c prodCat;
    static  cscfga__Product_Definition__c prodDef;
    static  cscfga__Attribute_Definition__c attDef;

    static  cscfga__Product_Basket__c prodBasket;
    static  cscfga__Product_Configuration__c prodConfig;

    static  Account newAccount;
    static  Contact newContact;
    static  User newUser;

    static  Product2 prod;
    static  Pricebook2 priceBK;
    static  PriceBookEntry priceEntry;

    static  csb2c__Inbound_Ecommerce_Order_Request__c orderReq;
    
    @isTest
    static void testObserver () {
        csb2c.ProductBasketObservable obs = new csb2c.ProductBasketObservable('Test Name', new List<Id>());
        PostRulesExecutionObserver preo = new PostRulesExecutionObserver();
        preo.execute(obs, null);
    }
    
    @isTest 
    static void testValidBasket () {

        initData();
        
        prodBasket.Campaign_Name__c = 'test campaign name';
        prodBasket.Campaign_Start_Date__c = Date.newInstance(2019, 1, 1);
        prodBasket.cscfga__Products_Id_Qty_In_Basket__c = '1';
        prodBasket.Sales_Rep_Identifier__c = 'singletestuser@email.com';
        prodBasket.Contact_Identifier__c = 'testExternalId';
        update prodBasket;
        List<id> pbId = new List<Id>();
        pbId.add(prodBasket.Id);
        
        Test.startTest();
        APIPostRuleExecution updateJob = new APIPostRuleExecution(pbId);
        ID jobID = System.enqueueJob(updateJob);
        
        Test.stopTest();

        Map<Id, csmso__Sales_Order__c> salesorders = new Map<Id, csmso__Sales_Order__c>(
                                                    [SELECT Id,
                                                            Origin__c,
                                                            csmso__Total_Price__c,
                                                            OwnerId,
                                                            csmso__Booking_Contact__c
                                                    FROM    csmso__Sales_Order__c 
                                                    WHERE   Id IN (Select csmso__Sales_Order__c FROM cscfga__Product_Basket__c where id =: prodBasket.Id)]);

        List<Payment__c> payments = [SELECT     Id,
                                                Total_Pending__c
                                        FROM    Payment__c];
        List<Order__c> orders = [SELECT Id
                                FROM    Order__c];
        List<CSPOFA__Orchestration_Process__c> processes = [SELECT  Id
                                                            FROM    CSPOFA__Orchestration_Process__c];
        List<csb2c__Inbound_Ecommerce_Order_Request__c> ordReqs = [SELECT   Id,
                                                                            Processing_Error_Message__c
                                                                    FROM    csb2c__Inbound_Ecommerce_Order_Request__c
                                                                    ];
        system.debug(ordReqs);
        System.assert(ordReqs[0].Processing_Error_Message__c == null || ordReqs[0].Processing_Error_Message__c == '', 'There should not be any processing error messages');
        System.assert(salesorders.size()>0, 'There are no Sales Orders created');
        System.assert(salesorders.values()[0].Origin__c=='Campaign Track', 'Total price on sales order is not updated');
        System.assert(orders.size() > 0, 'There are no orders created');
        System.assert(payments.size() > 0, 'There are no payments created');
        System.assert(payments[0].Total_Pending__c > 0, 'There is no price on payment');
        System.assert(processes.size()==0, 'Orchestrator processes should not be created');
    }

    @isTest 
    static void testMissingInfoBasket () {

        initData();

        List<id> pbId = new List<Id>();
        pbId.add(prodBasket.Id);
        Test.startTest();
        APIPostRuleExecution updateJob = new APIPostRuleExecution(pbId);
        ID jobID = System.enqueueJob(updateJob);
        Test.stopTest();

        List<csb2c__Inbound_Ecommerce_Order_Request__c> ordReqs = [SELECT   Id,
                                                                            Processing_Error_Message__c
                                                                    FROM    csb2c__Inbound_Ecommerce_Order_Request__c
                                                                    ];
        Map<Id, csmso__Sales_Order__c> salesorders = new Map<Id, csmso__Sales_Order__c>(
                                                    [SELECT Id,
                                                            Origin__c,
                                                            csmso__Total_Price__c,
                                                            OwnerId,
                                                            csmso__Booking_Contact__c
                                                    FROM    csmso__Sales_Order__c 
                                                    WHERE   Id IN (Select csmso__Sales_Order__c FROM cscfga__Product_Basket__c where id IN :pbId)]);
        List<Payment__c> payments = [SELECT     Id,
                                                Total_Pending__c
                                        FROM    Payment__c];
        System.assert(ordReqs[0].Processing_Error_Message__c != null, 'Processing Error message is not populated');
        System.assert(ordReqs.size()>0, 'Missing Order Request');
        System.assert(salesorders.size()==0, 'Sales Orders should not be created');
        System.assert(payments.size() == 0, 'Payments should not be created');
    }

    @isTest 
    static void testIncorrectFormatBasket () {

        initData();
        
        prodBasket.Campaign_Name__c = 'test campaign name';
        prodBasket.Campaign_Start_Date__c = Date.newInstance(2019, 1, 1);
        prodBasket.cscfga__Products_Id_Qty_In_Basket__c = '1';
        prodBasket.Sales_Rep_Identifier__c = 'singletest@email.com';
        prodBasket.Contact_Identifier__c = 'testExtnalId';
        update prodBasket;

        List<id> pbId = new List<Id>();
        pbId.add(prodBasket.Id);
        Test.startTest();
        APIPostRuleExecution updateJob = new APIPostRuleExecution(pbId);
        ID jobID = System.enqueueJob(updateJob);
        Test.stopTest();

        List<csb2c__Inbound_Ecommerce_Order_Request__c> incorrectordReqs = [SELECT  Id,
                                                                                    csb2c__Account__c,
                                                                                    csb2c__Product_Basket__c,
                                                                                    Processing_Error_Message__c,
                                                                                    csb2c__Processed__c,
                                                                                    csb2c__Error_Information__c
                                                                            FROM    csb2c__Inbound_Ecommerce_Order_Request__c
                                                                            ];

        Map<Id, csmso__Sales_Order__c> salesorders = new Map<Id, csmso__Sales_Order__c>(
                                                    [SELECT Id,
                                                            Origin__c,
                                                            csmso__Total_Price__c,
                                                            OwnerId,
                                                            csmso__Booking_Contact__c
                                                    FROM    csmso__Sales_Order__c 
                                                    WHERE   Id IN (Select csmso__Sales_Order__c FROM cscfga__Product_Basket__c where id IN :pbId)]);
        List<Payment__c> payments = [SELECT     Id,
                                                Total_Pending__c
                                        FROM    Payment__c];
        System.assert(incorrectordReqs[0].Processing_Error_Message__c != null, 'Processing Error message is not populated');
        System.assert(salesorders.size()==0, 'Sales Orders should not be created');
        System.assert(payments.size() == 0, 'Payments should not be created');
        System.assert(incorrectordReqs.size()>0, 'Missing Order Request');
    }

    static void initData() {
        
        csmso__SalesOrderAPI__c salesOrderApi = TestDataSetupClass.createSalesOrderAPI();
        insert salesOrderApi;
        csmso__Business_Unit__c busUnit = TestDataSetupClass.createBusinessUnit();
        insert busUnit;
        csmso__Product_Node__c prodNode = TestDataSetupClass.createProductNode('Campaign Track Product', busUnit);
        insert prodNode;
        
        prodCat = TestDataSetupClass.createProdCateg();
        insert prodCat;
        prodDef = TestDataSetupClass.createProDef(prodCat);
        insert prodDef;
        attDef = TestDataSetupClass.createAttrDefWithName(prodDef, 'Product');
        insert attDef;

        prodBasket = TestDataSetupClass.createProdBasketNoSO();
        insert prodBasket;
        prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        insert prodConfig;
        
        List<cscfga__Attribute__c> atts = new List<cscfga__Attribute__c>();
        cscfga__Attribute__c prodatt = TestDataSetupClass.createAttrNoSO(prodConfig, attDef);
        prodatt.cscfga__Product_Configuration__c = prodConfig.Id;   
        prodatt.cscfga__Value__c = prodNode.id;
        prodatt.Name = 'Product';
        atts.add(prodatt);
        cscfga__Attribute__c prodNameAtt = TestDataSetupClass.createAttrNoSO(prodConfig, attDef);
        prodNameAtt.cscfga__Product_Configuration__c = prodConfig.Id;   
        prodNameAtt.cscfga__Value__c = prodNode.Name;
        prodNameAtt.Name = 'Product Name';
        atts.add(prodNameAtt);
        cscfga__Attribute__c quantAtt = TestDataSetupClass.createAttrNoSO(prodConfig, attDef);
        quantAtt.cscfga__Product_Configuration__c = prodConfig.Id;   
        quantAtt.cscfga__Value__c = '1';
        quantAtt.Name = 'Quantity';
        atts.add(quantAtt);
        cscfga__Attribute__c priceAtt = TestDataSetupClass.createAttrNoSO(prodConfig, attDef);
        priceAtt.cscfga__Product_Configuration__c = prodConfig.Id;   
        priceAtt.cscfga__Value__c = '1000';
        priceAtt.Name = 'Price';
        atts.add(priceAtt);
        cscfga__Attribute__c payAtt = TestDataSetupClass.createAttrNoSO(prodConfig, attDef);
        payAtt.cscfga__Product_Configuration__c = prodConfig.Id;   
        payAtt.cscfga__Value__c = 'Recurring';
        payAtt.Name = 'Payment Type';
        atts.add(payAtt);
        insert atts;
        
        newAccount = TestDataSetupClass.createAccount();
        insert newAccount;
        newContact = TestDataSetupClass.createContactForIntegration(newAccount);
        insert newContact;
        orderReq = TestDataSetupClass.createOrderRequest(newAccount, prodBasket);
        insert orderReq;

        newUser = TestDataFactory.createUser('System Administrator', 'lastName', 'firstName', null, null, false);
        insert newUser;

        prod = TestDataSetupClass.createProduct2WithName('Digital - NewsXtend');
        insert prod;
        priceBK = TestDataSetupClass.createPriceBook();
        insert priceBK;
        priceEntry = TestDataSetupClass.createPriceBookEntry(prod); 
        insert priceEntry;

        No_Validation__c noValidationFlag = new No_Validation__c(Flag__c = true);
        insert noValidationFlag;
    }
    
}
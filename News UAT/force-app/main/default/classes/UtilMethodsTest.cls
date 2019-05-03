@isTest
private class UtilMethodsTest {

    @isTest
    static void test_getRecordTypeId() {
        Test.startTest();

        System.assertNotEquals(null, UtilMethods.getRecordTypeId('Account.Prospecting Account'));
        System.assertEquals(null, UtilMethods.getRecordTypeId('Wrong RT'));

        Test.stopTest();
    }

    @isTest
    static void test_getSobjectTypes() {
        Test.startTest();

        System.assertNotEquals(null, UtilMethods.getSobjectTypes('Account'));

        Test.stopTest();
    }

    @isTest
    static void test_createCreativeForProductOrderId() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Draft'
        );
        insert pOrd;

        Test.startTest();

        System.assertNotEquals(null, UtilMethods.createCreativeForProductOrderId(pOrd.Id, UserInfo.getUserId()));

        Test.stopTest();
    }

    @isTest
    static void test_findObjectNamesFromRecordIdPrefix() {
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Test.startTest();

        Set<String> rNames = UtilMethods.findObjectNamesFromRecordIdPrefix(new Set<Id>{acc.Id});
        System.assert(rNames.contains('Account'));

        Test.stopTest();
    }

    @isTest
    static void test_mapRecordIdWithObjectName() {
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Test.startTest();

        Map<Id, String> rNames = UtilMethods.mapRecordIdWithObjectName(new Set<Id>{acc.Id});
        System.assertEquals('Account', rNames.get(acc.Id));

        Test.stopTest();
    }

    @isTest
    static void test_startOrchestratorProcessFor() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Container Tag Setup'
        );
        insert template;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            New_Orch_Process__c = template.Name,
            CSPOFA__Orchestration_Process__c = process.Id
        );
        insert step;

        Test.startTest();

        UtilMethods.startOrchestratorProcessFor(order.Id, 'Container Tag Setup');

        Test.stopTest();
        
        Order__c updOrder = [select Id, Container_Tag_Pushed_Count__c, Is_Container_Tag_Button_Pushed__c
        				 	 from Order__c where Id = :order.Id];
        				  
         System.assertEquals(1, updOrder.Container_Tag_Pushed_Count__c);
         System.assertEquals('Clicked', updOrder.Is_Container_Tag_Button_Pushed__c);
     }

    @isTest
    static void test_prepareDataToRegenerateProductOrderNoOrder() {
        Test.startTest();

        System.assertEquals('Cannot find Order.', UtilMethods.prepareDataToRegenerateProductOrder(null));

        Test.stopTest();
    }

    @isTest
    static void test_prepareDataToRegenerateProductOrder() {
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c salesOrder = TestDataSetupClass.createSalesOrder(acc, opp);
        salesOrder.csmso__Status__c = 'Manually Approved';
        insert salesOrder;

        cscfga__Product_Basket__c basket = TestDataSetupClass.createProdBasket(salesOrder);
        insert basket;

        csmso__Business_Unit__c businessUnit = TestDataSetupClass.createBusinessUnit();
        insert businessUnit;

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;
        
        csmso__Product_Node__c productNode = TestDataSetupClass.createProductNode('Product Node Name', businessUnit);
        productNode.Product_Line__c = 'Social';
        productNode.Product_Type__c = 'Setup';
        insert productNode;

        cscfga__Product_Configuration__c config = TestDataSetupClass.createProdConfig(basket);
        config.Product_ID__c = productNode.Id;
        insert config;

        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;

        Test.startTest();

        System.assertEquals('Success.', UtilMethods.prepareDataToRegenerateProductOrder(order.Id));

        Test.stopTest();
    }

    @isTest
    static void test_prepareDataToRegenerateProductOrderNoProductLine() {
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c salesOrder = TestDataSetupClass.createSalesOrder(acc, opp);
        salesOrder.csmso__Status__c = 'Manually Approved';
        salesOrder.Call_Tracking__c = true;
        insert salesOrder;

        cscfga__Product_Basket__c basket = TestDataSetupClass.createProdBasket(salesOrder);
        insert basket;

        csmso__Business_Unit__c businessUnit = TestDataSetupClass.createBusinessUnit();
        insert businessUnit;

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        csmso__Product_Node__c productNode = TestDataSetupClass.createProductNode('Product Node Name', businessUnit);
        insert productNode;

        cscfga__Product_Configuration__c config = TestDataSetupClass.createProdConfig(basket);
        config.Product_ID__c = productNode.Id;
        insert config;

        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;

        Test.startTest();

        System.assertEquals('Success.', UtilMethods.prepareDataToRegenerateProductOrder(order.Id));

        Test.stopTest();
    }

    @isTest
    static void test_prepareDataToRegenerateProductOrderExistingFullfilment() {
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c salesOrder = TestDataSetupClass.createSalesOrder(acc, opp);
        insert salesOrder;

        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

        Test.startTest();

        System.assertEquals('At least one of your products has already started the fulfilment. Please ask your administrator for assistance.',
                            UtilMethods.prepareDataToRegenerateProductOrder(order.Id));

        Test.stopTest();
    }

    @isTest
    static void test_getSobjectRelatedFields() {
        Test.startTest();

        UtilMethods.getSobjectRelatedFields('Contact,Account');

        Test.stopTest();
    }
    
     @isTest
    static void test_startFulfillment_DraftOnly() {
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c salesOrder = TestDataSetupClass.createSalesOrder(acc, opp);
        insert salesOrder;

        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Draft'
        );
        insert pOrd;

        Test.startTest();

 		UtilMethods.startFulfilment(order.Id);
 		
        Test.stopTest();
        
        Order__c updOrder = [select Id, Start_All_Fulfillment_Pushed_Count__c, Is_Start_All_Fulfilment_Button_Pushed__c,
        				  (select Id, Status__c from Product_Orders__r) from Order__c where Id = :order.Id];
        				  
         //System.assertEquals(1, updOrder.Start_All_Fulfillment_Pushed_Count__c);
         //System.assertEquals('Clicked', updOrder.Is_Start_All_Fulfilment_Button_Pushed__c);
         //System.assertEquals('Fulfilment Started', updOrder.Product_Orders__r[0].Status__c);
    }   
    
      @isTest
    static void test_startFulfillment_DraftAndCancelled() {
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c salesOrder = TestDataSetupClass.createSalesOrder(acc, opp);
        insert salesOrder;

        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        list<Product_Order__c> pos = new list<Product_Order__c>();

        Product_Order__c pOrd1 = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Draft'
        );
        pos.add(pOrd1);
        
         Product_Order__c pOrd2 = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Cancelled'
        );
        pos.add(pOrd2);      
        
        insert pos; 

        Test.startTest();

 		UtilMethods.startFulfilment(order.Id);
 		
        Test.stopTest();
        
        Order__c updOrder = [select Id, Start_All_Fulfillment_Pushed_Count__c, Is_Start_All_Fulfilment_Button_Pushed__c,
        				  (select Id, Status__c from Product_Orders__r where Status__c = 'Fulfilment Started') from Order__c where Id = :order.Id];
        				  
         //System.assertEquals(1, updOrder.Start_All_Fulfillment_Pushed_Count__c);
         //System.assertEquals(null, updOrder.Is_Start_All_Fulfilment_Button_Pushed__c);
         //System.assertEquals(0, updOrder.Product_Orders__r.size());
    }    
    
          @isTest
    static void test_startFulfillment_TwoDraftsDirectFulFilOfOnePO() {
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c salesOrder = TestDataSetupClass.createSalesOrder(acc, opp);
        insert salesOrder;

        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        list<Product_Order__c> pos = new list<Product_Order__c>();

        Product_Order__c pOrd1 = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Draft'
        );
        pos.add(pOrd1);
        
         Product_Order__c pOrd2 = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Draft'
        );
        pos.add(pOrd2);      
        
        insert pos; 

        Test.startTest();

 		//UtilMethods.startFulfilment(order.Id);
 		//pOrd2.Status__c = 'Fulfilment Started';
 		//update pOrd2;
 		
        Test.stopTest();
        
        Order__c updOrder = [select Id, Start_All_Fulfillment_Pushed_Count__c, Is_Start_All_Fulfilment_Button_Pushed__c,
        				  (select Id, Status__c from Product_Orders__r where Status__c = 'Fulfilment Started') from Order__c where Id = :order.Id];
        				  
         //System.assertEquals(0, updOrder.Start_All_Fulfillment_Pushed_Count__c);
         //System.assertEquals(null, updOrder.Is_Start_All_Fulfilment_Button_Pushed__c);
         //System.assertEquals(1, updOrder.Product_Orders__r.size());
    }   
    
           @isTest
    static void test_startFulfillment_TwoDraftsDirectFulFilOfOnBothPO() {
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c salesOrder = TestDataSetupClass.createSalesOrder(acc, opp);
        insert salesOrder;

        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        list<Product_Order__c> pos = new list<Product_Order__c>();

        Product_Order__c pOrd1 = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Draft'
        );
        pos.add(pOrd1);
        
         Product_Order__c pOrd2 = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Draft'
        );
        pos.add(pOrd2);      
        
        insert pos; 

        Test.startTest();

 		//pOrd1.Status__c = 'Fulfilment Started';
 		//update pOrd1;
 		//pOrd2.Status__c = 'Fulfilment Started';
 		//update pOrd2;
 		
        Test.stopTest();
        
        Order__c updOrder = [select Id, Start_All_Fulfillment_Pushed_Count__c, Is_Start_All_Fulfilment_Button_Pushed__c,
        				  (select Id, Status__c from Product_Orders__r where Status__c = 'Fulfilment Started') from Order__c where Id = :order.Id];
        				  
         //System.assertEquals(0, updOrder.Start_All_Fulfillment_Pushed_Count__c);
         //System.assertEquals('Clicked', updOrder.Is_Start_All_Fulfilment_Button_Pushed__c);
         //System.assertEquals(2, updOrder.Product_Orders__r.size());
    }      

    @isTest
    static void test_runProductAttrUpgrade() {

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        Account account = TestDataSetupClass.createAccount();
        insert account;

        Contact contact = TestDataSetupClass.createContact(account);
        insert contact;

        Opportunity opp = TestDataSetupClass.createOpportunity(account, contact);
        insert opp;

        csmso__Sales_Order__c so  = TestDataSetupClass.createSalesOrder(account, opp);
        so.Campaign_Length__c = 4;
        insert so;

        Order__c order = TestDataSetupClass.createOrder(opp);
        order.Actual_Start_Date__c = System.today()+30;
        order.Opportunity__c = opp.Id;
        insert order;

        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        insert prodConfig;

        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;

        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;

        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);
        insert testAttrDef;

        cscfga__Attribute__c testAttr = new cscfga__Attribute__c(name = 'testAttr', 
                                                                 cscfga__Product_Configuration__c = prodConfig.Id, 
                                                                 cscfga__Attribute_Definition__c = testAttrDef.Id,
                                                                 cscfga__Value__c = 'test value');
        insert testAttr;

        List<cscfga__Product_Configuration__c> pcList= new List<cscfga__Product_Configuration__c>();
        pcList.add(prodConfig);

        Test.startTest();

        UtilMethods.runProductAttrUpgrade(pcList);
        
        Test.stopTest();
    }   

    @isTest
    static void test_runCreateCSVsForDataImport() {

        Document document;

        document = new Document();
        document.Body = Blob.valueOf('Header1,Header2,Header3\r\nYES,' + '' + ',NO\r\nNO,' + '' + ',YES\r\nYES,' + '' + ',YES,' + '' + ',F4,F5,F6,F7,' + '' + ',F9,F10,' + '' + ',F12,' + '' + ',' + '' + ',F16,F17,F18');
        document.ContentType = 'application/pdf';
        document.DeveloperName = 'my_document';
        document.IsPublic = true;
        document.Name = 'My Document';
        document.FolderId = UserInfo.getUserId();
        insert document;

        Test.startTest();

        UtilMethods.CreateCSVsForDataImport(document.Name);
        
        Test.stopTest();
    }

}
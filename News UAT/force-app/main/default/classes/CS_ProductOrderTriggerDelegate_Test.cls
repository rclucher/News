@isTest
private class CS_ProductOrderTriggerDelegate_Test 
{
	@testSetup
	static void setupData() {

        // insert test custom setting needed by ProductNodeTriggers and AttributeMediaTriggers triggers
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;
        
		cscfga__Product_Definition__c def = TestDataSetupClass.createProDef(TestDataSetupClass.createProdCateg());
		insert def;

		cscfga__Attribute_Definition__c attDef = TestDataSetupClass.createAttrDef(def);
		attDef.Name = 'Total Cost';
		insert attDef;

		cscfga__Attribute_Definition__c attDef1 = TestDataSetupClass.createAttrDef(def);
		attDef1.Name = 'Price';
		insert attDef1;

		Account acc = TestDataSetupClass.createAccount();
		insert acc;

		Contact con = TestDataSetupClass.createContact(acc);
		insert con;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		insert opp;

		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		so.csmso__Status__c = 'Externally Approved';
		insert so;

		cscfga__Product_Basket__c basket = TestDataSetupClass.createProdBasket(so);
		insert basket;

        Order__c order = TestDataSetupClass.createOrder(opp);
        order.Account__c = acc.Id;
        order.Status__c = 'Draft';
        order.sales_Order__c = so.Id;
        insert order;

        News_Xtend_Product_Ref__c productRef = new News_Xtend_Product_Ref__c(Product_Line__c = 'Social',
        																	 Product_Type__c = 'Setup',
        																	 Name = 'test Setup');
        insert productRef;

		cscfga__Product_Configuration__c config = TestDataSetupClass.createProdConfig(basket);
		insert config;

		config.Product_ID__c = productRef.Id;
		update config;

		cscfga__Attribute__c att = TestDataSetupClass.createAttr(config, so, attDef);
		att.Name = 'Total Cost';
		att.cscfga__Value__c = '100';
		insert att;

		cscfga__Attribute__c att1 = TestDataSetupClass.createAttr(config, so, attDef1);
		att1.Name = 'Price';
		att1.cscfga__Value__c = '100';
		insert att1;

        Product_Order_Tier_Ranges__c tier = new Product_Order_Tier_Ranges__c(name = 'Tier 3', Lowerbound__c = 0, Upperbound__c = 2000, Tier_level__c = 'Tier 3' );
        insert tier;
	}

	@isTest static void test_OptimiziationDate()
	{
		Test.startTest();

		cscfga__Product_Configuration__c config = [select Id from cscfga__Product_Configuration__c limit 1];

		Order__c o = [SELECT Id FROM Order__c LIMIT 1];

		Product_Order__c po = new Product_Order__c();
		//po.Name = 'CS_ProductOrderTriggerDelegate_Test: Unit Test: Product Order';
		po.RecordTypeId = Schema.SObjectType.Product_Order__c.getRecordTypeInfosByName().get('Search Engine Marketing').getRecordTypeId();
		po.Order__c = o.id;
		po.Status__c ='Draft';
		po.Product_Order_Start_Date__c = Date.today();
		po.Product_Order_End_Date__c = Date.today()+10;
		po.PC_Id__c = config.Id;
		insert po;

		po.Status__c = 'In Progress';
		po.Current_Optimisation_Date__c = Date.today();
		po.Next_Social_Go_Live__c = Date.today().addMonths(2);
		update po;

    	// Cover Delete event
    	delete po;

		Test.stopTest();
	}

	@isTest static void test_FulfilmentStarted() {
		Test.startTest();

		Order__c o = [SELECT Id FROM Order__c LIMIT 1];

		Product_Order__c po = new Product_Order__c();
		//po.Name = 'CS_ProductOrderTriggerDelegate_Test: Unit Test: Product Order';
		po.RecordTypeId = Schema.SObjectType.Product_Order__c.getRecordTypeInfosByName().get('Search Engine Marketing').getRecordTypeId();
		po.Order__c = o.id;
		po.Status__c ='Draft';
		insert po;

		Optimisation_Log__c ol = new Optimisation_Log__c();
		ol.Goal_Of_Change__c = 'Other';
		ol.Comments__c = 'Test';
		ol.Product_Order__c = po.Id;
		insert ol;

		po.Status__c = 'Fulfilment Started';
		update po;

		Test.stopTest();
	}

	@isTest static void test_ReadyToGoLive() {
		Test.startTest();

		Order__c o = [SELECT Id FROM Order__c LIMIT 1];

		// Create Product Order
		Product_Order__c po = new Product_Order__c();
		//po.Name = 'CS_ProductOrderTriggerDelegate_Test: Unit Test: Product Order';
		po.RecordTypeId = Schema.SObjectType.Product_Order__c.getRecordTypeInfosByName().get('Search Engine Marketing').getRecordTypeId();
		po.Order__c = o.id;
		po.Status__c ='Draft';
		insert po;

		po.Status__c = 'Ready to go live';
		update po;

		Test.stopTest();
	}

	@isTest static void test_Pending() {
		Test.startTest();

		Order__c o = [SELECT Id FROM Order__c LIMIT 1];

		Product_Order__c po = new Product_Order__c();
		//po.Name = 'CS_ProductOrderTriggerDelegate_Test: Unit Test: Product Order';
		po.RecordTypeId = Schema.SObjectType.Product_Order__c.getRecordTypeInfosByName().get('Search Engine Marketing').getRecordTypeId();
		po.Order__c = o.id;
		po.Status__c ='Draft';
		insert po;

		po.Status__c = 'Pending For Pause';
		update po;

		Test.stopTest();
	}

	@isTest static void test_Live(){
		Test.startTest();

		Opportunity opp = [select Id from Opportunity where name = 'testOpportunityForSalesOrderSupportTest'];
		csmso__Sales_Order__c so = [select Id from csmso__Sales_Order__c limit 1];

		Order__c o = [SELECT Id FROM Order__c LIMIT 1];

		cscfga__Product_Configuration__c config = [select Id from cscfga__Product_Configuration__c limit 1];

		Product_Order__c po = new Product_Order__c();
		//po.Name = 'CS_ProductOrderTriggerDelegate_Test: Unit Test: Product Order';
		po.RecordTypeId = Schema.SObjectType.Product_Order__c.getRecordTypeInfosByName().get('Social').getRecordTypeId();
		po.Order__c = o.id;
		po.Status__c ='Draft';
		po.PC_Id__c = config.Id;
		insert po;

		po.Status__c = 'Live';
		po.Product_Order_Start_Date__c = System.today();
		po.isNextBizDateRecalLanding__c = true;

		update po;

		Test.stopTest();
	}

	@isTest static void test_CallTrackingNumber(){
		Test.startTest();

		Order__c o = [SELECT Id FROM Order__c LIMIT 1];

		// Create Product Order
		Product_Order__c po = new Product_Order__c();
		//po.Name = 'CS_ProductOrderTriggerDelegate_Test: Unit Test: Product Order';
		
		po.RecordTypeId = Schema.SObjectType.Product_Order__c.getRecordTypeInfosByName().get('Search Engine Marketing').getRecordTypeId();
		po.Order__c = o.id;
		po.Status__c ='Draft';
		insert po;

		Product_Order__c po1 = new Product_Order__c();
		//po.Name = 'CS_ProductOrderTriggerDelegate_Test: Unit Test: Product Order';
		po1.RecordTypeId = Schema.SObjectType.Product_Order__c.getRecordTypeInfosByName().get('Call Tracking').getRecordTypeId();
		po1.Order__c = o.id;
		po1.Status__c ='Draft';
		insert po1;

		po1.Call_Tracking_Number__c = '123abc';
		update po1;

		Test.stopTest();

		Product_Order__c po_Mod = [select Call_Tracking_Number__c from Product_Order__c where Id = :po.id];
		system.assertEquals('123abc', po_Mod.Call_Tracking_Number__c);
	}

	@isTest static void test_SetAccountName(){
        Test.startTest();

		Order__c order = [SELECT Id FROM Order__c LIMIT 1];

 		Product_Order__c po = new Product_Order__c();
		//po.Name = 'CS_ProductOrderTriggerDelegate_Test: Unit Test: Product Order';

		po.RecordTypeId = Schema.SObjectType.Product_Order__c.getRecordTypeInfosByName().get('Search Engine Marketing').getRecordTypeId();
		po.Order__c = order.id;
		po.Status__c ='Draft';

		insert po;

		Test.stopTest();

		Product_Order__c po_Mod = [select Account_Name__c from Product_Order__c where Id = :po.id];
		system.assertEquals('testAccountForSalesOrderSupportTest', po_Mod.Account_Name__c);

	}
}
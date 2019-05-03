@isTest
private class CS_ProductConfigurationTriggerDelTest {
	@isTest static void test_method_one()
	{
		cscfga__Product_Configuration__c prodConfig  = [SELECT Id FROM cscfga__Product_Configuration__c WHERE Name = 'prodConfig' LIMIT 1];
		cscfga__Product_Configuration__c prodConfig1 = [SELECT Id FROM cscfga__Product_Configuration__c WHERE Name = 'prodConfig1' LIMIT 1];
		csmso__Product_Node__c product               = [SELECT Id FROM csmso__Product_Node__c WHERE Name = 'test SEM'];
		csmso__Product_Node__c product1              = [SELECT Id FROM csmso__Product_Node__c WHERE Name = 'test social'];

		prodConfig.Product_ID__c  = product.Id;
		prodConfig1.Product_ID__c = product1.Id;

		Test.startTest();
		update prodConfig;
		System.assert([select id,Call_Tracking__c, name from csmso__Sales_Order__c].Call_Tracking__c == true);
		delete prodConfig;

		System.assert([select id,Call_Tracking__c, name from csmso__Sales_Order__c].Call_Tracking__c == false,
					  [select id,Call_Tracking__c, name from csmso__Sales_Order__c].Call_Tracking__c);
		Test.stopTest();
	}

	@isTest static void test_method_two()
	{
		//change SO status to trigger ResetApprovalProcess logic within CS_AllAttributeTriggerHelper.ResetSalesOrder()
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.csmso__Status__c       = 'Internally Approved';
		update so;
		
		cscfga__Product_Configuration__c prodConfig  = [SELECT Id FROM cscfga__Product_Configuration__c WHERE Name = 'prodConfig' LIMIT 1];
		cscfga__Product_Configuration__c prodConfig1 = [SELECT Id FROM cscfga__Product_Configuration__c WHERE Name = 'prodConfig1' LIMIT 1];
		csmso__Product_Node__c product               = [SELECT Id FROM csmso__Product_Node__c WHERE Name = 'test SEM'];
		csmso__Product_Node__c product1              = [SELECT Id FROM csmso__Product_Node__c WHERE Name = 'test social'];

		prodConfig.Product_ID__c  = product.Id;
		prodConfig1.Product_ID__c = product1.Id;

		Test.startTest();
		update prodConfig;
		System.assert([select id,Call_Tracking__c, name from csmso__Sales_Order__c].Call_Tracking__c == true);
		delete prodConfig;

		System.assert([select id,Call_Tracking__c, name from csmso__Sales_Order__c].Call_Tracking__c == false,
					  [select id,Call_Tracking__c, name from csmso__Sales_Order__c].Call_Tracking__c);
		Test.stopTest();
	}

	@testSetup
	static void setupData() {
		// insert test custom setting needed by ProductNodeTriggers and AttributeMediaTriggers triggers
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
		insert soApi;

		List<BusinessHours> bhs = [select id from BusinessHours where IsDefault = true];
		System.assert(bhs.size() == 1);

		Account acc       = TestDataSetupClass.createAccount();
		RecordType rtypes = [Select Name, Id From RecordType where sObjectType = 'Account' and Name = 'Prospecting Account' and isActive = true];
		acc.RecordTypeId = rtypes.Id;
		insert acc;

		Contact con = TestDataSetupClass.createContact(acc);
		insert con;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		insert opp;

		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		so.csmso__Status__c       = 'Externally Approved';
		so.Campaign_Start_Date__c = System.today().addDays(20);
		insert so;

		cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
		insert prodBasket;

		cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
		prodConfig.Name = 'prodConfig';

		cscfga__Product_Configuration__c prodConfig1 = TestDataSetupClass.createProdConfig(prodBasket);
		prodConfig1.Name = 'prodConfig1';
		insert new List<cscfga__Product_Configuration__c> {prodConfig, prodConfig1};

		cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
		insert testProdCateg;

		cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
		insert testProDef;

		cscfga__Attribute_Definition__c testAttrDef1 = TestDataSetupClass.createAttrDef(testProDef);
		cscfga__Attribute_Definition__c testAttrDef2 = TestDataSetupClass.createAttrDef(testProDef);
		cscfga__Attribute_Definition__c testAttrDef3 = TestDataSetupClass.createAttrDef(testProDef);
		cscfga__Attribute_Definition__c testAttrDef4 = TestDataSetupClass.createAttrDef(testProDef);
		insert new List<cscfga__Attribute_Definition__c>{testAttrDef1, testAttrDef2, testAttrDef3, testAttrDef4};

		cscfga__Attribute__c testAttr1 = new cscfga__Attribute__c(name = 'Product Name', cscfga__Product_Configuration__c = prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef1.Id, cscfga__Value__c = 'testName');
		cscfga__Attribute__c testAttr2 = new cscfga__Attribute__c(name = 'Quantity', cscfga__Product_Configuration__c = prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef2.Id, cscfga__Value__c = '10');
		cscfga__Attribute__c testAttr3 = new cscfga__Attribute__c(name = 'Price', cscfga__Product_Configuration__c = prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef3.Id, cscfga__Value__c = '50.00');
		cscfga__Attribute__c testAttr4 = new cscfga__Attribute__c(name = 'Payment Type', cscfga__Product_Configuration__c = prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef4.Id, cscfga__Value__c = 'One Off');
		insert new List<cscfga__Attribute__c>{testAttr1, testAttr2, testAttr3, testAttr4};

		// COMMENTED FOR UPGRADE, SHABU
		/* News_Xtend_Product_Ref__c product = new News_Xtend_Product_Ref__c(Product_Line__c = 'Search',
		                                                                 Product_Type__c = 'SEM',
		                                                                 Name = 'test SEM');

		   News_Xtend_Product_Ref__c product1 = new News_Xtend_Product_Ref__c(Product_Line__c = 'Social',
		                                                                 Product_Type__c = 'test',
		                                                                 Name = 'test social'); */
		csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
		insert bu;

		csmso__Product_Node__c product = TestDataSetupClass.createProductNode('test SEM', bu);
		product.Product_Line__c = 'Search';
		product.Product_Type__c = 'SEM';

		csmso__Product_Node__c product1 = TestDataSetupClass.createProductNode('test social', bu);
		product1.Product_Line__c = 'Social';
		product1.Product_Type__c = 'test';

		insert new List<csmso__Product_Node__c>{product, product1};
	}
}
/*
 *
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class CS_DataCreationTest {

	@testSetup
	static void setupData() {

		/*
		 * Create Products
		 */
		/*     Pricebook2 pb = TestDataSetupClass.createPriceBook();
		     insert pb;

		     // Print
		     Product2 product2Print = TestDataSetupClass.createProduct2('The Advertiser');
		     insert product2Print;

		     PriceBookEntry printPbe = TestDataSetupClass.createPriceBookEntry(product2Print);
		     insert printPbe;

		     Publication_Product__c pbPrint = TestDataSetupClass.createPublicationProduct(product2Print);
		     pbPrint.Publication__c = 'The Advertiser';
		     insert pbPrint;

		     // Digital
		     Product2 product2Digital = TestDataSetupClass.createProduct2('RoN medrec roadblock Desktop');
		     insert product2Digital;

		     PriceBookEntry digitalPbe = TestDataSetupClass.createPriceBookEntry(product2Digital);
		     insert digitalPbe;

		     Publication_Product__c pbDigital = TestDataSetupClass.createPublicationProduct(product2Digital);
		     pbDigital.Publication__c = 'RoN medrec roadblock Desktop';
		     insert pbDigital;
		 */
		// Xtend
		Product2 product2Xtend = TestDataSetupClass.createProduct2('NewsXtend');
		insert product2Xtend;

		PriceBookEntry xtendPbe = TestDataSetupClass.createPriceBookEntry(product2Xtend);
		insert xtendPbe;

		Publication_Product__c pbXtend = TestDataSetupClass.createPublicationProduct(product2Xtend);
		pbXtend.Publication__c = 'NewsXtend';
		insert pbXtend;

		/*
		 * Create Product Definitions
		 * Otherwise Campaign_Products_Type__c field on Sales Order will not be populated correctly.
		 * createOpportunityProducts() code testing depends on this value
		 */
		cscfga__Product_Category__c productCategory = TestDataSetupClass.createProdCateg();
		insert productCategory;

		cscfga__Product_Definition__c printLedProdDef = TestDataSetupClass.createProDef(productCategory);
		printLedProdDef.Name = 'Print Led';

		cscfga__Product_Definition__c xtendLedProdDef = TestDataSetupClass.createProDef(productCategory);
		xtendLedProdDef.Name = 'News Xtend Led';

		cscfga__Product_Definition__c bundlePrintProdDef = TestDataSetupClass.createProDef(productCategory);
		bundlePrintProdDef.Name = 'Bundle Print';

		cscfga__Product_Definition__c bundleXtendProdDef = TestDataSetupClass.createProDef(productCategory);
		bundleXtendProdDef.Name = 'Bundle Xtend';

		cscfga__Product_Definition__c bundleDigitalProdDef = TestDataSetupClass.createProDef(productCategory);
		bundleDigitalProdDef.Name = 'Bundle Digital';
		insert new List<cscfga__Product_Definition__c>{printLedProdDef, xtendLedProdDef, bundlePrintProdDef, bundleXtendProdDef, bundleDigitalProdDef};

		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
		insert soApi;

		cscfga__Product_Definition__c def = TestDataSetupClass.createProDef(TestDataSetupClass.createProdCateg());
		insert def;

		cscfga__Attribute_Definition__c attDef = TestDataSetupClass.createAttrDef(def);
		attDef.Name = 'Total Cost';

		cscfga__Attribute_Definition__c attDef1 = TestDataSetupClass.createAttrDef(def);
		insert new List<cscfga__Attribute_Definition__c>{attDef, attDef1};

		Account acc = TestDataSetupClass.createAccount();
		insert acc;

		Contact con = TestDataSetupClass.createContact(acc);
		insert con;

		Opportunity opp1 = TestDataSetupClass.createOpportunity(acc, con);
		Opportunity opp2 = TestDataSetupClass.createOpportunity(acc, con);
		Opportunity opp3 = TestDataSetupClass.createOpportunity(acc, con);
		insert new List<Opportunity>{opp1, opp2, opp3};

		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp1);
		so.Platform_Set__c        = '{Xtend}';
		so.csmso__Status__c       = 'Draft';
		so.Campaign_Length__c     = 6;
		so.Campaign_Start_Date__c = Date.today()+1;
		so.csmso__Total_Price__c  = 500;
		so.Dashboard__c           = True;
		so.Conversion_Tracking__c = True;
		so.Creative_Services__c   = True;
		insert so;

		cscfga__Product_Basket__c seasonalSOPB = TestDataSetupClass.createProdBasket(so);
		insert seasonalSOPB;

		News_Xtend_Product_Ref__c productRef = new News_Xtend_Product_Ref__c(Product_Line__c = 'Search',
																			 Product_Type__c = 'SEM',
																			 Name = 'NewsXtend');
		insert productRef;

		csmso__Product_Node__c productNode = new csmso__Product_Node__c(Name            = 'NewsXtend',
																		Product_Line__c = 'Campaign Management',
																		Product_Type__c = 'Call Tracking');
		insert productNode;

		cscfga__Product_Configuration__c config = TestDataSetupClass.createProdConfig(seasonalSOPB);
		config.cscfga__Product_Definition__c = bundlePrintProdDef.Id;
		config.Bundle_Name__c                = '';
		config.Platform__c                   = 'Xtend';
		config.Publication__c                = 'NewsXtend';
		config.Total_Print_Price__c          = 100;
		config.Duration_Months__c            = 6;
		config.Product_ID__c                 = productRef.Id;

		cscfga__Product_Configuration__c config2 = TestDataSetupClass.createProdConfig(seasonalSOPB);
		config2.cscfga__Product_Definition__c = bundlePrintProdDef.Id;
		config2.Bundle_Name__c                = '';
		config2.Platform__c                   = 'Xtend';
		config2.Publication__c                = 'NewsXtend';
		config2.Total_Print_Price__c          = 100;
		config2.Duration_Months__c            = 6;
		config2.Product_ID__c                 = productNode.Id;
		insert new List<cscfga__Product_Configuration__c>{config, config2};

		cscfga__Product_Basket__c basket = TestDataSetupClass.createProdBasket(so);
		insert basket;

		cscfga__Attribute__c att = TestDataSetupClass.createAttr(config, so, attDef);
		att.Name             = 'Total Cost';
		att.cscfga__Value__c = '100';

		cscfga__Attribute__c att1 = TestDataSetupClass.createAttr(config, so, attDef1);
		att1.Name             = 'Price';
		att1.cscfga__Value__c = '100';
		insert new List<cscfga__Attribute__c>{att, att1};

		List<Map_Orchestrator_Process__mdt> procTemplatesList = [SELECT Orchestrator_Process_Template_s__c, MasterLabel, DeveloperName FROM
																 Map_Orchestrator_Process__mdt
																 WHERE Key_Process_Identifier__c in ('Campaign Setup Recurring', 'Search Engine Marketing Recurring')];

		list<cspofa__orchestration_process_template__c> opts = new list<cspofa__orchestration_process_template__c>();

		for (Map_Orchestrator_Process__mdt mdt : procTemplatesList) {
			cspofa__orchestration_process_template__c opt = new cspofa__orchestration_process_template__c(Name = mdt.Orchestrator_Process_Template_s__c);
			opts.add(opt);
		}

		insert opts;

		system.debug(loggingLevel.ERROR, '####### opts ' + opts);

		Product_Order_Tier_Ranges__c tier = new Product_Order_Tier_Ranges__c(name = 'Tier 3', Lowerbound__c = 0, Upperbound__c = 2000, Tier_level__c = 'Tier 3' );
		insert tier;

		// Used by testValidateDataSheet()
		Document document;

		document               = new Document();
		document.Body          = Blob.valueOf('Header1,Header2,Header3\r\nYES,' + opp1.Id + ',NO\r\nNO,' + opp2.Id + ',YES\r\nYES,' + opp3.Id + ',YES,' + opp3.Id + ',F4,F5,F6,F7,' + opp3.Id + ',F9,F10,' + opp3.Id + ',F12,' + opp3.Id + ',' + opp3.Id + ',F16,F17,F18');
		document.ContentType   = 'application/pdf';
		document.DeveloperName = 'my_document';
		document.IsPublic      = true;
		document.Name          = 'My Document';
		document.FolderId      = UserInfo.getUserId();
		insert document;
	}
	
	static testMethod void testNoExistingOrder() {
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.csmso__Status__c = 'Externally Approved';
		
		Test.startTest();
		update so;
		Opportunity opp = [select Id from Opportunity where Name = 'testOpportunityForSalesOrderSupportTest' LIMIT 1];

		Database.executeBatch(new CS_DataCreation(new List<ID>{opp.Id}));
		Test.stopTest();
	}
	
    
	static testMethod void testExistingOrder() {
		Opportunity opp = [select Id from Opportunity where Name = 'testOpportunityForSalesOrderSupportTest' LIMIT 1];

		Order__c testOrder = new Order__c();
		testOrder.Opportunity__c = opp.id;
		testOrder.Status__c      = 'In Progress';

		insert testOrder;
		
		Test.startTest();
		Database.executeBatch(new CS_DataCreation(new List<ID>{opp.Id}));
		Test.stopTest();
	}

	static testMethod void testExistingProductOrder() {
		Opportunity opp    = [select Id from Opportunity where Name = 'testOpportunityForSalesOrderSupportTest' LIMIT 1];
		Order__c testOrder = new Order__c();
		testOrder.Opportunity__c = opp.id;
		testOrder.sales_Order__c = [select Id from csmso__Sales_Order__c limit 1].id;
		testOrder.Status__c      = 'In Progress';

		insert testOrder;

		cscfga__Product_Configuration__c config = [select Id from cscfga__Product_Configuration__c][0];

		// Create Product Order
		Product_Order__c po = new Product_Order__c();
		//po.Name = 'CS_ProductOrderTriggerDelegate_Test: Unit Test: Product Order';
		po.RecordType                  = [Select Id,SobjectType,Name From RecordType Where Name = 'Other' and SobjectType = 'Product_Order__c' Limit 1];
		po.Order__c                    = testOrder.id;
		po.Status__c                   = 'Draft';
		po.Product_Order_Start_Date__c = Date.today();
		po.PC_Id__c                    = config.Id;

		insert po;
		
		Test.startTest();
		Database.executeBatch(new CS_DataCreation(new List<ID>{opp.Id}));
		Test.stopTest();
	}

	static testMethod void testSocialSetup() {
		Opportunity opp                      = [select Id from Opportunity where Name = 'testOpportunityForSalesOrderSupportTest' LIMIT 1];
		News_Xtend_Product_Ref__c productRef = [select Id from News_Xtend_Product_Ref__c limit 1];
		productRef.Product_Line__c = 'Social';
		//productRef.Product_Type__c = 'Setup';

		update productRef;
		
		Test.startTest();
		Database.executeBatch(new CS_DataCreation(new List<ID>{opp.Id}));
		Test.stopTest();
	}

	static testMethod void myUnitTest_Display() {
		Opportunity opp                      = [select Id from Opportunity where Name = 'testOpportunityForSalesOrderSupportTest' LIMIT 1];
		News_Xtend_Product_Ref__c productRef = [select Id from News_Xtend_Product_Ref__c limit 1];
		productRef.Product_Line__c = 'Display';
		//productRef.Product_Type__c = 'Setup';

		update productRef;

		Test.startTest();
		Database.executeBatch(new CS_DataCreation(new List<ID>{opp.Id}));
		Test.stopTest();
	}

	static testMethod void myUnitTest_NoRecType() {
		Opportunity opp                      = [select Id from Opportunity where Name = 'testOpportunityForSalesOrderSupportTest' LIMIT 1];
		News_Xtend_Product_Ref__c productRef = [select Id from News_Xtend_Product_Ref__c limit 1];
		productRef.Product_Line__c = 'aaaa';
		//productRef.Product_Type__c = 'Setup';

		update productRef;
		
		Test.startTest();
		Database.executeBatch(new CS_DataCreation(new List<ID>{opp.Id}));
		Test.stopTest();
	}

	static testMethod void myUnitTest_EndDate() {
		csmso__Sales_Order__c so = [select Id from csmso__Sales_Order__c limit 1];
		so.Campaign_End_Date__c = system.today().addDays(120);
		update so;

		Opportunity opp = [select Id from Opportunity where Name = 'testOpportunityForSalesOrderSupportTest' LIMIT 1];

		Test.startTest();
		Database.executeBatch(new CS_DataCreation(new List<ID>{opp.Id}));
		Test.stopTest();
	}

	static testMethod void testValidateDataSheet() {
		Test.startTest();
		String sheetName = 'My Document';
		CS_DataCreation.validateDataSheet(sheetName);
		Test.stopTest();
	}

}
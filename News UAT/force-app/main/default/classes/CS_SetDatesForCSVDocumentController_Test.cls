@isTest(seeAllData=true)
public class CS_SetDatesForCSVDocumentController_Test  {

	@IsTest
	public static void testGetData(){
	
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
	    insert soApi;

		Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
            
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
		
		Product2 testProduct2 = new Product2();
		testProduct2.Name = 'test product';
		testProduct2.IsActive = true;
		insert testProduct2;

		Pricebook2 testPriceBook = new Pricebook2();
		testPriceBook.Name = 'test';
		testPriceBook.IsActive = true;
		insert testPriceBook;

		Id pricebookId = Test.getStandardPricebookId();

		PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProduct2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
		insert standardPrice;

		PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id, Product2Id = testProduct2.Id,
            UnitPrice = 12000, IsActive = true);
        insert customPrice;
            
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		opp.Pricebook2 = testPriceBook;
		opp.IsPrivate = false;
        insert opp;
            
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		so.Campaign_Start_Date__c = Date.today().addDays(-30);
		so.csmso__Status__c = 'Manually Approved';
		insert so;
            
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig.cscfga__Configuration_Status__c ='Valid';
        prodConfig.cscfga__Product_Definition__c = testProDef.id;
        insert prodConfig;
                    
        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);
        insert testAttrDef;

		cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;
        testAttr1.cscfga__Value__c = '1000';
        testAttr1.Name = 'Product Groups For IO';
        insert testAttr1;

		OpportunityLineItem oppLineItem = new OpportunityLineItem();
		oppLineItem.OpportunityId = opp.Id;
		oppLineItem.Quantity = 5;
		oppLineItem.TotalPrice = 100;
		oppLineItem.PriceBookEntryId = customPrice.Id;
		oppLineItem.Product2Id = testProduct2.Id;

		system.debug('***Matija' + JSON.serializePretty(oppLineItem));
		insert oppLineItem;

		Date startDate = Date.today().addDays(-80);
		Date endDate = Date.today().addDays(60);

		opp.StageName = 'Closed Won';
		opp.Classification__c = 'New Business';
		opp.Competitor__c ='Online - Other';
		opp.Payer_Account__c = acc.Id;
		opp.Opportunity_Type__c= 'Promotions';
		opp.OpportunityGroup__c = 'Digital';
		opp.Reason_Won_Lost__c = 'Editorial';
		opp.Description = 'Test';
		update opp;

		CS_SetDatesForCSVDocumentController controller = new CS_SetDatesForCSVDocumentController();
		controller.startDate = startDate;
		controller.endDate = endDate;

		Test.startTest();
			controller.getData();
			controller.attachNewFile();
		Test.stopTest();

		System.assertEquals(controller.numberOfRecords.contains('1'), True, 'There should be a product configuration');
		System.assertEquals(String.isBlank(controller.csvName), false, 'There should be a product configuration');
	}

	@IsTest
	public static void testSwitchedDate(){
		
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
	    insert soApi;
	    
		Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
            
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
		
		Product2 testProduct2 = new Product2();
		testProduct2.Name = 'test product';
		testProduct2.IsActive = true;
		insert testProduct2;

		Pricebook2 testPriceBook = new Pricebook2();
		testPriceBook.Name = 'test';
		testPriceBook.IsActive = true;
		insert testPriceBook;

		Id pricebookId = Test.getStandardPricebookId();

		PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProduct2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
		insert standardPrice;

		PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id, Product2Id = testProduct2.Id,
            UnitPrice = 12000, IsActive = true);
        insert customPrice;
            
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		opp.Pricebook2 = testPriceBook;
		opp.IsPrivate = false;
        insert opp;
            
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		so.Campaign_Start_Date__c = Date.today().addDays(-30);
		so.csmso__Status__c = 'Manually Approved';
		insert so;
            
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig.cscfga__Configuration_Status__c ='Valid';
        prodConfig.cscfga__Product_Definition__c = testProDef.id;
        insert prodConfig;
                    
        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);
        insert testAttrDef;

		cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;
        testAttr1.cscfga__Value__c = '1000';
        testAttr1.Name = 'Product Groups For IO';
        insert testAttr1;

		OpportunityLineItem oppLineItem = new OpportunityLineItem();
		oppLineItem.OpportunityId = opp.Id;
		oppLineItem.Quantity = 5;
		oppLineItem.TotalPrice = 100;
		oppLineItem.PriceBookEntryId = customPrice.Id;
		oppLineItem.Product2Id = testProduct2.Id;
		insert oppLineItem;

		Date startDate = Date.today().addDays(60);
		Date endDate = Date.today().addDays(-80);

		opp.StageName = 'Closed Won';
		opp.Classification__c = 'New Business';
		opp.Competitor__c ='Online - Other';
		opp.Payer_Account__c = acc.Id;
		opp.Opportunity_Type__c= 'Promotions';
		opp.OpportunityGroup__c = 'Digital';
		opp.Reason_Won_Lost__c = 'Editorial';
		opp.Description = 'Test';
		update opp;

		CS_SetDatesForCSVDocumentController controller = new CS_SetDatesForCSVDocumentController();
		controller.startDate = startDate;
		controller.endDate = endDate;

		Test.startTest();
			controller.getData();
		Test.stopTest();

		System.assertEquals(controller.startDate, endDate, 'There should be a product configuration');
		System.assertEquals(controller.endDate, startDate, 'There should be a product configuration');
	}

	@IsTest
	public static void testNoDate() {
			
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
	    insert soApi;

		Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
            
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
		
		Product2 testProduct2 = new Product2();
		testProduct2.Name = 'test product';
		testProduct2.IsActive = true;
		insert testProduct2;

		Pricebook2 testPriceBook = new Pricebook2();
		testPriceBook.Name = 'test';
		testPriceBook.IsActive = true;
		insert testPriceBook;

		Id pricebookId = Test.getStandardPricebookId();

		PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProduct2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
		insert standardPrice;

		PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id, Product2Id = testProduct2.Id,
            UnitPrice = 12000, IsActive = true);
        insert customPrice;
            
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		opp.Pricebook2 = testPriceBook;
		opp.IsPrivate = false;
        insert opp;		
            
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		so.Campaign_Start_Date__c = Date.today().addDays(-30);
		so.csmso__Status__c = 'Manually Approved';
		insert so;
            
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig.cscfga__Configuration_Status__c ='Valid';
        prodConfig.cscfga__Product_Definition__c = testProDef.id;
        insert prodConfig;
                    
        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);
        insert testAttrDef;

		cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;
        testAttr1.cscfga__Value__c = '1000';
        testAttr1.Name = 'Product Groups For IO';
        insert testAttr1;

		OpportunityLineItem oppLineItem = new OpportunityLineItem();
		oppLineItem.OpportunityId = opp.Id;
		oppLineItem.Quantity = 5;
		oppLineItem.TotalPrice = 100;
		oppLineItem.PriceBookEntryId = customPrice.Id;
		oppLineItem.Product2Id = testProduct2.Id;
		insert oppLineItem;

		Date startDate = Date.today().addDays(60);
		Date endDate = Date.today().addDays(-80);

		opp.StageName = 'Closed Won';
		opp.Classification__c = 'New Business';
		opp.Competitor__c ='Online - Other';
		opp.Payer_Account__c = acc.Id;
		opp.Opportunity_Type__c= 'Promotions';
		opp.OpportunityGroup__c = 'Digital';
		opp.Reason_Won_Lost__c = 'Editorial';
		opp.Description = 'Test';
		update opp;

		CS_SetDatesForCSVDocumentController controller = new CS_SetDatesForCSVDocumentController();
		
		Test.startTest();
			controller.getData();
		Test.stopTest();

		System.assertEquals(controller.rendered, false, 'Rendered must be false as there is no date');
	}

	@IsTest
	public static void testNoConfigurations(){
	
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
	    insert soApi;

		Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
            
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
		
		Product2 testProduct2 = new Product2();
		testProduct2.Name = 'test product';
		testProduct2.IsActive = true;
		insert testProduct2;

		Pricebook2 testPriceBook = new Pricebook2();
		testPriceBook.Name = 'test';
		testPriceBook.IsActive = true;
		insert testPriceBook;

		Id pricebookId = Test.getStandardPricebookId();

		PricebookEntry standardPrice = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = testProduct2.Id, UnitPrice = 10000, IsActive = true, UseStandardPrice = false);
		insert standardPrice;

		PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = testPriceBook.Id, Product2Id = testProduct2.Id,
            UnitPrice = 12000, IsActive = true);
        insert customPrice;
            
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		opp.Pricebook2 = testPriceBook;
		opp.IsPrivate = false;
        insert opp;		
            
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		so.Campaign_Start_Date__c = Date.today().addDays(-30);
		so.csmso__Status__c = 'Manually Approved';
		insert so;
            
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig.cscfga__Configuration_Status__c ='Valid';
        prodConfig.cscfga__Product_Definition__c = testProDef.id;
        insert prodConfig;
                    
        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);
        insert testAttrDef;

		cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig,so ,testAttrDef);
        testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;
        testAttr1.cscfga__Value__c = '1000';
        testAttr1.Name = 'Product Groups For IO';
        insert testAttr1;

		OpportunityLineItem oppLineItem = new OpportunityLineItem();
		oppLineItem.OpportunityId = opp.Id;
		oppLineItem.Quantity = 5;
		oppLineItem.TotalPrice = 100;
		oppLineItem.PriceBookEntryId = customPrice.Id;
		oppLineItem.Product2Id = testProduct2.Id;
		insert oppLineItem;

		Date startDate = Date.today();
		Date endDate = Date.today();

		opp.StageName = 'Closed Won';
		opp.Classification__c = 'New Business';
		opp.Competitor__c ='Online - Other';
		opp.Payer_Account__c = acc.Id;
		opp.Opportunity_Type__c= 'Promotions';
		opp.OpportunityGroup__c = 'Digital';
		opp.Reason_Won_Lost__c = 'Editorial';
		opp.Description = 'Test';
		update opp;

		CS_SetDatesForCSVDocumentController controller = new CS_SetDatesForCSVDocumentController();
		controller.startDate = startDate;
		controller.endDate = endDate;

		Test.startTest();
			controller.getData();
		Test.stopTest();

		System.assertEquals(controller.rendered, false, 'Rendered should be false since there is no product configuration');
	}
}
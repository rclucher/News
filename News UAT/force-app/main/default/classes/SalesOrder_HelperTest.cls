@isTest
private class SalesOrder_HelperTest {

	@testSetup static void setup() {

		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
		insert soApi;

		/*
		 * Create Products
		 */
		Pricebook2 pb = TestDataSetupClass.createPriceBook();
		insert pb;

		// Print
		Product2 product2Print = TestDataSetupClass.createProduct2('The Advertiser');
		// Digital
		Product2 product2Digital = TestDataSetupClass.createProduct2('RoN medrec roadblock Desktop');
		// Xtend
		Product2 product2Xtend = TestDataSetupClass.createProduct2('NewsXtend');
		insert new List<Product2> {product2Print, product2Digital, product2Xtend};

		PriceBookEntry printPbe = TestDataSetupClass.createPriceBookEntry(product2Print);
		PriceBookEntry digitalPbe = TestDataSetupClass.createPriceBookEntry(product2Digital);
		PriceBookEntry xtendPbe = TestDataSetupClass.createPriceBookEntry(product2Xtend);
		insert new List<PriceBookEntry> {printPbe, digitalPbe, xtendPbe};
		//print
		Publication_Product__c pbPrint = TestDataSetupClass.createPublicationProduct(product2Print);
		pbPrint.Publication__c = 'The Advertiser';
		//digital
		Publication_Product__c pbDigital = TestDataSetupClass.createPublicationProduct(product2Digital);
		pbDigital.Publication__c = 'RoN medrec roadblock Desktop';
		//extend
		Publication_Product__c pbXtend = TestDataSetupClass.createPublicationProduct(product2Xtend);
		pbXtend.Publication__c = 'NewsXtend';
		insert new List<Publication_Product__c>{pbPrint, pbDigital, pbXtend};

		// create Opportunity object with two Sales Orders, one verified and one not.
		Account account = TestDataSetupClass.createAccount();
		insert account;

		Contact contact = TestDataSetupClass.createContact(account);
		insert contact;

		Opportunity opportunity = TestDataSetupClass.createOpportunity(account, contact);
		insert opportunity;

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

		cscfga__Product_Definition__c printDisplayProdDef = TestDataSetupClass.createProDef(productCategory);
		printDisplayProdDef.Name = 'Print Display';
		
		insert new List<cscfga__Product_Definition__c>{printLedProdDef, xtendLedProdDef, bundlePrintProdDef, bundleXtendProdDef, bundleDigitalProdDef, printDisplayProdDef};

		/*
		 * Seasonal Bundle Sales Order
		 */
		csmso__Sales_Order__c seasonalSO = TestDataSetupClass.createSalesOrder(account, opportunity);
		seasonalSO.csmso__Status__c = 'Draft';
		// Campaign_Length__c is calculated via Sales Order Update Campaign Dates Workflow Rule
		seasonalSO.csmso__From__c     = Date.newInstance(2018, 03, 23);
		seasonalSO.csmso__To__c       = seasonalSO.csmso__From__c.addMonths(6);
		seasonalSO.Campaign_Length__c = 6;
		seasonalSO.Campaign_Name__c   = 'Seasonal';

		insert seasonalSO;

		cscfga__Product_Basket__c seasonalSOPB = TestDataSetupClass.createProdBasket(seasonalSO);
		insert seasonalSOPB;

		// bundle PC
		cscfga__Product_Configuration__c bundlePC1 = TestDataSetupClass.createProdConfig(seasonalSOPB);
		bundlePC1.cscfga__Product_Definition__c = printLedProdDef.Id;
		bundlePC1.Bundle_Name__c                = 'Always-On LITE';
		insert bundlePC1;

		cscfga__Product_Configuration__c bundlePrintPC1 = TestDataSetupClass.createProdConfig(seasonalSOPB);
		bundlePrintPC1.cscfga__Parent_Configuration__c = bundlePC1.Id;
		bundlePrintPC1.cscfga__Product_Definition__c   = bundlePrintProdDef.Id;
		bundlePrintPC1.Bundle_Name__c                  = '';
		bundlePrintPC1.Platform__c                     = 'Print';
		bundlePrintPC1.Publication__c                  = 'The Advertiser';
		bundlePrintPC1.Total_Print_Price__c            = 100;
		bundlePrintPC1.Duration_Months__c              = 6;

		cscfga__Product_Configuration__c bundleDigitalPC1 = TestDataSetupClass.createProdConfig(seasonalSOPB);
		bundleDigitalPC1.cscfga__Parent_Configuration__c = bundlePC1.Id;
		bundleDigitalPC1.cscfga__Product_Definition__c   = bundleDigitalProdDef.Id;
		bundleDigitalPC1.Bundle_Name__c                  = '';
		bundleDigitalPC1.Platform__c                     = 'Digital';
		bundleDigitalPC1.Bespoke_Digital_Description__c  = 'RoN medrec roadblock Desktop';
		bundleDigitalPC1.Total_Digital_Price__c          = 100;
		bundleDigitalPC1.Duration_Months__c              = 6;

		cscfga__Product_Configuration__c bundleXtendPC1 = TestDataSetupClass.createProdConfig(seasonalSOPB);
		bundleXtendPC1.cscfga__Parent_Configuration__c = bundlePC1.Id;
		bundleXtendPC1.cscfga__Product_Definition__c   = bundleXtendProdDef.Id;
		bundleXtendPC1.Bundle_Name__c                  = '';
		bundleXtendPC1.Platform__c                     = 'Xtend';
		bundleXtendPC1.Total_Invoice__c                = 100;
		bundleXtendPC1.Duration_Months__c              = 6;

		cscfga__Product_Configuration__c bundleXtendPC2 = TestDataSetupClass.createProdConfig(seasonalSOPB);
		bundleXtendPC2.cscfga__Parent_Configuration__c = bundlePC1.Id;
		bundleXtendPC2.cscfga__Product_Definition__c   = bundleXtendProdDef.Id;
		bundleXtendPC2.Bundle_Name__c                  = '';
		bundleXtendPC2.Platform__c                     = 'Xtend';
		bundleXtendPC2.Total_Invoice__c                = 200;
		bundleXtendPC2.Duration_Months__c              = 6;

		cscfga__Product_Configuration__c nonExistingProductPC1 = TestDataSetupClass.createProdConfig(seasonalSOPB);
		nonExistingProductPC1.cscfga__Parent_Configuration__c = bundlePC1.Id;
		nonExistingProductPC1.cscfga__Product_Definition__c   = bundlePrintProdDef.Id;
		nonExistingProductPC1.Bundle_Name__c                  = '';
		nonExistingProductPC1.Platform__c                     = 'Print';
		nonExistingProductPC1.Publication__c                  = 'Non Existing Publication';
		nonExistingProductPC1.Total_Print_Price__c            = 100;
		nonExistingProductPC1.Duration_Months__c              = 6;

		cscfga__Product_Configuration__c nonExistingProductPC2 = TestDataSetupClass.createProdConfig(seasonalSOPB);
		nonExistingProductPC2.cscfga__Parent_Configuration__c = bundlePC1.Id;
		nonExistingProductPC2.cscfga__Product_Definition__c   = bundleDigitalProdDef.Id;
		nonExistingProductPC2.Bundle_Name__c                  = '';
		nonExistingProductPC2.Platform__c                     = 'Digital';
		nonExistingProductPC2.Publication__c                  = 'Non Existing Digital';
		nonExistingProductPC2.Total_Digital_Price__c          = 100;
		nonExistingProductPC2.Duration_Months__c              = 6;

		cscfga__Product_Configuration__c printDisplay = TestDataSetupClass.createProdConfig(seasonalSOPB);
		printDisplay.cscfga__Parent_Configuration__c = bundlePC1.Id;
		printDisplay.cscfga__Product_Definition__c   = printDisplayProdDef.Id;
		printDisplay.Bundle_Name__c                  = '';
		printDisplay.Platform__c                     = 'Print';
		printDisplay.Publication__c                  = 'Non Existing print';
		printDisplay.Total_Digital_Price__c          = 100;
		printDisplay.Duration_Months__c              = 6;
		insert new List<cscfga__Product_Configuration__c>{bundlePrintPC1, bundleDigitalPC1, bundleXtendPC1, bundleXtendPC2, nonExistingProductPC1, nonExistingProductPC2, printDisplay};

		/*
		 * Evergreen Bundle Sales Order
		 */
		csmso__Sales_Order__c evergreenSO = TestDataSetupClass.createSalesOrder(account, opportunity);
		evergreenSO.csmso__Status__c       = 'Draft';
		evergreenSO.Campaign_Start_Date__c = Date.newInstance(2018, 03, 24);
		evergreenSO.Campaign_Name__c       = 'Evergreen';

		insert evergreenSO;

		cscfga__Product_Basket__c evergreenSOPB = TestDataSetupClass.createProdBasket(evergreenSO);
		insert evergreenSOPB;

		// bundle PC
		cscfga__Product_Configuration__c bundlePC2 = TestDataSetupClass.createProdConfig(evergreenSOPB);
		bundlePC2.cscfga__Product_Definition__c = xtendLedProdDef.Id;
		bundlePC2.Bundle_Name__c                = 'Always-On LITE';
		insert bundlePC2;

		cscfga__Product_Configuration__c bundlePrintPC2 = TestDataSetupClass.createProdConfig(evergreenSOPB);
		bundlePrintPC2.cscfga__Parent_Configuration__c = bundlePC2.Id;
		bundlePrintPC2.cscfga__Product_Definition__c   = bundlePrintProdDef.Id;
		bundlePrintPC2.Bundle_Name__c                  = '';
		bundlePrintPC2.Platform__c                     = 'Print';
		bundlePrintPC2.Publication__c                  = 'The Advertiser';
		bundlePrintPC2.Total_Print_Price__c            = 100;
		bundlePrintPC2.Duration_Months__c              = 36;

		cscfga__Product_Configuration__c bundleDigitalPC2 = TestDataSetupClass.createProdConfig(evergreenSOPB);
		bundleDigitalPC2.cscfga__Parent_Configuration__c = bundlePC2.Id;
		bundleDigitalPC2.cscfga__Product_Definition__c   = bundleDigitalProdDef.Id;
		bundleDigitalPC2.Bundle_Name__c                  = '';
		bundleDigitalPC2.Platform__c                     = 'Digital';
		bundleDigitalPC2.Bespoke_Digital_Description__c  = 'RoN medrec roadblock Desktop';
		bundleDigitalPC2.Total_Digital_Price__c          = 100;
		bundleDigitalPC2.Duration_Months__c              = 36;

		cscfga__Product_Configuration__c bundleXtendPC3 = TestDataSetupClass.createProdConfig(evergreenSOPB);
		bundleXtendPC3.cscfga__Parent_Configuration__c = bundlePC2.Id;
		bundleXtendPC3.cscfga__Product_Definition__c   = bundleXtendProdDef.Id;
		bundleXtendPC3.Bundle_Name__c                  = '';
		bundleXtendPC3.Platform__c                     = 'Xtend';
		bundleXtendPC3.Total_Invoice__c                = 100;
		bundleXtendPC3.Duration_Months__c              = 36;
		insert new List<cscfga__Product_Configuration__c>{bundlePrintPC2, bundleDigitalPC2, bundleXtendPC3};
	}

	@isTest static void testSeasonalSalesOrder() {
		csmso__Sales_Order__c seasonalSO = [SELECT Id FROM csmso__Sales_Order__c WHERE Campaign_Name__c = 'Seasonal' LIMIT 1];

		//Setystem.debug('SalesOrder_HelperTest +++++++++++++++++++++++++++++' + seasonalSO);

		Test.startTest();

		// covers createOpportunityProducts()
		seasonalSO.csmso__Status__c = 'Externally Approved';
		update seasonalSO;

		// covers opportunityHasApprovedSOAfter()
		seasonalSO.csmso__Status__c = 'Verified';
		update seasonalSO;

		delete seasonalSO;

		Test.stopTest();
	}

	@isTest static void testEvergreenSalesOrder() {

		csmso__Sales_Order__c evergreenSO = [SELECT Id FROM csmso__Sales_Order__c WHERE Campaign_Name__c = 'Evergreen' LIMIT 1];

		Test.startTest();

		// covers createOpportunityProducts()
		evergreenSO.csmso__Status__c = 'Externally Approved';
		update evergreenSO;

		// covers opportunityHasApprovedSOAfter()
		evergreenSO.csmso__Status__c = 'Verified';
		update evergreenSO;

		delete evergreenSO;

		Test.stopTest();
	}

	/**
	 * Confirms that updating status from something to Sent for... ones will initiate sync
	 */
	@isTest static void testAutoSync() {

		csmso__Sales_Order__c evergreenSO = [SELECT Id FROM csmso__Sales_Order__c WHERE Campaign_Name__c = 'Evergreen' LIMIT 1];

		Test.startTest();
		//change status from Draft
		evergreenSO.csmso__Status__c = 'Sent For Internal Approval';
		update evergreenSO;
		//moving to another auto-sync status to trigger 2nd part of auto-sync logic
		evergreenSO.csmso__Status__c = 'Sent For External Approval';
		update evergreenSO;

		Test.stopTest();
	}

	/**
	 * Confirms that updating status from something to approved ones will initiate sync.
	 */
	@isTest static void testOnApprovalSync() {

		csmso__Sales_Order__c evergreenSO = [SELECT Id FROM csmso__Sales_Order__c WHERE Campaign_Name__c = 'Evergreen' LIMIT 1];

		Test.startTest();
		//change status from Draft
		evergreenSO.csmso__Status__c = 'Externally Approved';
		update evergreenSO;

		Test.stopTest();
	}

	/**
	 * Confirms that killing SO desyncs it.
	 * Also tests manual sync (not from trigger context).
	 */
	@isTest static void testDeSync() {
		List<csmso__Sales_Order__c> salesOrder = [SELECT Id, Name, csmso__Status__c, Invalid_Config_Count__c, Is_Synched__c,
												  csmso__Opportunity__c, csmso__Opportunity__r.Name, csmso__Opportunity__r.Has_an_Approved_SO__c
												  FROM csmso__Sales_Order__c
												  WHERE Campaign_Name__c = 'Evergreen' LIMIT 1];

		Test.startTest();
		//sync first
		String resyncResult = SalesOrder_Helper.syncWithOpportunity(salesOrder);
		//change status to Killed to desync
		salesOrder[0].csmso__Status__c = 'Killed';
		update salesOrder[0];

		Test.stopTest();
	}
}
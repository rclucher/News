@isTest
private class CS_OpportunitySOCloneControllerTest {
	/**
	 * Campaign not ended opportunities cannot be cloned.
	 */
	@isTest static void campaignNotEnded() {
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		//execute the logic
		Test.startTest();
		String result = CS_OpportunitySOCloneController.clone(opp.Id, 'Cloned Opp Name');
		Test.stopTest();
		//Test cloning results
		System.AssertEquals(true, result.contains('Re-Order is only possible on Ended Campaigns.'));
	}

	/**
	 * Campaign still live opportunities cannot be cloned.
	 */
	@isTest static void campaignStillLive() {
		//Update created Campaign Order to be live
		Order__c order = [SELECT Id FROM Order__c LIMIT 1];
		order.Status__c = 'Campaign Live';
		update order;
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		//execute the logic
		Test.startTest();
		String result = CS_OpportunitySOCloneController.clone(opp.Id, 'Cloned Opp Name');
		Test.stopTest();
		//Test cloning results
		System.AssertEquals(true, result.contains('This campaign is still Live. You cannot re-order at this time.'));
	}

	/**
	 * Campaign ended opportunities should be cloned successfully.
	 */
	@isTest static void campaignEndedCloneAllowed() {
		//Update created Campaign Order to be ended
		Order__c order = [SELECT Id FROM Order__c LIMIT 1];
		order.Status__c = 'Campaign Ended';
		update order;
		Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
		//execute the logic
		Test.startTest();
		String result = CS_OpportunitySOCloneController.clone(opp.Id, 'Cloned Opp Name');
		Test.stopTest();
		//Test cloning results
		System.AssertNotEquals(null, result);
		CS_LightningResponse response = (CS_LightningResponse)JSON.deserialize(result, CS_LightningResponse.class);
		System.AssertEquals(2000, response.code);
		System.AssertEquals('success', response.message);
	}

	/**
	 * Create necessary data for test:
	 * -Various product configurations
	 * -Question, Rule, Answer and Answer to Rule junction
	 * -Opportunity
	 * -Sales Order that is synced (by approving it) with Opportunity thus creating Opportunity Line Items
	 * -Campaign Order (created once opportunity is closed won)
	 */
	@testSetup static void setup() {
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
		insert soApi;

		//Create Products
		Pricebook2 pb = TestDataSetupClass.createPriceBook();
		insert pb;
		Product2 product2Print   = TestDataSetupClass.createProduct2('The Advertiser');
		Product2 product2Digital = TestDataSetupClass.createProduct2('RoN medrec roadblock Desktop');
		Product2 product2Xtend   = TestDataSetupClass.createProduct2('NewsXtend');
		insert new List<Product2> {product2Print, product2Digital, product2Xtend};
		//creating PBE
		PriceBookEntry printPbe   = TestDataSetupClass.createPriceBookEntry(product2Print);
		PriceBookEntry digitalPbe = TestDataSetupClass.createPriceBookEntry(product2Digital);
		PriceBookEntry xtendPbe   = TestDataSetupClass.createPriceBookEntry(product2Xtend);
		insert new List<PriceBookEntry> {printPbe, digitalPbe, xtendPbe};

		Publication_Product__c pbPrint   = TestDataSetupClass.createPublicationProduct(product2Print);
		Publication_Product__c pbDigital = TestDataSetupClass.createPublicationProduct(product2Digital);
		Publication_Product__c pbXtend   = TestDataSetupClass.createPublicationProduct(product2Xtend);
		pbPrint.Publication__c   = 'The Advertiser';
		pbDigital.Publication__c = 'RoN medrec roadblock Desktop';
		pbXtend.Publication__c   = 'NewsXtend';
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

		cscfga__Product_Definition__c printLedProdDef      = TestDataSetupClass.createProDef(productCategory);
		cscfga__Product_Definition__c xtendLedProdDef      = TestDataSetupClass.createProDef(productCategory);
		cscfga__Product_Definition__c bundlePrintProdDef   = TestDataSetupClass.createProDef(productCategory);
		cscfga__Product_Definition__c bundleXtendProdDef   = TestDataSetupClass.createProDef(productCategory);
		cscfga__Product_Definition__c bundleDigitalProdDef = TestDataSetupClass.createProDef(productCategory);
		cscfga__Product_Definition__c printDisplayProdDef  = TestDataSetupClass.createProDef(productCategory);
		//updating names
		printLedProdDef.Name      = 'Print Led';
		xtendLedProdDef.Name      = 'News Xtend Led';
		bundlePrintProdDef.Name   = 'Bundle Print';
		bundleXtendProdDef.Name   = 'Bundle Xtend';
		bundleDigitalProdDef.Name = 'Bundle Digital';
		printDisplayProdDef.Name  = 'Print Display';

		insert new List<cscfga__Product_Definition__c>{printLedProdDef, xtendLedProdDef, bundlePrintProdDef, bundleXtendProdDef, bundleDigitalProdDef, printDisplayProdDef};

		//Evergreen Bundle Sales Order
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

		//Create question, rule and answer for our opp
		Question2__c question = new Question2__c(Question_Text__c = 'My question');
		insert question;

		Rule__c rule = new Rule__c(
			Question2__c = question.Id,
			When_to_Ask__c = 'Opportunity',
			isActive__c = true,
			Question_Type__c = 'Universal');
		insert rule;

		Answer2__c answer = new Answer2__c(
			Answer_Text__c = 'My answer',
			Question2__c = question.Id);
		insert answer;

		Answer_to_Rule__c a2r = new Answer_to_Rule__c(
			Rule__c = rule.Id,
			Answer2__c = answer.Id,
			Opportunity__c = opportunity.Id);
		insert a2r;

		//Approve SO, sync with Opp and then close the Opp, set all mandatory fields
		//We are close to limits to start fresh
		Test.startTest();
		evergreenSO.csmso__Status__c = 'Manually Approved';
		update evergreenSO;

		opportunity.StageName         = 'Closed Won';
		opportunity.Classification__c = 'Existing Business';
		opportunity.Competitor__c     = 'Cinema';
		update opportunity;
		Test.stopTest();
	}
}
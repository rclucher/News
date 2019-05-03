@isTest
private class ButtonSOPricingCalculatorTest {

	@testSetup static void setup() {
		Account account = TestDataSetupClass.createAccount();
		account.TotalNewsCorpSpend__c  = 49000.00;
		account.CustomerDiscount__c    = 0.50;
		account.Share_of_Wallet__c     = '<50%';
		account.Print_Customer_Tier__c = 'AAA';     // why is this not updating SOs via process builder? IV
		account.Customer_Segment__c    = 'SME';
		account.BillingState           = 'NSW';
		insert account;

		Contact contact = TestDataSetupClass.createContact(account);
		insert contact;

		Opportunity opportunity = TestDataSetupClass.createOpportunity(account, contact);
		insert opportunity;

		Date soDateFrom = Date.today();
		soDateFrom = soDateFrom.addMonths(1);

		Date soDateTo = Date.today();
		soDateTo = soDateTo.addMonths(2);
		
		csmso__Sales_Order__c salesOrder1 = TestDataSetupClass.createSalesOrder(account, opportunity);
		salesOrder1.Platform_Set__c = '';
		salesOrder1.csmso__From__c  = soDateFrom;
		salesOrder1.csmso__To__c    = soDateTo;
		
		csmso__Sales_Order__c salesOrder2 = TestDataSetupClass.createSalesOrder(account, opportunity);
		salesOrder2.Platform_Set__c            = '{Print}';
		salesOrder2.csmso__From__c             = soDateFrom;
		salesOrder2.csmso__To__c               = soDateTo;
		salesOrder2.Proposed_Print_Discount__c = 10;
		salesOrder2.Customer_Segment__c = 'SME';
		salesOrder2.Print_Customer_Tier__c = 'AAA';
		

		csmso__Sales_Order__c salesOrder3 = TestDataSetupClass.createSalesOrder(account, opportunity);
		salesOrder3.Platform_Set__c            = '{Digital}';
		salesOrder3.csmso__From__c             = soDateFrom;
		salesOrder3.csmso__To__c               = soDateTo;
		salesOrder3.Proposed_Print_Discount__c = null;
		

		List<csmso__Sales_Order__c> salesOrders = new List<csmso__Sales_Order__c>{salesOrder1, salesOrder2, salesOrder3};
		insert salesOrders;

		cscfga__Product_Basket__c productBasket1 = TestDataSetupClass.createProdBasket(salesOrder1);
		cscfga__Product_Basket__c productBasket2 = TestDataSetupClass.createProdBasket(salesOrder2);
		cscfga__Product_Basket__c productBasket3 = TestDataSetupClass.createProdBasket(salesOrder3);

		List<cscfga__Product_Basket__c> productBaskets = new List<cscfga__Product_Basket__c>{productBasket1, productBasket2, productBasket3};
		insert productBaskets;

		cscfga__Product_Configuration__c productConfig1 = TestDataSetupClass.createProdConfig(productbasket1);
		cscfga__Product_Configuration__c productConfig2 = TestDataSetupClass.createProdConfig(productbasket2);
		cscfga__Product_Configuration__c productConfig3 = TestDataSetupClass.createProdConfig(productbasket3);

		List<cscfga__Product_Configuration__c> productConfigs = new List<cscfga__Product_Configuration__c>{productConfig1, productConfig2, productConfig3};
		insert productConfigs;
		//create Client Value Score
		List<Client_Value_Score__c> cvsList = new List<Client_Value_Score__c>{
			new Client_Value_Score__c(Platform__c = 'Print', Customer_Tier__c = 'AAA', Points_From__c = null, Points_To__c = -1, Discount__c = 0),
			new Client_Value_Score__c(Platform__c = 'Print', Customer_Tier__c = 'AAA', Points_From__c = 0, Points_To__c = 1, Discount__c = 2),
			new Client_Value_Score__c(Platform__c = 'Print', Customer_Tier__c = 'AAA', Points_From__c = 2, Points_To__c = null, Discount__c = 3)
		};
		insert cvsList;
		//create Client Value Points
		List<Client_Value_Point__c> cvpList = new List<Client_Value_Point__c>{
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Insertion Count', Value__c = '1-5', Score__c = -1),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Insertion Count', Value__c = '6-10', Score__c = 0),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Insertion Count', Value__c = '11-15', Score__c = 2),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Insertion Count', Value__c = '16+', Score__c = 3),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Share of Wallet', Value__c = '<50%', Score__c = 0),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Share of Wallet', Value__c = '>=50%', Score__c = 1),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Share of Wallet', Value__c = '100%', Score__c = 2),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Product Mix', Value__c = '{Print}', Score__c = 0),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Product Mix', Value__c = '{Print, Xtend}', Score__c = 1),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Product Mix', Value__c = '{Digital, Print, Xtend}', Score__c = 2),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Number of Publications', Value__c = '1', Score__c = -1),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Number of Publications', Value__c = '2', Score__c = 0),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Number of Publications', Value__c = '3', Score__c = 1),
			new Client_Value_Point__c(Platform__c = 'Print', Name__c = 'Number of Publications', Value__c = '4+', Score__c = 2)
		};
		insert cvpList;

		User currentUser = [SELECT ID, Title FROM User WHERE ID =: UserInfo.getUserId()];

		Discount_Threshold__c discountThresholds = new Discount_Threshold__c(
			Discount_Level_1__c = 60,
			Discount_Level_2__c = 70,
			Discount_Level_3__c = 80,
			Discount_Level_4__c = 90,
			Amount_Level_1__c  = 75000,
			Amount_Level_2__c  = 250000,
			Amount_Level_3__c  = 750000,
			Amount_Level_4__c  = 1000000,
			Segment__c = 'SME',
			Customer_Tier__c = 'AAA',
			Platform__c      = 'Print');
		insert discountThresholds;
	}

	// no valid platform found in Sales Order
	@isTest static void testNoPlatformFoundInSO() {
		Date soDateFrom = Date.today();
		soDateFrom = soDateFrom.addMonths(1);

		Date soDateTo = Date.today();
		soDateTo = soDateTo.addMonths(2);

		csmso__Sales_Order__c salesOrder = [SELECT csmso__From__c,
											csmso__To__c,
											Platform_Set__c,
											Client_Gross_Revenue__c,
											Client_Current_Discount_FY__c,
											Share_of_Wallet__c,
											Print_Customer_Tier__c,
											csmso__Advertiser__r.Digital_Customer_Tier__c,          // will be replaced by SO field
											Customer_Segment__c,
											Customer_State__c,
											Proposed_Print_Discount__c
											FROM csmso__Sales_Order__c LIMIT 1];
											//WHERE Platform_Set__c = ''];

	    salesOrder.Platform_Set__c = '';
		salesOrder.csmso__From__c  = soDateFrom;
		salesOrder.csmso__To__c    = soDateTo;
		update salesOrder;
		Test.startTest();

		ButtonSOPricingCalculator testObject = new ButtonSOPricingCalculator();
		String returnedJson                  = testObject.performAction(salesOrder.Id);

		String expectedJson = '{"status": "ok" , "message" : "No print products to update."}';

		System.assertEquals(returnedJson, expectedJson);

		Test.stopTest();
	}

	// Print platform found in Sales Order
	@isTest static void testPrintPlatformFoundInSO() {
		Date soDateFrom = Date.today();
		soDateFrom = soDateFrom.addMonths(1);

		Date soDateTo = Date.today();
		soDateTo = soDateTo.addMonths(2);
		
		csmso__Sales_Order__c salesOrder = [SELECT csmso__From__c,
											csmso__To__c,
											Platform_Set__c,
											Client_Gross_Revenue__c,
											Client_Current_Discount_FY__c,
											Share_of_Wallet__c,
											Print_Customer_Tier__c,
											csmso__Advertiser__r.Digital_Customer_Tier__c,          // will be replaced by SO field
											Customer_Segment__c,
											Customer_State__c,
											Proposed_Print_Discount__c
											FROM csmso__Sales_Order__c LIMIT 1];
											//WHERE Platform_Set__c = '{Print}' LIMIT 1 ];
		
		salesOrder.Platform_Set__c            = '{Print}';
		salesOrder.csmso__From__c             = soDateFrom;
		salesOrder.csmso__To__c               = soDateTo;
		salesOrder.Proposed_Print_Discount__c = 10;
		salesOrder.Customer_Segment__c = 'SME';
		salesOrder.Print_Customer_Tier__c = 'AAA';
		update salesOrder;
		Test.startTest();

		ButtonSOPricingCalculator testObject = new ButtonSOPricingCalculator();
		String returnedJson                  = testObject.performAction(salesOrder.Id);

		String expectedJson = '{"status": "ok" , "message" : "Proposed Discount distributed to Line items."}';

		System.assertEquals(returnedJson, expectedJson);

		Test.stopTest();
	}

	// Print platform found in Sales Order but no proposed discount set
	@isTest static void testPrintPlatformButNoProposedDiscountOnSO() {
		Date soDateFrom = Date.today();
		soDateFrom = soDateFrom.addMonths(1);

		Date soDateTo = Date.today();
		soDateTo = soDateTo.addMonths(2);

		csmso__Sales_Order__c salesOrder = [SELECT csmso__From__c,
											csmso__To__c,
											Platform_Set__c,
											Client_Gross_Revenue__c,
											Client_Current_Discount_FY__c,
											Share_of_Wallet__c,
											Print_Customer_Tier__c,
											csmso__Advertiser__r.Digital_Customer_Tier__c,          // will be replaced by SO field
											Customer_Segment__c,
											Customer_State__c,
											Proposed_Print_Discount__c
											FROM csmso__Sales_Order__c LIMIT 1];
											//WHERE Platform_Set__c = '{Print}'];
		//update generated data to match test case
		salesOrder.Platform_Set__c            = '{Print}';
		salesOrder.csmso__From__c             = soDateFrom;
		salesOrder.csmso__To__c               = soDateTo;
		salesOrder.Proposed_Print_Discount__c = 10;
		salesOrder.Customer_Segment__c = 'SME';
		salesOrder.Print_Customer_Tier__c = 'AAA';
		
		salesOrder.Proposed_Print_Discount__c = null;
		update salesOrder;
		Test.startTest();

		ButtonSOPricingCalculator testObject = new ButtonSOPricingCalculator();
		String returnedJson                  = testObject.performAction(salesOrder.Id);

		String expectedJson = '{"status": "ok" , "message" : "Proposed Discount has no value to distribute to Line items."}';

		System.assertEquals(returnedJson, expectedJson);

		Test.stopTest();
	}

	/**
	 * CVS recalculation test.
	 */
	@isTest static void testCVSrecalculation() {
		Date soDateFrom = Date.today();
		soDateFrom = soDateFrom.addMonths(1);

		Date soDateTo = Date.today();
		soDateTo = soDateTo.addMonths(2);

		csmso__Sales_Order__c salesOrder = [SELECT csmso__From__c,
											csmso__To__c,
											Platform_Set__c,
											Client_Gross_Revenue__c,
											Client_Current_Discount_FY__c,
											Share_of_Wallet__c,
											Print_Customer_Tier__c,
											csmso__Advertiser__r.Digital_Customer_Tier__c,          // will be replaced by SO field
											Customer_Segment__c,
											Customer_State__c,
											Proposed_Print_Discount__c,
											Calculated_Target_Discount__c,
											Print_Status__c,
											Print_Publication_Count__c,
											Print_Impressions_Count__c
											FROM csmso__Sales_Order__c LIMIT 1];
											//WHERE Platform_Set__c = '{Print}']; 
		
		salesOrder.Platform_Set__c            = '{Print}';
		salesOrder.csmso__From__c             = soDateFrom;
		salesOrder.csmso__To__c               = soDateTo;
		salesOrder.Proposed_Print_Discount__c = 10;
		salesOrder.Customer_Segment__c = 'SME';
		salesOrder.Print_Customer_Tier__c = 'AAA';
		update salesOrder;

		Test.startTest();
		salesOrder.Calculated_Target_Discount__c = 80;
		salesOrder.Client_Current_Discount_FY__c = 90;
		Map<String,List<Client_Value_Point__c>> cvpMap = ButtonSOPricingCalculator.getPlatformClientValuePointsMap('Print');
		List<Client_Value_Score__c> cvsList            = [SELECT Id,Customer_Tier__c, Points_From__c, Points_To__c, Discount__c
														  FROM Client_Value_Score__c
														  WHERE Platform__c = 'Print'];

		ButtonSOPricingCalculator.runCVSRecalculation(cvpMap, cvsList, salesOrder);
		//result is changed salesOrder
		System.assertEquals('Target discount recalculated.', salesOrder.Print_Status__c);

		Test.stopTest();
	}

	@isTest static void calculatePrintDiscountThreshold(){
		csmso__Sales_Order__c salesOrder = [SELECT csmso__From__c,
											csmso__To__c,
											Platform_Set__c,
											Client_Gross_Revenue__c,
											Client_Current_Discount_FY__c,
											Share_of_Wallet__c,
											Print_Customer_Tier__c,
											csmso__Advertiser__r.Digital_Customer_Tier__c,          // will be replaced by SO field
											Customer_Segment__c,
											Customer_State__c,
											Proposed_Print_Discount__c,
											Calculated_Target_Discount__c,
											Print_Status__c,
											Print_Publication_Count__c,
											Print_Impressions_Count__c
											FROM csmso__Sales_Order__c LIMIT 1];

		ButtonSOPricingCalculator.calculatePrintDiscountThreshold(salesOrder);
		
	}
}
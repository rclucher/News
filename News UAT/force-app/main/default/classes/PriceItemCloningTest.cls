@isTest
private class PriceItemCloningTest {
	private static List<cspmb__Price_Item__c> priceItems;

	/**
	 * Tests that Price Item validation logic makes sure we allow
	 * only some of Price Items to be cloned.
	 * Test case: date overlap causes validation error ERROR_MSG_DATE
	 */
	@isTest static void validationTestOverlap() {
		//using 1st price item we created
		priceItems = [SELECT Id, Name FROM cspmb__Price_Item__c ORDER BY Id];
		Test.setCurrentPage(Page.PriceItemCloning);
		ApexPages.StandardController stdController = new ApexPages.StandardController(priceItems[0]);
		PriceItemCloning controller                = new PriceItemCloning(stdController);

		Test.startTest();
		PageReference result = controller.clonePriceItems();
		Test.stopTest();
		//validate results
		System.assertEquals(true, ApexPages.hasMessages(), 'Validation message expected.');
		System.assertEquals(true, ApexPages.getMessages()[0].getSummary().contains('overlap with existing records'), 'Unexpected validation message!');
		System.assertEquals(null, result, 'Validation error, no redirect expected.');
	}

	/**
	 * Tests that Price Item validation logic makes sure we allow
	 * only some of Price Items to be cloned.
	 * Test case: using default Effective End Date causes validation error ERROR_MSG_END_DATE_UPDATE
	 */
	@isTest static void validationTestDefaultEndDate() {
		priceItems = [SELECT Id, Name FROM cspmb__Price_Item__c ORDER BY Id];
		Test.setCurrentPage(Page.PriceItemCloning);
		ApexPages.StandardController stdController = new ApexPages.StandardController(priceItems[2]);
		PriceItemCloning controller                = new PriceItemCloning(stdController);

		Test.startTest();
		PageReference result = controller.clonePriceItems();
		Test.stopTest();
		//validate results
		System.assertEquals(true, ApexPages.hasMessages(), 'Validation message expected.');
		System.assertEquals(true, ApexPages.getMessages()[0].getSummary().contains('Please set correct Effective End Date and try again'), 'Unexpected validation message!');
		System.assertEquals(null, result, 'Validation error, no redirect expected.');
	}

	/**
	 * Tests that Price Item validation logic makes sure we allow
	 * only some of Price Items to be cloned.
	 * Test case: using default Effective End Date would cause validation error ERROR_MSG_END_DATE_UPDATE
	 * but not when using Create New Bundle operation.
	 * Copy of validationTestDefaultEndDate test but expecting different outcome as we chose newBundle operation.
	 */
	@isTest static void validationTestDefaultEndDateNewBundle() {
		priceItems = [SELECT Id, Name FROM cspmb__Price_Item__c ORDER BY Id];
		Test.setCurrentPage(Page.PriceItemCloning);
		ApexPages.StandardController stdController = new ApexPages.StandardController(priceItems[2]);
		PriceItemCloning controller                = new PriceItemCloning(stdController);

		Test.startTest();
		controller.selectedOperation = 'newBundle';
		PageReference result = controller.clonePriceItems();
		Test.stopTest();
		//validate results
		System.assertEquals(false, ApexPages.hasMessages(), 'Validation message not expected.');
		System.assertNotEquals(null, result, 'Successful, redirect expected.');
	}

	/**
	 * Tests that Price Item validation logic makes sure we allow
	 * only some of Price Items to be cloned.
	 * Test case: having New Instance value causes validation error ERROR_MSG_USE_NEW
	 */
	@isTest static void validationTestNewInstance() {
		priceItems = [SELECT Id, Name FROM cspmb__Price_Item__c ORDER BY Id];
		Test.setCurrentPage(Page.PriceItemCloning);
		ApexPages.StandardController stdController = new ApexPages.StandardController(priceItems[3]);
		PriceItemCloning controller                = new PriceItemCloning(stdController);

		Test.startTest();
		PageReference result = controller.clonePriceItems();
		Test.stopTest();
		//validate results
		System.assertEquals(true, ApexPages.hasMessages(), 'Validation message expected.');
		System.assertEquals(true, ApexPages.getMessages()[0].getSummary().contains('Please use most recent one for cloning'), 'Unexpected validation message!');
		System.assertEquals(null, result, 'Validation error, no redirect expected.');
	}

	/**
	 * Tests that Price Item validation logic makes sure we allow
	 * only some of Price Items to be cloned.
	 * Test case: cloning from list view but not selecting any records causes validation error NO_SELECTION
	 */
	@isTest static void validationTestNoSelection() {
		priceItems = [SELECT Id, Name FROM cspmb__Price_Item__c ORDER BY Id];
		Test.setCurrentPage(Page.PriceItemCloning);
		ApexPages.StandardSetController stdController = new ApexPages.StandardSetController(priceItems);
		PriceItemCloning controller                   = new PriceItemCloning(stdController);

		Test.startTest();
		PageReference result = controller.clonePriceItems();
		Test.stopTest();
		//validate results
		System.assertEquals(true, ApexPages.hasMessages(), 'Validation message expected.');
		System.assertEquals(true, ApexPages.getMessages()[0].getSummary().contains('Please select at least one Price Item and try again'), 'Unexpected validation message!');
		System.assertEquals(null, result, 'Validation error, no redirect expected.');
	}

	/**
	 * Tests successful cloning process for record without external id.
	 */
	@isTest static void successfulCloningNoExternalId() {
		priceItems = [SELECT Id, Name FROM cspmb__Price_Item__c ORDER BY Id];
		Test.setCurrentPage(Page.PriceItemCloning);
		ApexPages.StandardController stdController = new ApexPages.StandardController(priceItems[4]);
		PriceItemCloning controller                = new PriceItemCloning(stdController);

		Test.startTest();
		PageReference result = controller.clonePriceItems();
		Test.stopTest();
		//we had 6 price items, 6 association records and 1 add on price item
		//expecting 7 price items, 7 association records and 1 add on price item
		Map<Id, cspmb__Price_Item__c> priceItemsAfterMap = new Map<Id, cspmb__Price_Item__c>([SELECT Id, Name, Old_Instance__c, New_Instance__c, ExternalID__c
																							  FROM cspmb__Price_Item__c ORDER BY Id]);
		List<cspmb__Add_On_Price_Item__c> addOnPriceItems                                         = [SELECT Id FROM cspmb__Add_On_Price_Item__c];
		List<cspmb__Price_Item_Add_On_Price_Item_Association__c> priceItemAddonPriceItemAssocList = [SELECT Id FROM cspmb__Price_Item_Add_On_Price_Item_Association__c];
		//validate results
		System.assertEquals(false, ApexPages.hasMessages(), 'Validation message is not expected.'+ ApexPages.getMessages());
		System.assertNotEquals(null, result, 'Successful cloning, redirect is expected.');
		System.assertEquals(priceItems.size() + 1, priceItemsAfterMap.keySet().size(), 'Expecting to have exactly one more price item.');
		System.assertEquals(priceItems.size() + 1, priceItemAddonPriceItemAssocList.size(), 'Expecting to have exactly one more association record.');
		System.assertEquals(1, addOnPriceItems.size(), 'Expecting to have same number of Add On Price Items.');
		//get old and new Price items for cleaner code
		cspmb__Price_Item__c originalPriceItem = priceItemsAfterMap.get(priceItems[4].Id);
		System.assertNotEquals(null, originalPriceItem.New_Instance__c, 'Expecting to have new instance populated on original price item.');
		cspmb__Price_Item__c clonedPriceItem = priceItemsAfterMap.get(originalPriceItem.New_Instance__c);
		System.assertNotEquals(null, clonedPriceItem.Old_Instance__c, 'Expecting to have old instance populated on cloned price item.');
		//old and new instance links should also be logically correct
		System.assertEquals(originalPriceItem.New_Instance__c, clonedPriceItem.Id, 'Original Price Item New Instance should point to cloned Price Item.');
		System.assertEquals(clonedPriceItem.Old_Instance__c, originalPriceItem.Id, 'Cloned Price Item Old Instance should point to original Price Item.');
		//we had no external id to start with so not expecting to have it on either one
		System.assertEquals(null, originalPriceItem.ExternalID__c, 'External Id should be empty');
		System.assertEquals(null, clonedPriceItem.ExternalID__c, 'External Id should be empty');
	}

	/**
	 * Tests successful cloning process for record with external id.
	 * Identical to successfulCloningNoExternalId but we now expect to have new external Id.
	 */
	@isTest static void successfulCloningWithExternalId() {
		priceItems = [SELECT Id, Name FROM cspmb__Price_Item__c ORDER BY Id];
		Test.setCurrentPage(Page.PriceItemCloning);
		ApexPages.StandardController stdController = new ApexPages.StandardController(priceItems[5]);
		PriceItemCloning controller                = new PriceItemCloning(stdController);

		Test.startTest();
		PageReference result = controller.clonePriceItems();
		Test.stopTest();
		//we had 6 price items, 6 association records and 1 add on price item
		//expecting 7 price items, 7 association records and 1 add on price item
		Map<Id, cspmb__Price_Item__c> priceItemsAfterMap = new Map<Id, cspmb__Price_Item__c>([SELECT Id, Name, Old_Instance__c, New_Instance__c, ExternalID__c
																							  FROM cspmb__Price_Item__c ORDER BY Id]);
		List<cspmb__Add_On_Price_Item__c> addOnPriceItems                                         = [SELECT Id FROM cspmb__Add_On_Price_Item__c];
		List<cspmb__Price_Item_Add_On_Price_Item_Association__c> priceItemAddonPriceItemAssocList = [SELECT Id FROM cspmb__Price_Item_Add_On_Price_Item_Association__c];
		//validate results
		System.assertEquals(false, ApexPages.hasMessages(), 'Validation message is not expected.');
		System.assertNotEquals(null, result, 'Successful cloning, redirect is expected.');
		System.assertEquals(priceItems.size() + 1, priceItemsAfterMap.keySet().size(), 'Expecting to have exactly one more price item.');
		System.assertEquals(priceItems.size() + 1, priceItemAddonPriceItemAssocList.size(), 'Expecting to have exactly one more association record.');
		System.assertEquals(1, addOnPriceItems.size(), 'Expecting to have same number of Add On Price Items.');
		//get old and new Price items for cleaner code
		cspmb__Price_Item__c originalPriceItem = priceItemsAfterMap.get(priceItems[5].Id);
		System.assertNotEquals(null, originalPriceItem.New_Instance__c, 'Expecting to have new instance populated on original price item.');
		cspmb__Price_Item__c clonedPriceItem = priceItemsAfterMap.get(originalPriceItem.New_Instance__c);
		System.assertNotEquals(null, clonedPriceItem.Old_Instance__c, 'Expecting to have old instance populated on cloned price item.');
		//old and new instance links should also be logically correct
		System.assertEquals(originalPriceItem.New_Instance__c, clonedPriceItem.Id, 'Original Price Item New Instance should point to cloned Price Item.');
		System.assertEquals(clonedPriceItem.Old_Instance__c, originalPriceItem.Id, 'Cloned Price Item Old Instance should point to original Price Item.');
		//we had external id so expecting to have it on both
		System.assertEquals('B-0001-001', originalPriceItem.ExternalID__c, 'External Id should be unchanged.');
		System.assertEquals('B-0001-002', clonedPriceItem.ExternalID__c, 'External Id not as expected.');
	}

	/**
	 * Tests optional constructor and some other methods to provide additional code coverage.
	 */
	@isTest static void optionalConstructorTest() {
		priceItems = [SELECT Id, Name, New_Instance__c, cspmb__Effective_Start_Date__c, cspmb__Effective_End_Date__c FROM cspmb__Price_Item__c ORDER BY Id];
		Test.setCurrentPage(Page.PriceItemCloning);
		PriceItemCloning controller = new PriceItemCloning(priceItems, 'newBundle');

		Test.startTest();
		PageReference forecastResult = controller.refreshForecastResult();
		cspmb__Price_Item__c forecastPriceItem = controller.forecastResult;
		PageReference result = controller.clonePriceItems();
		Test.stopTest();
		//validate results
		System.assertEquals(2, controller.operations.size(), 'We expect exactly 2 operations.');
		System.assertEquals(false, ApexPages.hasMessages(), 'Validation message not expected.');
		System.assertEquals(null, forecastResult, 'Should be null as it sets forecastPriceItem and refreshes the page');
		System.assertNotEquals(null, result, 'Successful, redirect expected.');
	}

	/**
	 * Creates data required for test cases.
	 * Creates Price Item, Add-on Price Item and association records
	 * Price item setup logic:
	 *  - Two Price items with Name ending with 10 overlap
	 *  - Price item with Name ending with 15 doesn't overlap but uses default End Date
	 *  - Price item with Name ending with 20 do not overlap but it has New Instance populated
	 *  - Price Item with Name ending with 25 is valid for cloning and has no external Id
	 *  - Price Item with Name ending with 30 is valid for cloning and has external id
	 */
	@testSetup public static void dataSetup() {
		//create price items
		priceItems = new List<cspmb__Price_Item__c>();
		//create few price items so we have some that overlap and some that don't
		priceItems.add(TestDataSetupClass.createPriceItem('Name','SME','NSW','Sales','Print','Plus','Pro','4',
														  DateTime.newInstanceGmt(2018,01,01).dateGMT(),DateTime.newInstanceGmt(2019,12,31).dateGMT(),true,false));
		priceItems.add(TestDataSetupClass.createPriceItem('Name','SME','NSW','Sales','Print','Plus','Pro','4',
														  DateTime.newInstanceGmt(2018,01,01).dateGMT(),DateTime.newInstanceGmt(2020,12,31).dateGMT(),true,false));
		priceItems.add(TestDataSetupClass.createPriceItem('Name','SME','NSW','Sales','Print','Plus','Pro','6',
														  DateTime.newInstanceGmt(2018,01,01).dateGMT(),DateTime.newInstanceGmt(2099,12,31).dateGMT(),true,false));
		priceItems.add(TestDataSetupClass.createPriceItem('Name','SME','NSW','Sales','Print','Plus','Pro','13',
														  DateTime.newInstanceGmt(2018,01,01).dateGMT(),DateTime.newInstanceGmt(2018,12,31).dateGMT(),true,false));
		priceItems.add(TestDataSetupClass.createPriceItem('Name','SME','NSW','Sales','Print','Plus','Pro','26',
														  DateTime.newInstanceGmt(2018,01,01).dateGMT(),DateTime.newInstanceGmt(2020,12,31).dateGMT(),true,false));
		priceItems.add(TestDataSetupClass.createPriceItem('Name','SME','NSW','Sales','Print','Plus','Pro','52',
														  DateTime.newInstanceGmt(2018,01,01).dateGMT(),DateTime.newInstanceGmt(2020,12,31).dateGMT(),true,false));
		//We need to turn off trigger as validation is not allowing date overlaps
		No_Triggers__c setting = new No_Triggers__c();
		setting.SetupOwnerId = UserInfo.getUserId();
		setting.Flag__c      = true;
		insert setting;
		insert priceItems;
		//link some of price items, doesn't have to be logically correct
		priceItems[3].New_Instance__c = priceItems[4].Id;
		priceItems[5].ExternalID__c   = 'B-0001-001';
		update priceItems;
		//reactivating trigger as that is normal state
		setting.Flag__c = false;
		update setting;

		//Add-on Price Item setup
		cspmb__Add_On_Price_Item__c addOnPriceItem = new cspmb__Add_On_Price_Item__c(Name = 'Add on price name', External_ID__c = 'A-0001');
		insert addOnPriceItem;

		//association junction setup, all price items are associated to a single AddOn Price Item for simplicity
		Integer i = 1;
		List<cspmb__Price_Item_Add_On_Price_Item_Association__c> priceItemAddonPriceItemAssocList = new List<cspmb__Price_Item_Add_On_Price_Item_Association__c>();
		for (cspmb__Price_Item__c priceItem :priceItems) {
			cspmb__Price_Item_Add_On_Price_Item_Association__c currAssoc = TestDataSetupClass.createPriceItemAddOnPriceItemAssociation(priceItem.Id, addOnPriceItem.Id, false);
			currAssoc.External_ID__c = 'AS-00' + i;
			priceItemAddonPriceItemAssocList.add(currAssoc);
			i++;
		}
		insert priceItemAddonPriceItemAssocList;
	}
}
@isTest(seeAllData = false)
private class ObjectFieldUpdateMappingHandlerTest {
	//helper variables
	private static cscfga__Product_Basket__c productBasket;
	private static List<cscfga__Product_Configuration__c> sourceRecords;
	private static Object_Field_Update_Mapping__mdt mappingConfig;
	private static Date minDate = Date.today();
	private static Date maxDate = Date.today().addDays(20);

	/**
	 * Test scenario:
	 * Handler loops over all 3 product configurations and since CALCULATE does not
	 * support filtering the value that we will have on product basket is the one
	 * that is calculated by using last inserted product configuration (prodConfig3).
	 */
	@isTest static void test_CALCULATE() {
		//prepare mapping configuration, load source
		setupMappingConfig('CALCULATE');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		//'Impressions_Quantity__c * 10 + 1000 / 10'
		//no operator precedence so calculates as: (300*10 + 1000) / 10 = 400
		System.assertEquals(400, productBasket.Total_Impressions_Quantity__c, 'Execution result not as expected!');
	}

	/**
	 * Test scenario:
	 * Handler loops over all 3 product configurations and since COPY does not
	 * support filtering the value that we will have on product basket is the one
	 * that is calculated by using last inserted product configuration (prodConfig3).
	 */
	@isTest static void test_COPY() {
		//prepare mapping configuration, load source
		setupMappingConfig('COPY');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		System.assertEquals(300, productBasket.Total_Impressions_Quantity__c, 'Execution result not as expected!');
	}

	/**
	 * Test scenario:
	 * Handler loops over all 3 product configurations and since COUNT does
	 * support filtering the value should be 2 as we filtered out 1 out of 3 configurations.
	 */
	@isTest static void test_COUNT() {
		//prepare mapping configuration, load source
		setupMappingConfig('COUNT');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		System.assertEquals(2, productBasket.Invalid_Config_Count__c, 'Execution result not as expected!');
	}

	/**
	 * Test scenario:
	 * Handler loops over all 3 product configurations and since CONCATENATE does
	 * support filtering the value should be concatenated values from prodConfig1 and prodConfig3.
	 */
	@isTest static void test_CONCATENATE() {
		//prepare mapping configuration, load source
		setupMappingConfig('CONCATENATE');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		System.assertEquals('Value 1 | Value 3', productBasket.Bundle_Name__c, 'Execution result not as expected!');
	}

	/**
	 * Test scenario:
	 * Handler loops over all 3 product configurations and returns
	 * result of Boolean AND for values of Bundle_Item__c field (true && false && true)
	 */
	@isTest static void test_AND() {
		//prepare mapping configuration, load source
		setupMappingConfig('AND');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		//value is stored in text field so expecting string
		System.assertEquals('false', productBasket.Bundle_Name__c, 'Execution result not as expected!');
	}

	/**
	 * Test scenario:
	 * Handler loops over all 3 product configurations and returns
	 * result of Boolean OR for values of Bundle_Item__c field (true || false || true)
	 */
	@isTest static void test_OR() {
		//prepare mapping configuration, load source
		setupMappingConfig('OR');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		//value is stored in text field so expecting string
		System.assertEquals('true', productBasket.Bundle_Name__c, 'Execution result not as expected!');
	}

	/**
	 * Test scenario:
	 * Handler loops over all 3 product configurations and returns
	 * MIN value for field Impressions_Quantity__c (decimal).
	 */
	@isTest static void test_MIN_Dec() {
		//prepare mapping configuration, load source
		setupMappingConfig('MIN_DEC');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		//value is stored in text field so expecting string
		System.assertEquals(100, productBasket.Total_Impressions_Quantity__c, 'Execution result not as expected!');
	}

	/**
	 * Test scenario:
	 * Handler loops over all 3 product configurations and returns
	 * MAX value for field Impressions_Quantity__c (decimal).
	 */
	@isTest static void test_MAX_Dec() {
		//prepare mapping configuration, load source
		setupMappingConfig('MAX_DEC');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		//value is stored in text field so expecting string
		System.assertEquals(300, productBasket.Total_Impressions_Quantity__c, 'Execution result not as expected!');
	}

	/**
	 * Test scenario:
	 * Similar to test_MIN_Dec but returning MIN value for Date field to test behavior
	 * for non-numeric fields. 
	 */
	@isTest static void test_MIN_Date() {
		//prepare mapping configuration, load source
		setupMappingConfig('MIN_DATE');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		//value is stored in text field so expecting string
		System.assertEquals(minDate, productBasket.XE_Campaign_Start_Date__c, 'Execution result not as expected!');
	}

	/**
	 * Test scenario:
	 * Similar to MIN but returning MAX value for Date field to test behavior
	 * for non-numeric fields. 
	 */
	@isTest static void test_MAX_Date() {
		//prepare mapping configuration, load source
		setupMappingConfig('MAX_DATE');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		//value is stored in text field so expecting string
		System.assertEquals(maxDate, productBasket.XE_Campaign_Start_Date__c, 'Execution result not as expected!');
	}

	/**
	 * Test scenario:
	 * Handler loops over all 3 product configurations and returns SUM for
	 * Impressions_Quantity__c which is 100 + 200 + 300 = 600
	 */
	@isTest static void test_SUM() {
		//prepare mapping configuration, load source
		setupMappingConfig('SUM');
		loadSourceRecords();
		//start testing
		Test.startTest();
		//create handler and set mapping and source objects for context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler(sourceRecords);
		handler.objFieldMappings = new List<Object_Field_Update_Mapping__mdt> {mappingConfig};
		handler.isValidationRun  = true; //gives extra coverage
		handler.execute();
		//execute
		Test.stopTest();
		//reload basket and validate output values
		reloadProductBasket();
		productBasket = (cscfga__Product_Basket__c)handler.objectsToUpdateMap.get(productBasket.Id);
		//value is stored in text field so expecting string
		System.assertEquals(600, productBasket.Total_Impressions_Quantity__c, 'Execution result not as expected!');
	}

	/**
	 * Providing extra coverage by running all available functionality.
	 */
	@isTest static void test_ValidationRun() {
		//prepare mapping configuration, load source
		setupMappingConfig('SUM');
		//start testing
		Test.startTest();
		//create handler without context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler();
		handler.validateMapping();
		//execute
		Test.stopTest();
		//nothing to reload no assert as only debug statements would be provided
	}

	/**
	 * Providing extra coverage by running all available functionality.
	 * Execution shouldn't make any changes as there was no execution context set and
	 * logic wasn't started from a trigger so auto-context logic wouldn't kick in.
	 */
	@isTest static void test_EmptyRun() {
		//start testing
		Test.startTest();
		//create handler without context
		ObjectFieldUpdateMappingHandler handler = new ObjectFieldUpdateMappingHandler();
		handler.execute();
		//execute
		Test.stopTest();
		//nothing should be executed so check that there are no modified objects
		System.assertEquals(true, handler.objectsToUpdateMap.isEmpty(), 'There should be no records to modify!');
	}

	/**
	 * Reloads product basket so we can investigate processing results.
	 */
	private static void reloadProductBasket() {
		productBasket = [SELECT Id, Total_Impressions_Quantity__c, Invalid_Config_Count__c,
						 Bundle_Name__c, XE_Campaign_Start_Date__c
						 FROM cscfga__Product_Basket__c LIMIT 1];
	}

	/**
	 * Helper method to load all source records that we created in setupData.
	 */
	private static void loadSourceRecords() {
		sourceRecords = [SELECT Id, cscfga__Product_Basket__c FROM cscfga__Product_Configuration__c LIMIT 10];
	}

	private static void setupMappingConfig(String actionType) {
		mappingConfig = new Object_Field_Update_Mapping__mdt(
			DeveloperName = 'ConfigToBasket001',
			Active__c = true,
			Source_Object_API_Name__c = 'cscfga__Product_Configuration__c',
			Relationship_field_API_Name__c = 'cscfga__Product_Basket__c',
			Destination_Object_API_Name__c = 'cscfga__Product_Basket__c');
		//action specific logic
		if (actionType == 'CALCULATE') {
			mappingConfig.Action_Type__c                = 'CALCULATE';
			//no operator precedence so calculates as: (300*10 + 1000) / 10 = 400
			mappingConfig.Source_Field_API_Name__c      = 'Impressions_Quantity__c * 10 + 1000 / 10 - 0';
			mappingConfig.Destination_Field_API_Name__c = 'Total_Impressions_Quantity__c';
		} else if (actionType == 'COPY') {
			mappingConfig.Action_Type__c                = 'COPY';
			mappingConfig.Source_Field_API_Name__c      = 'Impressions_Quantity__c';
			mappingConfig.Destination_Field_API_Name__c = 'Total_Impressions_Quantity__c';
			//only taking into account prodConfig2 as we would like to have predictable results
			mappingConfig.Filter__c = 'Bundle_Name__c = Value 3';
		}  else if (actionType == 'COUNT') {
			mappingConfig.Action_Type__c                = 'COUNT';
			mappingConfig.Source_Field_API_Name__c      = 'Id';
			mappingConfig.Destination_Field_API_Name__c = 'Invalid_Config_Count__c';
			mappingConfig.Filter__c = 'Bundle_Name__c <= Value 1 || Bundle_Name__c >= Value 3 && Bundle_Name__c != /';
		} else if (actionType == 'CONCATENATE') {
			mappingConfig.Action_Type__c                = 'CONCATENATE';
			mappingConfig.Source_Field_API_Name__c      = 'Bundle_Name__c';
			mappingConfig.Destination_Field_API_Name__c = 'Bundle_Name__c';
			mappingConfig.Separator__c = 'space|space';
			//playing with filter string to cover all comparison operators
			mappingConfig.Filter__c = 'Bundle_Name__c != / && Bundle_Name__c > aaa && Bundle_Name__c < zzz';
		} else if (actionType == 'AND') {
			mappingConfig.Action_Type__c                = 'AND';
			mappingConfig.Source_Field_API_Name__c      = 'Bundle_Item__c';
			mappingConfig.Destination_Field_API_Name__c = 'Bundle_Name__c';
		} else if (actionType == 'OR') {
			mappingConfig.Action_Type__c                = 'OR';
			mappingConfig.Source_Field_API_Name__c      = 'Bundle_Item__c';
			mappingConfig.Destination_Field_API_Name__c = 'Bundle_Name__c';
		} else if (actionType == 'MIN_DATE') {
			mappingConfig.Action_Type__c                = 'MIN';
			mappingConfig.Source_Field_API_Name__c      = 'cscfga__Entry_Date__c';
			mappingConfig.Destination_Field_API_Name__c = 'XE_Campaign_Start_Date__c';
		} else if (actionType == 'MAX_DATE') {
			mappingConfig.Action_Type__c                = 'MAX';
			mappingConfig.Source_Field_API_Name__c      = 'cscfga__Entry_Date__c';
			mappingConfig.Destination_Field_API_Name__c = 'XE_Campaign_Start_Date__c';
		} else if (actionType == 'MIN_DEC') {
			mappingConfig.Action_Type__c                = 'MIN';
			mappingConfig.Source_Field_API_Name__c      = 'Impressions_Quantity__c';
			mappingConfig.Destination_Field_API_Name__c = 'Total_Impressions_Quantity__c';
		} else if (actionType == 'MAX_DEC') {
			mappingConfig.Action_Type__c                = 'MAX';
			mappingConfig.Source_Field_API_Name__c      = 'Impressions_Quantity__c';
			mappingConfig.Destination_Field_API_Name__c = 'Total_Impressions_Quantity__c';
		} else if (actionType == 'SUM') {
			mappingConfig.Action_Type__c                = 'SUM';
			mappingConfig.Source_Field_API_Name__c      = 'Impressions_Quantity__c';
			mappingConfig.Destination_Field_API_Name__c = 'Total_Impressions_Quantity__c';
		}
	}
	/**
	 * Create all needed records for test.
	 * Plan is to test all mapping actions by rolling up configuration data
	 * to basket and sales order.
	 */
	@testSetup static void setupData() {
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
		soApi.csmso__No_Triggers__c = true; // we don't need them, speeds up test and isolates our logic
		insert soApi;

		Account acc = TestDataSetupClass.createAccount();
		insert acc;

		Contact con = TestDataSetupClass.createContact(acc);
		insert con;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		insert opp;

		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		//preapprove to avoid validation rule
		so.csmso__Process_Message_Type__c = 'preapproved';
		so.csmso__Status__c               = 'Draft';
		so.csmso__Booking_Contact__c      = con.Id;
		insert so;

		cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
		insert prodBasket;

		cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
		insert testProdCateg;

		cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
		insert testProDef;

		//fields and values used here are not meant to make business sense
		cscfga__Product_Configuration__c prodConfig1 = TestDataSetupClass.createProdConfig(prodBasket);
		prodConfig1.cscfga__Configuration_Status__c = 'Valid';
		prodConfig1.cscfga__Product_Definition__c   = testProDef.id;
		prodConfig1.Impressions_Quantity__c         = 100;
		prodConfig1.Bundle_Name__c                  = 'Value 1'; // Bundle_Item__c will be true
		prodConfig1.cscfga__Entry_Date__c           = minDate;

		cscfga__Product_Configuration__c prodConfig2 = TestDataSetupClass.createProdConfig(prodBasket);
		prodConfig2.cscfga__Configuration_Status__c = 'Valid';
		prodConfig2.cscfga__Product_Definition__c   = testProDef.id;
		prodConfig2.Bundle_Name__c                  = '/';  // Bundle_Item__c will be false
		prodConfig2.Impressions_Quantity__c         = 200;
		prodConfig2.cscfga__Entry_Date__c           = Date.today().addDays(10);

		cscfga__Product_Configuration__c prodConfig3 = TestDataSetupClass.createProdConfig(prodBasket);
		prodConfig3.cscfga__Configuration_Status__c = 'Valid';
		prodConfig3.cscfga__Product_Definition__c   = testProDef.id;
		prodConfig3.Bundle_Name__c                  = 'Value 3'; // Bundle_Item__c will be true
		prodConfig3.Impressions_Quantity__c         = 300;
		prodConfig3.cscfga__Entry_Date__c           = maxDate;

		insert new List<cscfga__Product_Configuration__c> {prodConfig1, prodConfig2, prodConfig3};

		/*
		   cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);
		   insert testAttrDef;

		   cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef);
		   testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;
		   testAttr1.cscfga__Value__c = '1000';
		   testAttr1.Name             = 'Product Groups For IO';
		   insert testAttr1;
		 */
	}

}
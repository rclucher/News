@isTest
private class ProductNodeCloningTest {
	//helper global variables
	private static List<csmso__Product_Node__c> productNodes;
	private static List<csmso__Product_Node__c> productNodesAfter;

	@isTest static void validationTestNewInstance() {
		productNodes = [SELECT Id, Name, Is_Active__c, New_Instance__c, ExternalID__c, Effective_Start_Date__c, Effective_End_Date__c, RecordTypeId
						FROM csmso__Product_Node__c ORDER BY Name];
		//prepare publication for test case, no need for DML as testing only validations
		productNodes[0].New_Instance__c = productNodes[1].Id;
		//
		Test.setCurrentPage(Page.ProductNodeManager);
		ApexPages.StandardController stdController = new ApexPages.StandardController(productNodes[0]);
		ProductNodeCloning controller              = new ProductNodeCloning(stdController);

		Test.startTest();
		PageReference result = controller.startOperation();
		Test.stopTest();
		//validate results
		System.assertEquals(true, ApexPages.hasMessages(), 'Validation message expected.');
		System.assertEquals(true, ApexPages.getMessages()[0].getSummary().contains('Please use most recent one for cloning'), 'Unexpected validation message!');
		System.assertEquals(null, result, 'Validation error, no redirect expected.');
	}

	/**
	 * Tests Create New Version operation.
	 * Product Node used can't have New Instance value nor End Date should be default one.
	 */
	@isTest static void createNewVersionTest() {
		productNodes = [SELECT Id, Name, Is_Active__c, New_Instance__c, ExternalID__c, Effective_Start_Date__c, Effective_End_Date__c, RecordTypeId
						FROM csmso__Product_Node__c ORDER BY Name];
		//prepare publication for test case, no need for DML as testing only validations
		productNodes[0].Effective_End_Date__c = productNodes[0].Effective_Start_Date__c + 1;
		update productNodes[0];
		//set context
		Test.setCurrentPage(Page.ProductNodeManager);
		ApexPages.StandardController stdController = new ApexPages.StandardController(productNodes[0]);
		ProductNodeCloning controller              = new ProductNodeCloning(stdController);

		Test.startTest();
		PageReference result = controller.startOperation();
		Test.stopTest();
		//validate results
		productNodesAfter = [SELECT Id, Name, Is_Active__c, New_Instance__c, ExternalID__c, Effective_Start_Date__c,
							 Effective_End_Date__c, RecordTypeId
							 FROM csmso__Product_Node__c
							 WHERE Old_Instance__c  = :productNodes[0].Id ORDER BY Name];
		System.assertEquals(false, ApexPages.hasMessages(), 'Validation message not expected.');
		System.assertNotEquals(null, result, 'Execution should be successful, redirect expected.');
		System.assertEquals(productNodesAfter.size(), 1, 'There should be only one new version created');
		System.assertEquals(productNodesAfter[0].Effective_Start_Date__c, productNodes[0].Effective_End_Date__c + 1, 'New start date should be old end date + 1 day');
	}

	/**
	 * Similar to createNewVersionTest but selected Product Node could have end date set to default one.
	 * New Product Node should be deactivated and would still use same Name.
	 */
	@isTest static void createNewTest() {
		productNodes = [SELECT Id, Name, Is_Active__c, Old_Instance__c, New_Instance__c, ExternalID__c, Effective_Start_Date__c,
						Effective_End_Date__c, RecordTypeId
						FROM csmso__Product_Node__c ORDER BY Name];
		//set context
		Test.setCurrentPage(Page.ProductNodeManager);
		ApexPages.StandardController stdController = new ApexPages.StandardController(productNodes[0]);
		ProductNodeCloning controller              = new ProductNodeCloning(stdController);

		Test.startTest();
		controller.selectedOperation = 'newBespoke';
		String operationDesc = controller.operationDescription;//extra code coverage
		PageReference result = controller.startOperation();
		Test.stopTest();
		//validate results
		productNodesAfter = [SELECT Id, Name, Is_Active__c, Old_Instance__c, New_Instance__c, ExternalID__c, Effective_Start_Date__c,
							 Effective_End_Date__c, RecordTypeId
							 FROM csmso__Product_Node__c
							 WHERE Name  = :productNodes[0].Name and Is_Active__c = false];
		System.assertEquals(false, ApexPages.hasMessages(), 'Validation message not expected.');
		System.assertNotEquals(null, result, 'Execution should be successful, redirect expected.');
		System.assertEquals(productNodesAfter.size(), 1, 'There should be only one new product node created');
		System.assertEquals(productNodesAfter[0].Effective_Start_Date__c, ProductNodeCloning.NOW_DATE, 'New start date should be today');
		System.assertEquals(null, productNodesAfter[0].New_Instance__c, 'There should be no New Instance value.');
		System.assertEquals(null, productNodesAfter[0].Old_Instance__c, 'There should be no New Instance value.');
	}

	/**
	 * Test propagate changes operation.
	 * For simplicity testing changes to all fields apart from Calendar.
	 */
	@isTest static void propagateChangesTest() {
		productNodes = [SELECT Id, Name, Is_Active__c, Old_Instance__c, New_Instance__c, ExternalID__c, Effective_Start_Date__c,
						Effective_End_Date__c, RecordTypeId, csmso__Calendar__c
						FROM csmso__Product_Node__c ORDER BY Name];
		//set context
		csmso__Product_Node__c prodNode = productNodes[0].clone(true, true);
		prodNode.Is_Active__c            = false;
		prodNode.Name                    = productNodes[0].Name + ' updated';
		prodNode.Effective_Start_Date__c = prodNode.Effective_Start_Date__c + 10;
		prodNode.Effective_End_Date__c   = prodNode.Effective_Start_Date__c + 20;
		Test.setCurrentPage(Page.ProductNodeManager);
		ApexPages.StandardController stdController = new ApexPages.StandardController(productNodes[0]);
		ProductNodeCloning controller              = new ProductNodeCloning(stdController);
		//make changes we would like to propagate on new instance so that queried records is unchanged for asserts

		Test.startTest();
		controller.selectedOperation = 'propagateChanges';
		String operationDesc = controller.operationDescription;//extra code coverage
		controller.forecastResult = prodNode;   // updating variable used for checking the changes
		PageReference result = controller.startOperation();
		Test.stopTest();
		//validate results
		productNodesAfter = [SELECT Id, Name, Is_Active__c, Old_Instance__c, New_Instance__c, ExternalID__c, Effective_Start_Date__c,
							 Effective_End_Date__c, RecordTypeId
							 FROM csmso__Product_Node__c ORDER BY Name];
		System.assertEquals(false, ApexPages.hasMessages(), 'Validation message not expected.');
		System.assertNotEquals(null, result, 'Execution should be successful, redirect expected.');
		System.assertEquals( productNodes.size(), productNodesAfter.size(), 'Nothing new should be created as we only updated records.');
		System.assertNotEquals(productNodes[0].Is_Active__c, productNodesAfter[0].Is_Active__c, 'Should be updated');
		System.assertNotEquals(productNodes[0].Name, productNodesAfter[0].Name, 'Should be updated');
		System.assertNotEquals(productNodes[0].Effective_Start_Date__c, productNodesAfter[0].Effective_Start_Date__c, 'Should be updated');
		System.assertNotEquals(productNodes[0].Effective_End_Date__c, productNodesAfter[0].Effective_End_Date__c, 'Should be updated');
	}

	/**
	 * Nice to have getters test to provide additional code coverage
	 */
	@isTest static void testGetters() {
		productNodes = [SELECT Id, Name, Is_Active__c, New_Instance__c, ExternalID__c, Effective_Start_Date__c, Effective_End_Date__c, RecordTypeId
						FROM csmso__Product_Node__c ORDER BY Name];
		//prepare publication for test case, no need for DML as testing only validations
		productNodes[0].Effective_End_Date__c = productNodes[0].Effective_Start_Date__c + 1;
		update productNodes[0];
		//set context, using 2nd constructor to get more code coverage
		ProductNodeCloning controller = new ProductNodeCloning(productNodes[0]);

		Test.startTest();
		//just calling getters
		List<SelectOption> operations = controller.operations;
		String operationDesc = controller.operationDescription;
		PageReference result = controller.refreshForecastResult();
		List<ProductNodeCloning.SummaryWrapper> summWrap = controller.summaryDetails;
		Test.stopTest();
	}
	/**
	 * Prepare data needed for our test cases.
	 */
	@testSetup static void dataSetup() {
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
		insert soApi;
		Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.csmso__Product_Node__c.getRecordTypeInfosByName();
		csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
		insert bu;
		//create publication hierarchy
		csmso__Product_Node__c pubPN = TestDataSetupClass.createProductNode('1 Publication', bu);
		pubPN.RecordTypeId            = rtMapByName.get('Print Publication').getRecordTypeId();
		pubPN.ExternalID__c           = 'Pub-001-001';
		pubPN.Is_Active__c            = true;
		pubPN.Effective_Start_Date__c = ProductNodeCloning.NOW_DATE;
		pubPN.Effective_End_Date__c   = ProductNodeCloning.DEFAULT_END_DATE;
		insert pubPN;
		//section
		csmso__Product_Node__c sectionPN = TestDataSetupClass.createProductNode('2 Section', bu);
		sectionPN.RecordTypeId                  = rtMapByName.get('Print Section').getRecordTypeId();
		sectionPN.csmso__Parent_Product_Node__c = pubPN.Id;
		sectionPN.ExternalID__c                 = 'Sec-001-001';
		sectionPN.Is_Active__c                  = true;
		sectionPN.Effective_Start_Date__c       = ProductNodeCloning.NOW_DATE;
		sectionPN.Effective_End_Date__c         = ProductNodeCloning.DEFAULT_END_DATE;
		insert sectionPN;
		//subsection
		csmso__Product_Node__c subSectionPN = TestDataSetupClass.createProductNode('3 Subsection', bu);
		subSectionPN.RecordTypeId                  = rtMapByName.get('Print Subsection').getRecordTypeId();
		subSectionPN.csmso__Parent_Product_Node__c = sectionPN.Id;
		subSectionPN.ExternalID__c                 = 'Subsec-001-001';
		subSectionPN.Is_Active__c                  = true;
		subSectionPN.Effective_Start_Date__c       = ProductNodeCloning.NOW_DATE;
		subSectionPN.Effective_End_Date__c         = ProductNodeCloning.DEFAULT_END_DATE;
		insert subSectionPN;
		//position
		csmso__Product_Node__c positionPN = TestDataSetupClass.createProductNode('4 Position', bu);
		positionPN.RecordTypeId                  = rtMapByName.get('Print Position').getRecordTypeId();
		positionPN.csmso__Parent_Product_Node__c = subSectionPN.Id;
		positionPN.ExternalID__c                 = 'Pos-001-001';
		positionPN.Is_Active__c                  = true;
		positionPN.Effective_Start_Date__c       = ProductNodeCloning.NOW_DATE;
		positionPN.Effective_End_Date__c         = ProductNodeCloning.DEFAULT_END_DATE;
		insert positionPN;

		//related records
		csmso__Node_Advert_Assignment__c naa = TestDataSetupClass.createNodeAdvAssignment('NAA for publication', pubPN);
		naa.Is_Active__c            = true;
		naa.Effective_Start_Date__c = ProductNodeCloning.NOW_DATE;
		naa.Effective_End_Date__c   = ProductNodeCloning.DEFAULT_END_DATE;
		insert naa;
		//Line Item Threshold records
		Line_Item_Threshold__c lit1 = new Line_Item_Threshold__c();
		lit1.Approval_Level__c         = '1';
		lit1.Product_Node__c           = pubPN.Id;
		lit1.Node_Advert_Assignment__c = naa.Id;
		insert lit1;
		// insert test rate cards
		csmso__Rate_Card__c rc1 = new csmso__Rate_Card__c();
		rc1.csmso__Product_Node__c = pubPN.Id;
		rc1.csmso__From_Date__c    = ProductNodeCloning.NOW_DATE;
		rc1.csmso__To_Date__c      = ProductNodeCloning.DEFAULT_END_DATE;

		csmso__Rate_Card__c rc2 = new csmso__Rate_Card__c();
		rc2.csmso__Product_Node__c = pubPN.Id;
		rc2.csmso__From_Date__c    = ProductNodeCloning.NOW_DATE;
		rc2.csmso__To_Date__c      = ProductNodeCloning.DEFAULT_END_DATE;
		insert new List<csmso__Rate_Card__c>{rc1, rc2};

		// insert test rate card item prices
		csmso__Rate_Card_Item_Price__c rcip1 = new csmso__Rate_Card_Item_Price__c();
		rcip1.csmso__Product_Node__c      = pubPN.Id;
		rcip1.csmso__Rate_Card__c         = rc1.Id;
		rcip1.csmso__Advert_Assignment__c = naa.Id;

		csmso__Rate_Card_Item_Price__c rcip2 = new csmso__Rate_Card_Item_Price__c();
		rcip2.csmso__Product_Node__c      = pubPN.Id;
		rcip2.csmso__Rate_Card__c         = rc2.Id;
		rcip2.csmso__Advert_Assignment__c = naa.Id;
		insert new List<csmso__Rate_Card_Item_Price__c>{rcip1, rcip2};
	}
}
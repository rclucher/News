@isTest
private class RecallSalesOrderTest {
	/**
	 * Test Xtend branch of logic (i.e. nothing to do part)
	 */
	@isTest static void recallXtend() {
		//get SO we created
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.Platform_Set__c = '{Xtend}';
		update so;

		Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
		request.setComments('Testing Xtend');
		request.setObjectId(so.Id);

		request.setProcessDefinitionNameOrId('Margin_Approval');
		request.setSkipEntryCriteria(true);

		Approval.ProcessResult result = Approval.process(request);

		RecallSalesOrder rso = new RecallSalesOrder();
		
		Test.startTest();
		rso.performAction((String) so.Id);
		Test.stopTest();
	}

	@isTest static void recallXtendException() {
		//get SO we created
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.Platform_Set__c = '{Xtend}';
		update so;


		RecallSalesOrder rso = new RecallSalesOrder();

		Test.startTest();
		rso.performAction((String) so.Id);
		Test.stopTest();
	}

	/**
	 * Test non Xtend branch of logic i.e. calling Ativa logic.
	 */
	@isTest static void recallOthers() {
		//get SO we created
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.Platform_Set__c = '{Print}';
		update so;

		Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
		request.setComments('Testing non Xtend');
		request.setObjectId(so.Id);

		request.setProcessDefinitionNameOrId('Margin_Approval');
		request.setSkipEntryCriteria(true);

		Approval.ProcessResult result = Approval.process(request);


		RecallSalesOrder rso = new RecallSalesOrder();
		
		Test.startTest();
		rso.performAction((String) so.Id);
		Test.stopTest();
	}


	@isTest static void recallOthersException() {

		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.Platform_Set__c = '{Print}';
		update so;

		//not starting approval process so it should throw exception
		RecallSalesOrder rso = new RecallSalesOrder();

		Test.startTest();
		rso.performAction((String) so.Id);
		Test.stopTest();
	}

	/**
	 * Creates all needed data for our test cases.
	 * Creates: Account, Contact, Opportunity, Sales Order, Customer Approval, ClickApprove custom settings
	 */
	@testSetup
	static void setupData() {
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
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

		cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
		prodConfig.cscfga__Configuration_Status__c = 'Valid';
		prodConfig.cscfga__Product_Definition__c   = testProDef.id;
		insert prodConfig;

		cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);
		insert testAttrDef;

		cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig, so, testAttrDef);
		testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;
		//testAttr.Configuration_Output_Mapping__c = Opportunity.Name;
		testAttr1.cscfga__Value__c = '1000';
		testAttr1.Name             = 'Product Groups For IO';
		insert testAttr1;
	}
}
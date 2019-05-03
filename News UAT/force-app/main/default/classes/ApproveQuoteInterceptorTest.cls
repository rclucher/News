@isTest(seeAllData = false)
private class ApproveQuoteInterceptorTest {
	private static final String TOKEN = 'ThisIsMyKey';

	/**
	 * Covers case when email approval comes for Opportunity that has no previously approved Sales Orders
	 */
	@isTest static void noPriorApproval() {
		// create a new email and envelope object
		Messaging.InboundEmail email  = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

		// setup the data for the email
		email.subject       = 'Something:' + TOKEN;
		email.fromAddress   = 'someaddress@email.com';
		email.plainTextBody = 'Inbound email plain text body';
		email.htmlBody      = 'Inbound email plain text body';

		// add an Binary attachment
		Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
		attachment.body            = Blob.valueOf('my attachment text');
		attachment.fileName        = 'textfileone.txt';
		attachment.mimeTypeSubType = 'text/plain';
		email.binaryAttachments    = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

		Test.startTest();
		ApproveQuoteInterceptor aqi = new ApproveQuoteInterceptor();
		aqi.handleInboundEmail(email, env);
		Test.stopTest();
	}

	/**
	 * Covers case when email approval comes for Opportunity that has no previously approved Sales Orders
	 * but customer approval record was already flagged as approved.
	 */
	@isTest static void approvalForAlreadyApproved() {
		//flag approval record as already approved
		CSCAP__Customer_Approval__c customerApproval = [SELECT Id FROM CSCAP__Customer_Approval__c LIMIT 1];
		customerApproval.CSCAP__Approved_By_Customer__c = true;
		update customerApproval;

		// create a new email and envelope object
		Messaging.InboundEmail email  = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

		// setup the data for the email
		email.subject       = 'Something:' + TOKEN;
		email.fromAddress   = 'someaddress@email.com';
		email.plainTextBody = 'Inbound email plain text body';
		email.htmlBody      = 'Inbound email plain text body';

		// add an Binary attachment
		Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
		attachment.body            = Blob.valueOf('my attachment text');
		attachment.fileName        = 'textfileone.txt';
		attachment.mimeTypeSubType = 'text/plain';
		email.binaryAttachments    = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

		Test.startTest();
		ApproveQuoteInterceptor aqi = new ApproveQuoteInterceptor();
		aqi.handleInboundEmail(email, env);
		Test.stopTest();
	}

	/**
	 * Covers case when email approval comes for Opportunity that has previously approved Sales Orders
	 */
	@isTest static void approvalForOppThatHasApprovedSO() {
		//update SO so that it is approved
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.csmso__Status__c = 'Manually Approved';
		update so;

		// create a new email and envelope object
		Messaging.InboundEmail email  = new Messaging.InboundEmail();
		Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

		// setup the data for the email
		email.subject       = 'Something:' + TOKEN;
		email.fromAddress   = 'someaddress@email.com';
		email.plainTextBody = 'Inbound email plain text body';
		email.htmlBody      = 'Inbound email plain text body';

		// add an Binary attachment
		Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
		attachment.body            = Blob.valueOf('my attachment text');
		attachment.fileName        = 'textfileone.txt';
		attachment.mimeTypeSubType = 'text/plain';
		email.binaryAttachments    = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

		Test.startTest();
		ApproveQuoteInterceptor aqi = new ApproveQuoteInterceptor();
		aqi.handleInboundEmail(email, env);
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

		csmso__Upload_Approval__c testUploadApproval = TestDataSetupClass.createUploadApproval(so);
		testUploadApproval.Name = 'InsertionOrder_2018-07-1614:11:30.pdf';
		insert testUploadApproval;

		CSCAP__Click_Approve_Setting__c testClkAppSet = TestDataSetupClass.createClkAppSet();
		testClkAppSet.Name                                = 'IO Email Approval Setting – News Value Bundles';
		testClkAppSet.CSCAP__Status__c                    = 'Active';
		testClkAppSet.Acknowl_Template_Approval_Exists__c = 'AckTemplateApprovalExists';
		insert testClkAppSet;

		CSCAP__Customer_Approval__c custApproval = new CSCAP__Customer_Approval__c();
		custApproval.Upload_Approval__c              = testUploadApproval.Id;
		custApproval.CSCAP__Opportunity__c           = opp.Id;
		custApproval.CSCAP__Click_Approve_Setting__c = testClkAppSet.Id;
		custApproval.CSCAP__Key__c                   = TOKEN;
		insert custApproval;
	}
}
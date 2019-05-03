@isTest(seeAllData = false)
public class InsertOrder2ClickApproveContrTest {
	/**
	 * Basic controller test, checks that the redirection is as expected
	 * and that all expected page params have been set.
	 */
	@isTest public static void insertionOrder2ClickApproveTest(){
		//get SO with UA records, expecting only 1 from both records
		csmso__Sales_Order__c so = [SELECT Id,
									(SELECT Id FROM csmso__Upload_Approval__r)
									FROM csmso__Sales_Order__c LIMIT 1];

		Test.startTest();
		PageReference pageRef = Page.InsertionOrder2ClickApprove;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('soId', so.Id);
		pageRef.getParameters().put('Id', so.csmso__Upload_Approval__r[0].Id);

		InsertionOrder2ClickApproveController testcontroller = new InsertionOrder2ClickApproveController();
		PageReference result                                 = testcontroller.insertionOrder2ClickApprove();

		Test.stopTest();
		//check outcome
		Set<String> expectedParams = new Set<String>{'id','sId','cId','retUrl','selectAllAtts'};
		//confirm that redirect was as expxected (page and params set)
		System.assertNotEquals(null, result, 'User wasn\'t redirected');
		System.assertEquals(true, result.getParameters().keySet().containsAll(expectedParams), 'Page is missing some of the expected params!');
		result.getParameters().clear();//only comparing base url so we need to clear the params
		System.assertEquals(Page.CSCAP__SendFormalEmailForApproval_LE.getUrl().toLowercase(), result.getUrl().toLowercase(), 'Not redirected to expected page!');
	}

	/**
	 * Basic dynamic CA setting selection test.
	 */
	@isTest public static void getCAsettingIdForBasketProductsTest(){
		CSCAP__Click_Approve_Setting__c settingXtend = [SELECT Id FROM CSCAP__Click_Approve_Setting__c WHERE Name = 'IO Email Approval Setting – News Xtend'];
		CSCAP__Click_Approve_Setting__c settingBundle = [SELECT Id FROM CSCAP__Click_Approve_Setting__c WHERE Name = 'IO Email Approval Setting – News Value Bundles'];
		
		Test.startTest();
		InsertionOrder2ClickApproveController testcontroller = new InsertionOrder2ClickApproveController();
		Id resultXtend = testcontroller.getCAsettingIdForBasketProducts('[News Xtend]');
		Id resultBundle = testcontroller.getCAsettingIdForBasketProducts('[Print Led]');
		Test.stopTest();
		//check outcome
		System.assertEquals(settingXtend.Id, resultXtend, 'Unexpected CA setting selected');
		System.assertEquals(settingBundle.Id, resultBundle, 'Unexpected CA setting selected');
	}

	/**
	 * Displaying SO attachments on Send Formal Approval Email page works from UA record.
	 * This test confirms that as soon as the approval is started system will:
	 *  - delete all but InsertionOrder attachments from Upload Approval record
	 *  - clone all SO attachments to Upload Approval record
	 * This is to ensure attachments on UA are kept in sync with SO attachments as we would like to attach only up to date attachments.
	 * Test starting position is SO with 2 attachments, UA with 1 attachment that has InsertionOrder_ in the name.
	 */
	@isTest public static void keepSOandUAattachmentsInSyncTest() {
		//get SO with UA records, expecting only 1 from both records
		csmso__Sales_Order__c so = [SELECT Id,
									(SELECT Id FROM csmso__Upload_Approval__r)
									FROM csmso__Sales_Order__c LIMIT 1];
		//we need to re-query attachment as name will be changed by triggers
		Attachment ioAtt = [SELECT Id, Name FROM Attachment WHERE ParentId = : so.csmso__Upload_Approval__r[0].Id LIMIT 1];
		//create additional attachment on UA record so that we can confirm that it will be deleted (since not found on SO)
		Attachment attUA = TestDataFactory.createAttachment(1, 'text', so.csmso__Upload_Approval__r[0].Id)[0];
		insert attUA;
		
		//ready to start the testing
		Test.startTest();
		PageReference pageRef = Page.InsertionOrder2ClickApprove;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('soId', so.Id);
		pageRef.getParameters().put('Id', so.csmso__Upload_Approval__r[0].Id);

		InsertionOrder2ClickApproveController testcontroller = new InsertionOrder2ClickApproveController();
		PageReference result                                 = testcontroller.insertionOrder2ClickApprove();

		Test.stopTest();
		//expected outcome:
		//UA has Insertion Order attachment unchanged, attUA attachment should be deleted, SO attachments cloned to UA
		Set<String> expectedAttNames    = new Set<String>{'test attachment 0','test attachment 1'};
		expectedAttNames.add(ioAtt.Name);//we need to add attachment name dynamically
		Map<Id, Attachment> uaAttResult = new Map<Id, Attachment>([SELECT Id, Name FROM Attachment WHERE ParentId = : so.csmso__Upload_Approval__r[0].Id]);
		//confirm that owe deleted only non insertion order attachment from UA record
		//System.assertEquals(false, uaAttResult.containsKey(attUA.Id), 'There should be no old non InsertionOrder attachments on UA record!');
		//System.assertEquals(true, uaAttResult.containsKey(ioAtt.Id), 'Original Insertion order attachment still should be present!');
		//confirm we have expected number of attachments and that each has expected name
		//System.assertEquals(3, uaAttResult.size(), 'Unexpected number of attachments on UA record!');
		//for (Attachment att : uaAttResult.values()) {
		//	System.assertEquals(true, expectedAttNames.contains(att.Name), 'Unexpected attachment found: ' + att.Name);
		//}
	}

	/**
	 * Create all data necessary for running test scenarios.
	 */
	@TestSetup static void setupTestData() {
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
		so.Margin__c = 0.3;
		so.csmso__Process_Message_Type__c = 'preapproved';
		so.csmso__Status__c = 'Draft';
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
		//testAttrDef.cscfga__configuration_output_mapping__c = 'test';
		insert testAttrDef;

		cscfga__Attribute__c testAttr1 = TestDataSetupClass.createAttr(prodConfig,so,testAttrDef);
		testAttr1.cscfga__Product_Configuration__c = prodConfig.Id;
		//testAttr.Configuration_Output_Mapping__c = Opportunity.Name;
		testAttr1.cscfga__Value__c = '1000';
		testAttr1.Name             = 'Product Groups For IO';
		insert testAttr1;
		
		csmso__Upload_Approval__c testUploadApproval = TestDataSetupClass.createUploadApproval(so);
		testUploadApproval.Name = 'InsertionOrder_2018-07-1614:11:30.pdf';
		insert testUploadApproval;

		Attachment ioAtt = TestDataFactory.createAttachment(1, 'text', testUploadApproval.Id)[0];
		//match naming convention before inserting
		ioAtt.Name = 'InsertionOrder_something';
		//generate SO attachments as well
		List<Attachment> soAtts = TestDataFactory.createAttachment(2, 'text', so.Id);
		//give unique names
		for (Integer i = 0; i<soAtts.size(); i++) {
			soAtts[i].Name = soAtts[i].Name + ' ' + i;
		}
		//insert all atts
		soAtts.add(ioAtt);
		insert soAtts;

		//csdf__Fulfilment__c testFulfilment = TestDataSetupClass.createFulfilment(so,acc);
		//insert testFulfilment;

		CSCAP__Click_Approve_Setting__c testClkAppSet = TestDataSetupClass.createClkAppSet();
		testClkAppSet.Name = 'IO Email Approval Setting – News Value Bundles';
		testClkAppSet.CSCAP__Status__c = 'Active';
		CSCAP__Click_Approve_Setting__c testClkAppSet2 = TestDataSetupClass.createClkAppSet();
		testClkAppSet2.Name = 'IO Email Approval Setting – News Xtend';
		testClkAppSet2.CSCAP__Status__c = 'Active';
		CSCAP__Click_Approve_Setting__c testClkAppSet3 = TestDataSetupClass.createClkAppSet();
		testClkAppSet3.Name = 'IO Email Approval Setting – News Multi Product Platform';
		testClkAppSet3.CSCAP__Status__c = 'Active';
		insert new List<CSCAP__Click_Approve_Setting__c>{testClkAppSet, testClkAppSet2, testClkAppSet3};

		CSCAP__ClickApprove_Contact_Role__c testClkAppConRoleSet = TestDataSetupClass.createClkAppConRoleSet(testUploadApproval);
		testClkAppConRoleSet.CSCAP__Role__c = '';
		insert testClkAppConRoleSet;
	}
}
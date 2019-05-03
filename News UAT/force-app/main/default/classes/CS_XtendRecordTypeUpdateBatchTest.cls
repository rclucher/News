@isTest
private class CS_XtendRecordTypeUpdateBatchTest {

	@isTest static void test_method_one() {

		// insert test custom setting needed by Product Node trigger
		csmso__SalesOrderAPI__c soApi = new csmso__SalesOrderAPI__c();
		soApi.csmso__No_Triggers__c = false;
		insert soApi;

		// insert test product nodes
		Id unusedRecordTypeId = Schema.SObjectType.csmso__Product_Node__c.getRecordTypeInfosByName().get('Provider').getRecordTypeId();

		csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
		insert bu;

		csmso__Product_Node__c pn1 = TestDataSetupClass.createProductNode('Product Node 1', bu);
		pn1.RecordTypeId = unusedRecordTypeId;
		insert pn1;

		csmso__Product_Node__c pn2 = TestDataSetupClass.createProductNode('Product Node 2', bu);
		pn2.RecordTypeId = unusedRecordTypeId;
		insert pn2;

		Test.startTest();
        Database.executeBatch(new CS_XtendRecordTypeUpdateBatch(true));
        Test.stopTest();
	}
}
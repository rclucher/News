@isTest
private class CS_XtendRcipRecordTypeUpdateBatchTest {
	
	@testSetup static void setup() {

		// insert test custom setting needed by Product Node trigger
		csmso__SalesOrderAPI__c soApi = new csmso__SalesOrderAPI__c();
		soApi.csmso__No_Triggers__c = false;
		insert soApi;

		// insert test product nodes
		csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
		insert bu;

		Id testPnRecordTypeId = Schema.SObjectType.csmso__Product_Node__c.getRecordTypeInfosByName().get('Xtend Product').getRecordTypeId();

		csmso__Product_Node__c pn1 = TestDataSetupClass.createProductNode('Product Node 1', bu);
		pn1.RecordTypeId = testPnRecordTypeId;
		insert pn1;

		csmso__Product_Node__c pn2 = TestDataSetupClass.createProductNode('Product Node 2', bu);
		pn2.RecordTypeId = testPnRecordTypeId;
		insert pn2;

		// insert test rate cards
		csmso__Rate_Card__c rc1 = new csmso__Rate_Card__c();
		rc1.csmso__Product_Node__c = pn1.Id;
		rc1.csmso__From_Date__c = Date.today();
		insert rc1;

		csmso__Rate_Card__c rc2 = new csmso__Rate_Card__c();
		rc2.csmso__Product_Node__c = pn2.Id;
		rc2.csmso__From_Date__c = Date.today();
		insert rc2;

		// insert test rate card item prices
		csmso__Rate_Card_Item_Price__c rcip1 = new csmso__Rate_Card_Item_Price__c();
		rcip1.csmso__Product_Node__c = pn1.Id;
		rcip1.csmso__Rate_Card__c    = rc1.Id;
		insert rcip1;

		csmso__Rate_Card_Item_Price__c rcip2 = new csmso__Rate_Card_Item_Price__c();
		rcip2.csmso__Product_Node__c = pn2.Id;
		rcip2.csmso__Rate_Card__c    = rc2.Id;
		insert rcip2;
	}

	@isTest static void test_method_one() {
		Test.startTest();
        Database.executeBatch(new CS_XtendRcipRecordTypeUpdateBatch(true), 200);
        Test.stopTest();
	}
	
}
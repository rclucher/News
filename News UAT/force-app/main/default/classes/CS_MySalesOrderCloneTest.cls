@isTest
private class CS_MySalesOrderCloneTest {
	
	@isTest static void testCloneFilterMethods() {
		csmso__Sales_Order__c so = [SELECT Id from csmso__Sales_Order__c];

		Test.startTest();

		CS_MySalesOrderClone mySOClone = new CS_MySalesOrderClone();

		mySOClone.prepareReferences(so.Id);
		mySOClone.filter('csmso__Sales_Order__c',  (SObject) so,  (SObject) so);
		mySOClone.cloningFinished(true);

		Test.stopTest();

	}


	@testSetup
	static void setupData() {
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
		insert soApi;

		List<BusinessHours> bhs = [select id from BusinessHours where IsDefault = true];
		System.assert(bhs.size() == 1);

		csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
		insert bu;

		Account acc = TestDataSetupClass.createAccount();
		insert acc;

		Contact con = TestDataSetupClass.createContact(acc);
		insert con;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		insert opp;

		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		so.csmso__Status__c = 'Draft';
		so.Campaign_Start_Date__c = Date.today();
		insert so;
	}
}
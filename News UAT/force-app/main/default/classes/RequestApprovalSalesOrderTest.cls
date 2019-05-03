@isTest(seeAllData = false)
public class RequestApprovalSalesOrderTest {

	@isTest
	public static void ReqApproveSO_MarginTest(){
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.Margin__c        = 1;
		so.csmso__Status__c = 'Sent for Internal Approval';
		update so;

		Test.startTest();
		RequestApprovalSalesOrder asoClass = new RequestApprovalSalesOrder();
		String str                         = so.Id;
		String paStr                       = asoClass.performAction(str);
		Test.stopTest();
	}

	@isTest
	public static void ReqApproveSO_MarginNullTest(){
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		//so.Margin__c = 0;
		so.csmso__Status__c = 'Sent for Internal Approval';
		update so;

		Test.startTest();
		RequestApprovalSalesOrder asoClass = new RequestApprovalSalesOrder();
		String str                         = so.Id;
		String paStr                       = asoClass.performAction(str);
		Test.stopTest();
	}

	@isTest
	public static void ReqApproveSO_MarginTooLowTest(){
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.Margin__c        = 0.1;
		so.Notes__c = null;
		so.csmso__Status__c = 'Sent for Internal Approval';
		update so;

		Test.startTest();
		RequestApprovalSalesOrder asoClass = new RequestApprovalSalesOrder();
		String str                         = so.Id;
		String paStr                       = asoClass.performAction(str);
		Test.stopTest();
	}

	@isTest
	public static void ReqApproveSOTestXtend(){
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.Margin__c        = 0.1;
		so.csmso__Status__c = 'Sent for Internal Approval';
		update so;
		
		Test.startTest();
		RequestApprovalSalesOrder asoClass = new RequestApprovalSalesOrder();
		String str                         = so.Id;
		String paStr                       = asoClass.performAction(str);
		Test.stopTest();
	}

	@isTest
	public static void ReqApproveSOTestNonXtend(){
		csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
		so.Margin__c        = 0.1;
		so.csmso__Status__c = 'Sent for Internal Approval';
		so.Platform_Set__c = 'not xtend';
		update so;
		
		Test.startTest();
		RequestApprovalSalesOrder asoClass = new RequestApprovalSalesOrder();
		String str                         = so.Id;
		String paStr                       = asoClass.performAction(str);
		Test.stopTest();
	}

	@testSetup
	static void setupData() {
		Account acc       = TestDataSetupClass.createAccount();
		RecordType rtypes = [SELECT Name, Id FROM RecordType WHERE sObjectType = 'Account' AND Name = 'Prospecting Account' AND isActive = true];
		acc.RecordTypeId = rtypes.Id;
		insert acc;

		Contact con = TestDataSetupClass.createContact(acc);
		insert con;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
		insert opp;

		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		so.csmso__Status__c = 'Draft';
		so.Notes__c         = 'Testing';
		so.Platform_Set__c  = '{Xtend}';
		insert so;
	}
}
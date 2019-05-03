@isTest
private class PreviousEndDateBuySheetAddOneYearTest {
	
	@isTest static void test_method_one() {

	Account acc = TestDataSetupClass.createAccount();
	insert acc;
	Contact con = TestDataSetupClass.createContact(acc);
	insert con;

	Order__c order = TestDataSetupClass.createOrder(new Opportunity());
	order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
	order.Customer_Contact__c = con.Id;
	order.Sales_Representative__c = UserInfo.getUserId();
	insert order;

	Product_Order__c prodOrder = new Product_Order__c(
			Status__c = 'Live',
			Previous_End_Date_Buy_Sheet_add_1y__c = 365,
			Order__c = order.Id
		);
	insert prodOrder;

	CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
		Name = 'testTemplate'
	);
	insert template;

	CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
			Order__c = order.Id,
			CSPOFA__Orchestration_Process_Template__c = template.Id,
			Product_Order__c = prodOrder.Id
	);
	insert process;

	CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
		To_Recepients__c = 'Customer;Campaign Manager',
		CC_Recepients__c = 'Sales Representative',
		CSPOFA__Orchestration_Process__c = process.Id
	);
	insert step;


	Test.startTest();

	PreviousEndDateBuySheetAddOneYear previousEndDate = new PreviousEndDateBuySheetAddOneYear();
	List<sObject> result = previousEndDate.process(new List<SObject>{step});

	Test.stopTest();

	}
	
	@isTest static void test_method_two() {
		// Implement test code
	}
	
}
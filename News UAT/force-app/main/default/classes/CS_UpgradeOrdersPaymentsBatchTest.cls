@isTest
private class CS_UpgradeOrdersPaymentsBatchTest {
	
	@testSetup static void prepareTest() {

		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

		Account acc = TestDataSetupClass.createAccount();
		insert acc;
        
        Contact con = TestDataSetupClass.createContact(acc);
        insert con;
        
        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

	    Order__c order = TestDataSetupClass.createOrder(opp);
	    insert order;

	    Payment__c payment = TestDataSetupClass.createPayment(order);
	    insert payment;

	    Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
	    paymentSch.Status__c = 'Pending';
	    insert paymentSch;

	    csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
        insert bu;

	    csmso__Product_Node__c productNode = TestDataSetupClass.createProductNode('Test Name', bu);
		insert productNode;

		News_Xtend_Product_Ref__c newsXtendProductRef = new News_Xtend_Product_Ref__c(Name = 'Test Xtend Prod Ref');
		newsXtendProductRef.Product_Node__c = productNode.Id;
        insert newsXtendProductRef;

	    Payment_Line_Item__c paymentLineItem = TestDataSetupClass.createPaymentLineItem(paymentSch);
	    paymentLineItem.News_Xtend_Product_Ref__c = newsXtendProductRef.Id;
	    insert paymentLineItem;

	    Product_Order__c productOrder = TestDataSetupClass.createProductOrder(order);
	    productOrder.News_Xtend_Product_Ref__c = newsXtendProductRef.Id;
	    productOrder.Status__c = 'Draft';
	    insert productOrder;

	}

	@isTest static void runTest() {
        Test.startTest();

        CS_UpgradeOrdersPaymentsBatch obj = new CS_UpgradeOrdersPaymentsBatch();
        DataBase.executeBatch(obj); 
            
        Test.stopTest();             
	}
}
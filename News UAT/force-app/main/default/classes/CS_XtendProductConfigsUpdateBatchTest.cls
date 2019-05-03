/**
 * @author Igor Vrabec <igor.vrabec@cloudsensesolutions.com>
 * @since 07/03/2018
 */
 @isTest private class CS_XtendProductConfigsUpdateBatchTest {
	
    @isTest static void runTest() {

		// insert test custom setting needed by Product Node trigger
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

		csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
		insert bu;

		csmso__Product_Node__c pn = TestDataSetupClass.createProductNode('Product Node 1', bu);
		insert pn;

		csmso__Product_Node__c pn2 = TestDataSetupClass.createProductNode('Product Node 2', bu);
		insert pn2;

		// prepare test data
		News_Xtend_Product_Ref__c nxProduct = TestDataSetupClass.createNewsXtendProductRef();
		nxProduct.Product_Node__c = pn.Id;
		nxProduct.Provider__c 	  = 'Dummy Provider';
		nxProduct.Product_Line__c = 'Dummy Product Line';
		nxProduct.Product_Type__c = 'Dummy Product Type';
		nxProduct.RecordTypeId    = Schema.SObjectType.News_Xtend_Product_Ref__c.getRecordTypeInfosByName().get('Product').getRecordTypeId(); 
		insert nxProduct;

		News_Xtend_Product_Ref__c nxProduct2 = TestDataSetupClass.createNewsXtendProductRef();
		nxProduct2.Product_Node__c = pn2.Id;
		nxProduct2.Provider__c 	   = 'Dummy Provider';
		nxProduct2.Product_Line__c = 'Dummy Product Line';
		nxProduct2.Product_Type__c = 'Dummy Product Type';
		nxProduct2.RecordTypeId    = Schema.SObjectType.News_Xtend_Product_Ref__c.getRecordTypeInfosByName().get('Product').getRecordTypeId(); 
		insert nxProduct2;

		Account acc	= TestDataSetupClass.createAccount();
		acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId(); 
		insert acc;

		Contact contact = TestDataSetupClass.createContact(acc);
		contact.Email = 'test@test.com';
		insert contact;

		Opportunity opp = TestDataSetupClass.createOpportunity(acc, contact);
		insert opp;

		csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
		insert so;

		cscfga__Product_Basket__c productBasket = TestDataSetupClass.createProdBasket(so);
		insert productBasket;

		// Product Node-based PC
		cscfga__Product_Configuration__c pcPN = TestDataSetupClass.createProdConfig(productBasket);
		pcPN.Product_ID__c    = (String)pn.Id;
		pcPN.Provider_Name__c = '';
		insert pcPN;

		// Xtend Product-based PC
		cscfga__Product_Configuration__c pcNX = TestDataSetupClass.createProdConfig(productBasket);
		pcNX.Product_ID__c    = (String)nxProduct.Id;
		pcNX.Provider_Name__c = '';
		insert pcNX;

		// Non-Xtend PC
		cscfga__Product_Configuration__c pcNonXtend = TestDataSetupClass.createProdConfig(productBasket);
		pcNonXtend.Product_ID__c    = 'xyz';
		pcNonXtend.Provider_Name__c = '';
		insert pcNonXtend;

		// do tests
    	Test.startTest();
        Database.executeBatch(new CS_XtendProductConfigsUpdateBatch(true));
        Test.stopTest();
    }
	
}
@isTest
private class CS_RetractSalesOrderServiceTest {

	@isTest static void testRetractSONonLiveCampaign() {
		Test.startTest();
		csmso__Sales_Order__c so = [select Id from csmso__Sales_Order__c limit 1];
		Order__c order = [SELECT Id FROM Order__c LIMIT 1];
		order.Status__c = 'Draft';
		update order;
        GroupMember member = [Select Id, UserOrGroupId
                                From GroupMember
                                Where Group.DeveloperName =: 'News_Xtend_Retract_SO_Group'
                                LIMIT 1];
        User testUser = [SELECT Id from User where Id =: member.UserOrGroupId];

        // test retract()
        System.runAs(testUser) {
            CS_RetractSalesOrderService.retract(so.Id);
        }
		Test.stopTest();
	}
	
	@isTest static void testRetractSOLiveCampaign() {
		Test.startTest();
		csmso__Sales_Order__c so = [select Id from csmso__Sales_Order__c limit 1];

		Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        GroupMember member = [Select Id, UserOrGroupId
                                        From GroupMember
                                        Where Group.DeveloperName =: 'News_Xtend_Retract_SO_Group'
                                        LIMIT 1];
        User testUser = [SELECT Id from User where Id =: member.UserOrGroupId];

        order.Status__c = 'Campaign Live';
		update order;

		// test retract()
        System.runAs(testUser) {
            CS_RetractSalesOrderService.retract(so.Id);

        }
		Test.stopTest();
	}

	@isTest static void testUpdatePaymentSchedules() {
		
		Order__c order = [SELECT Id, End_Date__c, Actual_Start_Date__c, Previous_Actual_Start_Date__c FROM Order__c LIMIT 1];
		order.Previous_Actual_Start_Date__c = System.today();

		Map<Id, Order__c> orderMap = new Map<Id, Order__c>();
		orderMap.put(order.Id, order);

		//test UpdatePaymentSchedules
		Test.startTest();
		CS_RetractSalesOrderService.updatePaymentSchedules(orderMap);
		Test.stopTest();
	}

	@isTest static void testUpdatePOs() {
		Order__c order = [SELECT Id FROM Order__c LIMIT 1];

		//test updateProductOrdersForRestractedOrders
		Test.startTest();
		CS_RetractSalesOrderService.updateProductOrdersForRestractedOrders(new Set<Id>{order.Id}, true);
		Test.stopTest();
	}

	@isTest static void testRetractSOInvalid() {
		Test.startTest();
		csmso__Sales_Order__c so = [select Id, csmso__Status__c from csmso__Sales_Order__c limit 1];
		Order__c order = [SELECT Id FROM Order__c LIMIT 1];

		// test so with a campaign under 'Fulfilment Started'
		order.Status__c = 'Fulfilment Started';
		update order;
		try{
			CS_RetractSalesOrderService.retract(so.Id);
		}catch(Exception ex){

		}
		

		// test so with a campaign under 'Paused'
		order.Status__c = 'Cancelled';
		update order;
		try{
			CS_RetractSalesOrderService.retract(so.Id);
		}catch(Exception ex){

		}

		// test so created from campaign track
		so.Origin__c = 'Campaign Track';
		update so;
		try{
			CS_RetractSalesOrderService.retract(so.Id);
		}catch(Exception ex){

		}
		
		Test.stopTest();
	}
	

	@testSetup
	static void setupData() {
		csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

		List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        System.assert(bhs.size() == 1);

        csmso__Business_Unit__c bu = TestDataSetupClass.createBusinessUnit();
        insert bu;

		csmso__Product_Node__c product = TestDataSetupClass.createProductNode('test SEM', bu);
        product.Product_Line__c = 'Search';
        product.Product_Type__c = 'SEM';

        csmso__Product_Node__c product1 = TestDataSetupClass.createProductNode('test social', bu);
        product1.Product_Line__c = 'Social';
        product1.Product_Type__c = 'test';

        insert product;
        insert product1;


        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'Externally Approved';
        so.Call_Tracking__c = true;
        insert so;

        Order__c order = TestDataSetupClass.createOrder(opp);
        order.Sales_Order__c = so.Id;
        order.End_Date__c = System.today().addMonths(5);
		order.Actual_start_date__c = System.today();
        insert order;

        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        // create test product configurations
        List<cscfga__Product_Configuration__c> pcList = new List<cscfga__Product_Configuration__c>();
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig.Platform__c = 'Xtend';
        prodConfig.Product_ID__c = product.Id;
        prodConfig.Total_Invoice__c = 200;

        cscfga__Product_Configuration__c prodConfig2 = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig2.Platform__c = 'Xtend';
        prodConfig2.Product_ID__c = product1.Id;
        prodConfig2.Total_Invoice__c = 200;

        cscfga__Product_Configuration__c prodConfig3 = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfig3.Platform__c = 'Xtend';
        prodConfig3.Product_ID__c = product1.Id;
        prodConfig3.Total_Invoice__c = 200;

        cscfga__Product_Configuration__c prodConfigOld = TestDataSetupClass.createProdConfig(prodBasket);
        prodConfigOld.Platform__c = 'Xtend';
        prodConfigOld.Product_ID__c = product1.Id;
        pcList.add(prodConfig);
        pcList.add(prodConfig2);
        pcList.add(prodConfig3);
        pcList.add(prodConfigOld);
        insert pcList;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Attribute_Definition__c testAttrDef1 = TestDataSetupClass.createAttrDef(testProDef);
        cscfga__Attribute_Definition__c testAttrDef2 = TestDataSetupClass.createAttrDef(testProDef);        
        cscfga__Attribute_Definition__c testAttrDef3 = TestDataSetupClass.createAttrDef(testProDef);        
        cscfga__Attribute_Definition__c testAttrDef4 = TestDataSetupClass.createAttrDef(testProDef);
        insert new List<cscfga__Attribute_Definition__c>{testAttrDef1, testAttrDef2, testAttrDef3, testAttrDef4};
        
        cscfga__Attribute__c testAttr1 = new cscfga__Attribute__c(name = 'Product Name', cscfga__Product_Configuration__c= prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef1.Id, cscfga__Value__c = 'testName');
        cscfga__Attribute__c testAttr2 = new cscfga__Attribute__c(name = 'Quantity', cscfga__Product_Configuration__c= prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef2.Id, cscfga__Value__c = '10');
        cscfga__Attribute__c testAttr3 = new cscfga__Attribute__c(name = 'Price', cscfga__Product_Configuration__c= prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef3.Id, cscfga__Value__c = '50.00');
        cscfga__Attribute__c testAttr4 =new cscfga__Attribute__c(name = 'Payment Type', cscfga__Product_Configuration__c= prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef4.Id, cscfga__Value__c = 'One Off');
        insert new List<cscfga__Attribute__c>{testAttr1, testAttr2, testAttr3, testAttr4};
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.Start_Date__c = System.today();
        insert payment;
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today().addMonths(3);
        paymentSch.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch.Status__c = 'Pending';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1); 
        insert paymentSch;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch);
        paymentLI.Price__c = 25;
        paymentLI.Type__c = 'Normal';
        insert paymentLI;


        List<Product_Order__c> pos = new List<Product_Order__c>();
        Product_Order__c po1 = new Product_Order__c(Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
                                             Order__c = order.Id,
                                             Status__c = 'In Progress',
                                             Product_Configuration__c = prodConfig.Id,
                                             PC_Id__c = prodConfig.Id,
                                             Product_Node__c = product.Id,
                                             Retail_Rate__c = 100);
       	Product_Order__c po2 = new Product_Order__c(Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
                                             Order__c = order.Id,
                                             Status__c = 'In Progress', 
                                             Product_Configuration__c = prodConfig2.Id,
                                             PC_Id__c = prodConfig2.Id,
                                             Retail_Rate__c = 300);
       	Product_Order__c po3 = new Product_Order__c(Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
                                             Order__c = order.Id,
                                             Status__c = 'In Progress', 
                                             Product_Configuration__c = prodConfig2.Id,
                                             PC_Id__c = prodConfig2.Id,
                                             Retail_Rate__c = 200);
       	Product_Order__c poOld = new Product_Order__c(Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
                                             Order__c = order.Id,
                                             Status__c = 'In Progress');
       	pos.add(po1);
       	pos.add(po2);
       	pos.add(po3);
       	pos.add(poOld);
        insert pos;

	}
}
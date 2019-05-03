@isTest
private class CS_OrderTriggerDelegate_Test 
{	
    @testSetup static void setupData()
    {
        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        System.assert(bhs.size() == 1);

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact con = TestDataSetupClass.createContact(acc);
        insert con;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, con);
        insert opp;

        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'Externally Approved';
        insert so;

        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;

        Product_Order__c pOrd = new Product_Order__c(Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
                                                     Order__c = order.Id,
                                                     Status__c = 'In Progress');
        insert pOrd;

        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
        insert prodBasket;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        insert prodConfig;
        
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
    }

	@isTest static void updateToInProgress() 
	{
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
		Test.startTest();
		
		order.Status__c = 'In Progress';
        order.Progress_Percentage__c = 40;
		update order;

        Test.stopTest();
	}

    @isTest static void updateToPendingForPause() {
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        order.Status__c = 'Pending For Pause';
        order.Progress_Percentage__c = 40;
        update order;

        Test.stopTest();
    }

/*
    // Commented out due to picklist value not in Status__c list
    @isTest static void updateToCampaignEnded() {
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        order.Status__c = 'Campaign Ended';
        update order;

        Test.stopTest();
    }
*/
    @isTest static void updateToPaused() {
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        order.Status__c = 'Paused';
        update order;

        Test.stopTest();
    }

    @isTest static void updateToCampaignLive() {
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        order.Status__c = 'Campaign Live';
        update order;

        Test.stopTest();
    }

    @isTest static void updateToPendingForCancel() {
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        order.Status__c = 'Pending For Cancel';
        update order;

        Test.stopTest();
    }

    @isTest static void updateToCancelled() {
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        order.Status__c = 'Cancelled';
        update order;

        Test.stopTest();
    }

    @isTest static void updateFromPaused() {
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        order.Status__c = 'Paused';
        update order;

        order.Status__c = 'Cancelled';
        update order;

        Test.stopTest();
    }

    @isTest static void updateCampaignManager() {
        csmso__Sales_Order__c so = [SELECT Id FROM csmso__Sales_Order__c LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];
        
        Test.startTest();
        
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        update order;

        order.Assigned_Campaign_Manager__c = null;
        update order;

        Test.stopTest();
    }
	
    @isTest static void test_updateDate() {
        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        System.assert(bhs.size() == 1);
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Proposed_Start_Date__c = Date.today();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'In Progress'
        );
        insert pOrd;

        Test.startTest();

        order.Actual_Start_Date__c = Date.today();
        order.End_Date__c = Date.today();
        update order;
        order.Proposed_Start_Date__c = Date.today()+3;
        update order;
        Test.stopTest();
    }

    @isTest static void test_updateDashDate() {
        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        System.assert(bhs.size() == 1);
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Actual_Start_Date__c = Date.today();

        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'In Progress'
        );
        insert pOrd;

        Test.startTest();

        order.Current_Dashboard_Review_Date__c  = Date.today()+1;
        update order;

        Test.stopTest();
    }

    @isTest static void test_updatePerfhDate() {
        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        System.assert(bhs.size() == 1);
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Actual_Start_Date__c = Date.today();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'In Progress'
        );
        insert pOrd;

        Test.startTest();

        order.Current_Campaign_Performance_Review_Date__c  = Date.today()+1;
        update order;

        Test.stopTest();
    }

    @isTest static void test_updateReporthDate() {
        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        System.assert(bhs.size() == 1);
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Actual_Start_Date__c = Date.today();
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'In Progress'
        );
        insert pOrd;

        Test.startTest();

        order.Current_Customer_Report_Date__c  = Date.today()+1;
        update order;

        Test.stopTest();
    }

    @isTest static void test_deleteOrder() {
        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        System.assert(bhs.size() == 1);
       
        Order__c order = [SELECT Id FROM Order__c LIMIT 1];

        Test.startTest();

        delete order;
        undelete order;

        Test.stopTest();
    }

     @isTest static void test_SetAccountName() {
  
        Test.startTest();

        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Account acc     = [SELECT Id FROM Account LIMIT 1];

        Order__c order  = TestDataSetupClass.createOrder(opp);
        order.Account__c = acc.Id;
        insert order;

        Test.stopTest();

        Order__c o = [select Account_Name__c from Order__c where Id = :order.Id];
        system.assertEquals('testAccountForSalesOrderSupportTest', o.Account_Name__c);
    }

     @isTest static void test_updat_NextDashDate() {

        List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        System.assert(bhs.size() == 1);
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Actual_Start_Date__c = Date.today();
        order.Next_Dashboard_Review_Date__c   = Date.today();
        //order.End_Date__c = Date.today()+150;
        //order.sales_Order__c = so.Id;

        Test.startTest();

        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'In Progress',
            Product_Order_Start_Date__c =  Date.today(),
            Product_Order_End_Date__c = Date.today()+150
        );

        insert pOrd;

        order.Actual_Start_Date__c = Date.today()+1;
        order.Next_Dashboard_Review_Date__c   = Date.today()+1;
        order.Cancellation_Date__c = Date.today()+100;
        order.isNextBizDateRecal__c = true;
        order.Pause_Start_Date__c = Date.today()+5;
        order.Setup_Call_Schedule__c =  Date.today()+ 10;
        order.Next_Dashboard_Review_Date__c   = Date.today()+1;
        update order;

        Test.stopTest();
    }

    @isTest static void test_shift_end_Dates_Test() {
        Date startDate = Date.newInstance(2016, 7, 31);
        Date endDate = Date.newInstance(2016, 8, 31);
        Date startDateMoved = Date.newInstance(2016, 8, 31);
        Date expectedEndDate = Date.newInstance(2016, 9, 30);
        Date datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        System.assertEquals(expectedEndDate, datakeep, 'Date not Correct '+startDate+' > '+endDate+' | new start '+startDateMoved+' Expected End '+expectedEndDate+' Actual '+datakeep);
        startDateMoved = Date.newInstance(2016, 5, 31);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2016, 6, 30);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDate = Date.newInstance(2016, 1, 1);
        endDate = Date.newInstance(2016, 8, 1);
        startDateMoved = Date.newInstance(2016, 1, 30);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2016, 1, 31);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2016, 2, 27);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2016, 2, 28);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2016, 2, 29);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDate = Date.newInstance(2016, 12, 15);
        endDate = Date.newInstance(2017, 2, 28);
        startDateMoved = Date.newInstance(2016, 12, 27);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2016, 12, 28);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2016, 12, 29);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2016, 12, 30);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2016, 12, 31);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDate = Date.newInstance(2015, 12, 15);
        endDate = Date.newInstance(2016, 2, 29);
        startDateMoved = Date.newInstance(2015, 12, 27);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2015, 12, 28);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2015, 12, 29);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2015, 12, 30);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2015, 12, 31);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDate = Date.newInstance(2018, 6, 30);
        endDate = Date.newInstance(2018, 8, 30);
        startDateMoved = Date.newInstance(2018, 7, 30);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2018, 7, 31);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDate = Date.newInstance(2018, 5, 30);
        endDate = Date.newInstance(2018, 7, 30);
        startDateMoved = Date.newInstance(2018, 5, 31);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
        startDateMoved = Date.newInstance(2018, 6, 30);
        datakeep = CS_OrderTriggerDelegate.calculateNewEndDate(startDate,endDate,startDateMoved);
    }
    
        @isTest static void test_Post_to_chatter(){
	
		List<BusinessHours> bhs = [select id from BusinessHours where IsDefault=true];
        System.assert(bhs.size() == 1);
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Actual_Start_Date__c = Date.today();
        order.Next_Dashboard_Review_Date__c   = Date.today();
        //order.End_Date__c = Date.today()+150;
        //order.sales_Order__c = so.Id;

        Test.startTest(); 

        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'In Progress',
            Product_Order_Start_Date__c =  Date.today(),
            Product_Order_End_Date__c = Date.today()+150
        );

        insert pOrd;

        order.Actual_Start_Date__c = Date.today()+1;
        order.Next_Dashboard_Review_Date__c   = Date.today()+1;
        order.Cancellation_Date__c = Date.today()+100;
        order.isNextBizDateRecal__c = true;
        order.Pause_Start_Date__c = Date.today()+5;
        order.Setup_Call_Schedule__c =  Date.today()+ 10;
        order.Next_Dashboard_Review_Date__c   = Date.today()+1;
        update order;
		list<Order__c> ordList = new list<Order__c>();
		ordList.add(order);
		CS_OrderTriggerDelegate cso = new CS_OrderTriggerDelegate();
		cso.PostToChatter(ordList,'Setup_Notes__c');
        
        Test.stopTest();
	
	}
    @isTest static void test_stringCompare(){
        CS_OrderTriggerDelegate cso1 = new CS_OrderTriggerDelegate();
        string strComp = cso1.stringCompare('Abcd','Abcd ef');
    }
}
@isTest(seeAllData=false)
public class CS_SchedulePaymentsControllerTest {
    
    @isTest
    public static void deleteOldOrder_Payment() {
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        //create a Billing file record
        Billing_File__c testBillingFile = new Billing_File__c(name = 'September 2016', Billing_Date__c = System.today(), Status__c='Pending' );
        insert testBillingFile;
        
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact contact = TestDataSetupClass.createContact(acc);
        insert contact;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, contact);
        insert opp;
        
        csmso__Sales_Order__c so1 = TestDataSetupClass.createSalesOrder(acc, opp);
        so1.csmso__Status__c = 'Externally Approved';
        insert so1;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so1);
        insert prodBasket;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        insert prodConfig;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);
        insert testAttrDef;
        
        cscfga__Attribute__c testAttr = new cscfga__Attribute__c(name = 'testAttr', cscfga__Product_Configuration__c= prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef.Id);
        insert testAttr;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.Start_Date__c = System.today();
        insert payment;
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today().addMonths(1);
        paymentSch.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch.Status__c = 'Pending';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch;
        system.debug('paymentSch-->'+paymentSch);
        System.debug('Prod Configs : ' + [select id, cscfga__Product_Basket__c, cscfga__Product_Basket__r.csmso__Sales_Order__c from cscfga__Product_Configuration__c]);
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch);
        insert paymentLI;
            
        Test.startTest();
        PageReference pageRef = Page.CS_SchedulePayments;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp);
        CS_SchedulePaymentsController bfcg = new CS_SchedulePaymentsController(sc);
        bfcg.schedulePayments();
        Test.stopTest();  
    }
    
    @isTest
    public static void status() {
        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        //create a Billing file record
        Billing_File__c testBillingFile = new Billing_File__c(name = 'September 2016', Billing_Date__c = System.today(), Status__c='Pending' );
        insert testBillingFile;
        
        Account acc = TestDataSetupClass.createAccount();
        insert acc;

        Contact contact = TestDataSetupClass.createContact(acc);
        insert contact;

        Opportunity opp = TestDataSetupClass.createOpportunity(acc, contact);
        insert opp;
        
        csmso__Sales_Order__c so1 = TestDataSetupClass.createSalesOrder(acc, opp);
        so1.csmso__Status__c = 'externally approved';
        insert so1;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so1);
        insert prodBasket;
        
        cscfga__Product_Configuration__c prodConfig = TestDataSetupClass.createProdConfig(prodBasket);
        insert prodConfig;
        
        cscfga__Product_Category__c testProdCateg = TestDataSetupClass.createProdCateg();
        insert testProdCateg;
        
        cscfga__Product_Definition__c testProDef = TestDataSetupClass.createProDef(testProdCateg);
        insert testProDef;
        
        cscfga__Attribute_Definition__c testAttrDef = TestDataSetupClass.createAttrDef(testProDef);
        insert testAttrDef;
        
        cscfga__Attribute__c testAttr = new cscfga__Attribute__c(name = 'testAttr', cscfga__Product_Configuration__c= prodConfig.Id, cscfga__Attribute_Definition__c = testAttrDef.Id);
        insert testAttr;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.Start_Date__c = System.today();
        insert payment;
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today().addMonths(1);
        paymentSch.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch.Status__c = 'In Progress';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch;
        system.debug('paymentSch-->'+paymentSch);
        System.debug('Prod Configs : ' + [select id, cscfga__Product_Basket__c, cscfga__Product_Basket__r.csmso__Sales_Order__c from cscfga__Product_Configuration__c]);
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch);
        insert paymentLI;
        
        Test.startTest();
        PageReference pageRef = Page.CS_SchedulePayments;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(opp);
        CS_SchedulePaymentsController bfcg = new CS_SchedulePaymentsController(sc);
        bfcg.schedulePayments();
        Test.stopTest();
    }
}
@isTest(seeAllData=false)
public class Order_PaymentSchedulerControllerTest {

    @testSetup static void setup() {

        csmso__SalesOrderAPI__c soApi = TestDataSetupClass.createSalesOrderAPI();
        insert soApi;

        Account account = TestDataSetupClass.createAccount();
        insert account;

        Contact contact = TestDataSetupClass.createContact(account);
        insert contact;

        Opportunity opp = TestDataSetupClass.createOpportunity(account, contact);
        insert opp;

        csmso__Sales_Order__c so  = TestDataSetupClass.createSalesOrder(account, opp);
        so.csmso__Status__c = 'Externally Approved';
        so.csmso__Booking_Contact__c = contact.Id;
        so.Campaign_Start_Date__c = System.today().addDays(20);
        so.Campaign_Length__c = 4;
        insert so;

        Order__c order = TestDataSetupClass.createOrder(opp);
        order.Actual_Start_Date__c = System.today()+30;
        order.Opportunity__c = opp.Id;
        insert order;

        cscfga__Product_Basket__c prodBasket = TestDataSetupClass.createProdBasket(so);
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
        paymentSch.Schedule_Start_Date__c = System.today().addMonths(3);
        paymentSch.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch.Status__c = 'Pending';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch;

        Payment_Line_Item__c paymentLI1 = TestDataSetupClass.createPaymentLineItem(paymentSch);
        paymentLI1.Price__c = 25;
        paymentLI1.List_Price__c = 20.00;
        paymentLI1.Type__c = 'Normal';
        paymentLI1.Payment_Schedule__c = paymentSch.Id;
        insert paymentLI1;

        Payment_Line_Item__c paymentLI2 = TestDataSetupClass.createPaymentLineItem(paymentSch);
        paymentLI2.Price__c = 50;
        paymentLI1.List_Price__c = 20.00;
        paymentLI2.Type__c = 'Normal';
        paymentLI2.Payment_Schedule__c = paymentSch.Id;
        insert paymentLI2;
    }

    @isTest
    public static void testBasic() {
        Opportunity opp = [SELECT Account.AdPoint_ID__c, Payer_Account__r.AdPoint_ID__c, JDE_Publication_Code__c, TM1_Publication__c
                             FROM Opportunity LIMIT 1];
        Order__c order  = [SELECT Actual_Start_Date__c FROM Order__c LIMIT 1];
        Payment__c payment = [SELECT Start_Date__c FROM Payment__c LIMIT 1];
        Payment_Schedule__c paymentSch = [SELECT Schedule_Start_Date__c, Schedule_End_Date__c, Status__c, Billing_Date__c
                                          FROM Payment_Schedule__c LIMIT 1];

        csmso__Sales_Order__c so = [SELECT Id, Name, csmso__Status__c, Campaign_Start_Date__c, Campaign_End_Date2__c,
                                           Campaign_Length__c, csmso__Booking_Contact__r.Name, Recurring_Price__c
                                           FROM csmso__Sales_Order__c LIMIT 1];
        cscfga__Product_Basket__c prodBasket = [SELECT ID From cscfga__Product_Basket__c LIMIT 1];

        Test.startTest();
        PageReference pageRef = Page.PaymentLayout;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(payment);
        Order_PaymentSchedulerController bfcg = new Order_PaymentSchedulerController(sc);
        Order_PaymentSchedulerController.getOrder(opp.id, so);
        Order_PaymentSchedulerController.createPaymentSchedule(so);
        Order_PaymentSchedulerController.ProdBasketList(so);
        Order_PaymentSchedulerController.ProdConfigList(prodBasket.id);
        Order_PaymentSchedulerController.createPaymentLineItem(so);
        bfcg.paymentPriceCalculation();
        bfcg.showcopyPricingButton=false;
        bfcg.copyPricingVal = paymentSch.Id;
        bfcg.copyPricingValue();
        bfcg.savelineItem();

        //Order_PaymentSchedulerController.createPayment(so, opp);  // try testing on it's own
        Order_PaymentSchedulerController.updateOrder_Payment(opp.id); // this one also deletes the orders
        Order_PaymentSchedulerController.checkActualStartDate(opp.Id);
        Test.stopTest();
    }

    @isTest
    public static void testOrderWithEndDate() {
        Opportunity opp = [SELECT Account.AdPoint_ID__c, Payer_Account__r.AdPoint_ID__c, JDE_Publication_Code__c, TM1_Publication__c
                             FROM Opportunity LIMIT 1];
        Order__c order  = [SELECT Actual_Start_Date__c FROM Order__c LIMIT 1];
        order.End_Date__c = System.today()+30;
        update order;

        Payment__c payment = [SELECT Start_Date__c FROM Payment__c LIMIT 1];
        csmso__Sales_Order__c so = [SELECT Id, Name, csmso__Status__c, Campaign_Start_Date__c, Campaign_End_Date2__c,
                                           Campaign_Length__c, csmso__Booking_Contact__r.Name, Recurring_Price__c
                                           FROM csmso__Sales_Order__c LIMIT 1];

        Test.startTest();
        PageReference pageRef = Page.PaymentLayout;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(payment);
        Order_PaymentSchedulerController bfcg = new Order_PaymentSchedulerController(sc);
        Order_PaymentSchedulerController.getOrder(opp.id, so);
        Order_PaymentSchedulerController.createPaymentSchedule(so);
        Test.stopTest();
    }
}
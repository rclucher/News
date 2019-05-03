@isTest
public class CS_PaymentCancellationHelperTest {
    
    @isTest
    public static void paymentCancellation()
    {
    	Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.End_Date__c = System.today().addMonths(3);
        payment.Last_End_Date__c = System.today().addMonths(2).addDays(-1);
        payment.Cancellation_Reason__c='Client perceived ROI';
        insert payment;
        system.debug('payment-->'+payment);
        
        Payment_Schedule__c paymentSch1 = TestDataSetupClass.createPaymentSch(payment);
		Date myStartDate = Date.newInstance(2019, 1, 1);
		Date myEndDate = Date.newInstance(2019, 2, 17);
		Date myStartDate1 = Date.newInstance(2019, 2, 1);
		Date myEndDate1 = Date.newInstance(2019, 2, 26);
        //paymentSch1.Schedule_Start_Date__c = System.today();
        //paymentSch1.Schedule_End_Date__c = System.today().addMonths(4);
		paymentSch1.Schedule_Start_Date__c = myStartDate;
        paymentSch1.Schedule_End_Date__c = myEndDate;
        paymentSch1.Status__c = 'Pending';
        paymentSch1.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch1;
        
        Map<Id, Date> testmap = new Map<Id, Date>();
        testmap.put(payment.id,System.today());
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment_Schedule__c> paymentSchList = new List<Payment_Schedule__c>();
        paymentList.add(payment);
        paymentSchList.add(paymentSch1);
        
        Test.startTest();
        CS_PaymentCancellationHelper payCancel = new CS_PaymentCancellationHelper();
        CS_PaymentCancellationHelper.calculateNumberOfPaymentSchedulesRequired(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.getLastPaymentSchedule(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.createPaymentSchedulesForPaymentCancellation(paymentList);
        CS_PaymentCancellationHelper.getPaymentScheduleForPayments(paymentList);
        CS_PaymentCancellationHelper.activateAndCancelPaymentSchedules(paymentList);
        CS_PaymentCancellationHelper.proRatePaymentSchedules(paymentList,paymentSchList,testmap);
		paymentSch1.Schedule_Start_Date__c = myStartDate1;
        paymentSch1.Schedule_End_Date__c = myEndDate1;
		CS_PaymentCancellationHelper.createPaymentSchedulesForPaymentCancellation(paymentList);
        Test.stopTest();  
    }
    
    @isTest
    public static void endDate_2()
    {
    	Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.End_Date__c = System.today().addMonths(3);
        payment.Last_End_Date__c = System.today().addMonths(2).addDays(-1);
        payment.Cancellation_Reason__c='Client perceived ROI';
        insert payment;
        system.debug('payment-->'+payment);
        
        Payment_Schedule__c paymentSch1 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch1.Schedule_Start_Date__c = System.today();
        paymentSch1.Schedule_End_Date__c = System.today().addMonths(5);
        paymentSch1.Status__c = 'Pending';
		paymentSch1.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch1;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch1);
		insert paymentLI;
        
        Map<Id, Date> testmap = new Map<Id, Date>();
        testmap.put(payment.id,System.today());
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment_Schedule__c> paymentSchList = new List<Payment_Schedule__c>();
        paymentList.add(payment);
        paymentSchList.add(paymentSch1);
        
        Test.startTest();
        CS_PaymentCancellationHelper payCancel = new CS_PaymentCancellationHelper();
        CS_PaymentCancellationHelper.calculateNumberOfPaymentSchedulesRequired(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.getLastPaymentSchedule(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.createPaymentSchedulesForPaymentCancellation(paymentList);
        CS_PaymentCancellationHelper.getPaymentScheduleForPayments(paymentList);
        //CS_PaymentCancellationHelper.activateAndCancelPaymentSchedules(paymentList);
        CS_PaymentCancellationHelper.proRatePaymentSchedules(paymentList,paymentSchList,testmap);
        Test.stopTest();  
    }
    
    @isTest
    public static void startDate_2()
    {
    	Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.End_Date__c = System.today().addMonths(3);
        payment.Last_End_Date__c = System.today().addMonths(2).addDays(-1);
        payment.Cancellation_Reason__c='Client perceived ROI';
        insert payment;
        system.debug('payment-->'+payment);
        
        Payment_Schedule__c paymentSch1 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch1.Schedule_Start_Date__c = System.today().addMonths(5);
        paymentSch1.Schedule_End_Date__c = System.today().addMonths(7);
        paymentSch1.Status__c = 'Pending';
        paymentSch1.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch1;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch1);
        insert paymentLI;
        
        Map<Id, Date> testmap = new Map<Id, Date>();
        testmap.put(payment.id,System.today());
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment_Schedule__c> paymentSchList = new List<Payment_Schedule__c>();
        paymentList.add(payment);
        paymentSchList.add(paymentSch1);
        
        Test.startTest();
        CS_PaymentCancellationHelper payCancel = new CS_PaymentCancellationHelper();
        CS_PaymentCancellationHelper.calculateNumberOfPaymentSchedulesRequired(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.getLastPaymentSchedule(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.createPaymentSchedulesForPaymentCancellation(paymentList);
        CS_PaymentCancellationHelper.getPaymentScheduleForPayments(paymentList);
        //CS_PaymentCancellationHelper.activateAndCancelPaymentSchedules(paymentList);
        CS_PaymentCancellationHelper.proRatePaymentSchedules(paymentList,paymentSchList,testmap);
        Test.stopTest();  
    }

   /* @isTest
    public static void startDateGreater()
    {
    	Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.End_Date__c = System.today().addMonths(3);
        payment.Last_End_Date__c = System.today().addMonths(2).addDays(-1);
        insert payment;
        system.debug('payment-->'+payment);
        
        Payment_Schedule__c paymentSch1 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch1.Schedule_Start_Date__c = System.today().addMonths(5);
        paymentSch1.Schedule_End_Date__c = System.today().addMonths(7);
        paymentSch1.Status__c = 'Pending';
        paymentSch1.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch1;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch1);
        insert paymentLI;
        
        Map<Id, Date> testmap = new Map<Id, Date>();
        testmap.put(payment.id,System.today());
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment_Schedule__c> paymentSchList = new List<Payment_Schedule__c>();
        paymentList.add(payment);
        paymentSchList.add(paymentSch1);
        
        Test.startTest();
        CS_PaymentCancellationHelper payCancel = new CS_PaymentCancellationHelper();
        CS_PaymentCancellationHelper.calculateNumberOfPaymentSchedulesRequired(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.getLastPaymentSchedule(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.createPaymentSchedulesForPaymentCancellation(paymentList);
        CS_PaymentCancellationHelper.getPaymentScheduleForPayments(paymentList);
        CS_PaymentCancellationHelper.activateAndCancelPaymentSchedules(paymentList);
        CS_PaymentCancellationHelper.proRatePaymentSchedules(paymentList,paymentSchList,testmap);
        Test.stopTest();  
    }*/

    @isTest
    public static void endDate_LastSchDate()
    {
    	Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.End_Date__c = System.today().addMonths(3);
        payment.Last_End_Date__c = System.today().addMonths(2);
        payment.Last_Scheduled_End_Date__c = System.today().addMonths(7);
        payment.Cancellation_Reason__c='Client perceived ROI';
        insert payment;
        system.debug('payment-->'+payment);
        
        Payment_Schedule__c paymentSch1 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch1.Schedule_Start_Date__c = System.today().addMonths(4);
        paymentSch1.Schedule_End_Date__c = System.today().addMonths(7);
        paymentSch1.Status__c = 'Pending';
        paymentSch1.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch1;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch1);
        paymentLI.List_Price__c = 200.50;
        insert paymentLI;
        
        Map<Id, Date> testmap = new Map<Id, Date>();
        testmap.put(payment.id,System.today().addMonths(5));
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment_Schedule__c> paymentSchList = new List<Payment_Schedule__c>();
        paymentList.add(payment);
        paymentSchList.add(paymentSch1);
        
        Test.startTest();
        CS_PaymentCancellationHelper payCancel = new CS_PaymentCancellationHelper();
        CS_PaymentCancellationHelper.calculateNumberOfPaymentSchedulesRequired(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.getLastPaymentSchedule(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.createPaymentSchedulesForPaymentCancellation(paymentList);
        CS_PaymentCancellationHelper.getPaymentScheduleForPayments(paymentList);
       // CS_PaymentCancellationHelper.activateAndCancelPaymentSchedules(paymentList);
        CS_PaymentCancellationHelper.proRatePaymentSchedules(paymentList,paymentSchList,testmap);
        Test.stopTest();  
    }
    
    @isTest
    public static void lastPsFound_False()
    {
    	Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.End_Date__c = System.today().addMonths(3);
        payment.Last_End_Date__c = System.today().addMonths(2);
        payment.Last_Scheduled_End_Date__c = System.today().addMonths(5);
        payment.Last_Scheduled_Start_Date__c = System.today().addMonths(2);
        payment.Cancellation_Reason__c='Client perceived ROI';
        insert payment;
        system.debug('payment-->'+payment);
        
        Payment_Schedule__c paymentSch1 = TestDataSetupClass.createPaymentSch(payment);
        //paymentSch1.Schedule_Start_Date__c = System.today();
       // paymentSch1.Schedule_End_Date__c = System.today().addMonths(7);
        paymentSch1.Status__c = 'Pending';
        paymentSch1.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch1;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch1);
        paymentLI.List_Price__c = 200.50;
        insert paymentLI;
        
        Map<Id, Date> testmap = new Map<Id, Date>();
        testmap.put(payment.id,System.today().addMonths(5));
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment_Schedule__c> paymentSchList = new List<Payment_Schedule__c>();
        paymentList.add(payment);
        paymentSchList.add(paymentSch1);
        
        Test.startTest();
        CS_PaymentCancellationHelper payCancel = new CS_PaymentCancellationHelper();
        CS_PaymentCancellationHelper.calculateNumberOfPaymentSchedulesRequired(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.getLastPaymentSchedule(paymentList,paymentSchList);
        //CS_PaymentCancellationHelper.createPaymentSchedulesForPaymentCancellation(paymentList);
        CS_PaymentCancellationHelper.getPaymentScheduleForPayments(paymentList);
       // CS_PaymentCancellationHelper.activateAndCancelPaymentSchedules(paymentList);
        CS_PaymentCancellationHelper.proRatePaymentSchedules(paymentList,paymentSchList,testmap);
        Test.stopTest();  
    }
    
    @isTest
    public static void lastSchStartDate_2()
    {
    	Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.End_Date__c = System.today().addMonths(3);
        payment.Last_End_Date__c = System.today().addMonths(2);
        payment.Last_Scheduled_End_Date__c = System.today().addMonths(7);
        payment.Last_Scheduled_Start_Date__c = System.today().addMonths(5);
        payment.Cancellation_Reason__c='Client perceived ROI';
        insert payment;
        system.debug('payment-->'+payment);
        
        Payment_Schedule__c paymentSch1 = TestDataSetupClass.createPaymentSch(payment);
        //paymentSch1.Schedule_Start_Date__c = System.today();
        //paymentSch1.Schedule_End_Date__c = System.today().addMonths(7);
        paymentSch1.Status__c = 'Pending';
        paymentSch1.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch1;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch1);
        paymentLI.List_Price__c = 200.50;
        insert paymentLI;
        
        Map<Id, Date> testmap = new Map<Id, Date>();
        testmap.put(payment.id,System.today().addMonths(5));
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment_Schedule__c> paymentSchList = new List<Payment_Schedule__c>();
        paymentList.add(payment);
        paymentSchList.add(paymentSch1);
        
        Test.startTest();
        CS_PaymentCancellationHelper payCancel = new CS_PaymentCancellationHelper();
        CS_PaymentCancellationHelper.calculateNumberOfPaymentSchedulesRequired(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.getLastPaymentSchedule(paymentList,paymentSchList);
        //CS_PaymentCancellationHelper.createPaymentSchedulesForPaymentCancellation(paymentList);
        CS_PaymentCancellationHelper.getPaymentScheduleForPayments(paymentList);
       // CS_PaymentCancellationHelper.activateAndCancelPaymentSchedules(paymentList);
        CS_PaymentCancellationHelper.proRatePaymentSchedules(paymentList,paymentSchList,testmap);
        Test.stopTest();  
    }

    @isTest
    public static void lastSchStartDate_not2()
    {
    	Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        payment.End_Date__c = System.today().addMonths(3);
        payment.Last_End_Date__c = System.today().addMonths(2);
        payment.Last_Scheduled_End_Date__c = System.today().addMonths(7);
        payment.Last_Scheduled_Start_Date__c = System.today().addMonths(6);
        payment.Cancellation_Reason__c='Client perceived ROI';
        insert payment;
        system.debug('payment-->'+payment);
        
        Payment_Schedule__c paymentSch1 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch1.Schedule_Start_Date__c = System.today();
        paymentSch1.Schedule_End_Date__c = System.today().addMonths(7);
        paymentSch1.Status__c = 'Pending';
        paymentSch1.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch1;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch1);
        paymentLI.List_Price__c = 200.50;
        paymentLI.Type__c = 'Normal';
        insert paymentLI;
        
        Map<Id, Date> testmap = new Map<Id, Date>();
        testmap.put(payment.id,System.today().addMonths(5));
        List<Payment__c> paymentList = new List<Payment__c>();
        List<Payment_Schedule__c> paymentSchList = new List<Payment_Schedule__c>();
        paymentList.add(payment);
        paymentSchList.add(paymentSch1);
        
        Test.startTest();
        CS_PaymentCancellationHelper payCancel = new CS_PaymentCancellationHelper();
        CS_PaymentCancellationHelper.calculateNumberOfPaymentSchedulesRequired(paymentList,paymentSchList);
        CS_PaymentCancellationHelper.getLastPaymentSchedule(paymentList,paymentSchList);
        //CS_PaymentCancellationHelper.createPaymentSchedulesForPaymentCancellation(paymentList);
        CS_PaymentCancellationHelper.getPaymentScheduleForPayments(paymentList);
       // CS_PaymentCancellationHelper.activateAndCancelPaymentSchedules(paymentList);
        CS_PaymentCancellationHelper.proRatePaymentSchedules(paymentList,paymentSchList,testmap);
        Test.stopTest();  
    }

}
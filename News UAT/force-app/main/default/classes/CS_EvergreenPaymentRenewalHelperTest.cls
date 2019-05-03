@isTest(seeAllData=false)
public class CS_EvergreenPaymentRenewalHelperTest {
    
    @isTest
    public static void createBillingFile()
    {
        Set<Id> paymentIdSet = new Set<Id>();
        
        //create a Billing file record
        Billing_File__c testBillingFile = new Billing_File__c(name = 'September 2016', Billing_Date__c = System.today(), Status__c='Pending' );
        insert testBillingFile;
        
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        insert payment;
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today();
        paymentSch.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch.Status__c = 'Pending';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch;
        system.debug('paymentSch-->'+paymentSch);
        
        PS_Billing_File_Association__c pbfa = new PS_Billing_File_Association__c(Billing_File__c = testBillingFile.id, Payment_Schedule__c = paymentSch.id);
        insert pbfa;
        
        paymentIdSet.add(payment.id);
        
        CS_EvergreenPaymentRenewalHelper evergreenPaymentRenewalHelper = new CS_EvergreenPaymentRenewalHelper();
        CS_EvergreenPaymentRenewalHelper.clonePaymentScheduleWithLineItems(paymentIdSet);     
    }

    @isTest
    public static void endDateMonth_2()
    {
        Set<Id> paymentIdSet = new Set<Id>();
        
        //create a Billing file record
        Billing_File__c testBillingFile = new Billing_File__c(name = 'September 2016', Billing_Date__c = System.today(), Status__c='Pending' );
        insert testBillingFile;
        
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        insert payment;
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today();
        paymentSch.Schedule_End_Date__c = System.today().addMonths(5);
        paymentSch.Status__c = 'Pending';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch;
        system.debug('paymentSch-->'+paymentSch);
        
        PS_Billing_File_Association__c pbfa = new PS_Billing_File_Association__c(Billing_File__c = testBillingFile.id, Payment_Schedule__c = paymentSch.id);
        insert pbfa;
        
        paymentIdSet.add(payment.id);
        
        CS_EvergreenPaymentRenewalHelper evergreenPaymentRenewalHelper = new CS_EvergreenPaymentRenewalHelper();
        CS_EvergreenPaymentRenewalHelper.clonePaymentScheduleWithLineItems(paymentIdSet);     
    }
    
    @isTest
    public static void startDateMonth_2()
    {
        Set<Id> paymentIdSet = new Set<Id>();
        
        //create a Billing file record
        Billing_File__c testBillingFile = new Billing_File__c(name = 'September 2016', Billing_Date__c = System.today(), Status__c='Pending' );
        insert testBillingFile;
        
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        insert acc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today());
        insert opp;
        
        Order__c order = TestDataSetupClass.createOrder(opp);
        insert order;
        
        Payment__c payment = TestDataSetupClass.createPayment(order);
        insert payment;
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today().addMonths(3);
        paymentSch.Schedule_End_Date__c = System.today().addMonths(7);
        paymentSch.Status__c = 'Pending';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch;
        system.debug('paymentSch-->'+paymentSch);
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch);
        paymentLI.Price__c = 24.02;
        paymentLI.Type__c = 'Normal';
        insert paymentLI;
        
        PS_Billing_File_Association__c pbfa = new PS_Billing_File_Association__c(Billing_File__c = testBillingFile.id, Payment_Schedule__c = paymentSch.id);
        insert pbfa;
        
        paymentIdSet.add(payment.id);
        
        CS_EvergreenPaymentRenewalHelper evergreenPaymentRenewalHelper = new CS_EvergreenPaymentRenewalHelper();
        CS_EvergreenPaymentRenewalHelper.clonePaymentScheduleWithLineItems(paymentIdSet);     
    }
}
@isTest
public class CS_BatchEvergreenRenewalTest {
    
    @isTest
    public static void createBillingFile()
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
        insert payment;
        system.debug('payment-->'+payment);
        
        Payment_Schedule__c paymentSch1 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch1.Schedule_Start_Date__c = System.today();
        paymentSch1.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch1.Status__c = 'Pending';
        paymentSch1.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch1;
        
        Payment_Schedule__c paymentSch2 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch2.Schedule_Start_Date__c = System.today();
        paymentSch2.Schedule_End_Date__c = System.today().addMonths(5);
        paymentSch2.Status__c = 'Pending';
        paymentSch2.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch2;
        
        Payment_Schedule__c paymentSch3 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch3.Schedule_Start_Date__c = System.today();
        paymentSch3.Schedule_End_Date__c = System.today().addMonths(6);
        paymentSch3.Status__c = 'Pending';
        paymentSch3.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch3;
        
        Test.startTest();
        CS_BatchEvergreenRenewal ber = new CS_BatchEvergreenRenewal();
        Database.executeBatch(ber);
        Test.stopTest();  
    }
    
    @isTest
    public static void endDateGreaterThanLastEndDate()
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
        payment.End_Date__c = System.today().addMonths(4);
        payment.Last_End_Date__c = System.today();
        payment.Cancellation_Reason__c='Client perceived ROI';
        insert payment;
        system.debug('payment-->'+payment);
        
        Payment_Schedule__c paymentSch1 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch1.Schedule_Start_Date__c = System.today();
        paymentSch1.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch1.Status__c = 'Pending';
        paymentSch1.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch1;
        
        Payment_Schedule__c paymentSch2 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch2.Schedule_Start_Date__c = System.today();
        paymentSch2.Schedule_End_Date__c = System.today().addMonths(5);
        paymentSch2.Status__c = 'Pending';
        paymentSch2.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch2;
        
        Payment_Schedule__c paymentSch3 = TestDataSetupClass.createPaymentSch(payment);
        paymentSch3.Schedule_Start_Date__c = System.today();
        paymentSch3.Schedule_End_Date__c = System.today().addMonths(6);
        paymentSch3.Status__c = 'Pending';
        paymentSch3.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch3;
        
        Test.startTest();
        CS_BatchEvergreenRenewal ber = new CS_BatchEvergreenRenewal();
        Database.executeBatch(ber);
        Test.stopTest();  
    }

}
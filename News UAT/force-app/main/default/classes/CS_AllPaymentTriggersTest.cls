@isTest
public class CS_AllPaymentTriggersTest {
    
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
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today().addMonths(1);
        paymentSch.Schedule_End_Date__c = System.today().addMonths(9);
        paymentSch.Status__c = 'In Progress';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch;
        
    }

    @isTest
    public static void updaterec()
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
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today().addMonths(1);
        paymentSch.Schedule_End_Date__c = System.today().addMonths(9);
        paymentSch.Status__c = 'In Progress';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch;
        
        test.startTest();
        payment.End_Date__c = System.today().addMonths(5);
        payment.Last_End_Date__c = System.today();
        update payment;
        
        test.stopTest();

        
    }

}
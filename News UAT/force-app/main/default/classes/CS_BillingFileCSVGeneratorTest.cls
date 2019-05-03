@isTest
public class CS_BillingFileCSVGeneratorTest {
    
    @isTest
    public static void createBillingFile()
    {
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
        payment.Start_Date__c = System.today();
        insert payment;
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today().addMonths(1);
        paymentSch.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch.Status__c = 'Pending';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch;
        system.debug('paymentSch-->'+paymentSch);
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch);
        paymentLI.Price__c = 12.00;
        insert paymentLI;
        
        PS_Billing_File_Association__c pbfa = new PS_Billing_File_Association__c(Billing_File__c = testBillingFile.id, Payment_Schedule__c = paymentSch.id);
        insert pbfa;
        
        Test.startTest();
        CS_BillingFileCSVGenerator bfcg = new CS_BillingFileCSVGenerator();
        CS_BillingFileCSVGenerator.generateCSV(testBillingFile);
        Test.stopTest();
    }

}
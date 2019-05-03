@isTest(seeAllData=false)
public class CS_BillingFileRedirectControllerTest {

    @isTest
    public static void redirectBillingFile()
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
        insert payment;
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today();
        paymentSch.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch.Status__c = 'Pending';
        paymentSch.Billing_Date__c = System.today();
        insert paymentSch;
        
        Test.startTest();
            PageReference pageRef = Page.CS_BillingFilePaymentCreation;
            Test.setCurrentPage(pageRef);
        	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testBillingFile);
        	ApexPages.currentPage().getParameters().put('recordId',paymentSch.id);
            CS_BillingFileRedirectController  testcontroller = new CS_BillingFileRedirectController(sc);
        	testcontroller.generatePayments();
        	CS_BillingFileRedirectController.generatePayments(testBillingFile.id);
        Test.stopTest();
    }
    
    @isTest
    public static void redirectBillingFile_Exception()
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
        insert payment;
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today();
        paymentSch.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch.Status__c = 'Pending';
        paymentSch.Billing_Date__c = System.today();
        insert paymentSch;
        
        Test.startTest();
            PageReference pageRef = Page.CS_BillingFilePaymentCreation;
            Test.setCurrentPage(pageRef);
        	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(paymentSch);
        	ApexPages.currentPage().getParameters().put('recordId',paymentSch.id);
            CS_BillingFileRedirectController  testcontroller = new CS_BillingFileRedirectController(sc);
        	testcontroller.generatePayments();
        Test.stopTest();
    }
}
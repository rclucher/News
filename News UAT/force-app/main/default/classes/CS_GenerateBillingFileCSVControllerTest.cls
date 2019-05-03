@isTest
public class CS_GenerateBillingFileCSVControllerTest {

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
        
        PS_Billing_File_Association__c pbfa = new PS_Billing_File_Association__c(Billing_File__c = testBillingFile.id, Payment_Schedule__c = paymentSch.id);
        insert pbfa;
        
        Attachment attach=new Attachment();   	
    	attach.Name=testBillingFile.name;
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=testBillingFile.id;
        insert attach;
        
        Test.startTest();
        PageReference pageRef = Page.CS_GenerateBillingFileCSV;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testBillingFile);
        CS_GenerateBillingFileCSVController bfcg = new CS_GenerateBillingFileCSVController(sc);
        bfcg.generateCSV();
        CS_GenerateBillingFileCSVController.generateCSV(testBillingFile.id);
        Test.stopTest();
    }
    
    @isTest
    public static void exception()
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
        
        PS_Billing_File_Association__c pbfa = new PS_Billing_File_Association__c(Billing_File__c = testBillingFile.id, Payment_Schedule__c = paymentSch.id);
        insert pbfa;
        
        Attachment attach=new Attachment();   	
    	attach.Name=testBillingFile.name;
    	Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
    	attach.body=bodyBlob;
        attach.parentId=testBillingFile.id;
        insert attach;
        
        Test.startTest();
        PageReference pageRef = Page.CS_GenerateBillingFileCSV;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testBillingFile);
        CS_GenerateBillingFileCSVController bfcg = new CS_GenerateBillingFileCSVController(sc);
        bfcg.generateCSV();
        CS_GenerateBillingFileCSVController.generateCSV(payment.id);
        Test.stopTest();
    }
}
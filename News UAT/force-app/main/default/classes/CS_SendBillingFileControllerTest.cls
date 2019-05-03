@isTest(seeAllData=false)
public class CS_SendBillingFileControllerTest {
    
    @isTest
    public static void createBillingFile()
    {
        //create a Billing file record
        Billing_File__c testBillingFile = new Billing_File__c(name = 'September 2016', Billing_Date__c = System.today(), Status__c='Pending', Error_Message__c ='res' );
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
        
        PageReference pageRef = Page.CS_SendBillingFile;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testBillingFile);
        CS_SendBillingFileController sendBillingFileHelper = new CS_SendBillingFileController(sc);
        Datetime dt = System.now();
        String filename = dt.format('MMMMM') + ' ' + dt.year();
        Date dateFilter = dt.date().addMonths(1).toStartofMonth().addDays(-1);
        
        //system.assertEquals(dateFilter,paymentSch.Billing_Date__c);
        CS_SendBillingFileController.sendBillingFile(testBillingFile.id);
        sendBillingFileHelper.sendBillingFile();
    }

    @isTest
    public static void bf_status()
    {
        //create a Billing file record
        Billing_File__c testBillingFile = new Billing_File__c(name = 'September 2016', Billing_Date__c = System.today(), Status__c='Sent to Billing' );
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
        
        PageReference pageRef = Page.CS_SendBillingFile;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(testBillingFile);
        CS_SendBillingFileController sendBillingFileHelper = new CS_SendBillingFileController(sc);
        Datetime dt = System.now();
        String filename = dt.format('MMMMM') + ' ' + dt.year();
        Date dateFilter = dt.date().addMonths(1).toStartofMonth().addDays(-1);
        
        //system.assertEquals(dateFilter,paymentSch.Billing_Date__c);
        CS_SendBillingFileController.sendBillingFile(testBillingFile.id);
        sendBillingFileHelper.sendBillingFile();
    }

}
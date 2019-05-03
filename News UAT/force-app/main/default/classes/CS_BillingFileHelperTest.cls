@isTest(seeAllData=false)
public class CS_BillingFileHelperTest {
    
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
        
        CS_BillingFileHelper billingFileHelper = new CS_BillingFileHelper();
        Datetime dt = System.now();
        String filename = dt.format('MMMMM') + ' ' + dt.year();
        Date dateFilter = dt.date().addMonths(1).toStartofMonth().addDays(-1);
        system.debug('dateFilter-->'+dateFilter);
        system.debug('paymentSch.Billing_Date__cTC-->'+paymentSch.Billing_Date__c);
       // system.assertEquals(dateFilter,paymentSch.Billing_Date__c);
        CS_BillingFileHelper.createBillingFile(dt);
        CS_BillingFileHelper.associatePaymentSchedulesToBillingFile(dt);
		List<Payment_Schedule__c> psList = [
				select id, name, Status__c
				from Payment_Schedule__c
				where Billing_Date__c = :dateFilter
				and (Status__c = 'Pending' or Status__c = 'In Progress')
			]; 
        system.debug('psListTC-->'+psList);    
        system.debug('Billing_Date__cTC-->'+paymentSch.Billing_Date__c); 
        List<Billing_File__c> bfList = [
			select id, name, Status__c
			from Billing_File__c
			where name = :fileName
		];
        system.debug('bfListTC-->'+bfList);
        
    }
    
    @isTest
    public static void bflist_empty()
    {
        //create a Billing file record
        Billing_File__c testBillingFile = new Billing_File__c(name = 'testbf', Billing_Date__c = System.today(), Status__c='Pending' );
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
        paymentSch.Schedule_Start_Date__c = System.today().addMonths(1);
        paymentSch.Schedule_End_Date__c = System.today().addMonths(4);
        paymentSch.Status__c = 'Pending';
        paymentSch.Billing_Date__c = System.now().date().addMonths(1).toStartofMonth().addDays(-1);
        insert paymentSch;
        system.debug('paymentSch-->'+paymentSch);
        
        PS_Billing_File_Association__c pbfa = new PS_Billing_File_Association__c(Billing_File__c = testBillingFile.id, Payment_Schedule__c = paymentSch.id);
        insert pbfa;
        
        CS_BillingFileHelper billingFileHelper = new CS_BillingFileHelper();
        Datetime dt = System.now();
        String filename = dt.format('MMMMM') + ' ' + dt.year();
        Date dateFilter = dt.date().addMonths(1).toStartofMonth().addDays(-1);
        system.debug('dateFilter-->'+dateFilter);
        system.debug('paymentSch.Billing_Date__cTC-->'+paymentSch.Billing_Date__c);
       // system.assertEquals(dateFilter,paymentSch.Billing_Date__c);
        CS_BillingFileHelper.createBillingFile(dt);
        CS_BillingFileHelper.associatePaymentSchedulesToBillingFile(dt);
		List<Payment_Schedule__c> psList = [
				select id, name, Status__c
				from Payment_Schedule__c
				where Billing_Date__c = :dateFilter
				and (Status__c = 'Pending' or Status__c = 'In Progress')
			]; 
        system.debug('psListTC-->'+psList);    
        List<Billing_File__c> bfList = [
			select id, name, Status__c
			from Billing_File__c
			where name = :fileName
		];
        system.debug('bfListTC-->'+bfList);
        
    }
  

}
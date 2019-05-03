@isTest(seeAllData=false)
public class CreditAdjustmentControllerTest {

    @isTest
    public static void status_Pending()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u2 = new User(Alias = 'newUser', Email='newuser@testorg.com', 
                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, 
                           TimeZoneSidKey='Australia/Sydney', UserName='testuserforcallout@testorg.com',
                           Sales_Team__c = 'QLD Metro',
                           Bypass_Triggers__c = 'AccountManagement;AccountTeam;CaseManagement;OpportunityManagement;SalesOrder_Helper_Trigger');
        System.runAs(u2){
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
        paymentSch.Status__c = 'Pending';
        insert paymentSch;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch);
        paymentLI.Price__c = 25.00;
        paymentLI.Type__c ='Normal';
        insert paymentLI;
        
        Test.startTest();
            PageReference pageRef = Page.Credit_Adjustment_Page;
            
            Test.setCurrentPage(pageRef);
        	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(payment);
            CreditAdjustmentController  testcontroller = new CreditAdjustmentController(sc);
        	Boolean psFound = true;
            testcontroller.paymentScheduleList[0].Payment_Line_Items__r[0].price__c = 10;
        	testcontroller.savelineItem();
        Test.stopTest();
        }
    }
    
    @isTest
    public static void status_Cancelled()
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
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today().addMonths(1);
        paymentSch.Status__c = 'Pending Cancellation';
        insert paymentSch;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch);
        paymentLI.Price__c = 25.00;
        paymentLI.Type__c ='Normal';
        insert paymentLI;
        
        Test.startTest();
            PageReference pageRef = Page.Credit_Adjustment_Page;
            Test.setCurrentPage(pageRef);
        	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(payment);
            CreditAdjustmentController  testcontroller = new CreditAdjustmentController(sc);
        	Boolean psFound = true;
        	paymentLI.Price__c = 24.02;
        	update paymentLI;
        	testcontroller.savelineItem();
        Test.stopTest();
        
    }
    
    @isTest
    public static void cloning()
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
        
        Payment_Schedule__c paymentSch = TestDataSetupClass.createPaymentSch(payment);
        paymentSch.Schedule_Start_Date__c = System.today().addDays(15);
        paymentSch.Status__c = 'Pending';
        insert paymentSch;
        
        Payment_Line_Item__c paymentLI = TestDataSetupClass.createPaymentLineItem(paymentSch);
        paymentLI.Price__c = 25.00;
        paymentLI.Type__c ='Normal';
        insert paymentLI;
        
        Test.startTest();
            PageReference pageRef = Page.Credit_Adjustment_Page;
            Test.setCurrentPage(pageRef);
        	ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(payment);
            CreditAdjustmentController  testcontroller = new CreditAdjustmentController(sc);
        	Boolean psFound = true;
        	paymentLI.Price__c = 24.02;
        	update paymentLI;
        	paymentSch.Status__c = 'Pending';
        	update paymentSch;
        	testcontroller.savelineItem();
        Test.stopTest();
        
    }
}
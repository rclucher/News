/*
* 2017-06-15 Existing class
* 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
*
*      This class provides test coverage for
*          - SalesOrder_Helper_Trigger.trigger             100% 
--------------------------------------------------------- */
@isTest(seeAllData=false)
public class NewSalesOrderTest {
    
    static public List<Product2> products;
    static public List<Pricebook2> pricebooks;
    static public List<PricebookEntry> pricebookEntries;    
    static public void setupProductData(){    
        // create 10 products
        products = TestDataFactory.createProducts(1);
        // create pricebooks
        pricebooks = TestDataFactory.createCustomPricebookData();
        pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
    }
    @isTest
    public static void oppGroup()
    {
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        acc.AdPoint_ID__c = null;
        acc.Is_Digital__c = false;
        insert acc;
        
        Account payerAcc = TestDataSetupClass.createAccount();
        RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        payerAcc.RecordTypeId = payerAccrtypes.Id;
        payerAcc.AdPoint_ID__c = null;
        payerAcc.Is_Digital__c = false;
        insert payerAcc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                          OpportunityGroup__c = 'Digital',  Payer_Account__c = payerAcc.Id);
        insert opp;
        
        setupProductData();
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(new List<Opportunity>{opp}, products, pricebookEntries, null);
        insert olis;
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'externally approved';
        insert so;
        
        List<csmso__Sales_Order__c> soList = new List<csmso__Sales_Order__c>();
        soList.add(so);
        
        Test.startTest();
        PageReference pageRef = Page.NewSalesOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
        ApexPages.currentPage().getParameters().put('Id',opp.id);
        NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);
        testcontroller.opptyValidation();
        testcontroller.redirectToOppotunity();
        
        Test.stopTest();
    }
    
    @isTest
    public static void AccountAdPointID_null()
    {
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        acc.AdPoint_ID__c = null;
        acc.Is_Digital__c = false;
        insert acc;
        
        Account payerAcc = TestDataSetupClass.createAccount();
        RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        payerAcc.RecordTypeId = payerAccrtypes.Id;
        payerAcc.AdPoint_ID__c = null;
        payerAcc.Is_Digital__c = false;
        insert payerAcc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                          OpportunityGroup__c = 'NewsXtend',  Payer_Account__c = payerAcc.Id);
        insert opp;
        
        setupProductData();
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(new List<Opportunity>{opp}, products, pricebookEntries, null);
        insert olis;
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'externally approved';
        insert so;
        
        List<csmso__Sales_Order__c> soList = new List<csmso__Sales_Order__c>();
        soList.add(so);
        
        Test.startTest();
        PageReference pageRef = Page.NewSalesOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
        ApexPages.currentPage().getParameters().put('Id',opp.id);
        NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);
        testcontroller.opptyValidation();
        testcontroller.redirectToOppotunity();
        
        Test.stopTest();
    }
    
    @isTest
    public static void PayerAccAdPointID_null()
    {
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        acc.AdPoint_ID__c = '12345';
        acc.Is_Digital__c = false;
        insert acc;
        
        Account payerAcc = TestDataSetupClass.createAccount();
        RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        payerAcc.RecordTypeId = payerAccrtypes.Id;
        payerAcc.AdPoint_ID__c = null;
        payerAcc.Is_Digital__c = false;
        insert payerAcc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                          OpportunityGroup__c = 'NewsXtend',  Payer_Account__c = payerAcc.Id);
        insert opp;
        
        setupProductData();
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(new List<Opportunity>{opp}, products, pricebookEntries, null);
        insert olis;
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'externally approved';
        insert so;
        
        List<csmso__Sales_Order__c> soList = new List<csmso__Sales_Order__c>();
        soList.add(so);
        
        Test.startTest();
        PageReference pageRef = Page.NewSalesOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
        ApexPages.currentPage().getParameters().put('Id',opp.id);
        NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);
        testcontroller.opptyValidation();
        testcontroller.redirectToOppotunity(); 
        
        Test.stopTest();
    }
    
    @isTest
    public static void AccIsDigital_false()
    {
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        acc.AdPoint_ID__c = '12345';
        acc.Is_Digital__c = false;
        insert acc;
        
        Account payerAcc = TestDataSetupClass.createAccount();
        RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        payerAcc.RecordTypeId = payerAccrtypes.Id;
        payerAcc.AdPoint_ID__c = '6789';
        payerAcc.Is_Digital__c = false;
        insert payerAcc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                          OpportunityGroup__c = 'NewsXtend',  Payer_Account__c = payerAcc.Id);
        insert opp;
        
        setupProductData();
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(new List<Opportunity>{opp}, products, pricebookEntries, null);
        insert olis;
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'externally approved';
        insert so;
        
        List<csmso__Sales_Order__c> soList = new List<csmso__Sales_Order__c>();
        soList.add(so);
        
        Test.startTest();
        PageReference pageRef = Page.NewSalesOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
        ApexPages.currentPage().getParameters().put('Id',opp.id);
        NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);
        testcontroller.opptyValidation();
        testcontroller.redirectToOppotunity(); 
        
        Test.stopTest();
    }
    
    @isTest
    public static void PayerAccIsDigital_false()
    {
        // 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
        Industry_Code__c indCode = TestDataFactory.createIndustryCode();
        insert indCode;
        
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        acc.AdPoint_ID__c = '12345';
        acc.Is_Digital__c = true;
        acc.Industry_Code__c = indCode.Id;
        insert acc;
        
        Account payerAcc = TestDataSetupClass.createAccount();
        RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        payerAcc.RecordTypeId = payerAccrtypes.Id;
        payerAcc.AdPoint_ID__c = '6789';
        payerAcc.Is_Digital__c = false;
        insert payerAcc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                          OpportunityGroup__c = 'NewsXtend',  Payer_Account__c = payerAcc.Id);
        insert opp;
        
        setupProductData();
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(new List<Opportunity>{opp}, products, pricebookEntries, null);
        insert olis;
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'externally approved';
        insert so;
        
        List<csmso__Sales_Order__c> soList = new List<csmso__Sales_Order__c>();
        soList.add(so);
        
        Test.startTest();
        PageReference pageRef = Page.NewSalesOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
        ApexPages.currentPage().getParameters().put('Id',opp.id);
        NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);
        testcontroller.opptyValidation();
        testcontroller.redirectToOppotunity(); 
        
        Test.stopTest();
    }
    
    @isTest
    public static void so_status()
    {
        // 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
        Industry_Code__c indCode = TestDataFactory.createIndustryCode();
        insert indCode;
        
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        acc.AdPoint_ID__c = '12345';
        acc.Is_Digital__c = true;
        acc.Industry_Code__c = indCode.Id;
        insert acc;
        
        Account payerAcc = TestDataSetupClass.createAccount();
        RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        payerAcc.RecordTypeId = payerAccrtypes.Id;
        payerAcc.AdPoint_ID__c = '6789';
        payerAcc.Is_Digital__c = true;
        payerAcc.Industry_Code__c = indCode.Id;
        insert payerAcc;
        
        Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                          OpportunityGroup__c = 'NewsXtend',  Payer_Account__c = payerAcc.Id);
        insert opp;
        
        setupProductData();
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(new List<Opportunity>{opp}, products, pricebookEntries, null);
        insert olis;
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'externally approved';
        insert so;
        
        List<csmso__Sales_Order__c> soList = new List<csmso__Sales_Order__c>();
        soList.add(so);
        
        Test.startTest();
        PageReference pageRef = Page.NewSalesOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
        ApexPages.currentPage().getParameters().put('Id',opp.id);
        NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);
        testcontroller.opptyValidation();
        testcontroller.redirectToOppotunity();  
        
        Test.stopTest();
    }
    
    @isTest
    public static void JDE_check()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u2 = new User(Alias = 'newUser', Email='newuser@testorg.com', 
                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, 
                           TimeZoneSidKey='Australia/Sydney', UserName='testuserforcallout@testorg.com',
                           
                           Bypass_Triggers__c = 'AccountManagement;AccountTeam;CaseManagement;OpportunityManagement;SalesOrder_Helper_Trigger');
        insert u2;
        Opportunity opp;
        List<csmso__Sales_Order__c> soList = new List<csmso__Sales_Order__c>();
        System.runAs(u2) {
            
            System.debug('User_JDE_check' + u2.Sales_Team__c);
            
            // 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
            Industry_Code__c indCode = TestDataFactory.createIndustryCode();
            insert indCode;
            
            Account acc = TestDataSetupClass.createAccount();
            RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            acc.RecordTypeId = rtypes.Id;
            acc.AdPoint_ID__c = '12345';
            acc.Is_Digital__c = true;
            acc.Industry_Code__c = indCode.Id;
            insert acc;
            
            Account payerAcc = TestDataSetupClass.createAccount();
            RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            payerAcc.RecordTypeId = payerAccrtypes.Id;
            payerAcc.AdPoint_ID__c = '6789';
            payerAcc.Is_Digital__c = true;
            payerAcc.Industry_Code__c = indCode.Id;
            insert payerAcc;
            
            opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                  OpportunityGroup__c = 'NewsXtend',  Payer_Account__c = payerAcc.Id);
            insert opp;
            
            setupProductData();
            List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(new List<Opportunity>{opp}, products, pricebookEntries, null);
            insert olis;
            csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
            so.csmso__Status__c = 'Draft';
            insert so;
            
            soList.add(so);
        }
        Test.startTest();
        PageReference pageRef = Page.NewSalesOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
        ApexPages.currentPage().getParameters().put('Id',opp.id);
        NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);
        testcontroller.opptyValidation();
        testcontroller.redirectToOppotunity(); 
        
        Test.stopTest();
    }
    
    @isTest
    public static void positive_check()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u3 = new User(Alias = 'newUser', Email='newuser@testorg.com', 
                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, 
                           TimeZoneSidKey='Australia/Sydney', UserName='testuserforcallout@testorg.com',
                           Sales_Team__c = 'QLD Metro',
                           Bypass_Triggers__c = 'AccountManagement;AccountTeam;CaseManagement;OpportunityManagement;SalesOrder_Helper_Trigger');
        insert u3;
        Opportunity opp;
        List<csmso__Sales_Order__c> soList = new List<csmso__Sales_Order__c>();
        System.runAs(u3) {
            
            System.debug('User_JDE_check' + u3.Sales_Team__c);
            
            // 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
            Industry_Code__c indCode = TestDataFactory.createIndustryCode();
            insert indCode;
            
            Account acc = TestDataSetupClass.createAccount();
            RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            acc.RecordTypeId = rtypes.Id;
            acc.AdPoint_ID__c = '12345';
            acc.Is_Digital__c = true;
            acc.Industry_Code__c = indCode.Id;
            insert acc;
            
            Account payerAcc = TestDataSetupClass.createAccount();
            RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            payerAcc.RecordTypeId = payerAccrtypes.Id;
            payerAcc.AdPoint_ID__c = '6789';
            payerAcc.Is_Digital__c = true;
            payerAcc.Industry_Code__c = indCode.Id;
            insert payerAcc;
            
            opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                  OpportunityGroup__c = 'Print',  Payer_Account__c = payerAcc.Id);
            insert opp;
            
            setupProductData();
            List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(new List<Opportunity>{opp}, products, pricebookEntries, null);
            insert olis;
            csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
            so.csmso__Status__c = 'Draft';
            insert so;
            
            
            soList.add(so);
        }
        Test.startTest();
        PageReference pageRef = Page.NewSalesOrder;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
        ApexPages.currentPage().getParameters().put('Id',opp.id);
        NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);
        testcontroller.opptyValidation();
        testcontroller.redirectToOppotunity(); 
        
        Test.stopTest();
    }
}
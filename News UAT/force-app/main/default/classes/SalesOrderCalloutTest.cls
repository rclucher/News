/*
 * 2017-06-15 Existing class
 * 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
 *
 *      This class provides test coverage for
 *          - GBALookupService.cls             100% 
 --------------------------------------------------------- */
@isTest
public class SalesOrderCalloutTest {
    /*@isTest static void testCallout_oppGrp() {              
        // This causes a fake response to be generated
        //Test.setMock(WebServiceMock.class, new SalesOrderCalloutMock());
        // Call the method that invokes a callout
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
        
        csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
        so.csmso__Status__c = 'externally approved';
        insert so;
        
        List<csmso__Sales_Order__c> soList = new List<csmso__Sales_Order__c>();
        soList.add(so);
        Test.startTest();
        	Test.setMock(WebServiceMock.class, new SalesOrderCalloutMock());
            PageReference pageRef = Page.NewSalesOrder;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
            ApexPages.currentPage().getParameters().put('Id',opp.id);
            NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);        
            pagereference result = testcontroller.opptyValidation();
        Test.stopTest();
        
    }
    
    @isTest static void testCallout_AccAdPointID() {              
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new SalesOrderCalloutMock());
        // Call the method that invokes a callout
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
            pagereference result = testcontroller.opptyValidation();
        Test.stopTest();
    }
    
        @isTest static void testCallout_PayerAccAdPointID() {              
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new SalesOrderCalloutMock());
        // Call the method that invokes a callout
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
            pagereference result = testcontroller.opptyValidation();
        Test.stopTest();
    }
    
    @isTest static void testCallout_AccIsDigi() {              
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new SalesOrderCalloutMock());
        // Call the method that invokes a callout
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
            pagereference result = testcontroller.opptyValidation();
        Test.stopTest();
        
    }
    
    @isTest static void testCallout_PayerAccIsDigi() {              
        // This causes a fake response to be generated
        Test.setMock(WebServiceMock.class, new SalesOrderCalloutMock());
        // Call the method that invokes a callout
        Account acc = TestDataSetupClass.createAccount();
        RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
        acc.RecordTypeId = rtypes.Id;
        acc.AdPoint_ID__c = '12345';
        acc.Is_Digital__c = true;
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
            pagereference result = testcontroller.opptyValidation();
        Test.stopTest();
    }*/
    
    @isTest static void testCallout_webService() {              
        // This causes a fake response to be generated
        //Test.setMock(WebServiceMock.class, new SalesOrderCalloutMock());
        // Call the method that invokes a callout
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u2 = new User(Alias = 'newUser', Email='newuser@testorg.com', 
                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, 
                           TimeZoneSidKey='Australia/Sydney', UserName='testuserforcallout@testorg.com',
                           Sales_Team__c = 'QLD Metro',
                           Bypass_Triggers__c = 'AccountManagement;AccountTeam;CaseManagement;OpportunityManagement;SalesOrder_Helper_Trigger');
        System.runAs(u2){
            // 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
            Industry_Code__c indCode = TestDataFactory.createIndustryCode();
            insert indCode;

            Account acc = TestDataSetupClass.createAccount();
            RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            acc.RecordTypeId = rtypes.Id;
            acc.AdPoint_ID__c = '234';
            acc.Is_Digital__c = true;
            acc.Industry_Code__c = indCode.Id;
            insert acc;
            
            Account payerAcc = TestDataSetupClass.createAccount();
            RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            payerAcc.RecordTypeId = payerAccrtypes.Id;
            payerAcc.AdPoint_ID__c = '7010';
            payerAcc.Is_Digital__c = true;
            payerAcc.Industry_Code__c = indCode.Id;
            insert payerAcc;
            
            Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                              OpportunityGroup__c = 'NewsXtend',  Payer_Account__c = payerAcc.Id);
            insert opp;
            
            csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
            so.csmso__Status__c = 'externally approved';
            //insert so;
            
            list<csmso__Sales_Order__c> soList = new list<csmso__Sales_Order__c>();     
            //soList.add(so);
            
            No_Triggers__c setting = new No_Triggers__c();
            setting.SetupOwnerId = UserInfo.getUserId();
            setting.Flag__c = true;
            insert setting;
            
            Test.startTest();
                Test.setMock(WebServiceMock.class, new SalesOrderCalloutMock());
                PageReference pageRef = Page.NewSalesOrder;
                Test.setCurrentPage(pageRef);
                ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
                ApexPages.currentPage().getParameters().put('Id',opp.id);
                NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);
                pagereference result = testcontroller.opptyValidation();
            	testcontroller.responseMapping(opp);
            Test.stopTest();
        }
    }
    
    @isTest static void testCallout_webServiceElse() {              
        // This causes a fake response to be generated
        //Test.setMock(WebServiceMock.class, new SalesOrderCalloutMock());
        // Call the method that invokes a callout
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u2 = new User(Alias = 'newUser', Email='newuser@testorg.com', 
                           EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                           LocaleSidKey='en_US', ProfileId = p.Id, 
                           TimeZoneSidKey='Australia/Sydney', UserName='testuserforcallout@testorg.com',
                           Sales_Team__c = 'QLD Metro',
                           Bypass_Triggers__c = 'AccountManagement;AccountTeam;CaseManagement;OpportunityManagement;SalesOrder_Helper_Trigger');
        System.runAs(u2){
            // 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
            Industry_Code__c indCode = TestDataFactory.createIndustryCode();
            insert indCode;

            Account acc = TestDataSetupClass.createAccount();
            RecordType rtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            acc.RecordTypeId = rtypes.Id;
            acc.AdPoint_ID__c = '234';
            acc.Is_Digital__c = true;
            acc.Industry_Code__c = indCode.Id;
            insert acc;
            
            Account payerAcc = TestDataSetupClass.createAccount();
            RecordType payerAccrtypes = [Select Name, Id From RecordType where sObjectType='Account' and Name = 'Prospecting Account' and isActive=true];
            payerAcc.RecordTypeId = payerAccrtypes.Id;
            payerAcc.AdPoint_ID__c = '7010';
            payerAcc.Is_Digital__c = true;
            payerAcc.Industry_Code__c = indCode.Id;
            insert payerAcc;
            
            Opportunity opp = new Opportunity(name = 'testOpportunityForSalesOrderSupportTest', AccountId = acc.Id, StageName = 'testStage', CloseDate = System.today(),
                                              OpportunityGroup__c = 'NewsXtend',  Payer_Account__c = payerAcc.Id);
            insert opp;
            
            csmso__Sales_Order__c so = TestDataSetupClass.createSalesOrder(acc, opp);
            so.csmso__Status__c = 'externally approved';
            //insert so;
            
            list<csmso__Sales_Order__c> soList = new list<csmso__Sales_Order__c>();     
            //soList.add(so);
            
            No_Triggers__c setting = new No_Triggers__c();
            setting.SetupOwnerId = UserInfo.getUserId();
            setting.Flag__c = true;
            insert setting;
            
            Test.startTest();
                Test.setMock(WebServiceMock.class, new SalesOrderCalloutMock());
                PageReference pageRef = Page.NewSalesOrder;
                Test.setCurrentPage(pageRef);
                ApexPages.StandardSetcontroller sc = new ApexPages.StandardSetcontroller(soList);
                ApexPages.currentPage().getParameters().put('Id',opp.id);
                NewSalesOrderController  testcontroller = new NewSalesOrderController(sc);
                pagereference result = testcontroller.opptyValidation();
            	//testcontroller.responseMapping(opp);
            Test.stopTest();
        }
    }
    
      
}
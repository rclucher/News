/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * this is the test class for walkin forecast UI
 * 28/08/2013  Bohao Chen  Created
 * 2016-01-15  Atul Gupta  Updated
 * 2016-02-17  Atul Gupta  Updated 
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
 *   This class provides test coverage for
 *        - WalkinForecast_ControllerX          86%
 ---------------------------------------------------------*/
 //SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - removed seeAllData from class
@isTest 
private class WalkinForecast_ControllerX_Test 
{
    static testMethod void create() 
    {
        // create two types of users
        // one has Manage All Walk-in checked
        // another has Manage All Walk-in unchecked
         
        List<UserRole> userRoles = [Select Id from UserRole limit 1];
        //List<UserRole> userRoles = TestDataFactory.createUserRoles(10);

        List<User> users = TestDataFactory.createUsers(2, 'News Field Sales Account Manager', userRoles, null, false);
        users[0].Manage_All_Walk_in__c = true;
        users[1].Manage_All_Walk_in__c = false;
        insert users;
        
        
        system.debug('===users== ' + users);
        
        Test.startTest();
        
        system.runAs(users[0])
        {
            PageReference walkInForecastPage = Page.WalkInForecast;
            Test.setCurrentPage(walkInForecastPage);
    
            ApexPages.StandardController ctr = new ApexPages.StandardController(new Opportunity());
            WalkinForecast_ControllerX walkinForecastInstance = new WalkinForecast_ControllerX(ctr);
            
            String reportId = walkinForecastInstance.reportId;
            walkinForecastInstance.refreshYearOptions();
                        
            // validate error message
            walkinForecastInstance.oppt.OwnerId = null;
            walkinForecastInstance.selectedYear = null;
            
            // case 1: no user and no fiscal year
            walkinForecastInstance.quickSave();
            
            List<Apexpages.Message> msgs = ApexPages.getMessages();
            boolean hasMessage = false;
            
            for(Apexpages.Message msg:msgs)
            {
                if (msg.getDetail().contains('Please select User and Period to start'))
                    hasMessage = true;
            }
            
            system.assert(hasMessage);
            
            // case 2: no user but fiscal year
            walkinForecastInstance.selectedYear = '14';
            walkinForecastInstance.oppt.OwnerId = null;
            
            walkinForecastInstance.quickSave();
            
            msgs = ApexPages.getMessages();
            hasMessage = false;
            
            for(Apexpages.Message msg:msgs)
            {
                if (msg.getDetail().contains('Please select User to start'))
                    hasMessage = true;
            }
            
            system.assert(hasMessage);
            
            // case 3: no fiscal year but user year
            walkinForecastInstance.selectedYear = null;
            walkinForecastInstance.oppt.OwnerId =users[0].Id;
            
            walkinForecastInstance.quickSave();
            
            msgs = ApexPages.getMessages();
            hasMessage = false;
            
            for(Apexpages.Message msg:msgs)
            {
                if (msg.getDetail().contains('Please select Period to start'))
                    hasMessage = true;
            }
            
            system.assert(hasMessage);
            
            // save walkin forecast opportunity and line items
                        
            walkinForecastInstance.selectedYear = '14';
            walkinForecastInstance.oppt.OwnerId =users[0].Id;
            
            walkinForecastInstance.refreshWalkinForecastTable();
            
            List<PricebookEntry> prodEntries = walkinForecastInstance.PricebookEntries;
            
            
            Date startDateOfFiscalYear = date.newInstance(2013, 07, 01);
            
            for(WalkinForecast_ControllerX.opportunityWrapper opptyWrapper : walkinForecastInstance.opportunities)
            {
                system.assertEquals(opptyWrapper.weekCommencingDate, startDateOfFiscalYear);
                
                for(PricebookEntry prodEntry : prodEntries)
                {
                    opptyWrapper.opportunityLineItemsByPricebookEntryId.get(prodEntry.Id).Custom_TotalPrice__c = 1000;
                }
                startDateOfFiscalYear = startDateOfFiscalYear.addDays(7);
            }
            

            walkinForecastInstance.quickSave();
            
            walkinForecastInstance.save();
            
            // validate that opportunities have been saved
            String opportunityName = 'Walk-in Forecast-Week-%-FY14';
            
            for(Opportunity oppty : [Select o.Status__c, o.StageName, o.Amount, 
                                    (Select TotalPrice From OpportunityLineItems) 
                                    From Opportunity o 
                                    Where o.Name like: opportunityName
                                    And o.OwnerId =: users[0].Id])
            {
                //Check number of opportunityLineItems returning
                //system.assertEquals(prodEntries.size(), oppty.OpportunityLineItems.size());
                system.assertEquals(1000 * prodEntries.size(), oppty.Amount);
            }
            
            
            walkinForecastInstance.cancel();
            
            walkinForecastInstance.goToReport();
        }    
        
        Test.stopTest();    
    }
    
    //SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - test method to cover reloadOpportunities method
    static testMethod void reloadOpportunitiesTest(){
        
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        for(Account acc : accounts){
            acc.Name = 'News Corp Australia';
        }
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(10);
        for(Product2 pro : products){
            pro.Name = 'Walk-in';
        }
        update products;

        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
        // create opportunities
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,null,accounts[0], contacts[0]);
        for(Opportunity opp : opportunities){
            opp.name = 'Walk-in Forecast-Week-01-FY16';
            opp.recordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Walk-In Forecast').getRecordTypeId();
        }
        insert opportunities;
        
        // create 2 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, salesOrders[0].Id);
        for(OpportunityLineItem oli : olis){
            oli.Custom_TotalPrice__c = 123;
        }
        insert olis;
        
        PageReference walkInForecastPage = Page.WalkInForecast;
        Test.setCurrentPage(walkInForecastPage);

        ApexPages.StandardController ctr = new ApexPages.StandardController(new Opportunity());
        WalkinForecast_ControllerX walkinForecastInstance = new WalkinForecast_ControllerX(ctr);
        
        walkinForecastInstance.retrieveOpportunities();
        walkinForecastInstance.reloadOpportunities();
        walkinForecastInstance.save();
    }
    
    //SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - test method to cover doSave method
    static testMethod void saveTest(){
        
        
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        for(Account acc : accounts){
            acc.Name = 'News Corp Australia';
        }
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(10);

        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
        // create opportunities
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,null,accounts[0], contacts[0]);
        for(Opportunity opp : opportunities){
            opp.name = 'Oppty FY16';
            opp.recordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Walk-In Forecast').getRecordTypeId();
        }
        insert opportunities;
        
        // create 2 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, salesOrders[0].Id);
        insert olis;
        
        PageReference walkInForecastPage = Page.WalkInForecast;
        Test.setCurrentPage(walkInForecastPage);
    
        ApexPages.StandardController ctr = new ApexPages.StandardController(opportunities[0]);//new Opportunity());
        WalkinForecast_ControllerX walkinForecastInstance = new WalkinForecast_ControllerX(ctr);
        
        walkinForecastInstance.retrieveOpportunities();

        walkinForecastInstance.goToReport();
        
        walkinForecastInstance.save();

    }

    //SFE-766 2016-02-15 atul.gupta@bluewolfgroup.com - test method to cover doSave method
    static testMethod void checkOpportunityNullValues(){
        
        Map<Id, OpportunityLineItem> pricebookIdToLineItems = new Map<Id, OpportunityLineItem>();
        
        String walkinRT = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Walk-In Forecast').getRecordTypeId();
        
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        for(Account acc : accounts){
            acc.Name = 'News Corp Australia';
        }
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(10);
        for(Product2 pro : products){
            pro.Name = 'Walk-in ' + pro.Name;
        }
        update products;
        
        Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
        // create opportunities
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,null,accounts[0], contacts[0]);
        for(Opportunity opp : opportunities){
            opp.name = 'Oppty FY16';
            opp.recordtypeId = walkinRT;
        }
        insert opportunities;
        
        // create 2 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, salesOrders[0].Id);
        insert olis;
        
        for(OpportunityLineItem oli : olis){
            pricebookIdToLineItems.put(oli.PricebookEntryId, oli);
        }
        PageReference walkInForecastPage = Page.WalkInForecast;
        Test.setCurrentPage(walkInForecastPage);
        Test.startTest();
        ApexPages.StandardController ctr = new ApexPages.StandardController(opportunities[0]);//new Opportunity());
        WalkinForecast_ControllerX walkinForecastInstance = new WalkinForecast_ControllerX(ctr);
        
        walkinForecastInstance.retrieveOpportunities();
        walkinForecastInstance.reloadOpportunities();
        List<WalkinForecast_ControllerX.opportunityWrapper> oppWrapList = walkinForecastInstance.opportunities;
        system.debug('@@oppWrap : '+ oppWrapList.size());
    
        for(WalkinForecast_ControllerX.opportunityWrapper wrap: oppWrapList){
            if(wrap.weekCommencingDate > system.today()){
                for(Id pbId : pricebookIdToLineItems.keySet()){
                    wrap.opportunityLineItemsByPricebookEntryId.get(pbId).Custom_TotalPrice__c = 45;
                }
            }
        }
        Pagereference p = walkinForecastInstance.save();
       
        List<Opportunity> opplist = [select Id, CloseDate from Opportunity where RecordTypeId =:walkinRT AND CloseDate >=: system.today()];
        system.assertEquals(opplist.size() > 0, true);
        
        for(WalkinForecast_ControllerX.opportunityWrapper wrap: oppWrapList){
            if(wrap.weekCommencingDate > system.today()){
                for(Id pbId : pricebookIdToLineItems.keySet()){
					 wrap.opportunityLineItemsByPricebookEntryId.get(pbId).Custom_TotalPrice__c = 0;
                }
            }
        }
        // commented out to avoid  Too many SQL Queries validation error --//
       // Pagereference p1 = walkinForecastInstance.save();
       
        Test.stopTest();
        
       List<Opportunity> opplist1 = [select Id, CloseDate from Opportunity where RecordTypeId = :walkinRT AND CloseDate >=: system.today()];

        system.assertEquals(opplist1.size() == 0, false);
    }
}
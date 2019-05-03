/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This is test class for OpportunityProductSearch_ControllerX, OpportunityProductSearch_Helper,
                ProductWrapper, OpportunityLineItemWrapper
 * History:
 * 6/06/2013  Bohao Chen  Created
 * 2016-01-15 Atul Gupta  Updated
 * 2016-01-14 atul.gupta@bluewolfgroup.com
 * 2017-04-20 Item-00264 louis.wang@bluewolf.com - Updated to only use standard Pricebook to avoid intermittent Production error.
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    // This class provides test coverage for
    //  - OpportunityLineItemWrapper.cls       86%
    //  - OpportProductSearch_ControllerX.cls  85%
    //  - OpportunityProductSearch_Helper.cls  91%
    //  - ProductWrapper.cls		           100%
 ---------------------------------------------------------*/
@isTest
private class OpportProductSearch_ControllerX_Test 
{
	
	static testMethod void editOpportunityLineItemsTest_For_OpptyLineItem_Helper() 
    {		
        // setup revenue schedule pattern in custom setting
        TestDataFactory.createRevenueSchedulePatterns();

        List<User> users = TestDataFactory.createUsers(1, 'News Field Sales Account Manager', null, null, false);
        insert users;
        
        system.runAs(users[0]) // problem here
        {
            // create account
            List<Account> accts = TestDataFactory.createAccounts(1, false);
            insert accts;
            
            // create contact
            List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
            insert contacts;

            // create products
            List<Product2> products = TestDataFactory.createProducts(20);
            Id stdPricebookId = Test.getStandardPricebookId();
            List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, products);
            List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, stdPricebookId, accts[0], contacts[0]);
            insert opportunities;

            // Case 1: no opportunity item associates with opportunity
            // this should redirect user to product search page
            PageReference OpportunityRevenueScheduleEditPage = Page.OpportunityProductRevenueSchedule;
            OpportunityRevenueScheduleEditPage.getParameters().put('retURL', opportunities[0].Id);
            OpportunityRevenueScheduleEditPage.getParameters().put('oppId', opportunities[0].Id);
            OpportunityRevenueScheduleEditPage.getParameters().put('oppName', opportunities[0].Name);
            OpportunityRevenueScheduleEditPage.getParameters().put('mode', 'edit');
            Test.setCurrentPage(OpportunityRevenueScheduleEditPage);
            
            ApexPages.StandardController ctr = new ApexPages.StandardController(new OpportunityLineItem());
            OpportunityProductSearch_ControllerX opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            
            PageReference productSearchPage = opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            productSearchPage.getURL().equals('/apex/OpportunityProductSearch?=oppId' + opportunities[0].Id +
                 '&oppName=' + opportunities[0].Name + '&retURL=' + opportunities[0].Id); // check redirect url
            
            // Case 2: all products are added to this opportunity
            // In order to test edit function, firstly we have to create opportunity line items and opportunity line item schedules
            Test.setCurrentPage(productSearchPage);
            
            ctr = new ApexPages.StandardController(new OpportunityLineItem());
            opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            
            for(ProductWrapper p : opportunityProductSearchCtr.productSearchResultsList)
            {
                p.isSelect = true;  
            }
            
            PageReference revenueSchedulePage = opportunityProductSearchCtr.selectBtn();
            Test.setCurrentPage(revenueSchedulePage);
            
            opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            // check number of opportunity line item for this opportunity
            system.assertEquals(20, opportunityProductSearchCtr.opportunityLineItemsList.size());
            
            // check default values have been populated correctly
            for(OpportunityLineItemWrapper p : opportunityProductSearchCtr.opportunityLineItemsList)
            {
                system.debug('@@line Items : '+p.opportunityLineItem);
                p.opportunityLineItem.UnitPrice = 3000;
            }

        	Test.startTest();
            Boolean boolVal = opportunityProductSearchCtr.doSave();
            Test.stopTest();
            //Test.setCurrentPage(productSearchPage);
        	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        	
        	for(ApexPages.Message message : pageMessages) {
        		system.debug('@@summary : '+message.getSummary());
			}
        }
    }
    
    //atul
    //test method to test if opportunitylineitem values are null
	static testMethod void editOpportunityLineItemsTest_For_Null_Values() 
    {		
        // setup revenue schedule pattern in custom setting
        TestDataFactory.createRevenueSchedulePatterns();

        List<User> users = TestDataFactory.createUsers(1, 'News Field Sales Account Manager', null, null, false);
        insert users;
        
        system.runAs(users[0]) // problem here
        {
            // create account
            List<Account> accts = TestDataFactory.createAccounts(1, false);
            insert accts;
            
            // create contact
            List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
            insert contacts;

            // create products
            List<Product2> products = TestDataFactory.createProducts(20);
            Id stdPricebookId = Test.getStandardPricebookId();
            List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, products);
            List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, stdPricebookId, accts[0], contacts[0]);
            insert opportunities;

            // Case 1: no opportunity item associates with opportunity
            // this should redirect user to product search page
            PageReference OpportunityRevenueScheduleEditPage = Page.OpportunityProductRevenueSchedule;
            OpportunityRevenueScheduleEditPage.getParameters().put('retURL', opportunities[0].Id);
            OpportunityRevenueScheduleEditPage.getParameters().put('oppId', opportunities[0].Id);
            OpportunityRevenueScheduleEditPage.getParameters().put('oppName', opportunities[0].Name);
            OpportunityRevenueScheduleEditPage.getParameters().put('mode', 'edit');
            Test.setCurrentPage(OpportunityRevenueScheduleEditPage);
            
            ApexPages.StandardController ctr = new ApexPages.StandardController(new OpportunityLineItem());
            OpportunityProductSearch_ControllerX opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            
            PageReference productSearchPage = opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            productSearchPage.getURL().equals('/apex/OpportunityProductSearch?=oppId' + opportunities[0].Id +
                 '&oppName=' + opportunities[0].Name + '&retURL=' + opportunities[0].Id); // check redirect url
            
            // Case 2: all products are added to this opportunity
            // In order to test edit function, firstly we have to create opportunity line items and opportunity line item schedules
            Test.setCurrentPage(productSearchPage);
            
            ctr = new ApexPages.StandardController(new OpportunityLineItem());
            opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            
            for(ProductWrapper p : opportunityProductSearchCtr.productSearchResultsList)
            {
                p.isSelect = true;  
            }
            
            PageReference revenueSchedulePage = opportunityProductSearchCtr.selectBtn();
            Test.setCurrentPage(revenueSchedulePage);
            
            opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            // check number of opportunity line item for this opportunity
            system.assertEquals(20, opportunityProductSearchCtr.opportunityLineItemsList.size());
            
            // check default values have been populated correctly
            for(OpportunityLineItemWrapper p : opportunityProductSearchCtr.opportunityLineItemsList)
            {
                p.opportunityLineItem.UnitPrice = 3000;
                p.opportunityLineItem.of_Periods__c = null;
                p.opportunityLineItem.Period__c = null;
                p.opportunityLineItem.ServiceDate = null;
                p.opportunityLineItem.Pattern__c = null;
            }
            
            
        	Test.startTest();
            productSearchPage = opportunityProductSearchCtr.saveBtn();
            Test.stopTest();
            //Test.setCurrentPage(productSearchPage);
        	ApexPages.Message[] pageMessages = ApexPages.getMessages();
        	
        	for(ApexPages.Message message : pageMessages) {
        		system.assertEquals(message.getSummary(), 'This field is required');
			}
        }
    }
    
    
    /**** BEGIN: product search page / function tests ****/
    //atul
    static testMethod void productSearchTest() 
    {
        List<User> users = TestDataFactory.createUsers(1, 'News Field Sales Account Manager', null, null, false);
        insert users;
        
        system.runAs(users[0]) // problem here
        {
            // create account
            List<Account> accts = TestDataFactory.createAccounts(1, false);
            insert accts;
            
            // create contact
            List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
            insert contacts;

            // create products
            List<Product2> products = TestDataFactory.createProducts(10);
            Id stdPricebookId = Test.getStandardPricebookId();
            List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, products);
            List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, stdPricebookId, accts[0], contacts[0]);
            insert opportunities;
            
            // create product mappings
            // testing publications one
            List<String> publications = TestDataFactory.createStringList(20, 'pub');
        
            // testing publication codes
            List<String> publicationCodes = TestDataFactory.createStringList(20, 'pubC');
        
            // testing ad types
            List<String> adTypes = TestDataFactory.createStringList(20, 'adType');
             
            //List<Publication_Product__c> publicationProducts = TestDataFactory.createPublicationProducts(publications, adTypes, products, publicationCodes);
            List<Publication_Product__c> publicationProducts = TestDataFactory.createPublicationProducts(products, publications, publicationCodes, adTypes);
            insert publicationProducts;
            
            Test.startTest();
        
            PageReference productSearchPage = Page.OpportunityProductSearch;
            productSearchPage.getParameters().put('retURL', opportunities[0].Id);
            productSearchPage.getParameters().put('oppId', opportunities[0].Id);
            productSearchPage.getParameters().put('oppName', opportunities[0].Name);
            Test.setCurrentPage(productSearchPage);
            
            ApexPages.StandardController ctr = new ApexPages.StandardController(new OpportunityLineItem());
            OpportunityProductSearch_ControllerX opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            
            // load criteria filters for this page
            List<SelectOption> familyOptions = opportunityProductSearchCtr.familySelectOptions;
            List<SelectOption> categoryOptions = opportunityProductSearchCtr.categorySelectOptions;
            List<SelectOption> regionOptions = opportunityProductSearchCtr.regionSelectOptions;
            
            
            // we should expect load 100 products when page first load
            system.assertEquals(10, opportunityProductSearchCtr.productSearchResultsList.size()); 
            
            opportunityProductSearchCtr.searchBtn(); // search without criterion
            system.assertEquals(10, opportunityProductSearchCtr.productSearchResultsList.size()); 
            
            opportunityProductSearchCtr.keyword = 'pub';
            opportunityProductSearchCtr.searchBtn(); // search keyword 'pub'
            system.assertEquals(10, opportunityProductSearchCtr.productSearchResultsList.size()); 
            
            opportunityProductSearchCtr.keyword = 'Test';
            opportunityProductSearchCtr.searchBtn(); // search keyword 'Test'
            system.assertEquals(10, opportunityProductSearchCtr.productSearchResultsList.size()); 
            
            opportunityProductSearchCtr.keyword = '1';
            opportunityProductSearchCtr.searchBtn(); // search keyword '1'
            system.assertEquals(10, opportunityProductSearchCtr.productSearchResultsList.size()); 
            
            opportunityProductSearchCtr.keyword = null;
            opportunityProductSearchCtr.productFamily = get_NewProductFamily();
            opportunityProductSearchCtr.searchBtn();
            system.assertEquals(1, opportunityProductSearchCtr.productSearchResultsList.size()); 
            
            opportunityProductSearchCtr.productFamily = null;
            opportunityProductSearchCtr.productCategory = 'Category 1';  
            opportunityProductSearchCtr.searchBtn();
            system.assertEquals(1, opportunityProductSearchCtr.productSearchResultsList.size()); 
            
            opportunityProductSearchCtr.productCategory = null;
            opportunityProductSearchCtr.productRegion = 'Region 1';
            opportunityProductSearchCtr.searchBtn();
            system.assertEquals(1, opportunityProductSearchCtr.productSearchResultsList.size()); 
            
            opportunityProductSearchCtr.keyword = 'Test';
            opportunityProductSearchCtr.productFamily = get_NewProductFamily();
            opportunityProductSearchCtr.productCategory = 'Category 1';  
            opportunityProductSearchCtr.productRegion = 'Region 1';
            opportunityProductSearchCtr.searchBtn();
            system.assertEquals(1, opportunityProductSearchCtr.productSearchResultsList.size()); 
            Test.stopTest();
        }
    }

    static String get_NewProductFamily()
    {
		
        // 2015-11-23 SFE-766 louis.wang@bluewolf.com
        //   - Product2.Exernal_Id__c (workflow) is now unique, through TestDataFactory.createProducts()
        //   - To achieve the above, ProductFamily is added with a random number string. 
        //   - This function fetches the full name of ProductFamily for this test class to assert correctly.
        String output = '';
        List<Product2> prodList = [SELECT Id, Family 
                                    FROM Product2 
                                    WHERE Family LIKE 'Family 1%' 
                                    ORDER BY Family];
        if(!prodList.isEmpty())
        {
            output = prodList[0].Family;
        }
        return output;
    }
    
    static testMethod void productSelectTest() 
    {
        List<User> users = TestDataFactory.createUsers(1, 'News Field Sales Account Manager', null, null, false);
        insert users;
        
        system.runAs(users[0])
        {
            // create account
            List<Account> accts = TestDataFactory.createAccounts(1, false);
            insert accts;
            
            // create contact
            List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
            insert contacts;

            // create products
            List<Product2> products = TestDataFactory.createProducts(20);
            Id stdPricebookId = Test.getStandardPricebookId();
            List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, products);
            List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, stdPricebookId, accts[0], contacts[0]);
            insert opportunities;
            
            Test.startTest();
        
            PageReference productSearchPage = Page.OpportunityProductSearch;
            productSearchPage.getParameters().put('retURL', opportunities[0].Id);
            productSearchPage.getParameters().put('oppId', opportunities[0].Id);
            productSearchPage.getParameters().put('oppName', opportunities[0].Name);
            Test.setCurrentPage(productSearchPage);
            
            ApexPages.StandardController ctr = new ApexPages.StandardController(new OpportunityLineItem());
            OpportunityProductSearch_ControllerX opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            
            // Case 1 : no product has been selected
            system.assertEquals(null, opportunityProductSearchCtr.selectBtn()); 
            
            // Case 2 : select all products
            for(ProductWrapper p : opportunityProductSearchCtr.productSearchResultsList)
            {
                p.isSelect = true;  
            }
            
            PageReference revenueSchedulePage = opportunityProductSearchCtr.selectBtn();
            PageReference testUrl = Page.OpportunityProductRevenueSchedule;
            system.assertEquals(revenueSchedulePage.getURL(), testUrl.getURL());
            Test.stopTest(); 
        }
    }
    
    /***** END: product search page / function tests ****/
    
    /**** BEGIN: revenue schedule page / function tests ****/
    //
    static testMethod void createOpportunityLineItemsAndScheduleItemsTest() 
    {
        // setup revenue schedule pattern in custom setting
        TestDataFactory.createRevenueSchedulePatterns();

        List<User> users = TestDataFactory.createUsers(1, 'News Field Sales Account Manager', null, null, false);
        insert users;
        
        system.runAs(users[0]) // problem here
        {
            // create account
            List<Account> accts = TestDataFactory.createAccounts(1, false);
            insert accts;
            
            // create contact
            List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
            insert contacts;

            // create products
            List<Product2> products = TestDataFactory.createProducts(50);
            Id stdPricebookId = Test.getStandardPricebookId();
            List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, products);
            List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, stdPricebookId, accts[0], contacts[0]);
            insert opportunities;
            
            Test.startTest();
        
            // go to product search, we select all products. firstly, we test save&more button
            PageReference productSearchPage = Page.OpportunityProductSearch;
            productSearchPage.getParameters().put('retURL', opportunities[0].Id);
            productSearchPage.getParameters().put('oppId', opportunities[0].Id);
            productSearchPage.getParameters().put('oppName', opportunities[0].Name);
            Test.setCurrentPage(productSearchPage);
            
            ApexPages.StandardController ctr = new ApexPages.StandardController(new OpportunityLineItem());
            OpportunityProductSearch_ControllerX opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            
            for(ProductWrapper p : opportunityProductSearchCtr.productSearchResultsList)
            {
                p.isSelect = true;  
            }
            
            PageReference revenueSchedulePage = opportunityProductSearchCtr.selectBtn();
            Test.setCurrentPage(revenueSchedulePage);
            
            opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            // check number of opportunity line item for this opportunity
            system.assertEquals(50, opportunityProductSearchCtr.opportunityLineItemsList.size());
            
            // check default values have been populated correctly
            for(OpportunityLineItemWrapper p : opportunityProductSearchCtr.opportunityLineItemsList)
            {
                //system.assertEquals(date.today().addMonths(1), p.opportunityLineItem.ServiceDate); // check date
                system.assertEquals(1, p.opportunityLineItem.of_Periods__c);// check number of period
                system.assertEquals('Week(s)', p.opportunityLineItem.Period__c);// check period
                system.assertEquals('Weekly', p.opportunityLineItem.Pattern__c);// check pattern
                p.opportunityLineItem.UnitPrice = 3000;
            }
            
            productSearchPage = opportunityProductSearchCtr.saveAndMoreBtn();
            

                Test.setCurrentPage(productSearchPage);
                
                productSearchPage.getURL().equals('/apex/OpportunityProductSearch?=oppId' + opportunities[0].Id +
                     '&oppName=' + opportunities[0].Name + '&retURL=' + opportunities[0].Id); // check redirect url after hitting save and more button
                
                // check number of OpportunityLineItemSchedules have been created correctly
                Integer numOfOpportunityLineItemSchedules = [Select count() From OpportunityLineItemSchedule o
                                                             Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id];
                
                system.assertEquals(50, numOfOpportunityLineItemSchedules);
                
                
                // after redirecting to product search, we select all products again. But this time, we hit save button
                for(ProductWrapper p : opportunityProductSearchCtr.productSearchResultsList)
                {
                    p.isSelect = true;  
                }
                
                revenueSchedulePage = opportunityProductSearchCtr.selectBtn();
                Test.setCurrentPage(revenueSchedulePage);
                
                opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
                // check number of opportunity line item for this opportunity
                system.assertEquals(100, opportunityProductSearchCtr.opportunityLineItemsList.size());
                
                // check default values have been populated correctly
                for(OpportunityLineItemWrapper p : opportunityProductSearchCtr.opportunityLineItemsList)
                {
                    //system.assertEquals(date.today().addMonths(1), p.opportunityLineItem.ServiceDate); // check date
                    system.assertEquals(1, p.opportunityLineItem.of_Periods__c);// check number of period
                    system.assertEquals('Week(s)', p.opportunityLineItem.Period__c);// check period
                    system.assertEquals('Weekly', p.opportunityLineItem.Pattern__c);// check pattern
                    p.opportunityLineItem.UnitPrice = 3000;
                }
                
                
                PageReference opportunityDetailPage =  opportunityProductSearchCtr.saveBtn();
                Test.setCurrentPage(opportunityDetailPage);
                
                productSearchPage.getURL().equals('/' + opportunities[0].Id); // check redirect url after hitting save button
                
                // check number of OpportunityLineItemSchedules have been created correctly
                numOfOpportunityLineItemSchedules = [Select count() From OpportunityLineItemSchedule o
                                                     Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id];
                
                system.assertEquals(100, numOfOpportunityLineItemSchedules);

            
            Test.stopTest(); 
        }
    }
    
    static testMethod void editOpportunityLineItemsAndScheduleItemsTest() 
    {
        // setup revenue schedule pattern in custom setting
        TestDataFactory.createRevenueSchedulePatterns();

        List<User> users = TestDataFactory.createUsers(1, 'News Field Sales Account Manager', null, null, false);
        insert users;
        
        system.runAs(users[0]) // problem here
        {
            // create account
            List<Account> accts = TestDataFactory.createAccounts(1, false);
            insert accts;
            
            // create contact
            List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
            insert contacts;

            // create products
            List<Product2> products = TestDataFactory.createProducts(20);
            Id stdPricebookId = Test.getStandardPricebookId();
            List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, products);
            List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, stdPricebookId, accts[0], contacts[0]);
            insert opportunities;

            // Case 1: no opportunity item associates with opportunity
            // this should redirect user to product search page
            PageReference OpportunityRevenueScheduleEditPage = Page.OpportunityProductRevenueSchedule;
            OpportunityRevenueScheduleEditPage.getParameters().put('retURL', opportunities[0].Id);
            OpportunityRevenueScheduleEditPage.getParameters().put('oppId', opportunities[0].Id);
            OpportunityRevenueScheduleEditPage.getParameters().put('oppName', opportunities[0].Name);
            OpportunityRevenueScheduleEditPage.getParameters().put('mode', 'edit');
            Test.setCurrentPage(OpportunityRevenueScheduleEditPage);
            
            ApexPages.StandardController ctr = new ApexPages.StandardController(new OpportunityLineItem());
            OpportunityProductSearch_ControllerX opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            
            PageReference productSearchPage = opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            productSearchPage.getURL().equals('/apex/OpportunityProductSearch?=oppId' + opportunities[0].Id +
                 '&oppName=' + opportunities[0].Name + '&retURL=' + opportunities[0].Id); // check redirect url
            
            // Case 2: all products are added to this opportunity
            // In order to test edit function, firstly we have to create opportunity line items and opportunity line item schedules
            Test.setCurrentPage(productSearchPage);
            
            ctr = new ApexPages.StandardController(new OpportunityLineItem());
            opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            
            for(ProductWrapper p : opportunityProductSearchCtr.productSearchResultsList)
            {
                p.isSelect = true;  
            }
            
            PageReference revenueSchedulePage = opportunityProductSearchCtr.selectBtn();
            Test.setCurrentPage(revenueSchedulePage);
            
            opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            // check number of opportunity line item for this opportunity
            system.assertEquals(20, opportunityProductSearchCtr.opportunityLineItemsList.size());
            
            // check default values have been populated correctly
            for(OpportunityLineItemWrapper p : opportunityProductSearchCtr.opportunityLineItemsList)
            {
                //system.assertEquals(date.today().addMonths(1), p.opportunityLineItem.ServiceDate); // check date
                system.assertEquals(1, p.opportunityLineItem.of_Periods__c);// check number of period
                system.assertEquals('Week(s)', p.opportunityLineItem.Period__c);// check period
                system.assertEquals('Weekly', p.opportunityLineItem.Pattern__c);// check pattern
                p.opportunityLineItem.UnitPrice = 3000;
            }
            
            productSearchPage = opportunityProductSearchCtr.saveBtn();
            Test.setCurrentPage(productSearchPage);
            
            // check number of OpportunityLineItemSchedules have been created correctly
            Integer numOfOpportunityLineItemSchedules = [Select count() From OpportunityLineItemSchedule o
                                                         Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id];

            system.assertEquals(20, numOfOpportunityLineItemSchedules);
            
            // Next, we simulate hitting edit all custom button on opportunity detail page to go to OpportunityProductRevenueSchedule page            
            OpportunityRevenueScheduleEditPage = Page.OpportunityProductRevenueSchedule;
            productSearchPage.getParameters().put('retURL', opportunities[0].Id);
            productSearchPage.getParameters().put('oppId', opportunities[0].Id);
            productSearchPage.getParameters().put('oppName', opportunities[0].Name);
            productSearchPage.getParameters().put('mode', 'edit');
            
            opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            system.assertEquals(20, opportunityProductSearchCtr.opportunityLineItemsList.size());

            // Case 1 : duration is 4, period is week(s), pattern is weekly
            for(OpportunityLineItemWrapper p : opportunityProductSearchCtr.opportunityLineItemsList)
            {
                p.opportunityLineItem.of_Periods__c = 4;
                p.opportunityLineItem.Period__c = 'Week(s)';
                p.opportunityLineItem.Pattern__c = 'Weekly';
                p.opportunityLineItem.UnitPrice = 3000;
            }
            
            opportunityProductSearchCtr.saveBtn();
            
            // check number of opportunity line item schedules
            numOfOpportunityLineItemSchedules = [Select count() From OpportunityLineItemSchedule o
                                                         Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id];
            
            system.assertEquals(80, numOfOpportunityLineItemSchedules); // 4 schedule items for each opportunity line item
            
            Test.startTest();
            
            Integer index = 0;
            Id prevOpportunityLineItemId;
            for(OpportunityLineItemSchedule o :[Select o.Type, o.ScheduleDate, o.Revenue, o.OpportunityLineItemId
                                                From OpportunityLineItemSchedule o
                                                Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id
                                                Order By o.OpportunityLineItemId, o.ScheduleDate ASC])
            {
                if(prevOpportunityLineItemId == null || prevOpportunityLineItemId != o.OpportunityLineItemId)
                    index = 0;
                
                system.assertEquals(750, o.Revenue);                
                system.assertEquals('Revenue', o.Type);
                system.assertEquals(opportunities[0].Campaign_Start_Date__c.addDays(7 * index), o.ScheduleDate);
                
                index++;
                prevOpportunityLineItemId = o.OpportunityLineItemId;
            }
            
            // Case 2 : duration is 4, period is week(s), pattern is Every 2 weeks
            opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            system.assertEquals(20, opportunityProductSearchCtr.opportunityLineItemsList.size());
            
            for(OpportunityLineItemWrapper p : opportunityProductSearchCtr.opportunityLineItemsList)
            {
                p.opportunityLineItem.of_Periods__c = 4;
                p.opportunityLineItem.Period__c = 'Week(s)';
                p.opportunityLineItem.Pattern__c = 'Every 2 Weeks';
            }
            
            opportunityProductSearchCtr.saveBtn();
            
            // check number of opportunity line item schedules
            numOfOpportunityLineItemSchedules = [Select count() From OpportunityLineItemSchedule o
                                                         Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id];
            
            system.assertEquals(40, numOfOpportunityLineItemSchedules); // 4 schedule items for each opportunity line item
            
            for(OpportunityLineItemSchedule o :[Select o.Type, o.ScheduleDate, o.Revenue, o.OpportunityLineItemId
                                                From OpportunityLineItemSchedule o
                                                Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id
                                                Order By o.OpportunityLineItemId, o.ScheduleDate ASC])
            {
                if(prevOpportunityLineItemId == null || o.OpportunityLineItemId != prevOpportunityLineItemId)
                    index = 0;
                
                system.assertEquals(1500, o.Revenue);
                system.assertEquals('Revenue', o.Type);
                system.assertEquals(opportunities[0].Campaign_Start_Date__c.addDays(7 * 2 * index), o.ScheduleDate);
                
                index++;     
                prevOpportunityLineItemId = o.OpportunityLineItemId;       
            }
            
            // Case 3 : duration is 8, period is week(s), pattern is monthly
            opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            system.assertEquals(20, opportunityProductSearchCtr.opportunityLineItemsList.size());
            
            for(OpportunityLineItemWrapper p : opportunityProductSearchCtr.opportunityLineItemsList)
            {
                p.opportunityLineItem.of_Periods__c = 8;
                p.opportunityLineItem.Period__c = 'Week(s)';
                p.opportunityLineItem.Pattern__c = 'Monthly';
            }
            
            opportunityProductSearchCtr.saveBtn();
            
            // check number of opportunity line item schedules
            numOfOpportunityLineItemSchedules = [Select count() From OpportunityLineItemSchedule o
                                                         Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id];
            
            system.assertEquals(40, numOfOpportunityLineItemSchedules); // 4 schedule items for each opportunity line item
            
            for(OpportunityLineItemSchedule o :[Select o.Type, o.ScheduleDate, o.Revenue, o.OpportunityLineItemId
                                                From OpportunityLineItemSchedule o
                                                Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id
                                                Order By o.OpportunityLineItemId, o.ScheduleDate ASC])
            {
                if(prevOpportunityLineItemId == null || o.OpportunityLineItemId != prevOpportunityLineItemId)
                    index = 0;
                
                system.assertEquals(1500, o.Revenue);
                system.assertEquals('Revenue', o.Type);
                system.assertEquals(opportunities[0].Campaign_Start_Date__c.addMonths(index), o.ScheduleDate);
                
                index++;
                prevOpportunityLineItemId = o.OpportunityLineItemId;
            }
            
            // Case 4 : duration is 2, period is month(s), pattern is Monthly 
            opportunityProductSearchCtr = new OpportunityProductSearch_ControllerX(ctr);
            opportunityProductSearchCtr.createSelectedOpportunityLineItems();
            
            system.assertEquals(20, opportunityProductSearchCtr.opportunityLineItemsList.size());
            
            for(OpportunityLineItemWrapper p : opportunityProductSearchCtr.opportunityLineItemsList)
            {
                p.opportunityLineItem.of_Periods__c = 2;
                p.opportunityLineItem.Period__c = 'month(s)';
                p.opportunityLineItem.Pattern__c = 'Monthly';
            }
            
            opportunityProductSearchCtr.saveBtn();
            
            // check number of opportunity line item schedules
            numOfOpportunityLineItemSchedules = [Select count() From OpportunityLineItemSchedule o
                                                         Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id];
            
            system.assertEquals(40, numOfOpportunityLineItemSchedules); // 4 schedule items for each opportunity line item
            
            for(OpportunityLineItemSchedule o :[Select o.Type, o.ScheduleDate, o.Revenue, o.OpportunityLineItemId
                                                From OpportunityLineItemSchedule o
                                                Where o.OpportunityLineItem.OpportunityId =: opportunities[0].Id
                                                Order By o.OpportunityLineItemId, o.ScheduleDate ASC])
            {
                if(prevOpportunityLineItemId == null || o.OpportunityLineItemId != prevOpportunityLineItemId)
                    index = 0;
                
                system.assertEquals(1500, o.Revenue);
                system.assertEquals('Revenue', o.Type);
                system.assertEquals(opportunities[0].Campaign_Start_Date__c.addMonths(index), o.ScheduleDate);
                
                index++;
                prevOpportunityLineItemId = o.OpportunityLineItemId;
          
            }
            
            // clone selected opportunitylineitems
            for(OpportunityLineItemWrapper p : opportunityProductSearchCtr.opportunityLineItemsList)
            {
                p.isSelect = true;
            }

            opportunityProductSearchCtr.cloneProducts();

            system.assertEquals(40, opportunityProductSearchCtr.opportunityLineItemsList.size());
            
            Test.stopTest();
        } 
    }
    /**** END: revenue schedule page / function tests ****/
	
}
/*
    // 2015-12-03 darshan.gosar@bluewolfgroup.com 
        // This class provides test coverage for
        //  - Opportunity_Helper                     84% 
        //  - OpportunityLineItemManagement.trigger  78%        
*/
@isTest
private class Opportunity_Helper_Test 
{
    @isTest
    static void test_method_one() 
    {
        // create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;

        // SFE-766 2015-12-03 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition & also created dummy product for OpportunityLineItem Trigger part
        // create products
        List<Product2> products = TestDataFactory.createProducts(5);
        List<Pricebook2> pricebooks  = TestDataFactory.createCustomPricebookData();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData (pricebooks[0], products);
   

        List<Product2> dummyProducts = TestDataFactory.createProducts(1);
        Product2 prod = dummyProducts[0];
        prod.Name = 'Dummy';
        update prod;
        TestDataFactory.createPricebookEntryData(pricebooks[0], dummyProducts);
                    
        // create 2 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(2, accounts[0], accounts[0], accounts[0], contacts[0], 'OSCA');
        insert salesOrders;

        // create map 
        Map<Id, Sales_Order__c> salesOrderById = new Map<Id, Sales_Order__c>();
        for (Sales_Order__c so : salesOrders)
        {
            salesOrderById.put(so.Id,so);
        }

        /*** BEGIN : TEST ***/  
        Test.startTest();
        
        Sales_Order__c salesOrderOSCA = TestDataFactory.createSalesOrder('OSCA');
        Opportunity_Helper.createOpportunitFromSalesOrder(salesOrderById);
        
        Test.stopTest();
        /*** END : TEST ***/
    }

    //@isTest static void test_createCreditCheckCase() {
    //    // create account
    //    List<Account> accounts = TestDataFactory.createAccounts(1, false);
    //    insert accounts;
        
    //    // create contact
    //    List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
    //    insert contacts;

    //    Test.startTest();

    //    Opportunity opp = new Opportunity();
    //    opp.Name = ' Sample: ' + Date.today();
    //    opp.AccountId = accounts[0].Id;
    //    opp.RecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('SME').getRecordTypeId();
    //    opp.StageName = 'Discover Needs';
    //    opp.CloseDate = Date.today() + 14;

    //    insert opp;

    //    Test.stopTest();
    //}
}
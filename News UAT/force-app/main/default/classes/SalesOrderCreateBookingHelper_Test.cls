/*---------------------------------------------------------
* Author:        Stuart Hamilton
* Company:       Salesforce.com
* Description:   Create & link Sales Orders & Opportunities
* Test for:      SalesOrderCreateBooking_Helper
* History 
* 14/06/2013     Stuart Hamilton Created
* 2015-12-24	   Atul Gupta      Updated
* 2016-01-14 atul.gupta@bluewolfgroup.com
* 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
*    This class provides test coverage for
*       - SalesOrderCreateBooking_Helper  74%
* Date : 2018-04-02 LA
* Changes made: Asserts outside test.startTest and test.stopTest
		SalesOrderCreateBooking_Helper  86%
---------------------------------------------------------*/
@isTest
private class SalesOrderCreateBookingHelper_Test {
	
    static Industry_Code__c industryCode;
    static List<Account> accounts;
    static List<Contact> contacts;
    static List<Sales_Order__c> salesOrders;
    static List<Product2> products;
    static List<Pricebook2> priceBookList;
    static List<PricebookEntry> pricebookEntries;
    static List<Opportunity> opportunities;
    static List<Sales_Order__c> sOrderList;
	
	static void testDataSetupMethod(){
		//create Industry Codes
		industryCode = TestDataFactory.createIndustryCode();
		insert industryCode;
		
        // create account
        accounts = TestDataFactory.createAccounts(1, false);
		for(Account acc : accounts){
			acc.Industry_Code__c = industryCode.id;
		}
        insert accounts;
		
		// create contact
         contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
		
        // create sales orders
        salesOrders = TestDataFactory.createSalesOrders(5, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
		
        products = TestDataFactory.createProducts(3, 'Test');
        		
        priceBookList = TestDataFactory.createCustomPricebookData_Standard();

         pricebookEntries = TestDataFactory.createPricebookEntryDataNew(products, priceBookList[0]);
            
        // create test opportunities
        opportunities = TestDataFactory.createOpportunities_withContact(1, null/*stdPricebookId*/, accounts[0], contacts[0]);
		for(Opportunity opp : opportunities){
			opp.Competitor__c = 'Cinema';
		}
        insert opportunities;

		SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper wrapper = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(opportunities[0]);
		
        sOrderList = TestDataFactory.createSalesOrders(1, null, accounts[0], null, contacts[0], 'AdPoint');
		insert sOrderList;
	}
    
    static void testDataSetupmethodForDummyOppItem(){
        
        
		//create Industry Codes
		industryCode = TestDataFactory.createIndustryCode();
		insert industryCode;
		
        // create account
        accounts = TestDataFactory.createAccounts(1, false);
		for(Account acc : accounts){
			acc.Industry_Code__c = industryCode.id;
		}
        insert accounts;
		
		// create contact
         contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
		
        // create sales orders
        salesOrders = TestDataFactory.createSalesOrders(5, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
		
         products = TestDataFactory.createProducts(3, 'Test');
        integer i =0;
		for(Product2 prod : products){
			prod.Name = 'Dummy';
			prod.isActive = false;
            if(i == products.size() -1)
                prod.isActive = false;
		}
        
        update products;
		
        priceBookList = TestDataFactory.createCustomPricebookData_Standard();

         pricebookEntries = TestDataFactory.createPricebookEntryDataNew(products, priceBookList[0]);
            
        // create test opportunities
        opportunities = TestDataFactory.createOpportunities_withContact(1, null/*stdPricebookId*/, accounts[0], contacts[0]);
		for(Opportunity opp : opportunities){
			opp.Competitor__c = 'Cinema';
		}
        insert opportunities;

		SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper wrapper = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(opportunities[0]);
		
        sOrderList = TestDataFactory.createSalesOrders(1, null, accounts[0], null, contacts[0], 'AdPoint');
		insert sOrderList;
    }
    
    static testMethod void testSetOpportunityItem() {
        
		testDataSetupmethod();        
        
        List<OpportunityLineItem> opportunityLineItems = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, null);
        insert opportunityLineItems;
        
        Set<Id> opptyLineItemSet = new Set<Id>();
        if(!opptyLineItemSet.isEmpty()){
	        for(OpportunityLineItem lineItem : opportunityLineItems){
	        	opptyLineItemSet.add(lineItem.Id);
	        }
        }
                
        //create case record
		String caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
        Case caseRec = TestDataFactory.createSingleCase(caseRT, accounts[0].Id);
        insert caseRec;
        
        Campaign campaign = TestDataFactory.createCampaigns(1).get(0);
        insert campaign;
        
        List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(5, contacts, campaign);
        insert campaignMembers;
        
        Sales_Order__c sOrder = TestDataFactory.createSalesOrder('AdPoint');
        
        Test.StartTest();
        SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper wrapperSOrder = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(sOrder);
        SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper wrapperOpp = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(opportunities[0]);
        SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper wrapperCase = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(caseRec);
        SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper wrapperAccount = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(accounts[0]);
        
        SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper wrapperCampaign = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(campaignMembers[0]);
        
        Test.StopTest();
        system.assertEquals(true, wrapperSOrder.salesOrder != null);
        system.assertEquals(true, wrapperOpp.oppty != null);
        system.assertEquals(true, wrapperCase.caseSource != null);
        system.assertEquals(true, wrapperCampaign.campaignMemberSource != null);	
    }
    
    static testMethod void testSetOpportunityItem1() {
		
		testDataSetupmethod();
        
        List<OpportunityLineItem> opportunityLineItems = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, null);
        insert opportunityLineItems;
		
        List<Id> opptyLineItemSet = new List<Id>();
        if(!opportunityLineItems.isEmpty()){
	        for(OpportunityLineItem lineItem : opportunityLineItems){
	        	opptyLineItemSet.add(lineItem.Id);
	        }
        }
		
        //create case record
		String caseRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
        Case caseRec = TestDataFactory.createSingleCase(caseRT, accounts[0].Id);
        caseRec.Opportunity__c = opportunities[0].Id;
        insert caseRec;
        
        Campaign campaign = TestDataFactory.createCampaigns(1).get(0);
        insert campaign;
        
        List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(5, contacts, campaign);
        insert campaignMembers;

        List<Sales_Order__c> sOrderList = TestDataFactory.createSalesOrders(1, null, accounts[0], null, contacts[0], 'AdPoint');

        SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper wrapper1 = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(opportunities[0]);

        wrapper1.createBooking();
        Test.startTest();
        wrapper1.setOpptyItems(opptyLineItemSet);
        wrapper1.createOpportunitFromSalesOrder(salesOrders[0]);
        
		Map<Id, Sales_Order__c> salesOrderIdMap = SalesOrderCreateBooking_Helper.getSalesOrderById(salesOrders);
        Test.StopTest();
		system.assertEquals(true, !salesOrderIdMap.isEmpty());
        
    }
	
	//test method for createDummyOpportunityLineItem
	static testMethod void testcreateDummyOpptyLineItem() {
		
        testDataSetupmethodForDummyOppItem();

		SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper wrapper = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(opportunities[0]);
		
        List<Sales_Order__c> sOrderList = TestDataFactory.createSalesOrders(1, null, accounts[0], null, contacts[0], 'AdPoint');
		insert sOrderList;
		Test.StartTest();
		OpportunityLineItem opptyItem = wrapper.createDummyOpportunityLineItem(sOrderList[0], opportunities[0]);
        Test.StopTest();
		system.assert(true, opptyItem <> null);
        
    }
}
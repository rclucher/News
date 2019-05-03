/*---------------------------------------------------------
 * Author: Bluewolf
 * Company: Bluewolf.com
 * Description: This is the test class for OpportunityLineItem_Helper class
 * History:
 * 2015-12-15  Atul Gupta  Created
 * 2015-12-14  Atul Gupta  Updated
 * 2016-01-16 atul.gupta@bluewolfgroup.com
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    // This class provides test coverage for
    //  - OpportunityLineItemManagement.trigger 94%
    //  - OpportunityLineItem_Helper.cls        60%
 ---------------------------------------------------------*/
@isTest
private class OpportunityLineItem_Helper_Test {

    static testMethod void testZeroLineItemOpportunity() {
        
        List<Account> accList = TestDataFactory.createAccounts(1, false);
        insert accList;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accList[0]);
        insert contacts;

        List<Opportunity> oppList = TestDataFactory.createOpportunities_withContact(5, null, accList[0], contacts[0]);
        insert oppList;
        
        List<Product2> products = TestDataFactory.createProducts(3);
        List<Pricebook2> priceBookList = TestDataFactory.createCustomPricebookData();
        
        List<PricebookEntry> entryList = TestDataFactory.createPricebookEntryDataNew(products, priceBookList[0]);
        
        List<OpportunityLineItem> oppLineItemList = TestDataFactory.createOpportunityLineItems(oppList, products, entryList, null);
        insert oppLineItemList;
        
        List<OpportunityLineItemSchedule> schedules = TestDataFactory.createOpportunityLineItemSchedules(5, oppLineItemList, date.today());
        insert schedules;
        
        //createOpportunityLineItems
        Set<Id> oppIdSet = new Set<Id>();
        for(Opportunity opp : oppList){
        	oppIdSet.add(opp.Id);
        }
        
        Test.startTest();
        OpportunityLineItem_Helper.zeroOpportunityLineItemRevenue(oppIdSet);
        Test.stopTest();
        
        List<OpportunityLineItemSchedule> oldLineItemScheduleList = [Select Id From OpportunityLineItemSchedule];
        system.assertEquals(oldLineItemScheduleList.size() > 0, false);
    }
    
    static testMethod void testDeleteOpptyLineItemSchedule() {
        
        List<Account> accList = TestDataFactory.createAccounts(1, false);
        insert accList;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accList[0]);
        insert contacts;

        List<Opportunity> oppList = TestDataFactory.createOpportunities_withContact(5, null, accList[0], contacts[0]);
        insert oppList;
        
        List<Product2> products = TestDataFactory.createProducts(3);
        List<Pricebook2> priceBookList = TestDataFactory.createCustomPricebookData();
        
        List<PricebookEntry> entryList = TestDataFactory.createPricebookEntryDataNew(products, priceBookList[0]);
        
        List<OpportunityLineItem> oppLineItemList = TestDataFactory.createOpportunityLineItems(oppList, products, entryList, null);
        insert oppLineItemList;
        
        List<OpportunityLineItemSchedule> schedules = TestDataFactory.createOpportunityLineItemSchedules(5, oppLineItemList, date.today());
        insert schedules;
        
        Test.startTest();
        OpportunityLineItem_Helper.deleteOpportunityLineItemSchedules(oppLineItemList);
        Test.stopTest();
        
        List<OpportunityLineItemSchedule> oldLineItemScheduleList = [Select Id From OpportunityLineItemSchedule];
        system.assertEquals(oldLineItemScheduleList.size() > 0, false);
        
       
        
    }
    
    //SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - test method to cover createDummyOpportunityLineItem method
    static testMethod void testDummyOpptyLineItem(){
    	
    	Map<Id, Sales_Order__c> IdSalesOrderMap = new Map<Id, Sales_Order__c>();
    	Map<String, Opportunity> salesIdOpptyMap = new Map<String, Opportunity>();
    	
    	List<Account> accounts = TestDataFactory.createAccounts(1, false);
		for(Account acc : accounts){
			acc.Name = 'News Corp Australia';
		}
		insert accounts;
		
		// create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
		insert contacts;
		
		// create 10 products
		List<Product2> products = TestDataFactory.createProducts(1);
		for(Product2 pro : products){
			pro.name = 'Dummy';
		}
		update products;
		
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
		
		for(Sales_Order__c sales : salesOrders){
			IdSalesOrderMap.put(sales.Id, sales);
		}
		
		for(Sales_Order__c sl : IdSalesOrderMap.values()){
			for(Opportunity opp : opportunities){
				salesIdOpptyMap.put(sl.Id, opp);
			}
		}
		
		 List<OpportunityLineItem> lineItems = OpportunityLineItem_Helper.createDummyOpportunityLineItem(IdSalesOrderMap, salesIdOpptyMap);
    }
}
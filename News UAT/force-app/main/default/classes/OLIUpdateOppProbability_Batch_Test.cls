/*---------------------------------------------------------
 * Author: Bluewolf
 * Company: Bluewolf.com
 * Description: This is the test class for OLIUpdateOppProbability_Batch batch class
 * History:
 * 2015-12-14  Atul Gupta  Created
 * 2015-12-14  Atul Gupta  Updated
 * 2016-01-15 atul.gupta@bluewolfgroup.com
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    // This class provides test coverage for
    //  - OLIUpdateOppProbabilityAndOwner_Batch   100%
 ---------------------------------------------------------*/
@isTest
private class OLIUpdateOppProbability_Batch_Test { 
	
	static testMethod void opptyLineItemTest(){
		
		// create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
		insert accounts;
		
		// create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
		insert contacts;
		
		// create 10 products
		List<Product2> products = TestDataFactory.createProducts(10);
		
		//call TestDataFactory method to create Opportunity records
		//List<Pricebook2> pricebooks = TestDataFactory.createPricebookData();
		Id pricebookId = Test.getStandardPricebookId();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(null, null, products);
        
        // create opportunities
		List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,null,accounts[0],contacts[0]);
		insert opportunities;
		
		// create 2 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
		insert salesOrders;
		
		// create opportunity line items
		List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, salesOrders[0].Id);
		insert olis;
		
		system.debug('@@olis : '+ olis.size());
		
		//assert that there are 20 records inserted
		System.assertEquals(olis.size(), 20);
		
        Test.startTest();
        OLIUpdateOppProbabilityAndOwner_Batch opptyLineItemBatch = new OLIUpdateOppProbabilityAndOwner_Batch();
        Database.executeBatch(opptyLineItemBatch);
        Test.stopTest();

        //Verify that OpportunityLineItem records have been updated
        List<OpportunityLineItem> opptyLineItem = [Select Id, LastModifiedById from OpportunityLineItem];
        for(OpportunityLineItem lineItem : opptyLineItem){
        	
        	system.assertEquals(UserInfo.getUserId(), lineItem.LastModifiedById);
        }
	}

}
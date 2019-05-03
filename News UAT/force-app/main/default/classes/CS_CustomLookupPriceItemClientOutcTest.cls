@isTest
private class CS_CustomLookupPriceItemClientOutcTest {
	
	@testSetup static void setup() {
		CS_CustomLookupFactoryTest.insertPriceItems();
	}

	@isTest static void testGetRequiredAttributes() {
		Test.startTest();

        CS_CustomLookupPriceItemClientOutcome testObject = new CS_CustomLookupPriceItemClientOutcome();

   		System.assertEquals(testObject.getRequiredAttributes(), CS_CustomLookupPriceItemClientOutcome.REQUIRED_ATTRIBUTES);

        Test.stopTest();
	}
	
	@isTest static void testDoLookupSearch() {
		List<cspmb__Price_Item__c> priceItemsExpected = [SELECT Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, Division__c  
										  		  		 FROM cspmb__Price_Item__c 
										  		  		 WHERE Bundle_Details_Searchable__c like '%Print | SME | NSW | N/A | Leads | Test Bundle Name | Pro | 13%'];

		Map<String, String> searchFields = new Map<String, String>();
		searchFields.put('Start Date', '2018-01-01');
		searchFields.put('Segment Value', 'SME');
		searchFields.put('State Value', 'NSW');
		searchFields.put('Division Value', 'N/A');

		Test.startTest();

        CS_CustomLookupPriceItemClientOutcome testObject = new CS_CustomLookupPriceItemClientOutcome();

        Object[] priceItemsReturned = testObject.doLookupSearch(searchFields, null, null, null, null);

   		System.assertEquals(priceItemsExpected, priceItemsReturned);

        Test.stopTest();
	}
}
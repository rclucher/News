@isTest
private class CS_CustomLookupPriceItemImpactTest {
	
	@testSetup static void setup() {
		CS_CustomLookupFactoryTest.insertPriceItems();
	}

	@isTest static void testGetRequiredAttributes() {
		Test.startTest();

        CS_CustomLookupPriceItemImpact testObject = new CS_CustomLookupPriceItemImpact();

   		System.assertEquals(testObject.getRequiredAttributes(), CS_CustomLookupPriceItemImpact.REQUIRED_ATTRIBUTES);

        Test.stopTest();
	}
	
	@isTest static void testDoLookupSearch() {
		List<cspmb__Price_Item__c> priceItemsExpected = [SELECT Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, Division__c 
										  		  		 FROM cspmb__Price_Item__c 
										  		  		 WHERE Bundle_Details_Searchable__c like '%Print | SME | NSW | N/A | Leads | Always-On LITE | Pro | 13%'];

		Map<String, String> searchFields = new Map<String, String>();
		searchFields.put('Start Date', '2018-01-01');
		searchFields.put('Segment Value', 'SME');
		searchFields.put('State Value', 'NSW');
		searchFields.put('Client Outcome Value', 'Leads');
		searchFields.put('Media Type Value', 'Print');
		searchFields.put('Bundle Name Value', 'Always-ON LITE');
		searchFields.put('Division Value', 'N/A');

		Test.startTest();

        CS_CustomLookupPriceItemImpact testObject = new CS_CustomLookupPriceItemImpact();

        Object[] priceItemsReturned = testObject.doLookupSearch(searchFields, null, null, null, null);

   		System.assertEquals(priceItemsExpected, priceItemsReturned);

        Test.stopTest();
	}
}
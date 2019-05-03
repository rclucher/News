@isTest
private class CS_CustomLookupPriceItemMediaTypeTest {
	
	@testSetup static void setup() {
		CS_CustomLookupFactoryTest.insertPriceItems();
	}

	@isTest static void testGetRequiredAttributes() {
		Test.startTest();

        CS_CustomLookupPriceItemMediaType testObject = new CS_CustomLookupPriceItemMediaType();

   		System.assertEquals(testObject.getRequiredAttributes(), CS_CustomLookupPriceItemMediaType.REQUIRED_ATTRIBUTES);

        Test.stopTest();
	}
	
	@isTest static void testDoLookupSearch() {
		List<cspmb__Price_Item__c> priceItemsExpected = [SELECT Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c 
										  		  		 FROM cspmb__Price_Item__c 
										  		  		 WHERE Name like '%Print | SME | NSW | Leads | Plus | Pro | 13%'];

		Map<String, String> searchFields = new Map<String, String>();
		searchFields.put('Start Date', '2018-01-01');
		searchFields.put('Segment Value', 'SME');
		searchFields.put('State Value', 'NSW');
		searchFields.put('Client Outcome Value', 'Leads');

		Test.startTest();

        CS_CustomLookupPriceItemMediaType testObject = new CS_CustomLookupPriceItemMediaType();

        Object[] priceItemsReturned = testObject.doLookupSearch(searchFields, null, null, null, null);

   		System.assertEquals(priceItemsExpected, priceItemsReturned);

        Test.stopTest();
	}
}
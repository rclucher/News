@isTest
private class CS_CustomLookupPriceItemSegmentTest {
	
	@testSetup static void setup() {
		CS_CustomLookupFactoryTest.insertPriceItems();
	}

	@isTest static void testGetRequiredAttributes() {
		Test.startTest();

        CS_CustomLookupPriceItemSegment testObject = new CS_CustomLookupPriceItemSegment();

   		System.assertEquals(testObject.getRequiredAttributes(), CS_CustomLookupPriceItemSegment.REQUIRED_ATTRIBUTES);

        Test.stopTest();
	}
	
	@isTest static void testDoLookupSearch() {
		List<cspmb__Price_Item__c> priceItemsExpected = [SELECT Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, State_Value__c, Segment_Value__c, Division__c 
										  		  		 FROM cspmb__Price_Item__c 
										  		  		 WHERE Bundle_Details_Searchable__c = 'Print | SME | NSW | N/A | Leads | Plus | Pro | 13'];

		Map<String, String> searchFields = new Map<String, String>();
		searchFields.put('Start Date', '2018-01-01');

		Test.startTest();

        CS_CustomLookupPriceItemSegment testObject = new CS_CustomLookupPriceItemSegment();

        Object[] priceItemsReturned = testObject.doLookupSearch(searchFields, null, null, null, null);

   		System.assertEquals(priceItemsExpected, priceItemsReturned);

        Test.stopTest();
	}

	@isTest static void testDoDynamicLookupSearch() {
		List<cspmb__Price_Item__c> priceItemsExpected = [SELECT Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, State_Value__c, Segment_Value__c, Division__c  
										  		  		 FROM cspmb__Price_Item__c 
										  		  		 WHERE Bundle_Details_Searchable__c = 'Print | SME | NSW | N/A | Leads | Plus | Pro | 13'];

		Map<String, String> searchFields = new Map<String, String>();
		searchFields.put('Media Type Value', 'Print Led');

		Test.startTest();

        CS_CustomLookupPriceItemSegment testObject = new CS_CustomLookupPriceItemSegment();

        Object[] priceItemsReturned = testObject.doDynamicLookupSearch(searchFields, null);

   		System.assertEquals(priceItemsExpected, priceItemsReturned);

        Test.stopTest();
	}
}
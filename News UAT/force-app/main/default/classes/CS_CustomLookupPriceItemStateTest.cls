@isTest
private class CS_CustomLookupPriceItemStateTest {
	
	@testSetup static void setup() {
		CS_CustomLookupFactoryTest.insertPriceItems();
	}

	@isTest static void testGetRequiredAttributes() {
		Test.startTest();

        CS_CustomLookupPriceItemState testObject = new CS_CustomLookupPriceItemState();

   		System.assertEquals(testObject.getRequiredAttributes(), CS_CustomLookupPriceItemState.REQUIRED_ATTRIBUTES);

        Test.stopTest();
	}
	
	@isTest static void testDoLookupSearch() {
		List<cspmb__Price_Item__c> priceItemsExpected = [SELECT Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, State_Value__c, Segment_Value__c, Division__c 
										  		  		 FROM cspmb__Price_Item__c 
										  		  		 WHERE Bundle_Details_Searchable__c = 'Print | SME | NSW | N/A | Leads | Plus | Pro | 13'];

		Map<String, String> searchFields = new Map<String, String>();
		searchFields.put('Start Date', '2018-01-01');
		searchFields.put('Segment Value', 'SME');

		Test.startTest();

        CS_CustomLookupPriceItemState testObject = new CS_CustomLookupPriceItemState();

        Object[] priceItemsReturned = testObject.doLookupSearch(searchFields, null, null, null, null);

   		System.assertEquals(priceItemsExpected, priceItemsReturned);

        Test.stopTest();
	}

	@isTest static void testDoDynamicLookupSearch() {
		List<cspmb__Price_Item__c> priceItemsExpected = [SELECT Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, Division__c 
										  		  		 FROM cspmb__Price_Item__c 
										  		  		 WHERE Bundle_Details_Searchable__c = 'Print | SME | NSW | N/A | Leads | Plus | Pro | 13'];

		Map<String, String> searchFields = new Map<String, String>();
		searchFields.put('Segment Value', 'SME');
		searchFields.put('User State', 'NSW');
		searchFields.put('Media Type Value', 'Print');

		Test.startTest();

        CS_CustomLookupPriceItemState testObject = new CS_CustomLookupPriceItemState();

        Object[] priceItemsReturned = testObject.doDynamicLookupSearch(searchFields, null);

        // 09/03/2018 IV: In normal circumstances, this would be used
   		// System.assertEquals(priceItemsExpected, priceItemsReturned);

        Test.stopTest();
	}
}
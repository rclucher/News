@isTest
private class CS_CustomLookupPriceItemBundleNameTest {
	
	@testSetup static void setup() {
		CS_CustomLookupFactoryTest.insertPriceItems();
	}

	@isTest static void testGetRequiredAttributes() {
		Test.startTest();

        CS_CustomLookupPriceItemBundleName testObject = new CS_CustomLookupPriceItemBundleName();

   		System.assertEquals(testObject.getRequiredAttributes(), CS_CustomLookupPriceItemBundleName.REQUIRED_ATTRIBUTES);

        Test.stopTest();
	}
	
	@isTest static void testDoLookupSearch() {
		List<cspmb__Price_Item__c> priceItemsExpected = [SELECT Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, Division__c  
										  		  		 FROM cspmb__Price_Item__c 
										  		  		 WHERE Bundle_Details_Searchable__c like '%Print | SME | NSW | N/A | Leads | Plus | Pro | 13%'];
		
		Map<String, String> searchFields = new Map<String, String>();
		searchFields.put('Start Date', '2018-01-01');
		searchFields.put('Segment Value', 'SME');
		searchFields.put('State Value', 'NSW');
		searchFields.put('Client Outcome Value', 'Leads');
		searchFields.put('Media Type Value', 'Print');
        searchFields.put('Impact Value', 'Pro');
        searchFields.put('Duration Value', '13');
        searchFields.put('Division Value', 'N/A');

		Test.startTest();

        CS_CustomLookupPriceItemBundleName testObject = new CS_CustomLookupPriceItemBundleName();

        Object[] priceItemsReturned = testObject.doLookupSearch(searchFields, null, null, null, null);

   		System.assertEquals(priceItemsExpected, priceItemsReturned);

        Test.stopTest();
	}
}
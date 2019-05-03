@isTest
private class SelectItems_Test {
	
	@isTest static void test_SelectItemsDisabled() {
		// Implement test code

		SelectItems items = new SelectItems('testValue','testLabel',true);
		System.assertEquals('testValue', items.value);
		System.assertEquals(true,items.disabled);

	}


	@isTest static void test_SelectItems() {
		// Implement test code

		SelectItems items = new SelectItems('testValue','testLabel');
		System.assertEquals('testValue', items.value);

	}
	
}
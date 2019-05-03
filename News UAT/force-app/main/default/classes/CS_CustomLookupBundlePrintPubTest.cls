@isTest
private class CS_CustomLookupBundlePrintPubTest {
    
    @testSetup static void setup() {
        CS_CustomLookupFactoryTest.insertPriceItems();
    }

    @isTest static void testGetRequiredAttributes() {
        Test.startTest();

        CS_CustomLookupBundlePrintPublication testObject = new CS_CustomLookupBundlePrintPublication();

        System.assertEquals(testObject.getRequiredAttributes(), CS_CustomLookupBundlePrintPublication.REQUIRED_ATTRIBUTES);

        Test.stopTest();
    }
    
    @isTest static void testDoLookupSearch() {
        List<csmso__Node_Advert_Assignment__c> naaListExpected = [SELECT csmso__Title_Product_Node__r.Group__c, csmso__Title_Product_Node__r.State__c, csmso__Title_Product_Node__r.Division__c, 
                            csmso__Title_Product_Node__r.Publication_Name__c 
                      FROM csmso__Node_Advert_Assignment__c 
                      WHERE csmso__title_product_node__r.applicable_for_bundles__c = true 
                            AND csmso__title_product_node__r.effective_end_date__c >= 2018-12-01 
                            AND csmso__title_product_node__r.effective_start_date__c <= 2018-12-01 
                            AND csmso__title_product_node__r.Is_Active__c = true 
                            AND csmso__title_product_node__r.product_node_platform_type__c = 'Print Publication' 
                            AND csmso__title_product_node__r.state_name__c = 'NSW'
                            AND Name = 'Half Page Horizontal'];

        Map<String, String> searchFields = new Map<String, String>();
        searchFields.put('Bundle Start Date', '2018-12-01');
        searchFields.put('Bundle State', 'NSW');
        searchFields.put('Ad Size', 'Half Page Horizontal');
        searchFields.put('Division', 'N/A');

        Test.startTest();

        CS_CustomLookupBundlePrintPublication testObject = new CS_CustomLookupBundlePrintPublication();

        Object[] nodeAdvertAssignmentsReturned = testObject.doLookupSearch(searchFields, null, null, null, null);

        System.assertEquals(naaListExpected, nodeAdvertAssignmentsReturned);

        Test.stopTest();
    }
}
global class CS_CustomLookupBundlePrintPublication extends cscfga.ALookupSearch {

    //Add all attributes required for the logic to work Like '["Attribute1","Attribute2"]'
    public static final String REQUIRED_ATTRIBUTES = '["Bundle Start Date","Bundle State","Ad Size","Division"]';

    global override String getRequiredAttributes() {
        // Attribute names used in the WHERE clause of SOQL query, JSON notation, e.g. '["Attribute1","Attribute2"]'
        return REQUIRED_ATTRIBUTES;
    }

    public override Object[] doLookupSearch(Map<String, String> searchFields, String productDefinitionId, Id[] excludeIds, Integer pageOffset, Integer pageLimit) {
        List<csmso__Node_Advert_Assignment__c> naaList = null;
        List<csmso__Node_Advert_Assignment__c> naaListFiltered = new List<csmso__Node_Advert_Assignment__c>();
        
        // Use these attributes for WHERE filter
        String bundleStartDate = searchFields.get('Bundle Start Date');
        String bundleState     = searchFields.get('Bundle State');
        String adSize          = searchFields.get('Ad Size');
        String division        = searchFields.get('Division');
        
        System.debug('This is bundleStartDate: ' + bundleStartDate + ', bundleState: ' + bundleState + ', adSize: ' + adSize + ', division: ' + division);
        
        if (String.isNotEmpty(bundleStartDate) && String.isNotEmpty(bundleState) && String.isNotEmpty(adSize) && String.isNotEmpty(division)) {
            Date dBundleStartDate = Date.valueOf(bundleStartDate);

            naaList = [SELECT csmso__Title_Product_Node__r.Name,
                                Publication_Name__c,
                                csmso__Title_Product_Node__r.Id,
                                csmso__Title_Product_Node__r.State_name__c,
                                csmso__Title_Product_Node__r.Type_name__c,
                                csmso__Title_Product_Node__r.Group__c,
                                csmso__Title_Product_Node__r.State__c,
                                csmso__Title_Product_Node__r.Publication_name__c,
                                Name,
                                csmso__Title_Product_Node__r.Product_Node_Platform_Type__c,
                                csmso__Title_Product_Node__r.Applicable_For_Bundles__c,
                                csmso__Title_Product_Node__r.Is_Active__c,
                                csmso__Title_Product_Node__r.Effective_Start_Date__c,
                                csmso__Title_Product_Node__r.Effective_End_Date__c,
                                csmso__Title_Product_Node__r.Division__c
                      FROM csmso__Node_Advert_Assignment__c 
                      WHERE csmso__title_product_node__r.applicable_for_bundles__c = true 
                            AND csmso__title_product_node__r.effective_end_date__c >= :dBundleStartDate 
                            AND csmso__title_product_node__r.effective_start_date__c <= :dBundleStartDate 
                            AND csmso__title_product_node__r.Is_Active__c = true 
                            AND csmso__title_product_node__r.product_node_platform_type__c = 'Print Publication' 
                            AND csmso__title_product_node__r.state_name__c = :bundleState 
                            AND Name = :adSize];

            if (division != 'N/A') {
                for (csmso__Node_Advert_Assignment__c naa : naaList) {
                    if (naa.csmso__Title_Product_Node__r.Division__c == division) {
                        naaListFiltered.add(naa);
                    }
                }
            } else {
                naaListFiltered = naaList;
            }
        }

        return naaListFiltered;
    }
}
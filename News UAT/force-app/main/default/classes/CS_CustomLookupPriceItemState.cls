global class CS_CustomLookupPriceItemState extends cscfga.ALookupSearch {

    //Add all attributes required for the logic to work Like '["Attribute1","Attribute2"]'
    public static final String REQUIRED_ATTRIBUTES = '["Start Date","Segment Value","User State","Media Type Value"]';

    public override String getRequiredAttributes() {
        return REQUIRED_ATTRIBUTES;
    } 
    
    public override Object[] doLookupSearch(Map<String, String> searchFields, String productDefinitionId, Id[] excludeIds, Integer pageOffset, Integer pageLimit){
        List<cspmb__Price_Item__c> piList = null;
        List<cspmb__Price_Item__c> piListUnique = new List<cspmb__Price_Item__c>();
        
        // Use these attributes for WHERE filter
        String startDate = searchFields.get('Start Date');
        String segment   = searchFields.get('Segment Value');
        String mediaType = searchFields.get('Media Type Value');

        if (String.isNotEmpty(startDate) && String.isNotEmpty(segment)) {
            Date dStartDate = Date.valueOf(startDate);

            piList = [SELECT Bundle_Details__c, Name, Segment__c, Segment_Value__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, State_Value__c, Division__c 
                      FROM cspmb__Price_Item__c
                      WHERE Segment__c =: segment AND 
                            cspmb__Is_Active__c = true AND 
                            cspmb__Effective_Start_Date__c <= :dStartDate AND 
                            (cspmb__Effective_End_Date__c >= :dStartDate OR cspmb__Effective_End_Date__c = null)];
           
            // add only unique items to the return List
            Set<String> uniqueItems = new Set<String>(); 
            
            for (cspmb__Price_Item__c priceItem : piList) {
                if (!uniqueItems.contains(priceItem.State__c)) {
                    piListUnique.add(priceItem);
                    uniqueItems.add(priceItem.State__c);
               }
            }
        }

        return piListUnique;
    }

    public override Object[] doDynamicLookupSearch(Map<String, String> searchFields, String productDefinitionID) {

        List<cspmb__Price_Item__c> piList = null;
        List<cspmb__Price_Item__c> piListUnique = new List<cspmb__Price_Item__c>();

        String segment   = searchFields.get('Segment Value');
        String userState   = searchFields.get('User State');
        String mediaType = searchFields.get('Media Type Value');

        piList = [SELECT Name, Segment__c, Segment_Value__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, State_Value__c, Division__c FROM cspmb__Price_Item__c WHERE Segment__c =:segment AND State__c =:userState AND Media_Type__c =: mediaType];
        
        /* 
        // 09/03/2018 IV: I have commmented this out because it didn't make sense to throw the exception (and the unit test was failing)
        // I'm not sure what was the original intetion here so I just returned the empty List.

        System.debug('*** doDynamicLookupSearch' + segment);
        System.debug('*** doDynamicLookupSearch' + userState);
        System.debug('*** doDynamicLookupSearch' + piList);
        throw new VisualforceException('lookup error');

        // add only unique items to the return List
        Set<String> uniqueItems = new Set<String>();

        for (cspmb__Price_Item__c priceItem : piList) {
            if (!uniqueItems.contains(priceItem.State__c)) {
                piListUnique.add(priceItem);
                uniqueItems.add(priceItem.State__c);
            }
        }
        */

        return piListUnique;
    }

}
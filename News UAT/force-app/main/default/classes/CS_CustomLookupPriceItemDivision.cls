global class CS_CustomLookupPriceItemDivision extends cscfga.ALookupSearch {

    //Add all attributes required for the logic to work Like '["Attribute1","Attribute2"]'
    public static final String REQUIRED_ATTRIBUTES = '["Start Date","Segment Value","State Value","FLAG Include Division","Media Type Value"]';
    public static final String DIVISION_AS_BLANK   = 'N/A';


    public override String getRequiredAttributes() {
        // Attribute names used in the WHERE clause of SOQL query, JSON notation, e.g. '["Attribute1","Attribute2"]'
        return REQUIRED_ATTRIBUTES;
    }


    public override Object[] doDynamicLookupSearch(Map<String, String> searchFields, String productDefinitionID) {
        List<cspmb__Price_Item__c> piList = null;
        List<cspmb__Price_Item__c> piListUnique = new List<cspmb__Price_Item__c>();


        // Use these attributes for WHERE filter
        String startDate = searchFields.get('Start Date');
        String segment   = searchFields.get('Segment Value');
        String state     = searchFields.get('State Value');
        String flagIncludeDivision = searchFields.get('FLAG Include Division');
        String mediaType = searchFields.get('Media Type Value');
        
        if (String.isNotEmpty(startDate) && String.isNotEmpty(segment) && String.isNotEmpty(state)) {
            Date dStartDate = Date.valueOf(startDate);

            piList = [SELECT Bundle_Details__c, Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, Division__c
                      FROM cspmb__Price_Item__c
                      WHERE Segment__c  = :segment AND 
                            State__c    = :state AND 
                            cspmb__Is_Active__c = true AND 
                            cspmb__Effective_Start_Date__c <= :dStartDate AND 
                            (cspmb__Effective_End_Date__c >= :dStartDate OR cspmb__Effective_End_Date__c = null) AND
                            Media_Type__c =: mediaType];
           
            // add only unique items to the return List
            Set<String> uniqueItems = new Set<String>(); 
            
            for (cspmb__Price_Item__c priceItem : piList) {
                if (priceItem.Division__c == null || (priceItem.Division__c != null && priceItem.Division__c == '')) {
                    priceItem.Division__c = DIVISION_AS_BLANK;
                }
                
                if (!uniqueItems.contains(priceItem.Division__c)) {

                    uniqueItems.add(priceItem.Division__c);

                    if (priceItem.Division__c == DIVISION_AS_BLANK && piListUnique.size()>0) {
                        piListUnique.add(0,priceItem); // forcing the N/A to be first
                    } else {
                        piListUnique.add(priceItem);
                    }
               }
            }
            
        }

        
        return piListUnique;
    }
    
    public override Object[] doLookupSearch(Map<String, String> searchFields, String productDefinitionId, Id[] excludeIds, Integer pageOffset, Integer pageLimit){
        List<cspmb__Price_Item__c> piList = null;
        List<cspmb__Price_Item__c> piListUnique = new List<cspmb__Price_Item__c>();
        
        // Use these attributes for WHERE filter
        String startDate = searchFields.get('Start Date');
        String segment   = searchFields.get('Segment Value');
        String state     = searchFields.get('State Value');
        String flagIncludeDivision = searchFields.get('FLAG Include Division');
        String mediaType = searchFields.get('Media Type Value');

        if (String.isNotEmpty(startDate) && String.isNotEmpty(segment) && String.isNotEmpty(state)) {
            Date dStartDate = Date.valueOf(startDate);

            piList = [SELECT Bundle_Details__c, Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, Division__c
                      FROM cspmb__Price_Item__c
                      WHERE Segment__c  = :segment AND 
                            State__c    = :state AND 
                            cspmb__Is_Active__c = true AND 
                            cspmb__Effective_Start_Date__c <= :dStartDate AND 
                            (cspmb__Effective_End_Date__c >= :dStartDate OR cspmb__Effective_End_Date__c = null) AND
                            Media_Type__c =: mediaType];
           
            // add only unique items to the return List
            Set<String> uniqueItems = new Set<String>(); 
            
            for (cspmb__Price_Item__c priceItem : piList) {
                if (priceItem.Division__c == null || (priceItem.Division__c != null && priceItem.Division__c == '')) {
                    priceItem.Division__c = DIVISION_AS_BLANK;
                }
                
                if (!uniqueItems.contains(priceItem.Division__c)) {

                    uniqueItems.add(priceItem.Division__c);

                    if (priceItem.Division__c == DIVISION_AS_BLANK && piListUnique.size()>0) {
                        piListUnique.add(0,priceItem); // forcing the N/A to be first
                    } else {
                        piListUnique.add(priceItem);
                    }
                }
            }


            
            
        }

        return piListUnique;
    }
}
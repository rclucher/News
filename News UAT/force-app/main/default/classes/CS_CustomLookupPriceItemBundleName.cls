global class CS_CustomLookupPriceItemBundleName extends cscfga.ALookupSearch {

    //Add all attributes required for the logic to work Like '["Attribute1","Attribute2"]'
    public static final String REQUIRED_ATTRIBUTES = '["Start Date","Segment Value","State Value","Division Value","Client Outcome Value","Media Type Value","Impact Value","Duration Value"]';

    public override String getRequiredAttributes() {
        // Attribute names used in the WHERE clause of SOQL query, JSON notation, e.g. '["Attribute1","Attribute2"]'
        return REQUIRED_ATTRIBUTES;
    } 
    
    public override Object[] doLookupSearch(Map<String, String> searchFields, String productDefinitionId, Id[] excludeIds, Integer pageOffset, Integer pageLimit){
        List<cspmb__Price_Item__c> piList = null;
        List<cspmb__Price_Item__c> piListUnique = new List<cspmb__Price_Item__c>();
        
        // Use these attributes for WHERE filter
        String startDate     = searchFields.get('Start Date');
        String segment         = searchFields.get('Segment Value');
        String state           = searchFields.get('State Value');
        String division        = searchFields.get('Division Value');
        String clientOutcome = searchFields.get('Client Outcome Value');
        String mediaType       = searchFields.get('Media Type Value');
        //String impact          = searchFields.get('Impact Value'); //13/02/2018 IG: COMMENTED
        //String duration          = searchFields.get('Duration Value'); //13/02/2018 IG: COMMENTED

        if (String.isNotEmpty(startDate) && String.isNotEmpty(segment) && String.isNotEmpty(state) && 
            String.isNotEmpty(clientOutcome) && String.isNotEmpty(mediaType)/* && String.isNotEmpty(impact) && String.isNotEmpty(duration)*/) {
          Date dStartDate = Date.valueOf(startDate);

          piList = [SELECT Bundle_Details__c, Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, Division__c 
                    FROM cspmb__Price_Item__c
                    WHERE Segment__c              = :segment AND 
                            State__c              = :state AND 
                            Division__c         = :division AND 
                            Client_Outcome__c = :clientOutcome AND 
                            Media_Type__c       = :mediaType AND 
                            //Impact__c       = :impact AND 
                            //Duration__c       = :duration AND 
                            cspmb__Is_Active__c = true AND 
                          cspmb__Effective_Start_Date__c <= :dStartDate AND 
                          (cspmb__Effective_End_Date__c >= :dStartDate OR cspmb__Effective_End_Date__c = null)];
         
          // add only unique items to the return List
          Set<String> uniqueItems = new Set<String>(); 

          for (cspmb__Price_Item__c priceItem : piList) {
              if (!uniqueItems.contains(priceItem.Bundle_Name__c)) {
                  piListUnique.add(priceItem);
                  uniqueItems.add(priceItem.Bundle_Name__c);
             }
          }
        }

        return piListUnique;
    }
}
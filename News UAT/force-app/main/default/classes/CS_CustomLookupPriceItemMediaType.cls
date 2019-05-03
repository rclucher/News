global class CS_CustomLookupPriceItemMediaType extends cscfga.ALookupSearch {

    //Add all attributes required for the logic to work Like '["Attribute1","Attribute2"]'
    public static final String REQUIRED_ATTRIBUTES = '["Start Date","Segment Value","State Value","Client Outcome Value"]';

    public override String getRequiredAttributes() {
        return REQUIRED_ATTRIBUTES;
    } 
    
    public override Object[] doLookupSearch(Map<String, String> searchFields, String productDefinitionId, Id[] excludeIds, Integer pageOffset, Integer pageLimit){
        List<cspmb__Price_Item__c> piList = null;
        List<cspmb__Price_Item__c> piListUnique = new List<cspmb__Price_Item__c>();
        
        // Use these attributes for WHERE filter
        String startDate     = searchFields.get('Start Date');
        String segment         = searchFields.get('Segment Value');
        String state           = searchFields.get('State Value');
        String clientOutcome = searchFields.get('Client Outcome Value');

        if (String.isNotEmpty(startDate) && String.isNotEmpty(segment) && 
            String.isNotEmpty(state) && String.isNotEmpty(clientOutcome)) {
          Date dStartDate = Date.valueOf(startDate);

          piList = [SELECT Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c
                    FROM cspmb__Price_Item__c
                    WHERE Segment__c        = :segment AND
                          State__c          = :state AND 
                          Client_Outcome__c = :clientOutcome AND 
                          cspmb__Effective_Start_Date__c <= :dStartDate AND 
                          (cspmb__Effective_End_Date__c >= :dStartDate OR cspmb__Effective_End_Date__c = null)];

          // add only unique items to the return List
          Set<String> uniqueItems = new Set<String>(); 

          for (cspmb__Price_Item__c priceItem : piList) {
              if (!uniqueItems.contains(priceItem.Media_Type__c)) {
                  piListUnique.add(priceItem);
                  uniqueItems.add(priceItem.Media_Type__c);
             }
          }
        }

        return piListUnique;
    }
}
@isTest
private class CS_CustomLookupPriceItemDivisionTest {
    
    @testSetup static void setup() {
        //CS_CustomLookupFactoryTest.insertPriceItems();

        List<cspmb__Price_Item__c> priceItems = new List<cspmb__Price_Item__c>{
                new cspmb__Price_Item__c(Name = 'Price Item 1',
                        Segment__c = 'SME',
                        State__c = 'NSW',
                        Client_Outcome__c = 'Sales',
                        Media_Type__c = 'Print Led',
                        Bundle_Name__c = 'Plus',
                        Impact__c = 'Pro',
                        Duration__c = '13',
                        cspmb__Is_Active__c = true,
                        cspmb__Effective_Start_Date__c = Date.valueOf('2018-01-01'),
                        cspmb__Effective_End_Date__c = Date.valueOf('2099-12-31')),
                new cspmb__Price_Item__c(Name = 'Price Item 2',
                        Segment__c = 'SME',
                        State__c = 'NSW',
                        Client_Outcome__c = 'Sales',
                        Media_Type__c = 'Print Led',
                        Bundle_Name__c = 'Plus',
                        Impact__c = 'Pro',
                        Duration__c = '26',
                        cspmb__Effective_Start_Date__c = Date.valueOf('2018-01-01'),
                        cspmb__Effective_End_Date__c = Date.valueOf('2018-03-01'))};

        // Note there is a Workflow rule that changes the Name of the record to be
        // "Media_Type__c | Segment__c | State__c | Client_Outcome__c | Bundle_Name__c | Impact__c | Duration__c"
        insert priceItems;
    }

    @isTest static void testGetRequiredAttributes() {
        Test.startTest();

        CS_CustomLookupPriceItemDivision testObject = new CS_CustomLookupPriceItemDivision();

        System.assertEquals(testObject.getRequiredAttributes(), CS_CustomLookupPriceItemDivision.REQUIRED_ATTRIBUTES);

        Test.stopTest();
    }
    
    @isTest static void testDoLookupSearch() {
        List<cspmb__Price_Item__c> priceItemsExpected = [SELECT Bundle_Details__c, Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, Division__c
                                                         FROM cspmb__Price_Item__c 
                                                         WHERE Bundle_Details_Searchable__c ='Print Led | SME | NSW | N/A | Sales | Plus | Pro | 13'];
        System.debug(priceItemsExpected);
        Map<String, String> searchFields = new Map<String, String>();
        searchFields.put('Start Date', '2018-01-01');
        searchFields.put('Segment Value', 'SME');
        searchFields.put('State Value', 'NSW');
        searchFields.put('Media Type Value', 'Print Led');

        Test.startTest();

        CS_CustomLookupPriceItemDivision testObject = new CS_CustomLookupPriceItemDivision();

        Object[] priceItemsReturned = testObject.doLookupSearch(searchFields, null, null, null, null);

        System.assertEquals(priceItemsExpected, priceItemsReturned);

        Test.stopTest();
    }

    @isTest static void testDoDynamicLookupSearch() {
        List<cspmb__Price_Item__c> priceItemsExpected = [SELECT Bundle_Details__c, Name, Segment__c, Bundle_Name__c, Client_Outcome__c, Duration__c, Impact__c, Media_Type__c, State__c, Division__c
        FROM cspmb__Price_Item__c
        WHERE Bundle_Details_Searchable__c = 'Print Led | SME | NSW | N/A | Sales | Plus | Pro | 13'];

        Map<String, String> searchFields = new Map<String, String>();
        searchFields.put('Start Date', '2018-01-01');
        searchFields.put('Segment Value', 'SME');
        searchFields.put('State Value', 'NSW');
        searchFields.put('Media Type Value', 'Print Led');
        Test.startTest();

        CS_CustomLookupPriceItemDivision testObject = new CS_CustomLookupPriceItemDivision();

        Object[] priceItemsReturned = testObject.doDynamicLookupSearch(searchFields, null);

        System.assertEquals(priceItemsExpected, priceItemsReturned);

        Test.stopTest();
    }
}
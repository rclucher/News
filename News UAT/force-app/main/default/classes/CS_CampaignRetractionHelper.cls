/**
 * Created by petar on 2019-02-28.
 */

public without sharing class CS_CampaignRetractionHelper {

    public static final String FIELDSET_PREFIX = 'OA_Retract_';
    public static final String PRODUCT_TYPE    = 'Product_Type_';

    public static final List<String> PO_SCENARIOS = new List<String> {'Upgrade','Downgrade'};

    /**
    * @name emptyProductOrderFieldsPerRecordType
    * @param applicablePOs List of Product_Order__c with included RecordType's DeveloperName
    */
    public static void emptyProductOrderFieldsPerRecordType(List<Product_Order__c> applicablePOs) {


        // gather unique Record Types
        Set<String> poRecordTypesDevNames = new Set<String>();

        for(Product_Order__c po: applicablePOs) {

            poRecordTypesDevNames.add(po.RecordType.DeveloperName);
        }
        System.debug('RecordType Names'  + poRecordTypesDevNames);

        // build the map with RecordType Names and fields required to clear out
        Map<String,List<FieldSetMember>> rtNameToFsMemberMap = new Map<String, List<FieldSetMember>>();
        String          fieldSetName = '';
        FieldSet        poFieldSet;

        for (String recordTypeDevName :poRecordTypesDevNames) {


            fieldSetName = FIELDSET_PREFIX + recordTypeDevName;
            poFieldSet = SObjectType.Product_Order__c.fieldSets.getMap().get(fieldSetName);

            if (poFieldSet != null) {
                System.debug('Found fieldset ' + fieldSetName);
                rtNameToFsMemberMap.put(fieldSetName, poFieldSet.getFields());
            }
        }

        // build the fieldset name against each PO and use the map to identify the field to clear
        for(Product_Order__c po: applicablePOs) {
            if (!PO_SCENARIOS.contains(po.Type__c)) continue;

            fieldSetName = FIELDSET_PREFIX + po.RecordType.DeveloperName;
            emptyProductOrderWithFieldSet(po, fieldSetName, rtNameToFsMemberMap);

        }

    }

    /**
    * @name emptyProductOrderFieldsPerProductType
    * @param applicablePOs List of Product_Order__c with included ProductNodes's Product Type
    */

    public static void emptyProductOrderFieldsPerProductType(List<Product_Order__c> applicablePOs) {


        // gather unique Product Types
        Set<String> poProductTypeNames = new Set<String>();

        for (Product_Order__c po : applicablePOs) {

            if (String.isBlank(po.Product_Node__r.Product_Type__c)) continue;

            poProductTypeNames.add(po.Product_Node__r.Product_Type__c);
        }

        System.debug('Product Types' + poProductTypeNames);

        // build the map with ProductType Names and fields required to clear out
        Map<String, List<FieldSetMember>> ptNameToFsMemberMap = new Map<String, List<FieldSetMember>>();
        String fieldSetName = '';
        FieldSet poFieldSet;

        for (String prodTypeName : poProductTypeNames) {

            fieldSetName = FIELDSET_PREFIX + PRODUCT_TYPE + prodTypeName.deleteWhitespace();

            poFieldSet = SObjectType.Product_Order__c.fieldSets.getMap().get(fieldSetName);

            if (poFieldSet != null) {
                System.debug('Found fieldset ' + fieldSetName);
                ptNameToFsMemberMap.put(fieldSetName, poFieldSet.getFields());
            }

        }

        // build the fieldset name against each PO and use the map to identify the field to clear
        for(Product_Order__c po: applicablePOs) {
            if (!PO_SCENARIOS.contains(po.Type__c)) continue;

            fieldSetName = FIELDSET_PREFIX + PRODUCT_TYPE + po.Product_Node__r.Product_Type__c;

            emptyProductOrderWithFieldSet(po, fieldSetName, ptNameToFsMemberMap);

        }

    }

    /**
     * @Name emptyProductOrderWithFieldSet
     * @param po Product_Order__c record
     * @param fieldSetName Name of the fieldSet expected to be found in the provided map
     * @param fieldSetMap  Map of FieldSetMember Lists where the key matches either the product type or record type fieldset for OA Retraction
     */
    private static void emptyProductOrderWithFieldSet(Product_Order__c po, String fieldSetName, Map<String,List<FieldSetMember>> fieldSetMap) {

        if (fieldSetMap.get(fieldSetName) == null) {
            //System.debug('Didn\'t find ' + fieldSetName + ' in the map: ' + fieldSetMap );
            return;
        }

        for (FieldSetMember fsMember: fieldSetMap.get(fieldSetName)) {

            System.debug('Clearing field ' + fsMember.getFieldPath() + ' for PO ' + po.Id);
            po.put( fsMember.getFieldPath(), null);
        }
    }


    public static void emptyProductOrderFields(List<Product_Order__c> applicablePOs) {
        emptyProductOrderFieldsPerProductType(applicablePOs);
        emptyProductOrderFieldsPerRecordType(applicablePOs);
    }
}
/**
 * Created by petar.mikic on 18/09/2017.
 */

global class CS_UpgradeOpenProductsBatch implements Database.Batchable<sObject>, Database.Stateful
{
    private string strQuery;
    private set<ID> productConfigIds;
    private Set<String> OppStageList;
    private Set<String> SOStatusList;


    //search only for original product configurations
    private cscfga__Product_Definition_Version__c defVer = [SELECT cscfga__Original_Definition__c,
                                                                   cscfga__Replacement_Definition__c
                                                            FROM  cscfga__Product_Definition_Version__c
                                                            LIMIT 1];

    private String origProdDef = defVer.cscfga__Original_Definition__c;

    //this should be part of JSON definition that is being imported
    private cscfga__Product_Definition__c def = [Select Id,
                                                 (Select Id,cscfga__active__c from cscfga__rules__r where cscfga__grouping__c = 'QuantityUpdate')
                                                from cscfga__Product_Definition__c
                                                where id = :defVer.cscfga__Replacement_Definition__c];
    // IV
    global CS_UpgradeOpenProductsBatch() {

        //excluding set of stages for select, so empty status used for orphan configurations
        OppStageList = new Set<String>{'Closed Won','Closed Lost'};
        SOStatusList = new Set<String>{'','Killed','Internally Rejected', 'Externally Rejected'};


        //quantity rule tweak
        for (cscfga__rule__c rule : def.cscfga__rules__r) {
                rule.cscfga__active__c = false;    
        }
        update def.cscfga__rules__r;

        strQuery =   'SELECT ID, ' +
                '       Product_ID__c, cscfga__configuration_status__c, ' +
                '       cscfga__Product_Definition__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.Name,' +
                '       (SELECT Id, cscfga__Value__c, cscfga__Attribute_Definition__c' +
                '        FROM cscfga__Attributes__r ' +
                '        WHERE Name = \'Product\')' +
                ' FROM cscfga__Product_Configuration__c' +
                ' WHERE ' +
                '  ((cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.StageName NOT IN :OppStageList AND ' +
                ' cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c NOT IN :SOStatusList and ' +
                '  (cscfga__originating_offer__c = null or cscfga__originating_offer__r.cscfga__active__c = true))'+
                ' or (cscfga__Configuration_Offer__c != null and cscfga__Configuration_Offer__r.cscfga__active__c = true))' +
                ' AND cscfga__Product_Definition__c = :origProdDef ';
    }

    global CS_UpgradeOpenProductsBatch(Boolean allInvalid) {
        OppStageList = new Set<String>{'Closed Won','Closed Lost'};
        SOStatusList = new Set<String>{'','Killed','Internally Rejected', 'Externally Rejected'};

        //quantity rule tweak
        for (cscfga__rule__c rule : def.cscfga__rules__r) {
                rule.cscfga__active__c = false;    
        }
        update def.cscfga__rules__r;

        strQuery =   'SELECT ID, ' +
                '       Product_ID__c, cscfga__configuration_status__c, ' +
                '       cscfga__Product_Definition__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.Name,' +
                '       (SELECT Id, cscfga__Value__c, cscfga__Attribute_Definition__c' +
                '        FROM cscfga__Attributes__r ' +
                '        WHERE Name = \'Product\')' +
                ' FROM cscfga__Product_Configuration__c' +
                ' WHERE cscfga__configuration_status__c = \'Incomplete\' and' +
                '  ((cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.StageName NOT IN :OppStageList AND ' +
                ' cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c NOT IN :SOStatusList and ' +
                '  (cscfga__originating_offer__c = null or cscfga__originating_offer__r.cscfga__active__c = true))'+
                ' or (cscfga__Configuration_Offer__c != null and cscfga__Configuration_Offer__r.cscfga__active__c = true))';
        system.debug(strQuery);
    }

    // IV
    global CS_UpgradeOpenProductsBatch(list<ID> pcList) {

        productConfigIds = new set<ID>();
        productConfigIds.addAll(pcList);

        //quantity rule tweak
       for (cscfga__rule__c rule : def.cscfga__rules__r) {
                rule.cscfga__active__c = false;    
        }
        update def.cscfga__rules__r;

        strQuery =   'SELECT ID, ' +
                '       Product_ID__c,cscfga__configuration_status__c, ' +
                '       cscfga__Product_Definition__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.Name,' +
                '       (SELECT Id, cscfga__Value__c, cscfga__Attribute_Definition__c' +
                '        FROM cscfga__Attributes__r ' +
                '        WHERE Name = \'Product\')' +
                ' FROM cscfga__Product_Configuration__c' +
                ' WHERE Id = :productConfigIds';
    }

    // prepare select of eligible Sales Orders and then return all the related product configurations;
    global Database.QueryLocator start(Database.BatchableContext BC)
    {

        return Database.getQueryLocator(strQuery);

    }

    global void execute(Database.BatchableContext BC, List<cscfga__Product_Configuration__c> scope)
    {

        //UtilMethods.runProductDefinitionUpgrade(UtilMethods.runProductAttrUpgrade(scope));
        List<cscfga__Product_Configuration__c> scopeWithProductNode =  UtilMethods.runProductAttrUpgrade(scope);
    }

    global void finish(Database.BatchableContext BC)
    {
        // def object must exist from execution start, otherwise the validation will fail
        // therefore no check for def record is happening
        for (cscfga__rule__c rule : def.cscfga__rules__r) {
                rule.cscfga__active__c = true;    
        }
        update def.cscfga__rules__r;
    }
}
/**
 * Created by petar.mikic on 20/09/2017.
 */

global class CS_UpgradeStartedCampaignBatch implements Database.Batchable<sObject>, Database.Stateful
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

    global CS_UpgradeStartedCampaignBatch()
    {
        //excluding set of stages for select, so empty status used for orphan configurations
        OppStageList          = new Set<String>{'Closed Won'};
        SOStatusList          = new Set<String>{'Manually Approved', 'Externally Approved'};

        //quantity rule tweak
        for (cscfga__rule__c rule : def.cscfga__rules__r) {
                rule.cscfga__active__c = false;    
        }
        update def.cscfga__rules__r;
                
        strQuery = 'SELECT ID, ' +
                '       Product_ID__c, cscfga__configuration_status__c, ' +
                '       cscfga__Product_Definition__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.Name,' +
                '       (SELECT Id, cscfga__Value__c, cscfga__Attribute_Definition__c' +
                '        FROM cscfga__Attributes__r ' +
                '        WHERE Name = \'Product\')' +
                ' FROM cscfga__Product_Configuration__c' +
                ' WHERE cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.StageName IN :OppStageList ' +
                ' AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.OpportunityGroup__c = \'NewsXtend\' ' +
                ' AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c IN :SOStatusList ' +
                ' AND cscfga__Product_Definition__c =:origProdDef ';
    }

    global CS_UpgradeStartedCampaignBatch(Boolean allInvalid) {
        OppStageList          = new Set<String>{'Closed Won'};
        SOStatusList          = new Set<String>{'Manually Approved', 'Externally Approved'};

        //quantity rule tweak
       for (cscfga__rule__c rule : def.cscfga__rules__r) {
                rule.cscfga__active__c = false;    
        }
        update def.cscfga__rules__r;

        strQuery = 'SELECT ID, ' +
                '       Product_ID__c, cscfga__configuration_status__c, ' +
                '       cscfga__Product_Definition__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.Name,' +
                '       (SELECT Id, cscfga__Value__c, cscfga__Attribute_Definition__c' +
                '        FROM cscfga__Attributes__r ' +
                '        WHERE Name = \'Product\')' +
                ' FROM cscfga__Product_Configuration__c' +
                ' WHERE cscfga__configuration_status__c = \'Incomplete\' ' +
                ' AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.StageName IN :OppStageList ' +
                ' AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.OpportunityGroup__c = \'NewsXtend\' ' +
                ' AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c IN :SOStatusList ';

    }

    global CS_UpgradeStartedCampaignBatch(list<ID> pcIds)
    {
        productConfigIds = new set<ID>();
        productConfigIds.addAll(pcIds);

        //quantity rule tweak
       for (cscfga__rule__c rule : def.cscfga__rules__r) {
                rule.cscfga__active__c = false;    
        }
        update def.cscfga__rules__r;

        strQuery = 'SELECT ID, ' +
                '       Product_ID__c, cscfga__configuration_status__c, ' +
                '       cscfga__Product_Definition__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c,' +
                '       cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.Name,' +
                '       (SELECT Id, cscfga__Value__c, cscfga__Attribute_Definition__c' +
                '        FROM cscfga__Attributes__r ' +
                '        WHERE Name = \'Product\')' +
                ' FROM cscfga__Product_Configuration__c' +
                ' WHERE Id in :productConfigIds';
    }

    // prepare select of eligible Sales Orders and then return all the related product configurations;
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(strQuery);
    }

    global void execute(Database.BatchableContext BC, List<cscfga__Product_Configuration__c> scope)
    {

        List<cscfga__Product_Configuration__c> scopeWithProductNode =  UtilMethods.runProductAttrUpgrade(scope);

        Set<ID> pcIDs = new  Set<Id>();



        for(cscfga__Product_Configuration__c configScope : scopeWithProductNode) {

            pcIDs.add(configScope.id);
        }

        //running validation after all
        //cscfga.ProductConfigurationBulkActions.revalidateConfigurationsAsync(pcIDs);



    }

    global void finish(Database.BatchableContext BC)
    {
        // def object must exist regardless of constructor call, otherwise the validation will fail
        // therefore no check for def record is happening

       for (cscfga__rule__c rule : def.cscfga__rules__r) {
                rule.cscfga__active__c = true;    
        }
        update def.cscfga__rules__r;

    }
}
/**
 * Created by petar.mikic on 27/09/2017.
 */

global class CS_UpgradeFinalizeProdDefBatch  implements  Database.Batchable<sObject>{
    private Integer useScale = 2;
    
    
    global CS_UpgradeFinalizeProdDefBatch() {}
    
    global CS_UpgradeFinalizeProdDefBatch(Integer useScale) {
        this.useScale = useScale;
    }
    
    // prepare
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        //search only for replacement product definition
        String newProdDef = [SELECT cscfga__Original_Definition__c,
                cscfga__Replacement_Definition__c
        FROM  cscfga__Product_Definition_Version__c LIMIT 1].cscfga__Replacement_Definition__c;

        Set<String> attNames = new Set<String>{'Basic Price','Price', 'Discount'};




        return Database.getQueryLocator([SELECT Id,
                                                Name, cscfga__Label__c,
                                                cscfga__Description__c,
                                                (SELECT ID FROM cscfga__Attribute_Definitions__r WHERE Name IN :attNames)
                                                FROM cscfga__Product_Definition__c WHERE ID =: newProdDef]);
    }
    /*
    *
     */
    global void execute(Database.BatchableContext BC, List<cscfga__Product_Definition__c> scope)
    {
        if (!scope.isEmpty()) {
            List<cscfga__Attribute_Definition__c> priceAttDefs = new List<cscfga__Attribute_Definition__c>();

            for (cscfga__Product_Definition__c prodDef: scope) {
                System.debug('* * * prod Def: ' + prodDef);

                for (cscfga__Attribute_Definition__c attDef: prodDef.cscfga__Attribute_Definitions__r) {
                    System.debug('* * * att: ' + attDef);
                    attDef.cscfga__Scale__c = useScale;
                    priceAttDefs.add(attDef);
                    System.debug('* * att: ' + attDef);
                }

                prodDef.Name             = prodDef.cscfga__Description__c;
                prodDef.cscfga__Label__c = prodDef.cscfga__Description__c;

                System.debug('* * prod Def: ' + prodDef);
            }

            update priceAttDefs;

            update scope;
        }




    }

    global void finish(Database.BatchableContext BC)
    {

    }

}
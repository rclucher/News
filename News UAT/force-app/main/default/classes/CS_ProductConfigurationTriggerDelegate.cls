public with sharing class CS_ProductConfigurationTriggerDelegate extends CS_TriggerHandler.DelegateBase
{
    Map<Id, Id> pcWithProductId;
    Map<Id, Id> deletepcWithProductId;
    Set<Id> basketIds;
    Set<Id> setPCId; //added by Davor Dubokovic as a part of SFE-860
    List<Id> soIds;
    Map<Id,Set<String>> soPlatformsMap;
    Map<Id,Set<String>> soDurationsMap;
    Map<Id, cscfga__Product_Configuration__c> undeletedPC;
    //NX-1504
    List<csmso__Sales_Order__c> overallSalesOrders; //for update sales order list (i.e. call tracking, platform, status...
    Boolean hasRetractionBlocked;

    public override void prepareBefore() {
        deletepcWithProductId = new Map<Id, Id>();
        basketIds             = new Set<Id>();
        setPCId               = new Set<Id>(); //added by Davor Dubokovic as a part of SFE-860
        soPlatformsMap        = new Map<Id,Set<String>>();
        soDurationsMap        = new Map<Id,Set<String>>();
    }

    public override void prepareAfter() {
        pcWithProductId = new Map<Id, Id>();
        undeletedPC = new Map<Id, cscfga__Product_Configuration__c>();
        basketIds       = new Set<Id>();
        setPCId         = new Set<Id>(); //added by Davor Dubokovic as a part of SFE-860
        soPlatformsMap  = new Map<Id,Set<String>>();
        soDurationsMap  = new Map<Id,Set<String>>();
    }

    public override void beforeInsert(SObject o) {
        cscfga__Product_Configuration__c newPC = (cscfga__Product_Configuration__c)o;

        //system.debug('****** beforeInsert ***'+ newPC);

        newPC.OwnerID = UserInfo.getUserId();
        //replacing Update Quantity WF with trigger AB 08-11-2018
        newPC.Quantity__c = newPC.Product_Quantity__c;
        //system.debug('****** beforeInsert 2 ***'+ newPC);
    }

    public override void beforeUpdate(sObject pcOld, sObject pcNew) {
        cscfga__Product_Configuration__c newPC = (cscfga__Product_Configuration__c)pcNew;
        //replacing Update Quantity WF with trigger AB 08-11-2018
        newPC.Quantity__c = newPC.Product_Quantity__c;
    }

    public override void afterUpdate(sObject pcOld, sObject pcNew) {
        cscfga__Product_Configuration__c oldPC = (cscfga__Product_Configuration__c)pcOld;
        cscfga__Product_Configuration__c newPC = (cscfga__Product_Configuration__c)pcNew;

        if (newPC.Product_ID__c != null && oldPC.Product_ID__c != newPC.Product_ID__c) {
            pcWithProductId.put(newPC.cscfga__Product_Basket__c, newPC.Product_ID__c);
        }

        // to mark call tracking for offer configs
        if (newPC.cscfga__originating_offer__c != null && oldPC.cscfga__originating_offer__c != null) {
            pcWithProductId.put(newPC.cscfga__Product_Basket__c, newPC.Product_ID__c);
        }
        basketIds.add(newPC.cscfga__Product_Basket__c);
    }

    public override void beforeDelete(sObject pcO) {
        cscfga__Product_Configuration__c oPC = (cscfga__Product_Configuration__c)pcO;
        basketIds.add(oPC.cscfga__Product_Basket__c);
        deletepcWithProductId.put(oPC.Id, oPC.Product_ID__c);
        setPCId.add(oPC.Id); //added by Davor Dubokovic as a part of SFE-860

        hasRetractionBlocked = false; //NX-1504 added by Petar Mikic
    }

    public override void afterDelete(sObject pcO) {
        cscfga__Product_Configuration__c oPC = (cscfga__Product_Configuration__c)pcO;
        basketIds.add(oPC.cscfga__Product_Basket__c);

        if(undeletedPC == null){
            undeletedPC = new Map<Id, cscfga__Product_Configuration__c>();
        }
        if(oPC.Sales_Order_Status__c == 'Retracted' || oPC.Sales_Order_Status__c == 'Retraction Blocked'){
            hasRetractionBlocked = oPC.Sales_Order_Status__c == 'Retraction Blocked'; //NX-1504 added by Petar Mikic
            undeletedPC.put(oPC.Id,oPC);
        }

    }

    public override void afterInsert(sObject pcO) {
        cscfga__Product_Configuration__c oPC = (cscfga__Product_Configuration__c)pcO;
        basketIds.add(oPC.cscfga__Product_Basket__c);
        setPCId.add(oPC.Id); //added by Davor Dubokovic as a part of SFE-860
        pcWithProductId.put(oPC.ID, oPC.Product_ID__c);

    }

    public override void finish() {
        MarkCallTracking();
        /*if (pcWithProductId!= null && !pcWithProductId.isEmpty()) {
        }

        if (deletepcWithProductId != null && !deletepcWithProductId.isEmpty()) {
            UnmarkCallTracking();
        }*/

        /*if (!basketIds.isEmpty()) {
            List<cscfga__Product_Configuration__c> pcList = getProductConfigs(basketIds);
            List<csmso__Sales_Order__c> soList            = new List<csmso__Sales_Order__c>();

            if (!pcList.isEmpty() ) {
                for (cscfga__Product_Configuration__c pc : pcList) {
                    String platform = ( String.isEmpty(pc.Line_Item_Platform__c) ) ? 'Xtend' : pc.Line_Item_Platform__c;
                    soPlatformsMap.put(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c, calculateConfigSet(soPlatformsMap,pc, platform ));
                    soDurationsMap.put(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c, calculateConfigSet(soDurationsMap,pc, String.valueOf(pc.Duration_Months__c)));
                }

                soList = [SELECT Id FROM csmso__Sales_Order__c WHERE Id IN: soPlatformsMap.keySet()];
                for (csmso__Sales_Order__c so: soList) {
                    so.Platform_Set__c =  getStringSetValue(soPlatformsMap.get(so.Id));
                    so.Duration_Set__c =  getStringSetValue(soDurationsMap.get(so.Id));
                }
            } else {

                //if empty SO's clear platform set
                for (cscfga__Product_Basket__c pb : [Select ID, csmso__Sales_Order__c FROM cscfga__Product_Basket__c
                                                     Where ID IN: basketIds]) {

                    soList.add(new csmso__Sales_Order__c(
                                   Id = pb.csmso__Sales_Order__c,
                                   Platform_Set__c = '',
                                   Duration_Set__c = ''));
                }
            }
            update soList;
        }
        System.debug('***setPCId='+setPCId);*/

        //added by Davor Dubokovic as a part of SFE-860
        if (setPCId.size()>0)
            CS_AllAttributeTriggerHelper.ResetSalesOrder(setPCId);
        //end of added code for SFE-860

        // kw: xtend order amendment
        if(undeletedPC != null && undeletedPC.size() > 0){
            CS_ProductConfigurationTriggerDelegate.undeletePcRetracted(undeletedPC.keyset());

            if (hasRetractionBlocked) {
               handleRetractionBlocked(getProductConfigs(basketIds));
            }
        }

        //NR-1930 Configuration_to_Basket_mapping field set logic migrated from CS_AllProductBasketTriggers
        //and replaced by new approach (using Object_Field_Update_Mapping__mdt custom metadata configs)
        if (Trigger.isAfter) {
            ObjectFieldUpdateMappingHandler mappingHandler = new ObjectFieldUpdateMappingHandler(null);
            //execute all active mapping configurations for our source object
            mappingHandler.execute();

            // refactor as part of NX-1504
            if (!overallSalesOrders.isEmpty()) {
                update overallSalesOrders;
            }
        }


    }

    // kw: xtend order amendment
    @future
    static void undeletePcRetracted(Set<Id> pcIDs){
        List<cscfga__Product_Configuration__c> deletedPC = [Select Id From cscfga__Product_Configuration__c Where Id IN: pcIDs ALL ROWS];
        undelete deletedPC;

        for(cscfga__Product_Configuration__c pc: deletedPC){
            pc.cscfga__Product_Basket__c = null;
        }
        update deletedPC;
    }

    /*void UnmarkCallTracking() {
        List<cscfga__Product_Configuration__c> pcList = getProductConfigs(basketIds);

        List<cscfga__Product_Configuration__c> restOfPCs           = new List<cscfga__Product_Configuration__c>();
        Map<id, list<cscfga__Product_Configuration__c>> pcsWithSOs = new Map<id, list<cscfga__Product_Configuration__c>>();

        for (cscfga__Product_Configuration__c pc : pcList) {
            list<cscfga__Product_Configuration__c> pcs = pcsWithSOs.get(pc.Id);
            if (pcs == null) {
                pcs = new list<cscfga__Product_Configuration__c>();
            }
            pcs.add(pc);
            pcsWithSOs.put(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c,pcs);
        }
        List<id> soEmpty = new list<id>();
        for (id soid : pcsWithSOs.keySet()) {
            id temp = pcsWithSOs.get(soid)[0].id;
            if (pcsWithSOs.get(soid).size() == 1 && deletepcWithProductId.containsKey(temp))
                soEmpty.add(soid);
            else
                restOfPCs.addAll(pcsWithSOs.get(soid));
        }

        if (!soEmpty.isEmpty()) {
            list<csmso__Sales_Order__c> soList = [select id, Call_Tracking__c from csmso__Sales_Order__c where id IN: soEmpty];
            for (csmso__Sales_Order__c so : soList) {
                so.Call_Tracking__c = false;
                so.Platform_Set__c  = '';
                so.Duration_Set__c  = '';
            }
            update soList;
        }

        List<Id> productIds = deletepcWithProductId.values();
        CalculateCallTracking(restOfPCs, productIds);
    }*/

    void MarkCallTracking() {
        List<cscfga__Product_Configuration__c> pcList = getProductConfigs(basketIds);
        List<Id> productIds                           = new list <Id>();

        for (cscfga__Product_Configuration__c pc : pcList) {
            productIds.add(pc.Product_ID__c);
        }

        CalculateCallTracking(pcList, productIds);
    }

    void CalculateCallTracking (List<cscfga__Product_Configuration__c> pcList, List<Id> productIds) {
        Set<Id> soIds               = new Set<Id>();
        Map<Id, Set<Id>> soProductId = new Map<Id, Set<Id>>();  // Sales Order ID --> Product IDs Map

        for (cscfga__Product_Configuration__c pc : pcList) {
            soIds.add(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c);

            Set<Id> ids = soProductId.get(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c);

            if (ids == null) {
                ids = new Set<id>();
            }
            ids.add(pc.Product_ID__c);
            soProductId.put(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c, ids);

            //platform set
            String platform = ( String.isEmpty(pc.Line_Item_Platform__c) ) ? 'Xtend' : pc.Line_Item_Platform__c;
            soPlatformsMap.put(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c, calculateConfigSet(soPlatformsMap,pc, platform) );

            //duration months set
            soDurationsMap.put(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c, calculateConfigSet(soDurationsMap,pc, String.valueOf(pc.Duration_Months__c)));

        }

        //handle emptied basket
        if (soIds.isEmpty() && !basketIds.isEmpty()) {
            List<cscfga__Product_Basket__c> product_baskets = [SELECT Id,csmso__Sales_Order__c FROm cscfga__Product_Basket__c WHERE Id IN:basketIds];

            for(cscfga__Product_Basket__c pb: product_baskets) {
                soIds.add(pb.csmso__Sales_Order__c);
            }
        }

        // Get Sales Order List based on Sales Order IDs extracted from <cscfga__Product_Configuration__c> pcList
        //
        overallSalesOrders = getSalesOrders(soIds);

        // Get Product Node Map IDs for productIds from the argument where Product Line = Search and Product Type = SEM
        Map<Id, csmso__Product_Node__c> productNodeProducts = new Map<Id, csmso__Product_Node__c>(
            [SELECT Id FROM csmso__Product_Node__c WHERE Id IN:productIds AND Product_Line__c = 'Search' AND Product_Type__c = 'SEM']);

        // Set Sales Order Call_Tracking__c attribute to True for every Sales Order in Product Configuration that contains
        // a product with Product Line = Search and Product Type = SEM
        for (csmso__Sales_Order__c so : overallSalesOrders) {
            Boolean hasCT = false;
            so.Call_Tracking__c = false;

            if(! soProductId.isEmpty()) {

                for (Id tId : soProductId.get(so.id)) {
                    if (productNodeProducts.containsKey(tId)) {
                        hasCT = true;
                        break;
                    }
                }
            }

            so.Call_Tracking__c = hasCT;
            so.Platform_Set__c  = getStringSetValue(soPlatformsMap.get(so.Id));
            so.Duration_Set__c  = getStringSetValue(soDurationsMap.get(so.Id));
        }

        //update overallSalesOrders;
    }

    Set<String> calculateConfigSet(Map<Id,Set<String>> soCfgValueSet, cscfga__Product_Configuration__c pc, String newValue){

        Set<String> pcValuesSet = soCfgValueSet.get(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c);

        if (pcValuesSet == null) {
            pcValuesSet = new Set<String>();
        }
        //ignoring bundle values
        if (!pc.Bundle_Item__c) {
            pcValuesSet.add(newValue);
        }

        return pcValuesSet;
    }



    String getStringSetValue(Set<String> platformNamesSet) {
        //platform set
        String platformSet = String.valueOf(platformNamesSet);
        //System.debug('Calculate CAll Tracking for so '+ platformSet);
        return (platformSet == '{}') ? '' : platformSet;
    }


    public List<cscfga__Product_Configuration__c> getProductConfigs(Set<Id> basketIDSet) {
        return [SELECT Id, Product_ID__c, Bundle_Item__c, Line_Item_Platform__c, Duration_Months__c,
                cscfga__Product_Basket__r.csmso__Sales_Order__c,IsArchived_Catalogue_Item__c
                FROM cscfga__Product_Configuration__c
                WHERE cscfga__Product_Basket__c IN:basketIDSet];
    }


    public List<csmso__Sales_Order__c> getSalesOrders(Set<Id> soIds) {
        return [SELECT Id, csmso__Status__c, Call_Tracking__c, Retraction_On__c
                FROM csmso__Sales_Order__c
                WHERE Id IN: soIds];
    }

    public void handleRetractionBlocked(List<cscfga__Product_Configuration__c> pcList) {
        //System.debug('NX-1504 handling retraction blocked with total SOs "' + overallSalesOrders.size() + '" and total PCs "' + pcList.size() + '"');
        Map<Id,List<cscfga__Product_Configuration__c>> soIdWithPCs = new Map<Id,List<cscfga__Product_Configuration__c>>();
        Id soID = null;

        for (cscfga__Product_Configuration__c pc : pcList){

            soID = pc.cscfga__Product_Basket__r.csmso__Sales_Order__c;

            if ( !soIdWithPCs.containsKey(soID) ) {
                soIdWithPCs.put(soID,new List<cscfga__Product_Configuration__c>());
            }

            soIdWithPCs.get(soID).add(pc);

        }

        //using the forUpdate sales order list to handle the status update
        for (csmso__Sales_Order__c so: overallSalesOrders ) {
            if (so.csmso__Status__c !='Retraction Blocked') continue;

            Boolean stillBlocked = false;

            // evaluate each so's line if one of those is still archived
            if( soIdWithPCs.containsKey(so.ID) ) {
                for (cscfga__Product_Configuration__c pc: soIdWithPCs.get(so.ID)){
                    stillBlocked = pc.IsArchived_Catalogue_Item__c;
                }
            }

            if (stillBlocked) {
                continue;
            }else {
                so.csmso__Status__c = (so.Retraction_On__c =='Active Campaign') ? 'Retracted' : 'Draft';
            }

        }


    }
}
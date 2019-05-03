/*
 * SalesOrder_Helper
 *
 * Handler Class for the csmso__Sales_Order__c custom object trigger
 *
 * PLEASE PLACE ALL LOGIC IN THIS HANDLER CLASS. TRIGGER: SalesOrder_Helper_Trigger
 *
 * Change history:
 *
 * #16/09/2016
 * @author     Peter Charalambous <peter.charalambous@bluewolf.com>
 * @author     David Dawson <david.dawson@bluewolf.com>
 *             - Created initial version of trigger and handler class
 *             - SalesOrder_Helper functionality added
 * #29/09/2016
 * @author     Calvin Noronha <calvin.noronha@bluewolf.com>
 *             - Bulkified trigger and implemented best coding practises
 * #27/10/2016
 * @author     David Dawson <david.dawson@bluewolf.com>
 *             - Moved functionality into trigger handler to ensure no logic is in trigger
 * @author     Peter Charalambous <peter.charalambous@bluewolf.com>
 *             - Added archive functionallity
 */

public class SalesOrder_Helper {
    //globals
    public static final String PRINT_STATUS_RECALC = 'Requires discount recalculation.';
    public static Set<Id> soWithCampaignChange = new Set<Id>();
    //status values that drive automatic sync/desync with opportunity
    public static final Set<String> APPROVED_STATUS_SET = new Set<String>{'Manually Approved', 'Externally Approved'};
    //status set that will trigger SO to Opp sync but only if current SO was previously synced or there are no synced SOs for that Opp
    public static final Set<String> AUTOSYNC_STATUS_SET = new Set<String>{'Sent For Internal Approval', 'Sent For External Approval'};
    public static final Set<String> DESYNC_STATUS_SET = new Set<String>{'Killed'};
    
    /* replaced by syncWithOpportunity
    public static void opportunityHasApprovedSO(List<csmso__Sales_Order__c> triggerNew, Map<Id, csmso__Sales_Order__c> triggerOldMap){
        Set<Id> oppIdToUpdate = new Set<Id>();
        for (csmso__Sales_Order__c so : triggerNew) {
            //if status was changed and it is in approved status list then include in the logic
            if (so.csmso__Status__c != triggerOldMap.get(so.Id).csmso__Status__c &&
                APPROVED_STATUS_SET.contains(so.csmso__Status__c) &&
                !APPROVED_STATUS_SET.contains(triggerOldMap.get(so.Id).csmso__Status__c)) {
                oppIdToUpdate.add(so.csmso__Opportunity__c);
            }
        }
        //update only when required, SOQL is cheaper than DML that runs all the triggers again
        if (!oppIdToUpdate.isEmpty()) {
            List<Opportunity> oppToUpdate = [SELECT Id, Has_an_Approved_SO__c
                                             FROM Opportunity
                                             WHERE Id IN :oppIdToUpdate AND Has_an_Approved_SO__c = false];
            for (Opportunity opp : oppToUpdate) {
                opp.Has_an_Approved_SO__c = true;
            }
            if (!oppToUpdate.isEmpty()) {
                update oppToUpdate;
            }
        }
    }

    public static void opportunityHasApprovedSOAfter(Boolean isUpdate, Boolean isInsert, Boolean isDelete, Boolean isUnDelete, List<csmso__Sales_Order__c> triggerNew, Map<Id, csmso__Sales_Order__c> triggerOldMap){
        Set<Id> oppIdsToCheck = new Set<Id>();

        if (isUpdate) {
            for (csmso__Sales_Order__c so : triggerNew) {
                // when Sales Order Status is changed from Externally Approved to some Other Status
                if (APPROVED_STATUS_SET.contains(triggerOldMap.get(so.Id).csmso__Status__c) && !APPROVED_STATUS_SET.contains(so.csmso__Status__c)) {
                    oppIdsToCheck.add(so.csmso__Opportunity__c);
                }
            }
        }

        if (isDelete) {
            for (csmso__Sales_Order__c so : (List<csmso__Sales_Order__c>)trigger.old) {
                oppIdsToCheck.add(so.csmso__Opportunity__c);
            }
        }

        if (!oppIdsToCheck.isEmpty()) {
            Set<Id> oppIdsToUpdate = new Set<Id>();

            List<csmso__Sales_Order__c> orders = [SELECT Id, csmso__Opportunity__c, csmso__Status__c
                                                  FROM csmso__Sales_Order__c
                                                  WHERE csmso__Opportunity__c IN :oppIdsToCheck];

            if (!orders.isEmpty()) {
                Map<Id, List<csmso__Sales_Order__c>> oppToOrdersMap = new Map<Id, List<csmso__Sales_Order__c>>();
                for (csmso__Sales_Order__c so : orders) {
                    if (oppToOrdersMap.get(so.csmso__Opportunity__c) == null) {
                        oppToOrdersMap.put(so.csmso__Opportunity__c, new List<csmso__Sales_Order__c>());
                    }
                    oppToOrdersMap.get(so.csmso__Opportunity__c).add(so);
                }
                for (Id oppId : oppToOrdersMap.keySet()) {
                    Boolean oppHasApprovedSo = false;
                    for (csmso__Sales_Order__c so : oppToOrdersMap.get(oppId)) {
                        if (APPROVED_STATUS_SET.contains(so.csmso__Status__c)) { //T-28931
                            oppHasApprovedSo = true;
                        }
                    }

                    if (!oppHasApprovedSo) {
                        oppIdsToUpdate.add(oppId);
                    }
                }
                //update only when required, SOQL is cheaper than DML that runs all the triggers again
                if (!oppIdsToUpdate.isEmpty()) {
                    List<Opportunity> oppToUpdate = [SELECT Id, Has_an_Approved_SO__c
                                                     FROM Opportunity
                                                     WHERE Id IN :oppIdsToUpdate AND Has_an_Approved_SO__c = true];
                    for (Opportunity opp : oppToUpdate) {
                        opp.Has_an_Approved_SO__c = false;
                    }
                    if (!oppToUpdate.isEmpty()) {
                        update oppToUpdate;
                    }
                }
            }
        }
    }
    end of replaced by syncWithOpportunity*/

    /**
     *
     *
     * @param salesOrder Sales order that has a Print Discount Percentage value
     * test covered in ButtonSOPricingCalculatorTest class
     */
    // 16/03/2018 Igor Vrabec: Commented out this method since ButtonSOPricingCalculator that calls it is not a part of the current deployment
    public static void propagateProposedPrintDiscount(csmso__Sales_Order__c salesOrder) {

        List<String> attNames = new List<String>{'Ad Size Rate Card', 'Proposed Discount Percentage', 'Proposed Discount Amount','Proposed Discount Amount Old','Proposed Discount Percentage Old','Price','Total Duration Price'}; //07/05/2018 IG removed 'Total Price'

        Map<ID,cscfga__Product_Configuration__c> printProdConfigsMap;

        // Select Attributes with Order by name
        //0 Ad Size Rate Card
        //1 Price
        //2 Proposed Discount Amount
        //3 Proposed Discount Amount Old
        //4 Proposed Discount Percentage
        //5 Proposed Discount Percentage Old
        //6 Total Price //07/05/2018 IG: Commented out
        printProdConfigsMap = new Map<ID,cscfga__Product_Configuration__c>(
            [SELECT ID,
             cscfga__Product_Basket__r.csmso__Sales_Order__c,
             cscfga__Product_Bundle__c,
             cscfga__Configuration_Offer__c,
             (SELECT Id, cscfga__Value__c
              FROM cscfga__Attributes__r
              WHERE Name IN:attNames ORDER BY NAME)
             FROM cscfga__Product_Configuration__c
             WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c = : salesOrder.Id
                                                                     AND cscfga__Product_Definition__r.Name = 'Print Display' //07/05/2018 IG:Updated to Print Display
                                                                                                              AND Platform__c = 'Print']);

        List<cscfga__Attribute__c> attributesToUpdate = new List<cscfga__Attribute__c>();

        for (cscfga__Product_Configuration__c pc: printProdConfigsMap.values()) {

            Decimal adSizeRateCard = Decimal.valueOf(pc.cscfga__Attributes__r[0].cscfga__Value__c);

            //2 Proposed Discount Amount
            Decimal discountAmmount = (salesOrder.Proposed_Print_Discount__c * adSizeRateCard) / 100;
            pc.cscfga__Attributes__r[2].cscfga__Value__c         = String.valueOf(discountAmmount);
            pc.cscfga__Attributes__r[2].cscfga__Display_Value__c = pc.cscfga__Attributes__r[2].cscfga__Value__c;

            //3 Proposed Discount Amount Old > get from 2
            pc.cscfga__Attributes__r[3].cscfga__Value__c         = pc.cscfga__Attributes__r[2].cscfga__Value__c;
            pc.cscfga__Attributes__r[3].cscfga__Display_Value__c = pc.cscfga__Attributes__r[2].cscfga__Value__c;

            //4 Proposed Discount Percentage
            pc.cscfga__Attributes__r[4].cscfga__Value__c         = String.valueOf(salesOrder.Proposed_Print_Discount__c);
            pc.cscfga__Attributes__r[4].cscfga__Display_Value__c = pc.cscfga__Attributes__r[4].cscfga__Value__c;

            //5 Proposed Discount Percentage Old > get from 4
            pc.cscfga__Attributes__r[5].cscfga__Value__c         = pc.cscfga__Attributes__r[4].cscfga__Value__c;
            pc.cscfga__Attributes__r[5].cscfga__Display_Value__c = pc.cscfga__Attributes__r[4].cscfga__Value__c;

            //6 Price
            pc.cscfga__Attributes__r[1].cscfga__Value__c         = String.valueOf( adSizeRateCard - discountAmmount );
            pc.cscfga__Attributes__r[1].cscfga__Display_Value__c = pc.cscfga__Attributes__r[1].cscfga__Value__c;

            /*
               //07/05/2018 IG: Commented out
               //6 Total Price
               pc.cscfga__Attributes__r[6].cscfga__Value__c = String.valueOf( adSizeRateCard - discountAmmount );
               pc.cscfga__Attributes__r[6].cscfga__Display_Value__c = pc.cscfga__Attributes__r[6].cscfga__Value__c;

               //1 Price   - set to Total Price value
               pc.cscfga__Attributes__r[1].cscfga__Value__c         = pc.cscfga__Attributes__r[6].cscfga__Value__c;
               pc.cscfga__Attributes__r[1].cscfga__Display_Value__c = pc.cscfga__Attributes__r[6].cscfga__Value__c;
             */
            System.debug(' ---+ ovo je adSizeRateCard = ' + adSizeRateCard);
            System.debug(' ---+ ovo je discountAmmount = ' + discountAmmount);
            pc.cscfga__Attributes__r[6].cscfga__Value__c         = String.valueOf( adSizeRateCard - discountAmmount );
            pc.cscfga__Attributes__r[6].cscfga__Display_Value__c = pc.cscfga__Attributes__r[6].cscfga__Value__c;

            attributesToUpdate.addAll(pc.cscfga__Attributes__r);
        }
    }

    public static void recountDiscountValues(Map<Id, csmso__Sales_Order__c> triggerNewMap, Map<Id, csmso__Sales_Order__c> triggerOldMap) {
        Boolean hasPrintDisplay = false;
        List<cscfga__Product_Configuration__c> pcList = new List<cscfga__Product_Configuration__c>();

        for (csmso__Sales_Order__c so: triggerNewMap.values()) {
            /* always resetting target discount values in case products are deleted. If not, they will be recalculated anyhow*/
            /*so.Target_Discount__c         =  so.Calculated_Target_Discount__c;
               so.Proposed_Print_Discount__c =  so.Calculated_Target_Discount__c;*/

            if (so.Basket_Products__c!= null && so.Basket_Products__c.contains('Print Display') && so.Invalid_Config_Count__c != null && so.Invalid_Config_Count__c == 0) {
                hasPrintDisplay = true;
                break;
            }
        }

        if (!hasPrintDisplay) {
            return;
        }
    
        //negotiation points attributes
        if (triggerNewMap != null && !triggerNewMap.isEmpty()) {
            pcList = [SELECT ID, Impressions_Quantity__c, Publication__c, cscfga__Product_Basket__r.csmso__Sales_Order__c
                                                         FROM cscfga__Product_Configuration__c WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c in :triggerNewMap.keySet() AND Platform__c = 'Print'];
        }
        
        Set<String> publicationSet = new Set<String>();
        //map to hold {"soId": numOfInsertions}
        Map<Id,SOWrapper> soToWrapperMap = new Map<Id, SOWrapper>();
        Integer numOfInsertions = 0;
        Id soID                 = null;

        for (cscfga__Product_Configuration__c pc: pcList) {

            soID = pc.cscfga__Product_Basket__r.csmso__Sales_Order__c;

            if (!soToWrapperMap.containsKey(soID)) {
                soToWrapperMap.put(soID,new SOWrapper());
            }

            soToWrapperMap.get(soID).ImpressionsQuantiy += pc.Impressions_Quantity__c != null ? Integer.valueOf(pc.Impressions_Quantity__c) : 0;
            soToWrapperMap.get(soID).PublicationsSet.add(pc.Publication__c);

        }

        Boolean needCVSUpdate =  false;
        
        for (csmso__Sales_Order__c so: triggerNewMap.values()) {
            if (soToWrapperMap.containsKey(so.Id) ) {
                so.Print_Impressions_Count__c = soToWrapperMap.get(so.ID).ImpressionsQuantiy;
                so.Print_Publication_Count__c = soToWrapperMap.get(so.ID).PublicationsSet.size();
            }

            // is print client discount bigger than max discount threshold
            if (so.Client_Current_Discount_FY__c != null && so.Client_Current_Discount_FY__c > so.Calculated_Target_Discount__c) {

                //if any client value point parameter has changed

                if ( (so.Print_Impressions_Count__c != triggerOldMap.get(so.ID).Print_Impressions_Count__c) ||
                     (so.Print_Publication_Count__c != triggerOldMap.get(so.ID).Print_Publication_Count__c) ||
                     (so.Platform_Set__c != triggerOldMap.get(so.ID).Platform_Set__c) ) {

                    so.Print_Status__c = Label.SO_Updated_Client_Value_Points;
                    needCVSUpdate      = true;

                }
            }

            //updating proposed discount % on change
            Decimal proposedAmount       = 0;
            Decimal priceWithoutDiscount = 0;
            
            //if (so.Target_Print_Price__c != triggerOldMap.get(so.ID).Target_Print_Price__c) {

                System.debug('PeroP: Target P P ' + so.Target_Print_Price__c);
                System.debug('PeroP: Total Duration Price ' + so.Total_Print_Duration_Price__c);

                //Added NULL check to get past PROD and Staging code coverage
                if(so.Total_Print_Duration_Price__c != null && so.Target_Print_Price__c != null){
                proposedAmount       = (so.Total_Print_Duration_Price__c - so.Target_Print_Price__c);
                }
                if(so.Total_Print_Duration_Price__c != null){
                priceWithoutDiscount = so.Total_Print_Duration_Price__c;
                }

                if (priceWithoutDiscount!=0) {
                    so.Proposed_Print_Discount__c = ((proposedAmount/priceWithoutDiscount)*100).setScale(2);
                    System.debug('PeroP: Proposed Print Discount ' + so.Proposed_Print_Discount__c);
                } else {
                    so.Proposed_Print_Discount__c = 0;
                }
            //}
        }

        if (needCVSUpdate) {
            Map<String,List<Client_Value_Point__c>> cvpMap = ButtonSOPricingCalculator.getPlatformClientValuePointsMap('Print');

            List<Client_Value_Score__c> cvsList = [SELECT Id,Customer_Tier__c, Points_From__c, Points_To__c, Discount__c
                                                   FROM Client_Value_Score__c
                                                   WHERE Platform__c = 'Print'];

            for (csmso__Sales_Order__c so: triggerNewMap.values()) {
                if (so.Print_Status__c == Label.SO_Updated_Client_Value_Points) {

                    ButtonSOPricingCalculator.runCVSRecalculation(cvpMap,cvsList,so);
                }
            }
        }
    }

    /**
     * Create Opportunity Products based on Sales Order Line Items.
     * Opportunity Products are created once the Sales Order is set to status "Completed". (RQ_0074, RQ_0075)
     *
     * 05/04 PM - changed the method to include old so Map for purposes of escaping recursive update and deletion of OLIs
     */
    /* //commented out as no longer used, will be deleted later on, to uncomment search for "deleteToUncomment"
    public static void createOpportunityProducts(List<csmso__Sales_Order__c> triggerNew, Map<Id,csmso__Sales_Order__c> triggerOldMap ) {

        Map<Id, csmso__Sales_Order__c> appliableSOs = new Map<Id, csmso__Sales_Order__c>();
        Set<Id> opportunityIds                      = new Set<Id>();

        // collect applicable Sales Orders and their Opportunity IDs
        for (csmso__Sales_Order__c so : triggerNew) {
            if ((so.csmso__Status__c == 'Externally Approved' && triggerOldMap.get(so.Id).csmso__Status__c != 'Externally Approved') || (so.csmso__Status__c == 'Manually Approved' && triggerOldMap.get(so.Id).csmso__Status__c != 'Manually Approved')) {
                appliableSOs.put(so.ID, so);
                opportunityIds.add(so.csmso__Opportunity__c);
            }
        }

        List<cscfga__Product_Configuration__c> PCs = new List<cscfga__Product_Configuration__c>();

        if (!appliableSOs.isEmpty()) {
            // Get non-bundle Product Configurations. This will also get related Product Configurations and skip Bundle Line Item PDs
            PCs = [SELECT Id, Name, Line_Item_Platform__c, Publication__c, Bespoke_Digital_Description__c, Line_Item_Price__c,
                   Primary_Product_Opp_Amount_Remainder__c, One_Off_Price__c, cscfga__Parent_Configuration__c,
                   cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Products_Type__c,
                   cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c,
                   cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c,
                   cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Length__c
                   FROM cscfga__Product_Configuration__c
                   WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c = :appliableSOs.keySet() AND Bundle_Item__c = false];
        }

        /*
         * Get Print and Digital Publication Products
         *
         * Get Xtend Publication Products
         * Xtend Sales Order Line Items to map with Publication Product with following criteria (RQ_0079):
         * There is only a single Product (Product2): "Digital - NewsXtend"
         * Match by Publication Name (Publication_Product__c.Publication__c) = "NewsXtend"
         *
         * Print Sales Order Line Items are mapped to Publication Products with following criteria (RQ_0077):
         * Match by Publication Name (Publication__c) or Publication Code (Publication_Code__c)
         * Where Ad Type (Ad_Type__c) is Display
         * Filter by Products that are Active (Product__c.IsActive)
         *
         * Digital Sales Order Line Items to map with Publication Product with following criteria (RQ_0078):
         * Match by Publication Name (Publication__c)
         * Where Ad Type (Ad_Type__c) is Display
         * Filter by Products that are Active (Product__c.IsActive)
         */
        /* deleteToUncomment
        if (!PCs.isEmpty()) {
            Set<String> publicationNames = new Set<String>();

            // get PC Ids
            for (cscfga__Product_Configuration__c PC : PCs) {
                if (PC.Line_Item_Platform__c == 'Print' ||
                    PC.Line_Item_Platform__c == 'Digital' ||
                    PC.Line_Item_Platform__c == 'Xtend') {

                    if (PC.Line_Item_Platform__c == 'Print') {
                        publicationNames.add(PC.Publication__c);
                    } else if (PC.Line_Item_Platform__c == 'Digital') {
                        publicationNames.add(PC.Bespoke_Digital_Description__c);
                    }
                }
            }

            /*
             * Get Publication Products
             */
            /* deleteToUncomment
            // get all Publication Products for PCs in question
            List<Publication_Product__c> publicationProducts = [SELECT Id, Product__c, Publication__c
                                                                FROM Publication_Product__c
                                                                WHERE Product__r.IsActive = true AND (
                                                                    (Publication__c IN :publicationNames AND Ad_Type__c = 'Display') OR Publication__c = 'NewsXtend')];

            // If there are multiple records matching above criteria, get the first record.
            // So using Map with Publication__c as a key is ok. (RQ_0080)
            Map<String, Publication_Product__c> publicationProductsMap = new Map<String, Publication_Product__c>();

            for (Publication_Product__c pp : publicationProducts) {
                publicationProductsMap.put(pp.Publication__c, pp);
            }

            Set<String> missingPublications             = new Set<String>();
            List<OpportunityLineItem> OLIsToInsert      = new list<OpportunityLineItem>();
            Map<Id, OpportunityLineItem> product2OLIMap = new Map<Id, OpportunityLineItem>();  // Product2Id => OpportunityLineItem

            //Map<String, Integer> platformToProductMapXtend = new Map<String, Integer>();
            Integer xtendBundleCount  = 0;
            Integer xtendBespokeCount = 0;

            Map<Id, Map<String, Integer>> platformToProductAll = new Map<Id, Map<String, Integer>>();
            Integer printBundleCount    = 0;
            Integer printBespokeCount   = 0;
            Integer digitalBundleCount  = 0;
            Integer digitalBespokeCount = 0;
            Map<String, Integer> productTypeCounterMap = new Map<String, Integer>();

            // Create OLIs for all Product Configurations
            for (cscfga__Product_Configuration__c PC : PCs) {

                Id product2Id = null;

                // Product__c is Product2Id
                if (PC.Line_Item_Platform__c == 'Print' && publicationProductsMap.containsKey(PC.Publication__c)) {
                    product2Id = publicationProductsMap.get(PC.Publication__c).Product__c;
                } else if (PC.Line_Item_Platform__c == 'Digital' && publicationProductsMap.containsKey(PC.Bespoke_Digital_Description__c)) {
                    product2Id = publicationProductsMap.get(PC.Bespoke_Digital_Description__c).Product__c;
                } else if (PC.Line_Item_Platform__c == 'Xtend' && publicationProductsMap.containsKey('NewsXtend')) {
                    product2Id = publicationProductsMap.get('NewsXtend').Product__c;
                } else {
                    // Prepare mail for System administrator
                    if (PC.Line_Item_Platform__c == 'Print') {
                        missingPublications.add('Opportunity: ' + PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c +
                                                ' - Publication: ' + PC.Line_Item_Platform__c + ' > ' + PC.Publication__c);
                    } else if (PC.Line_Item_Platform__c == 'Digital') {
                        missingPublications.add('Opportunity: ' + PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c +
                                                ' - Publication: ' + PC.Line_Item_Platform__c + ' > ' + PC.Bespoke_Digital_Description__c);
                    }
                }

                if (product2Id != null) {
                    // NR-132 Set new fields on Opportunity Product (Product Type field needs special logic, Source field is set to 'CPQ' value)
                    if (PC.cscfga__Parent_Configuration__c == null) {
                        if (PC.Line_Item_Platform__c == 'Xtend') {
                            xtendBespokeCount++;
                            productTypeCounterMap.put('Bespoke', xtendBespokeCount);
                        } else if (PC.Line_Item_Platform__c == 'Print') {
                            printBespokeCount++;
                            productTypeCounterMap.put('Bespoke', printBespokeCount);
                        } else if (PC.Line_Item_Platform__c == 'Digital') {
                            digitalBespokeCount++;
                            productTypeCounterMap.put('Bespoke', digitalBespokeCount);
                        }
                        platformToProductAll.put(product2Id, productTypeCounterMap);
                    } else if (PC.cscfga__Parent_Configuration__c != null) {
                        if (PC.Line_Item_Platform__c == 'Xtend') {
                            xtendBundleCount++;
                            productTypeCounterMap.put('Bundle', xtendBundleCount);
                        } else if (PC.Line_Item_Platform__c == 'Print') {
                            printBundleCount++;
                            productTypeCounterMap.put('Bundle', printBundleCount);
                        } else if (PC.Line_Item_Platform__c == 'Digital') {
                            digitalBundleCount++;
                            productTypeCounterMap.put('Bundle', digitalBundleCount);
                        }
                        platformToProductAll.put(product2Id, productTypeCounterMap);
                    }

                    /*
                       If Opportunity Product exists (RQ_0077, RQ_0078, RQ_0079):
                       Set Total Revenue Excl (TotalPrice) to Total Revenue Excl + this Sales Order line item amount.

                       Duration (OpportunityLineItem.of_periods__c) field logic (CR_17, TL_146):
                       - for Evergreen: mulitply Monthly price (Line_Item_Price__c) by 12 months
                       - fir Seasonal: multiplies by the duration
                        Duration is taken from csmso__Sales_Order__c.Campaign_Length__c - which used in
                        Print Led/Bundle Led PDs and Bespoke News Xtend, but empty for News Xtend Evergreen PDs
                       For more info see:
                       - csmso__Sales_Order__c.Campaign_Products_Type__c field formula
                       - cscfga__Product_Configuration__c.Line_Item_Price__c field formula

                       Pattern field (API name Pattern__c): Default to "Monthly"
                       Date field (API name ServiceDate): Taken from csmso__Sales_Order__c.Campaign_Start_Date__c,
                                                       available for all PDs
                     */
                    /* deleteToUncomment
                    Decimal duration   = PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Length__c;
                    Decimal totalPrice = 0;

                    //system.debug('SalesOrder_Helper - duration ------------------------- ' + duration);
                    //system.debug('SalesOrder_Helper - line item price ------------------------- ' + PC.Line_Item_Price__c);
                    //system.debug('SalesOrder_Helper - ------------------------- ' + PC);
                    if (PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Products_Type__c == 'Evergreen') {
                        duration = 12;
                    }

                    /*
                     * Total price for current product is calculated by multiplying Line Item Price with the Campaign Length duration
                     * and adding Primary Product Opportunity Amount Remainder if it exists.
                     * This remainder is to fix the difference in total Opportunity Amount caused by rouding the Total Bundle Price and
                     * dividing it by the number of months during product configuration process. (1B_003)
                     */
                     /* deleteToUncomment
                    // NR-214 For Xtend one off product, the calculation is wrong - it shouldn't be multiplied with duration
                    if (PC.Line_Item_Platform__c == 'Xtend' && PC.One_Off_Price__c != null && PC.One_Off_Price__c != 0.00) {
                        totalPrice = PC.Line_Item_Price__c + PC.Primary_Product_Opp_Amount_Remainder__c;
                    } else {
                        totalPrice = (PC.Line_Item_Price__c * duration) + PC.Primary_Product_Opp_Amount_Remainder__c;
                    }

                    // sum up the existing product values
                    if (product2OLIMap.containsKey(product2Id)) {
                        product2OLIMap.get(product2Id).Quantity   += 1;
                        product2OLIMap.get(product2Id).TotalPrice += totalPrice;
                        // product2OLIMap.get(product2Id).of_periods__c = duration;
                    } else {
                        product2OLIMap.put(product2Id,
                                           new OpportunityLineItem(Quantity      = 1,
                                                                   TotalPrice    = totalPrice,
                                                                   of_periods__c = duration,
                                                                   Source__c     = 'CPQ',
                                                                   OpportunityId = PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c,
                                                                   ServiceDate   = PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c,
                                                                   Pattern__c    = 'Monthly'));
                    }
                }
            } // for end

            // NR-132
            // set the values of Product type by created OLI
            for (Id oli : product2OLIMap.keySet()) {
                if (platformToProductAll.containsKey(oli)) {
                    if (platformToProductAll.get(oli).size() > 1) {
                        product2OLIMap.get(oli).Product_Type__c = 'Mixed';
                    } else {
                        for (String type : platformToProductAll.get(oli).keySet()) {
                            product2OLIMap.get(oli).Product_Type__c = type;
                        }

                    }
                }
            }


            /*
             * set Pricebook Etries to all OLIs
             */
            /* deleteToUncomment
            List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id
                                                     FROM PricebookEntry
                                                     WHERE Product2Id IN :product2OLIMap.keySet()];

            Map<Id, PricebookEntry> product2PricebookEntryMap = new Map<Id, PricebookEntry>(); // holds <Product2Id, PricebookEntry> maps

            for (PricebookEntry pricebookEntry : pricebookEntries) {
                product2PricebookEntryMap.put(pricebookEntry.Product2Id, pricebookEntry);
            }

            for (Id prodId : product2OLIMap.keySet()) {
                product2OLIMap.get(prodId).PricebookEntryId = product2PricebookEntryMap.get(prodId).Id;
            }

            /*
             * First delete all Opportunity Products for this Opportunity
             * then insert new Opportunity Products for this Opportunity
             */
             /* deleteToUncomment
            // prepare Opportunity Line Items for insert
            for (Id oliId : product2OLIMap.keySet()) {
                OLIsToInsert.add(product2OLIMap.get(oliId));
            }

            if (OLIsToInsert.size() > 0) {
                List<OpportunityLineItem> OLIsToDelete = [SELECT Id
                                                          FROM OpportunityLineItem
                                                          WHERE OpportunityId IN :opportunityIds];

                System.debug('SO TRIGGER: OLIs to delete: ' + OLIsToDelete);
                delete OLIsToDelete;
                System.debug('SO TRIGGER: Deleted OLIs: ' + OLIsToDelete);

                System.debug('SO TRIGGER: OLIs to insert: ' + product2OLIMap);
                insert OLIsToInsert;
                System.debug('SO TRIGGER: Inserted OLIs: ' + product2OLIMap);
            }

            /*
             * Send email if missing Publication Products RQ_0082
             */
            /* deleteToUncomment
            if (missingPublications.size() > 0) {
                System.debug('SO TRIGGER: Missing Publications: ' + missingPublications);
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();

                //sending bcc to each user which is limited to 25, plus the sender so they are aware
                List<User> sysUsers = [SELECT ID,Name, Email,LastLoginDate FROM User
                                       WHERE Profile.Name = 'System Administrator'
                                                            AND IsActive = TRUE
                                                                           AND (Email LIKE '%@news%' OR Email LIKE '%@cloudsense%')
                                                                           ORDER BY LastLoginDate DESC LIMIT 24];

                List<String> addressesList = new List<String>();

                for (User usr: sysUsers) {
                    addressesList.add(usr.Email);
                }

                emailMessage.setBccAddresses(addressesList);
                emailMessage.setBccSender(true);
                emailMessage.setSubject('Missing publication products were detected for Opportunity');

                String messageBody = '<p><strong>ORG: ' + UserInfo.getOrganizationId() + ' is missing the following Publication Products:</strong></p>';
                messageBody += '<ul>';

                for (String publication: missingPublications) {
                    messageBody += '<li>' + publication + '</li>';
                }

                messageBody += '<p>This is an automated message by the system.';
                messageBody += '</ul>';

                emailMessage.setHtmlBody(messageBody);

                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailMessage });
            }
        }
    }
    deleteToUncomment */

    /**
     * Sync with opportunity method that manages Opportunity products:
     *  - syncs selected SO with Opportunity (deletes old Opp products and creates new from selected SO)
     *  - deletes Opportunity products if SO was previously synced and now is in DESYNC_STATUS_SET
     *  - manages Is_Synched__c flag on all SOs that belong to the Opportunity (SO that was synced right now has flag set to true)
     *  - manages Has_an_Approved_SO__c on the Opportunity
     *
     * Can be used in trigger context and on-demand (from a button).
     * On-demand mode will validate the request i.e. will refuse to sync SOs that do not pass validation.
     * Passed in csmso__Sales_Order__c records have to include fields:
     *  - Name, csmso__Status__c, csmso__Opportunity__c, csmso__Opportunity__r.Has_an_Approved_SO__c,csmso__Opportunity__r.Name
     *    Invalid_Config_Count__c, Is_Synched__c
     */
    public static String syncWithOpportunity(List<csmso__Sales_Order__c> soList) {
        List<String> validationMessages = new List<String>();
        //Opportunity Ids of opportunities we need to update/refresh (delete products, update status or Has_an_Approved_SO__c)
        Set<Id> oppIds                                       = new Set<Id>();
        Map<Id, sObject> oldMap                              = new Map<Id, sObject>();
        Map<Id, csmso__Sales_Order__c> salesOrdersForSyncMap = new Map<Id, csmso__Sales_Order__c>();

        //trigger context is driven from status changes so we build our own salesOrdersForSyncMap
        //IMPORTANT: trigger based logic executes only if status has been changed to prevent
        //trigger firing again (as syncing one SO needs to update another SO to clear Is_Synched__c flag)
        Set<Id> oppIdsForLoad = new Set<Id>();
        if (Trigger.isExecuting) {
            oldMap = Trigger.oldMap;            
            //check which ones we need to sync, autosync or desync
            for (csmso__Sales_Order__c so : (List<csmso__Sales_Order__c>)Trigger.new) {
                csmso__Sales_Order__c oldSO = (csmso__Sales_Order__c)oldMap.get(so.Id);
                //if status was changed and it is in approved status list then resync is always required
                if (so.csmso__Status__c != oldSO.csmso__Status__c &&
                    APPROVED_STATUS_SET.contains(so.csmso__Status__c) &&
                    !APPROVED_STATUS_SET.contains(oldSO.csmso__Status__c)) {
                    //add to the sync list
                    salesOrdersForSyncMap.put(so.Id, so);
                    oppIds.add(so.csmso__Opportunity__c);
                } else if (so.csmso__Status__c != oldSO.csmso__Status__c &&
                    AUTOSYNC_STATUS_SET.contains(so.csmso__Status__c) &&
                    !AUTOSYNC_STATUS_SET.contains(oldSO.csmso__Status__c)) {
                    //if status was changed but it is in autosync status list then resync
                    //is allowed ONLY if this is the SO that was previously synced or if there are no synced SOs for that Opp
                    //add to the sync list
                    //in order to not waste SOQL we capture Opp Ids that require load to finish 2nd part of the condition!
                    if (so.Is_Synched__c) {
                        //we know we need to resync it without querying the Opp
                        salesOrdersForSyncMap.put(so.Id, so);
                        oppIds.add(so.csmso__Opportunity__c);
                    } else {
                        //maybe this Opportunity doesn't have previously synced SO so we will need to check this later
                        //oppMap.get(so.csmso__Opportunity__c).csmso__Sales_Orders__r.isEmpty() part of the condition
                        oppIdsForLoad.add(so.csmso__Opportunity__c);
                    }
                } else if (so.csmso__Status__c != oldSO.csmso__Status__c &&
                           DESYNC_STATUS_SET.contains(so.csmso__Status__c) &&
                           so.Is_Synched__c) {
                    //status was changed to value that requires Opp products cleanup so
                    //adding to oppIds only if this SO was synced to Opportunity
                    oppIds.add(so.csmso__Opportunity__c);
                    //not adding to sync list as there is nothing to resync
                }
            }
        } else {
            //on-demand context is using passed in soList and just validates them (can't check old vs new values)
            //on-demand context is specific as it expects only resync requests, desync request should be trigger based (reacting to status change)
            for (csmso__Sales_Order__c so : soList) {
                //TODO define all guarding conditions (SO and Opportunity level)
                if (so.csmso__Opportunity__r.Has_an_Approved_SO__c) {
                    validationMessages.add('Opportunity (' + so.csmso__Opportunity__r.Name + ') already has approved Sales Order and cannot be synced!');
                } else if (so.Invalid_Config_Count__c > 0) {
                    validationMessages.add('Sales Order (' + so.Name + ') contains invalid or incomplete line items and cannot be synced!');
                } else {
                    //can be synced so include it in helper map and set
                    salesOrdersForSyncMap.put(so.Id, so);
                    oppIds.add(so.csmso__Opportunity__c);
                }
            }
        }
        //new we need to perform 2nd part of the auto-sync condition but only if we have something flagged for check
        //load opp context with synced SOs
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        if (!oppIdsForLoad.isEmpty()) {
            oppMap = new Map<Id, Opportunity>([SELECT Id, Name, StageName,
                                              (SELECT Id FROM csmso__Sales_Orders__r WHERE Is_Synched__c = true)
                                              FROM Opportunity WHERE Id IN :oppIdsForLoad]);
            //loop over all SOs and check only 2nd part of the auto-sync criteria as we couldn't run it before without SOQL
            for (csmso__Sales_Order__c so : (List<csmso__Sales_Order__c>)Trigger.new) {
                csmso__Sales_Order__c oldSO = (csmso__Sales_Order__c)oldMap.get(so.Id);
                if (so.csmso__Status__c != oldSO.csmso__Status__c &&
                    AUTOSYNC_STATUS_SET.contains(so.csmso__Status__c) &&
                    !AUTOSYNC_STATUS_SET.contains(oldSO.csmso__Status__c) &&
                    oppMap.get(so.csmso__Opportunity__c).csmso__Sales_Orders__r.isEmpty()) {
                    //indeed it needs to be resynced as Opp didn't have previously synced SOs
                    salesOrdersForSyncMap.put(so.Id, so);
                    oppIds.add(so.csmso__Opportunity__c);
                }
            }
        }

        //continue if no validation messages
        if (!validationMessages.isEmpty()) {
            //TODO check what separator works best for UI messages
            return String.join(validationMessages, ' ');
        } else {
            //ready for core sync logic
            //Delete all Opportunity products from identified Opps
            List<OpportunityLineItem> oliToDeleteList = new List<OpportunityLineItem>();
            if (!oppIds.isEmpty()) {
                oliToDeleteList = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId IN :oppIds AND Source__c = 'CPQ'];
                //delete oliToDeleteList; NR-1941 delete postponed until new lines are inserted to avoid validation issues
            }
            //resync all identified Sales Orders (if any)
            if (!salesOrdersForSyncMap.isEmpty()) {
                createOpportunityProductsForSOs(salesOrdersForSyncMap.values());
            }
            //NR-1941
            if (!oliToDeleteList.isEmpty()) {
                delete oliToDeleteList;
            }
            
            //Refresh Opportunity with up-to-date Has_an_Approved_SO__c and/or status
            //Use this chance to reset Is_Synched__c flag on all other SOs
            List<Opportunity> oppsToProcess = new List<Opportunity>();
            //not wasting SOQL if we know nothing would be returned
            if (!oppIds.isEmpty()) {
                oppsToProcess = [SELECT Id, Has_an_Approved_SO__c, Approved_Sales_Order_Number__c, StageName,
                                    Campaign_Brief_Form_Completed__c, Type_of_Platforms__c, 
                                    (SELECT Id, Name, Is_Synched__c, csmso__Status__c FROM csmso__Sales_Orders__r)
                                FROM Opportunity
                                WHERE Id IN :oppIds];
            }
            //minimum scope, declaring update lists before use
            List<Opportunity> oppsToUpdate         = new List<Opportunity>();
            List<csmso__Sales_Order__c> soToUpdate = new List<csmso__Sales_Order__c>();
            for (Opportunity oppty : oppsToProcess) {
                Boolean hasApprovedSO = false;
                String soName;
                for (csmso__Sales_Order__c so :oppty.csmso__Sales_Orders__r) {
                    //true if previously set or if current SO is in approved status
                    hasApprovedSO = hasApprovedSO || APPROVED_STATUS_SET.contains(so.csmso__Status__c);
                    //SO is flagged as Is_Synched__c and it is not in salesOrdersForSyncMap it needs resetting
                    if (!salesOrdersForSyncMap.containsKey(so.Id) && so.Is_Synched__c) {
                        so.Is_Synched__c = false;
                        soToUpdate.add(so);
                    } else if (salesOrdersForSyncMap.containsKey(so.Id) && !so.Is_Synched__c) {
                        //SO is in our map but not flagged as synced
                        so.Is_Synched__c = true;
                        soToUpdate.add(so);
                    }
                    //maintain Approved SO Name on Opp
                    if (APPROVED_STATUS_SET.contains(so.csmso__Status__c)) {
                        soName = so.Name;
                    }
                }
                //update opportunity only if we have a change
                Boolean hasChange = false;
                if (oppty.Has_an_Approved_SO__c != hasApprovedSO) {
                    oppty.Has_an_Approved_SO__c = hasApprovedSO;
                    hasChange = true;
                }
                //stage name logic: replacing Sales Order - Auto update of opportunity stage process AB 08-11-2018
                if (hasApprovedSO) {
                    //calculate correct stage value and update if needed, for now just setting to Confirmed/Awaiting Bookings
                    String stageValue = oppty.StageName;
                    if (!oppty.Campaign_Brief_Form_Completed__c) {
                        stageValue = 'Confirmed/Awaiting Bookings';
                    } else if (oppty.Campaign_Brief_Form_Completed__c && oppty.Type_of_Platforms__c != 'Not NewsXtend') {
                        stageValue = 'Closed Won';
                        oppty.Reason_Won_Lost__c = 'Masthead Reputation';
                    } else if (oppty.Campaign_Brief_Form_Completed__c && oppty.Type_of_Platforms__c == 'Not NewsXtend') {
                        //same as above? probably logical error in process we are replacing!
                        stageValue = 'Closed Won';
                        oppty.Reason_Won_Lost__c = 'Masthead Reputation';
                    }
                    
                    if (oppty.StageName != stageValue) {
                        oppty.StageName = stageValue;
                        hasChange = true;
                    }
                }
                //Approved SO Name logic, replacing Sales Order: Update related Opportunity with Number process
                if (oppty.Approved_Sales_Order_Number__c != soName) {
                    oppty.Approved_Sales_Order_Number__c = soName;
                    hasChange = true;
                }

                if (hasChange) {
                    oppsToUpdate.add(oppty);
                }
            }
            //ready for final updates
            if (!oppsToUpdate.isEmpty()) {
                update oppsToUpdate;
            }
            if (!soToUpdate.isEmpty()) {
                update soToUpdate;
            }
        }

        //TODO check what successful message should be
        return 'OK';
    }

    /**
     * Started as a clone of createOpportunityProducts(List<csmso__Sales_Order__c> triggerNew, Map<Id,csmso__Sales_Order__c> triggerOldMap)
     * Original method left intact for now but should be deleted.
     * No longer checks if opportunity products should be created as that is taken care of by calling method.
     * Only creates new opportunity products.
     * IMPORTANT:
     * Still has original flaw of not correctly grouping data!
     * All Sales Orders passed in to this method are processed as if they are one logical whole so
     * logic for setting Product_Type__c is not correct!
     * Not critical as currently there are no mass syncs going on but should be fixed anyway.
     */
    public static void createOpportunityProductsForSOs(List<csmso__Sales_Order__c> soList) {
        List<cscfga__Product_Configuration__c> PCs = new List<cscfga__Product_Configuration__c>();
        if (!soList.isEmpty()) {
            // Get non-bundle Product Configurations. This will also get related Product Configurations and skip Bundle Line Item PDs
            PCs = [SELECT Id, Name, Line_Item_Platform__c, Publication__c, Bespoke_Digital_Description__c, Line_Item_Price__c,
                   Primary_Product_Opp_Amount_Remainder__c, One_Off_Price__c, cscfga__Parent_Configuration__c,
                   cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Products_Type__c,
                   cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c,
                   cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c,
                   cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Length__c,
                   Total_Target_Duration_Price__c
                   FROM cscfga__Product_Configuration__c
                   WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c = :soList AND Bundle_Item__c = false];
        }

        /*
         * Get Print and Digital Publication Products
         *
         * Get Xtend Publication Products
         * Xtend Sales Order Line Items to map with Publication Product with following criteria (RQ_0079):
         * There is only a single Product (Product2): "Digital - NewsXtend"
         * Match by Publication Name (Publication_Product__c.Publication__c) = "NewsXtend"
         *
         * Print Sales Order Line Items are mapped to Publication Products with following criteria (RQ_0077):
         * Match by Publication Name (Publication__c) or Publication Code (Publication_Code__c)
         * Where Ad Type (Ad_Type__c) is Display
         * Filter by Products that are Active (Product__c.IsActive)
         *
         * Digital Sales Order Line Items to map with Publication Product with following criteria (RQ_0078):
         * Match by Publication Name (Publication__c)
         * Where Ad Type (Ad_Type__c) is Display
         * Filter by Products that are Active (Product__c.IsActive)
         */
        if (!PCs.isEmpty()) {
            Set<String> publicationNames = new Set<String>();

            // get PC Ids
            for (cscfga__Product_Configuration__c PC : PCs) {
                if (PC.Line_Item_Platform__c == 'Print' ||
                    PC.Line_Item_Platform__c == 'Digital' ||
                    PC.Line_Item_Platform__c == 'Xtend') {

                    if (PC.Line_Item_Platform__c == 'Print') {
                        publicationNames.add(PC.Publication__c);
                    } else if (PC.Line_Item_Platform__c == 'Digital') {
                        publicationNames.add(PC.Bespoke_Digital_Description__c);
                    }
                }
            }

            /*
             * Get Publication Products
             */
            // get all Publication Products for PCs in question
            List<Publication_Product__c> publicationProducts = [SELECT Id, Product__c, Publication__c
                                                                FROM Publication_Product__c
                                                                WHERE Product__r.IsActive = true AND (
                                                                    (Publication__c IN :publicationNames AND Ad_Type__c = 'Display') OR Publication__c = 'NewsXtend')];

            // If there are multiple records matching above criteria, get the first record.
            // So using Map with Publication__c as a key is ok. (RQ_0080)
            Map<String, Publication_Product__c> publicationProductsMap = new Map<String, Publication_Product__c>();

            for (Publication_Product__c pp : publicationProducts) {
                publicationProductsMap.put(pp.Publication__c, pp);
            }

            Set<String> missingPublications             = new Set<String>();
            List<OpportunityLineItem> OLIsToInsert      = new list<OpportunityLineItem>();
            Map<Id, OpportunityLineItem> product2OLIMap = new Map<Id, OpportunityLineItem>();  // Product2Id => OpportunityLineItem

            //Map<String, Integer> platformToProductMapXtend = new Map<String, Integer>();
            Integer xtendBundleCount  = 0;
            Integer xtendBespokeCount = 0;

            Map<Id, Map<String, Integer>> platformToProductAll = new Map<Id, Map<String, Integer>>();
            Integer printBundleCount    = 0;
            Integer printBespokeCount   = 0;
            Integer digitalBundleCount  = 0;
            Integer digitalBespokeCount = 0;
            Map<String, Integer> productTypeCounterMap = new Map<String, Integer>();

            // Create OLIs for all Product Configurations
            for (cscfga__Product_Configuration__c PC : PCs) {

                Id product2Id = null;

                // Product__c is Product2Id
                if (PC.Line_Item_Platform__c == 'Print' && publicationProductsMap.containsKey(PC.Publication__c)) {
                    product2Id = publicationProductsMap.get(PC.Publication__c).Product__c;
                } else if (PC.Line_Item_Platform__c == 'Digital' && publicationProductsMap.containsKey(PC.Bespoke_Digital_Description__c)) {
                    product2Id = publicationProductsMap.get(PC.Bespoke_Digital_Description__c).Product__c;
                } else if (PC.Line_Item_Platform__c == 'Xtend' && publicationProductsMap.containsKey('NewsXtend')) {
                    product2Id = publicationProductsMap.get('NewsXtend').Product__c;
                } else {
                    // Prepare mail for System administrator
                    if (PC.Line_Item_Platform__c == 'Print') {
                        missingPublications.add('Opportunity: ' + PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c +
                                                ' - Publication: ' + PC.Line_Item_Platform__c + ' > ' + PC.Publication__c);
                    } else if (PC.Line_Item_Platform__c == 'Digital') {
                        missingPublications.add('Opportunity: ' + PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c +
                                                ' - Publication: ' + PC.Line_Item_Platform__c + ' > ' + PC.Bespoke_Digital_Description__c);
                    }
                }

                if (product2Id != null) {
                    // NR-132 Set new fields on Opportunity Product (Product Type field needs special logic, Source field is set to 'CPQ' value)
                    if (PC.cscfga__Parent_Configuration__c == null) {
                        if (PC.Line_Item_Platform__c == 'Xtend') {
                            xtendBespokeCount++;
                            productTypeCounterMap.put('Bespoke', xtendBespokeCount);
                        } else if (PC.Line_Item_Platform__c == 'Print') {
                            printBespokeCount++;
                            productTypeCounterMap.put('Bespoke', printBespokeCount);
                        } else if (PC.Line_Item_Platform__c == 'Digital') {
                            digitalBespokeCount++;
                            productTypeCounterMap.put('Bespoke', digitalBespokeCount);
                        }
                        platformToProductAll.put(product2Id, productTypeCounterMap);
                    } else if (PC.cscfga__Parent_Configuration__c != null) {
                        if (PC.Line_Item_Platform__c == 'Xtend') {
                            xtendBundleCount++;
                            productTypeCounterMap.put('Bundle', xtendBundleCount);
                        } else if (PC.Line_Item_Platform__c == 'Print') {
                            printBundleCount++;
                            productTypeCounterMap.put('Bundle', printBundleCount);
                        } else if (PC.Line_Item_Platform__c == 'Digital') {
                            digitalBundleCount++;
                            productTypeCounterMap.put('Bundle', digitalBundleCount);
                        }
                        platformToProductAll.put(product2Id, productTypeCounterMap);
                    }

                    Decimal duration   = PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Length__c;
                    Decimal totalPrice = 0;

                    if (PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Products_Type__c == 'Evergreen') {
                        duration = 12;
                    }

                    /*
                     * Total price for current product is calculated by multiplying Line Item Price with the Campaign Length duration
                     * and adding Primary Product Opportunity Amount Remainder if it exists.
                     * This remainder is to fix the difference in total Opportunity Amount caused by rouding the Total Bundle Price and
                     * dividing it by the number of months during product configuration process. (1B_003)
                     */

                    // NR-214 For Xtend one off product, the calculation is wrong - it shouldn't be multiplied with duration
                    /*if (PC.Line_Item_Platform__c == 'Xtend' && PC.One_Off_Price__c != null && PC.One_Off_Price__c != 0.00) {
                        totalPrice = PC.Line_Item_Price__c + PC.Primary_Product_Opp_Amount_Remainder__c;
                       } else {
                        totalPrice = (PC.Line_Item_Price__c * duration) + PC.Primary_Product_Opp_Amount_Remainder__c;
                       }*/

                    // MC: commented out the previous if-ology, due to an issue with Bespoke Print not having Line_Item_Price__c filled
                    // TO-DO test it and change accordingly
                    if (PC.Line_Item_Platform__c == 'Xtend' && PC.One_Off_Price__c != null && PC.One_Off_Price__c != 0.00) {
                    	if(PC.Primary_Product_Opp_Amount_Remainder__c != null){
                        	totalPrice = PC.Line_Item_Price__c + PC.Primary_Product_Opp_Amount_Remainder__c;
                    	}else{
                    		totalPrice = PC.Line_Item_Price__c;
                    	}
                    } else if (PC.Line_Item_Platform__c == 'Print' && PC.cscfga__Parent_Configuration__c == null) {
                    	if(PC.Primary_Product_Opp_Amount_Remainder__c!=null){
                        	totalPrice = PC.Total_Target_Duration_Price__c + PC.Primary_Product_Opp_Amount_Remainder__c;
                    	}else{
                    		totalPrice = PC.Total_Target_Duration_Price__c;
                    	}
                    } else {
                    	if(PC.Primary_Product_Opp_Amount_Remainder__c != null){
                        	totalPrice = (PC.Line_Item_Price__c * duration) + PC.Primary_Product_Opp_Amount_Remainder__c;
                    	}else{
                    		totalPrice = (PC.Line_Item_Price__c * duration);
                    	}
                    }

                    // sum up the existing product values
                    if (product2OLIMap.containsKey(product2Id)) {
                        //product2OLIMap.get(product2Id).Quantity   += 1; // PM 07/12/2018 : changing this to always 1 on creation as per NR-2174
                        product2OLIMap.get(product2Id).TotalPrice += totalPrice;
                        // product2OLIMap.get(product2Id).of_periods__c = duration;
                    } else {
                        product2OLIMap.put(product2Id, new OpportunityLineItem(
                                               Quantity      = 1,
                                               TotalPrice    = totalPrice,
                                               of_periods__c = duration,
                                               Source__c     = 'CPQ',
                                               OpportunityId = PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c,
                                               ServiceDate   = PC.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c,
                                               Pattern__c    = 'Monthly'));
                    }
                }
            } // for end

            // NR-132
            // set the values of Product type by created OLI
            for (Id oli : product2OLIMap.keySet()) {
                if (platformToProductAll.containsKey(oli)) {
                    System.debug(' --+ velicina: ' + platformToProductAll.get(oli).size());
                    if (platformToProductAll.get(oli).size() > 1) {
                        System.debug(' --+ ovo je Mixed');
                        product2OLIMap.get(oli).Product_Type__c = 'Mixed';
                    } else {
                        for (String type : platformToProductAll.get(oli).keySet()) {
                            System.debug(' --+ ovo je type kad je samo jedan: ' + type);
                            product2OLIMap.get(oli).Product_Type__c = type;
                        }
                    }
                }
            }

            //set Pricebook Etries to all OLIs
            List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id
                                                     FROM PricebookEntry
                                                     WHERE Product2Id IN :product2OLIMap.keySet()];

            Map<Id, PricebookEntry> product2PricebookEntryMap = new Map<Id, PricebookEntry>(); // holds <Product2Id, PricebookEntry> maps

            for (PricebookEntry pricebookEntry : pricebookEntries) {
                product2PricebookEntryMap.put(pricebookEntry.Product2Id, pricebookEntry);
            }

            for (Id prodId : product2OLIMap.keySet()) {
                product2OLIMap.get(prodId).PricebookEntryId = product2PricebookEntryMap.get(prodId).Id;
            }

            // prepare Opportunity Line Items for insert
            for (Id oliId : product2OLIMap.keySet()) {
                OLIsToInsert.add(product2OLIMap.get(oliId));
            }

            if (OLIsToInsert.size() > 0) {
                insert OLIsToInsert;
            }

            /*
             * Send email if missing Publication Products RQ_0082
             */
            if (missingPublications.size() > 0) {
                System.debug('SO TRIGGER: Missing Publications: ' + missingPublications);
                Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();

                //sending bcc to each user which is limited to 25, plus the sender so they are aware
                List<User> sysUsers = [SELECT ID,Name, Email,LastLoginDate FROM User
                                       WHERE Profile.Name = 'System Administrator'
                                                            AND IsActive = TRUE
                                                                           AND (Email LIKE '%@news%' OR Email LIKE '%@cloudsense%')
                                                                           ORDER BY LastLoginDate DESC LIMIT 24];

                List<String> addressesList = new List<String>();

                for (User usr: sysUsers) {
                    addressesList.add(usr.Email);
                }

                emailMessage.setBccAddresses(addressesList);
                emailMessage.setBccSender(true);
                emailMessage.setSubject('Missing publication products were detected for Opportunity');

                String messageBody = '<p><strong>ORG: ' + UserInfo.getOrganizationId() + ' is missing the following Publication Products:</strong></p>';
                messageBody += '<ul>';
                for (String publication: missingPublications) {
                    messageBody += '<li>' + publication + '</li>';
                }

                messageBody += '<p>This is an automated message by the system.';
                messageBody += '</ul>';
                emailMessage.setHtmlBody(messageBody);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { emailMessage });
            }
        }
    }

    //inner classes
    // 16/03/2018 Igor Vrabec: Commented out this method because the code in CS_AllProductBasketTriggers that calls it is commented out as well.
    public class SOWrapper {

        public Decimal ProposedDiscount     {get; set;}
        public Set<Decimal> LineItemsDiscountSet {get; set;}
        public Set<String>  PublicationsSet      {get; set;}
        public Decimal PreviousTotalPrintPrice {get; set;}
        public Decimal ImpressionsQuantiy {get; set;}

        public SOWrapper(){
            this.ImpressionsQuantiy   = 0;
            this.LineItemsDiscountSet = new Set<Decimal>();
            this.PublicationsSet      = new Set<String>();
        }
        //check if set containing all of Line Discount Set has SO proposed discount
        // AND if the discount in the set is actually the one from SO
        public Boolean isDiscountChangedOnLineLevel() {
            return (LineItemsDiscountSet.size()>1 || !LineItemsDiscountSet.contains(ProposedDiscount));
        }
    }
}
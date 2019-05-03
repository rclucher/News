public without sharing class RevenueReporting_Helper {
    
    /*---------------------------------------------------------
* Author: David Dawson
* Date: March 2016
* Description: Allocates an opportunity to a Sales Summary record based on its attributes
* History: 
---------------------------------------------------------*/
    
    public Void BookingLineItemRevenueDistRollups(Boolean isAfter, Boolean isBefore, Boolean isUpdate, Boolean isInsert, Boolean isDelete, Boolean isUnDelete){
        //Rollup Summary (Insert, Update and Undelete)
        if(isAfter){
            //Rollup the Custom_TotalPrice__c field to the Count__c field on SalesSummary__c object
            if(isInsert || isUpdate || isUnDelete){
                list<RollUpSummaryUtility.fieldDefinition> fieldDefinitions =
                    new list<RollUpSummaryUtility.fieldDefinition> {
                        new RollUpSummaryUtility.fieldDefinition('SUM', 'DistributedRevenueExclGST__c ',
                                                                 'Count__c')
                            };
                                RollUpSummaryUtility.rollUpTrigger(fieldDefinitions, (List<BookingLineItemRevenueDist__c>)trigger.new,
                                                                   'BookingLineItemRevenueDist__c', 'SalesSummary__c', 'SalesSummary__c', '');
            }
            
            //Rollup Summary (on Delete)
            //Rollup the Custom_TotalPrice__c field to the Count__c field on SalesSummary__c object
            if(isDelete){
                list<RollUpSummaryUtility.fieldDefinition> fieldDefinitions =
                    new list<RollUpSummaryUtility.fieldDefinition> {
                        new RollUpSummaryUtility.fieldDefinition('SUM', 'DistributedRevenueExclGST__c ',
                                                                 'Count__c')
                            };
                                RollUpSummaryUtility.rollUpTrigger(fieldDefinitions, (List<BookingLineItemRevenueDist__c>)trigger.old,
                                                                   'BookingLineItemRevenueDist__c', 'SalesSummary__c', 'SalesSummary__c', '');
            }
            
        }
    }
    
    /*---------------------------------------------------------
* Author: Peter Charalambous
* Company: Bluewolf
* Date: August 2016
* Description: Link Booking Line Item record to a Sales Summary record
* History:
---------------------------------------------------------*/
    
    public Void allocateSalesSummaryBLIDR(){
        
        Set<String> keySet = new Set<String>();
        Map<String, SalesSummary__c> ssMap = new Map<String, SalesSummary__c>();
        
        //Check what is in the trigger
        system.debug('Trigger contents ' + (List<BookingLineItemRevenueDist__c>)Trigger.NEW);
        
        //loop through the Booking Line Item records and qualify the record first, then build an external id
        for(BookingLineItemRevenueDist__c bli :(List<BookingLineItemRevenueDist__c>)Trigger.NEW){
            
            //check if the sales summary field is empty OR one of the calculative fields have changed AND all calculative fields are not null
            if(opportunityProductCompatible(bli, Trigger.isInsert, Trigger.oldMap)){
                //EXTERNAL ID UTILITY 
                String oKey = ExternalIdUtility.SalesSummaryExternalId(bli.OpportunityOwnerExternalId__c, bli.OpportunityOwnerCurrentRole__c, 'Actual', bli.ProductClassification__c, bli.FiscalMonthId__c);
                keySet.add(oKey);
            }
        }
        
        //we only need to progress through the rest of the trigger if the keyset is not empty
        if(!keySet.isEmpty()){
            //now that we have a set of keys, query the system to see which ones we already have and which ones we don't
            List<SalesSummary__c> ssList = new List<SalesSummary__c>([SELECT Id, ExternalId__c FROM SalesSummary__c WHERE ExternalId__c IN :keySet]);
            for(SalesSummary__c ss :ssList){
                ssMap.put(ss.ExternalId__c, ss);
            }
            
            //check the keyset against the generated map
            for(BookingLineItemRevenueDist__c bli :(List<BookingLineItemRevenueDist__c>)Trigger.NEW){
                //check if the sales summary field is empty OR one of the calculative fields have changed AND all calculative fields are not null
                if(opportunityProductCompatible(bli, Trigger.isInsert, Trigger.oldMap)){
                    //EXTERNAL ID UTILITY
                    String oKey = ExternalIdUtility.SalesSummaryExternalId(bli.OpportunityOwnerExternalId__c, bli.OpportunityOwnerCurrentRole__c, 'Actual', bli.ProductClassification__c, bli.FiscalMonthId__c);
                    
                    
                    if(!ssMap.containsKey(oKey)){
                        
                        SalesSummary__c newSS = new SalesSummary__c(ExternalId__c = oKey, Name = 'Temporary Name', Type__c = 'Actual', OwnerId = bli.SalesOrderOwner__c, UserId__c = bli.SalesOrderOwner__c, BookingRevenueType__c = bli.ProductClassification__c, Role__c = bli.OpportunityOwnerCurrentRole__c, MonthId__c = bli.FiscalMonthId__c);
                        
                        //generate the year field
                        newSS.Year__c = Integer.valueOf(bli.FiscalMonthId__c.substring(0,4));
                        //add the newly created record to the map to fill the gaps'
                        ssMap.put(newSS.ExternalId__c, newSS);
                    }
                }
            }
            
            //Check what is within the sales summary map
            system.debug('Check the map values ' + ssMap);
            
            //insert the list before we pass trigger.new back into the trigger
            try{
                upsert ssMap.values() ExternalId__c;
            }catch(exception e){
                ExLog.log(e, 'config', ssMap.values(), 'From RevenueReporting_Helper.allocateSalesSummaryBLIDR().');  
            }
            
            //one final loop through the Booking Line Item to link the Booking Line Item to a Sales Summary record
            for(BookingLineItemRevenueDist__c bli :(List<BookingLineItemRevenueDist__c>)Trigger.NEW){
                //check if the sales summary field is empty OR one of the calculative fields have changed AND all calculative fields are not null
                if(opportunityProductCompatible(bli, Trigger.isInsert, Trigger.oldMap)){
                    //EXTERNAL ID UTILITY
                    String oKey = ExternalIdUtility.SalesSummaryExternalId(bli.OpportunityOwnerExternalId__c, bli.OpportunityOwnerCurrentRole__c, 'Actual', bli.ProductClassification__c, bli.FiscalMonthId__c);
                    
                    if(ssMap.containsKey(oKey)){
                        bli.SalesSummary__c = ssMap.get(oKey).Id;
                    }
                }
            }
        }
    }
    
    /*---------------------------------------------------------
* Author: David Dawson
* Modified By: Peter Charalambous
* Company: Bluewolf
* Description: Qualify the sales order to be included in the allocateSalesSummary() function
* History:
---------------------------------------------------------*/
    
    public static Boolean opportunityProductCompatible(BookingLineItemRevenueDist__c bli, Boolean isInsert, Map<Id, sObject> oldMap){
        Boolean isQualified = false;
        
        if((isInsert || bli.SalesSummary__c == null || (bli.ProductClassification__c != String.valueOf(oldMap.get(bli.Id).get('ProductClassification__c')) || bli.SalesOrderOwner__c != String.valueOf(oldMap.get(bli.Id).get('SalesOrderOwner__c')) || bli.OpportunityOwnerCurrentRole__c != String.valueOf(oldMap.get(bli.Id).get('OpportunityOwnerCurrentRole__c'))
                                                       )) && bli.ProductClassification__c != null && bli.SalesOrderOwner__c != null && bli.FiscalMonthId__c != null){
                                                           isQualified = true;
                                                       }
        
        return isQualified;
    }
    
    /*---------------------------------------------------------
* Author: Peter Charalambous
* Company: Bluewolf
* Date: August 2016
* Description: Returns month ID from NewsCorp Fiscal Calendar
* History:
---------------------------------------------------------*/
    
    public static String returnFiscalMonthId(Date dateValue){
        String returnValue = null;
        
        List<FiscalCalendar__mdt> ncfcList = new List<FiscalCalendar__mdt>([SELECT Id, Date__c, FISC_MNTH_ID__c FROM FiscalCalendar__mdt WHERE Date__c =:dateValue LIMIT 1]);
        if(!ncfcList.isEmpty()){
            returnValue = ncfcList[0].FISC_MNTH_ID__c;
        }
        
        return returnValue;
    }
    
}
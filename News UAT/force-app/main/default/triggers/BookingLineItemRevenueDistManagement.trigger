/*---------------------------------------------------------
* Author: Peter Charalambous
* Company: Bluewolf
* Description: Populate Fiscal Month ID field based on NewsCorp Fiscal Calendar Objects
*              Allocate Sales Summary Record to Booking Line Item Dist record
*              Execute Rollups
*
* Created: 15/08/2016 - Peter Charalambous
* Revenue Reporting R1.2 Solution
---------------------------------------------------------*/

trigger BookingLineItemRevenueDistManagement on BookingLineItemRevenueDist__c (after insert, after update, after delete, before insert, before update) {
    
    RevenueReporting_Helper utility = new RevenueReporting_Helper();
    //populate the Fiscal Month Id field on the booking line item revenue dist, before update or before insert
    if(Trigger.isBefore){             
        BookingLineItemRevenueDist_Helper.setFiscalMonthId(trigger.new);//  Done changes as part of backlog#891. -- End      
    }
    TriggerSwitches__c triggerSwitch = TriggerSwitches__c.getOrgDefaults();
    if(triggerSwitch.RevReporting__c && triggerSwitch.RevReportingActual__c){
        //Before we fire the rollup triggers, we need to ensure that the Booking Line Items are pointed to the correct Sales Summary record
        if((Trigger.IsUpdate || Trigger.isInsert) && Trigger.isBefore){
            utility.allocateSalesSummaryBLIDR();
        }
        //Fire rollup functionality
        utility.BookingLineItemRevenueDistRollups(Trigger.isAfter, Trigger.isBefore, Trigger.isUpdate, Trigger.isInsert, Trigger.isDelete, Trigger.isUnDelete);
    }
}
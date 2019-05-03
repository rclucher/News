/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Bluewolf.com
 * Description: This batch is for the Opportunity Scheduling and Line Items
 * History:
 * 20/07/2014  Bohao Chen  Created
 * 2016-01-15  Atul Gupta   Updated
 ---------------------------------------------------------*/
global class OpportunitySchedule_Batch implements Database.Batchable<sObject> {
    
    String query;
    
    global OpportunitySchedule_Batch(String testQuery) {
        
        this.query = testQuery != null ? 
                     testQuery :
                     'SELECT Id, Run_Date__c ' +
                     'FROM Booking_Line_Item__c ';

        if(Test.isRunningTest())             
            this.query += ' Where Is_Test__c = true';

        this.query += ' ORDER BY Booking__r.Sales_Order__c';

    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {

        system.debug('## Start OpportunitySchedule_Batch ##'); 
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        // create the opportunity line item schedules

        system.debug('## Execute OpportunitySchedule_Batch ##'); 

        List<Booking_Line_Item__c> origBookingItems = (List<Booking_Line_Item__c>)scope;
        List<Booking_Line_Item__c> bookingItems = new List<Booking_Line_Item__c>();
        List<String> failedItems = new List<String>();

        OpportunityScheduleManagement_Controller scheduleCtr = new OpportunityScheduleManagement_Controller();

        Map<String, Map<OpportunityLineItem, List<OpportunityLineItemSchedule>>> opptLineItemSchedulesByOpptLineItemBySalesOrderId;

        scheduleCtr.cleanUpCollectionsValues();

        // check that fiscal calendar exists
        for(Booking_Line_Item__c bli : origBookingItems)
        {
            if(!scheduleCtr.isRunDateInFiscalCalendar(bli)) {
                bookingItems.add(bli);
            } else {
                failedItems.add(bli.Id);
            }
        }

        system.debug('## End isRunDateInFiscalCalendar ##'); 

        scheduleCtr.createBookingLineItemsMap(bookingItems, false);

        system.debug('## End createBookingLineItemsMap ##'); 
  
        opptLineItemSchedulesByOpptLineItemBySalesOrderId = scheduleCtr.createOpportunityLineItemSchedulesMap();

        system.debug('## End createOpportunityLineItemSchedulesMap ##'); 

        scheduleCtr.getWeekStartDayByRunDate();

        // Cross checking map opptLineItemSchedulesByOpptLineItemBySalesOrderId 
        // and map bookingLineItemsMapByProductIdBySalesOrderId.
        // create opportunity line item schedule according to booking line items
        scheduleCtr.processBookingLineItemsMap(opptLineItemSchedulesByOpptLineItemBySalesOrderId);

        system.debug('## End processBookingLineItemsMap ##'); 

        // upsert or delete opportunity schedule items
        scheduleCtr.processOpportunityScheduleItems();

        system.debug('## End processOpportunityScheduleItems ##'); 

        if (failedItems.size() > 0) Global_Helper.notifySysAdminException(failedItems, 'Booking Items outside Fiscal Calendar', UserInfo.getUserEmail()); 

    }
    
    global void finish(Database.BatchableContext BC) 
    {
        system.debug('## Finish OpportunitySchedule_Batch ##');
        
       // Get the ID of the AsyncApexJob representing this batch job
       // from Database.BatchableContext.
       // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                        FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        
        //SFE-766 2016-01-14 atul.gupta@bluewolfgroup.com - Consolidate common function in Batch Utility class
        Batch_Utility.errorHandling(a, 'Opportunity Schedule Batch');
    }
}
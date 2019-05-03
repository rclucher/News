/*---------------------------------------------------------
 * author: Bohao Chen
 * Company: Salesforce.com
 * description: 
 *  1. This trigger is going to copy value of Gross_Price__c over to field Gross_Price_YTD__c
 *      in order to trigger roll-up summary gross price YTD on booking and sales order ONLY when run date year is current year.
 *  2. R-0569 / R-0797: Automatically rollup Booking Revenue to Opportunity Revenue Schedule, Opportunity Product & Opportunity
 *  3. R-0822: Add trigger on Booking Line Item to set Salesforce Product based on Publication & Ad Type.
 *
 * History:
 * 17/07/2013   Bohao Chen  Created
 * 26/07/2013   Bohao Chen  Updated
 * 02/09/2013   Bohao Chen  Updated
 * 23/10/2013   Stuart Hamilton  Added conditional bypass
 * 15/08/2016   Peter Charalambous  Added trigger to fire distributedRevenue and deleteDistributedRevenue functions
 * 25/09/2018   Hari Kundrapu Added trigger to fire findEmmaReaderishipbyPubCode for Jira NX-853
---------------------------------------------------------*/
trigger BookingLineItemManagement on Booking_Line_Item__c (before insert, before update, after insert, after update, before delete) 
{

    system.debug(loggingLevel.Error, '===query check @ BookingLineItemManagement: 1 ===' + Limits.getQueries());
    
    if (Global_Helper.canTrigger( 'BookingLineItemManagement' ) ){

        OpportunityScheduleManagement_Controller scheduleCtr = new OpportunityScheduleManagement_Controller();
        
        system.debug(loggingLevel.Error, '===query check @ BookingLineItemManagement: 2 ===' + Limits.getQueries());
        
        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate))
        {
            List<Booking_Line_Item__c> bookingItems  = new List<Booking_Line_Item__c>();
            Set<String> publicationAdTypeKeys  = new Set<String>();
            Set<String> pubCodes  = new Set<String>(); //changes by Hari Kundrapu for Jira NX-853
            
            for(Booking_Line_Item__c bookingItem : trigger.new)
            {
                Date runDate = bookingItem.Run_Date__c;
                
                if(runDate != null && runDate.year() == date.today().year())
                {
                    bookingItem.Gross_Price_YTD__c = bookingItem.Gross_Price__c;
                }
                
                bookingItems.add(bookingItem);
                publicationAdTypeKeys.add(bookingItem.Publication__c + '&' + bookingItem.Booking_Category__c);
                pubCodes.add(bookingItem.Publication__c); // Changes by Hari Kundrapu Jira NX-853
            }
            
            system.debug(loggingLevel.Error, '====publicationAdTypeKeys=== ' + publicationAdTypeKeys);
            
            // R-0822: set Salesforce Product based on Publication code & Ad Type.
            // NOTE: Publication__c is publication code
            Map<String, String> productIdByPublicationCodeAndAdType = BookingLineItemManagement_Helper.findProductIdByPublicationCodeAndAdType(bookingItems, publicationAdTypeKeys);
            Map<String,EMMA_Readership_and_Circulation_Data__c> emmaReaderishipbyPubCode = BookingLineItemManagement_Helper.findEmmaReaderishipbyPubCode(pubCodes); //Changes by Hari Kundrapu Jira NX-853
            system.debug(loggingLevel.Error, '===query check @ BookingLineItemManagement: 3 ===' + Limits.getQueries());
            
            for(Booking_Line_Item__c bookingItem : trigger.new)
            {
                String publicationCodeAndAdType = bookingItem.Publication__c + '&' + bookingItem.Booking_Category__c;
                
                system.debug(loggingLevel.Error, '===publicationCodeAndAdType=== ' + publicationCodeAndAdType);
                
                system.debug(loggingLevel.Error, '===productIdByPublicationCodeAndAdType=== ' + productIdByPublicationCodeAndAdType);
                
                if(productIdByPublicationCodeAndAdType.containsKey(publicationCodeAndAdType))
                {
                    bookingItem.Product__c = productIdByPublicationCodeAndAdType.get(publicationCodeAndAdType);
                }
                else
                {
                    if(bookingItem.Product__c == null && !Test.isRunningTest())
                    {
                        // 2015-01-05 SFE-813 louis.wang@bluewolf.com - Added 'publicationCodeAndAdType' as part of the error message
                        String errorString = 'Could not find product based on ad type and publication code on current booking line item. '
                                                + '<br />This issue may due to missing entry in publication product mapping table. '
                                                + '<br />' + '(' + publicationCodeAndAdType + ')'
                                                + '<br />Please contact your administrator';
                        bookingItem.addError(errorString, false);
                    }
                }
                
                /**** Begin: The following block is requirement for Jira NX-853 ***** Hari Kundrapu*******/
                if(emmaReaderishipbyPubCode.containsKey(bookingItem.Publication__c))
                {
                    if(bookingItem.Run_Day_of_Week__c!=null)
                    {
                        EMMA_Readership_and_Circulation_Data__c tmpEmma = emmaReaderishipbyPubCode.get(bookingItem.Publication__c);
                        bookingItem.Circulation__c = tmpEmma.Circulation__c;

                        if(bookingItem.Run_Day_of_Week__c == 'SAT' || bookingItem.Run_Day_of_Week__c == 'SUN')
                        {                                 
                                bookingItem.ReaderShip__c = tmpEmma.Readership_Saturday_Sunday__c;
                        }

                        else
                        {
                                bookingItem.ReaderShip__c = tmpEmma.Readership_Monday_Friday__c;
                        }
                    }
                }
                /******* End of the block for Jira NX-853 ************* Hari Kundrapu*****/
            }
        }
         
        
        /********* Begin: the following block is for requirement R-0569 / R-0797 ***********/
        /*
         * Automatically rollup Booking Revenue to Opportunity Revenue Schedule, Opportunity Product & Opportunity
         */
        Map<String, Map<OpportunityLineItem, List<OpportunityLineItemSchedule>>> opptLineItemSchedulesByOpptLineItemBySalesOrderId;
        
        if((trigger.isBefore && trigger.isDelete) || (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)))
        {
            // need to clean up values for all collections
            scheduleCtr.cleanUpCollectionsValues();
        
            system.debug(loggingLevel.Error, '===query check @ BookingLineItemManagement: 4 ===' + Limits.getQueries());
        }
        
        if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate))
        {
            scheduleCtr.createBookingLineItemsMap(trigger.new, false);
            system.debug(loggingLevel.Error, '===query check @ BookingLineItemManagement: 5 ===' + Limits.getQueries());            
        }
        
        if(trigger.isBefore && trigger.isDelete)
        {
            scheduleCtr.createBookingLineItemsMap(trigger.old, true);
            system.debug(loggingLevel.Error, '===query check @ BookingLineItemManagement: 6 ===' + Limits.getQueries());            
        }
        
        if((trigger.isBefore && trigger.isDelete) || (trigger.isAfter && (trigger.isInsert || trigger.isUpdate)))
        {           
            system.debug(loggingLevel.Error, '===query check @ BookingLineItemManagement: 7 ===' + Limits.getQueries());
            
            opptLineItemSchedulesByOpptLineItemBySalesOrderId = scheduleCtr.createOpportunityLineItemSchedulesMap();
            
            system.debug(loggingLevel.error, '====BC: opptLineItemSchedulesByOpptLineItemBySalesOrderId=== ' + opptLineItemSchedulesByOpptLineItemBySalesOrderId);
            
            Boolean noFiscalCalendarFound = false;
            
            List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>();
            
            if(trigger.isDelete)
            {
                bookingLineItems.addAll(trigger.old);
            }
            
            if(trigger.isInsert || trigger.isUpdate)
            {
                bookingLineItems.addAll(trigger.new);
            }
    
            for(Booking_Line_Item__c bli : bookingLineItems)
            {
                noFiscalCalendarFound = scheduleCtr.isRunDateInFiscalCalendar(bli);
            }
            
            system.debug(loggingLevel.Error, '===query check @ BookingLineItemManagement: 8 ===' + Limits.getQueries());
            
                        
            if(!noFiscalCalendarFound)
            {
                scheduleCtr.getWeekStartDayByRunDate();
                
                // Cross checking map opptLineItemSchedulesByOpptLineItemBySalesOrderId 
                // and map bookingLineItemsMapByProductIdBySalesOrderId.
                // create opportunity line item schedule according to booking line items
                scheduleCtr.processBookingLineItemsMap(opptLineItemSchedulesByOpptLineItemBySalesOrderId);
        
                system.debug(loggingLevel.Error, '===query check @ BookingLineItemManagement: 9 ===' + Limits.getQueries());
        
                // zero out opportunity line item revenue and reset other values on opportunity line item
                // BC: opportunity line item should be zeroed out when booking is created not when booking line item is created
                //scheduleCtr.zeroOpportunityLineItemRevenue(scheduleCtr.salesOrderSetByOpportunityId);
    
                system.debug(loggingLevel.Error, '===query check @ BookingLineItemManagement: 10 ===' + Limits.getQueries());
    
                // upsert or delete opportunity schedule items
                scheduleCtr.processOpportunityScheduleItems();
            }
        }
        /********* End: the folloing block is for requirement R-0569 ***********/
    }
    

    //Fires the distributedRevenue() and the deleteDistributedRevenue() functions on the BookingLineItemMangement_Helper class
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){

        if(Trigger.isUpdate){
            BookingLineItemManagement_Helper.deleteDistributedRevenue(Trigger.new);
        }
        BookingLineItemManagement_Helper.distributeRevenue();
    }   

}
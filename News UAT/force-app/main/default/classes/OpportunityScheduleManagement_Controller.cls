/*---------------------------------------------------------
 * author: Bohao Chen
 * Company: Salesforce.com
 * description: This controller contains all methods that needed for trigger OpportunityScheduleManagement
 *
 * History:
 * 26/07/2013  Bohao Chen  Created
 * 2016-01-05  Darshan G   Updated
---------------------------------------------------------*/
global with sharing class OpportunityScheduleManagement_Controller 
{    
    
    public Set<Id> salesOrderIdSet;
    public Map<String, OpportunityLineItem> opptLineItemByProductIdAndSalesOrderId;
    public Map<Date, Integer> weekStartDayByRunDate;
    public Map<String, List<Booking_Line_Item__c>> bookingLineItemsMapByProductIdAndSalesOrderId;
    public Set<Id> opportunityIdSet;
    public Map<Id, Set<Id>> salesOrderSetByOpportunityId;
    private List<OpportunityLineItem> duplicateOpptLineItems;
    
    
    public List<FiscalYearSettings> fiscalYearSettingByStartDate 
    { 
        get{ return fiscalYearSettingByStartDate = fiscalYearSettingByStartDate == null ? 
              this.getFiscalYearSetting() : fiscalYearSettingByStartDate; } 
        set; 
    }
    
        
    // this is updated requirement: to time stamp opportunity line item 
    // schedule date / service date to the first booking line item run date
    public Map<Id, OpportunityLineItem> opportunityLineItemMapById = new Map<Id, OpportunityLineItem>();
    
    public OpportunityScheduleManagement_Controller()
    {
        salesOrderIdSet = new Set<Id>();
        opptLineItemByProductIdAndSalesOrderId = new Map<String, OpportunityLineItem>();
        weekStartDayByRunDate = new Map<Date, Integer>();
        bookingLineItemsMapByProductIdAndSalesOrderId = new Map<String, List<Booking_Line_Item__c>>();
        opportunityIdSet = new Set<Id>();
        salesOrderSetByOpportunityId = new Map<Id, Set<Id>>();
        duplicateOpptLineItems = new List<OpportunityLineItem>();
    }
    
    // create list of opportunity line item schedules map with opportunity line item id and sales order id as combination key
    public Map<String, Map<OpportunityLineItem, List<OpportunityLineItemSchedule>>> createOpportunityLineItemSchedulesMap()
    {       
        system.debug('===BC: salesOrderIdSet v1== ' + this.salesOrderIdSet);
        
        //List<OpportunityLineItem> duplicateOpptLineItems = new List<OpportunityLineItem>();
        
        Map<String, Map<OpportunityLineItem, List<OpportunityLineItemSchedule>>> opptLineItemSchedulesByOpptLineItemBySalesOrderId = new Map<String, Map<OpportunityLineItem, List<OpportunityLineItemSchedule>>>();
        
        for(OpportunityLineItem opptLineItem : [Select o.PricebookEntry.Product2Id, o.PricebookEntry.Name, o.PricebookEntryId, o.Sales_Order__c, o.Sales_Order__r.Id, o.OpportunityId, 
                                                    (Select Id, OpportunityLineItemId, Revenue, ScheduleDate From OpportunityLineItemSchedules) 
                                                From OpportunityLineItem o 
                                                Where o.Sales_Order__c IN: this.salesOrderIdSet])        
        {
            system.debug('====opptLineItem 1===' + opptLineItem);
            
            
            if(opptLineItem.Sales_Order__r.Id != null)
            {
                system.debug('===OpportunityLineItemSchedules=== ' + opptLineItem.OpportunityLineItemSchedules);
                
                // if opportunity line item links to sam opportunity and same product, it has to be deduplicate (remove) later on
                String combKey = opptLineItem.PricebookEntry.Product2Id + ' ' + opptLineItem.Sales_Order__c;
                
                system.debug('====combKey===' + combKey);
                    
                if(!opptLineItemByProductIdAndSalesOrderId.containsKey(combKey))
                {
                    opptLineItemByProductIdAndSalesOrderId.put(combKey, opptLineItem);
                    
                    system.debug('====opptLineItem===' + opptLineItem);

                    opptLineItemSchedulesByOpptLineItemBySalesOrderId = this.createOpptLineItemsMap(opptLineItem.Sales_Order__r.Id, opptLineItem, opptLineItemSchedulesByOpptLineItemBySalesOrderId);
                    
                    for(OpportunityLineItemSchedule opptLineItemSchedule : opptLineItem.OpportunityLineItemSchedules)
                    {
                        system.debug('===opptLineItem.Sales_Order__r.Id===' + opptLineItem.Sales_Order__r.Id);
                        
                        // check if booking sales order id has already exist in the map
                        // then, check if opptLineItem has already exist in the map
                        
                        // add this booking line item into map with product Id and sales order Id as key
                        opptLineItemSchedulesByOpptLineItemBySalesOrderId.get(opptLineItem.Sales_Order__r.Id).get(opptLineItem).add(opptLineItemSchedule);
                    }
                    
                    // if opportunity line item is linked to 'dummy' product, add this line item into duplicateOpptLineItems
                    // in order to delete this place holder opportunity line item
                    system.debug('===opptLineItem.PricebookEntry.Name=== ' +opptLineItem.PricebookEntry.Name);
                    
                    
                    if(opptLineItem.PricebookEntry.Name == 'Dummy')
                    {
                        duplicateOpptLineItems.add(opptLineItem);
                    }
                }
                else
                {
                    duplicateOpptLineItems.add(opptLineItem);
                }
            }
        }
        
        // delete duplicate opportunity line items
/*        system.debug('===duplicateOpptLineItems=== ' + duplicateOpptLineItems);
            
        delete duplicateOpptLineItems;*/
        
        return opptLineItemSchedulesByOpptLineItemBySalesOrderId;
    }
    
    public Map<String, Map<OpportunityLineItem, List<OpportunityLineItemSchedule>>> createOpptLineItemsMap(
                                        String salesOrderId, 
                                        OpportunityLineItem opptLineItem, 
                                        Map<String, Map<OpportunityLineItem, List<OpportunityLineItemSchedule>>> opptLineItemSchedulesByOpptLineItemBySalesOrderId)
    {
       // check if booking sales order id has already exist in the map
        if(!opptLineItemSchedulesByOpptLineItemBySalesOrderId.containsKey(opptLineItem.Sales_Order__r.Id))
        {
            opptLineItemSchedulesByOpptLineItemBySalesOrderId.put(opptLineItem.Sales_Order__r.Id, new Map<OpportunityLineItem, List<OpportunityLineItemSchedule>>());
        }
        
        // check if booking product Id has already exist in the map
        if(!opptLineItemSchedulesByOpptLineItemBySalesOrderId.get(opptLineItem.Sales_Order__r.Id).containsKey(opptLineItem))
        {
            opptLineItemSchedulesByOpptLineItemBySalesOrderId.get(opptLineItem.Sales_Order__r.Id).put(opptLineItem, new List<OpportunityLineItemSchedule>());
        }
        
        return opptLineItemSchedulesByOpptLineItemBySalesOrderId;
    }
    
    // create list of booking items map with product id and sales order id as combination key
    public void createBookingLineItemsMap(List<Booking_Line_Item__c> bookingLineItemFromTrigger, Boolean isDelete)
    {
        // get booking ids that booking line items links to.
        // use these booking ids to find all booking line items
        Set<String> bookingIdSet = new Set<String>();
        Set<String> bookingLineItemIdSet = new Set<String>();
        
        for(Booking_Line_Item__c bookingLineItem : [Select b.Run_Date__c, b.Product__c, b.Gross_Price__c, 
                                                        b.Booking__r.Sales_Order__c, b.Booking__c, b.Name
                                                    From Booking_Line_Item__c b
                                                    Where b.Id IN: bookingLineItemFromTrigger
                                                    //And b.Gross_Price__c != NULL
                                                    ])
        {
            bookingIdSet.add(bookingLineItem.Booking__c);
            bookingLineItemIdSet.add(bookingLineItem.Id);
            this.salesOrderIdSet.add(bookingLineItem.Booking__r.Sales_Order__c);
        }
        
        system.debug('===BC: bookingIdSet== ' + bookingIdSet);
        system.debug('===BC: salesOrderIdSet== ' + this.salesOrderIdSet);
        
        for(Booking_Line_Item__c bookingItem : [Select Booking__r.Sales_Order__r.Id, Product__r.Id, Run_Date__c, Gross_Price__c, Name
                                                From Booking_Line_Item__c  
                                                Where Booking__r.Sales_Order__c IN: salesOrderIdSet
                                                //And Gross_Price__c != NULL
                                                ])
        {
            if(bookingItem.Booking__r.Sales_Order__r.Id != null && bookingItem.Product__r.Id != null)
            {
                String combKey = this.generateCombKey(bookingItem.Product__r.Id, bookingItem.Booking__r.Sales_Order__r.Id);
                
                
                // check if booking sales order id and product id has already exist in the map
                if(!bookingLineItemsMapByProductIdAndSalesOrderId.containsKey(combKey))
                {
                    bookingLineItemsMapByProductIdAndSalesOrderId.put(combKey, new List<Booking_Line_Item__c>());
                }
                
                // add this booking line item into map with product Id and sales order Id as key
                // in the case of before delete context, deleted booking line item should not be included in the map 
                if(!isDelete || !bookingLineItemIdSet.contains(bookingItem.Id))
                {
                    bookingLineItemsMapByProductIdAndSalesOrderId.get(combKey).add(bookingItem);
                }   
            }
        }
        
        //return bookingLineItemsMapByProductIdAndSalesOrderId;
    }
    
    // Cross checking map opptLineItemSchedulesByOpptLineItemBySalesOrderId and map bookingLineItemsMapByProductIdAndSalesOrderId.
    // 1. create a new opportunity line item if no opportunity line item can be found according to sales order and same product
    // 2. overwrite opportunity line item schedules if there are any.
    // 3. delete extra opportunity line item schedules if there are more than needed.
    public void processBookingLineItemsMap(Map<String, Map<OpportunityLineItem, List<OpportunityLineItemSchedule>>> opptLineItemSchedulesByOpptLineItemBySalesOrderId)
    {
        system.debug('====BC: opptLineItemSchedulesByOpptLineItemBySalesOrderId 1 ==== ' + opptLineItemSchedulesByOpptLineItemBySalesOrderId);
        system.debug('====BC: opptLineItemByProductIdAndSalesOrderId 1 ==== ' + opptLineItemByProductIdAndSalesOrderId);
        
        // this block of code is to get product id set
        // so that we can find out price book entry id accord to product id
        // when we try to create opportunity line item
        List<Id> productIdSet = new List<Id>();
        
        for(String productIdAndSalesOrderId : bookingLineItemsMapByProductIdAndSalesOrderId.keySet())
        {
            String salesOrderId = productIdAndSalesOrderId.split(' ')[1];
            String productId = productIdAndSalesOrderId.split(' ')[0];
            
            if(!this.opptLineItemByProductIdAndSalesOrderId.containsKey(productIdAndSalesOrderId) 
                && opptLineItemSchedulesByOpptLineItemBySalesOrderId.containsKey(salesOrderId))
            {
                productIdSet.add(productId);
            }
        }
        
        Map<String, String> priceBookEntryIdMapByProductId = this.getPriceBookEntryIdMapByProductId(productIdSet);
        ////////////////
        
        // this step is essential when creating new opportunity line items if none exist.
        // Because we have to insert new opportunity line items to make their ids available in order to insert opportunity line item schedules, 
        // those new opportunity line items have to be bulkified insert first
        List<OpportunityLineItem> newOpportunityLineItems = new List<OpportunityLineItem>();
        
        //Set<OpportunityLineItem> revenueZeroOutOpportunityLineItems = new Set<OpportunityLineItem>();
        
        for(String productIdAndSalesOrderId : bookingLineItemsMapByProductIdAndSalesOrderId.keySet())
        {
            String salesOrderId = productIdAndSalesOrderId.split(' ')[1];
            String productId = productIdAndSalesOrderId.split(' ')[0];
            
            // if we cannot find any opportunity line item according to sales order id
            // find any opportunity line item with same sales order and, from there, find its opportunity.
            // Then, look for opportunity line item associated with same product, if found, update this opportunity line item.
            // If not, create a new opportunity line item (need to do this later, bulkified insertion)
            // and links to this opportunity
            if(!this.opptLineItemByProductIdAndSalesOrderId.containsKey(productIdAndSalesOrderId) 
                && opptLineItemSchedulesByOpptLineItemBySalesOrderId.containsKey(salesOrderId))
            {
                Map<OpportunityLineItem, List<OpportunityLineItemSchedule>> opptLineItemSchedulesByOpptLineItem = opptLineItemSchedulesByOpptLineItemBySalesOrderId.get(salesOrderId);
                
                // assume we always pickup the first opportunity line item and get opp
                OpportunityLineItem opptLineItem;
                
                for(OpportunityLineItem opptLi : opptLineItemSchedulesByOpptLineItem.keySet())
                {
                    opptLineItem = opptLi;
                    break; // as long as we get one opportunity line item, loop stops
                }
                
                // create OpportunityLineItem that link to same opportunity 
                OpportunityLineItem newOpptLineItem = new OpportunityLineItem();
                newOpptLineItem.PricebookEntryId = priceBookEntryIdMapByProductId.get(productId);
                newOpptLineItem.OpportunityId = opptLineItem.OpportunityId;
                newOpptLineItem.Sales_Order__c = salesOrderId;
                newOpptLineItem.Quantity = 1;
                newOpptLineItem.TotalPrice = 0;
                newOpportunityLineItems.add(newOpptLineItem);
                
                if(!this.salesOrderSetByOpportunityId.containsKey(opptLineItem.OpportunityId))
                {
                    this.salesOrderSetByOpportunityId.put(opptLineItem.OpportunityId, new Set<Id>());
                }
                this.salesOrderSetByOpportunityId.get(opptLineItem.OpportunityId).add(salesOrderId);
            }
            
            if(opptLineItemSchedulesByOpptLineItemBySalesOrderId.containsKey(salesOrderId))
            {
                for(OpportunityLineItem oli : opptLineItemSchedulesByOpptLineItemBySalesOrderId.get(salesOrderId).keySet())
                {
                    if(!this.salesOrderSetByOpportunityId.containsKey(oli.OpportunityId))
                    {
                        this.salesOrderSetByOpportunityId.put(oli.OpportunityId, new Set<Id>());
                    }
                    this.salesOrderSetByOpportunityId.get(oli.OpportunityId).add(salesOrderId);
                }
            }
        }
        
        // Insert new opportunity line items 
        // then, update bookingLineItemsMapByProductIdAndSalesOrderId and opptLineItemByProductIdAndSalesOrderId
        // to leave place holder for opportunity line item schedules in there 
        if(newOpportunityLineItems.size() > 0)
        {
        	try{
            	insert newOpportunityLineItems;
        	}
	        catch(Exception ex)
	        {
	            ExLog.log(ex, 'config', newOpportunityLineItems, 'SFE-824 Investigation');
	        }        	
            
            system.debug(loggingLevel.Error, '=====newOpportunityLineItems==== ' + newOpportunityLineItems);
            
            for(OpportunityLineItem opptLineItem : [Select o.PricebookEntry.Product2Id, o.PricebookEntryId, o.OpportunityId, o.Sales_Order__c
                                                   From OpportunityLineItem o
                                                   Where o.Id IN: newOpportunityLineItems])
            {
                opptLineItemSchedulesByOpptLineItemBySalesOrderId.get(opptLineItem.Sales_Order__c).put(opptLineItem, new List<OpportunityLineItemSchedule>());
                
                //String combKey = opptLineItem.PricebookEntry.Product2Id + ' ' + opptLineItem.Sales_Order__c;
               
                String combKey = generateCombKey(opptLineItem.PricebookEntry.Product2Id, opptLineItem.Sales_Order__c);
               
               system.debug('====BC: comb key 1==== ' + combKey);
               
                opptLineItemByProductIdAndSalesOrderId.put(combKey, opptLineItem);
            }
        }

        system.debug('====BC: opptLineItemSchedulesByOpptLineItemBySalesOrderId 2 ==== ' + opptLineItemSchedulesByOpptLineItemBySalesOrderId);
        system.debug('====BC: opptLineItemByProductIdAndSalesOrderId 2 ==== ' + opptLineItemByProductIdAndSalesOrderId);        
        
        
        List<OpportunityLineItemSchedule> upsertOpportunityLineItemSchedules = new List<OpportunityLineItemSchedule>(); // opportunity line item schedules to be insert and update
        List<OpportunityLineItemSchedule> deleteOpportunityLineItemSchedules = new List<OpportunityLineItemSchedule>(); // opportunity line item schedules to be delete
        
        for(String productIdAndSalesOrderId : bookingLineItemsMapByProductIdAndSalesOrderId.keySet())
        {
            String salesOrderId = productIdAndSalesOrderId.split(' ')[1];
            String productId = productIdAndSalesOrderId.split(' ')[0];
                        
            List<Booking_Line_Item__c> bookingLineItems = bookingLineItemsMapByProductIdAndSalesOrderId.get(productIdAndSalesOrderId);
            
            // process bookingLineItems
            // categories bookingLineItems according to their run date by start date of week
            Map<date, List<Booking_Line_Item__c>> bookingLineItemsByWeekStartDate = this.categoriesBookingLineItem(bookingLineItems);
            
            system.debug(loggingLevel.Error, '===productIdAndSalesOrderId=== ' + productIdAndSalesOrderId);
            system.debug(loggingLevel.Error, '===opptLineItemByProductIdAndSalesOrderId=== ' + opptLineItemByProductIdAndSalesOrderId);
            system.debug(loggingLevel.Error, '===opptLineItemSchedulesByOpptLineItemBySalesOrderId 3=== ' + opptLineItemSchedulesByOpptLineItemBySalesOrderId);
                
                if(this.opptLineItemByProductIdAndSalesOrderId.containsKey(productIdAndSalesOrderId))
                {
                    
                    OpportunityLineItem opptLineItem = this.opptLineItemByProductIdAndSalesOrderId.get(productIdAndSalesOrderId);
                    
                    system.debug(loggingLevel.Error, '===opptLineItem=== ' + opptLineItem);
                    
                    List<OpportunityLineItemSchedule> opptLineItemSchedules = opptLineItemSchedulesByOpptLineItemBySalesOrderId.get(salesOrderId).get(opptLineItem);
                    
                    // retrieve original oppotunity line item schedules for same sales order and same product,
                    // overwrite the existing schedules if there are any,
                    // otherwise, create new schedules or delete no longer needed schedules
                    
                    List<OpportunityLineItemSchedule> newOpportunityLineItemScheduleList = createOpportunityLineItemSchedules(bookingLineItemsByWeekStartDate, opptLineItem);

                    // this method is to sort opportnity line item schedules
                    // it also adds extra opportunity line item schedules into the gap where no consecutive schedules along the start date of week
                    newOpportunityLineItemScheduleList = this.sortOpportunityLineItemScheduleList(newOpportunityLineItemScheduleList); 
                    
                    system.debug('=====BC: newOpportunityLineItemScheduleList=== ' + newOpportunityLineItemScheduleList);
                                        
                    Integer newOpportunityLineItemScheduleListSize = newOpportunityLineItemScheduleList.size();
                    Integer oldOpportunityLineItemScheduleListSize = 0;
                    
                    if(opptLineItemSchedules != null)
                    {
                        oldOpportunityLineItemScheduleListSize = opptLineItemSchedules.size();
                    }
                    
                    Integer i = 0;
                    for(; i < newOpportunityLineItemScheduleListSize; i++)
                    {
                        OpportunityLineItemSchedule newScheduleItem = newOpportunityLineItemScheduleList[i];
                        
                        if(i < oldOpportunityLineItemScheduleListSize)
                        {
                            OpportunityLineItemSchedule scheduleItem = opptLineItemSchedules[i];
                            scheduleItem.Revenue = newScheduleItem.Revenue;
                            scheduleItem.ScheduleDate = newScheduleItem.ScheduleDate;
                            upsertOpportunityLineItemSchedules.add(scheduleItem); // updated schedules (overwrite existing schedule items)
                        }
                        else
                        {
                            newScheduleItem.Type = 'Revenue';
                            upsertOpportunityLineItemSchedules.add(newScheduleItem); // new schedules (create new schedule items)
                        }
                    }
                    
                    // if number of existing schedule items is more than needed, put them into delete list to be deleted later
                    while(i < oldOpportunityLineItemScheduleListSize)
                    {
                        deleteOpportunityLineItemSchedules.add(opptLineItemSchedules[i]); 
                        i++;
                    }
                }
        }
        
        system.debug(loggingLevel.Error, '====BC:opportunityLineItemMapById.values()=== ' + opportunityLineItemMapById.values());
        system.debug(loggingLevel.Error, '====BC:upsertOpportunityLineItemSchedules=== ' + upsertOpportunityLineItemSchedules);
        try{
        	upsert upsertOpportunityLineItemSchedules;
        }
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', upsertOpportunityLineItemSchedules, 'SFE-824 Investigation');
        }
        
        try{
        	delete deleteOpportunityLineItemSchedules;
        }
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', deleteOpportunityLineItemSchedules, 'SFE-824 Investigation');
        }
    }


    public void processOpportunityScheduleItems()
    {
        // Update service date on opportunity line item based on run date of earliest booking line item matched
        List<OpportunityLineItem> opportunityLineItems = [Select ServiceDate, TotalPrice From OpportunityLineItem 
                                                    Where Id IN: opportunityLineItemMapById.keySet()];
        
        for(OpportunityLineItem oli : opportunityLineItems)
        {
            system.debug('===TotalPrice1== ' + oli.TotalPrice);
            system.debug('===TotalPrice2== ' + opportunityLineItemMapById.get(oli.Id).TotalPrice);
            
            oli.ServiceDate = opportunityLineItemMapById.get(oli.Id).ServiceDate;
            //oli.TotalPrice = opportunityLineItemMapById.get(oli.Id).TotalPrice;
        }
        
        try{
        	update opportunityLineItems;
        }
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', opportunityLineItems, 'SFE-824 Investigation');
        }
        
        if(duplicateOpptLineItems.size() > 0)
        {
            // delete duplicate opportunity line items
            system.debug('===duplicateOpptLineItems=== ' + duplicateOpptLineItems); 
            try{            
            	delete duplicateOpptLineItems;
            }
            catch(Exception ex)
	        {
	            ExLog.log(ex, 'config', duplicateOpptLineItems, 'SFE-824 Investigation');
	        }
        }
    }
    
    private List<OpportunityLineItemSchedule> createOpportunityLineItemSchedules(
                            Map<date, List<Booking_Line_Item__c>> bookingLineItemsByWeekStartDate,
                            OpportunityLineItem opptLineItem)
    {
        List<OpportunityLineItemSchedule> opportunityLineItemSchedules = new List<OpportunityLineItemSchedule>();
        
        for(Date weekStartDate : bookingLineItemsByWeekStartDate.keySet())
        {
            decimal revenue;
            
            for(Booking_Line_Item__c bookingLineItem : bookingLineItemsByWeekStartDate.get(weekStartDate))
            {
                if(revenue == null && bookingLineItem.Gross_Price__c != null)
                {
                    revenue = bookingLineItem.Gross_Price__c;
                }
                else if(revenue != null && bookingLineItem.Gross_Price__c != null)
                {
                    revenue += bookingLineItem.Gross_Price__c;
                }
                
                // updated requirement: to be able to update service date on 
                // opportunity line item to the earliest date on booking line items
                if(bookingLineItem.Gross_Price__c != null)
                {
                    if(!opportunityLineItemMapById.containsKey(opptLineItem.Id))
                    {
                        opptLineItem.ServiceDate = bookingLineItem.run_date__c;
                        opportunityLineItemMapById.put(opptLineItem.Id, opptLineItem);
                    }
                    else
                    {
                        OpportunityLineItem tmpOpptLineItem = opportunityLineItemMapById.get(opptLineItem.Id);
                        
                        if(tmpOpptLineItem.ServiceDate > bookingLineItem.run_date__c)
                        {
                            tmpOpptLineItem.ServiceDate = bookingLineItem.run_date__c;
                        }
                    }
                }
                system.debug('====BC: opportunityLineItemMapById == ' + opportunityLineItemMapById);
            }
            
            if(revenue != null)
            {
                OpportunityLineItemSchedule opptLineItemSchedule = new OpportunityLineItemSchedule();
                opptLineItemSchedule.ScheduleDate = weekStartDate;
                opptLineItemSchedule.Revenue = revenue;
                opptLineItemSchedule.Type = 'Revenue';
                opptLineItemSchedule.OpportunityLineItemId = opptLineItem.Id;
                opportunityLineItemSchedules.add(opptLineItemSchedule);
            }
        }
        
        return opportunityLineItemSchedules;
    }
    
    private Map<date, List<Booking_Line_Item__c>> categoriesBookingLineItem(
                                    List<Booking_Line_Item__c> bookingLineItems)
    {
        Map<date, List<Booking_Line_Item__c>> bookingLineItemsByWeekStartDate = new Map<date, List<Booking_Line_Item__c>>();
        
        system.debug('===weekStartDayByRunDate=== ' + weekStartDayByRunDate);
        
        for(Booking_Line_Item__c bookingLineItem : bookingLineItems)
        {
            //if(bookingLineItem.Run_Date__c != null) // TODO: refer to Penelope's email on 24th Sept. adding this line is for data uploading purpose only
            //{
                // find week start day in current fiscal year for run date
                Integer weekStartDay = weekStartDayByRunDate.get(bookingLineItem.Run_Date__c);
    
                // find week start date of booking line item run date 
                Integer dayOfWeek = math.mod(date.newInstance(1900, 1, 6).daysBetween(bookingLineItem.Run_Date__c), 7);
                
                system.debug('====bookingLineItem=== ' + bookingLineItem);
                system.debug('====run date=== ' + bookingLineItem.Run_Date__c);
                system.debug('====weekStartDay=== ' + weekStartDay);
                system.debug('====dayOfWeek=== ' + dayOfWeek);
                
                
                Date weekStartDate;
                if(weekStartDay <= dayOfWeek)
                {
                    weekStartDate = bookingLineItem.Run_Date__c.addDays(weekStartDay - dayOfWeek);
                }
                else
                {
                    weekStartDate = bookingLineItem.Run_Date__c.addDays(weekStartDay - dayOfWeek - 7);
                }
                
                system.debug('=====weekStartDay====' + weekStartDay);
                system.debug('=====weekStartDate====' + weekStartDate);
                
                if(!bookingLineItemsByWeekStartDate.containsKey(weekStartDate))
                {
                    bookingLineItemsByWeekStartDate.put(weekStartDate, new List<Booking_Line_Item__c>());
                }
                
                bookingLineItemsByWeekStartDate.get(weekStartDate).add(bookingLineItem);
            //}
        }
        
        system.debug(loggingLevel.Error, '====BC: bookingLineItemsByWeekStartDate=== ' + bookingLineItemsByWeekStartDate);
        
        return bookingLineItemsByWeekStartDate;
    }
        
    public List<FiscalYearSettings> getFiscalYearSetting()
    {
        system.debug(logginglevel.Error, '===year setting query===');
        List<FiscalYearSettings> fySettingList = [Select f.WeekStartDay, f.StartDate, f.EndDate 
                                                From FiscalYearSettings f
                                                Where f.IsStandardYear = false];
        
        return fySettingList;
    }
    
    private Map<String, String> getPriceBookEntryIdMapByProductId(List<Id> productIdSet)
    {
        Map<String, String> priceBookEntryIdMapByProductId = new Map<String, String>();
        
        try
        {
            // SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
                // Added isRunningTest & in case of test class rung remove standard pricebook condition from Query
            if(!Test.isRunningTest()){
                // Updated by Bohao Chen on 29/05/2014 
                // To fix test method createOscaBookingTest in BookingLineItemManagement_Trigger_Test.
                // Error details when running above test class: pricebook entry is in a different pricebook than the one assigned to the opportunity
                // Begin:                
                for(PricebookEntry p : [Select p.Product2Id From PricebookEntry p 
                                        Where p.Product2Id IN: productIdSet And p.Pricebook2.IsStandard = true])
                {
                    priceBookEntryIdMapByProductId.put(p.Product2Id, p.Id);
                }
            }
            else{
                for(PricebookEntry p : [Select p.Product2Id From PricebookEntry p 
                                        Where p.Product2Id IN: productIdSet])
                {
                    priceBookEntryIdMapByProductId.put(p.Product2Id, p.Id);
                }
            }
            // End
        } catch(exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.Error, e.getMessage()));
        }
        
        return priceBookEntryIdMapByProductId;
    }
    
    // this method is to sort opportnity line item schedules
    // it also adds extra opportunity line item schedules into the gap where no consecutive schedules along the start date of week
    private List<OpportunityLineItemSchedule> sortOpportunityLineItemScheduleList(List<OpportunityLineItemSchedule> opportunityLineItemScheduleList)
    {
        system.debug('====BC: before sort=== ' + opportunityLineItemScheduleList);
        
        List<OpportunityLineItemSchedule> sortedOpportunityLineItemScheduleList = new List<OpportunityLineItemSchedule>();
        Map<Date, OpportunityLineItemSchedule> opportunityLineItemScheduleByDate = new Map<Date, OpportunityLineItemSchedule>();
        
        Date startDate, endDate;
        String opptLineItemId;
        
        for(OpportunityLineItemSchedule opptLineItemSchedule : opportunityLineItemScheduleList)
        {
            if(opptLineItemId == null)
            {
                opptLineItemId = opptLineItemSchedule.OpportunityLineItemId;
            }
            
            if(startDate == null || opptLineItemSchedule.ScheduleDate < startDate)
            {
                startDate = opptLineItemSchedule.ScheduleDate;
            }
            
            if(endDate == null || opptLineItemSchedule.ScheduleDate > endDate)
            {
                endDate = opptLineItemSchedule.ScheduleDate;
            }
            
            opportunityLineItemScheduleByDate.put(opptLineItemSchedule.ScheduleDate, opptLineItemSchedule);
        }
        
        system.debug('====start date== ' + startDate + ' | ==== end date==== ' + endDate);
        
        while(startDate <= endDate)
        {
            if(opportunityLineItemScheduleByDate.containsKey(startDate))
            {
                sortedOpportunityLineItemScheduleList.add(opportunityLineItemScheduleByDate.get(startDate));
            }

            startDate = startDate.addDays(7);
        }
        
        system.debug('====BC: after sort=== ' + sortedOpportunityLineItemScheduleList);
        
        return sortedOpportunityLineItemScheduleList;
    }
    
    /* 
     * this function is used by trigger BookingLineItemManagement
     * it checks whether booking line item run date has fiscal calendar in setting.
     * It also generate map collection of week start day for booking line item run date
     * with run date as key so it is easy to find out week start day based on booking line
     * item run date
     * Note that we need to set up weekStartDayByRunDate MAP collection in order for other booking line item with same product to
     * know which week it belongs to according to their run date. 
     */
    public Boolean isRunDateInFiscalCalendar(Booking_Line_Item__c bookingLineItem)
    {
        // find week start day in current fiscal year for run date
        boolean found = false;
        
        for(FiscalYearSettings fySetting : fiscalYearSettingByStartDate)
        {
            if(fySetting.StartDate <= bookingLineItem.Run_Date__c && fySetting.EndDate >= bookingLineItem.Run_Date__c)
            {
                found = true;
                break;
            }
        }
        
        if(!found)
        {
            bookingLineItem.addError('Could not find fiscal year calendar based on current booking line item run date. <br />Please change the run date or contact your administrator to add fiscal year calendar for current run date', false);
            return true;
        }
        
        return false;
    }
    
    public void getWeekStartDayByRunDate()
    {
        for(String productIdAndSalesOrderId : this.bookingLineItemsMapByProductIdAndSalesOrderId.keySet())
        {
            for(Booking_Line_Item__c bookingLineItem : bookingLineItemsMapByProductIdAndSalesOrderId.get(productIdAndSalesOrderId))
            {
                // find week start day in current fiscal year for run date
                Integer weekStartDay;
                 
                boolean found = false;
                for(FiscalYearSettings fySetting : fiscalYearSettingByStartDate)
                {
                    if(fySetting.StartDate <= bookingLineItem.Run_Date__c && fySetting.EndDate >= bookingLineItem.Run_Date__c)
                    {
                        weekStartDay = fySetting.WeekStartDay;
                        weekStartDayByRunDate.put(bookingLineItem.Run_Date__c, weekStartDay);
                        found = true;
                        break;
                    }
                }
            }
        }
    }
    
    // reset and initialise values in all collections in this controller 
    public void cleanUpCollectionsValues()
    {
        // need to clean up values for all collections
        this.salesOrderIdSet.clear();
        this.opptLineItemByProductIdAndSalesOrderId.clear();
        this.weekStartDayByRunDate.clear();
        this.bookingLineItemsMapByProductIdAndSalesOrderId.clear();
        this.opportunityIdSet.clear();
        this.salesOrderSetByOpportunityId.clear();
        this.opportunityLineItemMapById.clear();
    }
    
    public String generateCombKey(String productId, String salesOrderId)
    {
        return productId + ' ' + salesOrderId;
    }   
    
}
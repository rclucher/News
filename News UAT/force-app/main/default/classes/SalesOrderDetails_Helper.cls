/*---------------------------------------------------------
* Author: Bluewolf
* Description: 
* Date: 
* History:
* 2016-01-05   Atul Gupta   Updated
---------------------------------------------------------*/
global without sharing class SalesOrderDetails_Helper {



    public static ID upsertSalesOrderDertails(SalesOrderWrapper sow)
    {

        System.debug('sow:' + sow);

        Booking__c booking = convertSalesOrderWrapperToBooking(sow);

        if(booking==null)
        {
            throw new SalesOrderDetailsException('Booking could not be created');
            return null;
        }

        System.debug('booking:' + booking);
        System.debug('booking.id:' + booking.id);
        
        try{
        	upsert booking;
		}
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', booking, 'SFE-824 Investigation');
        }

        if(sow.parameter.containsKey('caseSourceSFID'))
        {
        	Case c;
            try
            {
                c = [Select id, Booking__c, Sales_Order__c from Case where id =:sow.parameter.get('caseSourceSFID')];              
                c.Booking__c = booking.id;
                c.Sales_Order__c = booking.Sales_Order__c;
                update c;               
            }
            catch (Exception ex) {
                System.debug('Error @ upsertSalesOrderDertails:' + ex.getMessage());
                ExLog.log(ex, 'config', c, 'SFE-824 Investigation');
            }
        
        }

        //add booking salesforce ID to the wrapper to be used on the update/creation of the line item
        sow.parameter.put('bookingSFID',booking.id);
        
        
        return booking.id;
        
    }


    private static Booking__c convertSalesOrderWrapperToBooking(SalesOrderWrapper sow)
    {

        Booking__c booking;

        if(sow.parameter.containsKey('salesOrderSFID'))
        {

            Sales_Order__c so = [Select External_Account__c
                                    From Sales_Order__c
                                    Where id =: sow.parameter.get('salesOrderSFID')];


            booking = new Booking__c();

            if(sow.parameter.containsKey('bookingSFID'))
            {
                Booking__c tmpbooking = [Select     id,
                                    Source_System__c,
                                    //Last_Expiry_Appearance__c,
                                    Total_Cost_Cyber__c,
                                    Run_Schedule__c,
                                    //Booking_System_Contact__c,
                                    Booked_Point__c,
                                    Third_Party_Created__c,
                                    Sales_Order__c,
                                    Name,
                                    Booking_number__c
                            From    Booking__c
                            Where   id = :sow.parameter.get('bookingSFID')];


                    // get the current if booking is NOT cloned in CyberAd
                    if(tmpbooking.Name.trim() == sow.salesOrder.bookingID.trim())
                    {
                        booking = tmpbooking;
                    }
            }


            if(booking.Third_Party_Created__c == null)
            {
                booking.Third_Party_Created__c = System.now();
            }

            //Sales Order and bookings are now master detail and cannot be re-parented 
            if(booking.Sales_Order__c==null)
                booking.Sales_Order__c  =   sow.parameter.get('salesOrderSFID');


            if(sow.parameter.containsKey('campaignSFID'))
            {
                booking.campaign__c = sow.parameter.get('campaignSFID');
            }

			//SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - Dead code removed
			
            booking.Name                        =   sow.salesOrder.bookingID; //## is the Booking Number?
            booking.Booking_Number__c           =   sow.salesOrder.bookingNum;
            booking.CyberAd_AdType__c           =   sow.salesOrder.adType;
            booking.Source_System__c            =   sow.salesOrder.sourceSystem=='Cyber'?'CyberAd':sow.salesOrder.sourceSystem;
            //booking.Last_Expiry_Appearance__c =   Date.parse(sow.salesOrder.lastDate.split(' ')[0]);
            booking.Total_Cost_Cyber__c         =   Decimal.valueOf(sow.salesOrder.totalCost);
            booking.Run_Schedule__c             =   sow.salesOrder.runSchedule;
            //booking.Booking_System_Contact__c =   sow.salesOrder.bookingContact;
            booking.Booked_Point__c             =   sow.salesOrder.bookedPoint;
            // ## set through workflow # // booking.External_Id__c             =   formatBookingExternalId(sow);
            booking.External_Account__c         =   so.External_Account__c;
            booking.External_Sales_Division__c  =   sow.salesOrder.divisionName;
            booking.Status__c                   =   sow.salesOrder.status;
            booking.CyberAd_Ad_Type__c          =   sow.salesOrder.adType;
            booking.CyberAd_Division__c         =   sow.salesOrder.divisionName;
            booking.CyberAd_Classification__c   =   sow.salesOrder.classificationCode;
            booking.CyberAd_Publication__c      =   sow.salesOrder.publicationName;
        }


        
            
        return booking;
    }
	
	//SFE-766 2016-01-05 atul.gupta@bluewolfgroup.com - Method annotated with @TestVisible to make it visible to Test Class
	@TestVisible
    private static Booking_Line_Item__c convertSalesOrderWrapperToBookingLineItem(SalesOrderWrapper sow)
    {

        Booking_Line_Item__c bookingLineItem = new Booking_Line_Item__c();

        String bookingId = sow.parameter.containsKey('bookingSFID')!=null?sow.parameter.get('bookingSFID'):'';

        date startDate = Date.parse(sow.salesOrder.startDate.split(' ')[0]);

            for(Booking_Line_Item__c bli : [Select Lines__c,
                                                    Publication__c,
                                                    Run_Date__c,
                                                    Classification__c,
                                                    Depth__c,
                                                    Caption__c
                                                From Booking_Line_Item__c
                                                Where Booking__c = :bookingId
                                                  OR  (Publication__c = :sow.salesOrder.productID
                                                  AND Run_Date__c = :startDate)
                                                Limit 1])
            {
                bookingLineItem = bli;
            }

            if(bookingLineItem.id==null)
                bookingLineItem.Booking__c          =   sow.parameter.get('bookingSFID');

            bookingLineItem.Lines__c            =   Decimal.valueOf(sow.salesOrder.newsLines);
            bookingLineItem.Publication__c      =   sow.salesOrder.productID;
            bookingLineItem.Run_Date__c         =   startDate;
            bookingLineItem.Classification__c   =   sow.salesOrder.classificationCode;
            bookingLineItem.Depth__c            =   Decimal.valueOf(sow.salesOrder.newsDepth);
            bookingLineItem.Caption__c          =   sow.salesOrder.newsCaption;
            bookingLineItem.Publication__c      =   sow.salesOrder.publicationName;
            bookingLineItem.Division__c         =   sow.salesOrder.divisionName;
            bookingLineItem.Ad_Type__c          =   sow.salesOrder.adType;
            bookingLineItem.Status__c           =   sow.salesOrder.status;

        System.debug('BookingLineItem:' + BookingLineItem);
        return bookingLineItem;
    }

	//SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - Dead Code Removed

  //SFE-766 2016-01-05 atul.gupta@bluewolfgroup.com - Method annotated with @TestVisible to make it visible to Test Class
  @TestVisible
  private static OpportunityLineItem createDummyOpportunityLineItem(Sales_Order__c inSalesOrder, Opportunity inOpportunity)
    {
        system.debug('@ createDummyOpportunityLineItem()');
        PricebookEntry pricebookEntry = new PricebookEntry();
        OpportunityLineItem oli = new OpportunityLineItem();
        Product2 prod = [Select id From Product2 Where Name=:'Dummy'];
        Id pricebookId = [Select p.Name, p.Id From Pricebook2 p where Name = 'Standard Price Book'].id;
        
        pricebookEntry = [Select p.UnitPrice, p.Product2Id, p.Pricebook2Id From PricebookEntry p
                                        Where   Pricebook2Id = :pricebookId
                                         AND    Product2Id = :prod.id];

        oli.Sales_Order__c = inSalesOrder.id;
        oli.opportunityId = inOpportunity.id;
        oli.PricebookEntryId = pricebookEntry.id;
        oli.quantity = 1;
        oli.totalPrice = 0;

        return oli;
    }

    //SFE-766 2016-01-05 atul.gupta@bluewolfgroup.com - Method annotated with @TestVisible to make it visible to Test Class
    @TestVisible
    private static string formatBookingExternalId(SalesOrderWrapper sow, Booking__c booking)
    {
        dateTime d = booking.Third_Party_Created__c;
        string year     = String.valueOf(d.year());
        string month    = String.valueOf(d.month());
        string day      = String.valueOf(d.day());         

        month   = month.length()<2?'0' + month:month;
        day     = day.length()<2?'0' + day:day;

        return 'CyberAd_' + sow.salesOrder.divisionName
                + sow.salesOrder.bookingID + '_'
                + year + month + day;
    }

    /*  ----------------------------------------------------------------
        Created by:     Timothy Fabros
        Updated by:     Bohao Chen
        Date created:   23 / 05 / 2014
        Company:        Bluewolf
        ----------------------------------------------------------------
        METHOD: webService
        
        Created for SFE - 429

        Creates an opportunity for a Sales_Order__c record if not already
        linked to an opportunity. If error occurs during this process, 
        return a string containing the error

        INPUT:  String(Sales_Order__c.Id)
        OUTPUT: string(error message)
        ---------------------------------------------------------------- */
    // BEGIN: SFE - 429
    webService static String createOpportunityAndLineItems(String salesOrderId) 
    {
        if(salesOrderId != null)
        {
            // query all booking line items belong to this sales order
            List<Booking_Line_Item__c> bookingLineItems = [Select b.Name, b.Run_Date__c, b.Product__c, b.Gross_Price__c, b.Booking__r.Sales_Order__c,
                                                                b.Booking__r.Sales_Order__r.Payer_Account__c, b.Booking__r.Sales_Order__r.Advertiser_Account__c,
                                                                b.Booking__r.Sales_Order__r.Advertiser_Account__r.Name, b.Booking__r.Sales_Rep__c, 
                                                                b.Booking__r.Sales_Order__r.Advertiser_Account__r.Revenue_Group__c,
                                                                b.Booking__r.Sales_Order__r.Advertiser_Account__r.Industry_Code__c
                                                            From Booking_Line_Item__c b
                                                            Where b.Booking__r.Sales_Order__c =: salesOrderId
                                                            Order by b.Booking__r.createdDate DESC];

            if(bookingLineItems.size() > 0)
            {
                Booking_Line_Item__c bookingLineItem = bookingLineItems[0];

                // create the opportunity
                Opportunity opportunity = new Opportunity();
                opportunity.Opportunity_Type__c = 'Walk-In';
                opportunity.Payer_Account__c = bookingLineItem.Booking__r.Sales_Order__r.Payer_Account__c;
                opportunity.AccountId = bookingLineItem.Booking__r.Sales_Order__r.Advertiser_Account__c;
                opportunity.RecordTypeId = Global_Helper.getRecordTypeIdByName('Walk-in', 'Opportunity');

                Date today = Date.today();
                Integer year = today.year();
                Integer month = today.month();
                Integer day = today.day();

                opportunity.name =  bookingLineItem.Booking__r.Sales_Order__r.Advertiser_Account__r.Name + ' - ' + year + month + day;
                opportunity.type = 'Non-Core Activity';
                opportunity.Revenue_Group__c = bookingLineItem.Booking__r.Sales_Order__r.Advertiser_Account__r.Revenue_Group__c;
                opportunity.Industry_Code__c = bookingLineItem.Booking__r.Sales_Order__r.Advertiser_Account__r.Industry_Code__c;
                opportunity.Description = salesOrderId; // sales order id in description is to find opportunity based on sales order id
                opportunity.StageName = 'Closed Won'; 
                opportunity.CloseDate = Date.today(); 
                //ND 10/04 set amount to avoid validation
                opportunity.amount = 0; 

                String salesRepId;

                // try to find sales rep from the most recent booking 
                if(bookingLineItems[0].Booking__r.Sales_Rep__c != null)
                {
                    String networkUsername = bookingLineItems[0].Booking__r.Sales_Rep__c;

                    List<User> salesReps = [Select u.Network_Username__c From User u Where u.Network_Username__c =: networkUsername];

                    if(!salesReps.isEmpty())
                        salesRepId = salesReps[0].Id;
                }
                
                // try to get default sales rep id from Custom setting -> System parameters -> Default Sales Rep if the most recent booking doesn't have sales rep
                if(salesRepId == null)
                {
                    SystemParameters__c defaultSalesRep = SystemParameters__c.getAll().get('Default Sales Rep');

                    if(defaultSalesRep != null)           
                        salesRepId = defaultSalesRep.Value__c;
                }

                // if sales rep id is still null, throw exception. Otherwise, assign sales rep to be the owner of newly created opportunity
                if(salesRepId != null)
                {
                    opportunity.OwnerId = salesRepId;
                }
                else
                {
                    throw new CreateOpportunityException('Couldn\'t find sales rep on the most recent booking or default sales rep hasn\'t been set up in custom setting');
                    return null;
                }

                // setup save point in case we have dml operation exception later
                system.savepoint sp = Database.setSavepoint();

                // insert opportunity 
                try
                {
                    insert opportunity;
                } catch (Exception e) {
                    Database.rollBack(sp);
                    ExLog.log(e, 'config', opportunity, 'SFE-824 Investigation');
                    throw new CreateOpportunityException('Insert opportunities error(s): ' + e.getMessage());
                }

                // loop through booking line items
                // create opportunity line items based on booking line items               
                // firsly, we need to group booking line items by products
                Map<Id, List<Booking_Line_Item__c>> bookingLineItemsByProductId = new Map<Id, List<Booking_Line_Item__c>>();

                for(Booking_Line_Item__c bli: bookingLineItems)
                {
                    if(bli.Product__c != null)
                    {
                        if(!bookingLineItemsByProductId.containsKey(bli.Product__c))
                        {
                            bookingLineItemsByProductId.put(bli.Product__c, new List<Booking_Line_Item__c>());
                        }

                        bookingLineItemsByProductId.get(bli.Product__c).add(bli);
                    }
                    else
                    {
                        Database.rollBack(sp);
                        throw new CreateOpportunityException('Booking line item ' + bli.Name + ' doesn\'t have a product associated with.');
                    }
                }

                system.debug('@createOpportunityAndLineItems bookingLineItemsByProductId: ' + bookingLineItemsByProductId);

                // get price book entry Id based on product key set
                Map<String, String> priceBookEntryIdMapByProductId = new Map<String, String>();

                for(PricebookEntry pe : [Select p.Product2Id From PricebookEntry p Where p.Product2Id IN: bookingLineItemsByProductId.keySet()])
                {
                    priceBookEntryIdMapByProductId.put(pe.Product2Id, pe.Id);
                }

                system.debug('@createOpportunityAndLineItems priceBookEntryIdMapByProductId: ' + priceBookEntryIdMapByProductId);

                // loop through MAP bookingLineItemsByProductId
                // create opportunity line items for each product
                List<OpportunityLineItem> opptyLineItems = new List<OpportunityLineItem>();

                for(Id productId : bookingLineItemsByProductId.keySet())
                {
                    if(priceBookEntryIdMapByProductId.containsKey(productId)) // get pricebook entries for products
                    {
                        OpportunityLineItem oli = new OpportunityLineItem();
                        oli.OpportunityId = opportunity.Id;
                        oli.UnitPrice = 0;
                        oli.Quantity = 1;
                        oli.PricebookEntryId = priceBookEntryIdMapByProductId.get(productId);  
            		    oli.Sales_Order__c = salesOrderId;                                             
                        opptyLineItems.add(oli);                        
                    }
                }


				Map<Id, Id> opptyLineItemIdByPriceBookEntryId = new Map<Id, Id>();
				
                if(opptyLineItems.size() > 0)
                {                
                    try
                    {
                        insert opptyLineItems;
                        
                        for(OpportunityLineItem oli : opptyLineItems)
                        {
                        	opptyLineItemIdByPriceBookEntryId.put(oli.PricebookEntryId, oli.Id);
                        }
                        
                    } catch (Exception e) {
                        Database.rollBack(sp);
                        ExLog.log(e, 'config', opptyLineItems, 'SFE-824 Investigation');
                        throw new CreateOpportunityException('Insert opportunity line items error(s): ' + e.getMessage());
                    }
                }
                
	            system.debug('@createOpportunityAndLineItems opptyLineItems: ' + opptyLineItems);
	            system.debug('@createOpportunityAndLineItems opptyLineItemIdByPriceBookEntryId: ' + opptyLineItemIdByPriceBookEntryId);
                
                // check if fiscal calendar exist for booking line item run date
                Boolean noFiscalCalendarFound;

                for(Booking_Line_Item__c bli : bookingLineItems)
                {
                    noFiscalCalendarFound = BookingLineItemManagement_Helper.isRunDateInFiscalCalendar(bli);
                }
				
				// if all booking line items have fiscal calendar, continue
                if(!noFiscalCalendarFound)
                {
                	// firsly, find out week start day in current fiscal year for each booking line item run date
                	Map<Date, Integer> weekStartDayByRunDate = new Map<Date, Integer>();
                	                	
                	for(Booking_Line_Item__c bli : bookingLineItems)
		            {
		                // find week start day in current fiscal year for run date
		                Integer weekStartDay;
		                 
		                boolean found = false;
		                
		                for(FiscalYearSettings fySetting : BookingLineItemManagement_Helper.fiscalYearSettingByStartDate)
		                {
		                    if(fySetting.StartDate <= bli.Run_Date__c && fySetting.EndDate >= bli.Run_Date__c)
		                    {
		                        weekStartDay = fySetting.WeekStartDay;
		                        weekStartDayByRunDate.put(bli.Run_Date__c, weekStartDay);
		                        found = true;
		                        break;
		                    }
		                }
		            }
					
					Map<Date, Map<Id, OpportunityLineItemSchedule>> opptyLineItemSchedulesByProductIdByWeekStartDate = new Map<Date, Map<Id, OpportunityLineItemSchedule>>();
					 
                	for(Booking_Line_Item__c bli : bookingLineItems)
                    {
                    	system.debug('@SalesOrderDetails_Helper createOpportunityAndLineItems bli: ' + bli);
                    	
                    	// calculate week start date according to booking line item week start day
                    	Integer weekStartDay = weekStartDayByRunDate.get(bli.Run_Date__c);
                    	
                    	// find week start date of booking line item run date 
                		Integer dayOfWeek = math.mod(date.newInstance(1900, 1, 6).daysBetween(bli.Run_Date__c), 7);
                    	
                    	Date weekStartDate;
		                if(weekStartDay <= dayOfWeek)
		                {
		                    weekStartDate = bli.Run_Date__c.addDays(weekStartDay - dayOfWeek);
		                }
		                else
		                {
		                    weekStartDate = bli.Run_Date__c.addDays(weekStartDay - dayOfWeek - 7);
		                }
                    	
                    	system.debug('@SalesOrderDetails_Helper createOpportunityAndLineItems weekStartDate: ' + weekStartDate);
                    	
                    	// generates opportunity line item schedules                    	                    
                    	if(!opptyLineItemSchedulesByProductIdByWeekStartDate.containsKey(weekStartDate))
                    	{
                    		opptyLineItemSchedulesByProductIdByWeekStartDate.put(weekStartDate, new Map<Id, OpportunityLineItemSchedule>());                    		
                    	}
                    	
                    	if(!opptyLineItemSchedulesByProductIdByWeekStartDate.get(weekStartDate).containsKey(bli.Product__c))
                    	{
			                // get price book entry id
                    		String PricebookEntryId = priceBookEntryIdMapByProductId.get(bli.Product__c);                        
                    		
                    		// get opportunity line item id by price book entry id
                    		String opportunityLineItemId = opptyLineItemIdByPriceBookEntryId.get(PricebookEntryId);
                    		
                    		OpportunityLineItemSchedule olis = new OpportunityLineItemSchedule();
                    		olis.Revenue = bli.Gross_Price__c;
    		                olis.ScheduleDate = weekStartDate;
			                olis.Type = 'Revenue';
			                //olis.OpportunityLineItemId = bli.Id;

                            system.debug('@opportunityLineItemId: ' + opportunityLineItemId);

                		    olis.OpportunityLineItemId = opportunityLineItemId;
                    		opptyLineItemSchedulesByProductIdByWeekStartDate.get(weekStartDate).put(bli.Product__c, olis);
                    	}
                    	else
                    	{
                    		opptyLineItemSchedulesByProductIdByWeekStartDate.get(weekStartDate).get(bli.Product__c).Revenue += bli.Gross_Price__c;
                    	}
                    }
                    
					List<OpportunityLineItemSchedule> opportunityLineItemSchedules = new List<OpportunityLineItemSchedule>();
                    
                    if(opptyLineItemSchedulesByProductIdByWeekStartDate.size() > 0)
                	{
                		for(Date wsd : opptyLineItemSchedulesByProductIdByWeekStartDate.keySet())
                		{
                			opportunityLineItemSchedules.addAll(opptyLineItemSchedulesByProductIdByWeekStartDate.get(wsd).values());
                		}
                	}
                    
                	system.debug('@SalesOrderDetails_Helper createOpportunityAndLineItems opptyLineItemSchedulesByProductIdByWeekStartDate: ' + opptyLineItemSchedulesByProductIdByWeekStartDate);
                	system.debug('@SalesOrderDetails_Helper createOpportunityAndLineItems opportunityLineItemSchedules: ' + opportunityLineItemSchedules);
                    
                    // insert opportunity line item schedules
                	if(opportunityLineItemSchedules.size() > 0)
                	{
                		try
                		{
                			insert opportunityLineItemSchedules;
                		} catch(Exception e) {
	                        Database.rollBack(sp);
	                        ExLog.log(e, 'config', opportunityLineItemSchedules, 'SFE-824 Investigation');
                        	throw new CreateOpportunityException('Insert opportunity line item schedules error(s): ' + e.getMessage());
                            return null;
                		}
                	}
                }
                else
                {
                	Database.rollBack(sp);
                    throw new CreateOpportunityException('No fiscal calendar found for booking line items');
                    return null;
                }

                system.debug('@createOpportunityAndLineItems opportunity name is: ' + opportunity.Name);
                return opportunity.Name;
            }
            else
            {
                throw new CreateOpportunityException('Booking line items don\'t exist for this sales order.');
                return null;
            }
        }
        else
        {
            throw new  CreateOpportunityException('Sales order id cannot be null');
            return null;
        }
    }

    public class CreateOpportunityException extends Exception {}    
    // END: SFE - 429

    public class SalesOrderDetailsException extends Exception {}

    global class SalesOrderWrapper {
    
        public string message {get;set;}
        public String orderId {get;set;}
        public SalesOrderDetail salesOrder {get;set;}
        public map<String, String> parameter {get;set;}
    
    }

    global class SalesOrderDetail {

        public String bookingDivision {get;set;}
        public String bookingNum {get;set;}
        public String placerConId {get;set;}

        public String salesOrderID {get;set;}
        public String billingAccountID {get;set;}
        public String bookingID {get;set;}
        public String orderId {get;set;}
        public String divisionName {get;set;}
        public String publicationName {get;set;}
        public String adType {get;set;}
        public String placerContact {get;set;}
        public String payerAccount {get;set;}
        public String bookingprofile {get;set;}
        public String placerFName {get;set;}
        public String placerLName {get;set;}
        public String intgID {get;set;}
        public String main {get;set;}
        public String address {get;set;}
        public String city {get;set;}
        public String postCode {get;set;} //Postcode
        public String bpType {get;set;}
        public String baType {get;set;}
        public String baNumber {get;set;}
        public String accountName {get;set;}
        public String localNumber {get;set;}
        public String areaCode {get;set;}
        public String createdDate {get;set;}
        public String baName {get;set;}
        public String state {get;set;}
        public String country {get;set;}
        public String status {get;set;}
        public String sourceSystem {get;set;}
        public String bookingContact {get;set;}
        public String newsLines {get;set;}
        public String searchDate {get;set;}
        public String productID {get;set;}
        public String startDate {get;set;}
        public String lastDate {get;set;}
        public String totalCost {get;set;}
        public String runSchedule {get;set;}
        public String classificationCode {get;set;}
        public String newsDepth {get;set;}
        public String newsCaption {get;set;}
        public String bookingAccount {get;set;}
        public String bookedPoint {get;set;}
        //public String campaignID {get;set;}
        //public String contactID {get;set;}
        //public String opportunityID {get;set;}

        public String salesOrderSFID {get;set;}
        public String bookingSFID {get;set;}

    }
}
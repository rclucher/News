/*---------------------------------------------------------
* Author:  Stuart Hamilton
* Company: Salesforce.com
* Test Class: SalesOrderCreateBookingHelper_Test
* Description: Helper class for linking & creating Opportunities & Sales Orders
* History:
* 14/06/2013  Stuart Hamilton  Created
* 2016-01-05  Atul Gupta       Updated
---------------------------------------------------------*/
public without sharing class SalesOrderCreateBooking_Helper 
{
    public class SalesOrderOpportunityWrapper {
        
        
        private final string GENERA_LABEL_AND_VALUE = 'Cyber$ell';
        private final string CYBER_LABEL_AND_VALUE = 'CyberAd';
        private final string DIGITAL_LABEL_AND_VALUE = 'AdPoint';
        private final string OSCA_LABEL_AND_VALUE = 'OSCA';
        
        public Opportunity oppty {get; private set;}
        public Case caseSource {get; private set;}
        public CampaignMember campaignMemberSource {get;set;}
        
        public List<OpportunityLineItem> lstOpptyItem {get; private set;}
        public Sales_Order__c salesOrder {get; private set;}
        
        public map<String,map<SelectOption,list<SelectOption>>> availableBookingSystem {get; private set;}
        public map<String, List<OpportunityLineItemWrapper>> opptyItemByBookingSystem{get; private set;}
        private set<string> opptyItemCyberAdDivisions;
        
        
        //get price book id by name, TODO:add custom setting to hold its name
        private id pricebookId = [Select p.Name, p.Id From Pricebook2 p where Name = 'Standard Price Book' limit 1].id;
        //get opportunity record type by name, TODO:add custom setting to hold record type name
        private Id opportunityRecordTypeId = [Select r.Id From RecordType r Where SobjectType='Opportunity' AND DeveloperName = 'Walk_in'].id;

        //SFE-766 2016-01-05 atul.gupta@bluewolfgroup.com - Method annotated with @TestVisible to make it visible to Test Class
        @TestVisible
        private void setOpptyItems(List<Id> opptyItems) {
            lstOpptyItem = [Select o.Sales_Order__c, o.PricebookEntryId, o.Parent_Opportunity__c,
                            o.OpportunityId, o.Id, o.PricebookEntry.Product2.Id,
                            o.PricebookEntry.Product2.Booking_System__c
                            From OpportunityLineItem o
                            Where o.Id IN :opptyItems];
            
            // validate all one opportunity
            // validate all one booking system
            oppty = [Select o.Type, o.StageName, o.Revenue_Group__c, o.RecordTypeId, o.Planner_Account__c,
                     o.Payer_Account__c, o.OwnerId, o.Name, o.CloseDate, o.AccountId, o.Contact__c, o.Contact__r.AccountId
                     From Opportunity o
                     Where o.Id = :lstOpptyItem[0].OpportunityId LIMIT 1];
        }
        
        private void setOppty(Id opptyId) {

            oppty = [Select o.Type, o.StageName, o.Revenue_Group__c, o.RecordTypeId, o.Planner_Account__c,
                     o.Payer_Account__c, o.OwnerId, o.Name, o.CloseDate, o.AccountId, o.Contact__c, o.Contact__r.AccountId
                     From Opportunity o
                     Where o.Id = :opptyId LIMIT 1];
            
            
            lstOpptyItem = new List<OpportunityLineItem>();
            opptyItemByBookingSystem = new map<String, List<OpportunityLineItemWrapper>>();
            for(OpportunityLineItem oli : [Select o.Sales_Order__c, o.PricebookEntryId, o.Parent_Opportunity__c,
                                           o.OpportunityId, o.Id, o.PricebookEntry.Product2.Id,
                                           o.PricebookEntry.Product2.Name,
                                           o.PricebookEntry.Product2.Booking_System__c,
                                           o.PricebookEntry.Product2.CyberAd_Division__c,
                                           o.PricebookEntry.Product2.Region__c
                                           From    OpportunityLineItem o
                                           Where   o.OpportunityId = :oppty.Id
                                           AND o.PricebookEntry.Product2.IsActive = true
                                           AND     o.Sales_Order__c=''])
            {
                
                list<string> bookingSys =  oli.PricebookEntry.Product2.Booking_System__c.trim().split(' ');
                if(!opptyItemByBookingSystem.containsKey(bookingSys[0]))
                {
                    opptyItemByBookingSystem.put(bookingSys[0], new list<OpportunityLineItemWrapper>());
                    if(bookingSys[0] == CYBER_LABEL_AND_VALUE)
                        opptyItemCyberAdDivisions = new set<string>();
                }
                
                opptyItemByBookingSystem.get(bookingSys[0]).add(new OpportunityLineItemWrapper(oli, false));
                
                if(bookingSys[0] == CYBER_LABEL_AND_VALUE && oli.PricebookEntry.Product2.CyberAd_Division__c!='')
                {
                    opptyItemCyberAdDivisions.add(oli.PricebookEntry.Product2.CyberAd_Division__c);
                }
                
                system.debug('@ setOppty() opptyItemByBookingSystem: ' + opptyItemByBookingSystem);
                
                lstOpptyItem.add(oli);
            }
            
            system.debug('@ setOppty() opptyItemByBookingSystem:' + opptyItemByBookingSystem);
            
            
            //IF the Opportunity is simple (has one Product) then predefault System
            if(opptyItemByBookingSystem.size()==1)
            {
                for(string k : opptyItemByBookingSystem.keySet())
                    SalesOrder.Source_System__c = k;
                
                system.debug('SalesOrder.Source_System__c:' + SalesOrder.Source_System__c);
                
                if(SalesOrder.Source_System__c == CYBER_LABEL_AND_VALUE &&
                   opptyItemCyberAdDivisions.size()==1)
                {
                    for(string d : opptyItemCyberAdDivisions)
                        SalesOrder.Booking_Division__c = d;
                    
                    system.debug('SalesOrder.Booking_Division__c:' + SalesOrder.Booking_Division__c);
                }
            }
            
            
        }
        
        private void setCaseSource(Id caseId) {
            caseSource = [Select id, Accountid, ContactId from Case Where id = :caseId];
        }
        
        // empty constructor
        public SalesOrderOpportunityWrapper() {
            this(new Sales_Order__c());
        }
        
        public SalesOrderOpportunityWrapper(Sales_Order__c so) {
            system.debug('@ SalesOrderOpportunityWrapper(Sales_Order__c so) ');
            salesOrder = so;
            oppty = new Opportunity();
            buildAvailableBookingSystemMap();
            //lstOpptyItem = new List<OpportunityLineItem>();
            //lstProdSelection = new List<ProductSelection>();
            //resetProductSelection();
        }
        
        // construct from opportunity
        public SalesOrderOpportunityWrapper(Opportunity inOppty) {
            system.debug('@ SalesOrderOpportunityWrapper(Opportunity inOppty)');
            salesOrder = new Sales_Order__c();
            createOrderFromOpportunity(inOppty.id, true, null);  // Updated by Bohao Chen on 25 June 2014 for JIRA issue SFE-456
            buildAvailableBookingSystemMap();
        }
        
        // construct from case
        public SalesOrderOpportunityWrapper(Case inCase) {
            system.debug('@ SalesOrderOpportunityWrapper(Case inCase)');
            caseSource = inCase;
            salesOrder = new Sales_Order__c();
            createOrderFromCase(caseSource);
            buildAvailableBookingSystemMap();
        }
        
        // construct from CampaignMember
        public SalesOrderOpportunityWrapper(CampaignMember inCampaignMember) {
            system.debug('@ SalesOrderOpportunityWrapper(CampaignMember inCampaignMember)');
            campaignMemberSource = inCampaignMember;
            salesOrder = new Sales_Order__c();
            oppty = new Opportunity();
            buildAvailableBookingSystemMap();           
        }
        
        // construct from Account
        public SalesOrderOpportunityWrapper(Account inAccount) {
            system.debug('@ SalesOrderOpportunityWrapper(Account inAccount)');
            salesOrder = new Sales_Order__c();
            oppty = new Opportunity();
            
            //salesOrder.Advertiser_Account__c = inAccount.id;
            
            buildAvailableBookingSystemMap();
        }
        
        // Updated by Bohao Chen on 25 June 2014 for JIRA issue SFE-456
        // BEGIN
        private void createOrderFromOpportunity(String opptyId, Boolean isFromOpportunity, Case inCase) {
            system.debug('@ createOrderFromOpportunity()');
            setOppty(opptyId);
            
            if(isFromOpportunity || (!isFromOpportunity && inCase.AccountId == null))
                salesOrder.Advertiser_Account__c = oppty.AccountId;
            else
                salesOrder.Advertiser_Account__c = inCase.AccountId;
            // END
            
            salesOrder.Payer_Account__c = oppty.Payer_Account__c;
            salesOrder.Placer_Account__c = oppty.Payer_Account__c;
            salesOrder.OwnerId = oppty.OwnerId;
            
            if(oppty.Contact__c != null && oppty.Contact__r.AccountId == oppty.Payer_Account__c)
            {
                salesOrder.Contact__c = oppty.Contact__c;
            }
            
            system.debug('@ createOrderFromOpportunityItems() salesOrder.Advertiser_Account__c:' + salesOrder.Advertiser_Account__c);
            system.debug('@ createOrderFromOpportunityItems() salesOrder.Payer_Account__c:' + salesOrder.Payer_Account__c );
            system.debug('@ createOrderFromOpportunityItems() salesOrder.Placer_Account__c:' + salesOrder.Placer_Account__c);
            system.debug('@ createOrderFromOpportunityItems() salesOrder.OwnerId' + salesOrder.OwnerId);
            
            // salesOrder.Source_System__c = lstOpptyItem.get(0).PricebookEntry.Product2.Booking_System__c ;
            
            if (oppty.Payer_Account__c == null || oppty.AccountId == oppty.Payer_Account__c) {
                salesOrder.Booking_Type__c = 'Direct';
                
                if(salesOrder.Source_System__c == DIGITAL_LABEL_AND_VALUE)
                {
                    salesOrder.Payer_Account__c = oppty.AccountId;
                    salesOrder.Placer_Account__c = oppty.Payer_Account__c;
                }
                
            } else {
                salesOrder.Booking_Type__c = 'Agency';
            }
        }
        
        private void createOrderFromCase(Case inCase) {
            system.debug('@ createOrderFromCase(Case inCase)');
            
            if(caseSource.Opportunity__c!=null)
            {
                createOrderFromOpportunity(caseSource.Opportunity__c, false, inCase); // Updated by Bohao Chen on 25 June 2014 for JIRA issue SFE-456
            }
            else
            {
                oppty = new Opportunity();
                setCaseSource(inCase.id);
                //salesOrder.Advertiser_Account__c = caseSource.Accountid;
            }
        }
        
        private void buildAvailableBookingSystemMap()
        {
            system.debug('@ buildAvailableBookingSystemMap()');
            
            availableBookingSystem = new map<String,map<SelectOption,list<SelectOption>>>();
            list<Schema.PicklistEntry> ple = Sales_Order__c.Source_System__c.getDescribe().getPicklistValues();
            
            
            
            for( Schema.PicklistEntry f : ple)
            {
                if(f.getValue() != OSCA_LABEL_AND_VALUE)
                {
                    list<SelectOption> cyberAdDivisions = new list<SelectOption>();
                    
                    system.debug('@ buildAvailableBookingSystemMap() f.getValue():' + f.getValue());
                    system.debug('@ buildAvailableBookingSystemMap() UserSettings_Helper.isCyberAddEnabled:' + UserSettings_Helper.isCyberAddEnabled);
                    system.debug('@ buildAvailableBookingSystemMap() UserSettings_Helper.isCyberSellEnabled:' + UserSettings_Helper.isCyberSellEnabled);
                    
                    
                    boolean isOptionEnabled = (     (f.getValue() == CYBER_LABEL_AND_VALUE && UserSettings_Helper.isCyberAddEnabled)
                                               ||  (f.getValue() == GENERA_LABEL_AND_VALUE && UserSettings_Helper.isCyberSellEnabled)
                                               ||  (f.getValue() == DIGITAL_LABEL_AND_VALUE && UserSettings_Helper.isAdPointEnabled)   );
                    
                    
                    system.debug('@ buildAvailableBookingSystemMap() isOptionEnabled:' + isOptionEnabled);
                    if(f.getValue() == CYBER_LABEL_AND_VALUE)
                    {
                        for (CyberAd_User_Credential__c c : UserSettings_Helper.cyberAdSettings)
                        {
                            if(opptyItemCyberAdDivisions==null)
                            {
                                cyberAdDivisions.add (new SelectOption(c.Division__c, c.Division__c));
                            }
                            else
                            {
                                cyberAdDivisions.add (new SelectOption(c.Division__c, c.Division__c, !opptyItemCyberAdDivisions.contains(c.Division__c)));
                            }
                        }
                    }
                    
                    
                    system.debug('@ buildAvailableBookingSystemMap() opptyItemByBookingSystem:' + opptyItemByBookingSystem);
                    map<SelectOption,list<SelectOption>> bookingSystem = new map<SelectOption,list<SelectOption>>();
                    
                    if(opptyItemByBookingSystem!=null && !opptyItemByBookingSystem.containskey(f.getValue()))
                    {
                        bookingSystem.put(new SelectOption(f.getLabel(), f.getValue(), true),cyberAdDivisions);
                    }
                    else
                    {
                        bookingSystem.put(new SelectOption(f.getLabel(), f.getValue(), !isOptionEnabled),cyberAdDivisions);
                    }
                    
                    availableBookingSystem.put(f.getValue(),bookingSystem);
                }
            }
            
            system.debug('@ buildAvailableBookingSystemMap() availableBookingSystem:' + availableBookingSystem);
        }
        
        
        
        
        public Sales_Order__c createBooking()
        {
            system.debug('@ createBooking()');
            //system.debug('lstProdSelection.size():' + lstProdSelection.size());
            
            try
            {
                system.debug('@salesordercreatbooking_helper createBooking salesorder ' + salesOrder);
                system.debug('### before upsert salesOrder');
                salesOrder.Ad_Taker__c = UserInfo.getUserId();
                upsert salesOrder;
                
                system.debug(logginglevel.error, '@createbooking upsert salesOrder: ' + salesOrder);
                
                salesOrder = SalesOrderCreateBooking_Helper.getSingleSalesOrderById(salesOrder.Id);
                
                system.debug(logginglevel.error, '@createbooking 1');
                
                //create an opportunity if not exist
                if(oppty.id == null)
                {
                    oppty = createOpportunitFromSalesOrder(salesOrder);
                    
                    createDummyOpportunityLineItem(salesOrder, oppty);
                }
                
                system.debug(logginglevel.error, '@createbooking 2');
                
                if(campaignMemberSource!=null)
                    oppty.campaignId = campaignMemberSource.campaignId;
                
                if(opptyItemByBookingSystem!=null && opptyItemByBookingSystem.containsKey(salesOrder.Source_System__c))
                {
                    list<OpportunityLineItem> oliList = new list<OpportunityLineItem>();
                    for(OpportunityLineItemWrapper oliw : opptyItemByBookingSystem.get(salesOrder.Source_System__c))
                    {
                        //if(oliw.selected)
                        if( salesOrder.Source_System__c!=CYBER_LABEL_AND_VALUE ||
                           oliw.opptylineItem.PricebookEntry.Product2.CyberAd_Division__c == salesOrder.Booking_Division__c)
                        {
                            oliw.opptyLineItem.Sales_Order__c = salesOrder.id;
                            oliw.opptyLineItem.totalPrice = 0;
                            oliList.add(oliw.opptyLineItem);
                        }
                    }
                    
                    system.debug(logginglevel.error, '@createbooking 3');
                    
                    system.debug('oliList.size():' + oliList.size());
                    if(oliList.size()>0)
                    {
                        //remove all schedule for the opportunity line items as their total price is being updated to 0
                        list<OpportunityLineItemSchedule> oliS = [Select Id From OpportunityLineItemSchedule where OpportunityLineItemId IN :oliList];
                        
                        system.debug(logginglevel.error, '@createbooking 4');
                        
                        if(oliS.size()>0)
                        {
                            delete oliS;
                        }
                        
                        system.debug(logginglevel.error, '@createbooking 5');
                        
                        update oliList;
                    }
                    else
                    {
                        //no opportunity product has been selecetd on a page initiated with
                        return null;
                    }
                }
                
                system.debug(logginglevel.error, '@createbooking 6');
                
                //Set opportunity to Closed won as it need to have products before closing
                //SL - Added condition for AdPoint Reservation requirement - 20/03/2015
                oppty.StageName = oppty.StageName == 'Awaiting Bookings' || oppty.StageName == 'Reservation'? oppty.StageName : 'Closed won';
                //oppty.StageName = 'Closed won';
                update oppty;
                
                /********End BC: ********/
                
                system.debug(logginglevel.error, '@createbooking 7');
                
                system.debug('@ createBooking() caseSource:' + caseSource);
                if(caseSource!=null)
                {
                    system.debug('@ createBooking() salesOrder.id:' + salesOrder.id);
                    system.debug('@ createBooking() caseSource.AccountId:' + caseSource.AccountId);
                    system.debug('@ createBooking() salesOrder.Placer_Account__c:' + salesOrder.Placer_Account__c);
                    system.debug('@ createBooking() caseSource.ContactId:' + caseSource.ContactId);
                    system.debug('@ createBooking() salesOrder.Contact__c:' + salesOrder.Contact__c);
                    
                    caseSource.Sales_Order__c = salesOrder.id;
                    if(caseSource.AccountId==null &&  salesOrder.Placer_Account__c!=null)
                        caseSource.AccountId = salesOrder.Placer_Account__c;
                    if(caseSource.ContactId==null &&  salesOrder.Contact__c!=null)                    
                        caseSource.ContactId = salesOrder.Contact__c;
                    
                    update caseSource; 
                }
            }
            catch(Exception ex){
                system.debug(logginglevel.error, '@createBooking exception:' + ex.getMessage());
                throw new SalesOrderCreateException(ex.getMessage());
                return null;
            }
            
            system.debug('salesOrder:' + salesOrder);
            return salesOrder;
        }
        
        public Opportunity createOpportunitFromSalesOrder(Sales_Order__c so)
        {
            system.debug('@ createOpportunitFromSalesOrder()');
            Opportunity opportunity = new Opportunity();
            
            opportunity.Payer_Account__c = so.Payer_Account__r.id;
            opportunity.AccountId = so.Advertiser_Account__r.id;
            opportunity.recordTypeId = opportunityRecordTypeId;
            opportunity.name = so.Advertiser_Account__r.Name + ' - ' + system.today().year() + system.today().month() + system.today().day();
            opportunity.type = 'Non-Core Activity';
            opportunity.Opportunity_Type__c = 'Walk-in';
            //opportunity.Reporting_type__c = 'Booked';
            opportunity.Revenue_Group__c = so.Advertiser_Account__r.Revenue_Group__c;
            opportunity.Industry_Code__c = so.Advertiser_Account__r.Industry_Code__c;
            opportunity.StageName = 'Identify Prospects';
            opportunity.CloseDate = system.today();
            opportunity.Campaign_Start_Date__c = system.today();
            insert opportunity;
            return opportunity;
        }
        
        
        public OpportunityLineItem createDummyOpportunityLineItem(Sales_Order__c so, Opportunity inOpportunity)
        {
            system.debug('@ createDummyOpportunityLineItem()');
            PricebookEntry pricebookEntry = new PricebookEntry();
            OpportunityLineItem oli = new OpportunityLineItem();
            
            Product2 prod = [Select id From Product2 Where Name=:'Dummy'and IsActive = false limit 1];
            
            pricebookEntry = [Select p.UnitPrice, p.Product2Id, p.Pricebook2Id From PricebookEntry p
                              Where   Pricebook2Id = :pricebookId
                              AND    Product2Id = :prod.id];
            
            oli.Sales_Order__c = so.id;
            oli.opportunityId = inOpportunity.id;
            oli.PricebookEntryId = pricebookEntry.id;
            oli.quantity = 1;
            oli.totalPrice = 0;
            
            insert oli;
            return oli;
        }
        
        
    }
    
    
    ///////////////////////////////////////
    //End of SalesOrderOpportunityWrapper//
    ///////////////////////////////////////
    
    
    public static Sales_order__c getSingleSalesOrderById(String soId)
    {
        system.debug('@ getSingleSalesOrderById(String soId)');
        return  [Select s.Planner_Account__c, s.Calc_External_id__c, s.Type__c, s.Status__c, s.Status_As_Of__c, s.Source_System__c,
                 s.Placer_Account__c, s.Payer_Account__c, s.Order__c, s.Name, s.Id, s.External_Id__c, s.External_Account__c,
                 s.Creative_Contact__c, s.Creative_Account__c, s.Creative_Contact_Name__c, s.Creative_Contact_Phone__c, s.Creative_Contact_Email__c, s.Contact__c, s.Booking_Type__c, s.Booking_Division__c,
                 s.Advertiser_Address__c, s.Advertiser_Account__r.DPID_Primary_Address__c, s.Advertiser_Account__r.External_ID__c,
                 s.Advertiser_Account__r.ABN_Validation__c, s.Advertiser_Account__r.ABN_Status__c,
                 s.External_Account_Address__c,s.Placer_Account_Name__c,s.Placer_Account_Phone__c,s.Advertiser_Account__r.Primary_Contact__c,External_Account__r.Account_No__c,
                 s.Advertiser_Account__r.AccountNumber, s.Advertiser_Account__r.Phone, s.Advertiser_Account__r.datasan__Billing_Address_DPID__c,
                 s.Advertiser_Account__r.BillingCountry,s.Advertiser_Account__r.BillingPostalCode, s.Advertiser_Account__r.BillingState, s.Advertiser_Account__r.BillingCity,
                 s.Advertiser_Account__r.BillingStreet, s.Advertiser_Account__r.ParentId, s.Advertiser_Account__r.RecordTypeId,
                 s.Advertiser_Account__r.Type, s.Advertiser_Account__r.Salutation, s.Advertiser_Account__r.FirstName,
                 s.Advertiser_Account__r.LastName, s.Advertiser_Account__r.Name, s.Advertiser_Account__c, s.Ad_Taker__c, s.Account_No__c,
                 s.Payer_Account__r.id, s.Advertiser_Account__r.id, s.Advertiser_Account__r.Revenue_Group__c, s.Advertiser_Account__r.Industry_Code__c,
                 s.Placer_Contact_Name__c, s.Placer_Contact_Phone__c, s.Placer_Contact_Email__c   
                 From Sales_Order__c s
                 WHERE id = :soId];
    }
    
    public static Map<Id, Sales_Order__c> getSalesOrderById(List<Sales_Order__c> salesOrders)
    {
        system.debug('@ getSalesOrderById(List<Sales_Order__c> salesOrders)');
        Map<Id, Sales_Order__c> salesOrdersById = new Map<Id, Sales_Order__c>([Select s.Id, s.Planner_Account__c, s.Calc_External_id__c, s.Type__c, s.Status__c, s.Status_As_Of__c, s.Source_System__c,
                                                                               s.Placer_Account__c, s.Payer_Account__c, s.Order__c, s.Name, s.External_Id__c, s.External_Account__c,
                                                                               s.Creative_Contact__c, s.Creative_Account__c, s.Creative_Contact_Name__c, s.Creative_Contact_Phone__c, s.Creative_Contact_Email__c, s.Contact__c, s.Booking_Type__c, s.Booking_Division__c,
                                                                               s.Advertiser_Address__c, s.Advertiser_Account__r.DPID_Primary_Address__c, s.Advertiser_Account__r.External_ID__c,
                                                                               s.Advertiser_Account__r.ABN_Validation__c, s.Advertiser_Account__r.ABN_Status__c,
                                                                               s.External_Account_Address__c,s.Placer_Account_Name__c,s.Placer_Account_Phone__c,s.Advertiser_Account__r.Primary_Contact__c,External_Account__r.Account_No__c,
                                                                               s.Advertiser_Account__r.AccountNumber, s.Advertiser_Account__r.Phone, s.Advertiser_Account__r.datasan__Billing_Address_DPID__c,
                                                                               s.Advertiser_Account__r.BillingCountry,s.Advertiser_Account__r.BillingPostalCode, s.Advertiser_Account__r.BillingState, s.Advertiser_Account__r.BillingCity,
                                                                               s.Advertiser_Account__r.BillingStreet, s.Advertiser_Account__r.ParentId, s.Advertiser_Account__r.RecordTypeId,
                                                                               s.Advertiser_Account__r.Type, s.Advertiser_Account__r.Salutation, s.Advertiser_Account__r.FirstName,
                                                                               s.Advertiser_Account__r.LastName, s.Advertiser_Account__r.Name, s.Advertiser_Account__c, s.Ad_Taker__c, s.Account_No__c,
                                                                               s.Payer_Account__r.id, s.Advertiser_Account__r.id, s.Advertiser_Account__r.Revenue_Group__c, s.Advertiser_Account__r.Industry_Code__c,
                                                                               s.Placer_Contact_Name__c, s.Placer_Contact_Phone__c, s.Placer_Contact_Email__c  
                                                                               From Sales_Order__c s
                                                                               WHERE s.Id IN :salesOrders]);
        return salesOrdersById;
    }
    
    public class OpportunityLineItemWrapper
    {
        public OpportunityLineItem opptylineItem {get;set;}
        public Boolean selected {get;set;}
        
        
        public OpportunityLineItemWrapper(OpportunityLineItem inOpptylineItem, Boolean inSelected)
        {
            opptylineItem = inOpptylineItem;
            selected = inSelected;
        }
        
    }
    
    public class SalesOrderCreateException extends Exception {}
    
}
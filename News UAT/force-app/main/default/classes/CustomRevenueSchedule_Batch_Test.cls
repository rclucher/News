/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: This class contains unit tests for validating the behaviours of custom revenue schedule process
 * Company: Salesforce.com
 * Date: 24/07/2013
 * History:
 * 24/07/2013   Bohao Chen       Created
 * 2015-11-30   Darshan Gosar    Updated
 * 2015-11-30 darshan.gosar@bluewolfgroup.com 
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    // This class provides test coverage for
    //  - CustomRevenueSchedule_Helper.cls      84%
    //  - Crs_Opportunity_Batch.cls             85%
    //  - CustomRevenueSchedule_Scheduler       100%        
    //  - OpportunityManagement.trigger         82%    
 ---------------------------------------------------------*/
@isTest
private class CustomRevenueSchedule_Batch_Test 
{
    // SFE-766 2015-11-30 darshan.gosar@bluewolfgroup.com
        // To cover test scenarios without seeAllData condition
    static void setUpBatchData(){
        Batch_Run_Start_Datetime__c lastRunDateTime = new Batch_Run_Start_Datetime__c();
        lastRunDateTime.Name = 'Booking_Refresh_YTD_Revenue_Batch';
        lastRunDateTime.Run_Start_Datetime__c = datetime.now().addDays(-1);
        insert lastRunDateTime;

        Batch_Run_Start_Datetime__c lastRunDateTime1 = new Batch_Run_Start_Datetime__c();
        lastRunDateTime1.Name = 'CRS Opportunity Batch';
        lastRunDateTime1.Run_Start_Datetime__c = datetime.now().addDays(-1);
        insert lastRunDateTime1;
    }
    
    static testMethod void insertDeleteCrsTest() 
    {
        setUpBatchData();
        /********** BEGIN: create testing data **************/
        // reset batch run start datetime for batches
        Datetime crsOpptyLastRunSuccessDatetime = datetime.now().addDays(-1);
        Datetime crsOpptyLineItemLastRunSuccessDatetime = datetime.now().addDays(-1);
        
        // create products 
        List<Product2> products = TestDataFactory.createProducts(10);

        // SFE-766 2015-11-30 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition                
        // create price books
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        
        // create price book entries
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        
        // create account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        insert accts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
        insert contacts;
        
        // create opportunities
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(10, null, accts[0], contacts[0]); // Updated by Darshan Gosar on 30 Nov & Passing null so it will assign standard pricebook entry to opportunity as same is being assigned to OLI's
        insert opportunities;
        
        /********** END: create testing data **************/
        
        // run batch methods
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities((List<Opportunity>)Database.query(CustomRevenueSchedule_Helper.crsOpptyQuery  + ' and Is_Test__c = true'));
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems((List<OpportunityLineItem>)Database.query(CustomRevenueSchedule_Helper.crsOpptyLineItemQuery  + ' and Is_Test__c = true'));
        
        // verify results
        // crs should be inserted without opportunit line item id, amount is 0 and revenue date is null
        for(Revenue_Schedule__c rs : [Select r.Sales_Order__c, r.Rev_Date__c, r.Rev_Amount__c, r.Owner__c, r.Opportunity__c, 
                                        r.Opportunity_Line_Item_Id__c, r.Line_Item_Schedule_Id__c, r.Account__c 
                                        From Revenue_Schedule__c r 
                                        Where Opportunity__c IN: opportunities])
        {
            system.assertEquals(null, rs.Rev_Date__c);
            system.assertEquals(0, rs.Rev_Amount__c);
            system.assertEquals(null, rs.Opportunity_Line_Item_Id__c);
            system.assertEquals(null, rs.Line_Item_Schedule_Id__c);
            system.assertEquals(accts[0].Id, rs.Account__c);
        }
        
        // create opportunity line items for opportunities
        List<OpportunityLineItem> opportunityLineItems = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, null);
        insert opportunityLineItems;
        
        // Case 1 : create line item schedules for opportunity line items
        List<OpportunityLineItemSchedule> opportunityItemSchedules  = TestDataFactory.createOpportunityLineItemSchedules(10, opportunityLineItems, date.today());
        insert opportunityItemSchedules;
        
        Test.StartTest();
        
        // run batch methods
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities((List<Opportunity>)Database.query(CustomRevenueSchedule_Helper.crsOpptyQuery + ' and Is_Test__c = true'));
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems((List<OpportunityLineItem>)Database.query(CustomRevenueSchedule_Helper.crsOpptyLineItemQuery + + ' and Is_Test__c = true'));
        
        // verify the testing results
        Map<String, Map<String, Set<String>>> scheduleItemIdByOpptyLineItemIdByOpptyId = new Map<String, Map<String, Set<String>>>();
        
        Integer revenueScheduleSize = 0;
        
        for(Revenue_Schedule__c rs : [Select r.Sales_Order__c, r.Rev_Date__c, r.Rev_Amount__c, r.Owner__c, r.Opportunity__c, 
                                        r.Opportunity_Line_Item_Id__c, r.Line_Item_Schedule_Id__c, r.Account__c 
                                        From Revenue_Schedule__c r 
                                        Where Opportunity__c IN: opportunities])
        {
            if(!scheduleItemIdByOpptyLineItemIdByOpptyId.containsKey(rs.Opportunity__c))
            {
                scheduleItemIdByOpptyLineItemIdByOpptyId.put(rs.Opportunity__c, new Map<String, Set<String>>());
            }
            
            if(!scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).containsKey(rs.Opportunity_Line_Item_Id__c))
            {
                scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).put(rs.Opportunity_Line_Item_Id__c, new Set<String>());
            }
            
            scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).get(rs.Opportunity_Line_Item_Id__c).add(rs.Line_Item_Schedule_Id__c);
            
            system.assertEquals(rs.Rev_Amount__c, 100);
            
            revenueScheduleSize++;
        }
        
        // expect results should have 1000 revenue schedules
        system.assertEquals(1000, revenueScheduleSize);
        
        // expect results should have 10 opportunities
        system.assertEquals(10, scheduleItemIdByOpptyLineItemIdByOpptyId.keySet().size());
        
        for(String opptyId : scheduleItemIdByOpptyLineItemIdByOpptyId.keySet())
        {
            // each opportunity should have 10 opportunity line items
            system.assertEquals(10, scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).keySet().size());
            
            for(String oliId : scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).keySet())
            {
                // each opportunity line items should have 10 schedule items
                system.assertEquals(10, scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).get(oliId).size());
            }
        }
        
        for(Opportunity oppty : opportunities)
        {
            system.assert(scheduleItemIdByOpptyLineItemIdByOpptyId.keySet().contains(oppty.Id));
            
            for(OpportunityLineItem oli : oppty.OpportunityLineItems)
            {
                system.assert(scheduleItemIdByOpptyLineItemIdByOpptyId.get(oppty.Id).keySet().contains(oli.Id));
            }
        }
        
        // Case 2 : re-establish less number of line item schedules for each opportunity line item than the number of line item schedules
        delete opportunityItemSchedules;
         
        List<OpportunityLineItemSchedule> opportunityItemSchedules1  = TestDataFactory.createOpportunityLineItemSchedules(2, opportunityLineItems, date.today());
        insert opportunityItemSchedules1;
        
        // run batch methods
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities((List<Opportunity>)Database.query(CustomRevenueSchedule_Helper.crsOpptyQuery  + ' and Is_Test__c = true'));
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems((List<OpportunityLineItem>)Database.query(CustomRevenueSchedule_Helper.crsOpptyLineItemQuery  + ' and Is_Test__c = true'));
        
        // verify the testing results
        scheduleItemIdByOpptyLineItemIdByOpptyId.clear();
        
        revenueScheduleSize = 0;
        
        for(Revenue_Schedule__c rs : [Select r.Sales_Order__c, r.Rev_Date__c, r.Rev_Amount__c, r.Owner__c, r.Opportunity__c, 
                                        r.Opportunity_Line_Item_Id__c, r.Line_Item_Schedule_Id__c, r.Account__c 
                                        From Revenue_Schedule__c r 
                                        Where Opportunity__c IN: opportunities])
        {
            if(!scheduleItemIdByOpptyLineItemIdByOpptyId.containsKey(rs.Opportunity__c))
            {
                scheduleItemIdByOpptyLineItemIdByOpptyId.put(rs.Opportunity__c, new Map<String, Set<String>>());
            }
            
            if(!scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).containsKey(rs.Opportunity_Line_Item_Id__c))
            {
                scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).put(rs.Opportunity_Line_Item_Id__c, new Set<String>());
            }
            
            scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).get(rs.Opportunity_Line_Item_Id__c).add(rs.Line_Item_Schedule_Id__c);
            
            system.assertEquals(rs.Rev_Amount__c, 100);
            
            revenueScheduleSize++;
        }
        
        // expect results should have 200 revenue schedules
        system.assertEquals(200, revenueScheduleSize);
        
        // expect results should have 10 opportunities
        system.assertEquals(10, scheduleItemIdByOpptyLineItemIdByOpptyId.keySet().size());
        
        for(String opptyId : scheduleItemIdByOpptyLineItemIdByOpptyId.keySet())
        {
            // each opportunity should have 10 opportunity line items
            system.assertEquals(10, scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).keySet().size());
            
            for(String oliId : scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).keySet())
            {
                // each opportunity line items should have 5 schedule items
                system.assertEquals(2, scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).get(oliId).size());
            }
        }
        
        for(Opportunity oppty : opportunities)
        {
            system.assert(scheduleItemIdByOpptyLineItemIdByOpptyId.keySet().contains(oppty.Id));
            
            for(OpportunityLineItem oli : oppty.OpportunityLineItems)
            {
                system.assert(scheduleItemIdByOpptyLineItemIdByOpptyId.get(oppty.Id).keySet().contains(oli.Id));
            }
        }

        // TODO: Case 2 : re-establish more number of line item schedules for each opportunity line item than the number of line item schedules
        delete opportunityItemSchedules1;
         
        List<OpportunityLineItemSchedule> opportunityItemSchedules2  = TestDataFactory.createOpportunityLineItemSchedules(3, opportunityLineItems, date.today());
        insert opportunityItemSchedules2;
        
        // run batch methods
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities((List<Opportunity>)Database.query(CustomRevenueSchedule_Helper.crsOpptyQuery  + ' and Is_Test__c = true'));
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems((List<OpportunityLineItem>)Database.query(CustomRevenueSchedule_Helper.crsOpptyLineItemQuery  + ' and Is_Test__c = true'));
        
        // verify the testing results
        scheduleItemIdByOpptyLineItemIdByOpptyId.clear();
        
        revenueScheduleSize = 0;
        
        for(Revenue_Schedule__c rs : [Select r.Sales_Order__c, r.Rev_Date__c, r.Rev_Amount__c, r.Owner__c, r.Opportunity__c, 
                                        r.Opportunity_Line_Item_Id__c, r.Line_Item_Schedule_Id__c, r.Account__c 
                                        From Revenue_Schedule__c r 
                                        Where Opportunity__c IN: opportunities])
        {
            if(!scheduleItemIdByOpptyLineItemIdByOpptyId.containsKey(rs.Opportunity__c))
            {
                scheduleItemIdByOpptyLineItemIdByOpptyId.put(rs.Opportunity__c, new Map<String, Set<String>>());
            }
            
            if(!scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).containsKey(rs.Opportunity_Line_Item_Id__c))
            {
                scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).put(rs.Opportunity_Line_Item_Id__c, new Set<String>());
            }
            
            scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).get(rs.Opportunity_Line_Item_Id__c).add(rs.Line_Item_Schedule_Id__c);
            
            system.assertEquals(rs.Rev_Amount__c, 100);
            
            revenueScheduleSize++;
        }
        
        // expect results should have 300 revenue schedules
        system.assertEquals(300, revenueScheduleSize);
        
        // expect results should have 10 opportunities
        system.assertEquals(10, scheduleItemIdByOpptyLineItemIdByOpptyId.keySet().size());
        
        for(String opptyId : scheduleItemIdByOpptyLineItemIdByOpptyId.keySet())
        {
            // each opportunity should have 10 opportunity line items
            system.assertEquals(10, scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).keySet().size());
            
            for(String oliId : scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).keySet())
            {
                // each opportunity line items should have 3 schedule items
                system.assertEquals(3, scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).get(oliId).size());
            }
        }
        
        for(Opportunity oppty : opportunities)
        {
            system.assert(scheduleItemIdByOpptyLineItemIdByOpptyId.keySet().contains(oppty.Id));
            
            for(OpportunityLineItem oli : oppty.OpportunityLineItems)
            {
                system.assert(scheduleItemIdByOpptyLineItemIdByOpptyId.get(oppty.Id).keySet().contains(oli.Id));
            }
        }
        
                
        // Case 3 : delete some opportunity line items
        List<OpportunityLineItem> deleteOpptyLineItems = new List<OpportunityLineItem>();
        
        for(Integer i = 0; i < opportunities.size(); i++)
        {
            Integer j = 0;
            for(OpportunityLineItem delOpptyLi : opportunities[i].OpportunityLineItems)
            {
                if(j == 5)
                {
                    break;
                }
                else
                {
                    deleteOpptyLineItems.add(delOpptyLi);
                    j++;
                }
            }
        }
        
        delete deleteOpptyLineItems;
        
        // run batch methods
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities((List<Opportunity>)Database.query(CustomRevenueSchedule_Helper.crsOpptyQuery  + ' and Is_Test__c = true'));
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems((List<OpportunityLineItem>)Database.query(CustomRevenueSchedule_Helper.crsOpptyLineItemQuery  + ' and Is_Test__c = true'));
        
        // verify the testing results
        scheduleItemIdByOpptyLineItemIdByOpptyId.clear();
        
        revenueScheduleSize = 0;
        
        for(Revenue_Schedule__c rs : [Select r.Sales_Order__c, r.Rev_Date__c, r.Rev_Amount__c, r.Owner__c, r.Opportunity__c, 
                                        r.Opportunity_Line_Item_Id__c, r.Line_Item_Schedule_Id__c, r.Account__c 
                                        From Revenue_Schedule__c r 
                                        Where Opportunity__c IN: opportunities])
        {
            if(!scheduleItemIdByOpptyLineItemIdByOpptyId.containsKey(rs.Opportunity__c))
            {
                scheduleItemIdByOpptyLineItemIdByOpptyId.put(rs.Opportunity__c, new Map<String, Set<String>>());
            }
            
            if(!scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).containsKey(rs.Opportunity_Line_Item_Id__c))
            {
                scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).put(rs.Opportunity_Line_Item_Id__c, new Set<String>());
            }
            
            scheduleItemIdByOpptyLineItemIdByOpptyId.get(rs.Opportunity__c).get(rs.Opportunity_Line_Item_Id__c).add(rs.Line_Item_Schedule_Id__c);
            
            system.assertEquals(rs.Rev_Amount__c, 100);
            
            revenueScheduleSize++;
        }
        
        // expect results should have 300 revenue schedules 
        system.assertEquals(300, revenueScheduleSize);
        
        // expect results should have 10 opportunities
        system.assertEquals(10, scheduleItemIdByOpptyLineItemIdByOpptyId.keySet().size());
        
        for(String opptyId : scheduleItemIdByOpptyLineItemIdByOpptyId.keySet())
        {
            // todo: have to check results
            // each opportunity should have 5 opportunity line items
            //system.assertEquals(5, scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).keySet().size());
            
            for(String oliId : scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).keySet())
            {
                // todo: have to check results
                // each opportunity line items should have 5 schedule items
                //system.assertEquals(5, scheduleItemIdByOpptyLineItemIdByOpptyId.get(opptyId).get(oliId).size());
            }
        }
        
        for(Opportunity oppty : opportunities)
        {
            system.assert(scheduleItemIdByOpptyLineItemIdByOpptyId.keySet().contains(oppty.Id));
            
            for(OpportunityLineItem oli : oppty.OpportunityLineItems)
            {
                system.assert(scheduleItemIdByOpptyLineItemIdByOpptyId.get(oppty.Id).keySet().contains(oli.Id));
            }
        }
        
        // Case 4: delete all opportunity line items
        delete OpportunityLineItems;
        
        // run batch methods
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities((List<Opportunity>)Database.query(CustomRevenueSchedule_Helper.crsOpptyQuery  + ' and Is_Test__c = true'));
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems((List<OpportunityLineItem>)Database.query(CustomRevenueSchedule_Helper.crsOpptyLineItemQuery  + ' and Is_Test__c = true'));
        
        // verify results
        // crs should reverse back to state when it is without opportunit line item id, amount is 0 and revenue date is null
        for(Revenue_Schedule__c rs : [Select r.Sales_Order__c, r.Rev_Date__c, r.Rev_Amount__c, r.Owner__c, r.Opportunity__c, 
                                        r.Opportunity_Line_Item_Id__c, r.Line_Item_Schedule_Id__c, r.Account__c 
                                        From Revenue_Schedule__c r 
                                        Where Opportunity__c IN: opportunities])
        {
            system.assertEquals(null, rs.Rev_Date__c);
            system.assertEquals(0, rs.Rev_Amount__c);
            system.assertEquals(null, rs.Opportunity_Line_Item_Id__c);
            system.assertEquals(null, rs.Line_Item_Schedule_Id__c);
            system.assertEquals(accts[0].Id, rs.Account__c);
        }
        
        
        // Case 5 : delete all opportunities
        Set<String> opptyIdSet = new Set<String>();
        
        for(Opportunity oppty : opportunities)
        {
            opptyIdSet.add(oppty.Id);
        }
        
        delete opportunities;
        
        // run batch methods
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities((List<Opportunity>)Database.query(CustomRevenueSchedule_Helper.crsOpptyQuery  + ' and Is_Test__c = true'));
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems((List<OpportunityLineItem>)Database.query(CustomRevenueSchedule_Helper.crsOpptyLineItemQuery  + ' and Is_Test__c = true'));
        
        // verify the testing results
        List<Revenue_Schedule__c> revenueSchedule = [Select r.Sales_Order__c, r.Rev_Date__c, r.Rev_Amount__c, r.Owner__c, r.Opportunity__c, 
                                        r.Opportunity_Line_Item_Id__c, r.Line_Item_Schedule_Id__c, r.Account__c 
                                        From Revenue_Schedule__c r 
                                        Where Opportunity__c IN: opptyIdSet];
        
        system.assertEquals(0, revenueSchedule.size());
        
        Test.stopTest();
        
    }
    
    static testMethod void updateCrsTest() 
    {
        setUpBatchData();
        /********** BEGIN: create testing data **************/
        // reset batch run start datetime for batches
        Datetime crsOpptyLastRunSuccessDatetime = datetime.now().addDays(-1);
        Datetime crsOpptyLineItemLastRunSuccessDatetime = datetime.now().addDays(-1);
        
        // create user
        List<User> users = TestDataFactory.createUsers(1, 'System Administrator', null, null,false);
        insert users;
        
        // create products 
        List<Product2> products = TestDataFactory.createProducts(10);

        // SFE-766 2015-11-30 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition        
        // create price books
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        
        // create price book entries
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        
        // create account
        List<Account> accts = TestDataFactory.createAccounts(2, false);
        insert accts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
        insert contacts;
        
        // create sales order
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(2, accts[0], accts[0], accts[0], contacts[0], null);
        insert salesOrders;
        
        system.debug(logginglevel.error, '=====salesOrders==== ' + salesOrders);
        
        
        // create opportunities
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(10, null, accts[0], contacts[0]); // Updated by Darshan Gosar on 30 Nov & Passing null so it will assign standard pricebook entry to opportunity as same is being assigned to OLI's
        insert opportunities;
        
        // create opportunity line items for opportunities
        List<OpportunityLineItem> opportunityLineItems = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, salesOrders[0].Id);
        insert opportunityLineItems;

        system.debug(logginglevel.error, '=====opportunityLineItems==== ' + opportunityLineItems);
        
        
        // Case 1 : create line item schedules for opportunity line items
        List<OpportunityLineItemSchedule> opportunityItemSchedules  = TestDataFactory.createOpportunityLineItemSchedules(10, opportunityLineItems, date.today());
        insert opportunityItemSchedules;
        
       // system.debug(logginglevel.error, '=====opportunityItemSchedules==== ' + opportunityItemSchedules);
        
        /********** END: create testing data **************/
        
        Test.startTest();
        
        // this is date map for item schedules in order to check original date of each item schedule
        Map<String, Date> scheduleDateMapByScheduleItemId = new Map<String, Date>(); 
        
        // Case 6 : update line item schedules (schedule date and revenue amount update)
        for(OpportunityLineItemSchedule olis : opportunityItemSchedules)
        {
            scheduleDateMapByScheduleItemId.put(olis.Id, olis.ScheduleDate);
            olis.Revenue = 200;
            olis.ScheduleDate = olis.ScheduleDate.addDays(7);
        }
        
        update opportunityItemSchedules;
        
        system.debug(logginglevel.error, '=====scheduleDateMapByScheduleItemId==== ' + scheduleDateMapByScheduleItemId);
        
        
        // run batch methods
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities((List<Opportunity>)Database.query(CustomRevenueSchedule_Helper.crsOpptyQuery  + ' and Is_Test__c = true'));
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems((List<OpportunityLineItem>)Database.query(CustomRevenueSchedule_Helper.crsOpptyLineItemQuery  + ' and Is_Test__c = true'));
        
        // verify the results
        for(Revenue_Schedule__c rs : [Select r.Sales_Order__c, r.Rev_Date__c, r.Rev_Amount__c, r.Owner__c, r.Opportunity__c, 
                                        r.Opportunity_Line_Item_Id__c, r.Line_Item_Schedule_Id__c, r.Account__c 
                                        From Revenue_Schedule__c r 
                                        Where Opportunity__c IN: opportunities])
        {
            system.assertEquals(rs.Rev_Amount__c, 200);
            system.assertEquals(scheduleDateMapByScheduleItemId.get(rs.Line_Item_Schedule_Id__c).addDays(7), rs.Rev_Date__c);
        }
        
        // Case 7: update opportunity line items
        for(OpportunityLineItem olis : opportunityLineItems)
        {
            olis.Sales_Order__c = salesOrders[1].Id;
        }
        
        update opportunityLineItems;
        
        // run batch methods
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities((List<Opportunity>)Database.query(CustomRevenueSchedule_Helper.crsOpptyQuery  + ' and Is_Test__c = true'));
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems((List<OpportunityLineItem>)Database.query(CustomRevenueSchedule_Helper.crsOpptyLineItemQuery  + ' and Is_Test__c = true'));
        
        // verify the results
        // sales order id on each revenue schedule should
        for(Revenue_Schedule__c rs : [Select r.Sales_Order__c, r.Rev_Date__c, r.Rev_Amount__c, r.Owner__c, r.Opportunity__c, 
                                        r.Opportunity_Line_Item_Id__c, r.Line_Item_Schedule_Id__c, r.Account__c 
                                        From Revenue_Schedule__c r 
                                        Where Opportunity__c IN: opportunities])
        {
            system.assertEquals(salesOrders[1].Id, rs.Sales_Order__c);
        }
        
        
        // Case 8: update opportunities
        for(Opportunity oppty : opportunities)
        {
            oppty.AccountId = accts[1].Id;
            oppty.OwnerId = users[0].Id;
        }
        
        update opportunities;
        
        // run batch methods
        CustomRevenueSchedule_Helper.upsertCrsOpprotunities((List<Opportunity>)Database.query(CustomRevenueSchedule_Helper.crsOpptyQuery  + ' and Is_Test__c = true'));
        CustomRevenueSchedule_Helper.processCrsOpportunityLineItems((List<OpportunityLineItem>)Database.query(CustomRevenueSchedule_Helper.crsOpptyLineItemQuery  + ' and Is_Test__c = true'));
        
        
        // verify results
        // account lookup and owner lookup should reflect new changes
        for(Revenue_Schedule__c rs : [Select r.Sales_Order__c, r.Rev_Date__c, r.Rev_Amount__c, r.Owner__c, r.Opportunity__c, 
                                        r.Opportunity_Line_Item_Id__c, r.Line_Item_Schedule_Id__c, r.Account__c
                                        From Revenue_Schedule__c r 
                                        Where Opportunity__c IN: opportunities])
        {
            system.assertEquals(accts[1].Id, rs.Account__c);
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void crsSchedulerTest()
    {
        setUpBatchData();

        // create account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        insert accts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
        insert contacts;

        // create opportunity
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(10, null, accts[0], contacts[0]);
        insert opportunities;
        
        // create products
        List<Product2> products = TestDataFactory.createProducts(10);

        // SFE-766 2015-11-30 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition        
        // pricebook entries
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        
        // create opportunity line items
        List<OpportunityLineItem> opptyLineItems = TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, null);
        insert opptyLineItems;
        
        Test.startTest();
        
         // Schedule the test job
        String CRON_EXP = '0 10 * * * ?';
        String jobId = System.schedule('TestCustomRevenueScheduler',
                                    CRON_EXP, 
                                    new CustomRevenueSchedule_Scheduler());
   
        // Get the information from the CronTrigger API object
        CronTrigger ct = [Select Id, CronExpression, TimesTriggered, NextFireTime
                        From CronTrigger Where id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run
        system.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run
        Datetime nextRunTime = datetime.now();
        
        if(nextRunTime.minute() >= 10)
        {
            nextRunTime = nextRunTime.addHours(1);
        }
       
        String runTimeHour = String.valueOf(nextRunTime.hour());
         
        if(nextRunTime.hour() <= 9)
        {
            runTimeHour = '0' + runTimeHour;
        }
       
        String runDatetime = String.valueOf(nextRunTime.date()).split(' ')[0] + ' '
                            + runTimeHour + ':10:00';
        
        system.assertEquals(runDatetime, String.valueOf(ct.NextFireTime));
        
        
        Test.stopTest();
    }
}
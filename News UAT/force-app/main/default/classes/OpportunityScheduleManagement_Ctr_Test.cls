/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: This class contains unit tests for controller OpportunityScheduleManagement_Controller and trigger BookingLineItemManagement
 * Company: Salesforce.com
 * Date: 31/07/2013
 * History:
 * 31/07/2013   Bohao Chen       Created
 * 2015-12-21 darshan.gosar@bluewolfgroup.com 
 *      Upadated to remove seeAllData condition
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
    // This class provides test coverage for 
    //  - OpportunityScheduleManagement_Controller.cls      91%
    //  - BookingLineItemManagement.trigger                 92% 
    //  - OpportunityLineItemManagement.trigger             79%
 ---------------------------------------------------------*/
@isTest
private class OpportunityScheduleManagement_Ctr_Test 
{
    private static List<OpportunityLineItem> opportunityLineItems;
    private static List<Product2> products;
    private static List<Booking__c> bookings;
    private static List<Sales_Order__c> salesOrders;
    private static List<Pricebook2> pricebooks;
    private static List<PricebookEntry> pricebookEntries;

    static testMethod void insertOpportunityLineItemScheduleTest() 
    {
        OpportunityScheduleManagement_Ctr_Test.setTestData();
        
        
        // create booking line items
        List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>(); 
        for(Integer i = 0; i < bookings.size(); i++)
        {
            bookingLineItems.addAll(TestDataFactory.createBookingLineItems(10, bookings[i]));
        }
        
        Integer i = 0;
        for(Booking_Line_Item__c bookingLineItem : bookingLineItems)
        {
            bookingLineItem.Product__c = products[i].Id;
            i++;
            
            if(i >= products.size())
            {
                i = 0;
            }
        }
        
        insert bookingLineItems;
        
        // validate results
        Map<Id, List<OpportunityLineItemSchedule>> opptLineItemScheduleMapBySalesOrderId = new Map<Id, List<OpportunityLineItemSchedule>>();
        Map<Id, Map<Id, List<OpportunityLineItemSchedule>>> opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId = new Map<Id, Map<Id, List<OpportunityLineItemSchedule>>>();
         
        for(OpportunityLineItemSchedule opptLineItemSchedule : [Select o.ScheduleDate, o.Revenue, o.OpportunityLineItem.Sales_Order__c, o.OpportunityLineItem.PricebookEntry.Product2Id, 
                                                        o.OpportunityLineItemId 
                                                        From OpportunityLineItemSchedule o 
                                                        Where o.OpportunityLineItemId IN: opportunityLineItems])
        {
            if(!opptLineItemScheduleMapBySalesOrderId.containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderId.put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderId.get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
            
            if(!opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.containsKey(opptLineItemSchedule.OpportunityLineItemId))
            {
                opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.put(opptLineItemSchedule.OpportunityLineItemId, new Map<Id, List<OpportunityLineItemSchedule>>());
            }
            
            if(!opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
        }
        
        system.debug(LoggingLevel.Error, '===opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId=== ' + opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId);
        system.debug(LoggingLevel.Error, '===opptLineItemScheduleMapBySalesOrderId=== ' + opptLineItemScheduleMapBySalesOrderId);

        
        for(String opportunityLineItemId : opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.keySet())
        {
            for(String SalesOrderId : opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).keySet())
            {
                system.assertEquals(1, opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).get(SalesOrderId).size());
                // TODO: assertion investigate
                system.assertEquals(2000, opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).get(SalesOrderId)[0].Revenue);
            }
        }
        
        for(Sales_Order__c so : salesOrders)
        {
            system.assertEquals(5, opptLineItemScheduleMapBySalesOrderId.get(so.Id).size());
        }
        
        // create additional new booking line items on existing bookings
        bookingLineItems = new List<Booking_Line_Item__c>(); 
        for(i = 0; i < bookings.size(); i++)
        {
            bookingLineItems.addAll(TestDataFactory.createBookingLineItems(10, bookings[i]));
        }
        
        i = 0;
        for(Booking_Line_Item__c bookingLineItem : bookingLineItems)
        {
            bookingLineItem.Product__c = products[i].Id;
            i++;
            
            if(i >= products.size())
            {
                i = 0;
            }
        }
        Test.startTest();
        insert bookingLineItems;
        
        system.debug(LoggingLevel.Error, '===bookingLineItems=== ' + bookingLineItems);
        
        
        // validate results
        // for opportunity line item schedule, revenue should be increased by 1000
        opptLineItemScheduleMapBySalesOrderId.clear();
        opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.clear();
         
        for(OpportunityLineItemSchedule opptLineItemSchedule : [Select o.ScheduleDate, o.Revenue, o.OpportunityLineItem.Sales_Order__c, o.OpportunityLineItem.PricebookEntry.Product2Id, 
                                                        o.OpportunityLineItemId 
                                                        From OpportunityLineItemSchedule o 
                                                        Where o.OpportunityLineItemId IN: opportunityLineItems])
        {
            if(!opptLineItemScheduleMapBySalesOrderId.containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderId.put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderId.get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
            
            if(!opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.containsKey(opptLineItemSchedule.OpportunityLineItemId))
            {
                opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.put(opptLineItemSchedule.OpportunityLineItemId, new Map<Id, List<OpportunityLineItemSchedule>>());
            }
            
            if(!opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
        }
        
        system.debug(LoggingLevel.Error, '===opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId v1=== ' + opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId);
        system.debug(LoggingLevel.Error, '===opptLineItemScheduleMapBySalesOrderId v1=== ' + opptLineItemScheduleMapBySalesOrderId);
        
        for(String opportunityLineItemId : opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.keySet())
        {
            for(String SalesOrderId : opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).keySet())
            {
                system.assertEquals(1, opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).get(SalesOrderId).size());
                // TODO: need to recheck assertion
//                system.assertEquals(2000, opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).get(SalesOrderId)[0].Revenue);
            }
        }
        
        // change booking line item run date to different week
        i = 0;
        for(Booking_Line_Item__c bookingLineItem : bookingLineItems)
        {
            bookingLineItem.Product__c = products[i].Id;
            bookingLineItem.Run_Date__c = date.today().addDays(8);
            i++;
            
            if(i >= products.size())
            {
                i = 0;
            }
        }
       
        update bookingLineItems;
        Test.stopTest();
        // validate results
        // each opportunity line item should have 2 schedule items now
        opptLineItemScheduleMapBySalesOrderId.clear();
        opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.clear();
         
        for(OpportunityLineItemSchedule opptLineItemSchedule : [Select o.ScheduleDate, o.Revenue, o.OpportunityLineItem.Sales_Order__c, o.OpportunityLineItem.PricebookEntry.Product2Id, 
                                                        o.OpportunityLineItemId 
                                                        From OpportunityLineItemSchedule o 
                                                        Where o.OpportunityLineItemId IN: opportunityLineItems])
        {
            if(!opptLineItemScheduleMapBySalesOrderId.containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderId.put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderId.get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
            
            if(!opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.containsKey(opptLineItemSchedule.OpportunityLineItemId))
            {
                opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.put(opptLineItemSchedule.OpportunityLineItemId, new Map<Id, List<OpportunityLineItemSchedule>>());
            }
            
            if(!opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
        }
        
        for(String opportunityLineItemId : opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.keySet())
        {
            for(String SalesOrderId : opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).keySet())
            {
                system.assertEquals(2, opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).get(SalesOrderId).size());
                // TODO: need to recheck assertion
                // system.assertEquals(1000, opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).get(SalesOrderId)[0].Revenue);
            }
        }
         
        
    }
    
    static testMethod void insertOpportunityLineItemTest() 
    {
        OpportunityScheduleManagement_Ctr_Test.setTestData();
        
        Test.startTest();
        
        // create an extra product
        // this product doesn't have opportunity line item associates with
        List<Product2> product = TestDataFactory.createProducts(1);
        
        // SFE-766 2015-12-21 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition         
        // create pricebook
        pricebookEntries.addAll(TestDataFactory.createPricebookEntryData(null, product));

        List<Booking_Line_Item__c> bookingLineItem = TestDataFactory.createBookingLineItems(1, bookings[bookings.size() - 1]);
        
        bookingLineItem[0].Product__c = product[0].Id;
        
        // insert this booking line item
        // notice that this booking line item has no associated opportunity line item
        insert bookingLineItem; 
        

        // validate results to be sure new opportunity line item has been created
        // and it doesn't exist in the original opportunity line item ids set       
        Set<String> originalOpportunityLineItemIdSet = new Set<String>();
         
        for(OpportunityLineItem opportunityLineItem : opportunityLineItems)
        {
            originalOpportunityLineItemIdSet.add(opportunityLineItem.Id);
        }
        
        for(OpportunityLineItemSchedule opptLineItemSchedule : [Select o.ScheduleDate, o.Revenue, o.OpportunityLineItem.Sales_Order__c, 
                                                                o.OpportunityLineItem.PricebookEntry.Product2Id, 
                                                                o.OpportunityLineItemId 
                                                                From OpportunityLineItemSchedule o 
                                                                Where o.OpportunityLineItem.PricebookEntry.Product2Id =: product[0].Id])
        {
            system.assert(!originalOpportunityLineItemIdSet.contains(opptLineItemSchedule.OpportunityLineItemId));
        }
        
        Test.stopTest();
    }
    
    static testMethod void updateOpportunityLineItemScheduleTest() 
    {
        OpportunityScheduleManagement_Ctr_Test.setTestData();
        
        // create booking line items
        List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>(); 
        for(Integer i = 0; i < bookings.size(); i++)
        {
            bookingLineItems.addAll(TestDataFactory.createBookingLineItems(10, bookings[i]));
        }
        
        Integer i = 0;
        for(Booking_Line_Item__c bookingLineItem : bookingLineItems)
        {
            bookingLineItem.Product__c = products[i].Id;
            i++;
            
            if(i >= products.size())
            {
                i = 0;
            }
        }
        
        insert bookingLineItems;
        
        // validate results
        Map<Id, List<OpportunityLineItemSchedule>> opptLineItemScheduleMapBySalesOrderId = new Map<Id, List<OpportunityLineItemSchedule>>();
        Map<Id, Map<Id, List<OpportunityLineItemSchedule>>> opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId = new Map<Id, Map<Id, List<OpportunityLineItemSchedule>>>();
         
        for(OpportunityLineItemSchedule opptLineItemSchedule : [Select o.ScheduleDate, o.Revenue, o.OpportunityLineItem.Sales_Order__c, o.OpportunityLineItem.PricebookEntry.Product2Id, 
                                                        o.OpportunityLineItemId 
                                                        From OpportunityLineItemSchedule o 
                                                        Where o.OpportunityLineItemId IN: opportunityLineItems])
        {
            if(!opptLineItemScheduleMapBySalesOrderId.containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderId.put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderId.get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
            
            if(!opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.containsKey(opptLineItemSchedule.OpportunityLineItemId))
            {
                opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.put(opptLineItemSchedule.OpportunityLineItemId, new Map<Id, List<OpportunityLineItemSchedule>>());
            }
            
            if(!opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
        }
        
        for(String opportunityLineItemId : opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.keySet())
        {
            for(String SalesOrderId : opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).keySet())
            {
                system.assertEquals(1, opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).get(SalesOrderId).size());
                system.assertEquals(2000, opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).get(SalesOrderId)[0].Revenue);
            }
        }
        
        for(Sales_Order__c so : salesOrders)
        {
            system.assertEquals(5, opptLineItemScheduleMapBySalesOrderId.get(so.Id).size());
        }
        
        Test.startTest();
        
        i = 0;
        for(Booking_Line_Item__c bookingLineItem : bookingLineItems)
        {
            bookingLineItem.Product__c = products[i].Id;
            bookingLineItem.Gross_Price__c = 1500;
            i++;
            
            if(i >= products.size())
            {
                i = 0;
            }
        }
        
        update bookingLineItems;
        
        opptLineItemScheduleMapBySalesOrderId.clear();
        opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.clear();
         
        for(OpportunityLineItemSchedule opptLineItemSchedule : [Select o.ScheduleDate, o.Revenue, o.OpportunityLineItem.Sales_Order__c, o.OpportunityLineItem.PricebookEntry.Product2Id, 
                                                        o.OpportunityLineItemId 
                                                        From OpportunityLineItemSchedule o 
                                                        Where o.OpportunityLineItemId IN: opportunityLineItems])
        {
            if(!opptLineItemScheduleMapBySalesOrderId.containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderId.put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderId.get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
            
            if(!opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.containsKey(opptLineItemSchedule.OpportunityLineItemId))
            {
                opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.put(opptLineItemSchedule.OpportunityLineItemId, new Map<Id, List<OpportunityLineItemSchedule>>());
            }
            
            if(!opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opptLineItemSchedule.OpportunityLineItemId).get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
        }
        
        for(String opportunityLineItemId : opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.keySet())
        {
            for(String SalesOrderId : opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).keySet())
            {
                system.assertEquals(1, opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).get(SalesOrderId).size());
                // TODO: need to recheck assertion
                //system.assertEquals(1500, opptLineItemScheduleMapBySalesOrderIdByOpportunityLineItemId.get(opportunityLineItemId).get(SalesOrderId)[0].Revenue);
            }
        }
        
        for(Sales_Order__c so : salesOrders)
        {
            system.assertEquals(5, opptLineItemScheduleMapBySalesOrderId.get(so.Id).size());
        }
        
        Test.stopTest();        
    }
    
    static testMethod void deleteOpportunityLineItemScheduleTest() 
    {
        OpportunityScheduleManagement_Ctr_Test.setTestData();
        
        // Case 1 : only one product for one booking line item 
        // create booking line items
        List<Booking_Line_Item__c> bookingLineItems = new List<Booking_Line_Item__c>(); 
        for(Integer i = 0; i < bookings.size(); i++)
        {
            bookingLineItems.addAll(TestDataFactory.createBookingLineItems(10, bookings[i]));
        }
        
        Integer i = 0;
        for(Booking_Line_Item__c bookingLineItem : bookingLineItems)
        {
            bookingLineItem.Product__c = products[i].Id;
            i++;
            
            if(i >= products.size())
            {
                i = 0;
            }
        }
        
        insert bookingLineItems;
        
        Test.startTest();
        
        // validate results before delete
        Map<Id, List<OpportunityLineItemSchedule>> opptLineItemScheduleMapBySalesOrderId = new Map<Id, List<OpportunityLineItemSchedule>>();
       
        for(OpportunityLineItemSchedule opptLineItemSchedule : [Select o.ScheduleDate, o.Revenue, o.OpportunityLineItem.Sales_Order__c, o.OpportunityLineItem.PricebookEntry.Product2Id, 
                                                        o.OpportunityLineItemId 
                                                        From OpportunityLineItemSchedule o 
                                                        Where o.OpportunityLineItemId IN: opportunityLineItems])
        {
            if(!opptLineItemScheduleMapBySalesOrderId.containsKey(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c))
            {
                opptLineItemScheduleMapBySalesOrderId.put(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c, new List<OpportunityLineItemSchedule>());
            }
            
            opptLineItemScheduleMapBySalesOrderId.get(opptLineItemSchedule.OpportunityLineItem.Sales_Order__c).add(opptLineItemSchedule);
        }
        
        for(Sales_Order__c so : salesOrders)
        {
            system.assertEquals(5, opptLineItemScheduleMapBySalesOrderId.get(so.Id).size());
        }
        
        delete bookingLineItems;
        
        // validate results after delete
        // it should not contains any opportunity line item schedule
        opptLineItemScheduleMapBySalesOrderId.clear();
        
        Integer numOfOpportunityLineItemSchedule = [Select count()
                                                    From OpportunityLineItemSchedule o 
                                                    Where o.OpportunityLineItemId IN: opportunityLineItems];
        // TODO: need to recheck assertion
        // system.assertEquals(0, numOfOpportunityLineItemSchedule);
        
        Test.stopTest();      
    }
    
    private static void setTestData() 
    {
        // SFE-766 2015-12-21 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition 
        TestDataFactory.createFaxSystemParameters();
            
        // create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        // create product
        products = TestDataFactory.createProducts(5);
        
        // SFE-766 2015-12-21 darshan.gosar@bluewolfgroup.com
            // To cover test scenarios without seeAllData condition 
        // create pricebook
        pricebooks = TestDataFactory.createCustomPricebookData();
        pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        
        // create sales order
        salesOrders = TestDataFactory.createSalesOrders(5, accounts[0], accounts[0], accounts[0], contacts[0], null);
        insert salesOrders;
        
        // create booking
        bookings = TestDataFactory.createBookings(5, salesOrders);
        insert bookings;
        
        // create opportunity
        List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(1, null, accounts[0], contacts[0]); // Updated by Bohao Chen on 30/05/2014
        insert opportunities;
        
        // create opportunity line items
        
        opportunityLineItems = new List<OpportunityLineItem>();
        
        Integer i = 0;
        for(Sales_Order__c so : salesOrders)
        {
            opportunityLineItems.addAll(TestDataFactory.createOpportunityLineItems(opportunities, products, pricebookEntries, salesOrders[i].Id));
            i++;
        }
        
        insert opportunityLineItems;
        
        system.assertEquals(25, opportunityLineItems.size());
    }

}
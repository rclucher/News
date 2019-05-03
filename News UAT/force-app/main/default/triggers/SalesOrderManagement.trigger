/*---------------------------------------------------------
 * Author: Paul Fayle / Bohao Chen
 * Company: Salesforce.com
 * Description: 
 1. Trigger to populate the Advertiser/Customer, Placer, Payer Accounts from the parent Sales Order to the Booking
 2. Trigger is for sales order made from online booking (OSCA) Online bookings always create new orders
 * which allows for related Bookings lists on Accounts
 * History:
 * 2/08/2013    Bohao Chen  Created
 * 21/08/2013   Paul Fayle  Updated
 * 26/08/2013   Bohao Chen  Updated
 * 22/11/2013   Celso de Souza updated //Added support for Cyber$ell sales orders created by Integrator user
 * 27/05/2014   Bohao Chen  Updated 
 ---------------------------------------------------------*/
trigger SalesOrderManagement on Sales_Order__c (after insert, after update, before delete) // Update by Bohao Chen on 27/5/2014 for JIRA SFE-4
{
    // Updated by Bohao Chen on 27/05/2014 for JIRA SFE-4
    Map<Id, Account> accountsByAccountId= new Map<Id, Account>();
    
    Map<Id, Decimal> tcsByAccountId= new Map<Id, Decimal>();
    Map<Id, Decimal> tasByAccountId= new Map<Id, Decimal>();
    // Update Ends

    // R-0820
    Map<Id, Id> ownerIdBySalesOrderId = new Map<Id, Id>();
    
    // this trigger is for sales order made from online booking (OSCA)
    // Online bookings always create new orders
    if (Global_Helper.canTrigger( 'SalesOrderManagement' ) ){
        if(trigger.isAfter && trigger.isInsert)
        {
            List<Sales_Order__c> inSalesOrders = new List<Sales_Order__c>();

            for(Sales_Order__c so : trigger.new)
            {
                // modified by Tim Fabros 20 / 06 / 2014 - SFE-527
                // added extra condition to the if statement to check for campaign track
                // BEGIN:
                if(so.Source_System__c == 'OSCA' || so.Source_System__c == 'CampaignTrack')
                {
                    inSalesOrders.add(so);
                }
                // END:
            }
            
            if(inSalesOrders.size() > 0)
            {
                Map<Id, Sales_Order__c> salesOrderById = SalesOrderCreateBooking_Helper.getSalesOrderById(inSalesOrders);
                Map<String, Opportunity> opportunityBySalesOrderId = Opportunity_Helper.createOpportunitFromSalesOrder(salesOrderById);
                List<OpportunityLineItem> opportLineItems = OpportunityLineItem_Helper.createDummyOpportunityLineItem(salesOrderById, opportunityBySalesOrderId);
            }
        }
        
        // Trigger to populate the Advertiser/Customer, Placer, Payer Accounts 
        // from the parent Sales Order to the Booking
        if(trigger.isAfter && trigger.isUpdate)
        {
            //Sales Order and Booking Lists
            Set<ID> listSO = new Set<ID>();
        
            //Loop through the Sales Orders
            for(Sales_Order__c newSo: trigger.new)
            {
                Sales_Order__c oldSo = Trigger.oldMap.get(newSo.Id);
         
                //Have the Accounts changed?
                if (newSo.Advertiser_Account__c != oldSo.Advertiser_Account__c || 
                    newSo.Payer_Account__c != oldSo.Payer_Account__c || 
                    newSo.Placer_Account__c != oldSo.Placer_Account__c )
                {
                    //Then add to newSo List
                    listSO.add(newSo.Id);
                }
                
                // R-0820
                ownerIdBySalesOrderId.put(newSo.Id, newSo.OwnerId);
                
                // Updated by Bohao Chen on 27/05/2014 for JIRA SFE-4   
                // There are 7 combination of updates in terms of ad account, payer account and gross price
                system.debug(loggingLevel.ERROR,'@trigger ran? ' + SalesOrderManagement_Helper.isNotInSalesOrderIdSetForUpdate(newSo.Id));

                if(SalesOrderManagement_Helper.isNotInSalesOrderIdSetForUpdate(newSo.Id))
                {
                    if(oldSo.Advertiser_Account__c != newSo.Advertiser_Account__c)
                    {
                        // Case 1: Only if advertiser account gets updated
                        if(oldSo.Payer_Account__c == newSo.Payer_Account__c 
                            && oldSo.Total_Gross_Price_Ytd__c == newSo.Total_Gross_Price_Ytd__c)
                        {
                            system.debug(loggingLevel.ERROR,'@Case 1');
                            if(oldSo.Advertiser_Account__c == oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId); 

                                // add gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, newSo.Total_Gross_Price_Ytd__c, tasByAccountId); 

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c == newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -newSo.Total_Gross_Price_Ytd__c, tcsByAccountId); 

                                // minus gross price from old payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Payer_Account__c, -newSo.Total_Gross_Price_Ytd__c, tasByAccountId); 

                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId); 

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -newSo.Total_Gross_Price_Ytd__c, tcsByAccountId); 

                                // add gross price to new advertiser account       
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);                      

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                        }
                        // Case 2: If both advertiser and payer account get updated
                        else if(oldSo.Payer_Account__c != newSo.Payer_Account__c
                            && oldSo.Total_Gross_Price_Ytd__c == newSo.Total_Gross_Price_Ytd__c)
                        {
                            system.debug(loggingLevel.ERROR,'@Case 2');
                            if(oldSo.Advertiser_Account__c == oldSo.Payer_Account__c && newSo.Advertiser_Account__c == newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);
                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c == oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                // add gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, newSo.Total_Gross_Price_Ytd__c, tasByAccountId); 

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c == newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                // minus gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Payer_Account__c, -newSo.Total_Gross_Price_Ytd__c, tasByAccountId);   
                                
                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);   

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                // minus gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Payer_Account__c, -newSo.Total_Gross_Price_Ytd__c, tasByAccountId);   
                                
                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);  

                                // add gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, newSo.Total_Gross_Price_Ytd__c, tasByAccountId);  

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                        }

                        // Case 3: If both advertiser and gross price get updated
                        else if(oldSo.Payer_Account__c == newSo.Payer_Account__c
                            && oldSo.Total_Gross_Price_Ytd__c != newSo.Total_Gross_Price_Ytd__c)
                        {
                            system.debug(loggingLevel.ERROR,'@Case 3');
                            if(oldSo.Advertiser_Account__c == oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId); 

                                // add gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, newSo.Total_Gross_Price_Ytd__c, tasByAccountId); 

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c == newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tcsByAccountId); 

                                // minus gross price from old payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Payer_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tasByAccountId); 

                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId); 

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tcsByAccountId); 

                                // add gross price to new advertiser account       
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);                      

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                        }

                        // Case 4 : If advertiser, payer account and gross price all get updated
                        else if(oldSo.Payer_Account__c != newSo.Payer_Account__c
                            && oldSo.Total_Gross_Price_Ytd__c != newSo.Total_Gross_Price_Ytd__c)
                        {
                            system.debug(loggingLevel.ERROR,'@Case 4');
                            if(oldSo.Advertiser_Account__c == oldSo.Payer_Account__c && newSo.Advertiser_Account__c == newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tcsByAccountId);
                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c == oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                // add gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, newSo.Total_Gross_Price_Ytd__c, tasByAccountId); 

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c == newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                // minus gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Payer_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tasByAccountId);   
                                
                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);   

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // minus gross price from old advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Advertiser_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tcsByAccountId);

                                // minus gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Payer_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tasByAccountId);   
                                
                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, newSo.Total_Gross_Price_Ytd__c, tcsByAccountId);  

                                // add gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, newSo.Total_Gross_Price_Ytd__c, tasByAccountId);  

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                        }
                    }
                    else if(oldSo.Payer_Account__c != newSo.Payer_Account__c)
                    {
                        // Case 5 : if only payer account gets updated
                        if(oldSo.Advertiser_Account__c == newSo.Advertiser_Account__c
                            && oldSo.Total_Gross_Price_Ytd__c == newSo.Total_Gross_Price_Ytd__c)
                        {
                            system.debug(loggingLevel.ERROR,'@Case 5');
                            if(oldSo.Advertiser_Account__c == oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // add gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, newSo.Total_Gross_Price_Ytd__c, tasByAccountId);  

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }

                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c == newSo.Payer_Account__c)
                            {
                                // minus gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Payer_Account__c, -newSo.Total_Gross_Price_Ytd__c, tasByAccountId);  

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // minus gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Payer_Account__c, -newSo.Total_Gross_Price_Ytd__c, tasByAccountId);
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, newSo.Total_Gross_Price_Ytd__c, tasByAccountId);

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                        }

                        // Case 6 : if both payer account and gross price gets updated
                        if(oldSo.Advertiser_Account__c == newSo.Advertiser_Account__c
                            && oldSo.Total_Gross_Price_Ytd__c != newSo.Total_Gross_Price_Ytd__c)
                        {
                            system.debug(loggingLevel.ERROR,'@Case 6');

                            Decimal grossPriceDiff = newSo.Total_Gross_Price_Ytd__c - oldSo.Total_Gross_Price_Ytd__c;

                            if(oldSo.Advertiser_Account__c == oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, grossPriceDiff, tcsByAccountId);  

                                // add gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, newSo.Total_Gross_Price_Ytd__c, tasByAccountId);  

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }

                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c == newSo.Payer_Account__c)
                            {
                                // add gross price to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, grossPriceDiff, tcsByAccountId);  

                                // minus gross price to new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Payer_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tasByAccountId); 

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(oldSo.Advertiser_Account__c != oldSo.Payer_Account__c && newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                // add gross price diff to new advertiser account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, grossPriceDiff, tcsByAccountId);

                                // minus old gross price from old payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(oldSo.Payer_Account__c, -oldSo.Total_Gross_Price_Ytd__c, tasByAccountId);

                                // add new gross price to new new payer account
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, newSo.Total_Gross_Price_Ytd__c, tasByAccountId);

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                        }

                    }
                    else if(oldSo.Total_Gross_Price_Ytd__c != newSo.Total_Gross_Price_Ytd__c)
                    {
                        Decimal grossPriceDiff = newSo.Total_Gross_Price_Ytd__c - oldSo.Total_Gross_Price_Ytd__c;

                        // Case 7 : if only gross price gets updated
                        if(oldSo.Advertiser_Account__c == newSo.Advertiser_Account__c 
                            && oldSo.Payer_Account__c == newSo.Payer_Account__c)
                        {
                            system.debug(loggingLevel.ERROR,'@so Id: ' + newSo.Id);
                            system.debug(loggingLevel.ERROR,'@new gp: ' + newSo.Total_Gross_Price_Ytd__c + ' old gp: ' + oldSo.Total_Gross_Price_Ytd__c);
                            system.debug(loggingLevel.ERROR,'@Case 7');

                            system.debug(loggingLevel.ERROR,'@new ad account: ' + newSo.Advertiser_Account__c + ' old ad acct: ' + oldSo.Advertiser_Account__c);
                            system.debug(loggingLevel.ERROR,'@new pay account: ' + newSo.Payer_Account__c + ' old pay acct: ' + oldSo.Payer_Account__c);

                            if(newSo.Advertiser_Account__c == newSo.Payer_Account__c)
                            {
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, grossPriceDiff, tcsByAccountId);  

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                            else if(newSo.Advertiser_Account__c != newSo.Payer_Account__c)
                            {
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Advertiser_Account__c, grossPriceDiff, tcsByAccountId); 
                                SalesOrderManagement_Helper.updateTcsTasByAccountIdMap(newSo.Payer_Account__c, grossPriceDiff, tasByAccountId); 

                                SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForUpdate(newSo.Id);
                            }
                        }
                    }

                    system.debug(loggingLevel.ERROR,'@salesorder trigger after update tcsByAccountId: ' + tcsByAccountId);
                    system.debug(loggingLevel.ERROR,'@salesorder trigger after update tasByAccountId: ' + tasByAccountId);


                    //SalesOrderManagement_Helper.isNotInSalesOrderIdSetForUpdate(newSo.Id);
                }
                // Update Ends
            }
             
            //get Sales Order & Booking info for changed records
            //Loop through changed salesOrder's related Bookings to modify Account info 
            List<Booking__c> listBooking = new List<Booking__c>();
          
            for(Sales_Order__c salesOrder: [SELECT Advertiser_Account__c, Payer_Account__c, Placer_Account__c, 
                                            (Select Payer_Account__c, Placer_Account__c, Advertiser_Account__c From Bookings__r) 
                                            FROM Sales_Order__c 
                                            WHERE Id in :listSO])
            { 
                for(Booking__c bk: salesOrder.Bookings__r)
                {
                    bk.Advertiser_Account__c =  salesOrder.Advertiser_Account__c;
                    bk.Payer_Account__c = salesOrder.Payer_Account__c;
                    bk.Placer_Account__c = salesOrder.Placer_Account__c;
                    listBooking.add(bk);
                } 
            }
            
            try
            {
                //update list outside of loop
                update listBooking;
            }            
            catch(Exception ex)
            {
                ExLog.log(ex, 'config', listBooking, 'SFE-723 Investigation');
            }
            
        }
        
        // Updated by Bohao Chen on 27/05/2014 for JIRA SFE-4                        
        if(trigger.isBefore && trigger.isDelete)
        {
            for(Sales_Order__c so : trigger.old)
            {
                // todo: comment.....
                system.debug(loggingLevel.ERROR,'@trigger ran? ' + SalesOrderManagement_Helper.isNotInSalesOrderIdSetForDelete(so.Id));

                if(SalesOrderManagement_Helper.isNotInSalesOrderIdSetForDelete(so.Id))
                {
                    if(so.Total_Gross_Price_Ytd__c != null && so.Total_Gross_Price_Ytd__c > 0)
                    {
                        if(so.Payer_Account__c != null && so.Payer_Account__c != so.Advertiser_Account__c && tasByAccountId.containsKey(so.Payer_Account__c))
                        {
                            Decimal totalAgencySpending = tasByAccountId.get(so.Payer_Account__c) - so.Total_Gross_Price_Ytd__c;                            
                            tasByAccountId.put(so.Payer_Account__c, totalAgencySpending);
                            SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForDelete(so.Id);
                        }
                        
                        if(so.Advertiser_Account__c != null && tcsByAccountId.containsKey(so.Advertiser_Account__c))
                        {
                            Decimal totalCustomerSpending = tasByAccountId.get(so.Advertiser_Account__c) - so.Total_Gross_Price_Ytd__c;
                            tcsByAccountId.put(so.Advertiser_Account__c, totalCustomerSpending);
                            SalesOrderManagement_Helper.addIdIntoSalesOrderIdSetForDelete(so.Id);
                        }
                    }
                    
                    system.debug('@salesordermanagement before delete tasByAccountId: ' + tasByAccountId);
                    system.debug('@salesordermanagement before delete tcsByAccountId: ' + tcsByAccountId);
                }
            }
        }
        // Update Ends
        
        /*
         * R-0820: when sales orders get updated, we have to find out current owner of opportunity 
         * via opportunity line item with same sales order number. Then, we need to compare
         * current owner of opportunity with owner of sales order. If they are different, owner
         * of opportunities need to be updated to reflect latest owner of sales orders.
         * NOTE: sales order owner gets updated when sales rep on its bookings changes. 
         */
        if(ownerIdBySalesOrderId.size() > 0)
        {
            Map<Id, Id> ownerIdByOpoortunityId = new Map<Id, Id>();
            
            for(OpportunityLineItem oli : [Select o.Sales_Order__c, o.Opportunity.OwnerId, 
                                            o.Opportunity.Id, o.OpportunityId 
                                            From OpportunityLineItem o
                                            Where o.Sales_Order__c IN: ownerIdBySalesOrderId.keySet()])
            {
                // only opportunities whose owner id is not the same as current sales order owner id
                if(oli.Opportunity.OwnerId != ownerIdBySalesOrderId.get(oli.Sales_Order__c))
                {
                    ownerIdByOpoortunityId.put(oli.OpportunityId, ownerIdBySalesOrderId.get(oli.Sales_Order__c));
                }
            }
            
            system.debug('===ownerIdByOpoortunityId==' + ownerIdByOpoortunityId);
            
            List<Opportunity> ownerUpdatedOpportunities = new List<Opportunity>();
            
            for(Opportunity o : [Select o.OwnerId 
                                From Opportunity o 
                                Where o.Id IN: ownerIdByOpoortunityId.keySet()])
            {
                // update opportunity owner id to sales order owner id
                o.OwnerId = ownerIdByOpoortunityId.get(o.Id);
                ownerUpdatedOpportunities.add(o);
            }
            
            system.debug('===ownerUpdatedOpportunities=== ' + ownerUpdatedOpportunities);
            
            try
            {
                update ownerUpdatedOpportunities;
            }
            catch(Exception ex)
            {
                ExLog.log(ex, 'config', ownerUpdatedOpportunities, 'SFE-723 Investigation');
            }
        }

        system.debug(loggingLevel.ERROR, '@tcsByAccountId: ' + tcsByAccountId);
        system.debug(loggingLevel.ERROR, '@tasByAccountId: ' + tasByAccountId);
        
        SalesOrderManagement_Helper.updateAccountSpendings(tcsByAccountId, tasByAccountId);
    }
}
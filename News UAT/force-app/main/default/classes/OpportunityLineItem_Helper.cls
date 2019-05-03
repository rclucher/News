/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: 
 * 1. R-0627 - This is helper class for trigger 'OpportunityManagement' is for requirement R-0627:
 *             Ability to copy the revenue for the opportunity and opportunity product line at time 
 *             of opportunity closure (won or lost)
 * 2. It also creates dummy opportunity line item as place holder if there is no opportunity line item in opportunity when booking
 * History:
 * 13/06/2013  Bohao Chen  Created
 * 2016-01-05  Darshan G   Updated
 * 2016-04-18  David D added sales summary functionality
 */
public with sharing class OpportunityLineItem_Helper
{
    // create dummy opportunity line item
    public static List<OpportunityLineItem> createDummyOpportunityLineItem(
                                            Map<Id, Sales_Order__c> salesOrderById, 
                                            Map<String, Opportunity> opportunityBySalesOrderId)
    {
        //System.debug('@ createDummyOpportunityLineItem()');
        
        //System.debug('@ OpportunityLineItem_Helper opportunityBySalesOrderId: ' + opportunityBySalesOrderId);
        Id pricebookId;         
        
        // SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
            // To cover test scenarios without seeAllData condition        
        if(!Test.isRunningTest()){
            pricebookId = [Select p.Name, p.Id From Pricebook2 p where Name = 'Standard Price Book'].Id;
        }
        else{
            pricebookId = Test.getStandardPricebookId();
        }
        
        Product2 prod = [Select id From Product2 Where Name=:'Dummy'];
        Id pricebookEntryId = [Select p.UnitPrice, p.Product2Id, p.Pricebook2Id From PricebookEntry p
                                          Where Pricebook2Id = :pricebookId
                                          AND Product2Id = :prod.id limit 1].Id;                    
        
                          
        List<OpportunityLineItem> opptLineItems = new List<OpportunityLineItem>();
      
        for(String salesOrderId : opportunityBySalesOrderId.keySet())
        {
            Opportunity opportunity = opportunityBySalesOrderId.get(salesOrderId);

            OpportunityLineItem opptLineItem = new OpportunityLineItem();
            opptLineItem.OpportunityId = opportunity.Id;
            opptLineItem.Sales_Order__c = salesOrderId;
            opptLineItem.PricebookEntryId = pricebookEntryId;
            opptLineItem.ServiceDate = date.today();
            opptLineItem.of_Periods__c = 1;
            opptLineItem.Quantity = 1;
            opptLineItem.Pattern__c = 'Weekly';
            opptLineItem.Period__c = 'Week(s)';
            opptLineItem.TotalPrice = 0;
            opptLineItems.add(opptLineItem);
        }
		try{
        	insert opptLineItems;
		}
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', opptLineItems, 'SFE-824 Investigation');
        }
        //System.debug('@ OpportunityLineItem_Helper opptLineItems:' + opptLineItems);
        return opptLineItems;
    }
    
    // Requirement R-0627
    // Ability to copy the revenue for the opportunity and opportunity product line at time of opportunity closure (won or lost)
    public static void updateOpportunityLineItemRevenueAtClose(Set<Id> revenueCopiedOpportunityList, 
                                                               Set<Id> revenueUncopiedOpportunityList)
    {
        Set<Id> allOpportunityList = new Set<Id>();
        allOpportunityList.addAll(revenueCopiedOpportunityList);
        allOpportunityList.addAll(revenueUncopiedOpportunityList);
        
        List<OpportunityLineItem> opprtunityLineItemList = new List<OpportunityLineItem>();
        
        for(OpportunityLineItem oppLineItem : [Select o.UnitPrice, o.Revenue_AtClose__c, o.OpportunityId 
                                               From OpportunityLineItem o 
                                               Where o.OpportunityId IN: allOpportunityList])
        {
            if(revenueCopiedOpportunityList.contains(oppLineItem.OpportunityId))
            {
                oppLineItem.Revenue_AtClose__c = oppLineItem.UnitPrice;
            }
            else if(revenueUncopiedOpportunityList.contains(oppLineItem.OpportunityId))
            {
                oppLineItem.Revenue_AtClose__c = null;
            }
            
            opprtunityLineItemList.add(oppLineItem);
        }
        
        //System.debug('@ OpportunityLineItem_Helper opprtunityLineItemList:' + opprtunityLineItemList.size());
        try{
        	update  opprtunityLineItemList;
		}
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', opprtunityLineItemList, 'SFE-824 Investigation');
        }
    }
    
    // to delete a list of existing revenue schedule items associated with opportunity line item
    public static void deleteOpportunityLineItemSchedules(List<OpportunityLineItem> opportunityLineItems)
    {  
        List<OpportunityLineItemSchedule> oldLineItemScheduleList = [Select o.OpportunityLineItemId, o.Id 
                                                                        From OpportunityLineItemSchedule o 
                                                                        Where o.OpportunityLineItemId IN: opportunityLineItems];
        
        System.debug('@ OpportunityLineItem_Helper old line item schedule:' + oldLineItemScheduleList);
        try{
        	delete oldLineItemScheduleList;
    	}
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', oldLineItemScheduleList, 'SFE-824 Investigation');
        }
    }
    
    // to create a list of new revenue schedule items associated with opportunity line item
    public static void createOpportunityLineItemSchedules(List<OpportunityLineItemWrapper> opportunityLineItems)
    {       
        // insert new revenue schedule items
        List<OpportunityLineItemSchedule> revenueScheduleItems = new List<OpportunityLineItemSchedule>();
        Map<Id, List<OpportunityLineItemSchedule>> revenueScheduleItemsByOpportunityLineItemId = new Map<Id, List<OpportunityLineItemSchedule>>();
        
        for(OpportunityLineItemWrapper o : opportunityLineItems)
        {
            String frequency = o.getRevenueScheduleFrequency();
            List<String> pattern = o.getRevenueSchedulePattern();
            Integer index = 1;
            Date startDate = o.opportunityLineItem.ServiceDate;
            Date endDate;
            Date dateLocator = startDate;
            
            //System.debug('@ OpportunityLineItem_Helper  endDate: ' + endDate);
            //System.debug('@ OpportunityLineItem_Helper  startDate: ' + startDate);
            //System.debug('@ OpportunityLineItem_Helper  o.opportunityLineItem.of_Periods__c:' + o.opportunityLineItem.of_Periods__c);

            if(startDate != null)
            {
                if(o.opportunityLineItem.Period__c == 'Week(s)')
                    endDate = startDate.addDays(Integer.valueOf(o.opportunityLineItem.of_Periods__c * 7));
                else if(o.opportunityLineItem.Period__c == 'Month(s)')
                    endDate = startDate.addMonths(Integer.valueOf(o.opportunityLineItem.of_Periods__c));
                
                while(endDate != null && startDate != null && String.isNotBlank(frequency) 
                   && !pattern.isEmpty() && dateLocator < endDate)
                {
                    
                    
                    if(pattern[index] == '1')
                    {
                        OpportunityLineItemSchedule lineItemSchedule = new OpportunityLineItemSchedule();
                        lineItemSchedule.Description = o.opportunityLineItem.Description;
                        lineItemSchedule.OpportunityLineItemId = o.opportunityLineItem.Id;
                        lineItemSchedule.ScheduleDate = dateLocator;
                        lineItemSchedule.Type = 'Revenue';
                        
                        if(!revenueScheduleItemsByOpportunityLineItemId.containsKey(o.opportunityLineItem.Id))
                            revenueScheduleItemsByOpportunityLineItemId.put(o.opportunityLineItem.Id, new List<OpportunityLineItemSchedule>());
                            
                        revenueScheduleItemsByOpportunityLineItemId.get(o.opportunityLineItem.Id).add(lineItemSchedule);
                        
                        o.numOfSchedules++; // increment number of schedules for each opportunity line item
                    }
                    
                    // increment datelocator
                    if(frequency == 'Week')
                        dateLocator = dateLocator.addDays(7);
                    else if(frequency == 'Month')
                        dateLocator = dateLocator.addMonths(1);
                    else
                    {
                        dateLocator = dateLocator.addDays(1);
                    }
                    index++;
                    
                    //System.debug('@ OpportunityLineItem_Helper index:' + index + ' == size == ' + pattern.size());
                    
                    //System.debug('@ OpportunityLineItem_Helper dateLocator:' + dateLocator);
                    
                    // increment pattern index
                    if(index == pattern.size())
                        index = 1;
                }
            }
        }
        
        for(OpportunityLineItemWrapper opportLineItem : opportunityLineItems)
        {
            if(!revenueScheduleItemsByOpportunityLineItemId.isEmpty())
            {
                for(OpportunityLineItemSchedule opportLineItemSchedule : revenueScheduleItemsByOpportunityLineItemId.get(opportLineItem.opportunityLineItem.Id))
                {
                    if(opportLineItem.numOfSchedules > 0)
                        opportLineItemSchedule.Revenue = opportLineItem.opportunityLineItem.UnitPrice / opportLineItem.numOfSchedules;
                }
            
                revenueScheduleItems.addAll(revenueScheduleItemsByOpportunityLineItemId.get(opportLineItem.opportunityLineItem.Id));
            }
        }
        
        //System.debug('@ OpportunityLineItem_Helper revenueScheduleItems:' + revenueScheduleItems);

        // Updated by Bohao Chen on 14/July/2014 For JIRA SFE-373
        // Begin
        List<Database.SaveResult> uResults = Database.insert(revenueScheduleItems,false);

        Integer i = 0;
        String exceptionMessage = '';

        for(Database.SaveResult result : uResults) 
        {

            if (!result.isSuccess())
            {            	
                for(Database.Error error : result.getErrors()) 
                {
                    if (error.getMessage().containsIgnoreCase('scheduling not enabled on product'))
                    {
                        exceptionMessage += 'Unable to add ' + opportunityLineItems[i].productName + ' product. Please ensure that you have enabled revenue scheduling for all products.<br/>'
                                        + 'To enable revenue scheduling, select Setup > Customise > Products > Schedule Setup.<br/>'
                                        + 'Under "Schedule Setup", click "Enable revenue scheduling for all products"<br/>';
                    }
                    else
                    {
                        exceptionMessage += error.getMessage();
                    }
                    
                }
            }

            i++;
        }

        if(String.isNotBlank(exceptionMessage))
        {
            system.debug('@exceptionMessage from helper: ' + exceptionMessage);			
			ExLog.log(new CustomException('Opportunity Line Item Schedule Error - see Additional Info'), 'config', (sObject) null, exceptionMessage);            
            throw new OpportunityLineItem_Helper_Exception(exceptionMessage);
        }
        // End
    }
    
    public static void zeroOpportunityLineItemRevenue(Set<Id> opportuntiyWithZeroOpportunityLineItems)
    {
        List<OpportunityLineItem> updatedOpportunityLineItems = new List<OpportunityLineItem>();
        List<OpportunityLineItemSchedule> deleteOpportunityLineItemSchedules = new List<OpportunityLineItemSchedule>();
         
        for(OpportunityLineItem oli : [Select o.TotalPrice, o.Sales_Order__r.Id, o.OpportunityId, o.Sales_Order__c, 
                                    (Select Id From OpportunityLineItemSchedules) From OpportunityLineItem o 
                                    Where o.OpportunityId IN: opportuntiyWithZeroOpportunityLineItems
                                    And o.Sales_Order__c = null])
        {
            
            // if sales order is blank on opportunity line item and opportunity line item has schedule items,
            // schedule items have to be deleted in order for total revenue (totalPrice) on opportunity line items to be zeroed out
            if(oli.OpportunityLineItemSchedules.size() > 0)
            {
                deleteOpportunityLineItemSchedules.addAll(oli.OpportunityLineItemSchedules);
            }
            
            // after schedule items have been deleted, 
            // we need to zero out total revenue (totalPrice) on opportunity line items
            // if sales order is blank on opportunity line item
            oli.TotalPrice = 0;
            oli.ServiceDate = null;
            oli.Pattern__c = null;
            oli.Period__c = null;
            oli.Quantity = 1;
            oli.Period__c = null;
            updatedOpportunityLineItems.add(oli);
        }   
        
        // delete unnecessary opportunity schedule items prior to reseting total revenue on its opportunity line item
        // otherwise, system will throw error when zero total revenue
        if(deleteOpportunityLineItemSchedules.size() > 0)
        {
        	try{
            	delete deleteOpportunityLineItemSchedules;
	        }
	        catch(Exception ex)
	        {
	            ExLog.log(ex, 'config', deleteOpportunityLineItemSchedules, 'SFE-824 Investigation');
	        }
        }
        if(updatedOpportunityLineItems.size() > 0)
        {
        	try{
            	update updatedOpportunityLineItems;
            }
	        catch(Exception ex)
	        {
	            ExLog.log(ex, 'config', updatedOpportunityLineItems, 'SFE-824 Investigation');
	        }
        }
    }
    
    /**** Updated by Bohao Chen on 17/03/2014 for JIRA SFE-104 *****/
    public static Boolean isOpportunityLineManagementTriggerEnabled
    {get { return isOpportunityLineManagementTriggerEnabled != null ? isOpportunityLineManagementTriggerEnabled : true;} set;}
    /**** Updated by Bohao Chen *****/
    
    /**** Updated by Bohao Chen on 1/4/2014 for JIRA SFE-248 *****/
    public static Boolean isWalkinForecast
    {get { return isWalkinForecast != null ? isWalkinForecast : false;} set;}
    /**** Updated by Bohao Chen *****/    

    // added by Tim Fabros 11 / 07 / 2014 - SFE-373
    // added custom exception
    // BEGIN:
    public class OpportunityLineItem_Helper_Exception extends Exception {}
    // END:
    //////////////////////////////////////////////////////////////
    // Inner Classes
    //////////////////////////////////////////////////////////////    
    /**    
    * @description  This inner class extends Exception class. It is used to enter Reusable Exception Logging Module.
    * @author       darshan.gosar@bluewolf.com
    * @date         2016-06-10
    */
    public class CustomException extends Exception {}
}
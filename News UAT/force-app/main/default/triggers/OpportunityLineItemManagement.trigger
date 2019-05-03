/*---------------------------------------------------------
* Author: Bohao Chen
* Company: Salesforce.com
* Description: This is Opportunity Line Item trigger
* History:
5/06/2013  Bohao Chen  Created
15/05/2016  David Dawson  Added functionality for the Revenue Reporting to associate OLI records with a Sales Summry record.
15/08/2016 Peter Charalambous - Removed Revenue Reporting functions as per Revenue Reporting R1.2 Solution
21/11/2018 Mohsin Ali - Adding isInsert check for creation of Revenue Schedule upon Sync Button on CPQ. Refer to Jira: NR-1988.
---------------------------------------------------------*/
trigger OpportunityLineItemManagement on OpportunityLineItem (after insert, after update, after delete, before insert, before update) 
{
    /**** Updated by Bohao Chen on 17/03/2014 for JIRA SFE-104 *****/
    if (Global_Helper.canTrigger( 'OpportunityLineItemManagement' ) && OpportunityLineItem_Helper.isOpportunityLineManagementTriggerEnabled ){
        /**** Updated by Bohao Chen *****/    
        if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate))	
        {
            // In order to prevent trigger from firing when trying to create dummy opportunity line item
            List<OpportunityLineItemWrapper> opportunityLineItemsList = new List<OpportunityLineItemWrapper>();
            List<OpportunityLineItem> delOpportunityLineItemsList = new List<OpportunityLineItem>();
            
            Set<Id> opportuntiyWithZeroOpportunityLineItems = new Set<Id>();
            
            // alternative way
            for(OpportunityLineItem newOpptLineItem : trigger.new)
            {
                if(trigger.isUpdate)
                {
                    OpportunityLineItem oldOpptLineItem = trigger.oldMap.get(newOpptLineItem.Id);
                    
                    system.debug('@OpportunityLineItemManagement isdifferent: ' + isDifferent(oldOpptLineItem, newOpptLineItem));
                    
                    // compare values of each field see if there are any changes
                    if(isDifferent(oldOpptLineItem, newOpptLineItem))
                    {
                        opportunityLineItemsList.add(new OpportunityLineItemWrapper(newOpptLineItem));
                        delOpportunityLineItemsList.add(newOpptLineItem);
                    }
                    
                    // check if sales order has been added
                    if(String.isBlank(trigger.oldMap.get(newOpptLineItem.Id).Sales_Order__c) 
                       && String.isNotBlank(newOpptLineItem.Sales_Order__c))
                    {
                        system.debug('@ OpportunityLineItemManagement === new sales order comes in');
                        opportuntiyWithZeroOpportunityLineItems.add(newOpptLineItem.OpportunityId);
                    }
                    
                    
                }
                else if(trigger.isInsert)
                {
                    //System.debug('@ OpportunityLineItemManagement id of new oppt:' + newOpptLineItem.id);
                    if(newOpptLineItem.Pattern__c != null && newOpptLineItem.Pattern__c != '')
                        opportunityLineItemsList.add(new OpportunityLineItemWrapper(newOpptLineItem));
                }
                
            }
            
            system.debug('@ OpportunityLineItemManagement delOpportunityLineItemsList:' + delOpportunityLineItemsList.size());
            system.debug('@ OpportunityLineItemManagement opportunityLineItemsList:' + opportunityLineItemsList.size());
            
            /**** Updated by Bohao Chen on 1/4/2014 for JIRA SFE-248 *****/
            // in order to prevent cloning opportunity from doubling revenue,
            // the following block of code is only for update trigger.
            if(!delOpportunityLineItemsList.isEmpty() && (trigger.isUpdate || OpportunityLineItem_Helper.isWalkinForecast))
                OpportunityLineItem_Helper.deleteOpportunityLineItemSchedules(delOpportunityLineItemsList);
            
            /*Adding Trigger.isInsert to add Revenue Schedules when OpportunityLineItem is added. Refer to Jira: NR-1988*/
            if(!opportunityLineItemsList.isEmpty() && (trigger.isInsert || trigger.isUpdate || OpportunityLineItem_Helper.isWalkinForecast))
                OpportunityLineItem_Helper.createOpportunityLineItemSchedules(opportunityLineItemsList);
            /**** Updated by Bohao Chen *****/    
            
            // This has been removed as per Item-00996
            
            //if(!opportuntiyWithZeroOpportunityLineItems.isEmpty())
            //  OpportunityLineItem_Helper.zeroOpportunityLineItemRevenue(opportuntiyWithZeroOpportunityLineItems);
        }
        
        /********* Start: this block is to copy opportunity line item to customer revenue schedule*******/
        // we don't need custom field last modified datetime
        // because any schedule items change can change modified datetime, we can't tell which changes are which
        //if(trigger.isDelete && trigger.isBefore)
        if(trigger.isDelete && trigger.isAfter)
        {
            CustomRevenueSchedule_Helper.deleteCrsByOpportunityLineItems(trigger.old);
        }
        /********* End: this block is to copy opportunity line item to customer revenue schedule*******/
        
        
    }
    
    if (Global_Helper.canTrigger( 'OpportunityLineItemManagement' ))
    {
        // added by Tim Fabros 14 / 08 / 2014 - SFE-612
        // BEGIN:
        if (trigger.isBefore)
        {
            Set<Id> opportunityIds = new Set<Id>();
            Map<Id, Opportunity> opportunityById = new Map<Id, Opportunity>();
            
            for (OpportunityLineItem oli : trigger.new)
            {
                opportunityIds.add(oli.OpportunityId);
            }
            
            System.debug('@OpportunityLineItemManagement opportunityIds: ' + opportunityIds);
            
            for (Opportunity o : [SELECT OwnerId FROM Opportunity WHERE Id IN: opportunityIds])
            {
                opportunityById.put(o.Id, o);
            }
            
            for (OpportunityLineItem oli : trigger.new)
            {
                if (opportunityById.containsKey(oli.OpportunityId))
                {
                    System.debug('@OpportunityLineItemManagement opportunityById.get(oli.OpportunityId).OwnerId: ' + opportunityById.get(oli.OpportunityId).OwnerId);
                    
                    oli.Opportunity_Owner__c = opportunityById.get(oli.OpportunityId).OwnerId;
                }
            }
        }
        // END:
    }
    
    private Boolean isDifferent(OpportunityLineItem oldOpptLineItem, OpportunityLineItem newOpptLineItem)
    {
        Boolean isDifferent = false;
        
        // note that sales order is null is very important
        // if sales order is not null, it means
        if((oldOpptLineItem.Pattern__c != newOpptLineItem.Pattern__c || oldOpptLineItem.of_Periods__c != newOpptLineItem.of_Periods__c
            || oldOpptLineItem.Period__c != newOpptLineItem.Period__c || oldOpptLineItem.ServiceDate != newOpptLineItem.ServiceDate
            //|| oldOpptLineItem.UnitPrice != newOpptLineItem.UnitPrice
           )
           && oldOpptLineItem.Sales_Order__c == null)
        {
            isDifferent = true;
        }
        
        return isDifferent;
    }
}
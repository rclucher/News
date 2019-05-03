/*---------------------------------------------------------
 * Author: Atul Gupta
 * Company: atul.gupta@bluewolfgroup.com
 * Description: Helper class for WalkinForecast_ControllerX controller class
 * History:
 * 2016-01-17  Atul Gupta  Created
---------------------------------------------------------*/
public class WalkinForecast_Controller_Helper {
    	
	/**
	* @description SFE-6844 Delete any Opportunties, OpportunityLineItems and associated OpportunityLineItemSchedules
							where Custom Price is 0 or blank
	* @param n/a
	* @return void
	* @author atul.gupta@bluewolfgroup.com
	* @date 2016-02-17
	**/
	public static void deleteNullOpportunities(Set<Id> lineItemIdSetWithNullValues){
		
		//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com List of OpportunityLineItemSchedules to be deleted
		List<OpportunityLineItemSchedule> schedulesToBeDeleted = new List<OpportunityLineItemSchedule>();
		
		//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com List of OpportunityLineItems to be deleted
		List<OpportunityLineItem> opptyLineItemDeleteList = new List<OpportunityLineItem>();
		
		//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com List of Opportunities to be deleted
		List<Opportunity> deleteOpptyList = new List<Opportunity>();
		
		//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com Set of Ids for OpportunityLineItems to be deleted
		Set<Id> lineItemIds = new Set<Id>();
		
		//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com Set of Ids for Opportunities to be deleted
		Set<Id> opptyIdSetforDeletedLineItems = new Set<Id>();
		
		try{
			
			//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com query OpportunityLineItems with Custom Price as 0 or blank
			if(!lineItemIdSetWithNullValues.isEmpty()){
				opptyLineItemDeleteList = [Select Id, OpportunityId from OpportunityLineItem where Id IN : lineItemIdSetWithNullValues];
			}
			
			//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com fetch OpportunityId of OpportunityLineItems with Custom Price as 0 or blank
			if(!opptyLineItemDeleteList.isEmpty()){
				
				for(OpportunityLineItem item : opptyLineItemDeleteList){
					lineItemIds.add(item.id);
					opptyIdSetforDeletedLineItems.add(item.OpportunityId);
				}
			}
			
			//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com query OpportunityLineItemSchedules for 0 or blank OpportunityLineItems
			if(!lineItemIds.isEmpty()){
				
				for(OpportunityLineItemSchedule sch : [Select Id from OpportunityLineItemSchedule where OpportunityLineItemId IN : lineItemIds]){
					schedulesToBeDeleted.add(sch);
				}
			}
		
			//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com if schedulesToBeDeleted is not empty, delete the list
			if(!schedulesToBeDeleted.isEmpty()){
				delete schedulesToBeDeleted;
			}
			
			//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com if opptyLineItemDeleteList is not empty, delete the list
			if(!opptyLineItemDeleteList.isEmpty()){
				delete opptyLineItemDeleteList;
			}
			
			//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com Query Opportunities for Blank or 0 OpportunityLineItems
			for(Opportunity opp : [Select id, (Select Id from OpportunityLineItems) from Opportunity where Id IN : opptyIdSetforDeletedLineItems]){
				
				List<OpportunityLineItem> lineItems = opp.OpportunityLineItems;
				if(lineItems == null || lineItems.size() == 0){
					deleteOpptyList.add(opp);
				}
			}
			
			//SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com if deleteOpptyList is not empty, delete the list
			if(!deleteOpptyList.isEmpty()){
				delete deleteOpptyList;
			}
		} catch(Exception ex){
			ExLog.log(ex, 'config', opptyLineItemDeleteList, 'Delete OpportunityLineItems where Custom Price is 0 or Blank');
		}
	}
}
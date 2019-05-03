/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This trigger is for requirement R-0284:
                Ability for agent to easily determine if customer is in an active Campaign.
                When user insert new campaign member, trigger will update account of campaign member
                to the parent account of the contact of campaign member 
 * History:
 * 02/07/2013  Bohao Chen  Created
 ---------------------------------------------------------*/
trigger CampaignMemberManagement on CampaignMember (before insert) 
{
    if (Global_Helper.canTrigger( 'CampaignMemberManagement' ) ){

    if(trigger.isBefore && trigger.isInsert)
    {
    	Set<Id> contactIdSet = new Set<Id>();
    	Set<Id> campaignIdSet = new Set<Id>();
    	
    	for(CampaignMember cm : trigger.new)
    	{
    		if(cm.ContactId!=null)
    		{
    			contactIdSet.add(cm.ContactId);
    			campaignIdSet.add(cm.campaignId);
    		}
    	}
    	
    	Map<Id, Id> accountIdMapByContactId = generateAccountIdMapByContactId(contactIdSet);
    	map<String,Integer> membershipCountMapByContactIdAndCampaignId = generateMembershipCountMapByContactIdAndCampaignId(contactIdSet, campaignIdSet);
    	
    	for(CampaignMember cm : trigger.new)
        {
            cm.Account__c = accountIdMapByContactId.get(cm.ContactId);
            if(membershipCountMapByContactIdAndCampaignId.containsKey(cm.ContactId + '-' + cm.campaignId))
            	cm.Campaign_Membership_Count__c = membershipCountMapByContactIdAndCampaignId.get(cm.ContactId + '-' + cm.campaignId) + 1;
        }
    	
    }
    }
    
    private Map<String,Integer> generateMembershipCountMapByContactIdAndCampaignId(Set<Id> contactIdSet, Set<Id> campaignIdSet)
    {
    	map<String,Integer> counterMap = new map<String,Integer>();
    	
	   for(AggregateResult ar : [Select 	COUNT_DISTINCT(Campaign_Member_Id__c)counter,
	   										contact__c,
	   										campaign__c
									from 	Campaign_Response__c
									where 	contact__c IN :contactIdSet AND 
											campaign__c IN :campaignIdSet
									group by contact__c, campaign__c
									having COUNT_DISTINCT(Campaign_Member_Id__c) > 1])
		{
			counterMap.put(ar.get('contact__c') + '-' + ar.get('campaign__c'), (Integer) ar.get('counter'));
		}
		
		return 	counterMap;					
    }		
			
    
    private Map<Id, Id> generateAccountIdMapByContactId(Set<Id> contactIdSet)
    {
    	Map<Id, Id> accountIdMapByContactId = new Map<Id, Id>();
        
        for(Contact c : [Select c.AccountId, c.Id From Contact c Where c.Id IN: contactIdSet])
        {
            accountIdMapByContactId.put(c.Id, c.AccountId);
        }
        
    	return accountIdMapByContactId;
    }

}
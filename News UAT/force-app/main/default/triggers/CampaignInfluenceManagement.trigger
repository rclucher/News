/*	---------------------------------------------------------
	Author: Tim Fabros
	Company: Bluewolf
	Description: Enhancement from SFE-484
				1. assigns the primary campaign influence on the opportunity record.
	History:

	---------------------------------------------------------	*/
trigger CampaignInfluenceManagement on Campaign_Influence__c (before insert, before update) {
	if (trigger.isBefore)
	{
		Map<Id,Id> campaignIdByOpportunityId = new Map<Id,Id>();

		for (Campaign_Influence__c campaignInfluence : trigger.new)
		{
			if (campaignInfluence.Is_Primary_Campaign__c)
			{
				campaignIdByOpportunityId.put(campaignInfluence.Opportunity__c, campaignInfluence.Campaign__c);
			}
		}

		// set the primary influence and clear previously set primary influences.
		CampaignInfluenceManagement_Helper.setPrimaryInfluence(campaignIdByOpportunityId);
	}
}
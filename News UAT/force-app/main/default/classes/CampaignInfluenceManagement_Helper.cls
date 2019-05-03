/*  ---------------------------------------------------------
    Author: Tim Fabros
    Company: Bluewolf
    Description: Helper class for CampaignInfluenceManagement Trigger.
                Enhancement from SFE-484
    History:

    ---------------------------------------------------------   */
public with sharing class CampaignInfluenceManagement_Helper {
    public static void setPrimaryInfluence(Map<Id,Id> campaignIdByOpportunityId)
    {
        List<Campaign_Influence__c> campaignInfluences = new List<Campaign_Influence__c>();

        for (Campaign_Influence__c campaignInfluence : [SELECT Opportunity__c, Campaign__c, Is_Primary_Campaign__c FROM Campaign_Influence__c WHERE Is_Primary_Campaign__c = true])
        {
            if (campaignIdByOpportunityId.containsKey(campaignInfluence.Opportunity__c))
            {
                campaignInfluence.Is_Primary_Campaign__c = false;
                campaignInfluences.add(campaignInfluence);
            }
        }

        List<Opportunity> opportunities = new List<Opportunity>();

        for (Opportunity opportunity : [SELECT CampaignId FROM Opportunity WHERE Id IN: campaignIdByOpportunityId.keySet()])
        {
            if (campaignIdByOpportunityId.containsKey(opportunity.Id))
            {
                opportunity.CampaignId = campaignIdByOpportunityId.get(opportunity.Id);
                opportunities.add(opportunity);
            }
        }

        if (opportunities.size() > 0)
            update opportunities;

        if (campaignInfluences.size() > 0)
            update campaignInfluences;
    }
}
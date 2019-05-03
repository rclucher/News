public without sharing class LeadManagement_Helper {

	public static void updateRelatedCampaignResponsesWithConvertedContact(set<Lead> leads)
	{
		map<Id,Id> contactIdByLeadId = new map<Id,Id>();

		for(Lead l : leads)
		{	//Just to be sure the leads passed as parameneter has been converted
			if(l.IsConverted && l.ConvertedContactId!=null)
			{
				contactIdByLeadId.put(l.id, l.ConvertedContactId);
			}
		}


		list<Campaign_Response__c> campaignResponsesToUpdate = new list<Campaign_Response__c>();
		for(Campaign_Response__c cr : [Select cr.Lead__c, cr.Contact__c From Campaign_Response__c cr Where cr.Lead__c IN : contactIdByLeadId.keySet()])
		{
			if(contactIdByLeadId.containsKey(cr.Lead__c))
			{
				cr.Contact__c = contactIdByLeadId.get(cr.Lead__c);
				campaignResponsesToUpdate.add(cr);
			}
		}

		if(campaignResponsesToUpdate.size()>0)
		{
			update campaignResponsesToUpdate;
		}

	}


}
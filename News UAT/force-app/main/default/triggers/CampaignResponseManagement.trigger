// Created by Tim Fabros 13 / 08 / 2014
// TODO: create helper class and functions.
trigger CampaignResponseManagement on Campaign_Response__c (before insert, before update) {
	System.debug('@CampaignResponseManagement');
	Map<Id, Id> contactIdByCampaignResponseId = new Map<Id, Id>();
	//Map<Id, Id> campaignMemberIdByCampaignResponseId = new Map<Id, Id>();

	for (Campaign_Response__c campaignResponse : trigger.new)
	{
		contactIdByCampaignResponseId.put(campaignResponse.Id, campaignResponse.Contact__c);
		//campaignMemberIdByCampaignResponseId.put(campaignResponse.Id, campaignResponse.Campaign_Member_Id__c);
	}

	//List<CampaignMember> campaignMembers = [SELECT CreatedDate FROM CampaignMember WHERE Id IN: campaignMemberIdByCampaignResponseId.values()];
	List<Contact> contacts = [SELECT AccountId FROM Contact WHERE Id IN: contactIdByCampaignResponseId.values()];

	System.debug('@CampaignResponseManagement contacts: ' + contacts);

	for (Contact contact : contacts)
	{
		for (Campaign_Response__c campaignResponse : trigger.new)
		{
			if (contactIdByCampaignResponseId.get(campaignResponse.Id) == contact.Id)
			{
				System.debug('@CampaignResponseManagement contact.AccountId: ' + contact.AccountId);
				campaignResponse.Account__c = contact.AccountId;
			}
		}
	}

	/*
	for (CampaignMember campaignMember : campaignMembers)
	{
		for (Campaign_Response__c campaignResponse : trigger.new)
		{
			if (campaignMemberIdByCampaignResponseId.get(campaignResponse.Id) == campaignMember.Id)
			{
				System.debug('@CampaignResponseManagement campaignMember.CreatedDate: ' + campaignMember.CreatedDate);
				campaignResponse.Campaign_Member_First_Associated_Date__c = campaignMember.CreatedDate;
			}
		}
	}*/
}
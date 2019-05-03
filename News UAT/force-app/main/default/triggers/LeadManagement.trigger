trigger LeadManagement on Lead (after update) {
if (Global_Helper.canTrigger( 'LeadManagement' ) ){
    if(trigger.isAfter && trigger.isUpdate)
    {
    	set<lead> convertedLeads = new set<lead>();
		for(Lead l:System.Trigger.new) {
		  if (l.IsConverted)
		  {
		  		convertedLeads.add(l);
		  }
		}

		if(convertedLeads.size()>0)
		{
			LeadManagement_Helper.updateRelatedCampaignResponsesWithConvertedContact(convertedLeads);
		}

	}
}
}
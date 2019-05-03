@isTest
private class LeadManagement_Helper_Test 
{
    static testMethod void updateCampaignResponsesTest() 
    {
    	// create accounts
    	List<Account> accts = TestDataFactory.createAccounts(1, false);
    	insert accts;
    	
    	// create contacts
    	List<Contact> contacts = TestDataFactory.createContacts(1, accts[0]);
    	insert contacts;
    	
    	// create leads
    	List<Lead> leads = TestDataFactory.createLeads(1);
    	insert leads;
    	
    	// bind contact and lead together
    	

    	// create campaigns
    	List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
    	insert campaigns;
    	
    	system.debug('@campaigns: ' + campaigns.size());
    	
    	// create campaign members
    	List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(1, leads, campaigns[0]);
    	insert campaignMembers;
    	
    	system.debug('@campaignMembers: ' + campaignMembers.size());
    	
    	// create campaign responses
    	List<Campaign_Response__c> campaignResps = TestDataFactory.createCampaignResponses(1, campaignMembers);
    	
    	
    	system.debug('@leads: ' + leads.size());
    	system.debug('@campaignResps: ' + campaignResps.size());
    	
    	// add lead into campaign responses
    	Integer i = 0;
    	for(Campaign_Response__c cr : campaignResps)
    	{
    		cr.Lead__c = leads[i].Id;
    		cr.Contact__c = null;
    		i++; 
    	}
    	
    	insert campaignResps;
    	
    	// convert leads to contacts
        List<Database.LeadConvert> lcs = new List<Database.LeadConvert>();
        
        i = 0;
        for(Lead l : leads)
        {
            Database.LeadConvert lc = new database.LeadConvert();
            lc.setLeadId(l.id);
            lc.setOwnerId(UserInfo.getUserId());
            lc.setConvertedStatus('Converted');
            //lc.setConvertedStatus('Qualified');
            lcs.add(lc);
            i++;
        }
        
        List<Database.LeadConvertResult> lcrs = Database.convertLead(lcs);
        
        for(Database.LeadConvertResult lcr : lcrs)
        {
            System.assert(lcr.isSuccess());
        }

    	// verify that contact has been added to campaign responses based on leads' contact
        /*for(Campaign_Response__c cr : campaignResps)
        {
            cr.Lead__c = leads[i].Id;
            cr.Contact__c = null;
            i++; 
        }*/
        
    }
}
//
// 2015-12-09 darshan.gosar@bluewolfgroup.com 
    // This class provides test coverage for
    //  - Campaign_ControllerX_ResultLine    100%
//
@isTest
private class Campaign_ControllerX_ResultLine_Test {
    // This test class no longer needs to test for comparable interface
    // Test converage is achieved through Campaign_ControllerX_Test 76%

    @isTest static void testComparableClass() {
        Campaign campaign = TestDataFactory.createCampaigns(1).get(0);
        insert campaign;

        Account account = TestDataFactory.createAccounts(1,false).get(0);
        insert account;

        List<Contact> contacts = TestDataFactory.createContacts(5,account);
        insert contacts;
        
        // SFE-766 2015-12-09 darshan.gosar@bluewolfgroup.com
            // To cover more test scenarios & condition added Lead Campaign Member related changes
        contacts = [Select Id, Name, AccountId from Contact where Id in :contacts];
        
        List<Lead> leads = TestDataFactory.createLeads(5);       
        insert leads;        

        leads = [Select Id, Name from Lead where Id in :leads];
        
        List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(5,contacts,campaign);
        campaignMembers.addall(TestDataFactory.createCampaignMembers(5,leads,campaign));
        insert campaignMembers;

        campaignMembers = [Select Id, ContactId, LeadId, Contact.Name, Lead.Name, CompanyOrAccount__c from CampaignMember where Id in :campaignMembers];
        
        List<Campaign_ControllerX_ResultLine> testResults = new List<Campaign_ControllerX_ResultLine>();
        Campaign_ControllerX_ResultLine result;
        Campaign_ControllerX_ResultLine result2 = new Campaign_ControllerX_ResultLine();
        Integer i = 0;
        for (CampaignMember member : campaignMembers)
        {
            result = new Campaign_ControllerX_ResultLine(member);
            //result.cm = member;
            //result.fullName = 'ABC' + i;
            result.lastResponseDate = string.valueOf(System.today());
            testResults.add(result);
            i++; 
        }        
        //testResults.sort();
        i = 0;
        for (Campaign_ControllerX_ResultLine rt : testResults){
            System.assertEquals(rt.cm, campaignMembers[i], 'CampaignMemeber didnt set corerctly');
            if(i< 5){
                System.assertEquals(rt.fullName, contacts[i].Name, 'Contact Name didnt set correctly');
                System.assertEquals(rt.recordId , contacts[i].Id, 'Contact Id didnt set correctly');
            }
            else{
                System.assertEquals(rt.fullName, leads[i-5].Name, 'Lead Name didnt set correctly');
                System.assertEquals(rt.recordId , leads[i-5].Id, 'Lead Id didnt set correctly');
            }
            i++;
        }
    }
}
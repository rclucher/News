@isTest
private class CampaignExecutionControllerTest {
    
    static testMethod void testCampaignExecutionController() {
        
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        campaigns[0].Publication_Division__c = 'NWN;NMG;HWT';
        insert campaigns;
        
        List<Contact> contacts = new List<Contact>();
        List<Contact> contacts1 = TestDataFactory.createContacts(40, accounts[0]);
        List<Contact> contacts2 = TestDataFactory.createContacts(40, accounts[1]);
        contacts.addAll(contacts1);
        contacts.addAll(contacts2);
        insert contacts;
        
        
        list<CampaignMember> campaignMembers =  TestDataFactory.createCampaignMembers(contacts.size(), contacts, campaigns[0]);
        for(CampaignMember objCampaignMember : campaignMembers){
          objCampaignMember.DNC_Override__c=true;
        }
        insert campaignMembers;
        
        //insert TestDataFactory.createCampaignResponses(1,campaignMembers);

        list<Lead> leads = TestDataFactory.createLeads(1);
        insert leads;
        
        
        list<CampaignMember> campaignMembers2 =  TestDataFactory.createCampaignMembers(1, leads, campaigns[0]);
        insert campaignMembers2;
        
        //insert TestDataFactory.createCampaignResponses(1,campaignMembers2);
        
        
        Test.startTest();
        
        Campaign objCampaign = CampaignExecutionController.getCampaign(campaigns[0].Id);
        Id currentUderId = CampaignExecutionController.getCurrentUserId();
        CampaignExecutionSearchWrapper objCampaignExecutionSearchWrapper = CampaignExecutionController.resetCampaignExecutionSearchWrapper();
        List<SelectOptionWrapper> lstStatus = CampaignExecutionController.getStatus();
        List<SelectOptionWrapper> lstExecutionStatus = CampaignExecutionController.getExecutionStatus();
        List<SelectOptionWrapper> lstCampaignMemberClassification = CampaignExecutionController.getCampaignMemberClassification();
        Map<String, List<CampaignMember>> mapSearchResults = CampaignExecutionController.getSearchResults(campaigns[0], JSON.serialize(objCampaignExecutionSearchWrapper), '-','-');
        //CampaignExecutionController.getCampaign(campaigns[0].Id);

        List<String> lstFilterOptions  = new List<String>();
        lstFilterOptions.add('equals');
    lstFilterOptions.add('not equals to');
    lstFilterOptions.add('less than');
    lstFilterOptions.add('greater than');
    lstFilterOptions.add('less or equal');
    lstFilterOptions.add('greater or equal');

    for(String objFilterOption : lstFilterOptions){
      objCampaignExecutionSearchWrapper.searchLead_Contact_Name= 'test';
      objCampaignExecutionSearchWrapper.searchCompanyOrAccount= 'test';
      objCampaignExecutionSearchWrapper.searchExecution_Status= 'Not Started';
      objCampaignExecutionSearchWrapper.searchLast_Booking_Line_Item_Publication_Divs= 'NWN';
      objCampaignExecutionSearchWrapper.searchStatus= '1';
      objCampaignExecutionSearchWrapper.filterCall_Count= objFilterOption;
      objCampaignExecutionSearchWrapper.searchCall_Count= '1';
      objCampaignExecutionSearchWrapper.filterAge_In_List= objFilterOption;
      objCampaignExecutionSearchWrapper.searchAge_In_List= '1';
      objCampaignExecutionSearchWrapper.filterLast_Booking_Value= objFilterOption;
      objCampaignExecutionSearchWrapper.searchLast_Booking_Value= '3'; 
      objCampaignExecutionSearchWrapper.filterResponse_DateTime= objFilterOption;
      objCampaignExecutionSearchWrapper.filterCall_Back_Date= objFilterOption;
      objCampaignExecutionSearchWrapper.searchResponse_DateTime= system.today();
      objCampaignExecutionSearchWrapper.searchCall_Back_Date= system.today();
      objCampaignExecutionSearchWrapper.includeFilterOptions = true;

      mapSearchResults = CampaignExecutionController.getSearchResults(campaigns[0], JSON.serialize(objCampaignExecutionSearchWrapper), '','');
    }

        Test.stopTest();
    }
}
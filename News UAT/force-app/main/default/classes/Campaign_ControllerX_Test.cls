@isTest
private class Campaign_ControllerX_Test {
    // This class covers the test coverage for the following classes
    //      - Campaign_ControllerX              95%
    //      - Campaign_sObjectPaginator         100%
    //      - Campaign_ControllerX_ResultLine   76%

    // 25/05/2017  Darshan Gosar Updated - AdSales 272
    //      - Campaign_ControllerX              85%
    //      - Campaign_sObjectPaginator         100%
    @isTest static void test_method_one() {
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        for (Campaign campaign : campaigns)
        {
            campaign.Allow_DNC_Calls__c = true;
            campaign.Default_Sort_Field_for_Campaign_Exec__c = 'Age In List';
            campaign.Default_Sort_Order_for_Campaign_Exec__c = 'DESC';
        }
        insert campaigns;
        
        List<Contact> contacts = TestDataFactory.createContacts(300, accounts[0]);
        insert contacts;
        
        List<Lead> leads = TestDataFactory.createLeads(5);
        insert leads;
        //List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(Integer numOfCampaignMembers, List<Lead> leads, Campaign campaign)
        
        
        
        List<CampaignMember> campaignMembers = TestDataFactory.createCampaignMembers(contacts.size(), contacts, campaigns[0]);
        campaignMembers.addAll(TestDataFactory.createCampaignMembers(leads.size(), leads, campaigns[0]));
        insert campaignMembers;
        
        insert TestDataFactory.createCampaignResponses(2,campaignMembers);
        
        Test.startTest(); 
        
        PageReference pageRef = Page.Campaign;        
        ApexPages.StandardController stdController = new ApexPages.StandardController(campaigns[0]);       
        Campaign_ControllerX controller = new Campaign_ControllerX(stdController);
        Test.setCurrentPage(pageRef);
        
        // modified by Tim Fabros 20 / 06 / 2014 - SFE-533
        // modified by Tim Fabros 16 / 07 / 2014 - SFE-315
        // was List<CampaignMember>; now List<Campaign_ControllerX_ResultLine>
        // BEGIN:
        controller.getTodoCampaignMemberList();
        
        controller.getMyCampaignMemberList();
        
        controller.getAllTodoCampaignMemberList();
        
        controller.getMyDoneCampaignMemberList();
        
        controller.getDoneCampaignMemberList();
        
        controller.getNotStartedCampaignMemberList();
        
        controller.getAllCampaignMemberList();
        // END:
        
        String testString = controller.campaignIdPrefix;
        
        controller.refresh();
        controller.refreshCampaignMembers();
        
        controller.gettheController();
        
        // improve the test coverage for Campaign_sObjectPaginator (inner class is now promoted to top class)
        Campaign_sObjectPaginator todo = controller.todoCampaignMemberPaginator;
        
        todo.getHasPrevious();
        todo.getHasNext();
        todo.Next();
        todo.Previous();
        
        pageRef.getParameters().put('tabName', 'todo');
        todo.sortField = 'fullname';
        todo.sortDir = 'ASC';
        controller.toggleSort();
        
        todo.sortField = 'fullname';
        todo.sortDir = 'DESC';
        controller.toggleSort();
        
        todo.sortField = 'companyOrAccount';
        todo.sortDir = 'ASC';
        controller.toggleSort();
        
        todo.sortField = 'lockedBy';
        todo.sortDir = 'ASC';
        controller.toggleSort();
        
        todo.sortField = 'status';
        todo.sortDir = 'ASC';
        controller.toggleSort();
        
        todo.sortField = 'executionStatus';
        todo.sortDir = 'ASC';
        controller.toggleSort();
        
        todo.sortField = 'callBackDate';
        todo.sortDir = 'ASC';
        controller.toggleSort();
        
        todo.sortField = 'lastBookingValue';
        todo.sortDir = 'ASC';
        controller.toggleSort();
        
        todo.sortField = 'lastBookingLineItemPublicationDivs';
        todo.sortDir = 'ASC';
        controller.toggleSort();
        
        pageRef.getParameters().put('tabName', 'done');
        controller.toggleSort();
        
        pageRef.getParameters().put('tabName', 'myDone');
        controller.toggleSort();
        
        pageRef.getParameters().put('tabName', 'allTodo');
        controller.toggleSort();
        
        pageRef.getParameters().put('tabName', 'my');
        controller.toggleSort();
        
        pageRef.getParameters().put('tabName', 'notStarted');
        controller.toggleSort();
        
        pageRef.getParameters().put('tabName', 'all');
        controller.toggleSort();
        
        
        controller.refreshPostMemberResponse();
        controller.refresh_withTabName('todo');
        controller.refresh_withTabName('done');
        controller.refresh_withTabName('myDone');
        controller.refresh_withTabName('allTodo');
        controller.refresh_withTabName('my');
        controller.refresh_withTabName('notStarted');
        controller.refresh_withTabName('all');
        
        controller.hasUserSearchInput=true;
        controller.activeTab ='all';
        
        controller.searchLead_Contact_Name = null;
        controller.searchPre_Completion_Status ='Test';
        controller.searchCall_Count = '0';
        controller.searchExecution_Status = null;        
        controller.searchCampaign_Membership_Count = '2';
        
        controller.searchLastPublicationDivision = 'ABC';
        controller.searchStatus ='Test';
        controller.searchResponseDateTime = system.today().addDays(-2);
        controller.searchCallBackDate = system.today();
		controller.tempCampaignMember.Contact_Plan_Date__c = system.today().addDays(-2);
        controller.tempCampaignMember1.Contact_Plan_Date__c = system.today();         
        controller.searchLastBookingValue = '4';
        
        controller.filterCallCount = 'equals';
        controller.filterAgeInLast ='not equals';
        controller.filterLastBookingValue = 'greater than';
        controller.filterResponseDateTime = 'less than';
        controller.filterCallBackDate = 'greater or equal';        
        controller.search();
        
        controller.resetSearch();
        controller.resetSort();
        
        controller.getExecutionStatus();
        controller.getFilterOption();
        controller.getStatus();
        
        Test.stopTest();
        
    }
    
}
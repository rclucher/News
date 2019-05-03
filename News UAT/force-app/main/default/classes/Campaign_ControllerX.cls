/**
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: this controller is used by custom button 'Campaing Execution' on Campaign detail page. Requirement R-0630.
 * BC: 18/07/2014: The latest update is to fix exceeded view state limit issue. In order to solve this issue, we have to limit
 *                 number of records returned back to browser by only showing those records on current page in current tab. 
 *                 When user switch between different tabs or go to different pages, 
 * History:
 * 02/07/2013  Bohao Chen  Created
 * 11/07/2013  Bohao Chen  Updated
 * 26/07/2013  Bohao Chen  Updated
 * 23/10/2013  Celso de Souza Updated
 * 18/07/2014  Bohao Chen  Updated
 * 28/04/2015  Louis Wang Updated - UserStory16.3
 * 02/09/2016  Darshan Gosar Updated - AdSales 113
 * 21/05/2017  Darshan Gosar Updated - AdSales 272
 */
public with sharing class Campaign_ControllerX 
{
    private List<String> todoCampainMemberListStatuses  =  new String[]{'', 'Not Started', 'Attempted', 'Call to Do', 'Call Limit Reached'};
    private List<String> notStartedCampainMemberListStatuses  =  new String[]{'', 'Not Started'};    
    private List<String> myCampainMemberListStatuses  =  new String[]{'Call to Do'};
    private List<String> allTodoCampainMemberListStatuses  =  new String[]{'Call to Do'};
    private List<String> doneCampainMemberListStatuses  =  new String[]{'Completed'};
    
    // modified by Bohao Chen 15 / 07 / 2014 - SFE-315    
    // BEGIN:
    // list of records for current page for all tabs
    public transient List<CampaignMember> todoCampaignMemberCurrentList {get; private set;}
    public transient List<CampaignMember> notStartedCampaignMemberCurrentList {get; private set;}
    public transient List<CampaignMember> myCampaignMemberCurrentList {get; private set;}
    public transient List<CampaignMember> allTodoCampaignMemberCurrentList {get; private set;}
    public transient List<CampaignMember> myDoneCampaignMemberCurrentList {get; private set;}
    public transient List<CampaignMember> doneCampaignMemberCurrentList {get; private set;}
    public transient List<CampaignMember> allCampaignMemberCurrentList {get; private set;}
    // END:

    /* 02-09-2016 AdSales 113 darshan.gosar@bluewolfgroup.com
        Previous implementation was binding this search text with campaign member fields & few fields were not given write access to few of the profiles
        hence in UAT found that we can not perform search based on this field hence removed reference of campaignmember field & binded it
        with simple text fields as given below & performing search using text fields  */
    
    public String searchLead_Contact_Name {get; set;}
    public String searchPre_Completion_Status {get; set;}
    public String searchCall_Count {get; set;}    
    public String searchExecution_Status {get; set;}    
    public String searchCampaign_Membership_Count {get; set;}    

    /* 21-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
        Added new search & filter variables based on requirements  */
    
    public String searchLastBookingValue {get; set;}
    public String searchLastPublicationDivision {get; set;}
    public String searchStatus {get; set;}    
    public Date searchResponseDateTime {get; set;}    
    public Date searchCallBackDate {get; set;} 

    /* 21-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
        CampaignMember instance are display search date fields on UI in dd/mm/yyyy format & parse to controller */    
    public CampaignMember tempCampaignMember {get; set;}
    public CampaignMember tempCampaignMember1 {get; set;}
    
    public String filterCallCount {get; set;}
    public String filterAgeInLast {get; set;}
    public String filterLastBookingValue {get; set;}    
    public String filterResponseDateTime {get; set;}    
    public String filterCallBackDate {get; set;}
        
    /* 21-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
        Added to populate filter options  */
    
    public List<SelectOption> getFilterOption()
    {
        List<SelectOption> options = new List<SelectOption>();            
        options.add(new SelectOption('equals', 'equals'));
        options.add(new SelectOption('not equals to', 'not equals to'));
        options.add(new SelectOption('less than', 'less than'));
        options.add(new SelectOption('greater than', 'greater than'));
        options.add(new SelectOption('less or equal', 'less or equal'));
        options.add(new SelectOption('greater or equal', 'greater or equal'));                                               
        return options; 
    }

    /* 21-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
        Added to get picklist values for Status field  */    
    public List<SelectOption> getStatus()
    {
       List<SelectOption> options = new List<SelectOption>();
            
       Schema.DescribeFieldResult fieldResult =  CampaignMember.Status.getDescribe();
       List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
       options.add(new SelectOption('None', 'None'));
                   
       for( Schema.PicklistEntry f : ple)
       {
          options.add(new SelectOption(f.getLabel(), f.getValue()));
       }       
       return options;
    }
    
    public List<SelectOption> getExecutionStatus()
    {
       List<SelectOption> options = new List<SelectOption>();
            
       Schema.DescribeFieldResult fieldResult =  CampaignMember.Execution_Status__c.getDescribe();
       List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
       options.add(new SelectOption('None', 'None'));
                   
       for( Schema.PicklistEntry f : ple)
       {
          options.add(new SelectOption(f.getLabel(), f.getValue()));
       }       
       return options;
    }
        
    public String campaignIdPrefix 
    {   
        get
        {
            if(campaignIdPrefix == null)
            {
                campaignIdPrefix = CampaignMember.SObjectType.getDescribe().getKeyPrefix();
            }
            return campaignIdPrefix;
        }
        set;
    }


    public Campaign_ControllerX gettheController()
    {
        // this method passes the VF Page controller to VF Component
        return this; 
    }

    public Campaign campaign {get;set;}
    
    public Boolean hasProgressCampaignMemberInTodo {get; private set;}
    public Boolean hasProgressCampaignMemberInDone {get; private set;}
    public Boolean hasProgressCampaignMemberInAll  {get; private set;}
    public String hideColumns {get; private set;}

    private Id campaignId;
    private String s;
    
    public String activeTab {get; set;}

    public Boolean hasUserSearchInput{get; set;}
    public Campaign_ControllerX(ApexPages.StandardController controller) 
    {
        if(!test.isRunningTest())
        {
            controller.addFields(new String[]{'Type', 
                                                'NEWS_Campaign_Type__c',
                                                'NEWS_Campaign_Type__c', 
                                                'Hide_Column_from_Campaign_Exec__c',
                                                'Default_Sort_Field_for_Campaign_Exec__c',
                                                'Default_Sort_Order_for_Campaign_Exec__c',
                                                'Allow_DNC_Calls__c'});
        }
        
        tempCampaignMember = new CampaignMember();
        tempCampaignMember1 = new CampaignMember();
        resetSearchInputs();
        hasUserSearchInput = false;
        campaign = (Campaign)controller.getRecord();
        campaignId = campaign.Id;
        // determine which column to hide
        hideColumns = campaign.Hide_Column_from_Campaign_Exec__c;
        this.resetHasProgressCampaignMember();
    }

    private Map<String, String> defaultSortFieldMap 
    {
        get
        {
            if(defaultSortFieldMap==null)
            {
                defaultSortFieldMap = new Map<String, String>();
                defaultSortFieldMap.put('Name', 'fullName');
                defaultSortFieldMap.put('Last Booking Value', 'lastBookingValue');
                /* 21-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com Added sorting logic for Last Booking Line Item Publication Divs field which got added as part of Adsales 272*/
                defaultSortFieldMap.put('Last Booking Line Item Publication Divs', 'lastBookingLineItemPublicationDivs');
                defaultSortFieldMap.put('CompanyOrAccount', 'companyOrAccount');
                defaultSortFieldMap.put('Execution Status', 'executionStatus');
                defaultSortFieldMap.put('Status', 'status');
                defaultSortFieldMap.put('Call Back Date', 'callBackDate');
                defaultSortFieldMap.put('Locked By', 'lockedBy');
                defaultSortFieldMap.put('Age in List', 'ageInList');
            }
            return defaultSortFieldMap;
        }
        private set;
    }

    private Map<String, String> defaultSortOrderMap 
    {
        get
        {
            if(defaultSortOrderMap==null)
            {
                defaultSortOrderMap = new Map<String, String>();
                defaultSortOrderMap.put('Ascending', 'ASC');
                defaultSortOrderMap.put('Descending', 'DESC');
            }
            return defaultSortOrderMap;
        }
        private set;
    }

    private void resetHasProgressCampaignMember()
    {
        hasProgressCampaignMemberInTodo = false;
        hasProgressCampaignMemberInDone = false;
        hasProgressCampaignMemberInAll = false;
    }    

    public Campaign_sObjectPaginator todoCampaignMemberPaginator {
        get
        {
            //system.debug('@ todoCampaignMemberPaginator() get');
            if(todoCampaignMemberPaginator==null)
            {
                todoCampaignMemberPaginator = new Campaign_sObjectPaginator();
                todoCampaignMemberPaginator.sortField = defaultSortField;
                todoCampaignMemberPaginator.sortDir = defaultSortOrder;
            }   
            return todoCampaignMemberPaginator;
        }
        private set;
    }
    public PageReference search()
    {
        hasUserSearchInput = true;
        refresh_withTabName(activeTab);
        return null;
    }
    public PageReference resetSearch()
    {
        resetSearchInputs();
        hasUserSearchInput = false;        
        refresh_withTabName(activeTab);
        return null;
    }
    public PageReference getTodoCampaignMemberList()
    {
        // update activeTab value so rerender tabpanel does not go back to 1st tab
        activeTab = 'todoTab';
        this.resetAllCampaignMemberList();
        //system.debug('@ getTodoCampaignMemberList()');
        todoCampaignMemberCurrentList = (List<CampaignMember>)todoCampaignMemberPaginator.getRecords(
                this.getQueryString(todoCampainMemberListStatuses, 
                                    'todoTab', 
                                    todoCampaignMemberPaginator.sortField,
                                    todoCampaignMemberPaginator.sortDir));
        return null;
    }

    public void resetSearchInputs(){
        searchLead_Contact_Name = null;
        searchPre_Completion_Status  = null;
        searchCall_Count = null;
        searchExecution_Status = null;
        searchCampaign_Membership_Count  = null;
        /* 21-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com Added reseting new variables which got added as part of Adsales 272 */
        searchLastBookingValue = null;
        searchLastPublicationDivision = null;
        searchStatus = null;
        searchResponseDateTime = null;
        searchCallBackDate = null;    
        filterCallCount = null;
        filterAgeInLast = null;
        filterLastBookingValue = null;
        filterResponseDateTime = null;    
        filterCallBackDate = null;
        tempCampaignMember.Contact_Plan_Date__c = null;
        tempCampaignMember1.Contact_Plan_Date__c = null;
    }
    
    // My Call to do
    public Campaign_sObjectPaginator myCampaignMemberPaginator {
        get
        {
            //system.debug('@ myCampaignMemberPaginator() get');
            if(myCampaignMemberPaginator==null)
            {
                myCampaignMemberPaginator = new Campaign_sObjectPaginator();
                myCampaignMemberPaginator.sortField = defaultSortField;
                myCampaignMemberPaginator.sortDir = defaultSortOrder;                
            }
            return myCampaignMemberPaginator;
        }
        private set;
    }
    public PageReference getMyCampaignMemberList()
    {
        // update activeTab value so rerender tabpanel does not go back to 1st tab
        activeTab = 'myTab';        
        this.resetAllCampaignMemberList();
        //system.debug('@ getMyCampaignMemberList()');
        myCampaignMemberCurrentList = (List<CampaignMember>) myCampaignMemberPaginator.getRecords(
                this.getQueryString(myCampainMemberListStatuses, 
                                    'myTab',
                                    notStartedCampaignMemberPaginator.sortField,
                                    notStartedCampaignMemberPaginator.sortDir));
        return null;
    }

    // All to Do
    public Campaign_sObjectPaginator allTodoCampaignMemberPaginator {
        get
        {
            //system.debug('@ allTodoCampaignMemberPaginator() get');
            if(allTodoCampaignMemberPaginator==null)
            {
                allTodoCampaignMemberPaginator = new Campaign_sObjectPaginator();
                allTodoCampaignMemberPaginator.sortField = defaultSortField;
                allTodoCampaignMemberPaginator.sortDir = defaultSortOrder;                                
            }
            return allTodoCampaignMemberPaginator;
        }
        private set;
    }
    public PageReference getAllTodoCampaignMemberList()
    {
        // update activeTab value so rerender tabpanel does not go back to 1st tab
        activeTab = 'allTodoTab';                
        this.resetAllCampaignMemberList();
        //system.debug('@ getAllTodoCampaignMemberList()');
        allTodoCampaignMemberCurrentList = (List<CampaignMember>) allTodoCampaignMemberPaginator.getRecords(
            this.getQueryString(allTodoCampainMemberListStatuses, 
                                'alltodoTab',
                                allTodoCampaignMemberPaginator.sortField,
                                allTodoCampaignMemberPaginator.sortDir));
        return null;
    }

    // My Done
    public Campaign_sObjectPaginator myDoneCampaignMemberPaginator {
        get
        {
            //system.debug('@ myDoneCampaignMemberPaginator() get');
            if(myDoneCampaignMemberPaginator==null)
            {
                myDoneCampaignMemberPaginator = new Campaign_sObjectPaginator();
                myDoneCampaignMemberPaginator.sortField = defaultSortField;
                myDoneCampaignMemberPaginator.sortDir = defaultSortOrder;                                                
            }
            return myDoneCampaignMemberPaginator;
        }
        private set;
    }    
    public PageReference getMyDoneCampaignMemberList()
    {
        // update activeTab value so rerender tabpanel does not go back to 1st tab
        activeTab = 'myDoneTab';                        
        this.resetAllCampaignMemberList();
        //system.debug('@ getMyDoneCampaignMemberList()');
        myDoneCampaignMemberCurrentList = (List<CampaignMember>) myDoneCampaignMemberPaginator.getRecords(
                this.getQueryString(doneCampainMemberListStatuses, 
                                    'myDoneTab',
                                    myDoneCampaignMemberPaginator.sortField,
                                    myDoneCampaignMemberPaginator.sortDir));
        return null;
    }

    //Done
    public Campaign_sObjectPaginator doneCampaignMemberPaginator {
        get
        {
            //system.debug('@ doneCampaignMemberPaginator() get');
            if(doneCampaignMemberPaginator==null)
            {
                doneCampaignMemberPaginator = new Campaign_sObjectPaginator();
                doneCampaignMemberPaginator.sortField = defaultSortField;
                doneCampaignMemberPaginator.sortDir = defaultSortOrder;                                                                
            }
            return doneCampaignMemberPaginator;
        }
        private set;
    }
    public PageReference getDoneCampaignMemberList()
    {
        // update activeTab value so rerender tabpanel does not go back to 1st tab
        activeTab = 'doneTab';
        this.resetAllCampaignMemberList();
        //system.debug('@ getDoneCampaignMemberList()');
        doneCampaignMemberCurrentList = (List<CampaignMember>) doneCampaignMemberPaginator.getRecords(
                this.getQueryString(doneCampainMemberListStatuses, 
                                    'doneTab',
                                    doneCampaignMemberPaginator.sortField,
                                    doneCampaignMemberPaginator.sortDir));
        return null;
    }

    //Not Started
    public Campaign_sObjectPaginator notStartedCampaignMemberPaginator {
        get
        {
            //system.debug('@ notStartedCampaignMemberPaginator() get');
            if(notStartedCampaignMemberPaginator==null)
            {
                notStartedCampaignMemberPaginator = new Campaign_sObjectPaginator();
                notStartedCampaignMemberPaginator.sortField = defaultSortField;
                notStartedCampaignMemberPaginator.sortDir = defaultSortOrder;                
            }
            return notStartedCampaignMemberPaginator;
        }
        private set;
    }          
    public PageReference getNotStartedCampaignMemberList()
    {
        // update activeTab value so rerender tabpanel does not go back to 1st tab
        activeTab = 'notStartedTab';        
        this.resetAllCampaignMemberList();
        //system.debug('@ getNotStartedCampaignMemberList()');
        notStartedCampaignMemberCurrentList = (List<CampaignMember>) notStartedCampaignMemberPaginator.getRecords(
                this.getQueryString(notStartedCampainMemberListStatuses, 
                                    'notStartedTab',
                                    notStartedCampaignMemberPaginator.sortField,
                                    notStartedCampaignMemberPaginator.sortDir));
        return null;
    }

    //All
    public Campaign_sObjectPaginator allCampaignMemberPaginator {
        get
        {
            //system.debug('@ allCampaignMemberPaginator() get');
            if(allCampaignMemberPaginator==null)
            {
                allCampaignMemberPaginator = new Campaign_sObjectPaginator();
                allCampaignMemberPaginator.sortField = defaultSortField;
                allCampaignMemberPaginator.sortDir = defaultSortOrder;                
            }
            return allCampaignMemberPaginator;
        }
        private set;
    }  
    public PageReference getAllCampaignMemberList()
    {
        // update activeTab value so rerender tabpanel does not go back to 1st tab
        activeTab = 'allTab';                
        this.resetAllCampaignMemberList();
        //system.debug('@ getAllCampaignMemberList()');
        allCampaignMemberCurrentList = (List<CampaignMember>) allCampaignMemberPaginator.getRecords(
                this.getQueryString(null, 
                                    null, 
                                    allCampaignMemberPaginator.sortField, 
                                    allCampaignMemberPaginator.sortDir));
        return null;
    }

    private Map<String, String> tabNameConversionMap
    {
        get
        {
            if(tabNameConversionMap==null)
            {
                tabNameConversionMap = new Map<String, String>();
                tabNameConversionMap.put('todoTab', 'todo');
                tabNameConversionMap.put('doneTab', 'done');
                tabNameConversionMap.put('myDoneTab', 'myDone');
                tabNameConversionMap.put('allTodoTab', 'allTodo');
                tabNameConversionMap.put('myTab', 'my');
                tabNameConversionMap.put('notStartedTab', 'notStarted');
                tabNameConversionMap.put('allTab', 'all');
            }
            return tabNameConversionMap;
        }
        private set;
    }
 
    public PageReference refreshPostMemberResponse()
    {
        // refresh the tab based on activeTab detail.
        if(tabNameConversionMap.containsKey(activeTab))
        {
            string tabName = tabNameConversionMap.get(activeTab);
            refresh_withTabname(tabName);    
        }
        return null;
    }

    // for refresh buttons for each campaign member tables
    public PageReference refresh()
    {
        String tabName = Apexpages.currentPage().getParameters().get('tabName');
        //system.debug('@ refresh() tabName: ' + tabName);
        
        refresh_withTabName(tabName);
        return null;
    }        

    public PageReference refresh_withTabName(String tabName)
    {
        this.resetHasProgressCampaignMember();

        if(tabName == 'todo')
        {
            this.getTodoCampaignMemberList();
        }
        else if(tabName == 'done')
        {
            this.getDoneCampaignMemberList();
        }
        else if(tabName == 'myDone')
        {
            this.getMyDoneCampaignMemberList();
        }
        else if(tabName == 'allTodo')
        {
            this.getAllTodoCampaignMemberList();
        }
        else if(tabName == 'my')
        {
            this.getMyCampaignMemberList();
        }
        else if(tabName == 'notStarted')
        {
            this.getNotStartedCampaignMemberList();
        }        
        else if(tabName == 'all')
        {
            this.getAllCampaignMemberList();
        }        
        return null;
    }


    /* 24-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
        Added new method add filter criteria in query based on filter selection on UI  */
    private string applyFilters(String filterValue, String field, String searchValue){
        String temp = '';        
        
        if(filterValue == 'equals')
            temp = ' And ' + field + ' = ' + searchValue;
        
        if(filterValue == 'not equals to')
            temp = ' And ' + field + ' != ' + searchValue;
        
        if(filterValue == 'less than')
            temp = ' And ' + field + ' < ' + searchValue;
        
        if(filterValue == 'greater than')
            temp = ' And ' + field + ' > ' + searchValue;
        
        if(filterValue == 'less or equal')
            temp = ' And ' + field + ' <= ' + searchValue;
        
        if(filterValue == 'greater or equal')
            temp = ' And ' + field + ' >= ' + searchValue;        
        
        return temp;
    }
    

    /* 24-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
        Added new method add filter criteria in query based on filter selection on UI  */       
    private string applyDateFilters(String filterValue, String field, Date dateValue){
        String temp = '';
        String searchValue = '';        
        
        DateTime d = datetime.newInstance(dateValue, Time.newInstance(0,0,0,0));
        String sameDay = d.formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        String nextDay = d.addDays(1).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        if(filterValue == 'equals')
            temp = ' And ' + field + ' > ' + sameDay + ' And ' + field + ' < ' + nextDay;
        
        if(filterValue == 'not equals to')
            temp = ' And ((' + field + ' < ' + sameDay + ' OR ' + field + ' > ' + nextDay + ') OR ' + field + '=' + 'NULL)';
        
        if(filterValue == 'less than')
            temp = ' And ' + field + ' < ' + sameDay;
        
        if(filterValue == 'greater than')
            temp = ' And ' + field + ' > ' + nextDay;
        
        if(filterValue == 'less or equal')
            temp = ' And ' + field + ' < ' + nextDay;
        
        if(filterValue == 'greater or equal')
            temp = ' And ' + field + ' > ' + sameDay;        
        
        return temp;
    }
    
    // generate query string for different campaign lists according to different statuses
    private List<CampaignMember> getQueryString(List<String> statuses, String tabName, String sortField, String sortDir)
    {
        String queryString = 'Select c.Status, c.Execution_Status__c, c.Response_Type__c, c.Id, c.CreatedDate, c.ContactId, c.LeadId, c.CampaignId, c.Lead.Phone_DNC_Is_Contactable__c, '
                                     + ' c.Contact.Home_Phone_on_DNC__c, c.CompanyOrAccount__c, c.Account__c, c.Locked_By__c, c.Contact.Name, c.Lead.Name, c.Contact.DNC_A_Number_Is_Contactable__c,  c.Lead.DNC_A_Number_Is_Contactable__c, '
                                     + 'c.Campaign.Allow_DNC_Calls__c,In_Progress__c, c.Contact.Mobile_on_DNC__c, c.Account__r.Name, c.Account__r.Id, Completed_by__c, Date_Completed__c,  '
                                     + 'Age_in_List__c, Call_Count__c, Call_Back_Date__c, Response_Datetime__c, Response_Comment__c, Locked_By__r.Name, Last_Booking_Value__c, Last_Booking_Line_Item_Publication_Divs__c, Response_Sub_Type__c, '
                                     + 'Campaign.Hide_Column_from_Campaign_Exec__c, Campaign.Default_Sort_Order_for_Campaign_Exec__c, Campaign.Default_Sort_Field_for_Campaign_Exec__c, Member_Type__c, '
                                     + 'DNC_A_Number_is_Contactable__c '
                                     + 'From CampaignMember c '
                                     + 'Where c.CampaignId =: campaignId';
        
        //if(statuses != null && statuses.size() > 0)
        //{
            if(!campaign.Allow_DNC_Calls__c)
            {
                // 2015-09-22 SFE-680 louis.wang@bluewolf.com
                //  - make CampaignMember contactable, if DNC_Override is ticked at CampaignMember level
                queryString += ' AND (DNC_A_Number_is_Contactable__c=true OR DNC_Override__c=true)'; 
            }   
            
            if(tabName == 'todoTab')
            {
                queryString += ' And c.Execution_Status__c IN: todoCampainMemberListStatuses';
            }
            else if(tabName == 'myTab')
            {
                queryString += ' AND (Locked_By__c = \'' + userInfo.getUserId() + '\')';
            }
            else if(tabName == 'allTodoTab')
            {
                queryString += ' And c.Execution_Status__c IN: allTodoCampainMemberListStatuses';
            }            
            else if(tabName == 'notStartedTab')
            {
                queryString += ' And c.Execution_Status__c IN: notStartedCampainMemberListStatuses AND Locked_By__c = null';
            }           
            else if(tabName == 'myDoneTab')
            {
                queryString += ' And c.Execution_Status__c IN: doneCampainMemberListStatuses AND Completed_by__c =\'' + UserInfo.getUserId() + '\'';
            }
            else if(tabName == 'doneTab')
            {
                queryString += ' And c.Execution_Status__c IN: doneCampainMemberListStatuses';
            }
        //}
        if(hasUserSearchInput){
            
            searchResponseDateTime = tempCampaignMember.Contact_Plan_Date__c;
            searchCallBackDate = tempCampaignMember1.Contact_Plan_Date__c;
            //if(searchCampaignMember.search_contact__c != null)queryString += ' And c.contactId =\''+searchCampaignMember.search_contact__c+'\'';
            //if(searchCampaignMember.Search_Lead__c != null)queryString += ' And c.leadId =\''+searchCampaignMember.Search_Lead__c+'\'';
            if(searchLead_Contact_Name != null && searchLead_Contact_Name != '')
            {
                queryString += ' And ( c.lead.name like \'%'+String.escapeSingleQuotes(searchLead_Contact_Name)+'%\'';
                queryString += ' Or c.contact.name like \'%'+String.escapeSingleQuotes(searchLead_Contact_Name)+'%\')';
            }
            if(searchPre_Completion_Status != null && searchPre_Completion_Status != '')queryString += ' And c.CompanyOrAccount__c like \'%'+String.escapeSingleQuotes(searchPre_Completion_Status)+'%\'';            
            if(searchExecution_Status != null && searchExecution_Status != '' && searchExecution_Status != 'None')queryString += ' And c.Execution_Status__c =\''+searchExecution_Status+'\'';            
            
            
            /* 24-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
                Added new filter criteria in query based on filter selection on UI  */
            if(searchLastPublicationDivision != null && searchLastPublicationDivision != '')queryString += ' And c.Last_Booking_Line_Item_Publication_Divs__c  Like \'%' + String.escapeSingleQuotes(searchLastPublicationDivision) + '%\'';            
            if(searchLastBookingValue != null && searchLastBookingValue != '')queryString += applyFilters(filterLastBookingValue, 'c.Last_Booking_Value__c', searchLastBookingValue);
            if(searchCall_Count != null && searchCall_Count != '')queryString += applyFilters(filterCallCount, 'c.Call_Count__c', searchCall_Count);
            if(searchCampaign_Membership_Count != null && searchCampaign_Membership_Count != '')queryString += applyFilters(filterAgeInLast, 'c.Age_in_List__c', searchCampaign_Membership_Count);            
            if(searchResponseDateTime != null) queryString += applyDateFilters(filterResponseDateTime, 'c.Response_Datetime__c', searchResponseDateTime);            
            if(searchCallBackDate != null) queryString += applyDateFilters(filterCallBackDate, 'c.Call_Back_Date__c', searchCallBackDate);            
        }
        //system.debug('@sortField: ' + sortField);
        //system.debug('@sortDir: ' + sortDir);

        if(String.isNotBlank(sortField) && String.isNotBlank(sortDir))
        {
            if(sortField=='CompanyOrAccount')
            {
                queryString += ' Order By CompanyOrAccount__c ' + sortDir + ', Age_in_List__c ';
            }
            else if(sortField=='fullName')
            {
                queryString += ' Order By Full_Name__c ' + sortDir + ', Age_in_List__c ';
            }
            else if(sortField=='lastBookingValue')
            {
                queryString += ' Order By Last_Booking_Value__c ' + sortDir + ', Age_in_List__c ';
            }
            
            /* 24-05-2019 AdSales 272 darshan.gosar@bluewolfgroup.com
                Added new sort condition for field Last_Booking_Line_Item_Publication_Divs__c  */                
            else if(sortField=='lastBookingLineItemPublicationDivs')
            {
                queryString += ' Order By Last_Booking_Line_Item_Publication_Divs__c ' + sortDir + ', Age_in_List__c ';
            }
            else if(sortField=='executionStatus')
            {
                queryString += ' Order By Execution_Status__c ' + sortDir + ', Age_in_List__c ';
            }
            else if(sortField=='status')
            {
                queryString += ' Order By Status ' + sortDir + ', Age_in_List__c ';
            }
            else if(sortField=='callBackDate')
            {
                queryString += ' Order By Call_Back_Date__c ' + sortDir + ', Age_in_List__c ';
            }
            else if(sortField=='lockedBy')
            {
                queryString += ' Order By Locked_By__r.Name ' + sortDir + ', Age_in_List__c ';
            }
            else if(sortField=='ageInList')
            {
                queryString += ' Order By Age_in_List__c ' + sortDir + ' ';
            }
        }
        else if(campaign.NEWS_Campaign_Type__c == 'Retention' || campaign.NEWS_Campaign_Type__c == 'Contact Plan')
        {
            queryString += ' Order By Age_in_List__c';      
        }
        else
        {
            queryString += ' Order By Status, CompanyOrAccount__c';
        }
        
        queryString += ' LIMIT 1000';

        system.debug('===queryString is === ' + queryString);
      
        
        List<CampaignMember> campaignMembers = (List<CampaignMember>)Database.query(queryString);
          
        // loop through campaign member results
        // if campaign allows do not calls, we don't need to check do not call fields on campaign contact
        // otherwise if campaign don't allow do not calls, we have to check do not call for mobile and home phone on campaign contact
        // either of both allows call, add this campaign member to Campaign Member list
        //List<CampaignMember> campaignMembers = new List<CampaignMember>(); 

        // added by Tim Fabros 10 / 07 / 2014 - SFE-375
        // BEGIN:
        List<String> contactIds = new List<String>();
        List<String> leadIds = new List<String>();
        // END:

        
        system.debug('@getQueryString campaignMembers: ' + campaignMembers);


        Integer lockedByUser = [Select count()
                                From   CampaignMember
                                where  CampaignId =: campaignId
                                AND Locked_By__c =:UserInfo.getUserId()
                                AND Execution_Status__c != 'Call to Do'];

        hasProgressCampaignMemberInTodo = lockedByUser>0;


/*****
        for(CampaignMember cm : campaignMembers)
        {
            system.debug('@getQueryString -------------------------------------------------------------------- ');
            system.debug('@getQueryString cm.Campaign.Allow_DNC_Calls__c: ' + cm.Campaign.Allow_DNC_Calls__c);
            system.debug('@getQueryString cm.ContactId: ' + cm.ContactId);
            system.debug('@getQueryString cm.Contact.DNC_A_Number_Is_Contactable__c: ' + cm.Contact.DNC_A_Number_Is_Contactable__c);
            system.debug('@getQueryString cm.LeadId: ' + cm.LeadId);
            system.debug('@getQueryString cm.Lead.DNC_A_Number_Is_Contactable__c: ' + cm.Lead.DNC_A_Number_Is_Contactable__c);
            system.debug('@getQueryString cm.In_Progress__c: ' + cm.In_Progress__c);
            system.debug('@getQueryString cm.Locked_By__c: ' + cm.Locked_By__c);
            
            
           
                if(cm.In_Progress__c && cm.Locked_By__c == userInfo.getUserId())
                {
                    system.debug('@getQueryString **************** INSIDE 2nd IF');
                        hasProgressCampaignMemberInTodo = true;
                        break;
                }

            system.debug('@getQueryString hasProgressCampaignMemberInTodo: ' + hasProgressCampaignMemberInTodo);

        }
****/
                                                                     
                                                                     
                                                                     
        // added by Tim Fabros 10 / 07 / 2014 - SFE-375
        // assigns the last response date
        // BEGIN:
        // 
         /*
        Map<String,Datetime> lastResponseDateByContactId    = getLastResponseDateContact(contactIds);
        Map<String,Datetime> lastResponseDateByLeadId       = getLastResponseDateLead(leadIds);

        for (CampaignMember ccrl : campaignMembers)
        {
            if (lastResponseDateByContactId.containsKey(ccrl.recordId))
            {
                ccrl.lastResponseDate = lastResponseDateByContactId.get(ccrl.recordId).format();
            }
            else if (lastResponseDateByLeadId.containsKey(ccrl.recordId))
            {
                ccrl.lastResponseDate = lastResponseDateByLeadId.get(ccrl.recordId).format();
            }
        }
*/
        // END:

        return campaignMembers;
    }
  
    // added by Tim Fabros 10 / 07 / 2014 - SFE-375
    // gets the last response date from the related campaign response
    // BEGIN:
    private Map<String,Datetime> getLastResponseDateContact(List<String> contactIds)
    {
        //Datetime latestResponseDate;
        Map<String,Datetime> lastResponseDateByContactId = new Map<String,Datetime>();

        Map<String, List<Campaign_Response__c>> campaignResponseListByContactId = new Map<String, List<Campaign_Response__c>>();

        List<Campaign_Response__c> campaignResponses = [SELECT CreatedDate, Contact__c FROM Campaign_Response__c WHERE Contact__c IN: contactIds AND Campaign__c =: campaignId];

        if (campaignResponses.size() > 0)
        {
            for (Campaign_Response__c cr : campaignResponses)
            {
                if (campaignResponseListByContactId.containsKey(cr.Contact__c))
                    campaignResponseListByContactId.get(cr.Contact__c).add(cr);
                else
                    campaignResponseListByContactId.put(cr.Contact__c, new List<Campaign_Response__c>{cr});
            }
        }

        for (String cid : campaignResponseListByContactId.keySet())
        {
            Datetime latestResponseDate;

            for (Campaign_Response__c cr : campaignResponseListByContactId.get(cid))
            {
                if (latestResponseDate != null)
                {
                    if (latestResponseDate < cr.CreatedDate)
                    {
                        latestResponseDate = cr.CreatedDate;
                    }
                }
                else
                {
                    latestResponseDate = cr.CreatedDate;
                }
            }

            lastResponseDateByContactId.put(cid, latestResponseDate);
        }

        return lastResponseDateByContactId;
    }

    private Map<String,Datetime> getLastResponseDateLead(List<String> leadIds)
    {
        //Datetime latestResponseDate;
        Map<String,Datetime> lastResponseDateByLeadId = new Map<String,Datetime>();

        Map<String, List<Campaign_Response__c>> campaignResponseListByLeadId = new Map<String, List<Campaign_Response__c>>();

        List<Campaign_Response__c> campaignResponses = [SELECT CreatedDate, Lead__c FROM Campaign_Response__c WHERE Lead__c IN: leadIds AND Campaign__c =: campaignId];

        if (campaignResponses.size() > 0)
        {
            for (Campaign_Response__c cr : campaignResponses)
            {
                if (campaignResponseListByLeadId.containsKey(cr.Lead__c))
                    campaignResponseListByLeadId.get(cr.Lead__c).add(cr);
                else
                    campaignResponseListByLeadId.put(cr.Lead__c, new List<Campaign_Response__c>{cr});
            }
        }

        for (String lid : campaignResponseListByLeadId.keySet())
        {
            Datetime latestResponseDate;

            for (Campaign_Response__c cr : campaignResponseListByLeadId.get(lid))
            {
                if (latestResponseDate != null)
                {
                    if (latestResponseDate < cr.CreatedDate)
                    {
                        latestResponseDate = cr.CreatedDate;
                    }
                }
                else
                {
                    latestResponseDate = cr.CreatedDate;
                }
            }

            lastResponseDateByLeadId.put(lid, latestResponseDate);
        }

        return lastResponseDateByLeadId; //latestResponseDate.format();
    }
    // END:

    public PageReference refreshCampaignMembers()
    {
        return null;
    }

    private void resetAllCampaignMemberList()
    {
        if(this.todoCampaignMemberCurrentList != null && !this.todoCampaignMemberCurrentList.isEmpty())
            this.todoCampaignMemberCurrentList.clear();
        if(this.notStartedCampaignMemberCurrentList != null && !this.notStartedCampaignMemberCurrentList.isEmpty())
            this.notStartedCampaignMemberCurrentList.clear();
        if(this.myCampaignMemberCurrentList != null && !this.myCampaignMemberCurrentList.isEmpty())
          this.myCampaignMemberCurrentList.clear();
        if(this.allTodoCampaignMemberCurrentList != null && !this.allTodoCampaignMemberCurrentList.isEmpty())
          this.allTodoCampaignMemberCurrentList.clear();
        if(this.myDoneCampaignMemberCurrentList != null && !this.myDoneCampaignMemberCurrentList.isEmpty())
           this.myDoneCampaignMemberCurrentList.clear();
        if(this.doneCampaignMemberCurrentList != null && !this.doneCampaignMemberCurrentList.isEmpty())
          this.doneCampaignMemberCurrentList.clear();
        if(this.allCampaignMemberCurrentList != null && !this.allCampaignMemberCurrentList.isEmpty())
          this.allCampaignMemberCurrentList.clear();
    } 

    private Campaign_sObjectPaginator assignPaginator(string tabName)
    {
        Campaign_sObjectPaginator output = new Campaign_sObjectPaginator();
        if(tabName == 'todo')
        {
            output = this.todoCampaignMemberPaginator;
        }
        else if(tabName == 'done')
        {
            output = this.doneCampaignMemberPaginator;
        }
        else if(tabName == 'myDone')
        {
            output = this.myDoneCampaignMemberPaginator;  
        }
        else if(tabName == 'allTodo')
        {
            output = this.allTodoCampaignMemberPaginator;
        }
        else if(tabName == 'my')
        {
            output = this.myCampaignMemberPaginator;
        }
        else if(tabName == 'notStarted')
        {
            output = this.notStartedCampaignMemberPaginator;
        }        
        else if(tabName == 'all')
        {
            output = this.allCampaignMemberPaginator;
        }
        return output;
    }

    public PageReference toggleSort() 
    {
        // sort against selected column
        system.debug('@ toggleSort()');

        String tabName = Apexpages.currentPage().getParameters().get('tabName');
                
        system.debug('@ toggleSort() tabName: ' + tabName);

        Campaign_sObjectPaginator tmpPaginator = assignPaginator(tabName);

        if(tmpPaginator.sortDir == 'ASC')
        {
            tmpPaginator.sortDir = 'DESC NULLS LAST';
        }
        else
        {
            tmpPaginator.sortDir = 'ASC';
        }

        this.refresh();

        return null;
    }

    private String fetchDefaultSortField()
    {
        String output = 'ageInList';
        string campaignSortField = campaign.Default_Sort_Field_for_Campaign_Exec__c; 
        system.debug('@@ campaignSortField = ' + campaignSortField);

        // see if there is override from Campaign record
        // fetch the campaign information
        if(defaultSortFieldMap.containsKey(campaignSortField))
        {
            output = defaultSortFieldMap.get(campaignSortField);
        }
        return output;
    }

    private String fetchDefaultSortOrder()
    {
        String output = 'DESC NULLS LAST';
        string campaignSortOrder = campaign.Default_Sort_Order_for_Campaign_Exec__c;
        system.debug('@@ campaignSortOrder = ' + campaignSortOrder);

        // see if there is override from Campaign record
        // fetch the campaign information
        if(defaultSortOrderMap.containsKey(campaignSortOrder))
        {
            output = defaultSortOrderMap.get(campaignSortOrder);
        }

        if(output=='DESC') output = 'DESC NULLS LAST';
        return output;
    }

    public PageReference resetSort()
    {
        // revert back to default sort
        String tabName = Apexpages.currentPage().getParameters().get('tabName');
        system.debug('@ toggleSort() tabName: ' + tabName);
        Campaign_sObjectPaginator tmpPaginator = assignPaginator(tabName);
        tmpPaginator.sortField = defaultSortField;
        tmpPaginator.sortDir = defaultSortOrder;

        refresh();

        return null;
    }

    private string defaultSortField 
    {
        get 
        {
            if(defaultSortField==null)
            {
                defaultSortField = fetchDefaultSortField();
            }
            return defaultSortField;
        }
        private set;
    }

    private string defaultSortOrder
    {
        get
        {
            if(defaultSortOrder==null)
            {
                defaultSortOrder = fetchDefaultSortOrder();
            }
            return defaultSortOrder;
        }
        private set;
    }
}
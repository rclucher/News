/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: Controller for pre-processing address information
 * History:
 * 10/09/2013  Bohao Chen  Created
 * 21/11/2013  Bohao Chen  Updated
 * 2016-01-17  Atul Gupta  Updated
 * 2016-02-17  Atul Gupta  Updated
---------------------------------------------------------*/
public without sharing class WalkinForecast_ControllerX 
{
    private final String RECORD_TYPE_NAME = 'Walk-In Forecast';
    private final String ACCOUNT_NAME = 'News Corp Australia';
    private final Integer PROBABILITY = 99;
    private final String STAGE = 'Walk-In Forecast';
    private final String TYPE = 'Non-Core Activity';
    public static final String NO_ACCESS_PERMISSION = 'You have insufficient access rights on saving walk-in forecast for chosen user';
    public static final String INVALID_ROLE_HIERARCHY = 'Walk-in forecast cannot be entered for users at the same level or higher than your own, or users outside of your team.';
    
    public String selectedYear { get; set;}
    public Boolean manageAllWalkIn { get; set;}
    public Opportunity oppt {get;set;}
    public List<opportunityWrapper> opportunities { get{ return opportunities = opportunities == null ? new List<opportunityWrapper>() : opportunities; } set; }
    public List<SelectOption> yearOptions { get; set;}

    public ApexPages.StandardController ctr;
    private final String accountId;
    private final String recordTypeId;
    
    private Map<String, Map<String, OpportunityLineItem>> opptyLineItemsByEntryIdByOpptyName = new Map<String, Map<String, OpportunityLineItem>>();
    private Map<String, Opportunity> opportunitiesByName = new Map<String, Opportunity>();
          
    public Map<String, FiscalYearSettings> fiscalSettingByYear
    {
        get 
        {
            if(fiscalSettingByYear == null)
            {
                fiscalSettingByYear = new Map<String, FiscalYearSettings>();
            
                for(FiscalYearSettings fy : [Select f.WeekStartDay, f.StartDate, f.Name, f.EndDate 
                                            From FiscalYearSettings f 
                                            Where f.YearType = 'Custom'
                                            Order by f.Name ASC Limit 50000])
                {
                    fiscalSettingByYear.put(fy.Name, fy);
                }
            }
            
            return fiscalSettingByYear;
        }
        private set;
    }
    
    public List<PricebookEntry> PricebookEntries
    {
        get 
        {
            if(PricebookEntries == null)
            {
                PricebookEntries = [Select p.Product2.Category__c, p.Product2.Family, p.Product2Id 
                                    From PricebookEntry p
                                    Where p.Product2.Name like 'Walk-in%'
                                    And p.IsActive = true
                                    order by p.Product2.Family ASC];
            }
            
            return PricebookEntries;
        }
        private set;
    }
    
    public String reportId
    {
        get 
        {   
            //SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - Code block exempted from Test Context
            if(!Test.isRunningTest()){
                if(reportId == null){
                    reportId = [Select r.Name, r.Id From Report r Where r.Name = 'Actual Walk-ins Opportunities' limit 1].Id;
                }
            }
            return reportId;
        }
        private set;
    }
    
    // constructor
    public WalkinForecast_ControllerX(ApexPages.StandardController controller) 
    {
        try
        {
            accountId = [Select Id from Account Where Name =: ACCOUNT_NAME limit 1].Id;
            
        }catch(QueryException e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, 'Please add account named "News Corp Australia"'));        
        }
        
        system.debug('====url ===' + ApexPages.currentPage().getHeaders().get('Referrer'));
 
        
        this.ctr = controller;
        
        this.recordTypeId = Global_Helper.getRecordTypeIdByName(RECORD_TYPE_NAME, 'Opportunity');
        
        this.oppt = (Opportunity)controller.getRecord();
        system.debug('@@oppt inside constructor : '+ oppt);
        this.oppt.OwnerId = UserInfo.getUserId();
        
        this.manageAllWalkIn = [Select Manage_All_Walk_in__c From User Where Id = : UserInfo.getUserId() limit 1].Manage_All_Walk_in__c;
        
        this.refreshYearOptions();
        
        // order of the following lines are very important
        this.retrieveOpportunities();
        this.reloadOpportunities();
        
        
    }
    
    // get year select options    
    public void refreshYearOptions()
    {
        if(yearOptions == null)
        {
            yearOptions = new List<SelectOption>();
        }
        
        for(String yearName : fiscalSettingByYear.keySet())
        {
            if(date.today() >= fiscalSettingByYear.get(yearName).StartDate 
                && date.today() <= fiscalSettingByYear.get(yearName).EndDate)
            {
                selectedYear = yearName;
            }
            
            if(date.today() <= fiscalSettingByYear.get(yearName).EndDate)
            {
                yearOptions.add(new SelectOption(yearName, 'FY' + yearName));
            }
        }
        
        system.debug('####selectedYear1### ' + selectedYear);
    }
    
        // this function will load related opportunities and opportunity line items into 
    public void reloadOpportunities()
    {
        
        if(oppt.OwnerId != null && String.isNotBlank(selectedYear) && accountId != null)
        {           
            if(String.isNotBlank(selectedYear) && fiscalSettingByYear.containsKey(selectedYear))
            {
                FiscalYearSettings fy = fiscalSettingByYear.get(selectedYear);
                
                Date startDate = fy.StartDate;
                Date endDate = fy.EndDate;
            
                Integer numOfWeeks = startDate.daysBetween(endDate.addDays(1)) / 7;
                
                
                List<OpportunityLineItem> newOpptyLineItems = this.createOpportunityLineItems(null);
                
                for(Integer i = 1; i <= numOfWeeks; i++)
                {
                    Opportunity oppty;
                    
                    String opportunityName = 'Walk-in Forecast-Week-' + convertWeekNum(i) + '-FY' + selectedYear;
                    
                    List<OpportunityLineItem> opptyLineItems;
                    
                    system.debug('===opportunitiesByName=== ' + opportunitiesByName);
                    system.debug('===opportunityName=== ' + opportunityName);
                    
                    
                    if(opportunitiesByName.containsKey(opportunityName))
                    {
                        oppty = opportunitiesByName.get(opportunityName);
                        
                        system.debug('===oppty 1=== ' + oppty);
                    
                        system.debug('===opptyLineItemsByEntryIdByOpptyName 1=== ' + opptyLineItemsByEntryIdByOpptyName);
                        
                        
                        if(opptyLineItemsByEntryIdByOpptyName.containsKey(opportunityName))
                        {
                            opptyLineItems = this.createOpportunityLineItems(opptyLineItemsByEntryIdByOpptyName.get(opportunityName));
                        }
                        else
                        {
                            opptyLineItems = newOpptyLineItems.deepClone();
                        }
                    }
                    else
                    {
                        oppty = new Opportunity();
                        oppty.Amount = 0;
                        oppty.Opportunity_Type__c = this.RECORD_TYPE_NAME;
                        oppty.RecordTypeId = this.recordTypeId;
                        oppty.AccountId = this.accountId;
                        oppty.Type = this.TYPE;
                        opptyLineItems = newOpptyLineItems.deepClone();                    
                    }
                    
                    system.debug('===opptyLineItems=== ' + opptyLineItems);
                    opportunities.add(new opportunityWrapper(oppty, opptyLineItems, i, startDate.addDays(7 * (i -1))));
                }
            }
            
            system.debug('====opportunities=== ' + opportunities);
        }
    }
    
    // this function conver integer week number to string week number.
    // it also covert single digit week number to double digits
    private String convertWeekNum(Integer num)
    {
        String weekNum = String.valueOf(num);
        
        if(num < 9)
            weekNum = '0' + weekNum;
        
        return weekNum;
    }
    
    // retrieve related opportunities and opportunity line items
    public void retrieveOpportunities()
    {
        system.debug('@@oppt retrieveOpportunities : '+ oppt);
        if(oppt.OwnerId != null && selectedYear != null && accountId != null)
        {
            String opptyNamePart = '%FY' + selectedYear;
            
            for(Opportunity oppty : [Select o.Name, o.Id, o.OwnerId, o.Amount, o.CloseDate, 
                                        (Select OpportunityId, PricebookEntryId, PricebookEntry.Name, Custom_TotalPrice__c
                                        From OpportunityLineItems) 
                                    From Opportunity o
                                    Where o.OwnerId =: oppt.OwnerId
                                    And o.Name like: opptyNamePart
                                    And o.RecordType.Name =: RECORD_TYPE_NAME
                                    order by o.CloseDate ASC
                                    ])
            {
                system.debug('====oppty=== ' + oppty);
                // generate opportunities map with Name as key
                opportunitiesByName.put(oppty.Name, oppty);
                
                // generate opportunity line items map with price book and opportunity name as combination key
                Map<String, OpportunityLineItem> opptyLineItemsByEntryId = new Map<String, OpportunityLineItem>();
                
                system.debug('====OpportunityLineItems=== ' + oppty.OpportunityLineItems);
                
                for(OpportunityLineItem oli : oppty.OpportunityLineItems)
                {
                    opptyLineItemsByEntryId.put(oli.PricebookEntryId, oli);
                }
                
                opptyLineItemsByEntryIdByOpptyName.put(oppty.Name, opptyLineItemsByEntryId);
            }
            
            system.debug('@opportunitiesByName size: ' + opportunitiesByName.size());
        }
    }
    
    public PageReference save()
    {
        this.doSave();
        
        PageReference p = new PageReference(ctr.cancel().getUrl());
        return p;
    }
    
    // reset collections and variables
    private void reset()
    {
        this.opportunities.clear();
        this.opportunitiesByName.clear();
        this.opptyLineItemsByEntryIdByOpptyName.clear();
    }
    
    // when cancel, redirect back to previous page
    public PageReference cancel()
    {       
        PageReference p = new PageReference(ctr.cancel().getUrl());
        return p;
    }
    
    public PageReference goToReport()
    {
        try
        {
            // convert opportunity owner id to name so that filter on custom report can work
            String userName = [Select Name From User Where Id = : oppt.OwnerId limit 1].Name;
            
            // redirect to custom report
            PageReference p = new PageReference('/' + reportId + '?pv0=' + userName);
            p.setRedirect(true);
            return p;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
            return null;                    
        }
    }
        
    public PageReference quickSave()
    {
        this.doSave();
        this.refreshWalkinForecastTable();
        return null;
    }
    
    private void doSave()
    {
        /**** Updated by Bohao Chen on 1/4/2014 for JIRA SFE-248 *****/
        OpportunityLineItem_Helper.isWalkinForecast = true;
        /**** Updated by Bohao Chen *****/    
        
        Map<String, List<OpportunityLineItem>> opptyLineItemsByOpptyName = new Map<String, List<OpportunityLineItem>>();

        
        for(opportunityWrapper opptyWrapper : Opportunities)
        {
            // if none of product family has walk-in forecast, we should not create opportunity for that week, 
            // neither any opportunity line items
            Boolean hasOpportunityLines = false;
            
            for(opportunityLineItem oli : opptyWrapper.opportunityLineItemsByPricebookEntryId.values())
            {
                //SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com Exclude 0 values from OpportunityLineItem creation
                if(oli.Custom_TotalPrice__c != null && oli.Custom_TotalPrice__c != 0)
                {
                    hasOpportunityLines = true;
                }
            }

            // if any product families have walk-in forecast for this week, an opportunity is created if it doesn't exist previously        
            if(hasOpportunityLines)
            {
                String opportunityName = 'Walk-in Forecast-Week-' + convertWeekNum(opptyWrapper.weekNum) + '-FY' + selectedYear;
                
                // create opportunity when it doesn't exist before
                if(opptyWrapper.opportunity.Id == null)
                {
                    opptyWrapper.opportunity.OwnerId = this.oppt.OwnerId;
                    opptyWrapper.opportunity.Name = opportunityName;
                    opptyWrapper.opportunity.CloseDate = opptyWrapper.weekCommencingDate;
                    opptyWrapper.opportunity.Probability = this.PROBABILITY;
                    opptyWrapper.opportunity.StageName = this.STAGE;
                    opptyWrapper.opportunity.RecordTypeId = this.recordTypeId;
                    opptyWrapper.opportunity.AccountId = this.accountId; 
                    
                    system.debug('===record type id=== ' + opptyWrapper.opportunity.RecordTypeId);
                    
                    opportunitiesByName.put(opptyWrapper.opportunity.Name, opptyWrapper.opportunity);
                }

                // update service date on opportunity line items
                for(OpportunityLineItem oli : opptyWrapper.opportunityLineItemsByPricebookEntryId.values())
                {
                    oli.ServiceDate = opptyWrapper.weekCommencingDate;
                }
                
                opptyLineItemsByOpptyName.put(opportunityName, opptyWrapper.opportunityLineItemsByPricebookEntryId.values());
            }
        }

        system.debug('=== opptyLineItemsByOpptyName 1=== ' + opptyLineItemsByOpptyName);
        
        try
        {
            upsert opportunitiesByName.values();
        }
        catch(NoAccessException e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, NO_ACCESS_PERMISSION));  
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));  
        }
        
        system.debug('=== opportunitiesByName 2=== ' + opportunitiesByName);
        
        // insert / update opportunity line items
        List<OpportunityLineItem> opptyLineItems = new List<OpportunityLineItem>();
        //List<OpportunityLineItem> newOpptyLineItems = new List<OpportunityLineItem>();
        //List<OpportunityLineItem> updateOpptyLineItems = new List<OpportunityLineItem>();
        
        for(String opptyName: opptyLineItemsByOpptyName.keySet())
        {
            Id opptyId = opportunitiesByName.get(opptyName).Id;
            
            for(OpportunityLineItem oli : opptyLineItemsByOpptyName.get(opptyName))
            {
                // only create opportunity line item if total price is not null
                if(oli.Custom_TotalPrice__c != null)
                {
                    if(oli.Id == null)
                    {
                        oli.Pattern__c = 'Weekly';
                        oli.Period__c = 'Week(s)';
                        oli.of_Periods__c = 1;
                        oli.OpportunityId = opptyId;
                        oli.Quantity = 1;
                        oli.TotalPrice = 0;
                    }
                    
                    opptyLineItems.add(oli);
                }
            }
        }
        
        try
        {
            upsert opptyLineItems;
        }
        catch(NoAccessException e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, NO_ACCESS_PERMISSION));  
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));  
        }
        
        // insert / update line item schedule
        List<OpportunityLineItemSchedule> opportunityLineItemSchedules = new List<OpportunityLineItemSchedule>();
        
        for(OpportunityLineItemSchedule olis : [Select o.Revenue, o.OpportunityLineItem.PricebookEntryId, o.OpportunityLineItem.Custom_TotalPrice__c,
                                                    o.OpportunityLineItemId, o.OpportunityLineItem.Opportunity.Name, o.OpportunityLineItem.ServiceDate
                                                    From OpportunityLineItemSchedule o
                                                    Where o.OpportunityLineItemId IN: opptyLineItems])
        {
            system.debug('====custom total price=== ' + olis.OpportunityLineItem.Custom_TotalPrice__c);
            system.debug('=====olis id==== ' + olis.Id);
            
            olis.Revenue = olis.OpportunityLineItem.Custom_TotalPrice__c;
            olis.ScheduleDate = olis.OpportunityLineItem.ServiceDate;
            //olis.Type = 'Revenue';
            opportunityLineItemSchedules.add(olis);
        }
        
        system.debug('===opportunityLineItemSchedules 1=== ' + opportunityLineItemSchedules);
        
        try
        {
            upsert opportunityLineItemSchedules;
        }
        catch(NoAccessException e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, NO_ACCESS_PERMISSION));  
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));  
        }
        
        system.debug('===opportunityLineItemSchedules 2=== ' + opportunityLineItemSchedules);
        
        //SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com Set of OpportunityLineItem Ids where Custom Total Price is = or blank
        Set<Id> lineItemIdSetWithNullValues = new Set<Id>();
        
        //SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com Invoke method to delete any Opportunities and associated records where Custom Prices is 0 or blank
        if(!Opportunities.isEmpty()){
            
            //SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com Iterate over the wrapper list and check with OpportunityLineItems have Custom Price = 0 or blank
            for(opportunityWrapper opptyWrapper : Opportunities){
                
                for(OpportunityLineItem oli : opptyWrapper.opportunityLineItemsByPricebookEntryId.values()){
                    
                    if(oli.Custom_TotalPrice__c == null || oli.Custom_TotalPrice__c == 0){
                        
                        if(oli.id <> null){
                            lineItemIdSetWithNullValues.add(oli.id);
                        }
                    }
                }
            }
            
            if(!lineItemIdSetWithNullValues.isEmpty()){
                //SFE-844 2016-02-17 atul.gupta@bluewolfgroup.com call helper method to delete Opportunity and its associated records
                WalkinForecast_Controller_Helper.deleteNullOpportunities(lineItemIdSetWithNullValues);
            }
        }
        
    }

    private List<OpportunityLineItem> createOpportunityLineItems(Map<String, OpportunityLineItem> opptyLineItemsByEntryId)
    {
        List<OpportunityLineItem> opptyLineItems = new List<OpportunityLineItem>();

        for(PricebookEntry p : this.PricebookEntries)
        {
            OpportunityLineItem oli;
            
            if(opptyLineItemsByEntryId != null && opptyLineItemsByEntryId.containsKey(p.Id))
            {
                oli = opptyLineItemsByEntryId.get(p.Id);  
            }
            else
            {
                oli = new OpportunityLineItem();
                oli.PricebookEntryId = p.Id;
            }

            opptyLineItems.add(oli);
        }
        
        return opptyLineItems;
    }
    
    public PageReference refreshWalkinForecastTable()
    {
        // update: before showing opportunity for chose user, we have to check if chose user is below 
        // role hierarchy of current user role
        system.debug('@refreshWalkinForecastTable 0');
        this.reset();
        this.doValidate();
        
        if(oppt.OwnerId != null)
        {
            system.debug('@refreshWalkinForecastTable 1');
            
            Id chosenUserRoleId = [Select u.UserRoleId From User u Where u.Id =: oppt.OwnerId limit 1].UserRoleId;
            
            if(UserInfo.getUserId() == oppt.OwnerId || Global_Helper.isBelowRoleHierarchy(UserInfo.getUserRoleId(), chosenUserRoleId))
            {
                system.debug('@refreshWalkinForecastTable 2');
                
                this.retrieveOpportunities();
                this.reloadOpportunities();
            }
            else
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, INVALID_ROLE_HIERARCHY));
            } 
        }       
        return null;
    }
    
    private PageReference doValidate()
    {
        if(oppt.OwnerId == null && String.isBlank(selectedYear))
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Please select User and Period to start'));
        }           
        else if(oppt.OwnerId == null)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Please select User to start'));
            
        }
        else if(String.isBlank(selectedYear))
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Please select Period to start'));              
        }
        else if(accountId == null)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.FATAL, 'Please add an account named "News Corp Australia"'));                 
        }
        return null;
    }
    
       
    public class opportunityWrapper
    {
        public Boolean isSelect { get{ return isSelect = isSelect == null ? false : isSelect; } set; }
        public Integer weekNum { get;set; }
        public Date weekCommencingDate { get;set; }
        public Decimal total { get;set; }
        public Opportunity opportunity { get;set; }
        public Map<Id, OpportunityLineItem> opportunityLineItemsByPricebookEntryId { get;set; }
        
        //public Map<Id, OpportunityLineItemSchedule> opportunityLineItemSchedulesByPricebookEntryId { get;set; }
        
        public List<OpportunityLineItem> opportunityLineItems { get;set; }
        
        public opportunityWrapper(Opportunity opportunityIn, List<OpportunityLineItem> opportunityLineItemsIn, 
                                   Integer weekNumIn, Date weekCommencingDateIn)
        {
            opportunityLineItemsByPricebookEntryId = new Map<Id, OpportunityLineItem>();
            
            for(OpportunityLineItem oli : opportunityLineItemsIn)
            {
                opportunityLineItemsByPricebookEntryId.put(oli.PricebookEntryId, oli);
            }
            
            this.weekNum = weekNumIn;
            this.weekCommencingDate = weekCommencingDateIn;
            this.opportunity = opportunityIn;
            
            this.total = 0;
            
            
        }
    }
}
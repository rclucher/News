/**
* @company      Bluewolf
* @author       Louis Wang (louis.wang@bluewolf.com)
* @date         2015-07-17
* @description  This class contains methods for Visualforce Page NewsXtend_ActionPlan
*/
public with sharing class NewsXtend_ActionPlan 
{
	public Action_Plan__c actionPlan {get; private set;}
    public String entered_ActionPlanGroup {get; set;}
	public String entered_ActionPlanSubGroup {get; set;}
	public List<Action_Task__c> campMgmt_Setup_List {get; set;}
	public List<Action_Task__c> campMgmt_Monthly_List {get; set;}
	public List<Action_Task__c> creative_Setup_List {get; set;}
	public List<Action_Task__c> creative_Monthly_List {get; set;}
	public List<Action_Task__c> display_Setup_List {get; set;}
	public List<Action_Task__c> display_Monthly_List {get; set;}
	public List<Action_Task__c> sem_Setup_List {get; set;}
	public List<Action_Task__c> sem_Monthly_List {get; set;}
	public List<Action_Task__c> seo_Setup_List {get; set;}
	public List<Action_Task__c> seo_Monthly_List {get; set;}
	public List<Action_Task__c> social_Setup_List {get; set;}
	public List<Action_Task__c> social_Monthly_List {get; set;}
    public List<Action_Task__c> video_Setup_List {get; set;}
    public List<Action_Task__c> video_Monthly_List {get; set;}
	private List<Action_Task__c> cloned_AllActionTask_List;
	private List<Action_Task__c> current_AllActionTask_List;
	public Id oppId {get; private set;}
    public String oppName {get; private set;}
	private Id apId;

	//page static data
	public list<SelectOption> selectOption_ActionPlanGroup {get; private set;}
	public list<SelectOption> selectOption_ActionPlanSubGroup {get; private set;}
    public list<SelectOption> selectOption_ActionTaskStatus {get; private set;}
	private static final String WIZARD_MANDATORY_FIELD_MISSING = 'Please enter both "Action Plan Group" and "Action Plan Sub Group".';
	private static final String WIZARD_MANDATORY_FIELD_MISSING_2 = 'Please enter both "Action Plan Period" and "Start Date".';
	private static final String MONTHLY_ACTION_TASK = 'Month-Month Task';
	private static final String SETUP_ACTION_TASK = 'Setup Task';
	private static final String ACTIONPLAN_STATUS_CANCELLED = 'Cancelled';	
	private static final String ACTIONTASK_GROUP_CAMPMGMT = 'Campaign Management';
	private map<string,string> recordTypeMap;
	public boolean canDelete {get; private set;}

    public NewsXtend_ActionPlan(ApexPages.StandardController controller) 
    {
    	initPage();
    }

    public PageReference initPage()
    {
    	apId = ApexPages.currentPage().getParameters().get('Id');
    	actionPlan = NewsXtend_ActionPlan_Helper.fetch_ActionPlan(apId);
        if(actionPlan.Opportunity__c!=null) 
        {
            oppId = actionPlan.Opportunity__c;
            oppName = actionPlan.Opportunity__r.Name;
        }

    	selectOption_ActionPlanGroup = NewsXtend_ActionPlan_Helper.fetch_SelectOption_ActionTask('Action_Task_Group__c', true);
    	selectOption_ActionPlanSubGroup = NewsXtend_ActionPlan_Helper.fetch_SelectOption_ActionTask('Action_Task_Sub_Group__c', true);
        selectOption_ActionTaskStatus = NewsXtend_ActionPlan_Helper.fetch_SelectOption_ActionTask('Action_Task_Status__c', false);
		recordTypeMap = NewsXtend_ActionPlan_Helper.fetch_RecordTypeMap();
		canDelete = NewsXtend_ActionPlan_Helper.fetch_CanDelete(apId);

    	campMgmt_Setup_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'Campaign Management', SETUP_ACTION_TASK);
    	campMgmt_Monthly_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'Campaign Management', MONTHLY_ACTION_TASK);
    	creative_Setup_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'Creative', SETUP_ACTION_TASK);
    	creative_Monthly_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'Creative', MONTHLY_ACTION_TASK);
    	display_Setup_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'Display', SETUP_ACTION_TASK);
    	display_Monthly_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'Display', MONTHLY_ACTION_TASK);
    	sem_Setup_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'SEM', SETUP_ACTION_TASK);
    	sem_Monthly_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'SEM', MONTHLY_ACTION_TASK);
    	seo_Setup_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'SEO', SETUP_ACTION_TASK);
    	seo_Monthly_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'SEO', MONTHLY_ACTION_TASK);
    	social_Setup_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'Social', SETUP_ACTION_TASK);
    	social_Monthly_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'Social', MONTHLY_ACTION_TASK);
        video_Setup_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'Video', SETUP_ACTION_TASK);
        video_Monthly_List = NewsXtend_ActionPlan_Helper.fetch_ActionTask_List(apId, 'Video', MONTHLY_ACTION_TASK);

    	// add all the list together as backup, so can compare what is changed later
    	reset_Current_AllActionTask_List();
    	cloned_AllActionTask_List = current_AllActionTask_List.deepClone(true, true, true);

    	return null;
    }

    private void reset_Current_AllActionTask_List()
    {
    	// add all the current list together, so can compare what is changed 
		current_AllActionTask_List = new List<Action_Task__c>();
		current_AllActionTask_List.addAll(campMgmt_Setup_List);
		current_AllActionTask_List.addAll(campMgmt_Monthly_List);
		current_AllActionTask_List.addAll(creative_Setup_List);
		current_AllActionTask_List.addAll(creative_Monthly_List);
		current_AllActionTask_List.addAll(display_Setup_List);
		current_AllActionTask_List.addAll(display_Monthly_List);
		current_AllActionTask_List.addAll(sem_Setup_List);
		current_AllActionTask_List.addAll(sem_Monthly_List);
		current_AllActionTask_List.addAll(seo_Setup_List);
		current_AllActionTask_List.addAll(seo_Monthly_List);
		current_AllActionTask_List.addAll(social_Setup_List);
		current_AllActionTask_List.addAll(social_Monthly_List);
        current_AllActionTask_List.addAll(video_Setup_List);
        current_AllActionTask_List.addAll(video_Monthly_List);
    }

    public PageReference click_Save_button()
    {
        if(actionPlan.To_Create_CampMgmt_SetupTask__c || actionPlan.To_Create_CampMgmt_MonthlyTask__c)
        {
        	// these 2 checkboxes are ticked when ActionPlan is created. 
        	//	if they are ticked then wizard is not displayed
        	//	Create corresponding tasks and reset these checkboxes
	    	boolean isError = false;
	    	boolean isDmlError = false;
	        SavePoint sp = Database.setSavepoint();

			if(actionPlan.To_Create_CampMgmt_SetupTask__c)
			{
                entered_ActionPlanGroup = ACTIONTASK_GROUP_CAMPMGMT;
                entered_ActionPlanSubGroup = SETUP_ACTION_TASK;

		    	isError = check_MandatoryFields_MassCreateTasks();
		    	if(isError)
		    	{
		    		return null;
		    	}

		        isDmlError = insert_ActionTasks(entered_ActionPlanGroup, entered_ActionPlanSubGroup);
		        if(isDmlError)
		        {
		        	Database.rollback(sp);
		        	return null;
		        }
				actionPlan.To_Create_CampMgmt_SetupTask__c = false;
			}	

			if(actionPlan.To_Create_CampMgmt_MonthlyTask__c)
			{
                entered_ActionPlanGroup = ACTIONTASK_GROUP_CAMPMGMT;
                entered_ActionPlanSubGroup = MONTHLY_ACTION_TASK;

		    	isError = check_MandatoryFields_MassCreateTasks();
		    	if(isError)
		    	{
		    		return null;
		    	}

		        isDmlError = insert_ActionTasks(entered_ActionPlanGroup, entered_ActionPlanSubGroup);
		        if(isDmlError)
		        {
		        	Database.rollback(sp);
		        	return null;
		        }
				actionPlan.To_Create_CampMgmt_MonthlyTask__c = false;
			}	

			try
			{
				update actionPlan;
			}
			catch(Exception ex)
			{
	            ApexPages.addMessages(ex);
	            Database.rollback(sp);
	            return null;
			}
	    	// refresh the current page
	    	return refresh_CurrentPage();				
        }
        else
        {
            // Check if ActionPlanPeriod or ActionPlanStartDate is changed
            boolean isActionPlanChanged 
                = NewsXtend_ActionPlan_Helper.check_isActionPlanChanged(actionPlan.Id, 
                                                                        actionPlan.Action_Plan_Period__c, 
                                                                        actionPlan.Start_Date__c);

        	// wizard is now visible, so can have various interaction
	        SavePoint sp = Database.setSavepoint();

	    	// combine all ActionTask together into one list
            reset_Current_AllActionTask_List();
            // checking against started value against the VF input, to see which ActionTask needs to be updated
	    	List<Action_Task__c> toUpdate_AllActionTask_List 
	    		= NewsXtend_ActionPlan_Helper.fetch_toUpdate_AllActionTask_List(current_AllActionTask_List, 
																					cloned_AllActionTask_List);
	    	try
	    	{
	    		update actionPlan;
	    		update toUpdate_AllActionTask_List; // only update action tasks that were modified

	    		// Update Due Date for ActionTask that belongs to same Group-SubGroup-Month combination
                // moved by Tim Fabros 2015-10-20: moved to ActionTask Trigger
	    		// List<Action_Task__c> toUpdate_DueDate = NewsXtend_ActionPlan_Helper.update_DueDate(current_AllActionTask_List);
	    		// update toUpdate_DueDate; // only update action tasks due to parent's DueDate is changed

	    		if(actionPlan.Action_Plan_Status__c==ACTIONPLAN_STATUS_CANCELLED)
	    		{
	    			// if ActionPlan is set to Cancelled, set every action task status to cancelled, if it is not currently completed
		    		List<Action_Task__c> toUpdate_CancelledStatus = NewsXtend_ActionPlan_Helper.update_CancelledStatus(current_AllActionTask_List);
                    // skip trigger actions if setting all statuses to "Cancelled"
                    NewsXtend_ActionPlan_Helper.skipActionTaskTrigger = true;
		    		update toUpdate_CancelledStatus; // only update action tasks that is not competed/canceleed yet
		    	}
	    	}
	    	catch(Exception ex)
	    	{
	            ApexPages.addMessages(ex);
	            Database.rollback(sp);
	            return null;
	    	}

            ////////////////////START - Delete and Recreate Monthly ActionTasks///////////////////
            // Check if any monthly tasks has started
            boolean isMonthlyTasksStarted = NewsXtend_ActionPlan_Helper.check_isMonthlyTasksStarted(actionPlan.Id);
            if(!isMonthlyTasksStarted && isActionPlanChanged)
            {
                boolean isDmlError = false;
                // if none of the mothly task is started, and ActionPlanPeriod is changed,
                // then delete all the monthly tasks and re-create
                List<Action_Task__c> toDelete_MonthlyTasks 
                    = NewsXtend_ActionPlan_Helper.generate_toDelete_MonthlyTasks(actionPlan.Id);

                List<String> groupList = NewsXtend_ActionPlan_Helper.generate_toRecreate_MonthlyGroupNames(toDelete_MonthlyTasks);

                isDmlError = delete_ActionTasks(toDelete_MonthlyTasks);
                if(isDmlError)
                {
                    Database.rollback(sp);
                    return null;
                }

                for(String s : groupList)
                {
                    isDmlError = insert_ActionTasks(s, MONTHLY_ACTION_TASK);
                    if(isDmlError)
                    {
                        break;
                    }
                }
                if(isDmlError)
                {
                    Database.rollback(sp);
                    return null;
                }
            }   
            ////////////////////END - Delete and Recreate Monthly ActionTasks///////////////////         

            ////////////////////START - Recreate Monthly ActionTasks - if ActionPlanPeriod is changed from 1 month to larger value ///////////////////
            // Check if ActionPlanPeriod is changed and current value is larger than 1 month
            boolean isActionPlanPeriodChangedToLarger = NewsXtend_ActionPlan_Helper.check_isActionPlanPeriodChangedToLarger(actionPlan);

            if(!isActionPlanPeriodChangedToLarger)
            {
                boolean isDmlError = false;
                // determine which group needs to create monthly tasks
                List<String> groupList = NewsXtend_ActionPlan_Helper.generate_GroupNamesForMonthlyTasks(actionPlan.Id);

                // re-create the "missing" monthly tasks
                for(String s : groupList)
                {
                    isDmlError = insert_ActionTasks(s, MONTHLY_ACTION_TASK);
                    if(isDmlError)
                    {
                        break;
                    }
                }
                if(isDmlError)
                {
                    Database.rollback(sp);
                    return null;
                }
            }   
            ////////////////////END - Delete and Recreate Monthly ActionTasks///////////////////

	    	// refresh the current page
	    	return refresh_CurrentPage();
		}
    }

    public NewsXtend_ActionPlan gettheController()
    {
        // this method passes the VF Page controller to VF Component
        return this; 
    }

    public PageReference click_Mass_Create_Tasks_button()
    {
    	boolean isError = false;
    	isError = check_MandatoryFields_MassCreateTasks();
    	if (isError)
    	{
    		return null;
    	}

        SavePoint sp = Database.setSavepoint();

        isError = insert_ActionTasks(entered_ActionPlanGroup, entered_ActionPlanSubGroup);
        if (isError)
        {
        	Database.rollback(sp);
        	return null;
        }

        // automatically create monthly tasks when creating setup tasks.
        if (entered_ActionPlanSubGroup == SETUP_ACTION_TASK) {

            entered_ActionPlanSubGroup = MONTHLY_ACTION_TASK;

            isError = check_MandatoryFields_MassCreateTasks();
            if (isError)
            {
                return null;
            }

            isError = insert_ActionTasks(entered_ActionPlanGroup, entered_ActionPlanSubGroup);
            if (isError)
            {
                Database.rollback(sp);
                return null;
            }
        }
        
    	// refresh the current page
    	return refresh_CurrentPage();
    }

    private boolean check_MandatoryFields_MassCreateTasks()
    {
    	boolean isError = false;

    	if(entered_ActionPlanGroup==null || entered_ActionPlanSubGroup==null)
    	{
    		AddVfErrorMessage(WIZARD_MANDATORY_FIELD_MISSING);
    		isError = true;
    	}

    	if(entered_ActionPlanSubGroup==MONTHLY_ACTION_TASK 
    		&& (actionPlan.Start_Date__c==null || actionPlan.Action_Plan_Period__c==null))
    	{
    		AddVfErrorMessage(WIZARD_MANDATORY_FIELD_MISSING_2);
    		isError = true;
    	}
    	return isError;
    }

    private boolean insert_ActionTasks(String actionPlanGroup, String actionPlanSubGroup)
    {
    	boolean isDmlError = false;

    	try
    	{
	    	// generate ActionTask based on Admin Data
	    	List<Action_Task__c> toInsert_AllActionTask_List 
	    		= NewsXtend_ActionPlan_Helper.generate_toInsert_AllActionTask_List(apId, 
																				actionPlanGroup, 
																				actionPlanSubGroup, 
																				recordTypeMap, 
																				actionPlan.Action_Plan_Period__c,
																				actionPlan.Start_Date__c);
    		insert toInsert_AllActionTask_List;

            // added by Tim Fabros 2015-10-14
            // reorder first then apply actions 
            List<Action_Task__c> toUpdate_FirstTask = NewsXtend_ActionPlan_Helper.reorder_ActionTask_List(toInsert_AllActionTask_List);

            toUpdate_FirstTask = NewsXtend_ActionPlan_Helper.update_lastActionTask(toUpdate_FirstTask);

            update toUpdate_FirstTask;

    		// now every record has Ids, link each other with First Task
    		toUpdate_FirstTask = NewsXtend_ActionPlan_Helper.update_FirstTask(toUpdate_FirstTask, actionPlanSubGroup);
            
    		update toUpdate_FirstTask;
    	}
    	catch(Exception ex)
    	{
            ApexPages.addMessages(ex);
			isDmlError = true;
    	}
    	return isDmlError;
    }

    private boolean delete_ActionTasks(List<Action_Task__c> toDeleteList)
    {
        boolean isDmlError = false;
        try
        {
            delete toDeleteList;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            isDmlError = true;
        }
        return isDmlError;
    }    

    private void AddVfErrorMessage(string errorMsg)
    {
        apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.Error, errorMsg);
        apexpages.addMessage(msg);            
    }

    private PageReference refresh_CurrentPage()
    {
    	string urlEntered = ApexPages.CurrentPage().GetURL();
        if(urlEntered.contains('?'))
        {
            urlEntered = urlEntered.substring(0,urlEntered.indexOf('?'));
        }
        PageReference currentPage = new PageReference(urlEntered);
        currentPage.getParameters().put('Id', apId);
        currentPage.setRedirect(true);            
        return currentPage;
    }    

    public PageReference click_Delete_button()
    {
    	SavePoint sp = Database.setSavepoint();
	    // consolidate every action tasks to one list
	    reset_Current_AllActionTask_List();
    	try
    	{
    		delete actionPlan;
    		delete current_AllActionTask_List;
    	}
    	catch(Exception ex)
    	{
            ApexPages.addMessages(ex);
            Database.rollback(sp);
            return null;
    	}
    	return goto_Opportunity_Page();
    }

    private PageReference goto_Opportunity_Page()
    {
        PageReference optyPage = new PageReference('/' + oppId);
        optyPage.setRedirect(true);            
        return optyPage;
    }   

    public PageReference click_Reset_All_Month_Month_Tasks_button()
    {        
        SavePoint sp = Database.setSavepoint();
        // fetch all the Month-Month Tasks and reset them
        List<Action_Task__c> resetList = NewsXtend_ActionPlan_Helper.generate_Reset_ActionTask_List(apId);
        try
        {
            update resetList;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            Database.rollback(sp);
            return null;
        }        
        // refresh the current page
        return refresh_CurrentPage();
    }     
}
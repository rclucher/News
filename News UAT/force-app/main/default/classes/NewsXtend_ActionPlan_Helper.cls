/**
* @company      Bluewolf
* @author       Louis Wang (louis.wang@bluewolf.com)
* @date         2015-07-17
* @description  This class contains methods that are used for NewsXtend_ActionPlan
*/
public with sharing class NewsXtend_ActionPlan_Helper
{
	private static final String COMPLETED_ACTION_TASK = 'Completed';
	private static final String RECORDTYPE_ADMIN_DATA = 'Action_Task__c-Admin_Data';
	private static final String RECORDTYPE_GENERAL_DATA = 'Action_Task__c-General_Data';
	private static final String PICKLIST_BLANK_ENTRY = 'Select';
	private static final String NEWSXTEND_QUEUE = 'NewsXtend_Queue';
	private static final String MONTHLY_ACTION_TASK = 'Month-Month Task';
	private static final String SETUP_ACTION_TASK = 'Setup Task';
	private static final String ACTIONTASK_STATUS_COMPLETED = 'Completed';
	private static final String ACTIONTASK_STATUS_CANCELLED = 'Cancelled';
	private static final String ACTIONTASK_STATUS_NOTSTARTED = 'Not Started';
	private static final String ACTIONPLAN_PERIOD_1MONTH = '1 month';

	public static Boolean skipActionTaskTrigger = false;

    /**
    * @description Fetch ActionPlan record 
    * @param Id  
    * @return Action_Plan__c
    * @author louis.wang@bluewolf.com
    * @date 2015-07-17
    * @change 2015-08-31 NewsXtend Phase 2 louis.wang@bluewolf.com
    *						- Opportunity will be updated and accessed through Action Plan as a field
    *						- Relationship between Opportunity and ActionPlan is locked to one to one
    **/
    public static Action_Plan__c fetch_ActionPlan(Id apId)
    {		
		Action_Plan__c output;
		if(apId!=null)
		{
			//SFE-835 2016-02-10 atul.gupta@bluewolfgroup.com owner.name field queried to show on vf page
			list<Action_Plan__c> apList = [SELECT Id, Name, 
													Customer_Type__c,
													State__c,
													Action_Plan_Status__c,
													Action_Plan_Period__c,
													Start_Date__c,
													End_Date__c,
													Go_Live_Date__c,
													CreatedBy.Name,
													CreatedDate,
													LastModifiedBy.Name,
													LastModifiedDate,
													Owner.Name,
													To_Create_CampMgmt_SetupTask__c,
													To_Create_CampMgmt_MonthlyTask__c,
													Opportunity__c, Opportunity__r.Name
											FROM Action_Plan__c
											WHERE Id =: apId];
			if(!apList.IsEmpty())
			{
				output = apList[0];
			}
		}
		return output;
	}

    /**
    * @description Fetch the SelectOption for picklist field on Action_Task__c
    * @param string
    * @param boolean
    * @return list<SelectOption>
    * @author louis.wang@bluewolf.com
    * @date 2015-07-20
    **/
    public static List<SelectOption> fetch_SelectOption_ActionTask(String picklistFieldName, Boolean isMandatory)
    {
        List<SelectOption> output = new List<SelectOption>();

        if(picklistFieldName!=null)
        {
	        string blankEntry = PICKLIST_BLANK_ENTRY;
	        Schema.sObjectType sobject_type = Action_Task__c.getSObjectType();        
	        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe();       
	        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap();        
	        List<Schema.PicklistEntry> pick_list_values = field_map.get(picklistFieldName).getDescribe().getPickListValues(); 

	        if(isMandatory)
	        {
	        	output.add(new SelectOption('', blankEntry));
	        }

	        for (Schema.PicklistEntry a : pick_list_values) 
	        {
	            output.add(new selectOption(a.getValue(), a.getLabel()));
	        }
	    }
        return output;
    }	

    /**
    * @description Fetch the applicable Action Task List
    * @param Id
    * @param String
	* @param String
    * @return List<Action_Task__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-07-20
    **/
    public static List<Action_Task__c> fetch_ActionTask_List(Id actionPlanId, String actionTaskGroup, String actionTaskSubGroup)
    {
    	List<Action_Task__c> output = new List<Action_Task__c>();
    	if(actionPlanId!=null && actionTaskGroup!=null && actionTaskSubGroup!=null)
    	{
	    	output = [SELECT Id, Name, 
	    					Action_Plan__c,
	    					Action_Task_Name__c,
	    					Action_Task_Status__c,
	    					Action_Task_Group__c,
	    					Action_Task_Sub_Group__c,
	    					First_Task__c, First_Task__r.Due_Date__c,	    				
	    					RecordTypeId,
	    					Due_Date__c,
	    					Due_Date_SLA__c, 
	    					Number_Of_Tasks__c,  
	    					Note__c, 				
	    					OwnerId, Owner.Name, Owner.Type,
	    					Step_Number__c,
	    					Target_Month__c,
	    					Previous_Task__c,
	    					Previous_Task__r.Action_Task_Status__c
	    				FROM Action_Task__c
	    				WHERE Action_Plan__c =: actionPlanId
	    				AND Action_Task_Group__c =: actionTaskGroup
	    				AND Action_Task_Sub_Group__c =: actionTaskSubGroup
	    				ORDER BY Step_Number__c];
		}
    	return output;
    }

    /**
     * @description Fetch the applicable Action Task Map List that is split into Group and Sub-Group
     * @param 		Id
     * @return 
     * @author 		timothy.fabros@bluewolf.com
     * @date 		2015-10-21
     *
     * @note 		Commented out for future implementation to optimise code.
    **/
    /*
    public static Map<String, Map<String, List<Action_Task__c>>> fetch_totalActionTasks(Id actionPlanId)
    {
    	// map: task group, task sub group, list of action tasks
    	Map<String, Map<String, List<Action_Task__c>>> output = new Map<String, Map<String, List<Action_Task__c>>>();

    	if (actionPlanId != null)
    	{
	    	List<Action_Task__c> actionTasks = [SELECT Id
							    				     , Name 
							    				     , Action_Plan__c
							    				     , Action_Task_Name__c
							    				     , Action_Task_Status__c
							    				     , Action_Task_Group__c
							    				     , Action_Task_Sub_Group__c
							    				     , First_Task__c
							    				     , First_Task__r.Due_Date__c    				
							    				     , RecordTypeId
							    				     , Due_Date__c
							    				     , Due_Date_SLA__c
							    				     , Number_Of_Tasks__c
							    				     , Note__c
							    				     , OwnerId
							    				     , Owner.Name
							    				     , Owner.Type
							    				     , Step_Number__c
							    				     , Target_Month__c
							    				     , Previous_Task__c
							    				     , Previous_Task__r.Action_Task_Status__c
							    				  FROM Action_Task__c
							    			     WHERE Action_Plan__c =: actionPlanId
							    			  ORDER BY Action_Task_Group__c
												     , Action_Task_Sub_Group__c
												     , Step_Number__c ASC];

			// split and populate action tasks into map
			for (Action_Task__c at : actionTasks) 
			{
				if (!output.containsKey(at.Action_Task_Group__c)) 
				{
					output.put(at.Action_Task_Group__c, new Map<String, List<Action_Task__c>>());
				}

				if (!output.get(at.Action_Task_Group__c).containsKey(at.Action_Task_Sub_Group__c)) 
				{
					output.get(at.Action_Task_Group__c).put(at.Action_Task_Sub_Group__c, new List<Action_Task__c>());
				}

				output.get(at.Action_Task_Group__c).get(at.Action_Task_Sub_Group__c).add(at);
			}
		}

    	return output;
    }
    */

    /**
    * @description Compare each Action Task and determine what got changed, so only need to update specific ActionTask record
    * @param List<Action_Task__c>
    * @param List<Action_Task__c>
    * @return List<Action_Task__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-07-21
    **/
    public static List<Action_Task__c> fetch_toUpdate_AllActionTask_List(List<Action_Task__c> currentTasks, List<Action_Task__c> clonedTasks)
    {
		List<Action_Task__c> output = new List<Action_Task__c>();
		if(currentTasks!=null && clonedTasks!=null)
		{
			integer counter = 0;
			for(Action_Task__c currentTask : currentTasks)
			{
				if(currentTask!=clonedTasks[counter])
				{
					// apply record level automation
					// commented out by Tim Fabros for BR_017
					// currentTask = update_AutomationLogic(currentTask, clonedTasks[counter]);	
					output.add(currentTask);
				}
				counter++;
			}
		}
		return output;
    }

    /**
    * @description Update each ActionTask with automation logic
    * @param Id
    * @param Action_Task__c
    * @param Action_Task__c
    * @return Action_Task__c
    * @author louis.wang@bluewolf.com
    * @date 2015-07-21
    **/
    public static Action_Task__c update_AutomationLogic(Action_Task__c currentTask, Action_Task__c clonedTask)
    {
		Integer numberOfTasks = Integer.valueOf(currentTask.Number_Of_Tasks__c);
		Integer currentStep = Integer.valueOf(currentTask.Step_Number__c);
		Integer dueDateSLA = 0;
		if(currentTask.Due_Date_SLA__c!=null)
		{
			dueDateSLA = Integer.valueOf(currentTask.Due_Date_SLA__c);
		}

		if(currentTask.OwnerId!=clonedTask.OwnerId)
		{
			if(currentTask.OwnerId.getSobjectType()==User.SobjectType)
			{
				// When AssignedTo is updated to user, set AssignedDate to today
				currentTask.Task_Assigned_Date__c = System.Today();

				if(currentTask.Action_Task_Sub_Group__c==SETUP_ACTION_TASK)
				{
					if(currentStep==1)
					{
						// update Due Date based on SLA, if the 1st Step of Setup Task is assinged to a user
						currentTask.Due_Date__c = System.Today().addDays(dueDateSLA);
					}
				}
				else if(currentTask.Action_Task_Sub_Group__c==MONTHLY_ACTION_TASK)
				{
					for(Integer i=0; i<=11; i++)
					{
						if(currentStep==(1 + numberOfTasks * i))
						{
							// update Due Date based on SLA, if the 1st Step of Setup Task is assinged to a user
							currentTask.Due_Date__c = System.Today().addDays(dueDateSLA);
						}
					}
				}
			}
			else
			{
				// if it is set back to Queue, then clear out the AssignedDate
				currentTask.Task_Assigned_Date__c = null;

				if(currentTask.Action_Task_Sub_Group__c==SETUP_ACTION_TASK)
				{
					if(currentStep==1)
					{
						// update Due Date based on SLA, if the 1st Step of Setup Task is assinged to a user
						currentTask.Due_Date__c = null;
					}
				}
				else if(currentTask.Action_Task_Sub_Group__c==MONTHLY_ACTION_TASK)
				{
					for(Integer i=0; i<=11; i++)
					{
						if(currentStep==(1 + numberOfTasks * i))
						{
							// update Due Date based on SLA, if the 1st Step of Setup Task is assinged to a user
							currentTask.Due_Date__c = null;
						}
					}
				}
			}
		}

		if(currentTask.Action_Task_Status__c!=clonedTask.Action_Task_Status__c)
		{
			if(currentTask.Action_Task_Status__c==COMPLETED_ACTION_TASK) 
			{
				// When Completed, set CompletedDate to today
				currentTask.Task_Completed_Date__c = System.Today();
			}
			else
			{
				// if it is set to something else, then clear out the CompletedDate
				currentTask.Task_Completed_Date__c = null;	
			}
		}
		Action_Task__c output = currentTask;
		return output;
    }

    /**
    * @description Generate the Action Task List based on wizard input
    * @param Id
    * @param String
    * @param String
    * @param Map<String,String>
    * @param String
    * @return List<Action_Task__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-07-20
    **/
    public static List<Action_Task__c> generate_toInsert_AllActionTask_List(Id actionPlanId, 
    																		String actionTaskGroup, 
    																		String actionTaskSubGroup, 
    																		Map<String,String> recordTypeMap, 
    																		String actionPlanPeriod,
    																		Date actionPlanStartDate)
    {
    	List<Action_Task__c> output = new List<Action_Task__c>();
    	List<Action_Task__c> adminDataList = new List<Action_Task__c>();
    	if(actionTaskGroup!=null && actionTaskSubGroup!=null)
    	{
	    	adminDataList = [SELECT Id, Name, 
	    					Action_Plan__c,
	    					Action_Task_Name__c,
	    					Action_Task_Status__c,
	    					Action_Task_Group__c,
	    					Action_Task_Sub_Group__c,
	    					First_Task__c, First_Task__r.Due_Date__c,
	    					RecordTypeId,
	    					Due_Date__c, 
	    					Due_Date_SLA__c,
	    					Number_Of_Tasks__c,  
	    					Note__c, 				
	    					OwnerId, Owner.Name, Owner.Type,
	    					Step_Number__c,
	    					Target_Month__c
	    				FROM Action_Task__c
	    				WHERE RecordTypeId =: recordTypeMap.get(RECORDTYPE_ADMIN_DATA)
	    				AND Action_Task_Group__c =: actionTaskGroup
	    				AND Action_Task_Sub_Group__c =: actionTaskSubGroup
	    				ORDER BY Step_Number__c];
	    	// deepclone - ignoring Id, system timestamps, auto number
	    	output = adminDataList.deepClone(false, false, false);
	    	output = update_WizardLogic(actionPlanId, output, actionTaskGroup, actionTaskSubGroup, recordTypeMap, actionPlanPeriod, actionPlanStartDate);
		}
    	return output;
    }

    /**
    * @description Update each New ActionTask with automation logic, generated from Wizard
    * @param Id
    * @param List<Action_Task__c>
    * @param String
    * @param String
    * @return List<Action_Task__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-07-21
    **/
    public static List<Action_Task__c> update_WizardLogic(Id actionPlanId, 
    														List<Action_Task__c> newTasks, 
    														String actionTaskGroup, 
    														String actionTaskSubGroup, 
    														Map<String,String> recordTypeMap, 
    														String actionPlanPeriod,
    														Date actionPlanStartDate)
    {
		List<Action_Task__c> output = new List<Action_Task__c>();
		if(actionPlanId!=null && newTasks!=null)
		{
			integer newTasks_Size = newTasks.size();
			integer actionPlanPeriod_Integer = 0;
			if(actionTaskSubGroup==MONTHLY_ACTION_TASK)
			{
				actionPlanPeriod_Integer = parse_ActionPlanPeriod(actionPlanPeriod);
			}

			Id NewsXtendQueueId = fetch_NewsXtendQueueId();
			for(Action_Task__c at : newTasks)
			{

				if(actionTaskSubGroup==MONTHLY_ACTION_TASK)
				{
					// only need to create for different month if period is 2 months or more
					// modified by Tim Fabros 2015-10-15: BR-008
					// if(actionPlanPeriod_Integer>=2)
					if (actionPlanPeriod_Integer >= 1)
					{
						at.Action_Plan__c = actionPlanId;
						at.RecordTypeId = recordTypeMap.get(RECORDTYPE_GENERAL_DATA);
						at.OwnerId = NewsXtendQueueId;
						at.Number_Of_Tasks__c = newTasks_Size;
						at.Target_Date__c = actionPlanStartDate;

						for(integer i = 0; i < actionPlanPeriod_Integer-1; i++)
						{
							Action_Task__c newAt = at.clone(false, true, false, false);
							newAt.Step_Number__c = newAt.Step_Number__c + (newTasks_Size * i);
							newAt.Target_Date__c = newAt.Target_Date__c.addMonths(i + 1);
							newAt.Number_Of_Tasks__c = newTasks_Size;
							output.add(newAt);
						}
					}
				}
				else if(actionTaskSubGroup==SETUP_ACTION_TASK)
				{
					at.Action_Plan__c = actionPlanId;
					at.RecordTypeId = recordTypeMap.get(RECORDTYPE_GENERAL_DATA);
					at.OwnerId = NewsXtendQueueId;
					at.Number_Of_Tasks__c = newTasks_Size;
					output.add(at);
				}
			}
		}
		return output;
	}

    /**
    * @description Fetch record types
    * @param n/a
    * @return map<string,string> applicable recordtype maps
    * @author louis.wang@bluewolf.com
    * @date 2015-04-07
    **/
    public static map<String,String> fetch_RecordTypeMap()
    {
        map<String,String> output = new map<String,String>();
        for(RecordType rt : [SELECT Id, DeveloperName, SobjectType, IsActive, Name 
                                FROM RecordType
                                WHERE IsActive=true])
        {
            output.put(rt.SobjectType+'-'+rt.DeveloperName, rt.Id);
        }
        return output;
    }	

    /**
    * @description Fetch NewsXtend Queue Id
    * @param n/a
    * @return Id
    * @author louis.wang@bluewolf.com
    * @date 2015-04-07
    **/
    public static Id fetch_NewsXtendQueueId()
    {
    	Id output;
    	List<Group> qList = [SELECT Id, DeveloperName, Name, Type 
								FROM Group
								WHERE Type = 'Queue'
								AND DeveloperName =: NEWSXTEND_QUEUE];
		if(!qList.IsEmpty()) 
		{
			output = qList[0].Id;
		}
    	return output;
    }

    /**
    * @description Fetch integer portion out from picklist 
    * @param String
    * @return integer
    * @author louis.wang@bluewolf.com
    * @date 2015-07-21
    **/
	public static Integer parse_ActionPlanPeriod(String actionPlanPeriod)
	{
		Integer output = 0;
		if(actionPlanPeriod!=null)
		{
			if(actionPlanPeriod==ACTIONPLAN_PERIOD_1MONTH)
			{
				output = 1;
			}
			else
			{
				// trim out the 'months' string to obtain the integer portion
				output = Integer.valueOf(actionPlanPeriod.mid(0,actionPlanPeriod.length()-7));
			}
		}
		return output;
	}

	/**
     * @description Update each New ActionTask with the preceding task. 
     *
     * @param 		List<Action_Task__c>
     * @return 		List<Action_Task__c>
     * @author 		timothy.fabros@bluewolf.com
     * @date 		2015-10-14
    **/
    public static List<Action_Task__c> update_lastActionTask(List<Action_Task__c> newTasks)
    {
    	for (Integer i = 1; i<newTasks.size(); i++) {
    		newTasks[i].Previous_Task__c = newTasks[i-1].Id;
    		System.debug(LoggingLevel.ERROR, '@Action_Task Updated: ' + newTasks[i].Name + ' SEQUENCE: ' + newTasks[i].Step_Number__c);
    		System.debug(LoggingLevel.ERROR, '@Action_Task Previous: ' + newTasks[i-1].Name + ' SEQUENCE: ' + newTasks[i-1].Step_Number__c);
    		System.debug(LoggingLevel.ERROR, '@iteration number: ' + i);
    	}

    	return newTasks;
    }

	/**
	 * @description Update each New ActionTask with First_Task 
	 * @param List<Action_Task__c>
	 * @param String
	 * @return List<Action_Task__c>
	 * @author louis.wang@bluewolf.com
	 * @date 2015-07-21
	**/
	public static List<Action_Task__c> update_FirstTask(List<Action_Task__c> newTasks, String actionTaskSubGroup)
	{
		List<Action_Task__c> output = new List<Action_Task__c>();
		if(newTasks!=null && !newTasks.IsEmpty())
		{
			// make the list to order by Step_Number (SOQL query)
			// commented out by Tim Fabros 2015-10-14
			// newTasks = reorder_ActionTask_List(newTasks);

			Integer numberOfTasks = 0;
			if(newTasks[0].Number_Of_Tasks__c!=null)
			{
				numberOfTasks = Integer.valueOf(newTasks[0].Number_Of_Tasks__c);
			}

			// Determine First Task, so it can be used for Due Date SLA updates
			Action_Task__c firstTask;
			Action_Task__c firstTask_month2;
			Action_Task__c firstTask_month3;
			Action_Task__c firstTask_month4;
			Action_Task__c firstTask_month5;
			Action_Task__c firstTask_month6;
			Action_Task__c firstTask_month7;
			Action_Task__c firstTask_month8;
			Action_Task__c firstTask_month9;
			Action_Task__c firstTask_month10;
			Action_Task__c firstTask_month11;
			Action_Task__c firstTask_month12;

			Integer counter = 1;
			for(Action_Task__c at : newTasks)
			{
				if(actionTaskSubGroup==SETUP_ACTION_TASK)
				{
					if(at.Step_Number__c==1) 
					{
						firstTask = at;
					}
					else
					{
						// only second task onwards can point to first task.
						//   first task cannot self point to itself, and will cause DML error
						at.First_Task__c = firstTask.Id;
						output.add(at);
					}
				}
				else if(actionTaskSubGroup==MONTHLY_ACTION_TASK)
				{
					// for monthly task, need to loop through in order to determie the first task for each month
					if(at.Step_Number__c==(1 + numberOfTasks * 0))
					{
						firstTask = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 0) && at.Step_Number__c<(1 + numberOfTasks * 1))
					{
						at.First_Task__c = firstTask.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 1))
					{
						firstTask_month2 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 1) && at.Step_Number__c<(1 + numberOfTasks * 2))
					{
						at.First_Task__c = firstTask_month2.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 2))
					{
						firstTask_month3 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 2) && at.Step_Number__c<(1 + numberOfTasks * 3))
					{
						at.First_Task__c = firstTask_month3.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 3))
					{
						firstTask_month4 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 3) && at.Step_Number__c<(1 + numberOfTasks * 4))
					{
						at.First_Task__c = firstTask_month4.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 4))
					{
						firstTask_month5 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 4) && at.Step_Number__c<(1 + numberOfTasks * 5))
					{
						at.First_Task__c = firstTask_month5.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 5))
					{
						firstTask_month6 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 5) && at.Step_Number__c<(1 + numberOfTasks * 6))
					{
						at.First_Task__c = firstTask_month6.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 6))
					{
						firstTask_month7 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 6) && at.Step_Number__c<(1 + numberOfTasks * 7))
					{
						at.First_Task__c = firstTask_month7.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 7))
					{
						firstTask_month8 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 7) && at.Step_Number__c<(1 + numberOfTasks * 8))
					{
						at.First_Task__c = firstTask_month8.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 8))
					{
						firstTask_month9 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 8) && at.Step_Number__c<(1 + numberOfTasks * 9))
					{
						at.First_Task__c = firstTask_month9.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 9))
					{
						firstTask_month10 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 9) && at.Step_Number__c<(1 + numberOfTasks * 10))
					{
						at.First_Task__c = firstTask_month10.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 10))
					{
						firstTask_month11 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 10) && at.Step_Number__c<(1 + numberOfTasks * 11))
					{
						at.First_Task__c = firstTask_month11.Id;
						output.add(at);
					}
					else if(at.Step_Number__c==(1 + numberOfTasks * 11))
					{
						firstTask_month12 = at;
					}
					else if(at.Step_Number__c>(1 + numberOfTasks * 11) && at.Step_Number__c<(1 + numberOfTasks * 12))
					{
						at.First_Task__c = firstTask_month12.Id;
						output.add(at);
					}	
				}
				counter++;
			}
		}
		return output;    	
    }

    /**
    * @description Re-sequence the applicable Action Task List based on Step_Number
    * @param List<Action_Task__c>
    * @return List<Action_Task__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-07-22
    **/
    public static List<Action_Task__c> reorder_ActionTask_List(List<Action_Task__c> atList)
    {
    	List<Action_Task__c> output = new List<Action_Task__c>();
    	if(atList!=null)
    	{
	    	output = [SELECT Id, Name, 
	    					Action_Plan__c,
	    					Action_Task_Name__c,
	    					Action_Task_Status__c,
	    					Action_Task_Group__c,
	    					Action_Task_Sub_Group__c,
	    					First_Task__c, First_Task__r.Due_Date__c,
	    					RecordTypeId,
	    					Due_Date__c, 
	    					Due_Date_SLA__c, 
	    					Number_Of_Tasks__c, 
	    					Note__c, 				
	    					OwnerId, Owner.Name, Owner.Type,
	    					Step_Number__c,
	    					Target_Month__c,
	    					Previous_Task__c
	    				FROM Action_Task__c
	    				WHERE Id IN : atList
	    				ORDER BY Step_Number__c ASC];
		}
    	return output;
    } 

    /**
    * @description Update Due Date for ActionTask that belongs to same Group-SubGroup-Month combination
    * @param List<Action_Task__c>
    * @return List<Action_Task__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-07-22
    **/
    public static List<Action_Task__c> update_DueDate(List<Action_Task__c> newTasks)
    {
		List<Action_Task__c> output = new List<Action_Task__c>();
		if(newTasks!=null)
		{
	    	// query again from DB
			newTasks = reorder_ActionTask_List(newTasks);

			for(Action_Task__c at : newTasks)
			{
				// Parent won't have First_Task lookup, so skip it
				if(at.First_Task__c!=null)
				{
					Date parentDueDate = at.First_Task__r.Due_Date__c;
					Date childDueDate = at.Due_Date__c;
					if(parentDueDate!=childDueDate)
					{
						at.Due_Date__c = parentDueDate;
						output.add(at);
					}
				}
			}
		}
		return output;
    }

    /**
    * @description Update ActionTask to Cancelled
    *				If ActionPlan is set to Cancelled, set every action task status to cancelled, 
    *					if it is not currently completed
    * @param List<Action_Task__c>
    * @return List<Action_Task__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-07-22
    **/
    public static List<Action_Task__c> update_CancelledStatus(List<Action_Task__c> newTasks)
    {
		List<Action_Task__c> output = new List<Action_Task__c>();
		if(newTasks!=null)
		{
	    	// query again from DB
			newTasks = reorder_ActionTask_List(newTasks);

			for(Action_Task__c at : newTasks)
			{
				String actionTaskStatus = at.Action_Task_Status__c;
				if(actionTaskStatus!=ACTIONTASK_STATUS_COMPLETED && actionTaskStatus!=ACTIONTASK_STATUS_CANCELLED)
				{	
					at.Action_Task_Status__c = ACTIONTASK_STATUS_CANCELLED;
					output.add(at);
				}
			}
		}
		return output;
    }

    /**
    * @description Decide whether the current user can delete Action Plan record
    * @param Id
    * @return boolean
    * @author louis.wang@bluewolf.com
    * @date 2015-07-23
    **/
    public static boolean fetch_CanDelete(Id apId)
    {
    	boolean output = false;
    	if(apId!=null)
    	{
			List<UserRecordAccess> accessList = [SELECT HasDeleteAccess, HasEditAccess, HasReadAccess, RecordId 
													FROM UserRecordAccess 
													WHERE RecordId =: apId 
													AND UserId =: UserInfo.getUserId()];
			if(!accessList.isEmpty())
			{
				output = accessList[0].HasDeleteAccess;
			}													
    	}
    	return output;
    }

    /**
    * @description Decide whether all the Monthly Tasks still Not Started
    * @param Id
    * @return boolean
    * @author louis.wang@bluewolf.com
    * @date 2015-09-25
    **/
    public static boolean check_isMonthlyTasksStarted(Id apId)
    {
    	boolean output = false;
    	if(apId!=null)
    	{
    		List<Action_Task__c> atList = [SELECT Id, Action_Task_Status__c 
    										FROM Action_Task__c
    										WHERE Action_Plan__c =: apId
    										AND Action_Task_Sub_Group__c =: MONTHLY_ACTION_TASK
    										AND Action_Task_Status__c !=: ACTIONTASK_STATUS_NOTSTARTED];
    		if(!atList.isEmpty())
    		{
    			output = true;
    		}
    	}
    	return output;
    }

    /**
    * @description Decide whether ActionPlanPeriod or ActionPlanStartDate is changed against DB
    * @param Id
    * @param string
	* @param date
    * @return boolean
    * @author louis.wang@bluewolf.com
    * @date 2015-09-25
    **/
    public static boolean check_isActionPlanChanged(Id apId, String actionPlanPeriod, Date actionPlanStartDate)
    {
    	boolean output = false;
    	if(apId!=null)
    	{
    		List<Action_Plan__c> apList = [SELECT Id, Action_Plan_Period__c, Start_Date__c 
    										FROM Action_Plan__c
    										WHERE Id =: apId];
    		if(!apList.isEmpty())
    		{
    			Action_Plan__c ap = apList[0];
    			if(ap.Action_Plan_Period__c!=actionPlanPeriod)
    			{
    				output = true;
    			}
    			if(ap.Start_Date__c!=actionPlanStartDate)
    			{
    				output = true;
    			}
    		}
    	}
    	return output;
    }

    /**
    * @description Generate a list of Monthly ActionTasks that needs to be deleted, due to change of ActionPlanPeriod
    * @param Id
    * @return list<Action_Task__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-09-25
    **/
    public static List<Action_Task__c> generate_toDelete_MonthlyTasks(Id apId)
    {
    	List<Action_Task__c> output = new List<Action_Task__c>();
    	if(apId!=null)
    	{
    		output = [SELECT Id, Action_Task_Group__c 
						FROM Action_Task__c
						WHERE Action_Plan__c =: apId
						AND Action_Task_Sub_Group__c =: MONTHLY_ACTION_TASK
						AND Action_Task_Status__c =: ACTIONTASK_STATUS_NOTSTARTED];
    	}
    	return output;
    }

    /**
    * @description Generate a List of Group Name that will be deleted, due to change of ActionPlanPeriod
    * @param List<Action_Task__c>
    * @return List<String>
    * @author louis.wang@bluewolf.com
    * @date 2015-09-25
    **/
    public static List<String> generate_toRecreate_MonthlyGroupNames(List<Action_Task__c> toDeleteList)
    {
		// get the Group name that will be deleted
		List<String> output = new List<String>();
    	if(toDeleteList!=null)
    	{
			Map<String, String> groupMap = new Map<String, String>();
    		for(Action_Task__c at : toDeleteList)
    		{
    			if(!groupMap.containsKey(at.Action_Task_Group__c))
    			{
    				groupMap.put(at.Action_Task_Group__c, at.Action_Task_Group__c);
    			}
    		}
    		for(String s : groupMap.keySet())
    		{
    			output.add(s);
    		}
    	}
    	return output;
    }

    /**
    * @description Determine if ActionPlanPeriod is changed from 1 month to larger value
    * @param Action_Plan__c
    * @return boolean
    * @author louis.wang@bluewolf.com
    * @date 2015-10-28
    **/
    public static boolean check_isActionPlanPeriodChangedToLarger(Action_Plan__c ap_Runtime)
    {
    	boolean output = false;
    	if(ap_Runtime!=null)
    	{
    		Id ap_Runtime_Id = ap_Runtime.Id;
    		String ap_Runtime_Period = ap_Runtime.Action_Plan_Period__c;
    		List<Action_Plan__c> apList = [SELECT Id, Action_Plan_Period__c
    										FROM Action_Plan__c
    										WHERE Id =: ap_Runtime_Id];
    		if(!apList.isEmpty())
    		{
    			Action_Plan__c ap_DB = apList[0];
    			if(ap_Runtime_Period!=ap_DB.Action_Plan_Period__c)
    			{
    				if(ap_Runtime_Period!=null && ap_Runtime_Period!=ACTIONPLAN_PERIOD_1MONTH)
    				{
    					output = true;
    				}
    			}
    		}
    	}
    	return output;
    }

    /**
    * @description Generate a List of Group Name that will re-create Monthly Tasks, if Setup Task exists and Monthly Task not exists
    * @param Id
    * @return List<String>
    * @author louis.wang@bluewolf.com
    * @date 2015-10-28
    **/
    public static List<String> generate_GroupNamesForMonthlyTasks(Id apId)
    {
		// get the Group name that will be deleted
		List<String> output = new List<String>();

    	if (apId != null)
    	{
            // fetch the ActionTasks that are now relating to this ActionPlan, as records could have been deleted or created already
	    	List<Action_Task__c> actionTasks = [SELECT Id
							    				     , Name 
							    				     , Action_Plan__c
							    				     , Action_Task_Name__c
							    				     , Action_Task_Status__c
							    				     , Action_Task_Group__c
							    				     , Action_Task_Sub_Group__c
							    				  FROM Action_Task__c
							    			     WHERE Action_Plan__c =: apId
							    			  ORDER BY Action_Task_Group__c
												     , Action_Task_Sub_Group__c
												     , Step_Number__c ASC];

			Map<String, Integer> numberOfMonthlyTasks_perGroup = new Map<String, Integer>();
			// get the list of GroupNames from Setup Tasks	
			for(Action_Task__c at : actionTasks)
			{
				String groupName = at.Action_Task_Group__c;
				String subGroupName = at.Action_Task_Sub_Group__c;
				if(subGroupName==SETUP_ACTION_TASK)
				{
					if(!numberOfMonthlyTasks_perGroup.containsKey(groupName))
					{
						numberOfMonthlyTasks_perGroup.put(groupName, 0);
					}
				}
			}
			// find out how many monthly tasks are in each Setup Tasks
			for(Action_Task__c at : actionTasks)
			{
				String groupName = at.Action_Task_Group__c;
				String subGroupName = at.Action_Task_Sub_Group__c;				 
				if(subGroupName==MONTHLY_ACTION_TASK)
				{
					if(numberOfMonthlyTasks_perGroup.containsKey(groupName))
					{
						Integer currentCount = numberOfMonthlyTasks_perGroup.get(groupName);
						numberOfMonthlyTasks_perGroup.put(groupName, currentCount+1);
					}
				}
			}												     
			// only retain GroupName that contains zero Monthly Tasks
			for(String groupName : numberOfMonthlyTasks_perGroup.keySet())
			{
				if(numberOfMonthlyTasks_perGroup.get(groupName)==0)
				{
					output.add(groupName);
				}
			}
		}
		return output;
    }

    /**
    * @description Fetch all the Month-Month Tasks and reset them
    * @param Id
    * @return list<Action_Task__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-11-13
    **/
    public static List<Action_Task__c> generate_Reset_ActionTask_List(Id apId)
    {
    	List<Action_Task__c> output = new List<Action_Task__c>();
    	if(apId!=null)
    	{
    		Map<String,String> recordTypeMap = fetch_RecordTypeMap();
    		// fetch all the Month-Month Tasks for this action plan
    		output = [SELECT Id, Action_Task_Group__c 
						FROM Action_Task__c
						WHERE Action_Plan__c =: apId
						AND Action_Task_Sub_Group__c =: MONTHLY_ACTION_TASK
	    				AND RecordTypeId =: recordTypeMap.get(RECORDTYPE_GENERAL_DATA)
	    				ORDER BY Step_Number__c];

			Id NewsXtendQueueId = fetch_NewsXtendQueueId();
			for(Action_Task__c at : output)
			{
				at.Action_Task_Status__c = ACTIONTASK_STATUS_NOTSTARTED;
				at.Note__c = null;
				at.OwnerId = NewsXtendQueueId;
			}	    				
    	}
    	return output;
    }
}
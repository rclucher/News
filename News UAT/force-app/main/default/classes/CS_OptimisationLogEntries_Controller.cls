public with sharing class CS_OptimisationLogEntries_Controller {
	public Id currentUserId{get;set;}
	public Integer searchNumberOfDays{get;set;}
	public String sortOrder{get;set;}
	public String errorMessage{get;set;}
	public Id submitLogTaskId{get;set;}
	public String submitLogMentions{get;set;}
	public String submitLogEntry{get;set;}
	public String submitActionGoal{get;set;}
	public Map<Id,Task> optimisationIdTaskMap;
	
	public String onChangeUpdateLogEntry{get;set;}
	public Id onChangeUpdateTaskId{get;set;}
	public String onChangeUpdateActionGoal{get;set;}
	public String onChangeUpdateMentions{get;set;}

	public List<OptimisationTaskWrapper> optimizationTaskWrapperList{get;set;}
	public List<OptimisationTaskWrapper> previousOptimizationTaskWrapperList{get;set;}
	private Map<Id,Map<Id,String>> mapTaskIdUserIdName = new Map<Id,Map<Id,String>>();

	public CS_OptimisationLogEntries_Controller() {
		currentUserId=UserInfo.getUserId();
		searchNumberOfDays=7;
		optimisationIdTaskMap=new Map<Id,Task>();
		sortOrder='ASC';
		errorMessage='';
		optimizationTaskWrapperList=new List<OptimisationTaskWrapper>();
		previousOptimizationTaskWrapperList=new List<OptimisationTaskWrapper>();
	}

	public List<OptimisationTaskWrapper> getOptimisationTaskWrapperList(){
		Set<Id> previousCompletedTasksIdSet=new Set<Id>();

		errorMessage='';
		String searchDaysQuery;
		if(searchNumberOfDays==-1){//This is to handle the value from the picklist related to the number of days from today when the task records must be queried
			searchDaysQuery='';
		}else{
		//	searchDaysQuery=' AND CreatedDate >= '+String.valueOf(DateTime.now().addDays(-searchNumberOfDays).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\''));
			//DateTime dT = DateTime.now().addDays(-searchNumberOfDays);
			Date activityDate = Date.today().addDays(-searchNumberOfDays);
			searchDaysQuery=' AND ActivityDate >= '+ String.valueOf(activityDate);
		}

		//Since each time that the table is rerendered there is a query to the database, the values that the user changed before the rerender must be kept stored so that they are not lost.
		previousOptimizationTaskWrapperList=optimizationTaskWrapperList;

		//This needed because each time the pageblock table is rerendered and the task records are queried again, the tasks that were completed should only be disabled and not disappear completely
		//and since they are not in Status "Completed", they must be somehow included in the list again
		for(OptimisationTaskWrapper taskWrapper:previousOptimizationTaskWrapperList){ 
			if(taskWrapper.disableOptimisationTask==true){
				previousCompletedTasksIdSet.add(taskWrapper.task.id);
			}
		}

		optimizationTaskWrapperList=new List<OptimisationTaskWrapper>();

		OptimisationTaskWrapper optimisationTaskWrapper;


		String taskQuery='SELECT Id,Subject,Item_Proposed_Start_Date__c,ActivityDate,Status,Completed_Date_Time__c,CSPOFA__Orchestration_Step__c,'+
								+'Campaign_Order__c,Campaign_Order__r.Name,Campaign_Order__r.Account__c,Campaign_Order__r.Account__r.Name,'+
								+'Campaign_Order__r.Assigned_Campaign_Manager__c,Campaign_Order__r.Assigned_Campaign_Manager__r.Name,'+
								+'Campaign_Order__r.Assigned_Campaign_Manager_For_QA__c,Campaign_Order__r.Assigned_Campaign_Manager_For_QA__r.Name,'+
								+'Campaign_Order__r.Assigned_Setup_Coordinator__c,Campaign_Order__r.Assigned_Setup_Coordinator__r.Name,'+
								+'Campaign_Order__r.Sales_Representative__c,Campaign_Order__r.Sales_Representative__r.Name,'+
								+'Campaign_Order__r.OwnerId,Campaign_Order__r.Owner.Name,'+
								+'Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_1__c,Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_1__r.Name,'+
								+'Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_2__c,Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_2__r.Name,'+
								+'Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_3__c,Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_3__r.Name,'+
								+'Campaign_Order__r.Opportunity__r.OwnerId,Campaign_Order__r.Opportunity__r.Owner.Name,'+

								+'Product_Order__c,Product_Order__r.Name,Product_Order__r.Product_Node__r.Name, '+
								+'Product_Order__r.Assigned_Fulfilment_Owner__c,Product_Order__r.Assigned_Fulfilment_Owner__r.Name, '+
								+'Product_Order__r.Assigned_Fulfilment_Owner_For_QA__c,Product_Order__r.Assigned_Fulfilment_Owner_For_QA__r.Name, '+
								+'Product_Order__r.Assigned_Social_Owner__c,Product_Order__r.Assigned_Social_Owner__r.Name, '+
								+'Product_Order__r.Assigned_Social_Owner_For_QA__c,Product_Order__r.Assigned_Social_Owner_For_QA__r.Name '+
								
							+'FROM Task WHERE Subject=\'Compile Summary Of Optimisations\' AND OwnerId=\''+currentUserId +'\' AND (Status=\'Not Started\' OR Id IN :previousCompletedTasksIdSet ) '+searchDaysQuery+
							+'ORDER BY ActivityDate '+sortOrder+ ', Campaign_Order__c';
							
							system.debug(taskQuery);

		List<Task> optimisationTaskList=Database.query(taskQuery);

		for(Task optimisationTask:optimisationTaskList){
			optimisationTaskWrapper=new OptimisationTaskWrapper(optimisationTask);
			optimizationTaskWrapperList.add(optimisationTaskWrapper);
			optimisationIdTaskMap.put(optimisationTask.id,optimisationTask);
		}

		//This is the place where the queried records are replaced by the ones that were in the table before the rerender
		if(!previousOptimizationTaskWrapperList.isEmpty()){
			for(OptimisationTaskWrapper optimisationWrapper:optimizationTaskWrapperList){
				for(OptimisationTaskWrapper previousOptimisationWrapper:previousOptimizationTaskWrapperList){
					if(optimisationWrapper.task.id==previousOptimisationWrapper.task.id){
						optimisationWrapper.logEntry=previousOptimisationWrapper.logEntry;
						optimisationWrapper.logActionGoal=previousOptimisationWrapper.logActionGoal;
						optimisationWrapper.disableOptimisationTask=previousOptimisationWrapper.disableOptimisationTask;
					}
				}
			}
		}

		//This is where the wrapper list is organized in order to get the lines for the Accounts and subsequent Product Orders
		if(!optimizationTaskWrapperList.isEmpty()){
			optimizationTaskWrapperList=OptimisationTaskWrapper.organizeOptimizationWrapper(optimizationTaskWrapperList);
		}

		return optimizationTaskWrapperList;
	}

	public List<SelectOption> getActionGoalItems() 
	{
		List<SelectOption> options = new List<SelectOption>();
		
		Schema.DescribeFieldResult fieldResult = Optimisation_Log__c.Goal_Of_Change__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry f : ple)
		{
			options.add(new SelectOption(f.getValue(), f.getLabel()));
		}

		return options;
	 }

	
	public void submitLog(){

		Set<Id> orchestrationStepIdSet=new Set<Id>();
		System.debug('***Submit log');
		System.debug('***submitLogEntry=' + submitLogEntry);
		System.debug('***submitActionGoal=' + submitActionGoal);
		System.debug('***submitLogTaskId=' + submitLogTaskId);
		System.debug('***submitLogMentions=' + submitLogMentions);



		Optimisation_Log__c optimisationLogToInsert=new Optimisation_Log__c(
			Comments__c=submitLogEntry,
			Product_Order__c=optimisationIdTaskMap.get(submitLogTaskId).Product_Order__c,
			Goal_Of_Change__c=submitActionGoal
			);
		
		List<Task> tasksToCompleteList=[SELECT Status,Completed_Date_Time__c,CSPOFA__Orchestration_Step__c FROM Task WHERE Id=:submitLogTaskId];

		for(Task task:tasksToCompleteList){
			task.Status = 'Completed';
			task.Completed_Date_Time__c=DateTime.now();
			orchestrationStepIdSet.add(task.CSPOFA__Orchestration_Step__c);
		}

		List<CSPOFA__Orchestration_Step__c> stepsToComplete = [SELECT Id, CSPOFA__Orchestration_Process__c, CSPOFA__Related_Object_ID__c,
																		CSPOFA__Status__c,CSPOFA__Completed_Date__c,CSPOFA__Message__c
																	FROM CSPOFA__Orchestration_Step__c
																	WHERE Id IN :orchestrationStepIdSet];						

		for(CSPOFA__Orchestration_Step__c step : stepsToComplete){
			step.CSPOFA__Status__c = 'Complete';
			step.CSPOFA__Completed_Date__c = Date.today();
			step.CSPOFA__Message__c = 'The related task was completed';
		}

		try {
			insert optimisationLogToInsert;

			/*
			for(OptimisationTaskWrapper optimisationWrapper : optimizationTaskWrapperList){
				System.debug('+++ optimisationWrapper.listOfMentions = ' + optimisationWrapper.listOfMentions);
				if(optimisationWrapper.task.id==submitLogTaskId && optimisationWrapper.listOfMentions != null){
					System.debug('+++ PostToChatter iz if');
					PostToChatter(optimisationLogToInsert, optimisationWrapper.listOfMentions);
				} else if (optimisationWrapper.task.id==submitLogTaskId && optimisationWrapper.listOfMentions != null && optimisationWrapper.listOfMentions.isEmpty()) {
					System.debug('+++ PostToChatter iz else');
					PostToChatter(optimisationLogToInsert, new List<String>());
				}
			}*/

			PostToChatter(optimisationLogToInsert,submitLogMentions);


			if(!stepsToComplete.isEmpty()){
				update stepsToComplete;
			}

			if(!tasksToCompleteList.isEmpty()){
				update tasksToCompleteList;
			}
			for(OptimisationTaskWrapper optimisationWrapper : optimizationTaskWrapperList){//mark the record that was submited so that when the rerender of the table occurs, the record don't disappear but only be disabled
				if(optimisationWrapper.task.id==submitLogTaskId){
					optimisationWrapper.disableOptimisationTask=true;
					optimisationWrapper.logActionGoal=submitActionGoal;
				}
			}

		} catch (Exception ex) {
			errorMessage=ex.getMessage();
		}
	}

	public void PostToChatter(Optimisation_Log__c optimisationLogToInsert, String strmentions){
			ConnectApi.FeedItemInput feedItemInput;
			ConnectApi.MentionSegmentInput mentionSegmentInput;
			ConnectApi.MessageBodyInput messageBodyInput;
			ConnectApi.LinkSegmentinput linksegment;
			ConnectApi.TextSegmentInput textSegmentInput;
			ConnectApi.ActionLinkDefinitionInput actionLinkDefinitionInput = new ConnectApi.ActionLinkDefinitionInput();

			feedItemInput = new ConnectApi.FeedItemInput();
			messageBodyInput = new ConnectApi.MessageBodyInput();
			messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
			linksegment = new ConnectApi.LinkSegmentinput();
			textSegmentInput = new ConnectApi.TextSegmentInput();

			textSegmentInput.text = 'TYPE OF CHANGE: \n  - ' + optimisationLogToInsert.Goal_Of_Change__c + '\n \n CHANGE ACTION/GOAL: \n - ' + optimisationLogToInsert.Comments__c + '\n \n OPTIMISATION LOG: \n';
			messageBodyInput.messageSegments.add(textSegmentInput);


			linksegment.url = '' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + optimisationLogToInsert.Id +'\n ';
			messageBodyInput.messageSegments.add(linksegment);

			List<String> mentions = strmentions.split(',');

			if (!mentions.isEmpty()) {
				for(String mention : mentions) {
					if (mention != '') {
						textSegmentInput = new ConnectApi.TextSegmentInput();
						textSegmentInput.text = '\n';
						messageBodyInput.messageSegments.add(textSegmentInput);
						mentionSegmentInput = new ConnectApi.MentionSegmentInput();
						mentionSegmentInput.Id = mention;
						messageBodyInput.messageSegments.add(mentionSegmentInput);

					}
				}
			}


	/*
	public void PostToChatter(Optimisation_Log__c optimisationLogToInsert, List<String> mentions){
		System.debug('+++ pozvan PostToChatter');
			ConnectApi.FeedItemInput feedItemInput;
			ConnectApi.MentionSegmentInput mentionSegmentInput;
			ConnectApi.MessageBodyInput messageBodyInput;
			ConnectApi.LinkSegmentinput linksegment;
			ConnectApi.ActionLinkDefinitionInput actionLinkDefinitionInput = new ConnectApi.ActionLinkDefinitionInput();

			feedItemInput = new ConnectApi.FeedItemInput();
			messageBodyInput = new ConnectApi.MessageBodyInput();
			messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
			linksegment = new ConnectApi.LinkSegmentinput();

			linksegment.url = '' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + optimisationLogToInsert.Product_Order__c +'\n \n';
			messageBodyInput.messageSegments.add(linksegment);

			if (!mentions.isEmpty()) {
				for(String mention : mentions) {
					System.debug('+++ mention = ' + mention);
					if (mention != '') {
						mentionSegmentInput = new ConnectApi.MentionSegmentInput();
						mentionSegmentInput.Id = mention;
						messageBodyInput.messageSegments.add(mentionSegmentInput);
					}
				}
			}


			FeedItem post = new FeedItem();
			post.ParentId = optimisationLogToInsert.Id;
			post.Type = 'LinkPost'; 
			post.Title = optimisationLogToInsert.Product_Order__r.Name;
			post.LinkURL = linksegment.url;
			if (!mentions.isEmpty()) {
				for(String mention : mentions) {
					post.Body += '@'+mention;
				}
			}
			
			insert post;




*/



			feedItemInput.body = messageBodyInput;
			feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
			feedItemInput.subjectId = optimisationLogToInsert.Product_Order__c;

			ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
	}

	public void UpdateLogEntryInWrapper(){

		for(OptimisationTaskWrapper optimisationWrapper:optimizationTaskWrapperList){
			if(optimisationWrapper.task.id==onChangeUpdateTaskId){
				optimisationWrapper.logEntry=onChangeUpdateLogEntry;
			}
		}
	}

	public void UpdateActionGoalInWrapper(){
		for(OptimisationTaskWrapper optimisationWrapper:optimizationTaskWrapperList){
			if(optimisationWrapper.task.id==onChangeUpdateTaskId){
				optimisationWrapper.logActionGoal=onChangeUpdateActionGoal;
			}
		}
	}

	public void UpdateMentionsInnWrapper(){
		for(OptimisationTaskWrapper optimisationWrapper:optimizationTaskWrapperList){
			if(optimisationWrapper.task.id==onChangeUpdateTaskId){
				optimisationWrapper.mentions=onChangeUpdateMentions;
			}
		}
	}



	public class OptimisationTaskWrapper{
		public Task task{get;set;}
		public Date createdDate{get;set;}
		public Id campaignOrderId{get;set;}
		public String campaignOrderName{get;set;}
		public Id accountId{get;set;}
		public String accountName{get;set;}
		public Id productOrderId{get;set;}
		public String productOrderName{get;set;}
		public Id campaignManagerId{get;set;}
		public String campaignManagerName{get;set;}
		public String logActionGoal{get;set;}
		public String logEntry{get;set;}
		public String mentions{get;set;}
		public List<String> listOfMentions{get;set;}
		public boolean disableOptimisationTask{get;set;}//this wrapper variable is used to know if the line should be disabled
		public boolean allowCreatingLogInLine{get;set;}//this wrapper variable is used to know if the wrapper line is related to a Product Order and if it related to a task that can be submitted.(If the line should contain changeable columns and a Submit button) 
		//public Map<Id,String> mapUserMentions {get;set;}
		public List<SelectOption> lstMentionUsers {get;set;}

		public OptimisationTaskWrapper(){
		}

		private void CreateUserMentionList(Task taskWrapper)
		{
			Map<Id,String>mapUser = new Map<Id,String>();
			lstMentionUsers = new List<SelectOption>();

			if (taskWrapper.Campaign_Order__r.Assigned_Campaign_Manager__c!=null) 
				if (!mapUser.containsKey(taskWrapper.Campaign_Order__r.Assigned_Campaign_Manager__c))
					mapUser.put(taskWrapper.Campaign_Order__r.Assigned_Campaign_Manager__c,taskWrapper.Campaign_Order__r.Assigned_Campaign_Manager__r.Name);


			if (taskWrapper.Campaign_Order__r.Assigned_Campaign_Manager_For_QA__c!=null) 
				if(!mapUser.containsKey(taskWrapper.Campaign_Order__r.Assigned_Campaign_Manager_For_QA__c))
					mapUser.put(taskWrapper.Campaign_Order__r.Assigned_Campaign_Manager_For_QA__c,taskWrapper.Campaign_Order__r.Assigned_Campaign_Manager_For_QA__r.Name);

			if (taskWrapper.Campaign_Order__r.Assigned_Setup_Coordinator__c!=null) 
				if(!mapUser.containsKey(taskWrapper.Campaign_Order__r.Assigned_Setup_Coordinator__c))
					mapUser.put(taskWrapper.Campaign_Order__r.Assigned_Setup_Coordinator__c,taskWrapper.Campaign_Order__r.Assigned_Setup_Coordinator__r.Name);

			if (taskWrapper.Campaign_Order__r.Sales_Representative__c!=null) 
				if(!mapUser.containsKey(taskWrapper.Campaign_Order__r.Sales_Representative__c))
					mapUser.put(taskWrapper.Campaign_Order__r.Sales_Representative__c,taskWrapper.Campaign_Order__r.Sales_Representative__r.Name);

			if (taskWrapper.Campaign_Order__r.OwnerId!=null) 
				if (!mapUser.containsKey(taskWrapper.Campaign_Order__r.OwnerId))
					mapUser.put(taskWrapper.Campaign_Order__r.OwnerId,taskWrapper.Campaign_Order__r.Owner.Name);

			if (taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_1__c!=null) 
				if(!mapUser.containsKey(taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_1__c))
					mapUser.put(taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_1__c,taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_1__r.Name);

			if (taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_2__c!=null) 
				if(!mapUser.containsKey(taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_2__c))
					mapUser.put(taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_2__c,taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_2__r.Name);

			if (taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_3__c!=null) 
				if(!mapUser.containsKey(taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_3__c))
					mapUser.put(taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_3__c,taskWrapper.Campaign_Order__r.Opportunity__r.NLM_Opportunity_Team_Member_3__r.Name);

			if (taskWrapper.Campaign_Order__r.Opportunity__r.OwnerId!=null) 
				if(!mapUser.containsKey(taskWrapper.Campaign_Order__r.Opportunity__r.OwnerId))
					mapUser.put(taskWrapper.Campaign_Order__r.Opportunity__r.OwnerId,taskWrapper.Campaign_Order__r.Opportunity__r.Owner.Name);

			if (taskWrapper.Product_Order__r.Assigned_Fulfilment_Owner__c!=null) 
				if(!mapUser.containsKey(taskWrapper.Product_Order__r.Assigned_Fulfilment_Owner__c))
					mapUser.put(taskWrapper.Product_Order__r.Assigned_Fulfilment_Owner__c,taskWrapper.Product_Order__r.Assigned_Fulfilment_Owner__r.Name);

			if (taskWrapper.Product_Order__r.Assigned_Fulfilment_Owner_For_QA__c!=null) 
				if(!mapUser.containsKey(taskWrapper.Product_Order__r.Assigned_Fulfilment_Owner_For_QA__c))
					mapUser.put(taskWrapper.Product_Order__r.Assigned_Fulfilment_Owner_For_QA__c,taskWrapper.Product_Order__r.Assigned_Fulfilment_Owner_For_QA__r.Name);

			if (taskWrapper.Product_Order__r.Assigned_Social_Owner__c!=null) 
				if(!mapUser.containsKey(taskWrapper.Product_Order__r.Assigned_Social_Owner__c))
					mapUser.put(taskWrapper.Product_Order__r.Assigned_Social_Owner__c,taskWrapper.Product_Order__r.Assigned_Social_Owner__r.Name);

			if (taskWrapper.Product_Order__r.Assigned_Social_Owner_For_QA__c!=null) 
				if(!mapUser.containsKey(taskWrapper.Product_Order__r.Assigned_Social_Owner_For_QA__c))
					mapUser.put(taskWrapper.Product_Order__r.Assigned_Social_Owner_For_QA__c,taskWrapper.Product_Order__r.Assigned_Social_Owner_For_QA__r.Name);


			if (mapUser.size()>0)
			{
				for (string Key : mapUser.keySet())
				{
					lstMentionUsers.add(new SelectOption(Key, mapUser.get(Key)));
				}
			}


			//lstMentionUsers.add(new SelectOption('1','Davor'));
		}


		public OptimisationTaskWrapper(Task taskWrapper){
			task = taskWrapper;
			createdDate = taskWrapper.ActivityDate;
			campaignOrderId = taskWrapper.Campaign_Order__c;
			campaignOrderName = taskWrapper.Campaign_Order__r.Name;
			accountId = taskWrapper.Campaign_Order__r.Account__c;
			accountName = taskWrapper.Campaign_Order__r.Account__r.Name;
			productOrderId = taskWrapper.Product_Order__c;
			productOrderName=taskWrapper.Product_Order__r.Name+' - '+taskWrapper.Product_Order__r.Product_Node__r.Name;
			campaignManagerId=taskWrapper.Campaign_Order__r.Assigned_Campaign_Manager__c;
			campaignManagerName=taskWrapper.Campaign_Order__r.Assigned_Campaign_Manager__r.Name;
			allowCreatingLogInLine=false;
			disableOptimisationTask=false;
			
			CreateUserMentionList(taskWrapper);
			
		}


		public List<OptimisationTaskWrapper> organizeOptimizationWrapper(List<OptimisationTaskWrapper> unorganizedWrapperList){
			List<OptimisationTaskWrapper> organizedWrapperList=new List<OptimisationTaskWrapper>();
			Date currentDate=null;
			Id currentCampaignOrderId=null;
			OptimisationTaskWrapper taskWrapper;

			for(OptimisationTaskWrapper unorganizedWrapper:unorganizedWrapperList){//The list is already ordered by Date and Campaign Order
				if(unorganizedWrapper.createdDate!=currentDate || unorganizedWrapper.campaignOrderId!=currentCampaignOrderId){//If the Date or Campaign Order changes when the table is being looped, a new line is inserted with the Date, Campaign Order and Account of the Product Orders that are shown next
					taskWrapper=new OptimisationTaskWrapper();
					taskWrapper.task=unorganizedWrapper.task;
					taskWrapper.createdDate=unorganizedWrapper.createdDate;
					taskWrapper.campaignOrderId = unorganizedWrapper.campaignOrderId;
					taskWrapper.campaignOrderName = unorganizedWrapper.campaignOrderName;
					taskWrapper.accountId = unorganizedWrapper.accountId;
					taskWrapper.accountName = unorganizedWrapper.accountName;
					taskWrapper.campaignManagerId = unorganizedWrapper.campaignManagerId;
					taskWrapper.campaignManagerName = unorganizedWrapper.campaignManagerName;
					taskWrapper.allowCreatingLogInLine=false;
					organizedWrapperList.add(taskWrapper);
					currentDate=unorganizedWrapper.createdDate;
					currentCampaignOrderId=unorganizedWrapper.campaignOrderId;
				}
				taskWrapper=new OptimisationTaskWrapper();
				taskWrapper.task=unorganizedWrapper.task;
				taskWrapper.productOrderId=unorganizedWrapper.productOrderId;
				taskWrapper.productOrderName = unorganizedWrapper.productOrderName;
				taskWrapper.logEntry=unorganizedWrapper.logEntry;
				taskWrapper.lstMentionUsers=unorganizedWrapper.lstMentionUsers;
				taskWrapper.logActionGoal=unorganizedWrapper.logActionGoal;
				taskWrapper.disableOptimisationTask=unorganizedWrapper.disableOptimisationTask;
				taskWrapper.allowCreatingLogInLine=true;
				organizedWrapperList.add(taskWrapper);
			}
			return organizedWrapperList;
		}
	}

	public class MyException extends Exception {}

}
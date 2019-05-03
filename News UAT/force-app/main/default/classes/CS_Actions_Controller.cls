/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Sep 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing class CS_Actions_Controller
{
	/***********************************************************************************************************
		Members
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Exception Classes & Enums
	public class X_Exception extends Exception{}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Singular
	public boolean	mp_bActionsExist				{get; set;}
	public string	mp_ActionId						{get; set;}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Collections
	public list<ActionWrapper> mp_liActions			{get; set;}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Wrapper classes
	public class ActionWrapper
	{
		public boolean		bShowEdit				{get; set;}
		public boolean		bShowDelete				{get; set;}
		public boolean		bShowInactivate			{get; set;}
		public Questionnaire_Action__c	Action		{get; set;}
		
		public ActionWrapper(Questionnaire_Action__c sAction, boolean showEdit, boolean showDelete, boolean showInactivate)
		{
			bShowEdit			= showEdit;
			bShowDelete			= showDelete;
			bShowInactivate		= showInactivate;
			Action				= sAction;
		}
	}

	/***********************************************************************************************************
		Constructor
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Our Constructor
	public CS_Actions_Controller()
	{
		mp_liActions = new list<ActionWrapper>();
		mp_bActionsExist = false;
	}


	public pageReference Init()
	{
		try
		{
			buildActionList();
			
			
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}
		
		return null;
	}


	/***********************************************************************************************************
		Button / link methods
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionEdit()
	{
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', mp_ActionId);

		pageReference pageRef = page.CS_ConfigureAction;
		pageRef.setRedirect(true);
		return pageRef;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionDelete()
	{
		try
		{
			// Get the record
			Questionnaire_Action__c sQuestionnaireAction = [ select id from Questionnaire_Action__c where id = : mp_ActionId][0];
	
			delete sQuestionnaireAction;
			
			// Delete any Rules
			list<Rule__c> li_RulestoDelete = [ select id from Rule__c where Questionnaire_Action__c = : mp_ActionId];
			
			if (!li_RulestoDelete.isEmpty())
				delete li_RulestoDelete;
			
			buildActionList();
	
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.ACTION_DELETED));
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionInactivate()
	{
		try
		{
			// Get the record
			Questionnaire_Action__c sQuestionnaireAction = [ select id, isActive__c from Questionnaire_Action__c where id = : mp_ActionId][0];
	
			// Update
			sQuestionnaireAction.isActive__c = false;
	
			update sQuestionnaireAction;

			buildActionList();
	
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.ACTION_INACTIVED));
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionNew()
	{
		pageReference pageRef = page.CS_ConfigureAction;
		pageRef.setRedirect(true);
		return pageRef;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference gotoQuestions()
	{
		pageReference pageRef = page.CS_Questions;
		pageRef.setRedirect(true);
		return pageRef;
	}


	/***********************************************************************************************************
		Helper methods
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void buildActionList()
	{
		mp_liActions = new list<ActionWrapper>();
		map<string, ActionWrapper> map_ActionWrappers = new map<string, ActionWrapper>();
		map<id, Questionnaire_Action__c> map_Actions = new map<id, Questionnaire_Action__c>();

		// First get the Actions
		for (Questionnaire_Action__c sQuestionnaireAction :	[	select	id,
																		Name,
																		isActive__c
																from	Questionnaire_Action__c
															])
		{
			map_Actions.put(sQuestionnaireAction.id, sQuestionnaireAction);
		}
		
		// Get the ids of Actions that are linked to Results
		set<id> set_ActionIdsWithResults = new set<id>();
		
		for (Questionnaire_Action_Result__c sQAR :	[	select	id,
																Questionnaire_Action__c
														from	Questionnaire_Action_Result__c
														where	Questionnaire_Action__c in : map_Actions.keySet()
													])
		{
			set_ActionIdsWithResults.add(sQAR.Questionnaire_Action__c);
		}
		
		// Now we can figure out which Actions have Results and populate the wrapper class accordingly
		for (Questionnaire_Action__c sQuestionnaireAction : map_Actions.values())
		{
			boolean bShowEdit			= true;
			boolean bShowDelete			= true;
			boolean bShowInactivate		= false;
			
			if (set_ActionIdsWithResults.contains(sQuestionnaireAction.id))
			{
				bShowDelete		= false;
				bShowInactivate	= true;
			}
			
			// Override booleans if the record is inactive
			if (!sQuestionnaireAction.isActive__c)
				bShowInactivate	= false;
			
			map_ActionWrappers.put(sQuestionnaireAction.Name, new ActionWrapper(sQuestionnaireAction, bShowEdit, bShowDelete, bShowInactivate));
		}
		
		// Sort by Action Name
		list<string> li_ActionNames = new list<string>(map_ActionWrappers.keySet());
		li_ActionNames.sort();
		
		for (string actionName : li_ActionNames)
		{
			mp_liActions.add(map_ActionWrappers.get(actionName));
		}
		
		if (mp_liActions.isEmpty())
			return;

		mp_bActionsExist = true;
	}

}
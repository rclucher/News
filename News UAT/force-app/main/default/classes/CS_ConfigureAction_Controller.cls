/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Sep 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing class CS_ConfigureAction_Controller
{
	/***********************************************************************************************************
		Members
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Exception Classes & Enums
	public class X_Exception extends Exception{}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Singular
	public string mp_SectionTitle							{get; set;}
	
	public Questionnaire_Action__c mp_Action				{get; set;}
	
	public string	mp_RuleId								{get; set;}
	public string	mp_InputOutput							{get; set;}
	
	public boolean	mp_bEditAction							{get; set;}
	public boolean	mp_bEditParameters						{get; set;}
	public boolean	mp_bEditRule							{get; set;}
	
	// Dummy Rule - not saved
	public Rule__c mp_Rule									{get; set;}
	

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Collections
	public list<RuleWrapper>	mp_liInputs					{get; set;}
	public list<RuleWrapper>	mp_liOutputs				{get; set;}
	
	private list<SelectOption>			m_liSections;
	private map<string, map<string, Question2__c>>	m_mapSectiontoQuestions;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Wrapper classes
	public class RuleWrapper
	{
		public boolean				bReadOnly				{get; set;}
		public Rule__c				Rule					{get; set;}
		public string				Section					{get; set;}
		public list<SelectOption>	li_Sections				{get; set;}
		public string				QuestionText			{get; set;}
		public string				QuestionId				{get; set;}
		public list<SelectOption>	li_Questions			{get; set;}
		
		public RuleWrapper(Rule__c sRule, boolean showEdit, list<SelectOption>	li_SectionsIn)
		{
			bReadOnly			= showEdit;
			Rule				= sRule;
			li_Sections			= new list<SelectOption>(li_SectionsIn);
			li_Questions		= new list<SelectOption>();
		}
	}

	public class ActionWrapper
	{
		public id					QuestionId				{get; set;}
		public string				ActionName				{get; set;}
		public string				QuestionText			{get; set;}
		
		public ActionWrapper(id qid, string ActionNameIn, string QuestionTextIn)
		{
			QuestionId			= qid;
			ActionName			= ActionNameIn;
			QuestionText		= QuestionTextIn;
		}
	}

	/***********************************************************************************************************
		Constructor and Init
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Our Constructor
	public CS_ConfigureAction_Controller()
	{
		mp_Rule = new Rule__c();
		mp_bEditAction		= true;
		mp_bEditParameters	= false;
		mp_bEditRule		= false;
		mp_RuleId			= null;
		
		mp_liInputs = new list<RuleWrapper>();
		mp_liOutputs = new list<RuleWrapper>();
	}

	public pageReference Init()
	{
		try
		{
			buildSectionPicklist();
			
			// Work out if we are creating or editing a record
			cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');

			string actionId;
			
			if (sP.contains('id'))
				actionId = (string)sP.get('id');

			// Are we editing an existing record?
			if (string.isBlank(actionId))
			{
				mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_CREATEACTION;
			
				mp_Action = new Questionnaire_Action__c();
			}
			else
			{
				mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_EDITACTION;
				
				// Retrieve the record
				list<Questionnaire_Action__c> li_Actions =
					[	select	id,
								Name,
								Description__c,
								isActive__c
						from	Questionnaire_Action__c
						where	id = : actionId
					];
				
				// Defensive code
				if (li_Actions.isEmpty())
				{
					mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_CREATEACTION;
			
					mp_Action = new Questionnaire_Action__c();
				}
				else
				{
					mp_Action = li_Actions[0];
					
					rebuildRuleLists();
					
					if (!mp_liInputs.isEmpty())
					{
						mp_Rule = mp_liInputs[0].Rule;
					}
					else if (!mp_liOutputs.isEmpty())
					{
						mp_Rule = mp_liOutputs[0].Rule;
					}
	
					mp_bEditAction = false;
					mp_bEditParameters = true;
				}
			}
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
	//	STEP 1 - create / edit an Action
	public pageReference actionSaveAction()
	{
		try
		{
			if (!validateAction())
				return null;

			// Save the record
			upsert mp_Action;
			
			mp_bEditAction = false;
			mp_bEditParameters = true;
			
			mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_EDITACTION;
			
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.RECORDSAVED));
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}
		
		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	public pageReference actionCancel()
	{
		CS_Questions_Utilities.clearSessionCache();
		
		pageReference pageRef = page.CS_Actions;
		pageRef.setRedirect(true);
		return pageRef;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionAddRule()
	{
		try
		{
			RuleWrapper RuleWrapper = new RuleWrapper(
				new Rule__c(
					Questionnaire_Action__c	= mp_Action.id,
					Service_Class_Name__c	= mp_Rule.Service_Class_Name__c,
					Service_Method_Name__c	= mp_Rule.Service_Method_Name__c,
					Input_Output__c			= mp_InputOutput
					),
				false,
				m_liSections);
			
			// Add to the displayed list
			if (mp_InputOutput == 'Input')
				mp_liInputs.add(RuleWrapper);
			else if (mp_InputOutput == 'Output')
				mp_liOutputs.add(RuleWrapper);
			
			mp_bEditRule = true;
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}
		
		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionEditRule()
	{
		try
		{
			if (mp_InputOutput == 'Input')
				mp_liInputs = editRule(mp_liInputs);
			else if (mp_InputOutput == 'Output')
				mp_liOutputs = editRule(mp_liOutputs);
			
			mp_bEditRule = true;
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}

	private list<RuleWrapper> editRule(list<RuleWrapper> li_RulesIn)
	{
		list<RuleWrapper> li_RulesOut = new list<RuleWrapper>();
			
		for (RuleWrapper RuleWrapper : li_RulesIn)
		{
			if (!string.isBlank(mp_RuleId) && RuleWrapper.Rule.id != mp_RuleId)
			{
				li_RulesOut.add(RuleWrapper);
				continue;
			}
			
			RuleWrapper.bReadOnly = false;

			RuleWrapper.li_Questions = new list<SelectOption>();
			RuleWrapper.li_Questions.add(new SelectOption(' ', 'Please select'));
			
			map<string, Question2__c> map_Questions = m_mapSectiontoQuestions.get(RuleWrapper.Section);
			
			// Sort
			list<string> li_Questions = new list<string>(map_Questions.keySet());
			li_Questions.sort();
			
			for (string questionText : li_Questions)
			{
				Question2__c sQuestion2 = map_Questions.get(questionText);
				
				RuleWrapper.li_Questions.add(new SelectOption(sQuestion2.Id, sQuestion2.Question_Text__c));
			}

			system.debug('*** RuleWrapper ***' + RuleWrapper);
				
			li_RulesOut.add(RuleWrapper);
		}
			
		return li_RulesOut;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionDeleteRule()
	{
		try
		{
			if (mp_InputOutput == 'Input')
				mp_liInputs = deleteRule(mp_liInputs);
			else if (mp_InputOutput == 'Output')
				mp_liOutputs = deleteRule(mp_liOutputs);
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}

	private list<RuleWrapper> deleteRule(list<RuleWrapper> li_RulesIn)
	{
		list<RuleWrapper> li_RulesOut = new list<RuleWrapper>();
			
		for (RuleWrapper RuleWrapper : li_RulesIn)
		{
			if (!string.isBlank(mp_RuleId) && RuleWrapper.Rule.id != mp_RuleId)
			{
				li_RulesOut.add(RuleWrapper);
				continue;
			}
			
			delete RuleWrapper.Rule;
		}
			
		return li_RulesOut;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionSaveRule()
	{
		try
		{
			if (!validateRule())
				return null;

			list<Rule__c> li_RulestoUpsert = new list<Rule__c>();
			
			if (mp_InputOutput == 'Input')
			{
				for (RuleWrapper RuleWrapper : mp_liInputs)
				{
					RuleWrapper.Rule.Question2__c = RuleWrapper.QuestionId;
					li_RulestoUpsert.add(RuleWrapper.Rule);
				}
			}
			else if (mp_InputOutput == 'Output')
			{
				for (RuleWrapper RuleWrapper : mp_liOutputs)
				{
					RuleWrapper.Rule.Question2__c = RuleWrapper.QuestionId;
					li_RulestoUpsert.add(RuleWrapper.Rule);
				}
			}
			
			if (!li_RulestoUpsert.isEmpty())
				upsert li_RulestoUpsert;
			
			// Rebuild the display
			rebuildRuleLists();

			mp_bEditRule = false;
			
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.RECORDSAVED));
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionCancelEditRule()
	{
		try
		{
			// Rebuild the display
			rebuildRuleLists();

			mp_bEditRule = false;
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	public pageReference actionRebuildQuestionPicklist()
	{
		try
		{
			if (mp_InputOutput == 'Input')
				mp_liInputs = rebuildQuestionPicklist(mp_liInputs);
			else if (mp_InputOutput == 'Output')
				mp_liOutputs = rebuildQuestionPicklist(mp_liOutputs);
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private list<RuleWrapper> rebuildQuestionPicklist(list<RuleWrapper> li_RulesIn)
	{
		list<RuleWrapper> li_RulesOut = new list<RuleWrapper>();
			
		for (RuleWrapper RuleWrapper : li_RulesIn)
		{
			if (!string.isBlank(mp_RuleId) && RuleWrapper.Rule.id != mp_RuleId)
			{
				li_RulesOut.add(RuleWrapper);
				continue;
			}
			
			RuleWrapper.li_Questions = new list<SelectOption>();
			RuleWrapper.li_Questions.add(new SelectOption(' ', 'Please select'));
			
			map<string, Question2__c> map_Questions = m_mapSectiontoQuestions.get(RuleWrapper.Section);
			
			// Sort
			list<string> li_Questions = new list<string>(map_Questions.keySet());
			li_Questions.sort();
			
			for (string questionText : li_Questions)
			{
				Question2__c sQuestion2 = map_Questions.get(questionText);
				
				RuleWrapper.li_Questions.add(new SelectOption(sQuestion2.Id, sQuestion2.Question_Text__c));
			}
				
			li_RulesOut.add(RuleWrapper);
		}
			
		return li_RulesOut;
	}

	/***********************************************************************************************************
		Helper methods
	***********************************************************************************************************/

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void buildSectionPicklist()
	{
		// Get the Section values
		set<string> set_SectionNames = new set<string>();
		m_mapSectiontoQuestions = new map<string, map<string, Question2__c>>();
		
		for (Question2__c sQuestion :	[	select	Section__c,
													Question_Text__c
											from	Question2__c
											where	isActive__c = true
											order by Question_Text__c
										])
		{
			set_SectionNames.add(sQuestion.Section__c);
			
			map<string, Question2__c> map_Questions	= m_mapSectiontoQuestions.containsKey(sQuestion.Section__c)
													? m_mapSectiontoQuestions.get(sQuestion.Section__c)
													: new map<string, Question2__c>();
			
			map_Questions.put(sQuestion.Question_Text__c, sQuestion);
			m_mapSectiontoQuestions.put(sQuestion.Section__c, map_Questions);
		}
		
		// Sort Section names
		list<string> li_SectionNames = new list<string>(set_SectionNames);
		li_SectionNames.sort();
		
		// Build the picklist
		m_liSections = new list<SelectOption>();
		m_liSections.add(new SelectOption(' ', 'Please select'));
		
		for (string sectionName : li_SectionNames)
		{
			m_liSections.add(new SelectOption(sectionName, sectionName));
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private boolean validateAction()
	{
		// Basic validation
		boolean bIsValid = true;		
		
		// Required data
		if (string.isBlank(mp_Action.Name))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ACTIONNAME));
			bIsValid = false;
		}

		if (mp_Rule.Service_Class_Name__c == null)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_CLASSNAME));
			bIsValid = false;
		}

		if (mp_Rule.Service_Method_Name__c == null)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_METHODNAME));
			bIsValid = false;
		}
		
		return bIsValid;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private boolean validateRule()
	{
		boolean bIsValid = true;
		
		if (mp_InputOutput == 'Input')
		{
			bIsValid = validateRule(mp_liInputs);
		}
		else if (mp_InputOutput == 'Output')
		{
			bIsValid = validateRule(mp_liOutputs);
			
			if (bIsValid == false)
				return bIsValid;
			
			// Check that we do not have two Actions pointing to the same Answer
			map<id, ActionWrapper> map_RuletoActions = new map<id, ActionWrapper>();
			
			for (Rule__c sRule :	[	select	id,
												Question2__c,
												Question2__r.Question_Text__c,
												Questionnaire_Action__r.Name
										from	Rule__c
										where	Input_Output__c = 'Output'
									])
			{
				map_RuletoActions.put(sRule.id, new ActionWrapper(
					sRule.Question2__c,
					sRule.Questionnaire_Action__r.Name,
					sRule.Question2__r.Question_Text__c));
			}
			
			for (RuleWrapper RuleWrapper : mp_liOutputs)
			{
				for (id RuleId : map_RuletoActions.keySet())
				{
					ActionWrapper ActionWrapper = map_RuletoActions.get(RuleId);
					
					if (ActionWrapper.QuestionId == RuleWrapper.QuestionId &&
						RuleId != RuleWrapper.Rule.id)
					{
						string errorMsg = 'The Action ' +
							ActionWrapper.ActionName +
							' is already populating the Answer to the Question ' +
							ActionWrapper.QuestionText;
							
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
						bIsValid = false;
					}
				}
			}
		}

		return bIsValid;
	}

	private boolean validateRule(list<RuleWrapper> li_RulesIn)
	{
		boolean bIsValid = true;
		
		for (RuleWrapper RuleWrapper : li_RulesIn)
		{
			if (RuleWrapper.bReadOnly)
				continue;
			
			// Required data
			if (string.isBlank(RuleWrapper.Section))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ACTIONRULESECTION));
				bIsValid = false;
			}
	
			if (string.isBlank(RuleWrapper.QuestionId))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ACTIONRULEQUESTION));
				bIsValid = false;
			}
	
			if (string.isBlank(RuleWrapper.Rule.Parameter_Label__c))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ACTIONRULELABEL));
				bIsValid = false;
			}
		}
		
		return bIsValid;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void rebuildRuleLists()
	{
		if (mp_Action.id == null)
			return;
		
		mp_liInputs = new list<RuleWrapper>();
		mp_liOutputs = new list<RuleWrapper>();
		
		map<string, Rule__c> map_Rules = new map<string, Rule__c>();

		for (Rule__c sRule :	[	select	id,
											Question2__c,
											Questionnaire_Action__c,
											Service_Class_Name__c,
											Service_Method_Name__c,
											Parameter_Label__c,
											Input_Output__c,
											isActive__c
									from	Rule__c
									where	Questionnaire_Action__c = : mp_Action.id
								])
		{
			map_Rules.put(sRule.Parameter_Label__c, sRule);
		}
		
		// Sort
		list<string> li_ParameterLabels = new list<string>(map_Rules.keySet());
		li_ParameterLabels.sort();
		
		for (string parameterLabel : li_ParameterLabels)
		{
			Rule__c sRule = map_Rules.get(parameterLabel);

			RuleWrapper RuleWrapper = new RuleWrapper(
				sRule,
				true,
				m_liSections);
			
			// Crunch through the master collection to get the Section Name and Question Text
			for (string sectionName : m_mapSectiontoQuestions.keySet())
			{
				map<string, Question2__c> map_Questions	= m_mapSectiontoQuestions.get(sectionName);
				
				for (string questionText : map_Questions.keySet())
				{
					Question2__c sQuestion2 = map_Questions.get(questionText);
					
					if (sQuestion2.id == sRule.Question2__c)
					{
						RuleWrapper.QuestionId		= sQuestion2.id;
						RuleWrapper.Section			= sectionName;
						RuleWrapper.QuestionText	= questionText;
						
						break;
					}
				}
			}
			
			if (sRule.Input_Output__c == 'Input')
			{
				mp_liInputs.add(RuleWrapper);
			}
			else if (sRule.Input_Output__c == 'Output')
			{
				mp_liOutputs.add(RuleWrapper);
			}
		}
	}

}
/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Jun 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing class CS_Questions_Controller
{
	/***********************************************************************************************************
		Members
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Exception Classes & Enums
	public class X_Exception extends Exception{}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Singular
	public boolean	mp_bQuestionsExist				{get; set;}
	public string	mp_QuestionId					{get; set;}

	// List display variables
	public integer  m_iStartList;
	public integer  mp_iListSize					{get; set;}
	public integer  m_iDefaultListSize				= 20;
	public integer  mp_iPageNumber					{get; set;}
	public integer  mp_iTotalPages					{get; set;}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Collections
	public list<QuestionWrapper> m_liQuestions;
	public list<QuestionWrapper> mp_liQuestions		{get; set;}
	
	public map<id, set<id>> m_mapQuestiontoRules;


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Wrapper classes
	public class QuestionWrapper
	{
		public boolean		bShowEdit				{get; set;}
		public boolean		bShowDelete				{get; set;}
		public boolean		bShowInactivate			{get; set;}
		public Question2__c	Question				{get; set;}
		
		public QuestionWrapper(Question2__c sQuestion, boolean ShowEdit, boolean showDelete, boolean showInactivate)
		{
			bShowEdit			= ShowEdit;
			bShowDelete			= showDelete;
			bShowInactivate		= showInactivate;
			Question			= sQuestion;
		}
	}

	/***********************************************************************************************************
		Constructor
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Our Constructor
	public CS_Questions_Controller()
	{
		mp_liQuestions = new list<QuestionWrapper>();
		mp_bQuestionsExist = false;
	}


	public pageReference Init()
	{
		try
		{
			buildQuestionList();
			
			cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
			
			string strPageNo;
			
			if (sP.contains('pageNo'))
				strPageNo	= (string)sP.get('pageNo');
			
			if (!string.isBlank(strPageNo))
			{
				mp_iPageNumber  = integer.valueOf(strPageNo);
				m_iStartList   = (mp_iPageNumber - 1) * m_iDefaultListSize;
				mp_iListSize	= (m_iStartList + m_iDefaultListSize) < m_liQuestions.size()
								? m_iDefaultListSize
								: m_liQuestions.size() - m_iStartList;
				
				for (integer i = m_iStartList; i < (m_iStartList + mp_iListSize); i++)
					mp_liQuestions.add(m_liQuestions[i]);
			}
			else
			{
				// Initialise page indices
				mp_iPageNumber  = 1;
				m_iStartList   = 0;
	
				return showFirstPage();
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
	//
	public pageReference actionEdit()
	{
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', mp_QuestionId);
		sP.put('pageNo', string.valueOf(mp_iPageNumber));

		pageReference pageRef = page.CS_Question;
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
			Question2__c sQuestion = [ select id from Question2__c where id = : mp_QuestionId][0];
	
			delete sQuestion;
			
			// Delete any child Rules as well
			list<Rule__c> li_RulestoDelete = new list<Rule__c>();

			if (m_mapQuestiontoRules.containsKey(mp_QuestionId))
			{
				set<id> set_RuleIds	= m_mapQuestiontoRules.get(mp_QuestionId);
				
				for (Rule__c sRule : [	select	id
										from	Rule__c
										where	id in : set_RuleIds
									])
				{
					li_RulestoDelete.add(sRule);
				}
			}
	
			if (!li_RulestoDelete.isEmpty())
				delete li_RulestoDelete;
			
			buildQuestionList();
	
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.QUESTION_DELETED));
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
			Question2__c sQuestion2 = [ select id, isActive__c from Question2__c where id = : mp_QuestionId][0];
	
			// Update
			sQuestion2.isActive__c = false;
	
			update sQuestion2;

			// Mark any child Rules as inactive as well
			list<Rule__c> li_RulestoInactivate = new list<Rule__c>();

			if (m_mapQuestiontoRules.containsKey(mp_QuestionId))
			{
				set<id> set_RuleIds	= m_mapQuestiontoRules.get(sQuestion2.Id);
				
				for (Rule__c sRule : [	select	id,
												isActive__c
										from	Rule__c
										where	id in : set_RuleIds
									])
				{
					// Only update Active Rules
					if (sRule.isActive__c)
					{
						sRule.isActive__c = false;
					
						li_RulestoInactivate.add(sRule);
					}
				}
			}
	
			if (!li_RulestoInactivate.isEmpty())
				update li_RulestoInactivate;

			buildQuestionList();
	
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.QUESTION_INACTIVED));
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
		pageReference pageRef = page.CS_Question;
		pageRef.setRedirect(true);
		return pageRef;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference gotoViewRules()
	{
		pageReference pageRef = page.CS_RulesBySection;
        pageRef.setRedirect(true);
        return pageRef;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference gotoViewActions()
	{
		pageReference pageRef = page.CS_Actions;
        pageRef.setRedirect(true);
        return pageRef;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// 
	public pageReference showFirstPage()
	{
		mp_liQuestions = new list<QuestionWrapper>();
		
		mp_iPageNumber  = 1;
		m_iStartList   = 0;
		mp_iListSize	= m_iDefaultListSize < m_liQuestions.size()
						? m_iDefaultListSize
						: m_liQuestions.size() - m_iStartList;

		for (integer i = m_iStartList; i < mp_iListSize; i++)
			mp_liQuestions.add(m_liQuestions[i]);

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference showPreviousPage()
	{
		mp_liQuestions = new list<QuestionWrapper>();
		
		mp_iPageNumber  -= 1;
		m_iStartList   = (mp_iPageNumber - 1) * m_iDefaultListSize;
		mp_iListSize	= (m_iStartList + m_iDefaultListSize) < m_liQuestions.size()
						? m_iDefaultListSize
						: m_liQuestions.size() - m_iStartList;

		for (integer i = m_iStartList; i < (m_iStartList + mp_iListSize); i++)
			mp_liQuestions.add(m_liQuestions[i]);

		return null;
	}
	

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference showNextPage()
	{
		mp_liQuestions = new list<QuestionWrapper>();
		
		mp_iPageNumber  += 1;
		m_iStartList   = (mp_iPageNumber - 1) * m_iDefaultListSize;
		mp_iListSize	= (m_iStartList + m_iDefaultListSize) < m_liQuestions.size()
						? m_iDefaultListSize
						: m_liQuestions.size() - m_iStartList;

		for (integer i = m_iStartList; i < (m_iStartList + mp_iListSize); i++)
			mp_liQuestions.add(m_liQuestions[i]);

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference showLastPage()
	{
		mp_liQuestions = new list<QuestionWrapper>();
		
		mp_iPageNumber = mp_iTotalPages;
		m_iStartList   = (mp_iPageNumber - 1) * m_iDefaultListSize;
		mp_iListSize	= (m_iStartList + m_iDefaultListSize) < m_liQuestions.size()
						? m_iDefaultListSize
						: m_liQuestions.size() - m_iStartList;

		for (integer i = m_iStartList; i < (m_iStartList + mp_iListSize); i++)
			mp_liQuestions.add(m_liQuestions[i]);

		return null;
	}


	/***********************************************************************************************************
		Helper methods
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void buildQuestionList()
	{
		list<QuestionWrapper> li_QuestionWrappers = new list<QuestionWrapper>();

		// First get the Questions
		list<Question2__c> li_Questions = CS_Questions_Utilities.getQuestions();
		
		// Get the Question ids
		set<id> set_QuestionIds = new set<id>();
		
		for (Question2__c sQuestion : li_Questions)
			set_QuestionIds.add(sQuestion.id);
		
		// Then get any Rules
		map<id, Rule__c> map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
		
		// Derive a map of Question id to a set of Rule ids
		m_mapQuestiontoRules = new map<id, set<id>>();
		
		for (Rule__c sRule : map_Rules.values())
		{
			set<id> set_RuleIds	= m_mapQuestiontoRules.containsKey(sRule.Question2__c)
								? m_mapQuestiontoRules.get(sRule.Question2__c)
								: new set<id>();

			set_RuleIds.add(sRule.id);
			m_mapQuestiontoRules.put(sRule.Question2__c, set_RuleIds);
		}
		
		// Lastly get the ids of Rules that are linked to Answers
		set<id> set_RuleIdsWithAnswers = CS_Questions_Utilities.identifyRuleswithAnswers(map_Rules.keySet());
		
		// Now we can figure out which Questions have Answers and populate the wrapper class accordingly
		for (Question2__c sQuestion : li_Questions)
		{
			boolean bShowEdit			= true;
			boolean bShowDelete			= true;
			boolean bShowInactivate		= false;
			
			if (m_mapQuestiontoRules.containsKey(sQuestion.id))
			{
				set<id> set_RuleIds = m_mapQuestiontoRules.get(sQuestion.id);
				
				for (id RuleId : set_RuleIds)
				{
					if (set_RuleIdsWithAnswers.contains(RuleId))
					{
						bShowDelete		= false;
						bShowInactivate	= true;
						
						break;
					}
				}
			}
			
			// Override booleans if the record is inactive
			if (!sQuestion.isActive__c)
				bShowInactivate	= false;
			
			li_QuestionWrappers.add(new QuestionWrapper(sQuestion, bShowEdit, bShowDelete, bShowInactivate));
		}
		
		m_liQuestions = new list<QuestionWrapper>();
		m_liQuestions.addAll(li_QuestionWrappers);
		
		if (m_liQuestions.isEmpty())
			return;

		mp_bQuestionsExist = true;

		// Work out how many pages there are
		if (m_liQuestions.size() > 0)
		{
			decimal decTotalPages = decimal.valueOf(m_liQuestions.size()).divide(decimal.valueOf(m_iDefaultListSize),0, system.RoundingMode.UP);
			
			mp_iTotalPages = integer.valueOf(decTotalPages);
		}
		else
		{
			mp_iTotalPages = 0;
		}
	}

}
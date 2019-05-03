/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Jun 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing class CS_RulesBySection_Controller
{
	/***********************************************************************************************************
		Members
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Exception Classes & Enums
	public class X_Exception extends Exception{}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Singular
	public boolean	mp_bShowLists					{get; set;}
	
	public id		mp_QuestionId					{get; set;}
	public id		mp_RuleId						{get; set;}

	// List display variables for Questions
	public integer  m_iStartList;
	public integer  mp_iListSize					{get; set;}
	public integer  m_iDefaultListSize				= 20;
	public integer  mp_iPageNumber					{get; set;}
	public integer  mp_iTotalPages					{get; set;}

	// List display variables for Related Records
	public integer  m_iStartListRR;
	public integer  mp_iListSizeRR					{get; set;}
	public integer  m_iDefaultListSizeRR			= 10;
	public integer  mp_iPageNumberRR				{get; set;}
	public integer  mp_iTotalPagesRR				{get; set;}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Collections
	public list<QuestionWrapper> m_liQuestions;
	public list<RuleWrapper> m_liRelatedRecords;

	public list<QuestionWrapper> mp_liQuestions		{get; set;}
	public list<RuleWrapper> mp_liRelatedRecords	{get; set;}

	// Data driven picklists
	public list<SelectOption>	mp_liSections		{get; set;}
	public string				mp_strSection		{get; set;}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Wrapper classes
	public class QuestionWrapper
	{
		public string		QuestionId				{get; set;}
		public string		QuestionText			{get; set;}
		public list<RuleWrapper> li_Rules			{get; set;}
		
		public QuestionWrapper(id QuestionIdIn, string strQuestionText)
		{
			QuestionId		= QuestionIdIn;
			QuestionText	= strQuestionText;
			li_Rules		= new list<RuleWrapper>();
		}
	}

	public class RuleWrapper
	{
		public boolean		bShowEdit				{get; set;}
		public boolean		bShowDelete				{get; set;}
		public boolean		bShowInactivate			{get; set;}
		public string		objectName				{get; set;}
		public string		fieldName				{get; set;}
		public Rule__c		Rule					{get; set;}
		public boolean		bShowActiveandFT		{get; set;}
		
		public RuleWrapper(map<string, SObjectType> map_ObjectToSObjectTypes, Rule__c sRule, boolean ShowEdit, boolean showDelete, boolean showInactivate)
		{
			bShowEdit			= ShowEdit;
			bShowDelete			= showDelete;
			bShowInactivate		= showInactivate;
			bShowActiveandFT	= true;
			Rule				= sRule;
			
			system.debug('*** sRule ***' + sRule);
			
			// Query the schema for the selected object and field to get the labels
			if (sRule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_QUESTION)
			{
				if (!string.isBlank(sRule.Object_Name_1__c) && !string.isBlank(sRule.Field_Name_1__c))
				{
					SObjectType sObjType = map_ObjectToSObjectTypes.get(sRule.Object_Name_1__c.toLowerCase());
					objectName = sObjType.getDescribe().getLabel();
				
					SObjectField sObjField = sObjType.getDescribe().fields.getMap().get(sRule.Field_Name_1__c.toLowerCase());
					fieldName = SObjField.getDescribe().getLabel();
				}
			}
			else
			{
				objectName = sRule.Related_Object_Label__c;

				Schema.DescribeFieldResult descFieldResult = Rule__c.Related_Field_Name__c.getDescribe();
				
				for (Schema.PicklistEntry PLE : descFieldResult.getPicklistValues())
				{
					if (PLE.getValue() == sRule.Related_Field_Name__c)
					{
						fieldName = PLE.getLabel();
						break;
					}
				}
			}
		}

		public RuleWrapper(map<string, SObjectType> map_ObjectToSObjectTypes, Rule__c sRule)
		{
			Rule = new Rule__c();
			bShowActiveandFT = false;
			
			// Query the schema for the selected object and field to get the labels
			SObjectType sObjType = map_ObjectToSObjectTypes.get(sRule.Object_Name_2__c.toLowerCase());
			objectName = sObjType.getDescribe().getLabel();
				
			SObjectField sObjField = sObjType.getDescribe().fields.getMap().get(sRule.Field_Name_2__c.toLowerCase());
					fieldName = SObjField.getDescribe().getLabel();

			Rule.Field_Value_Text__c = sRule.Field_Value_Text_2__c;
		}
	}


	/***********************************************************************************************************
		Constructor
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Our Constructor
	public CS_RulesBySection_Controller()
	{

	}


	public pageReference Init()
	{
		buildSectionPicklist();
		
		mp_bShowLists = false;

		mp_liQuestions = new list<QuestionWrapper>();
		mp_liRelatedRecords = new list<RuleWrapper>();

		// If we are returning from the editor we will have a section name
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		
		string strPageNumber;
		string strPageNumberRR;

			if (sP.contains('section'))
				mp_strSection	= (string)sP.get('section');

			if (sP.contains('pageNo'))
				strPageNumber	= (string)sP.get('pageNo');

			if (sP.contains('pageNoRR'))
				strPageNumberRR	= (string)sP.get('pageNoRR');
		
		if (!string.isBlank(strPageNumber))
			mp_iPageNumber = integer.valueOf(strPageNumber);

		if (!string.isBlank(strPageNumberRR))
			mp_iPageNumberRR = integer.valueOf(strPageNumberRR);
		
		if (!string.isBlank(mp_strSection))
		{
			return actionRebuildSection();
		}
		
		return null;
	}


	/***********************************************************************************************************
		Button / link methods
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionRebuildSection()
	{
		try
		{
			m_liQuestions = new list<QuestionWrapper>();
			m_liRelatedRecords = new list<RuleWrapper>();
			map<string, SObjectType> map_ObjectToSObjectTypes = Schema.getGlobalDescribe();
			
			// Get Question records for the selected Section
			list<Question2__c> li_Questions = new list<Question2__c>();
			set<id> set_QuestionIds = new set<id>();
			
			for (Question2__c sQuestion :	[	select	id,
														Question_Text__c
												from	Question2__c
												where	Section__c = : mp_strSection
												and		isActive__c = true
												order by Question_Text__c
											])
			{
				li_Questions.add(sQuestion);
				set_QuestionIds.add(sQuestion.Id);
			}
	
			// Now get any Rule records
			map<id, Rule__c> map_Rules = CS_Questions_Utilities.getRules(set_QuestionIds, false);
			map<id, list<Rule__c>> map_QuestiontoRules = new map<id, list<Rule__c>>();
			
			for (Rule__c sRule : map_Rules.values())
			{
				list<Rule__c> li_Rules	= map_QuestiontoRules.containsKey(sRule.Question2__c)
										? map_QuestiontoRules.get(sRule.Question2__c)
										: new list<Rule__c>();
				
				li_Rules.add(sRule);
				map_QuestiontoRules.put(sRule.Question2__c, li_Rules);
			}
			
			// Identify records with Answers
			set<id> set_RuleIdsWithAnswers = CS_Questions_Utilities.identifyRuleswithAnswers(map_Rules.keySet());
			
			// Now build the list for display
			list<QuestionWrapper> li_QuestionswithNoRules = new list<QuestionWrapper>();
			map<integer, QuestionWrapper> map_QuestionWrappers = new map<integer, QuestionWrapper>();
			
			for (Question2__c sQuestion : li_Questions)
			{
				QuestionWrapper QuestionWrapper = new QuestionWrapper(sQuestion.Id, sQuestion.Question_Text__c);
				
				if (!map_QuestiontoRules.containsKey(sQuestion.Id))
				{
					li_QuestionswithNoRules.add(QuestionWrapper);
					continue;
				}

				list<Rule__c> li_Rules = map_QuestiontoRules.get(sQuestion.Id);
					
				for (Rule__c sRule : li_Rules)
				{
					boolean bShowEdit			= true;
					boolean bShowDelete			= false;
					boolean bShowInactivate		= false;
						
					// Set delete / disable flags
					if (set_RuleIdsWithAnswers.contains(sRule.Id))
					{
						bShowInactivate = true;
					}
					else
					{
						bShowDelete = true;
					}

					// Override booleans if the record is inactive
					if (!sRule.isActive__c)
						bShowInactivate	= false;

					RuleWrapper RuleWrapper = new RuleWrapper(map_ObjectToSObjectTypes, sRule, bShowEdit, bShowDelete, bShowInactivate);
					
					QuestionWrapper.li_Rules.add(RuleWrapper);
					
					// Add a second entry if there are two data filters
					if (!string.isBlank(sRule.Object_Name_2__c))
					{
						RuleWrapper RuleWrapper2 = new RuleWrapper(map_ObjectToSObjectTypes, sRule);
						QuestionWrapper.li_Rules.add(RuleWrapper2);
					}
				}
					
				map_QuestionWrappers.put(integer.valueOf(li_Rules[0].Sequence_Number__c), QuestionWrapper);
			}
			
			// Add Questions with Rules, ordered by sequence number
			if (!map_QuestionWrappers.isEmpty())
			{
				list<integer> li_SequenceNumbers = new list<integer>(map_QuestionWrappers.keySet());
				li_SequenceNumbers.sort();
				
				for (integer iSequenceNumber : li_SequenceNumbers)
				{
					m_liQuestions.add(map_QuestionWrappers.get(iSequenceNumber));
				}
			}

			// Add any Questions with no rules
			if (!li_QuestionswithNoRules.isEmpty())
				m_liQuestions.addAll(li_QuestionswithNoRules);

			// Finally, get any Related Records (these are not linked to Questions)
			list<Rule__c> li_RelatedRecords = CS_Questions_Utilities.getRelatedRecords(mp_strSection);
			
			for (Rule__c sRule : li_RelatedRecords)
			{
				RuleWrapper RuleWrapper = new RuleWrapper(map_ObjectToSObjectTypes, sRule, true, true, false);
				m_liRelatedRecords.add(RuleWrapper);
			}
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

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

		if (m_liRelatedRecords.size() > 0)
		{
			decimal decTotalPages = decimal.valueOf(m_liRelatedRecords.size()).divide(decimal.valueOf(m_iDefaultListSizeRR),0, system.RoundingMode.UP);
			
			mp_iTotalPagesRR = integer.valueOf(decTotalPages);
		}
		else
		{
			mp_iTotalPagesRR = 0;
		}
		
		// Show the data
		mp_bShowLists = true;

		// Initialise page indices
		showFirstPage();
		return showFirstPageRR();
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionAddQuestionRule()
	{
		CS_Questions_Utilities.clearSessionCache();
		
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		
		if (!string.isBlank(mp_QuestionId))
			sP.put('qid', mp_QuestionId);

		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', mp_strSection);
		sP.put('source', CS_Questions_Utilities.ANSWERSOURCE_QUESTION);
		sP.put('pageNo', string.valueOf(mp_iPageNumber));
		sP.put('pageNoRR', string.valueOf(mp_iPageNumberRR));
		
		pageReference pageRef = page.CS_ConfigureRule;
		pageRef.setRedirect(true);
		return pageRef;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionAddRelatedRecordRule()
	{
		CS_Questions_Utilities.clearSessionCache();
		
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		
		if (!string.isBlank(mp_QuestionId))
			sP.put('qid', mp_QuestionId);

		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', mp_strSection);
		sP.put('source', CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD);
		sP.put('pageNo', string.valueOf(mp_iPageNumber));
		sP.put('pageNoRR', string.valueOf(mp_iPageNumberRR));

		pageReference pageRef = page.CS_ConfigureRule;
		pageRef.setRedirect(true);
		return pageRef;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionEdit()
	{
		CS_Questions_Utilities.clearSessionCache();
		
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('id', mp_RuleId);
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', mp_strSection);

		pageReference pageRef = page.CS_ConfigureRule;
		pageRef.setRedirect(true);
		return pageRef;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionInactivate()
	{
		try
		{
			// Get the record
			Rule__c sRule = [ select id, isActive__c from Rule__c where id = : mp_RuleId][0];
	
			// Update
			sRule.isActive__c = false;
	
			update sRule;
			
			return actionRebuildSection();
	
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.RULE_INACTIVED));
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionDelete()
	{
		try
		{
			// Get the record
			Rule__c sRule = [ select id from Rule__c where id = : mp_RuleId][0];
	
			// Delete
			delete sRule;
			
			actionRebuildSection();
	
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.RULE_DELETED));
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference gotoConfigureRule()
	{
		CS_Questions_Utilities.clearSessionCache();
		
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.put('returl', 'cs_rulesbysection');
		sP.put('section', mp_strSection);

		pageReference pageRef = page.CS_ConfigureRule;
		pageRef.setRedirect(true);
		return pageRef;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionDownload()
	{
		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Please do not press this button again'));

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference gotoQuestions()
	{
		pageReference pageRef = page.CS_Questions;
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


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// 
	public pageReference showFirstPageRR()
	{
		mp_liRelatedRecords = new list<RuleWrapper>();

		mp_iPageNumberRR = 1;
		m_iStartListRR	= 0;
		mp_iListSizeRR	= m_iDefaultListSizeRR < m_liRelatedRecords.size()
						? m_iDefaultListSizeRR
						: m_liRelatedRecords.size() - m_iStartListRR;

		for (integer i = m_iStartListRR; i < mp_iListSizeRR; i++)
			mp_liRelatedRecords.add(m_liRelatedRecords[i]);

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference showPreviousPageRR()
	{
		mp_liRelatedRecords = new list<RuleWrapper>();

		mp_iPageNumberRR -= 1;
		m_iStartListRR	= (mp_iPageNumberRR - 1) * m_iDefaultListSizeRR;
		mp_iListSizeRR	= (m_iStartListRR + m_iDefaultListSizeRR) < m_liRelatedRecords.size()
						? m_iDefaultListSizeRR
						: m_liRelatedRecords.size() - m_iStartListRR;

		for (integer i = m_iStartListRR; i < (m_iStartListRR + mp_iListSizeRR); i++)
			mp_liRelatedRecords.add(m_liRelatedRecords[i]);

		return null;
	}
	

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference showNextPageRR()
	{
		mp_liRelatedRecords = new list<RuleWrapper>();

		mp_iPageNumberRR += 1;
		m_iStartListRR	= (mp_iPageNumberRR - 1) * m_iDefaultListSizeRR;
		mp_iListSizeRR	= (m_iStartListRR + m_iDefaultListSizeRR) < m_liRelatedRecords.size()
						? m_iDefaultListSizeRR
						: m_liRelatedRecords.size() - m_iStartListRR;

		for (integer i = m_iStartListRR; i < (m_iStartListRR + mp_iListSizeRR); i++)
			mp_liRelatedRecords.add(m_liRelatedRecords[i]);

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference showLastPageRR()
	{
		mp_liRelatedRecords = new list<RuleWrapper>();

		mp_iPageNumberRR = mp_iTotalPagesRR;
		m_iStartListRR	= (mp_iPageNumberRR - 1) * m_iDefaultListSizeRR;
		mp_iListSizeRR	= (m_iStartListRR + m_iDefaultListSizeRR) < m_liRelatedRecords.size()
						? m_iDefaultListSizeRR
						: m_liRelatedRecords.size() - m_iStartListRR;

		for (integer i = m_iStartListRR; i < (m_iStartListRR + mp_iListSizeRR); i++)
			mp_liRelatedRecords.add(m_liRelatedRecords[i]);

		return null;
	}


	/***********************************************************************************************************
		Helper methods
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public void buildSectionPicklist()
	{
		// Get the Section values
		set<string> set_SectionNames = new set<string>();
		
		for (Question2__c sQuestion :	[	select	Section__c
											from	Question2__c
											where	isActive__c = true
											order by Section__c
										])
		{
			set_SectionNames.add(sQuestion.Section__c);
		}
		
		// Build the picklist
		mp_liSections = new list<SelectOption>();
		mp_liSections.add(new SelectOption(' ', 'Please select'));
		
		for (string strSection : set_SectionNames)
		{
			mp_liSections.add(new SelectOption(strSection, strSection));
		}
		
		system.debug('*** mp_liSections ***' + mp_liSections);
	}

}
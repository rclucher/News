/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Sep 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing class CS_AnswerHistoryDownload_Controller
{
	/***********************************************************************************************************
		Members
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Exception Classes & Enums
	public class X_Exception extends Exception{}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Singular
	private id m_OpportunityId;
	public string m_OpportunityName					{get; set;}

	public string		mp_UserName					{get; set;}
	public datetime		mp_Timestamp				{get; set;}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Collections
	public list<SectionWrapper> mp_liAnswers				{get; set;}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Wrapper classes
	public class SectionWrapper
	{
		public string	SectionName							{get; set;}
		public list<AnswerWrapper>	AnswerWrappers			{get; set;}
		
		public SectionWrapper(string strSectionName)
		{
			SectionName = strSectionName;
			AnswerWrappers = new list<AnswerWrapper>();
		}
	}

	public class AnswerWrapper
	{
		public string	QuestionText						{get; set;}
		public string	whoChanged							{get; set;}
		public string	dateChanged							{get; set;}
		public string	timeChanged							{get; set;}
		public string	whatChanged							{get; set;}
		
		public AnswerWrapper(string qText)
		{
			// Enclose text in double quotes so that commas, line breaks are displayed as expected
			QuestionText = '\"' + qText + '\"';
		}

		public AnswerWrapper(string qText, CS_Questions_Utilities.ChangeHistoryWrapper ChangeHistoryWrapperIn)
		{
			// Enclose text in double quotes so that commas, line breaks are displayed as expected
			if (!string.isBlank(qText))
				QuestionText = '\"' + qText + '\"';

			whoChanged = ChangeHistoryWrapperIn.whoChanged;
			list<string> li_timestampData = ChangeHistoryWrapperIn.whenChanged.split(' ');
			
			dateChanged = li_timestampData[1];

			timeChanged = li_timestampData[3];

			if (!string.isBlank(ChangeHistoryWrapperIn.whatChanged))
				whatChanged = '\"' + ChangeHistoryWrapperIn.whatChanged + '\"';
		}
	}


	/***********************************************************************************************************
		Constructor and Init
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Our Constructor
	public CS_AnswerHistoryDownload_Controller()
	{

	}

	public pageReference Init()
	{
		try
		{
			// Set up userid and timestamp
			mp_UserName = UserInfo.getName();			
			mp_Timestamp = datetime.now();
			string recordId = ApexPages.currentPage().getParameters().get('id');

			getAnswers(recordId);
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}


	/***********************************************************************************************************
		Worker Methods
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public void getAnswers(string recordId)
	{
		// Get the Answers for this Opportunity
		CS_QuestionnaireService ctrl = new CS_QuestionnaireService();
		
		ctrl.buildQuestionsForDisplay(recordId, true);
		
		mp_liAnswers = new list<SectionWrapper>();
		
		// Unpack into a map
		map<string, map<integer, Answer2__c>> map_SectiontoAnswers = new map<string, map<integer, Answer2__c>>();
		
		for (CS_Questions_Utilities.SectionWrapper SW : ctrl.mp_liQuestions)
		{
			map<integer, Answer2__c> map_Answers	= map_SectiontoAnswers.containsKey(SW.SectionName)
													? map_SectiontoAnswers.get(SW.SectionName)
													: new map<integer, Answer2__c>();
			
			for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SW.QuestionWrappers)
			{
				// Question id will be null for Related Records - ignore them
				if (QuestionWrapper.Answer.Question2__c == null)
					continue;

				map_Answers.put(QuestionWrapper.SequenceNumber, QuestionWrapper.Answer);
			}
			
			map_SectiontoAnswers.put(SW.SectionName, map_Answers);
		}
		
		for (string strSectionName : map_SectiontoAnswers.keySet())
		{
			SectionWrapper SectionWrapper = new SectionWrapper(strSectionName);
			
			map<integer, Answer2__c> map_Answers = map_SectiontoAnswers.get(strSectionName);

			list<integer> li_SequenceNumbers = new list<integer>(map_Answers.keySet());
			li_SequenceNumbers.sort();
			
			for (integer iSequenceNumber : li_SequenceNumbers)
			{
				Answer2__c sAnswer2 = map_Answers.get(iSequenceNumber);
			
				list<CS_Questions_Utilities.ChangeHistoryWrapper> li_HistoryText = new list<CS_Questions_Utilities.ChangeHistoryWrapper>();

				if (!string.isBlank(sAnswer2.Change_History__c))
				{
					list<CS_Questions_Utilities.ChangeHistoryWrapper> li_ChangeHistory = (list<CS_Questions_Utilities.ChangeHistoryWrapper>)JSON.deserialize(sAnswer2.Change_History__c, list<CS_Questions_Utilities.ChangeHistoryWrapper>.class);

					if (!li_ChangeHistory.isEmpty())
					{
						li_HistoryText.addAll(li_ChangeHistory);
					}
				}
				
				if (li_HistoryText.isEmpty())
				{
					SectionWrapper.AnswerWrappers.add(new AnswerWrapper(sAnswer2.Question_Text__c));
					continue;
				}
				
				for (integer i = 0; i < li_HistoryText.size(); i++)
				{
					if (i == 0)
					{
						SectionWrapper.AnswerWrappers.add(new AnswerWrapper(sAnswer2.Question_Text__c, li_HistoryText[i]));
					}
					else
					{
						SectionWrapper.AnswerWrappers.add(new AnswerWrapper(null, li_HistoryText[i]));
					}
				}
			}
			
			mp_liAnswers.add(SectionWrapper);
		}
	}

}
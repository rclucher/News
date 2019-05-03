/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Jul 18		Mike Jupp			Created
Sep 18		Mike Jupp			Fixes to content
------------------------------------------------------------*/
public with sharing class CS_AnswersDownload_Controller
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
		public string		SectionName						{get; set;}
		public list<AnswerWrapper>	AnswerWrappers			{get; set;}
		
		public SectionWrapper(string strSectionName)
		{
			SectionName = strSectionName;
			AnswerWrappers = new list<AnswerWrapper>();
		}
	}

	public class AnswerWrapper
	{
		public string		QuestionText					{get; set;}
		public string		AnswerText						{get; set;}
		
		public AnswerWrapper()
		{
			
		}
	}

	/***********************************************************************************************************
		Constructor and Init
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Our Constructor
	public CS_AnswersDownload_Controller()
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
		map<id, string> map_AnswertoAnswerType = new map<id, string>();
		
		// Unpack into a map
		map<string, map<integer, CS_Questions_Utilities.QuestionWrapper>> map_SectiontoAnswers = new map<string, map<integer, CS_Questions_Utilities.QuestionWrapper>>();
		
		for (CS_Questions_Utilities.SectionWrapper SW : ctrl.mp_liQuestions)
		{
			map<integer, CS_Questions_Utilities.QuestionWrapper> map_Answers	= map_SectiontoAnswers.containsKey(SW.SectionName)
																				? map_SectiontoAnswers.get(SW.SectionName)
																				: new map<integer, CS_Questions_Utilities.QuestionWrapper>();
			
			for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SW.QuestionWrappers)
			{
				// Question text will be blank for Related Records
				if (string.isBlank(QuestionWrapper.Answer.Question_Text__c))
					QuestionWrapper.Answer.Question_Text__c = QuestionWrapper.QuestionText;
				
				map_Answers.put(QuestionWrapper.SequenceNumber, QuestionWrapper);
				
				// Get the data type
				string answerType;

				if (QuestionWrapper.showAnswerCheckbox)
					answerType = CS_Questions_Utilities.ANSWERTYPE_CHECKBOX;
				else if (QuestionWrapper.showAnswerCurrency)
					answerType = CS_Questions_Utilities.ANSWERTYPE_CURRENCY;
				else if (QuestionWrapper.showAnswerDate)
					answerType = CS_Questions_Utilities.ANSWERTYPE_DATE;
				else if (QuestionWrapper.showAnswerEmail)
					answerType = CS_Questions_Utilities.ANSWERTYPE_EMAIL;
				else if (QuestionWrapper.showAnswerLongText)
					answerType = CS_Questions_Utilities.ANSWERTYPE_LONGTEXT;
				else if (QuestionWrapper.showAnswerNumeric)
					answerType = CS_Questions_Utilities.ANSWERTYPE_NUMBER;
				else if (QuestionWrapper.showAnswerPercent)
					answerType = CS_Questions_Utilities.ANSWERTYPE_PERCENT;
				else if (QuestionWrapper.showAnswerPhone)
					answerType = CS_Questions_Utilities.ANSWERTYPE_PHONE;
				else if (QuestionWrapper.showAnswerPicklist || QuestionWrapper.showAnswerText)
					answerType = CS_Questions_Utilities.ANSWERTYPE_TEXT;
				else if (QuestionWrapper.showAnswerURL)
					answerType = CS_Questions_Utilities.ANSWERTYPE_URL;
				
				if (QuestionWrapper.Answer.id != null)
				{
					// Data is from an Answer record
					map_AnswertoAnswerType.put(QuestionWrapper.Answer.id, answerType);
				}
				else
				{
					// Data is from a related record
					map_AnswertoAnswerType.put(QuestionWrapper.RuleId, answerType);
				}
			}
			
			map_SectiontoAnswers.put(SW.SectionName, map_Answers);
		}
		
		for (string strSectionName : map_SectiontoAnswers.keySet())
		{
			SectionWrapper SectionWrapper = new SectionWrapper(strSectionName);
			
			map<integer, CS_Questions_Utilities.QuestionWrapper> map_Answers = map_SectiontoAnswers.get(strSectionName);

			list<integer> li_SequenceNumbers = new list<integer>(map_Answers.keySet());
			li_SequenceNumbers.sort();
			
			for (integer iSequenceNumber : li_SequenceNumbers)
			{
				CS_Questions_Utilities.QuestionWrapper QuestionWrapper = map_Answers.get(iSequenceNumber);
				
				AnswerWrapper AnswerWrapper = new AnswerWrapper();
				
				AnswerWrapper.QuestionText = '\"' + QuestionWrapper.Answer.Question_Text__c + '\"';
				
				string answerType;
				
				if (map_AnswertoAnswerType.containsKey(QuestionWrapper.Answer.id))
					answerType = map_AnswertoAnswerType.get(QuestionWrapper.Answer.id);
				else if (map_AnswertoAnswerType.containsKey(QuestionWrapper.RuleId))
					answerType = map_AnswertoAnswerType.get(QuestionWrapper.RuleId);
				
				// Only one of these conditions should be met
				if (answerType == CS_Questions_Utilities.ANSWERTYPE_CHECKBOX && QuestionWrapper.Answer.Answer_Checkbox__c != null)
					AnswerWrapper.AnswerText = string.valueOf(QuestionWrapper.Answer.Answer_Checkbox__c);
	
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_CURRENCY && QuestionWrapper.Answer.Answer_Currency__c != null)
					AnswerWrapper.AnswerText = string.valueOf(QuestionWrapper.Answer.Answer_Currency__c);
	
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_DATE && QuestionWrapper.Answer.Answer_Date__c != null)
					AnswerWrapper.AnswerText = string.valueOf(QuestionWrapper.Answer.Answer_Date__c);
	
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_EMAIL)
					AnswerWrapper.AnswerText = QuestionWrapper.Answer.Answer_Email__c;
	
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_LONGTEXT)
					AnswerWrapper.AnswerText = QuestionWrapper.Answer.Answer_Long_Text__c;
	
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_NUMBER && QuestionWrapper.Answer.Answer_Numeric__c != null)
					AnswerWrapper.AnswerText = string.valueOf(QuestionWrapper.Answer.Answer_Numeric__c);
	
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_PERCENT && QuestionWrapper.Answer.Answer_Percent__c != null)
					AnswerWrapper.AnswerText = string.valueOf(QuestionWrapper.Answer.Answer_Percent__c);
	
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_PHONE)
					AnswerWrapper.AnswerText = string.valueOf(QuestionWrapper.Answer.Answer_Phone__c);
	
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_TEXT || answerType == CS_Questions_Utilities.ANSWERTYPE_PICKLIST)
					AnswerWrapper.AnswerText = QuestionWrapper.Answer.Answer_Text__c;
	
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_URL)
					AnswerWrapper.AnswerText = QuestionWrapper.Answer.Answer_Url__c;

				// Enclose Answer text in double quotes so that commas, line breaks are displayed as expected
				if (!string.isBlank(AnswerWrapper.AnswerText))
					AnswerWrapper.AnswerText = '\"' + AnswerWrapper.AnswerText + '\"';
				
				SectionWrapper.AnswerWrappers.add(AnswerWrapper);
			}
			
			mp_liAnswers.add(SectionWrapper);
		}
	}

}
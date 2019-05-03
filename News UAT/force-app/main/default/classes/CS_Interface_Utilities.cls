/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	Interface Utilities
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Sep 18		Mike Jupp			Created
------------------------------------------------------------*/
public class CS_Interface_Utilities
{
	/***********************************************************************************************************
		Member variables
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private static id	m_OpportunityId;

	private static map<id, Answer2__c>					m_mapQuestiontoAnswer;
	private static map<id, Questionnaire_Action__c>		m_mapQuestionnaireActions;
	private static map<id, list<Rule__c>>				m_mapQuestionnaireActiontoRules;
	private static map<id, string>						m_mapQuestiontoAnswerType;


	/***********************************************************************************************************
		Internal classes
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Exception classes
	private class CS_Exception extends Exception{}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Interface wrapper classes
	public class Request
	{
		public string		MethodName;
		public map<string, string>	map_Values;
		
		public Request()
		{
			
		}

		public Request(string strMethodName)
		{
			MethodName		= strMethodName;
			map_Values		= new map<string, string>();
		}

		public Request(string strMethodName, map<string, string> map_ValuesIn)
		{
			MethodName		= strMethodName;
			map_Values		= new map<string, string>();
			
			map_Values.putAll(map_ValuesIn);
		}
	}

	public class Response
	{
		public boolean		success;
		public list<string>	messages;
		public map<string, string>	map_Values;
		
		public Response()
		{
			success			= true;
			messages		= new list<string>();
			map_Values		= new map<string, string>();
		}
	}

	public class InterfaceWrapper
	{
		public string						className;
		public string						methodName;
		public map<string, string>			map_Inputs;
		public map<string, AnswerWrapper>	map_Outputs;
		
		public InterfaceWrapper(string strClassName, string strMethodName)
		{
			className		= strClassName;
			methodName		= strMethodName;
			map_Inputs		= new map<string, string>();
			map_Outputs		= new map<string, AnswerWrapper>();
		}
	}

	public class AnswerWrapper
	{
		public string			stringValue;
		public string			answerType;
		public Answer2__c		answer2;

		public AnswerWrapper(string strAnswerType, Answer2__c answerIn)
		{
			stringValue		= null;
			answerType		= strAnswerType;
			answer2			= answerIn;
		}
	}

	/***********************************************************************************************************
		Interface methods
	***********************************************************************************************************/
	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Clears existing data in Answers configured as the targets of an interface call
	Inputs:			A list of SectionWrapper classes
	Output:			none
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
    ------------------------------------------------------------*/
	public static void clearAnswers(list<CS_Questions_Utilities.SectionWrapper> li_SectionWrappers)
	{
		// Update the Answers
		map<id, Answer2__c> map_AnswerstoUpdate = new map<id, Answer2__c>();

		// Identify any interface Rules
		
		// Get Question ids
		buildQuestiontoAnswerMap(li_SectionWrappers);
		
		// Get Questionnaire Actions
		buildQuestionnaireActionsMap();
		
		// Found something to process?
		if (m_mapQuestionnaireActions.isEmpty())
			return;
		
		// Get the Rules - Output only
		buildRulesMaps(true);
		
		if (m_mapQuestionnaireActiontoRules.isEmpty())
			return;

		// Build interface wrappers
		map<id, CS_Interface_Utilities.InterfaceWrapper> map_InterfaceWrappers = getInterfaceWrappers();

		// Look for any execution history
		map<id, Questionnaire_Action_Result__c> map_QARs = getQARs(m_OpportunityId);

		for (id questionnaireActionId : map_InterfaceWrappers.keySet())
		{
			Questionnaire_Action__c sQuestionnaireAction = m_mapQuestionnaireActions.get(questionnaireActionId);

			CS_Interface_Utilities.InterfaceWrapper InterfaceWrapper = map_InterfaceWrappers.get(questionnaireActionId);
			
			// Don't do any processing if the parameters are the same as last time, unless there was an error
			if (hasParameterChanged(sQuestionnaireAction.Id, map_QARs, InterfaceWrapper) == false)
				continue;
		
			for (Rule__c sRule : m_mapQuestionnaireActiontoRules.get(questionnaireActionId))
			{
				// Get the Answer record
				Answer2__c sAnswer = m_mapQuestiontoAnswer.get(sRule.Question2__c);
				
				string answerType = m_mapQuestiontoAnswerType.get(sRule.Question2__c);
	
				// Identify the appropriate field and clear it
						
				if (answerType == CS_Questions_Utilities.ANSWERTYPE_CHECKBOX)
				{
					sAnswer.Answer_Checkbox__c = null;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_CURRENCY)
				{
					sAnswer.Answer_Currency__c = null;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_DATE)
				{
					sAnswer.Answer_Date__c = null;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_EMAIL)
				{
					sAnswer.Answer_Email__c = null;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_LONGTEXT)
				{
					sAnswer.Answer_Long_Text__c = null;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_NUMBER)
				{
					sAnswer.Answer_Numeric__c = null;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_PERCENT)
				{
					sAnswer.Answer_Percent__c = null;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_PHONE)
				{
					sAnswer.Answer_Phone__c = null;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_TEXT || answerType == CS_Questions_Utilities.ANSWERTYPE_PICKLIST)
				{
					sAnswer.Answer_Text__c = null;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_URL)
				{
					sAnswer.Answer_Url__c = null;
				}
						
				map_AnswerstoUpdate.put(sAnswer.id, sAnswer);
			}
		}
		
		system.debug('*** map_AnswerstoUpdate ***' + map_AnswerstoUpdate);
		
		if (!map_AnswerstoUpdate.isEmpty())
			update map_AnswerstoUpdate.values();

	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Executes Questionnaire Actions
	Inputs:			A list of SectionWrapper classes
	Output:			none
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
    ------------------------------------------------------------*/
	public static void makeInterfaceCalls(list<CS_Questions_Utilities.SectionWrapper> li_SectionWrappers)
	{
		// Identify any interface Rules
		
		// Get Question ids
		buildQuestiontoAnswerMap(li_SectionWrappers);
		
		// Get Questionnaire Actions
		buildQuestionnaireActionsMap();
		
		// Found something to process?
		if (m_mapQuestionnaireActions.isEmpty())
			return;
		
		// Get the Rules
		buildRulesMaps();
		
		if (m_mapQuestionnaireActiontoRules.isEmpty())
			return;

		// Build interface wrappers
		map<id, CS_Interface_Utilities.InterfaceWrapper> map_InterfaceWrappers = getInterfaceWrappers();
		
		// Look for any execution history
		map<id, Questionnaire_Action_Result__c> map_QARs = getQARs(m_OpportunityId);

		// Execute
		map<id, Answer2__c> map_AnswerstoUpdate = new map<id, Answer2__c>();
		list<Questionnaire_Action_Result__c> li_QARstoUpdate = new list<Questionnaire_Action_Result__c>();

		for (id questionnaireActionId : map_InterfaceWrappers.keySet())
		{
			Questionnaire_Action__c sQuestionnaireAction = m_mapQuestionnaireActions.get(questionnaireActionId);

			CS_Interface_Utilities.InterfaceWrapper InterfaceWrapper = map_InterfaceWrappers.get(questionnaireActionId);
			
			// Don't do any processing if the parameters are the same as last time, unless there was an error
			if (hasParameterChanged(questionnaireActionId, map_QARs, InterfaceWrapper) == false)
				continue;

			Type t = Type.forName(InterfaceWrapper.className);
			CS_Questionnaire_Interface objInterface = (CS_Questionnaire_Interface)t.newInstance();
				
			// Make the call
			CS_Interface_Utilities.Request req = new CS_Interface_Utilities.Request(InterfaceWrapper.MethodName, InterfaceWrapper.map_Inputs);
								
			CS_Interface_Utilities.Response res = objInterface.process(req);
				
			system.debug('*** res ***' + res);
			
			// Record the result
			if (map_QARs.containsKey(questionnaireActionId))
			{
				Questionnaire_Action_Result__c sQAR = map_QARs.get(questionnaireActionId);
				sQAR.Parameters__c		= JSON.serialize(InterfaceWrapper.map_Inputs);
				sQAR.Success__c			= res.success;
				sQAR.Error_Message__c	= JSON.serialize(res.messages);

				li_QARstoUpdate.add(sQAR);
			}
			else
			{
				Questionnaire_Action_Result__c sQAR = new Questionnaire_Action_Result__c(
					Questionnaire_Action__c	= questionnaireActionId,
					Opportunity__c			= m_OpportunityId,
					Parameters__c			= JSON.serialize(InterfaceWrapper.map_Inputs),
					Success__c				= res.success,
					Error_Message__c		= JSON.serialize(res.messages));

				li_QARstoUpdate.add(sQAR);
			}
				
			// Unpack the response
			system.debug('*** InterfaceWrapper ***' + InterfaceWrapper);
				
			for (string parameterLabel : InterfaceWrapper.map_Outputs.keySet())
			{
				if (res.map_Values.containsKey(parameterLabel))
				{
					string stringValue = res.map_Values.get(parameterLabel);
					
					CS_Interface_Utilities.AnswerWrapper AnswerWrapper = InterfaceWrapper.map_Outputs.get(parameterLabel);
					
					if (AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_CHECKBOX && !string.isBlank(stringValue))
					{
						AnswerWrapper.answer2.Answer_Checkbox__c = boolean.valueOf(stringValue);
					}
					else if (AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_CURRENCY && !string.isBlank(stringValue))
					{
						AnswerWrapper.answer2.Answer_Currency__c = double.valueOf(stringValue);
					}
					else if (AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_DATE && !string.isBlank(stringValue))
					{
						AnswerWrapper.answer2.Answer_Date__c = date.valueOf(stringValue);
					}
					else if (AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_EMAIL)
					{
						AnswerWrapper.answer2.Answer_Email__c = stringValue;
					}
					else if (AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_LONGTEXT)
					{
						AnswerWrapper.answer2.Answer_Long_Text__c = stringValue;
					}
					else if (AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_NUMBER && !string.isBlank(stringValue))
					{
						AnswerWrapper.answer2.Answer_Numeric__c = double.valueOf(stringValue);
					}
					else if (AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_PERCENT && !string.isBlank(stringValue))
					{
						AnswerWrapper.answer2.Answer_Percent__c = double.valueOf(stringValue);
					}
					else if (AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_PHONE)
					{
						AnswerWrapper.answer2.Answer_Phone__c = stringValue;
					}
					else if (AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_TEXT || AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_PICKLIST)
					{
						AnswerWrapper.answer2.Answer_Text__c = stringValue;
					}
					else if (AnswerWrapper.answerType == CS_Questions_Utilities.ANSWERTYPE_URL)
					{
						AnswerWrapper.answer2.Answer_Url__c = stringValue;
					}
						
					map_AnswerstoUpdate.put(AnswerWrapper.answer2.id, AnswerWrapper.answer2);
				}
			}
		}
		
		system.debug('*** map_AnswerstoUpdate ***' + map_AnswerstoUpdate);
		system.debug('*** li_QARstoUpdate ***' + li_QARstoUpdate);
		
		if (!map_AnswerstoUpdate.isEmpty())
			update map_AnswerstoUpdate.values();
		
		if (!li_QARstoUpdate.isEmpty())
			upsert li_QARstoUpdate;

	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
    ------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	private static void buildQuestiontoAnswerMap(list<CS_Questions_Utilities.SectionWrapper> li_SectionWrappers)
	{
		m_mapQuestiontoAnswer = new map<id, Answer2__c>();
		
		for (CS_Questions_Utilities.SectionWrapper SectionWrapper : li_SectionWrappers)
		{
			for (CS_Questions_Utilities.QuestionWrapper QuestionWrapper : SectionWrapper.QuestionWrappers)
			{
				if (QuestionWrapper.QuestionId == null)
					continue;

				m_mapQuestiontoAnswer.put(QuestionWrapper.QuestionId, QuestionWrapper.Answer);
				
				if (m_OpportunityId == null && QuestionWrapper.OpportunityId != null)
					m_OpportunityId = QuestionWrapper.OpportunityId;
			}
		}
		
		system.debug('*** m_mapQuestiontoAnswer ***' + m_mapQuestiontoAnswer);
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
    ------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	private static void buildQuestionnaireActionsMap()
	{
		// Get Questionnaire Actions
		m_mapQuestionnaireActions = new map<id, Questionnaire_Action__c>();
		
		for (Questionnaire_Action__c sQuestionnaireAction :	[	select	id,
																		Name,
																		isActive__c
																from	Questionnaire_Action__c
																where	isActive__c = true
															])
		{
			m_mapQuestionnaireActions.put(sQuestionnaireAction.Id, sQuestionnaireAction);
		}
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
    ------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	private static void buildRulesMaps()
	{
		buildRulesMaps(false);
	}

	private static void buildRulesMaps(boolean bOutputOnly)
	{
		m_mapQuestionnaireActiontoRules = new map<id, list<Rule__c>>();
		m_mapQuestiontoAnswerType = new map<id, string>();
		
		for (Rule__c sRule :	[	select	id,
											Question2__c,
											Question2__r.Answer_Type__c,
											Questionnaire_Action__c,
											Service_Class_Name__c,
											Service_Method_Name__c,
											Parameter_Label__c,
											Input_Output__c
									from	Rule__c
									where	Questionnaire_Action__c in : m_mapQuestionnaireActions.keySet()
									and		Service_Class_Name__c <> null
									and		isActive__c = true
								])
		{
			if (bOutputOnly && sRule.Input_Output__c != 'Output')
				continue;

			list<Rule__c> li_Rules	= m_mapQuestionnaireActiontoRules.containsKey(sRule.Questionnaire_Action__c)
									? m_mapQuestionnaireActiontoRules.get(sRule.Questionnaire_Action__c)
									: new list<Rule__c>();
			
			li_Rules.add(sRule);
			m_mapQuestionnaireActiontoRules.put(sRule.Questionnaire_Action__c, li_Rules);
			
			m_mapQuestiontoAnswerType.put(sRule.Question2__c, sRule.Question2__r.Answer_Type__c);
		}
		
		system.debug('*** m_mapQuestionnaireActiontoRules ***' + m_mapQuestionnaireActiontoRules);
		system.debug('*** m_mapQuestiontoAnswerType ***' + m_mapQuestiontoAnswerType);
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Builds a collection of InterfaceWrappers
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
    ------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	private static map<id, CS_Interface_Utilities.InterfaceWrapper> getInterfaceWrappers()
	{
		// Build interface wrappers
		map<id, CS_Interface_Utilities.InterfaceWrapper> map_InterfaceWrappers = new map<id, CS_Interface_Utilities.InterfaceWrapper>();

		system.debug('*** m_mapQuestionnaireActions ***' + m_mapQuestionnaireActions);

		for (Questionnaire_Action__c sQuestionnaireAction : m_mapQuestionnaireActions.values())
		{
			if (!m_mapQuestionnaireActiontoRules.containsKey(sQuestionnaireAction.Id))
				continue;

			// Get the Rules
			list<Rule__c> li_Rules	= m_mapQuestionnaireActiontoRules.get(sQuestionnaireAction.Id);

			for (Rule__c sRule : li_Rules)
			{
				if (!m_mapQuestiontoAnswer.containsKey(sRule.Question2__c))
					continue;

				Answer2__c sAnswer = m_mapQuestiontoAnswer.get(sRule.Question2__c);
				string answerType = m_mapQuestiontoAnswerType.get(sRule.Question2__c);

				CS_Interface_Utilities.InterfaceWrapper InterfaceWrapper
					= map_InterfaceWrappers.containsKey(sQuestionnaireAction.Id)
					? map_InterfaceWrappers.get(sQuestionnaireAction.Id)
					: new CS_Interface_Utilities.InterfaceWrapper(sRule.Service_Class_Name__c, sRule.Service_Method_Name__c);
				
				// Convert the Answer value to a string
				string stringValue;
				
				if (answerType == CS_Questions_Utilities.ANSWERTYPE_CHECKBOX && sAnswer.Answer_Checkbox__c != null)
				{
					stringValue = string.valueOf(sAnswer.Answer_Checkbox__c);
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_CURRENCY && sAnswer.Answer_Currency__c != null)
				{
					stringValue = string.valueOf(sAnswer.Answer_Currency__c);
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_DATE && sAnswer.Answer_Date__c != null)
				{
					stringValue = string.valueOf(sAnswer.Answer_Date__c);
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_EMAIL)
				{
					stringValue = sAnswer.Answer_Email__c;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_LONGTEXT)
				{
					stringValue = sAnswer.Answer_Long_Text__c;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_NUMBER && sAnswer.Answer_Numeric__c != null)
				{
					stringValue = string.valueOf(sAnswer.Answer_Numeric__c);
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_PERCENT && sAnswer.Answer_Percent__c != null)
				{
					stringValue = string.valueOf(sAnswer.Answer_Percent__c);
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_PHONE)
				{
					stringValue = sAnswer.Answer_Phone__c;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_TEXT || answerType == CS_Questions_Utilities.ANSWERTYPE_PICKLIST)
				{
					stringValue = sAnswer.Answer_Text__c;
				}
				else if (answerType == CS_Questions_Utilities.ANSWERTYPE_URL)
				{
					stringValue = sAnswer.Answer_Url__c;
				}

				// Save input values
				if (sRule.Input_Output__c == 'Input')
				{
					InterfaceWrapper.map_Inputs.put(sRule.Parameter_Label__c, stringValue);
				}
				else if (sRule.Input_Output__c == 'Output')
				{
					CS_Interface_Utilities.AnswerWrapper AnswerWrapper 
						= new CS_Interface_Utilities.AnswerWrapper(answerType, sAnswer);

					InterfaceWrapper.map_Outputs.put(sRule.Parameter_Label__c, AnswerWrapper);
				}
				
				// Write back to the master collection
				map_InterfaceWrappers.put(sQuestionnaireAction.Id, InterfaceWrapper);
			}
		}

		system.debug('*** map_InterfaceWrappers ***' + map_InterfaceWrappers);

		return map_InterfaceWrappers;
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Checks previous call's input parameters
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
    ------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	private static map<id, Questionnaire_Action_Result__c> getQARs(id opportunityId)
	{
		map<id, Questionnaire_Action_Result__c> map_QARs = new map<id, Questionnaire_Action_Result__c>();
		
		for (Questionnaire_Action_Result__c sQAR :	[	select	id,
																Questionnaire_Action__c,
																Parameters__c,
																Success__c,
																Error_Message__c
														from	Questionnaire_Action_Result__c
														where	Opportunity__c = : opportunityId
													])
		{
			map_QARs.put(sQAR.Questionnaire_Action__c, sQAR);
		}
		
		system.debug('*** map_QARs ***' + map_QARs);

		return map_QARs;
	}



	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Checks previous call's input parameters
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
    ------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	private static boolean hasParameterChanged(id questionnaireActionId,
												map<id, Questionnaire_Action_Result__c> map_QARs,
												InterfaceWrapper InterfaceWrapper
											)
	{
		// Check execution history and if found, check that the parameters have changed
		boolean bParameterChanged = true;
			
		if (map_QARs.containsKey(questionnaireActionId))
		{
			Questionnaire_Action_Result__c sQAR = map_QARs.get(questionnaireActionId);
		
			if (!string.isBlank(sQAR.Parameters__c) && sQAR.Success__c == true)
			{
				map<string, string> map_OldParameters = (map<string, string>)JSON.deserialize(sQAR.Parameters__c, map<string, string>.class);
					
				boolean bFoundMismatch = false;
					
				for (string key : InterfaceWrapper.map_Inputs.keySet())
				{
					if (!map_OldParameters.containsKey(key))
						bFoundMismatch = true;

					if (map_OldParameters.containsKey(key) &&
						map_OldParameters.get(key) != InterfaceWrapper.map_Inputs.get(key))
						bFoundMismatch = true;
				}
					
				if (!bFoundMismatch)
					bParameterChanged = false;
			}
		}
		
		return bParameterChanged;
	}




	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Returns an error response
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Sep 18		Mike Jupp			Created
    ------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	public static Response returnError(string errorMessage)
	{
		Response res = new Response();
		res.success = false;
		res.messages.add(errorMessage);
		
		return res;
	}

}
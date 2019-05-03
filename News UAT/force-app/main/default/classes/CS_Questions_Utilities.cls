/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	Methods and static strings for the Questionnaire page controllers
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Jun 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing class CS_Questions_Utilities
{
	/***********************************************************************************************************
		Static strings
	***********************************************************************************************************/
	// Section titles for Question page
	public static final string SECTIONTITLE_CREATE			= 'Create New Question';
	public static final string SECTIONTITLE_EDIT			= 'Edit Question';

	// Section titles for Rule page
	public static final string SECTIONTITLE_CREATERULE		= 'Create New Rule';
	public static final string SECTIONTITLE_EDITRULE		= 'Edit Rule';

	// Section titles for Action page
	public static final string SECTIONTITLE_CREATEACTION	= 'Create New Action';
	public static final string SECTIONTITLE_EDITACTION		= 'Edit Action';

	// Configuration operators
	public static final string RULEOPERATOR_EQUALS			= 'equals';

	// Rule object - Question Type picklist values
	public static final string QUESTIONTYPE_SPECIFIC		= 'Specific';
	public static final string QUESTIONTYPE_GENERAL			= 'General';
	public static final string QUESTIONTYPE_UNIVERSAL		= 'Universal';
	public static final string QUESTIONTYPELABEL_SPECIFIC	= 'Ask this Question if a specific record is chosen';
	public static final string QUESTIONTYPELABEL_GENERAL	= 'Ask this Question if general criteria are met';
	public static final string QUESTIONTYPELABEL_UNIVERSAL	= 'Always ask this Question';

	// Rule object - Answer Source picklist values
	public static final string ANSWERSOURCE_QUESTION		= 'Question';
	public static final string ANSWERSOURCE_RELATEDRECORD	= 'Related Record';

	// Rule object - Answer Type picklist values
	public static final string ANSWERTYPE_CHECKBOX			= 'Checkbox';
	public static final string ANSWERTYPE_CURRENCY			= 'Currency';
	public static final string ANSWERTYPE_DATE				= 'Date';
	public static final string ANSWERTYPE_EMAIL				= 'Email';
	public static final string ANSWERTYPE_LONGTEXT			= 'Long Text Area';
	public static final string ANSWERTYPE_NUMBER			= 'Number';
	public static final string ANSWERTYPE_PERCENT			= 'Percentage';
	public static final string ANSWERTYPE_PHONE				= 'Phone';
	public static final string ANSWERTYPE_TEXT				= 'Text';
	public static final string ANSWERTYPE_PICKLIST			= 'Picklist';
	public static final string ANSWERTYPE_URL				= 'URL';

	// User facing messages
	public static final string GENERALERROR								= 'An error has occurred. Please contact Support';
	public static final string NOMATCHINGRULES							= 'No additional data is required at this point in time';
	public static final string RECORDSAVED								= 'Record has been saved';
	public static final string VALIDATIONERROR_SECTION					= 'Please choose a Section';
	public static final string VALIDATIONERROR_QUESTION					= 'Please enter text for your Question';
	public static final string VALIDATIONERROR_OBJECT					= 'Please choose an Object';
	public static final string VALIDATIONERROR_FIELD					= 'Please choose a Field';
	public static final string VALIDATIONERROR_VALUE					= 'Please enter a Value';
	public static final string VALIDATIONERROR_RELATEDDATALABEL			= 'Please provide a label for this data';
	public static final string VALIDATIONERROR_RELATEDOBJECT			= 'Please choose an Object';
	public static final string VALIDATIONERROR_RELATEDFIELD				= 'Please choose a Field';
	public static final string VALIDATIONERROR_ANSWERTYPE				= 'Please choose an Answer Type';
	public static final string VALIDATIONERROR_ANSWERPICKLISTVALUE		= 'Please enter some values in the picklist';
	public static final string VALIDATIONERROR_ANSWERPICKLISTSELECTION	= 'Please make a selection';
	public static final string VALIDATIONERROR_WHENTOASK				= 'Please specify when this Question should be asked';
	public static final string VALIDATIONERROR_WHENTOVIEW				= 'Please specify when this Question should be viewed';
	public static final string VALIDATIONERROR_MINMAXZERO				= 'Min / max length cannot be zero';
	public static final string VALIDATIONERROR_MINGTMAX					= 'Min length cannot be greater than the max length';
	public static final string VALIDATIONERROR_SEQNO					= 'Please specify a Sequence Number';
	public static final string VALIDATIONERROR_SERVICEMETHOD			= 'Please select a Service Method';
	public static final string VALIDATIONERROR_PARAMETERLABEL			= 'Please specify a Parameter Label';
	public static final string VALIDATIONERROR_INPUTOUTPUT				= 'Please select Input or Output';
	public static final string VALIDATIONERROR_SEQNOINUSE				= 'Another Rule has specified this Sequence Number';
	public static final string QUESTION_DELETED							= 'Question has been deleted';
	public static final string QUESTION_INACTIVED						= 'Question has been marked as inactive';
	public static final string RULE_DELETED								= 'Rule has been deleted';
	public static final string RULE_INACTIVED							= 'Rule has been marked as inactive';
	public static final string ACTION_DELETED							= 'Action has been deleted';
	public static final string ACTION_INACTIVED							= 'Action has been marked as inactive';
	public static final string PICKLISTEMPTY							= 'There are no values in this picklist';
	public static final string VALIDATIONFILTER_NOMATCH					= 'No record matches the filter criteria';
	public static final string VALIDATIONFILTER_TOOMANY					= 'More than one record matches the filter criteria';
	public static final string VALIDATIONERROR_ACTIONNAME				= 'Please enter a Name for this Action';
	public static final string VALIDATIONERROR_CLASSNAME				= 'Please choose a Service Class';
	public static final string VALIDATIONERROR_METHODNAME				= 'Please choose a Service Method';
	public static final string VALIDATIONERROR_ACTIONRULESECTION		= 'Please choose a Section';
	public static final string VALIDATIONERROR_ACTIONRULEQUESTION		= 'Please choose a Question';
	public static final string VALIDATIONERROR_ACTIONRULELABEL			= 'Please enter a Parameter Label';
	
	// User facing Questionnaire messages
	public static final string VALIDATIONERROR_REQUIRED		= 'Please answer this question';
	public static final string VALIDATIONERROR_CHECKBOXREQUIRED	= 'Checkbox must be ticked';
	public static final string VALIDATIONERROR_MINLENGTH	= 'Length is less than the minimum of ';		// Note trailing space - the code appends a number to this message
	public static final string VALIDATIONERROR_MAXLENGTH	= 'Length is greater than the maximum of ';		// Note trailing space - the code appends a number to this message


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Wrapper classes
	public class SectionWrapper
	{
		public string		SectionName						{get; set;}
		public string		SectionId						{get; set;}
		public list<QuestionWrapper>	QuestionWrappers	{get; set;}
		
		public SectionWrapper(string strSectionName)
		{
			SectionName = strSectionName;
			SectionId	= strSectionName.replaceAll(' ','_');
			QuestionWrappers = new list<QuestionWrapper>();
		}
	}

	public class QuestionWrapper
	{
		public integer		SequenceNumber					{get; set;}
		public id			QuestionId						{get; set;}
		public id			RuleId							{get; set;}
		public string		QuestionText					{get; set;}
		public id			OpportunityId					{get; set;}
		public Answer2__c	Answer							{get; set;}
		public list<PicklistWrapper> li_AnswerPicklistValues	{get; set;}
		public string		LongTextAdditional				{get; set;}
		public integer		LongTextRows					{get; set;}
		
		// Display booleans
		public boolean		isReadOnly						{get; set;}
		public boolean		showAnswerCheckbox				{get; set;}
		public boolean		showAnswerCurrency				{get; set;}
		public boolean		showAnswerDate					{get; set;}
		public boolean		showAnswerEmail					{get; set;}
		public boolean		showAnswerLongText				{get; set;}
		public boolean		showAnswerNumeric				{get; set;}
		public boolean		showAnswerPercent				{get; set;}
		public boolean		showAnswerPhone					{get; set;}
		public boolean		showAnswerText					{get; set;}
		public boolean		showAnswerPicklist				{get; set;}
		public boolean		showAnswerURL					{get; set;}

		public boolean		showHelpText					{get; set;}
		public string		HelpText						{get; set;}
		public integer		MinLength						{get; set;}
		public integer		MaxLength						{get; set;}	
		public boolean		isFieldTracking					{get; set;}
		public boolean		showLongTextAdditional			{get; set;}
		public boolean		isMandatory						{get; set;}
		
		// Validation errors
		public list<string>	messages						{get; set;}

		public QuestionWrapper(id qid, string question, Answer2__c sAnswer)
		{
			QuestionId				= qid;
			QuestionText			= question;
			Answer					= sAnswer;
			li_AnswerPicklistValues	= new list<PicklistWrapper>();
			
			// Display booleans
			isReadOnly				= false;
			showAnswerCheckbox		= false;
			showAnswerCurrency		= false;
			showAnswerDate			= false;
			showAnswerEmail			= false;
			showAnswerLongText		= false;
			showAnswerNumeric		= false;
			showAnswerPercent		= false;
			showAnswerPhone			= false;
			showAnswerText			= false;
			showAnswerPicklist		= false;
			showAnswerURL			= false;
			
			showHelpText			= false;
			isFieldTracking			= false;
			showLongTextAdditional	= false;
			isMandatory				= false;
			
			messages				= new list<string>();
		}
	}

	public class AnswerWrapper
	{
		public Answer2__c	Answer;
		public map<id, list<Answer_to_Rule__c>>	map_AnswertoRules;
		
		public AnswerWrapper()
		{
			map_AnswertoRules = new map<id, list<Answer_to_Rule__c>>();
		}
	}

	public class PicklistWrapper
	{
		public string	value;
		public string	label;
		
		public PicklistWrapper(string strValue, string strLabel)
		{
			value	= strValue;
			label	= strLabel;
		}
	}

	public class ChangeHistoryWrapper
	{
		public string	whoChanged			{get; set;}
		public string	whenChanged			{get; set;}
		public string	whatChanged			{get; set;}
		
		public ChangeHistoryWrapper(string whoChangedIn, string whatChangedIn)
		{
			whoChanged	= whoChangedIn;
			whatChanged	= whatChangedIn;

			// Convert timestamp to a sortable string
			string strDay		= string.valueOf(system.now().day());
			string strMonth		= string.valueOf(system.now().month());
			string strYear		= string.valueOf(system.now().year());
			string strHour		= string.valueOf(system.now().hour());
			string strMinute	= string.valueOf(system.now().minute());

			strDay = strDay.length() == 1
					? '0' + strDay
					: strDay;

			strMonth = strMonth.length() == 1
					? '0' + strMonth
					: strMonth;

			strHour = strHour.length() == 1
					? '0' + strHour
					: strHour;

			strMinute = strMinute.length() == 1
					? '0' + strMinute
					: strMinute;

			whenChanged = 'On ' + strDay + '/' + strMonth + '/' + strYear +
						' at ' + strHour + ':' + strMinute;
			
			system.debug('*** whenChanged ***' + whenChanged);
		}
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Following classes are used by getRelatedRecordData method
	private class RelationshipWrapper
	{
		private string		fieldAPIName;
		private string		relationshipName;
		private sObjectType	referenceTo;
	}

	private class QueryWrapper
	{
		private string	objectName;
		private id		recordId;
		private set<string> set_FieldNames;
		
		private QueryWrapper ()
		{
			set_FieldNames = new set<string>();
		}
	}

	private class ObjectFieldWrapper
	{
		private string	objectName;
		private string	fieldName;
		
		private ObjectFieldWrapper(string objectNameIn, string fieldNameIn)
		{
			objectName	= objectNameIn;
			fieldName	= fieldNameIn;
		}
	}
	
	private class ResultWrapper
	{
		private SObjectField	sObjField;
		private string	result;
	}


	/***********************************************************************************************************
		Utility methods
	***********************************************************************************************************/

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Returns a list of Question2 records, sorted by Section and Question Text
	Inputs			None
	Output			list of Question2 records
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jun 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public static list<Question2__c> getQuestions()
	{
		list<Question2__c> li_QuestionsOut = new list<Question2__c>();
		
		map<string, list<Question2__c>> map_SectiontoQuestions = new map<string, list<Question2__c>>();

		for (Question2__c sQuestion :	[	select	id,
													Section__c,
													Question_Text__c,
													Answer_Type__c,
													isActive__c
											from	Question2__c
											order by Question_Text__c
										])
		{
			list<Question2__c> li_Questions	= map_SectiontoQuestions.containsKey(sQuestion.Section__c)
											? map_SectiontoQuestions.get(sQuestion.Section__c)
											: new list<Question2__c>();

			li_Questions.add(sQuestion);
			map_SectiontoQuestions.put(sQuestion.Section__c, li_Questions);
		}
		
		// Now sort by Section
		list<string> li_SectionNames = new list<string>(map_SectiontoQuestions.keySet());
		
		li_SectionNames.sort();
		
		for (string strSectionName : li_SectionNames)
		{
			list<Question2__c> li_Questions	= map_SectiontoQuestions.get(strSectionName);
			li_QuestionsOut.addAll(li_Questions);
		}
		
		return li_QuestionsOut;
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Returns a map of Rule records
	Inputs			Set of Question2 record ids
	Output			map of Rule records
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jun 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public static map<id, Rule__c> getRules(set<id> set_QuestionIds)
	{
		return getRules(set_QuestionIds, true);
	}

	public static map<id, Rule__c> getRules(set<id> set_QuestionIds, boolean bSelectActiveOnly)
	{
		map<id, Rule__c> map_Rules = new map<id, Rule__c>();

		for (Rule__c sRule :	[	select	id,
											Question2__c,
											Question_Type__c,
											Answer_Source__c,
											Field_Name__c,
											Field_Name_1__c,
											Field_Name_2__c,
											Field_Data_Type__c,
											Field_Data_Type_2__c,
											Field_Value_Text__c,
											Field_Value_Text_2__c,
											Object_Name__c,
											Object_Name_1__c,
											Object_Name_2__c,
											Operator__c,
											Related_Object_Name__c,
											Related_Field_name__c,
											WhatId__c,
											Sequence_Number__c,
											When_to_Ask__c,
											When_to_View__c,
											Help_Text__c,
											Enable_Field_Tracking__c,
											isActive__c
									from	Rule__c
									where	Question2__c in : set_QuestionIds
									and		Answer_Source__c = : ANSWERSOURCE_QUESTION
								])
		{
			// Do we only want active Rules?
			if (bSelectActiveOnly && sRule.isActive__c == false)
				continue;

			map_Rules.put(sRule.id, sRule);
		}
		
		return map_Rules;
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Returns a list of Rule records for Related Records
	Inputs			Section name
	Output			list of Rule records
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jun 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public static list<Rule__c> getRelatedRecords(string strSection)
	{
		list<Rule__c> li_Rules = new list<Rule__c>();

		for (Rule__c sRule :	[	select	id,
											Question_Type__c,
											Answer_Source__c,
											Related_Record_Section__c,
											Related_Object_Name__c,
											Related_Object_Label__c,
											Related_Field_Name__c,
											Related_Field_Label__c,
											Sequence_Number__c,
											When_to_View__c,
											Help_Text__c,
											isActive__c
									from	Rule__c
									where	Answer_Source__c = : ANSWERSOURCE_RELATEDRECORD
									and		Related_Record_Section__c = : strSection
									order by Sequence_Number__c
								])
		{
			li_Rules.add(sRule);
		}
		
		return li_Rules;
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Returns a set of Rule record ids that are linked to Answer records
	Inputs			Set of Rule record ids
	Output			set of Rule record ids
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jun 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public static set<id> identifyRuleswithAnswers(set<id> set_RuleIds)
	{
		set<id> set_RuleIdsWithAnswers = new set<id>();

		for (Answer_to_Rule__c sAnswertoRule :	[	select	id,
															Rule__c
													from	Answer_to_Rule__c
													where	Rule__c in : set_RuleIds LIMIT 45000
												])
		{
			set_RuleIdsWithAnswers.add(sAnswertoRule.Rule__c);
		}
		
		return set_RuleIdsWithAnswers;
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Returns a map of Answer records
	Inputs			Set of Answer2 record ids
	Output			map of Answer2 records keyed on id
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public static map<id, Answer2__c> getAnswers(set<id> set_AnswerIds)
	{
		map<id, Answer2__c> map_QuestiontoAnswer = new map<id, Answer2__c>();

		for (Answer2__c sAnswer2 :	[	select	id,
												Question2__c,
												Question_Text__c,
												Section__c,
												Answer_Checkbox__c,
												Answer_Currency__c,
												Answer_Date__c,
												Answer_Email__c,
												Answer_Long_Text__c,
												Answer_Numeric__c,
												Answer_Percent__c,
												Answer_Phone__c,
												Answer_Text__c,
												Answer_Url__c,
												Change_History__c
										from	Answer2__c
										where	id in : set_AnswerIds
									])
		{
			map_QuestiontoAnswer.put(sAnswer2.Question2__c, sAnswer2);
		}
		
		return map_QuestiontoAnswer;
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	
	Inputs			
	Output			
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public static map<string, map<integer, QuestionWrapper>> getRelatedRecordData(
		map<string, map<string, set<string>>> map_SectiontoRelatedRecordData,
		map<string, list<Rule__c>> map_RelatedDataRules,
		map<string, SObjectType> map_ObjectToSObjectTypes, 
		map<string, map<integer, QuestionWrapper>> map_SectiontoQuestionWrappers,
		string opportunityId,
		string campaignOrderId,
		string salesOrderId)
	{
		// Prepare to build dynamic queries for the related records
		map<string, set<string>> map_ObjecttoFields = new map<string, set<string>>();

		for (string sectionName : map_SectiontoRelatedRecordData.keySet())
		{
			map<string, set<string>> map_ObjecttoFieldsfromSection = map_SectiontoRelatedRecordData.get(sectionName);
			
			for (string objectName : map_ObjecttoFieldsfromSection.keySet())
			{
				set<string> set_Fields	= map_ObjecttoFields.containsKey(objectName)
										? map_ObjecttoFields.get(objectName)
										: new set<string>();
			
				set_Fields.addAll(map_ObjecttoFieldsfromSection.get(objectName));
				
				map_ObjecttoFields.put(objectName, set_Fields);
			}
			
			system.debug('*** map_ObjecttoFields ***' + map_ObjecttoFields);
		}

		// Set of object API names to handle
		set<string> set_ObjectNames = new set<string>(map_ObjecttoFields.keySet());

		// Via the schema information, build a map of relationship describe information from our foundation objects 
		// in set_ObjectNames through ALL their possible parent relationships
		map<string, map<string, RelationshipWrapper>> map_ObjecttoRelationships = new map<string, map<string, RelationshipWrapper>>();
		map<string, map<string, set<string>>> map_ParenttoChildRelationships = new map<string, map<string, set<string>>>();
		
		boolean bContinueProcessing = true;
		
		do
		{
			boolean bFoundObjecttoProcess = false;
			
			for (string objectName : set_ObjectNames)
			{
//				system.debug('*** objectName ***' + objectName);
				
				if (map_ObjecttoRelationships.containsKey(objectName))
					continue;
				
				bFoundObjecttoProcess = true;
				
				map<string, RelationshipWrapper> map_Relationships = new map<string, RelationshipWrapper>();
			
				SObjectType sObjType = map_ObjectToSObjectTypes.get(objectName.toLowerCase());
	
				for (SObjectField sObjField : sObjType.getDescribe().fields.getMap().values())
				{					
					if (sObjField.getDescribe().getType().Name() == 'REFERENCE' && !sObjField.getDescribe().isNamePointing() 
						&& sObjField.getDescribe().isAccessible())
					{
						// Ignore if there is no foreign key
						if (sObjField.getDescribe().getRelationshipName() == null)
							continue;

						RelationshipWrapper RelationshipWrapper = new RelationshipWrapper();
						RelationshipWrapper.fieldAPIName		= sObjField.getDescribe().getName().toLowerCase();
						RelationshipWrapper.relationshipName	= sObjField.getDescribe().getRelationshipName().toLowerCase();
						RelationshipWrapper.referenceTo			= sObjField.getDescribe().getReferenceTo()[0];
						
//						system.debug('*** RelationshipWrapper ***' + RelationshipWrapper);
						
						set_ObjectNames.add(RelationshipWrapper.referenceTo.getDescribe().getName());
						
						map_Relationships.put(RelationshipWrapper.relationshipName, RelationshipWrapper);
					}
				}
				
				map_ObjecttoRelationships.put(objectName, map_Relationships);
			}
			
			if (!bFoundObjecttoProcess)
				bContinueProcessing = false;
		}
		while (bContinueProcessing);
		
//		system.debug('*** map_ObjecttoRelationships ***' + map_ObjecttoRelationships.keySet());

		// Now work out which of these relationships we need to actually use
		bContinueProcessing = true;
		
		do
		{
			boolean bFoundObjecttoProcess = false;
			
			for (string objectName : map_ObjecttoFields.keySet())
			{
				system.debug('*** objectName ***' + objectName);

				map<string, RelationshipWrapper> map_Relationships = map_ObjecttoRelationships.get(objectName);

				set<string> set_FieldNames = map_ObjecttoFields.get(objectName);

				for (string fieldName : set_FieldNames)
				{
					system.debug('*** fieldName ***' + fieldName);
						
					if (fieldName.contains('.'))
					{
						bFoundObjecttoProcess = true;

						integer index = fieldName.indexOf('.');
						string relationshipName = fieldName.subString(0, index).toLowerCase();
						
						RelationshipWrapper RelationshipWrapper = map_Relationships.get(relationshipName);
						
						system.debug('*** relationshipName ***' + relationshipName);
						system.debug('*** RelationshipWrapper ***' + RelationshipWrapper);

						// Add to the relational map
						// First the child object
						set<string> set_ChildFields	= map_ObjecttoFields.containsKey(objectName)
													? map_ObjecttoFields.get(objectName)
													: new set<string>();
		
						set_ChildFields.remove(fieldName);
						set_ChildFields.add(RelationshipWrapper.fieldAPIName);
						map_ObjecttoFields.put(objectName, set_ChildFields);
						
						system.debug('*** set_ChildFields ***' + set_ChildFields);
						
						// Now the parent
						string parentObjectName = RelationshipWrapper.referenceTo.getDescribe().getName();
						string parentFieldName = fieldName.subString(index + 1, fieldName.length()).toLowerCase();
						
						set<string> set_ParentFields	= map_ObjecttoFields.containsKey(parentObjectName)
														? map_ObjecttoFields.get(parentObjectName)
														: new set<string>();
		
						set_ParentFields.add(parentFieldName);
						map_ObjecttoFields.put(parentObjectName, set_ParentFields);

						system.debug('*** set_ParentFields ***' + set_ParentFields);

						// Save to the parent-child master map
						map<string, set<string>> map_ChildRelationships = map_ParenttoChildRelationships.containsKey(parentObjectName)
										? map_ParenttoChildRelationships.get(parentObjectName)
										: new map<string, set<string>>();

						set<string> set_ChildFieldNames	= map_ChildRelationships.containsKey(objectName)
														? map_ChildRelationships.get(objectName)
														: new set<string>();

						set_ChildFieldNames.add(RelationshipWrapper.fieldAPIName);
						map_ChildRelationships.put(objectName, set_ChildFieldNames);
						map_ParenttoChildRelationships.put(parentObjectName, map_ChildRelationships);
					}
				}
			}

			if (!bFoundObjecttoProcess)
				bContinueProcessing = false;
		}
		while (bContinueProcessing);

		// Prepare the query wrappers
		map<string, map<string, QueryWrapper>> map_ObjecttoQueryWrapper = new map<string, map<string, QueryWrapper>>();
		map<string, set<string>> map_ObjecttoIdFields = new map<string, set<string>>();

		for (string objectName : map_ObjecttoFields.keySet())
		{
			QueryWrapper QueryWrapper = new QueryWrapper();
			QueryWrapper.objectName = objectName;
			QueryWrapper.set_FieldNames = map_ObjecttoFields.get(objectName);
			
			// Opportunity
			if (objectName.toLowerCase() == 'opportunity')
			{
				QueryWrapper.recordId		= opportunityId;
			}
			else if (objectName.toLowerCase() == 'order__c')
			{
				QueryWrapper.recordId		= campaignOrderId;
			}
			else if (objectName.toLowerCase() == 'sales_order__c')
			{
				QueryWrapper.recordId		= salesOrderId;
			}
			else
			{
				continue;
			}
			
			map<string, QueryWrapper> map_QueryWrapper = new map<string, QueryWrapper>();
			map_QueryWrapper.put('id', QueryWrapper);
			map_ObjecttoQueryWrapper.put(objectName, map_QueryWrapper);
			
			set<string> set_IdFields = new set<string>();
			set_IdFields.add('id');
			map_ObjecttoIdFields.put(objectName, set_IdFields);
		}
		
		// Execute the queries
		map<string, map<string, ResultWrapper>> map_ObjecttoFieldResult = new map<string, map<string, ResultWrapper>>();

		bContinueProcessing = true;
		
		do
		{
			boolean bFoundObjecttoProcess = false;
			
			set_ObjectNames = new set<string>(map_ObjecttoIdFields.keySet());
			
			for (string objectName : set_ObjectNames)
			{
				map<string, QueryWrapper> map_QueryWrapper = map_ObjecttoQueryWrapper.get(objectName);
				
				for (string fieldName : map_QueryWrapper.keySet())
				{
					QueryWrapper QueryWrapper = map_QueryWrapper.get(fieldName);
					
					if (QueryWrapper.recordId != null)
					{
						map<string, ResultWrapper> map_FieldResults = executeQuery(QueryWrapper, map_ObjectToSObjectTypes, map_ObjecttoFields);
						
						map_ObjecttoFieldResult.put(objectName, map_FieldResults);
						
						system.debug('*** map_QueryWrapper ***' + map_QueryWrapper);
						system.debug('*** fieldName ***' + fieldName);
						
						set<string> set_IdFields = map_ObjecttoIdFields.get(objectName);
						set_IdFields.remove(fieldName);
						
						system.debug('*** set_IdFields ***' + set_IdFields);
						
						if (set_IdFields.isEmpty())
							map_ObjecttoIdFields.remove(objectName);
						
						system.debug('*** map_ObjecttoIdFields ***' + map_ObjecttoIdFields);
					}
				}
			}
			
			system.debug('*** map_ObjecttoFieldResult ***' + map_ObjecttoFieldResult);
			system.debug('*** map_ObjecttoFields ***' + map_ObjecttoFields);
			system.debug('*** map_ParenttoChildRelationships ***' + map_ParenttoChildRelationships);

			// Populate missing record ids from the results
			set_ObjectNames = new set<string>(map_ObjecttoFields.keySet());
			
			system.debug('*** set_ObjectNames ***' + set_ObjectNames);
			
			for (string objectName : set_ObjectNames)
			{
				system.debug('*** objectName ***' + objectName);
				
				if (!map_ParenttoChildRelationships.containsKey(objectName))
					continue;
				
				map<string, set<string>> map_ChildRelationships	= map_ParenttoChildRelationships.remove(objectName);
				
				system.debug('*** map_ChildRelationships ***' + map_ChildRelationships);
				
				for (string childObjectName : map_ObjecttoFieldResult.keySet())
				{
					system.debug('*** childObjectName ***' + childObjectName);
					
					map<string, ResultWrapper> map_FieldResults = map_ObjecttoFieldResult.get(childObjectName);
					
					system.debug('*** map_FieldResults ***' + map_FieldResults);
					
					if (!map_ChildRelationships.containsKey(childObjectName))
						continue;
					
					set<string> set_FieldNames = map_ChildRelationships.get(childObjectName);
					
					system.debug('*** set_FieldNames ***' + set_FieldNames);
					
					map<string, QueryWrapper> map_QueryWrapper	= map_ObjecttoQueryWrapper.containsKey(objectName)
																? map_ObjecttoQueryWrapper.get(objectName)
																: new map<string, QueryWrapper>();
					
					system.debug('*** map_QueryWrapper ***' + map_QueryWrapper);
				
					for (string fieldName : set_FieldNames)
					{
						ResultWrapper ResultWrapper = map_FieldResults.get(fieldName);
						
						// If we didn't get a result, remove from the Object / IdFields collection
						system.debug('*** map_ObjecttoIdFields ***' + map_ObjecttoIdFields);
						
						if (ResultWrapper.result == null && map_ObjecttoIdFields.containsKey(objectName))
						{
							set<string> set_IdFields = map_ObjecttoIdFields.get(objectName);
							
							system.debug('*** set_IdFields ***' + set_IdFields);
							
							set_IdFields.remove(fieldName);
							
							system.debug('*** set_IdFields ***' + set_IdFields);
							
							if (set_IdFields.isEmpty())
								map_ObjecttoIdFields.remove(objectName);
							
							system.debug('*** map_ObjecttoIdFields ***' + map_ObjecttoIdFields);
							
							continue;
						}
						
						bFoundObjecttoProcess = true;
						
						QueryWrapper QueryWrapper = new QueryWrapper();
						QueryWrapper.objectName = objectName;
						QueryWrapper.set_FieldNames = map_ObjecttoFields.get(objectName);
						QueryWrapper.recordId = ResultWrapper.result;
						
						system.debug('*** QueryWrapper ***' + QueryWrapper);
					
						map_QueryWrapper.put(fieldName, QueryWrapper);

						set<string> set_IdFields	= map_ObjecttoIdFields.containsKey(objectName)
													? map_ObjecttoIdFields.get(objectName)
													: new set<string>();
						set_IdFields.add(fieldName);
						map_ObjecttoIdFields.put(objectName, set_IdFields);
					}
					
					map_ObjecttoQueryWrapper.put(objectName, map_QueryWrapper);
				}
			}
			
			system.debug('*** map_ObjecttoQueryWrapper ***' + map_ObjecttoQueryWrapper);
			system.debug('*** map_ObjecttoIdFields ***' + map_ObjecttoIdFields);

			if (!bFoundObjecttoProcess)
				bContinueProcessing = false;
		}
		while (bContinueProcessing);

		// Build the response
		for (string sectionName : map_SectiontoRelatedRecordData.keySet())
		{
			system.debug('*** sectionName ***' + sectionName);
			
			map_ObjecttoFields	= map_SectiontoRelatedRecordData.get(sectionName);
			
			if (!map_RelatedDataRules.containsKey(sectionName))
				continue;

			list<Rule__c> li_Rules = map_RelatedDataRules.get(sectionName);
			
			for (Rule__c sRule : li_Rules)
			{
				system.debug('*** sRule ***' + sRule);
				
				ResultWrapper ResultWrapper;

				// If dot notation, find the parent object and field
				if (sRule.Related_Field_name__c.contains('.'))
				{
					map<string, RelationshipWrapper> map_Relationships = map_ObjecttoRelationships.get(sRule.Related_Object_Name__c);

					integer index = sRule.Related_Field_name__c.indexOf('.');
					string relationshipName = sRule.Related_Field_name__c.subString(0, index).toLowerCase();
					string parentFieldName = sRule.Related_Field_name__c.subString(index + 1, sRule.Related_Field_name__c.length()).toLowerCase();
					
					RelationshipWrapper RelationshipWrapper = map_Relationships.get(relationshipName);
						
					system.debug('*** relationshipName ***' + relationshipName);
					system.debug('*** RelationshipWrapper ***' + RelationshipWrapper);
					
					system.debug('*** RelationshipWrapper.referenceTo.getDescribe().getName() ***' + RelationshipWrapper.referenceTo.getDescribe().getName());
					system.debug('*** map_ObjecttoFieldResult ***' + map_ObjecttoFieldResult.keySet());

					string parentObject = RelationshipWrapper.referenceTo.getDescribe().getName();

					if (map_ObjecttoFieldResult.containsKey(parentObject))
					{
						map<string, ResultWrapper> map_Results = map_ObjecttoFieldResult.get(parentObject);
					
						system.debug('*** map_Results ***' + map_Results);

						if (map_Results.containsKey(parentFieldName))
							ResultWrapper = map_Results.get(parentFieldName);
					}
				}
				else
				{
					map<string, ResultWrapper> map_Results = map_ObjecttoFieldResult.get(sRule.Related_Object_Name__c);
					
					ResultWrapper = map_Results.get(sRule.Related_Field_Name__c);
				}

				system.debug('*** ResultWrapper ***' + ResultWrapper);

				// Initialise a QuestionWrapper
				QuestionWrapper QuestionWrapper = new QuestionWrapper(null, sRule.Related_Field_Label__c, new Answer2__c());
				QuestionWrapper.RuleId = sRule.Id;
				QuestionWrapper.isReadOnly = true;
				QuestionWrapper.SequenceNumber = integer.valueOf(sRule.Sequence_Number__c);

				if (ResultWrapper != null)
				{
					// Get the field type
					string fieldDataType = ResultWrapper.sObjField.getDescribe().getType().Name();
	
					// Work out the data type so we can cast the returned value correctly
					if (fieldDataType == 'BOOLEAN')
					{
						QuestionWrapper.showAnswerCheckbox = true;
						
						if (!string.isEmpty(ResultWrapper.result))
							QuestionWrapper.Answer.Answer_Checkbox__c = boolean.valueOf(ResultWrapper.result);
					}
					else if (fieldDataType == 'CURRENCY')	
					{
						QuestionWrapper.showAnswerCurrency = true;
						
						if (!string.isEmpty(ResultWrapper.result))
							QuestionWrapper.Answer.Answer_Currency__c = double.valueOf(ResultWrapper.result);
					}
					else if (fieldDataType == 'DATE')
					{
						QuestionWrapper.showAnswerDate = true;
						
						if (!string.isEmpty(ResultWrapper.result))
							QuestionWrapper.Answer.Answer_Date__c = date.valueOf(ResultWrapper.result);
					}
					else if (fieldDataType == 'EMAIL')
					{
						QuestionWrapper.showAnswerEmail = true;
						QuestionWrapper.Answer.Answer_Email__c = ResultWrapper.result;
					}
					else if (fieldDataType == 'TEXTAREA')
					{
	
					}
					else if (fieldDataType == 'INTEGER')
					{
						QuestionWrapper.showAnswerNumeric = true;
						
						if (!string.isEmpty(ResultWrapper.result))
							QuestionWrapper.Answer.Answer_Numeric__c = integer.valueOf(ResultWrapper.result);
					}
					else if (fieldDataType == 'DOUBLE')
					{
						QuestionWrapper.showAnswerNumeric = true;
						
						if (!string.isEmpty(ResultWrapper.result))
							QuestionWrapper.Answer.Answer_Numeric__c = double.valueOf(ResultWrapper.result);
					}
					else if (fieldDataType == 'PERCENT')
					{
						QuestionWrapper.showAnswerPercent = true;
						
						if (!string.isEmpty(ResultWrapper.result))
							QuestionWrapper.Answer.Answer_Percent__c = double.valueOf(ResultWrapper.result);
					}
					else if (fieldDataType == 'PHONE')
					{
						QuestionWrapper.showAnswerPhone = true;
						QuestionWrapper.Answer.Answer_Phone__c = ResultWrapper.result;
					}
					else if (fieldDataType == 'STRING' ||
						fieldDataType == 'PICKLIST')
					{
						QuestionWrapper.showAnswerText = true;
						QuestionWrapper.Answer.Answer_Text__c = ResultWrapper.result;
					}
					else if (fieldDataType == 'URL')
					{
						QuestionWrapper.showAnswerURL = true;
						QuestionWrapper.Answer.Answer_Url__c = ResultWrapper.result;
					}
				}
				else
				{
					// We didn't find the related record, so show an empty text field
					QuestionWrapper.showAnswerText = true;
				}

				// Help text etc
				if (!string.isBlank(sRule.Help_Text__c))
				{
					QuestionWrapper.showHelpText = true;
					QuestionWrapper.HelpText = sRule.Help_Text__c;
				}

				// Save to the master map
				map<integer, QuestionWrapper> map_QuestionWrappers	= map_SectiontoQuestionWrappers.containsKey(sectionName)
																	? map_SectiontoQuestionWrappers.get(sectionName)
																	: new map<integer, QuestionWrapper>();

				map_QuestionWrappers.put(QuestionWrapper.SequenceNumber, QuestionWrapper);
				
				system.debug('*** QuestionWrapper ***' + QuestionWrapper);
				
				map_SectiontoQuestionWrappers.put(sectionName, map_QuestionWrappers);
			}
		}
		
		return map_SectiontoQuestionWrappers;
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	
	Inputs			
	Output			
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public static map<string, ResultWrapper> executeQuery(
		QueryWrapper QueryWrapper, 
		map<string, SObjectType> map_ObjectToSObjectTypes,
		map<string, set<string>> map_ObjecttoFields)
	{
		map<string, ResultWrapper> map_FieldResults = new map<string, ResultWrapper>();
		
//		system.debug('*** QueryWrapper ***' + QueryWrapper);
		
		string strQuery = 'select id ';
				
		// Add fields
		for (string fieldName : QueryWrapper.set_FieldNames)
		{
			strQuery += ', ' + fieldName;
		}

		strQuery += ' from ' + QueryWrapper.objectName + ' where id = \'' + QueryWrapper.recordId + '\'  limit 1';
		
		// Execute the query
		list<sObject> li_sObj = database.query(strQuery);
						
		sObject sObj = li_sObj[0];

		// Process the results
		SObjectType sObjType = map_ObjectToSObjectTypes.get(QueryWrapper.objectName.toLowerCase());
			
		for (string fieldName : map_ObjecttoFields.get(QueryWrapper.objectName))
		{					
			ResultWrapper ResultWrapper = new ResultWrapper();
			ResultWrapper.sObjField = sObjType.getDescribe().fields.getMap().get(fieldName.toLowerCase());
			ResultWrapper.result = string.valueOf(sObj.get(fieldName.toLowerCase()));
					
			map_FieldResults.put(fieldName, ResultWrapper);
		}

		return map_FieldResults;
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Calculates the number of rows required to display a long text area
	Inputs			string representing a long text area
	Output			integer
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public static integer calculateNumberofRows(string answerText)
	{
		integer iNumberofRows = 0;
						
		// Split by line breaks
		list<string> li_AnswerText = answerText.split('\n');
						
		// Now count length of each line because we are wrapping text
		for (string strAnswerText : li_AnswerText)
		{
			decimal decRows = decimal.valueOf(strAnswerText.length()).divide
				(100, 0, System.RoundingMode.UP);

			iNumberofRows += integer.valueOf(decRows);
		}
		
		return iNumberofRows;
	}


	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Clears session cache
	Inputs			none
	Output			none
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Created
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public static void clearSessionCache()
	{
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
		sP.remove('id');
		sP.remove('returl');
		sP.remove('section');
		sP.remove('qid');
		sP.remove('source');
		sP.remove('pageNo');
		sP.remove('pageNoRR');
	}

}
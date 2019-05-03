/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Jun 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing class CS_ConfigureRule_Controller
{
	/***********************************************************************************************************
		Members
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Exception Classes & Enums
	public class X_Exception extends Exception{}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Singular
	public Rule__c mp_Rule								{get; set;}
	// This second Rule record is only used to display the second data filter picklist fields
	public Rule__c mp_Rule2								{get; set;}
	
	public string m_strReturl;
	public string m_strRetSection;
	public string m_strPageNo;
	public string m_strPageNoRR;

	public string m_strQuestionType;
	public string m_strFieldDataType1;
	public string m_strFieldDataType2;
	
	public string mp_SectionTitle						{get; set;}

	public boolean	mp_bShowAnswerSource				{get; set;}
	public boolean	mp_bShowQuestions					{get; set;}
	public boolean	mp_bShowRelatedObjectFilter			{get; set;}
	public boolean	mp_bShowQuestionTypes				{get; set;}
	public boolean	mp_bShowDataFilter					{get; set;}

	public boolean	mp_bIsText1							{get; set;}
	public boolean	mp_bIsPicklist1						{get; set;}
	public boolean	mp_bShowValue1						{get; set;}
	public boolean	mp_bDisableDeleteButton1			{get; set;}
	public boolean	mp_bIsText2							{get; set;}
	public boolean	mp_bIsPicklist2						{get; set;}
	public boolean	mp_bShowValue2						{get; set;}
	public boolean	mp_bDisableDeleteButton2			{get; set;}

	public boolean	mp_bShowConfig						{get; set;}
	public boolean	mp_bShowFieldTracking				{get; set;}
	public boolean	mp_bEditMode						{get; set;}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Collections
	private map<id, Question2__c> m_mapQuestions = new map<id, Question2__c>();

	// Data driven picklists
	public list<SelectOption>	mp_liSections						{get; set;}
	public string				mp_strSection						{get; set;}

	public list<SelectOption>	mp_liQuestionTypes					{get; set;}
	public string				mp_strQuestionType					{get; set;}

	public list<SelectOption>	mp_liQuestions						{get; set;}
	public string				mp_strQuestion						{get; set;}

	// Data filters	
	public list<SelectOption>	mp_liFilterPicklist1Values			{get; set;}
	public string				mp_strFilterPicklist1Value			{get; set;}
	public list<SelectOption>	mp_liSelectedPicklist1Values		{get; set;}
	public string				mp_strSelectedPicklist1Value		{get; set;}

	public list<SelectOption>	mp_liFilterPicklist2Values			{get; set;}
	public string				mp_strFilterPicklist2Value			{get; set;}
	public list<SelectOption>	mp_liSelectedPicklist2Values		{get; set;}
	public string				mp_strSelectedPicklist2Value		{get; set;}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Wrapper classes


	/***********************************************************************************************************
		Constructor and Init
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Our Constructor
	public CS_ConfigureRule_Controller()
	{
		mp_Rule2 = new Rule__c();
		
		mp_liSelectedPicklist1Values = new list<SelectOption>();
		
		clearDisplayBooleans();
		
		mp_bShowFieldTracking = false;
		mp_bShowValue1 = false;
		mp_bShowValue2 = false;
		mp_bEditMode = false;
	}

	public pageReference Init()
	{
		try
		{
			// Work out if we are creating or editing a record
			cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');

			string RuleId;
			string answerSource;
			string questionId;
			
			if (sP.contains('id'))
				RuleId	= (string)sP.get('id');

			if (sP.contains('returl'))
				m_strReturl	= (string)sP.get('returl');

			if (sP.contains('section'))
				m_strRetSection	= (string)sP.get('section');

			if (sP.contains('qid'))
				questionId	= (string)sP.get('qid');

			if (sP.contains('source'))
				answerSource	= (string)sP.get('source');

			if (sP.contains('pageNo'))
				m_strPageNo	= (string)sP.get('pageNo');

			if (sP.contains('pageNoRR'))
				m_strPageNoRR	= (string)sP.get('pageNoRR');

			mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_CREATERULE;
			
			buildSectionPicklist();
			
			buildQuestionTypePicklist();
			
			// Have we been given a question?
			if (!string.isBlank(questionId))
			{
				// Prepopulate the Section value
				mp_strSection = m_strRetSection;
				
				// Prepopulate the Answer Source
				mp_Rule = new Rule__c(
					Answer_Source__c = answerSource);
				
				// And the Question
				actionRebuildQuestionPicklist();
				
				mp_strQuestion = questionId;

				return actionShowQuestionTypePicklist();
			}
			
			// Are we editing an existing record?
			if (string.isBlank(RuleId))
			{
				// Prepopulate the Section value if we came here from one of the lists
				if (!string.isBlank(m_strRetSection))
					mp_strSection = m_strRetSection;

				// Prepopulate the Answer Source
				mp_Rule = new Rule__c(Answer_Source__c = answerSource);
				
				// And the Question
				if (!string.isBlank(questionId))
					mp_strQuestion = questionId;
				
				// Decide what to do before returning
				if (answerSource == CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD)
				{
					mp_Rule.Related_Record_Section__c = m_strRetSection;
					
					return actionProcessAnswerSource();
				}
				else if (answerSource == CS_Questions_Utilities.ANSWERSOURCE_QUESTION)
				{
					actionRebuildQuestionPicklist();
					
					return actionGetQuestionType();
				}

				return actionProcessSection();
			}
			else
			{
				mp_Rule =	[	select	id,
										Question2__c,
										Question2__r.Section__c,
										Question2__r.Question_Text__c,
										Question_Type__c,
										Answer_Source__c,
										Question2__r.Answer_Type__c,
										Field_Name__c,
										Field_Name_2__c,
										Field_Name_1__c,
										Field_Data_Type__c,
										Field_Data_Type_2__c,
										Field_Value_Text__c,
										Field_Value_Text_2__c,
										Object_Name__c,
										Object_Name_1__c,
										Object_Name_2__c,
										Operator__c,
										Related_Record_Section__c,
										Related_Object_Name__c,
										Related_Field_name__c,
										Related_Field_Label__c,
										Sequence_Number__c,
										WhatId__c,
										When_to_Ask__c,
										When_to_View__c,
										Help_Text__c,
										Enable_Field_Tracking__c,
										isActive__c
								from	Rule__c
								where	id = : RuleId
										][0];
				
				mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_EDITRULE;
				
				system.debug('*** mp_Rule ***' + mp_Rule);
				
				// Do the relevant processing to set picklists and display booleans
				if (mp_Rule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_QUESTION)
				{
					mp_strSection = mp_Rule.Question2__r.Section__c;
					
					mp_strQuestion			= mp_Rule.Question2__r.Question_Text__c;
					mp_strQuestionType		= mp_Rule.Question_Type__c;

					mp_bShowFieldTracking	= mp_Rule.Question2__r.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_LONGTEXT
											? true
											: false;

					if (mp_Rule.Question_Type__c == CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL)
					{
						
					}
					else
					{
						system.debug('*** mp_Rule ***' + mp_Rule);
						
						mp_Rule.Object_Name__c = mp_Rule.Object_Name_1__c;
						mp_Rule.Field_Name__c = mp_Rule.Field_Name_1__c;
						m_strFieldDataType1 = mp_Rule.Field_Data_Type__c;
						rebuildFilter(true, false);

						if (!string.isBlank(mp_Rule.Object_Name_2__c))
						{
							mp_Rule2.Object_Name__c = mp_Rule.Object_Name_2__c;
							mp_Rule2.Field_Name__c = mp_Rule.Field_Name_2__c;
							m_strFieldDataType2 = mp_Rule.Field_Data_Type_2__c;
							rebuildFilter(false, true);
						}
						
						mp_bDisableDeleteButton1 = true;
						mp_bDisableDeleteButton2 = true;
						
						if (mp_Rule.Field_Data_Type__c == 'PICKLIST' && !string.isBlank(mp_Rule.Field_Value_Text__c))
						{
							mp_liSelectedPicklist1Values = new list<SelectOption>();

							list<string> li_SelectedValues = (list<string>)JSON.deserialize(mp_Rule.Field_Value_Text__c, list<string>.class);
							
							for (string value : li_SelectedValues)
							{
								mp_liSelectedPicklist1Values.add(new SelectOption(value, value));
							}
							
							mp_bDisableDeleteButton1 = false;
							
							// Remove selected values from the available list
							for (SelectOption so : mp_liSelectedPicklist1Values)
							{
								mp_liFilterPicklist1Values = actionRemoveValueFromPicklist(mp_liFilterPicklist1Values, so.getValue(), true, false);
							}
						}

						if (mp_Rule.Field_Data_Type_2__c == 'PICKLIST' && !string.isBlank(mp_Rule.Field_Value_Text_2__c))
						{
							mp_liSelectedPicklist2Values = new list<SelectOption>();

							list<string> li_SelectedValues = (list<string>)JSON.deserialize(mp_Rule.Field_Value_Text_2__c, list<string>.class);
							
							for (string value : li_SelectedValues)
							{
								mp_liSelectedPicklist2Values.add(new SelectOption(value, value));
							}
							
							mp_bDisableDeleteButton2 = false;

							// Remove selected values from the available list
							for (SelectOption so : mp_liSelectedPicklist2Values)
							{
								mp_liFilterPicklist2Values = actionRemoveValueFromPicklist(mp_liFilterPicklist2Values, so.getValue(), true, false);
							}
						}
					}
					
					actionShowConfig();
					
					if (!string.isBlank(mp_Rule.Field_Data_Type__c))
						mp_bShowValue1 = true;
					
					if (!string.isBlank(mp_Rule.Field_Data_Type_2__c))
						mp_bShowValue2 = true;

					mp_bEditMode = true;
				}
				else if (mp_Rule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD)
				{
					system.debug('*** mp_Rule ***' + mp_Rule);
					
					mp_strSection = m_strRetSection;
					mp_bShowAnswerSource = true;
					mp_bShowRelatedObjectFilter = true;
					mp_bShowConfig = true;					
					mp_bEditMode = true;
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
	//	STEP 1 - CHOOSE A SECTION
	public pageReference actionProcessSection()
	{
		// Reset display
		clearDisplayBooleans();
		clearRuleDataFilter1();
		clearRuleDataFilter2();

		mp_bShowAnswerSource = true;
		mp_bEditMode = false;
		
		// Discard any changes to the record
		mp_Rule = new Rule__c();
		
		// Clear picklists
		mp_strQuestion = null;
		mp_strQuestionType = null;
		
		mp_Rule.Object_Name__c = null;
		mp_Rule2.Object_Name__c = null;

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	STEP 2 - CHOOSE THE SOURCE
	public pageReference actionProcessAnswerSource()
	{
		// Clear picklists
		mp_strQuestion = null;
		mp_strQuestionType = null;

		if (mp_Rule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_QUESTION)
		{
			return actionRebuildQuestionPicklist();
		}
		else if (mp_Rule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD)
		{
			// Reset display
			clearDisplayBooleans();
			clearRuleDataFilter1();
			clearRuleDataFilter2();

			mp_bShowAnswerSource = true;
			mp_bShowRelatedObjectFilter = true;
			mp_bShowConfig = true;
			
			mp_Rule.Related_Record_Section__c = mp_strSection;
			
			mp_Rule.Object_Name__c = null;
			mp_Rule2.Object_Name__c = null;
		}
		
		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	STEP 3A - SOURCE IS QUESTION - CHOOSE A QUESTION AND QUESTION TYPE
	public pageReference actionRebuildQuestionPicklist()
	{
		try
		{
			// Reset display
			clearDisplayBooleans();
			clearRuleDataFilter1();
			clearRuleDataFilter2();

			mp_bShowAnswerSource = true;
			mp_bShowQuestions = true;

			// Clear picklists
			mp_strQuestion = null;
			mp_strQuestionType = null;
			
			mp_Rule.Object_Name__c = null;
			mp_Rule2.Object_Name__c = null;
			
			// Build the picklist
			mp_liQuestions = new list<SelectOption>();
			mp_liQuestions.add(new SelectOption(' ', 'Please select'));
			
			m_mapQuestions = new map<id, Question2__c>();
			
			// Get the Question values
			for (Question2__c sQuestion :	[	select	id,
														Question_Text__c,
														Answer_Type__c,
														Answer_Picklist_Values__c,
														Minimum_Length__c,
														Maximum_Length__c,
														isMandatory__c
												from	Question2__c
												where	Section__c = : mp_strSection
												and		isActive__c = true
												order by Question_Text__c
											])
			{
				m_mapQuestions.put(sQuestion.id, sQuestion);
				mp_liQuestions.add(new SelectOption(sQuestion.id, sQuestion.Question_Text__c));
			}
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionShowQuestionTypePicklist()
	{
		// Reset display
		clearDisplayBooleans();
		clearRuleDataFilter1();
		clearRuleDataFilter2();

		mp_bShowAnswerSource = true;
		mp_bShowQuestions = true;
		mp_bShowQuestionTypes = true;

		// Clear picklists
		mp_strQuestionType = null;
		
		mp_Rule.Object_Name__c = null;
		mp_Rule2.Object_Name__c = null;
		
		// Check if we should show Field Tracking option
		Question2__c sQuestion2 = m_mapQuestions.get(mp_strQuestion);
		
		mp_bShowFieldTracking	= sQuestion2.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_LONGTEXT
								? true
								: false;

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	
	public pageReference actionGetQuestionType()
	{
		// Ignore if nothing selected
		if (string.isBlank(mp_strQuestionType))
			return null;

		// Reset display
		clearDisplayBooleans();		
		clearRuleDataFilter1();
		clearRuleDataFilter2();
		
		mp_bShowAnswerSource = true;
		mp_bShowQuestions = true;
		mp_bShowQuestionTypes = true;
		
		mp_Rule.Object_Name__c = null;
		mp_Rule2.Object_Name__c = null;

		// Save the selection
		mp_Rule.Question_Type__c = mp_strQuestionType;
		m_strQuestionType = mp_Rule.Question_Type__c;

		if (mp_Rule.Question_Type__c != CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL)
		{
			mp_bShowDataFilter = true;
		}
		else
		{
			mp_bShowConfig = true;
		}

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	STEP 3A1 - SOURCE IS QUESTION - QUESTION TYPE IS GENERAL OR SPECIFIC
	public pageReference actionChangeObject1()
	{
		clearRuleDataFilter1();
		
		return null;
	}

	public pageReference actionChangeObject2()
	{
		clearRuleDataFilter2();
		
		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionRebuildFilter1()
	{
		try
		{
			mp_bShowValue1 = true;
			
			// Clear field data type
			m_strFieldDataType1	= null;
			
			// Clear data types
			mp_bIsText1		= false;
			mp_bIsPicklist1	= false;

			return rebuildFilter(true, false);
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionRebuildFilter2()
	{
		try
		{
			mp_bShowValue2 = true;
			
			// Clear field data type
			m_strFieldDataType2	= null;
			
			// Clear data types
			mp_bIsText2		= false;
			mp_bIsPicklist2	= false;

			return rebuildFilter(false, true);
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference rebuildFilter(boolean bIsFirstFilter, boolean bIsSecondFilter)
	{
		// Validate the Data Filter and show appropriate value field

		// Query the schema for the selected object and field
		if (bIsFirstFilter && !string.isBlank(mp_Rule.Field_Name__c))
		{
			SObjectField sObjField = getSObjectField(mp_Rule.Object_Name__c, mp_Rule.Field_Name__c);
			DescribeFieldResult descFieldResult = SObjField.getDescribe();
			m_strFieldDataType1 = sObjField.getDescribe().getType().Name();

			if (!isValidDataType(m_strFieldDataType1))
			{
				// Invalid field selection
				ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Field data type of ' + m_strFieldDataType1 + ' is not valid');
				ApexPages.addMessage(msg);
				return null;
			}
			
			// Save the selection
			mp_Rule.Object_Name_1__c = mp_Rule.Object_Name__c;
			mp_Rule.Field_Name_1__c = mp_Rule.Field_Name__c;
			mp_Rule.Field_Data_Type__c = m_strFieldDataType1;
			
			// Set display flag
			if (m_strFieldDataType1 == 'STRING')
			{
				// Text
				mp_bIsText1 = true;
			}
			else if (m_strFieldDataType1 == 'PICKLIST')
			{
				// Check that there are some entries to show
				if (descFieldResult.getPicklistValues().size() < 2)
				{
					ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.PICKLISTEMPTY);
					ApexPages.addMessage(msg);
					return null;
				}
	
				// Picklist
				mp_bIsPicklist1 = true;
				
				mp_liSelectedPicklist1Values = new list<SelectOption>();
				mp_liSelectedPicklist1Values.add(new SelectOption(' ', '--None--'));
				mp_bDisableDeleteButton1 = true;
				
				// Get values from the schema
				mp_liFilterPicklist1Values = new list<SelectOption>();
				mp_liFilterPicklist1Values.add(new SelectOption(' ', 'Please select'));
				
				for (schema.PicklistEntry sPLE : descFieldResult.getPicklistValues())
				{
					if (sPLE.isActive())
						mp_liFilterPicklist1Values.add(new SelectOption(sPLE.getValue(), sPLE.getLabel()));
				}		
			}
		}
		else if (bIsSecondFilter && !string.isBlank(mp_Rule2.Field_Name__c))
		{
			system.debug('*** mp_Rule ***' + mp_Rule);
			
			SObjectField sObjField = getSObjectField(mp_Rule2.Object_Name__c, mp_Rule2.Field_Name__c);
			DescribeFieldResult descFieldResult = SObjField.getDescribe();
			m_strFieldDataType2 = sObjField.getDescribe().getType().Name();

			if (!isValidDataType(m_strFieldDataType2))
			{
				// Invalid field selection
				ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Field data type of ' + m_strFieldDataType2 + ' is not valid');
				ApexPages.addMessage(msg);
				return null;
			}
			
			// Save the selection
			mp_Rule.Object_Name_2__c = mp_Rule2.Object_Name__c;
			mp_Rule.Field_Name_2__c = mp_Rule2.Field_Name__c;
			mp_Rule.Field_Data_Type_2__c = m_strFieldDataType2;
			
			// Set display flag
			if (m_strFieldDataType2 == 'STRING')
			{
				// Text
				mp_bIsText2 = true;
			}
			else if (m_strFieldDataType2 == 'PICKLIST')
			{
				// Check that there are some entries to show
				if (descFieldResult.getPicklistValues().size() < 2)
				{
					ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.PICKLISTEMPTY);
					ApexPages.addMessage(msg);
					return null;
				}
	
				// Picklist
				mp_bIsPicklist2 = true;

				mp_liSelectedPicklist2Values = new list<SelectOption>();
				mp_liSelectedPicklist2Values.add(new SelectOption(' ', '--None--'));
				mp_bDisableDeleteButton2 = true;
				
				// Get values from the schema
				mp_liFilterPicklist2Values = new list<SelectOption>();
				mp_liFilterPicklist2Values.add(new SelectOption(' ', 'Please select'));
				
				for (schema.PicklistEntry sPLE : descFieldResult.getPicklistValues())
				{
					if (sPLE.isActive())
						mp_liFilterPicklist2Values.add(new SelectOption(sPLE.getValue(), sPLE.getLabel()));
				}		
			}
		}
		
		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionAddSelectedFilterValue1()
	{
		try
		{
			mp_liSelectedPicklist1Values = actionAddValueToPicklist(mp_liSelectedPicklist1Values, mp_strFilterPicklist1Value, false);

			// Rebuild the selection picklist
			mp_liFilterPicklist1Values = actionRemoveValueFromPicklist(mp_liFilterPicklist1Values, mp_strFilterPicklist1Value, true, false);
			
			mp_bDisableDeleteButton1 = false;
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionDeselectedPicklistValue1()
	{
		// Remove the selected value
		mp_liSelectedPicklist1Values = actionRemoveValueFromPicklist(mp_liSelectedPicklist1Values, mp_strSelectedPicklist1Value, false, true);
		
		mp_liFilterPicklist1Values = actionAddValueToPicklist(mp_liFilterPicklist1Values, mp_strSelectedPicklist1Value, true);
		
		if (mp_liSelectedPicklist1Values.size() == 1)
			mp_bDisableDeleteButton1 = true;
		
		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionAddSelectedFilterValue2()
	{
		try
		{
			mp_liSelectedPicklist2Values = actionAddValueToPicklist(mp_liSelectedPicklist2Values, mp_strFilterPicklist2Value, false);

			// Rebuild the selection picklist
			mp_liFilterPicklist2Values = actionRemoveValueFromPicklist(mp_liFilterPicklist2Values, mp_strFilterPicklist2Value, true, false);
			
			mp_bDisableDeleteButton2 = false;
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionDeselectedPicklistValue2()
	{
		// Remove the selected value
		mp_liSelectedPicklist2Values = actionRemoveValueFromPicklist(mp_liSelectedPicklist2Values, mp_strSelectedPicklist2Value, false, true);
		
		mp_liFilterPicklist2Values = actionAddValueToPicklist(mp_liFilterPicklist2Values, mp_strSelectedPicklist2Value, true);

		if (mp_liSelectedPicklist2Values.size() == 1)
			mp_bDisableDeleteButton2 = true;

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionValidateDataFilter()
	{
		// First validate the data filter
		try
		{
			// First validate the data filter
			if (!validateDataFilter())
				return null;
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		mp_bShowConfig = true;

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionShowConfig()
	{
		// Reset display
		clearDisplayBooleans();
		mp_bShowAnswerSource = true;
		mp_bShowQuestions = true;
		mp_bShowQuestionTypes = true;
		mp_bShowDataFilter = true;
		mp_bShowConfig = true;

		if (mp_Rule.Question_Type__c == CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL)
			mp_bShowDataFilter = false;
		
		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionSave()
	{
		try
		{
			if (!validateDataFilter())
				return null;

			if (!validateConfig())
				return null;

			// Save the record
			saveRule();
			
			mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_EDITRULE;
			mp_bEditMode = true;
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionSaveandNew()
	{
		try
		{
			if (!validateDataFilter())
				return null;

			if (!validateConfig())
				return null;

			// Save the record
			saveRule();
			
			mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_CREATERULE;

			return actionProcessSection();
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionSaveandReturn()
	{
		try
		{
			if (!validateDataFilter())
				return null;

			if (!validateConfig())
				return null;

			// Save the record
			saveRule();
			
			return actionCancel();
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}

		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionClone()
	{
		try
		{
			system.debug('*** mp_Rule ***' + mp_Rule);

			if (!validateDataFilter())
				return null;

			if (!validateConfig())
				return null;

			// Save the record
			saveRule();
			
			mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_CREATERULE;
			mp_strFilterPicklist1Value = null;
			mp_strFilterPicklist2Value = null;
			mp_liSelectedPicklist1Values = new list<SelectOption>();
			mp_liSelectedPicklist1Values.add(new SelectOption(' ', '--None--'));
			mp_liSelectedPicklist2Values = new list<SelectOption>();
			mp_liSelectedPicklist2Values.add(new SelectOption(' ', '--None--'));

			// Prepare the record
			mp_Rule.id							= null;
			mp_Rule.Object_Name__c				= null;
			mp_Rule.Object_Name_1__c			= null;
			mp_Rule.Field_Name_1__c				= null;
			mp_Rule.Object_Name_2__c			= null;
			mp_Rule.Field_Name_2__c				= null;
			mp_Rule.Field_Name__c				= null;
			mp_Rule.Related_Object_Name__c		= null;
			mp_Rule.Related_Field_Name__c		= null;
			mp_Rule.Related_Field_Label__c		= null;
			mp_Rule.Field_Value_Text__c			= null;
			mp_Rule.Field_Value_Text_2__c		= null;
			
			system.debug('*** mp_Rule ***' + mp_Rule);
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
		pageReference pageRef;
		
		CS_Questions_Utilities.clearSessionCache();
		
		if (m_strReturl == 'cs_rulesbysection')
		{
			cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
			
			if (!string.isBlank(mp_strSection))
				sP.put('section', mp_strSection);
			
			if (m_strPageNo != null)
				sP.put('pageNo', m_strPageNo);
			
			if (m_strPageNoRR != null)
				sP.put('pageNoRR', m_strPageNoRR);

			pageRef = page.CS_RulesBySection;
		}
		else
		{
			pageRef = new pageReference('/o');
		}			

		pageRef.setRedirect(true);
		return pageRef;
	}


	/***********************************************************************************************************
		Helper methods
	***********************************************************************************************************/

	/***********************************************************************************************************
		Picklist utility methods
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public list<SelectOption> actionAddValueToPicklist(list<SelectOption> li_SOIn, string value, boolean bShowSelect)
	{
		// Remove the selected value
		list<SelectOption> li_SOOut = new list<SelectOption>();
		
		if (bShowSelect)
			li_SOOut.add(new SelectOption(' ', 'Please select'));

		// Loop through the ist to remove null values
		for (SelectOption so : li_SOIn)
		{
			if (!string.isBlank(so.getValue()))
				li_SOOut.add(so);
		}

		li_SOOut.add(new SelectOption(value, value));
		
		return li_SOOut;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public list<SelectOption> actionRemoveValueFromPicklist(list<SelectOption> li_SOIn, string value, boolean bShowSelect, boolean bShowNone)
	{
		// Remove the selected value
		list<SelectOption> li_SOOut = new list<SelectOption>();
		
		if (bShowSelect)
			li_SOOut.add(new SelectOption(' ', 'Please select'));
		
		for (SelectOption so : li_SOIn)
		{
			if (so.getValue() != value && !string.isBlank(so.getValue()))
				li_SOOut.add(so);
		}
		
		if (bShowNone && li_SOOut.isEmpty())
			li_SOOut.add(new SelectOption(' ', '--None--'));
		
		return li_SOOut;
	}


	/***********************************************************************************************************
		Other methods
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private boolean validateDataFilter()
	{
		// Basic validation
		boolean bIsValid = true;
		
		if (mp_Rule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD ||
			mp_Rule.Question_Type__c == CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL)
			return bIsValid;

		// Get selected picklist values
		set<string> set_SelectedPicklist1Values = new set<string>();
		
		for (SelectOption so : mp_liSelectedPicklist1Values)
		{
			if (!string.isBlank(so.getValue()))
				set_SelectedPicklist1Values.add(so.getValue());
		}

		set<string> set_SelectedPicklist2Values = new set<string>();
		
		if (mp_liSelectedPicklist2Values != null)
		{
			for (SelectOption so : mp_liSelectedPicklist2Values)
			{
				if (!string.isBlank(so.getValue()))
					set_SelectedPicklist2Values.add(so.getValue());
			}
		}		
		
		// Now check data was supplied
		if (string.isBlank(mp_Rule.Object_Name_1__c))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_OBJECT));
			bIsValid = false;
		}

		if (string.isBlank(mp_Rule.Field_Name_1__c))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_FIELD));
			bIsValid = false;
		}

		if (m_strFieldDataType1 == 'STRING' && string.isBlank(mp_Rule.Field_Value_text__c))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_VALUE));
			bIsValid = false;
		}
		else if (m_strFieldDataType1 == 'PICKLIST' && set_SelectedPicklist1Values.isEmpty())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_VALUE));
			bIsValid = false;
		}

		// Optional second filter
		if (!string.isBlank(mp_Rule.Object_Name_2__c))
		{
			if (string.isBlank(mp_Rule.Field_Name_2__c))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_FIELD));
				bIsValid = false;
			}

			if (m_strFieldDataType2 == 'STRING' && string.isBlank(mp_Rule.Field_Value_Text_2__c))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_VALUE));
				bIsValid = false;
			}
			else if (m_strFieldDataType2 == 'PICKLIST' && set_SelectedPicklist2Values.isEmpty())
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_VALUE));
				bIsValid = false;
			}
		}
		
		// Stop here if validation failed
		if (!bIsValid)
			return bIsValid;

		// Build a query to validate the filter will match records
		string strQuery = 'select id from ' + mp_Rule.Object_Name_1__c + ' where ';
	
		// Add filter criteria depending on data type
		if (m_strFieldDataType1 == 'STRING')
		{
			// Text / picklist field
			strQuery += mp_Rule.Field_Name_1__c + ' = \'' + mp_Rule.Field_Value_Text__c + '\'';
		}
		else if (m_strFieldDataType1 == 'PICKLIST')
		{
			// Text / picklist field
			strQuery += mp_Rule.Field_Name_1__c + ' in : set_SelectedPicklist1Values';
		}
		
		strQuery += ' limit 1000';
				
		// Execute the query
		list<sObject> li_sObj = database.query(strQuery);
		
		// Check that we found some records
		if (li_sObj.isEmpty())
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, CS_Questions_Utilities.VALIDATIONFILTER_NOMATCH));
		}
/*
		if (mp_Rule.Question_Type__c == CS_Questions_Utilities.QUESTIONTYPE_SPECIFIC && li_sObj.size() > 1)
		{
			// Check that we found one - and only one - record
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONFILTER_TOOMANY));
			bIsValid = false;
		}
			
		if (mp_Rule.Question_Type__c == CS_Questions_Utilities.QUESTIONTYPE_SPECIFIC && bIsValid)
		{
			// All good - get the record id
			sObject sObj = li_sObj[0];
		
			mp_Rule.WhatId__c= string.valueOf(sObj.get('id'));
		}
*/
		// Stop here if validation failed
		if (!bIsValid)
			return bIsValid;

		// Optional second filter
		if (!string.isBlank(mp_Rule.Object_Name_2__c))
		{
			strQuery = 'select id from ' + mp_Rule.Object_Name_2__c + ' where ';
		
			// Add filter criteria depending on data type
			if (m_strFieldDataType2 == 'STRING')
			{
				// Text / picklist field
				strQuery += mp_Rule.Field_Name_2__c + ' = \'' + mp_Rule.Field_Value_Text_2__c + '\'';
			}
			else if (m_strFieldDataType2 == 'PICKLIST')
			{
				// Text / picklist field
				strQuery += mp_Rule.Field_Name_2__c + ' in : set_SelectedPicklist2Values';
			}
					
			strQuery += ' limit 1000';
					
			// Execute the query
			li_sObj = database.query(strQuery);
			
			// Check that we found some records
			if (li_sObj.isEmpty())
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, CS_Questions_Utilities.VALIDATIONFILTER_NOMATCH));
			}
/*
			if (mp_Rule.Question_Type__c == CS_Questions_Utilities.QUESTIONTYPE_SPECIFIC && li_sObj.size() > 1)
			{
				// Check that we found one - and only one - record
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONFILTER_TOOMANY));
				bIsValid = false;
			}
				
			if (mp_Rule.Question_Type__c == CS_Questions_Utilities.QUESTIONTYPE_SPECIFIC && bIsValid)
			{
				// All good - get the record id
				sObject sObj = li_sObj[0];
			
				mp_Rule.WhatId2__c= string.valueOf(sObj.get('id'));
			}
*/
		}

		return bIsValid;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private boolean validateConfig()
	{
		// Basic validation
		boolean bIsValid = true;

		if (mp_Rule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_QUESTION)
		{
			if (string.isBlank(mp_Rule.When_to_Ask__c))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_WHENTOASK));
				bIsValid = false;
			}

			if (string.isBlank(mp_Rule.When_to_View__c))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_WHENTOVIEW));
				bIsValid = false;
			}

			if (mp_Rule.Sequence_Number__c == null || mp_Rule.Sequence_Number__c == 0)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_SEQNO));
				bIsValid = false;
			}
		}
		else if (mp_Rule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD)
		{
			if (string.isBlank(mp_Rule.Related_Field_Label__c))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_RELATEDDATALABEL));
				bIsValid = false;
			}

			if (string.isBlank(mp_Rule.Related_Object_Name__c))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_RELATEDOBJECT));
				bIsValid = false;
			}
	
			if (string.isBlank(mp_Rule.Related_Field_Name__c))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_RELATEDFIELD));
				bIsValid = false;
			}

			if (string.isBlank(mp_Rule.When_to_View__c))
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_WHENTOVIEW));
				bIsValid = false;
			}

			if (mp_Rule.Sequence_Number__c == null || mp_Rule.Sequence_Number__c == 0)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_SEQNO));
				bIsValid = false;
			}

			// Stop here if validation failed
			if (!bIsValid)
				return bIsValid;

			// Validate the Field Type
			map<string, SObjectType> map_ObjectToSObjectTypes = Schema.getGlobalDescribe();
	
			// Query the schema for the selected object and field		
			SObjectType sObjType = map_ObjectToSObjectTypes.get(mp_Rule.Related_Object_Name__c.toLowerCase());
			mp_Rule.Related_Object_Label__c = sObjType.getDescribe().getLabel();
			
			string fieldDataType;
			
			// If using dot notation we will get an error here
			if (!mp_Rule.Related_Field_Name__c.contains('.'))
			{
				SObjectField sObjField = sObjType.getDescribe().fields.getMap().get(mp_Rule.Related_Field_Name__c.toLowerCase());
				fieldDataType = sObjField.getDescribe().getType().Name();
			}
			else
			{
				// Cater for dot notation
				
				// First build a map of relationship name to sObjectType for the related object
				map<string, SObjectType> mapRelationships = new map<string, SObjectType>();
				
				for (SObjectField sObjField : sObjType.getDescribe().fields.getMap().values())
				{
					if (sObjField.getDescribe().getType().Name() == 'REFERENCE' && !sObjField.getDescribe().isNamePointing())
						mapRelationships.put(sObjField.getDescribe().getRelationshipName().toLowerCase(), sObjField.getDescribe().getReferenceTo()[0]);
				}

				// Now work out what is the top level parent object and field name
				string relationshipName;
				string fieldName = mp_Rule.Related_Field_Name__c.toLowerCase();

				do
				{
					integer index = fieldName.indexOf('.');
					relationshipName = fieldName.subString(0, index);
					fieldName = fieldName.subString(index + 1, fieldName.length());
				}
				while (fieldName.contains('.'));
				
				system.debug('*** relationshipName ***' + relationshipName);
				system.debug('*** fieldName ***' + fieldName);
				
				SObjectType sObjTypeParent = mapRelationships.get(relationshipName.toLowerCase());

				SObjectField sObjFieldParent = sObjTypeParent.getDescribe().fields.getMap().get(fieldName.toLowerCase());
				fieldDataType = sObjFieldParent.getDescribe().getType().Name();
				
				system.debug('*** fieldDataType ***' + fieldDataType);
			}

			// Validate the data type, then determine how to filter the data
//			set<string> set_InvalidFieldDataTypes = new set<string>{
//				'REFERENCE', 'BOOLEAN', 'CURRENCY', 'DATE', 'DATETIME', 'EMAIL', 'DOUBLE',
//				'PERCENT', 'PHONE', 'MULTIPICKLIST', 'TEXTAREA', 'URL', 'ID', 'INTEGER', 'ADDRESS'
//			};
	
			set<string> set_ValidFieldDataTypes = new set<string>{
				'PICKLIST', 'STRING', 'BOOLEAN', 'CURRENCY', 'DATE', 'EMAIL', 'DOUBLE', 'PHONE', 'TEXTAREA', 'URL', 'INTEGER'
			};
	
			if (!set_ValidFieldDataTypes.contains(fieldDataType))
			{
				// Invalid field selection
				ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR,'Related Field data type of ' + fieldDataType + ' is not valid');
				ApexPages.addMessage(msg);
				return null;
			}
		}
			
		// Lastly, check that the sequence number is not already in use
		for (Rule__c sRule :	[	select	id,
											Question2__r.Section__c,
											Question_Type__c,
											Answer_Source__c,
											Related_Record_Section__c,
											Sequence_Number__c
									from	Rule__c
								])
		{
			if (sRule.id == mp_Rule.id)
				continue;

			if (sRule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_QUESTION &&
				sRule.Question2__r.Section__c == mp_strSection &&
				mp_Rule.Sequence_Number__c == sRule.Sequence_Number__c)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_SEQNOINUSE));
				bIsValid = false;

				break;
			}
				
			if (sRule.Answer_Source__c == CS_Questions_Utilities.ANSWERSOURCE_RELATEDRECORD &&
				sRule.Related_Record_Section__c == mp_strSection &&
				mp_Rule.Sequence_Number__c == sRule.Sequence_Number__c)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_SEQNOINUSE));
				bIsValid = false;

				break;
			}
		}
		
		return bIsValid;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void saveRule()
	{
		try
		{
			system.debug('*** mp_Rule ***' + mp_Rule);
			
			// Link to the Question record
			if (mp_Rule.Question2__c == null && m_mapQuestions.containsKey(mp_strQuestion))
			{
				Question2__c sQuestion2 = m_mapQuestions.get(mp_strQuestion);
				
				mp_Rule.Question2__c				= sQuestion2.id;
			}

			mp_Rule.Question_Type__c = mp_strQuestionType;
			
			// Handle Data Filter picklists
			if (mp_Rule.Field_Data_Type__c == 'PICKLIST')
			{
				list<string> li_SelectedValues = new list<string>();
				
				for (SelectOption so : mp_liSelectedPicklist1Values)
				{
					if (!string.isBlank(so.getValue()))
						li_SelectedValues.add(so.getValue());
				}
				
				mp_Rule.Field_Value_Text__c = JSON.serialize(li_SelectedValues);
			}
			
			if (mp_Rule.Field_Data_Type_2__c == 'PICKLIST')
			{
				list<string> li_SelectedValues = new list<string>();
				
				for (SelectOption so : mp_liSelectedPicklist2Values)
				{
					if (!string.isBlank(so.getValue()))
						li_SelectedValues.add(so.getValue());
				}
				
				mp_Rule.Field_Value_Text_2__c = JSON.serialize(li_SelectedValues);
			}
			
			if (!mp_bShowFieldTracking)
				mp_Rule.Enable_Field_Tracking__c = false;
			
			upsert mp_Rule;
	
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.RECORDSAVED));
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void buildSectionPicklist()
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
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void buildQuestionTypePicklist()
	{
		// Build the picklist
		mp_liQuestionTypes = new list<SelectOption>();
		mp_liQuestionTypes.add(new SelectOption(' ', 'Please select'));
		mp_liQuestionTypes.add(new SelectOption(CS_Questions_Utilities.QUESTIONTYPE_GENERAL, CS_Questions_Utilities.QUESTIONTYPELABEL_GENERAL));
		mp_liQuestionTypes.add(new SelectOption(CS_Questions_Utilities.QUESTIONTYPE_UNIVERSAL, CS_Questions_Utilities.QUESTIONTYPELABEL_UNIVERSAL));
//		mp_liQuestionTypes.add(new SelectOption(CS_Questions_Utilities.QUESTIONTYPE_SPECIFIC, CS_Questions_Utilities.QUESTIONTYPELABEL_SPECIFIC));
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private SObjectField getSObjectField(string objectName, string fieldName)
	{
		map<string, SObjectType> map_ObjectToSObjectTypes = Schema.getGlobalDescribe();
		
		system.debug('*** objectName ***' + objectName);
		system.debug('*** fieldName ***' + fieldName);
		system.debug('*** map_ObjectToSObjectTypes ***' + map_ObjectToSObjectTypes.keySet());
		system.debug('*** key found? ***' + map_ObjectToSObjectTypes.containsKey(objectName.toLowerCase()));

		SObjectType sObjType = map_ObjectToSObjectTypes.get(objectName.toLowerCase());
		return sObjType.getDescribe().fields.getMap().get(fieldName.toLowerCase());
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private boolean isValidDataType(string fieldDataType)
	{
		// Validate the data type, then determine how to filter the data
//		set<string> set_InvalidFieldDataTypes = new set<string>{
//			'REFERENCE', 'BOOLEAN', 'CURRENCY', 'DATE', 'DATETIME', 'EMAIL', 'DOUBLE',
//			'PERCENT', 'PHONE', 'MULTIPICKLIST', 'TEXTAREA', 'URL', 'ID', 'INTEGER', 'ADDRESS'
//		};
	
		set<string> set_ValidFieldDataTypes = new set<string>{'PICKLIST', 'STRING'};
	
		return set_ValidFieldDataTypes.contains(fieldDataType);
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void clearRuleDataFilter1()
	{
		mp_bIsText1 = false;
		mp_bIsPicklist1 = false;
		mp_bShowValue1 = false;
		mp_Rule.Operator__c = CS_Questions_Utilities.RULEOPERATOR_EQUALS;
		// Picklists
		mp_Rule.Field_Name__c = null;
		// Selections
		mp_Rule.Field_Data_Type__c = null;
		mp_Rule.Object_Name_1__c = null;
		mp_Rule.Field_Name_1__c = null;
		mp_Rule.Field_Value_Text__c = null;

		mp_liSelectedPicklist1Values = new list<SelectOption>();
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void clearRuleDataFilter2()
	{
		mp_bIsText2 = false;
		mp_bIsPicklist2 = false;
		mp_bShowValue2 = false;
		// Picklists
		mp_Rule2.Field_Name__c = null;
		// Selections
		mp_Rule.Field_Data_Type_2__c = null;
		mp_Rule.Object_Name_2__c = null;
		mp_Rule.Field_Name_2__c = null;
		mp_Rule.Field_Value_Text_2__c = null;

		mp_liSelectedPicklist2Values = new list<SelectOption>();
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void clearDisplayBooleans()
	{
		// Reset display booleans
		mp_bShowAnswerSource			= false;
		mp_bShowQuestions				= false;
		mp_bShowQuestionTypes			= false;
		mp_bShowRelatedObjectFilter		= false;
		mp_bShowDataFilter				= false;
		mp_bShowConfig					= false;
	}

}
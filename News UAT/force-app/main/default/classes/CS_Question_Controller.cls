/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Jun 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing class CS_Question_Controller
{
	/***********************************************************************************************************
		Members
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Exception Classes & Enums
	public class X_Exception extends Exception{}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Singular
	public Question2__c mp_Question						{get; set;}
	
	public string	mp_SectionTitle						{get; set;}
	public string	m_strPageNo;
	
	public string mp_NewAnswerValue						{get; set;}
	
	public boolean	mp_bShowAnswerPicklistValues		{get; set;}
	public boolean	mp_bShowMinMaxLength				{get; set;}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Collections
	// Answer picklist values
	public list<SelectOption>	mp_liAnswerPicklistValues			{get; set;}
	public string				mp_strAnswerPicklistValue			{get; set;}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Wrapper classes


	/***********************************************************************************************************
		Constructor
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Our Constructor
	public CS_Question_Controller()
	{
		mp_bShowAnswerPicklistValues	= false;
		mp_bShowMinMaxLength			= false;
	}

	public pageReference Init()
	{
		try
		{
			cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');

			// Work out if we are creating or editing a record			
			string questionId;
			
			if (sP.contains('id'))
				questionId	= (string)sP.get('id');

			// Save the record number so we can return it
			if (sP.contains('pageNo'))
				m_strPageNo	= (string)sP.get('pageNo');

			if (string.isBlank(questionId))
			{
				mp_Question = new Question2__c();
				mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_CREATE;
			}
			else
			{
				mp_Question =	[	select	id,
											Name,
											Section__c,
											Question_Text__c,
											Answer_Type__c,
											Answer_Picklist_Values__c,
											Minimum_Length__c,
											Maximum_Length__c,
											isMandatory__c,
											isActive__c
									from	Question2__c
									where	id = : questionId
											][0];
	
				mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_EDIT;
				
				return actionProcessAnswerType();
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
	public pageReference actionProcessAnswerType()
	{
		if (string.isBlank(mp_Question.Answer_Type__c))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ANSWERTYPE));
			return null;
		}
		
		// Decide if we can show the Min / Max length validation fields
		mp_bShowMinMaxLength = false;
		
		if (mp_Question.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_CURRENCY ||
			mp_Question.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_NUMBER ||
			mp_Question.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_PHONE ||
			mp_Question.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_TEXT)
		{
				mp_bShowMinMaxLength = true;
		}
		else
		{
			// Clear min / max
			mp_Question.Minimum_Length__c = null;
			mp_Question.Maximum_Length__c = null;
		}

		try
		{
			if (mp_Question.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_PICKLIST)
			{
				mp_bShowAnswerPicklistValues = true;
				
				mp_liAnswerPicklistValues = new list<SelectOption>();
				
				if (!string.isBlank(mp_Question.Answer_Picklist_Values__c))
				{
					list<CS_Questions_Utilities.PicklistWrapper> li_PicklistWrappers = (list<CS_Questions_Utilities.PicklistWrapper>)JSON.deserialize(mp_Question.Answer_Picklist_Values__c, list<CS_Questions_Utilities.PicklistWrapper>.class);
					
					for (CS_Questions_Utilities.PicklistWrapper PicklistWrapper : li_PicklistWrappers)
						mp_liAnswerPicklistValues.add(new SelectOption(PicklistWrapper.value, PicklistWrapper.label));
				}
			}
			else
			{
				mp_bShowAnswerPicklistValues = false;
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
	public pageReference actionSave()
	{
		try
		{
			// Validate
			if (!validateQuestion(mp_Question))
				return null;

			upsertQuestion(mp_Question);
	
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.RECORDSAVED));
			
			mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_EDIT;
			
			return actionProcessAnswerType();
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
			// Validate
			if (!validateQuestion(mp_Question))
				return null;

			upsertQuestion(mp_Question);
			
			// Save the Section value
			string strSection = mp_Question.Section__c;
	
			// Reinitialise the record
			mp_Question = new Question2__c(Section__c = strSection);
			
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, CS_Questions_Utilities.RECORDSAVED));
			
			mp_SectionTitle = CS_Questions_Utilities.SECTIONTITLE_CREATE;

			return actionProcessAnswerType();
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
			// Validate
			if (!validateQuestion(mp_Question))
				return null;

			upsertQuestion(mp_Question);

			return actionReturn();
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}
		
		return null;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionReturn()
	{
		cache.SessionPartition sP = cache.Session.getPartition('local.CSQuestionnaire');
			
		if (m_strPageNo != null)
			sP.put('pageNo', m_strPageNo);

		pageReference pageRef = page.CS_Questions;
		pageRef.setRedirect(true);
		return pageRef;
	}


	/***********************************************************************************************************
		Worker methods
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public boolean validateQuestion(Question2__c sQuestion)
	{
		boolean bIsValid = true;
		
		if (string.isBlank(sQuestion.Section__c))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_SECTION));
			bIsValid = false;
		}
		
		if (string.isBlank(sQuestion.Question_Text__c))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_QUESTION));
			bIsValid = false;
		}

		if (string.isBlank(sQuestion.Answer_Type__c))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ANSWERTYPE));
			bIsValid = false;
		}
		
		// Picklist
		if (mp_Question.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_PICKLIST)
		{
			if (mp_liAnswerPicklistValues.isEmpty())
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ANSWERPICKLISTVALUE));
				bIsValid = false;
			}
		}

		// Min / max length sanity check
		if (mp_bShowMinMaxLength)
		{
			if (mp_Question.Minimum_Length__c != null && mp_Question.Minimum_Length__c == 0)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_MINMAXZERO));
				bIsValid = false;
			}

			if (mp_Question.Maximum_Length__c != null && mp_Question.Maximum_Length__c == 0)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_MINMAXZERO));
				bIsValid = false;
			}

			if (mp_Question.Minimum_Length__c != null && mp_Question.Maximum_Length__c != null && 
				mp_Question.Minimum_Length__c > mp_Question.Maximum_Length__c)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_MINGTMAX));
				bIsValid = false;
			}
		}
		
		return bIsValid;
	}


	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public void upsertQuestion(Question2__c sQuestion)
	{
		// Save picklist values
		if (sQuestion.Answer_Type__c == CS_Questions_Utilities.ANSWERTYPE_PICKLIST)
		{
			list<CS_Questions_Utilities.PicklistWrapper> li_PicklistWrappers = new list<CS_Questions_Utilities.PicklistWrapper>();
			
			for (SelectOption so : mp_liAnswerPicklistValues)
				li_PicklistWrappers.add(new CS_Questions_Utilities.PicklistWrapper(so.getValue(), so.getLabel()));
			
			sQuestion.Answer_Picklist_Values__c = JSON.serialize(li_PicklistWrappers);
		}

		// If inactive, mark any child Rules as inactive as well
		if (sQuestion.id != null && sQuestion.isActive__c == false)
		{
			list<Rule__c> li_RulestoInactivate = new list<Rule__c>();

			for (Rule__c sRule :	[	select	id,
												isActive__c
										from	Rule__c
										where	Question2__c = : sQuestion.id
									])
			{
				// Only update Active Rules
				if (sRule.isActive__c)
				{
					sRule.isActive__c = false;
					li_RulestoInactivate.add(sRule);
				}
			}
		
			if (!li_RulestoInactivate.isEmpty())
				update li_RulestoInactivate;
		}

		upsert sQuestion;
	}


	/***********************************************************************************************************
		Picklist utility methods
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionAdd()
	{
		if (string.isBlank(mp_NewAnswerValue))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ANSWERPICKLISTVALUE));
			return null;
		}
		
		mp_liAnswerPicklistValues.add(new SelectOption(mp_NewAnswerValue, mp_NewAnswerValue));
		mp_NewAnswerValue = null;
		
		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionDelete()
	{
		if (string.isBlank(mp_strAnswerPicklistValue))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ANSWERPICKLISTSELECTION));
			return null;
		}
		
		// Remove the selected value
		list<SelectOption> li_AnswerPicklistValues = new list<SelectOption>();
		
		for (SelectOption so : mp_liAnswerPicklistValues)
		{
			if (so.getValue() != mp_strAnswerPicklistValue)
				li_AnswerPicklistValues.add(so);
		}
		
		mp_liAnswerPicklistValues.clear();
		mp_liAnswerPicklistValues.addAll(li_AnswerPicklistValues);
		
		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionMoveUp()
	{
		if (string.isBlank(mp_strAnswerPicklistValue))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ANSWERPICKLISTSELECTION));
			return null;
		}
		
		// Do nothing if we're already at the top
		if (mp_strAnswerPicklistValue == mp_liAnswerPicklistValues[0].getValue())
			return null;
		
		list<SelectOption> li_AnswerPicklistValues = new list<SelectOption>();
		
		for (integer i=0; i < mp_liAnswerPicklistValues.size(); i++)
		{
			SelectOption so;
			
			if (i < mp_liAnswerPicklistValues.size()-1)
			{
				so = mp_liAnswerPicklistValues[i+1];
			}
			else
			{
				li_AnswerPicklistValues.add(mp_liAnswerPicklistValues[i]);
				break;
			}
			
			if (so.getValue() == mp_strAnswerPicklistValue)
			{
				li_AnswerPicklistValues.add(so);
				li_AnswerPicklistValues.add(mp_liAnswerPicklistValues[i]);
				i += 1;
			}
			else
			{
				li_AnswerPicklistValues.add(mp_liAnswerPicklistValues[i]);
			}
		}
		
		mp_liAnswerPicklistValues.clear();
		mp_liAnswerPicklistValues.addAll(li_AnswerPicklistValues);

		return null;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	public pageReference actionMoveDown()
	{
		if (string.isBlank(mp_strAnswerPicklistValue))
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.VALIDATIONERROR_ANSWERPICKLISTSELECTION));
			return null;
		}

		// Do nothing if we're already at the bottom
		if (mp_strAnswerPicklistValue == mp_liAnswerPicklistValues[mp_liAnswerPicklistValues.size()-1].getValue())
			return null;
		
		list<SelectOption> li_AnswerPicklistValues = new list<SelectOption>();
		
		for (integer i=0; i < mp_liAnswerPicklistValues.size(); i++)
		{
			SelectOption so = mp_liAnswerPicklistValues[i];
			
			if (so.getValue() == mp_strAnswerPicklistValue)
			{
				li_AnswerPicklistValues.add(mp_liAnswerPicklistValues[i+1]);
				li_AnswerPicklistValues.add(so);
				i += 1;
			}
			else
			{
				li_AnswerPicklistValues.add(so);
			}
		}
		
		mp_liAnswerPicklistValues.clear();
		mp_liAnswerPicklistValues.addAll(li_AnswerPicklistValues);

		return null;
	}
}
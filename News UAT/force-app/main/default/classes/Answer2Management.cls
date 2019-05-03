/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	Trigger code for Answer2 object
Test Class:		Answer2Management_Test
History
<Date>		<Authors Name>		<Brief Description of Change>
Jul 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing class Answer2Management extends CS_GenericTriggerHandler
{
	/***********************************************************************************************************
		This class performs the processing required by the Answer2Management trigger
		One trigger and one class per object
	***********************************************************************************************************/
	public override void doBeforeInsert(list<SObject> newRecords)
	{
		UpdateChangeHistory(newRecords);
	}
	
	public override void doAfterInsert(map<id, SObject> map_newRecords)
	{
		
	}
	
	public override void doBeforeUpdate(map<id, SObject> map_oldRecords, map<id, SObject> map_newRecords)
	{
		UpdateChangeHistory(map_oldRecords, map_newRecords.values());
	}
	
	public override void doAfterUpdate(map<id, SObject> map_oldRecords, map<id, SObject> map_newRecords)
	{
		
	}

	public override void doBeforeDelete(map<id, SObject> map_oldRecords)
	{
		
	}

	public override void doAfterDelete(map<id, SObject> map_oldRecords)
	{

	}

	public override void doAfterUndelete(map<id, SObject> map_newRecords)
	{
	
	}


	/***********************************************************************************************************
		Internal classes here
	***********************************************************************************************************/


	/***********************************************************************************************************
		Variables here
	***********************************************************************************************************/


 
	/***********************************************************************************************************
		Processing methods here
	***********************************************************************************************************/

	/*------------------------------------------------------------
	Author:			Mike Jupp
	Company:		CloudSense
	Description:	Save any and all updates to the Answer fields for audit trail purposes
	History
	<Date>		<Authors Name>		<Brief Description of Change>
	Jul 18		Mike Jupp			Rewritten based on original code
	------------------------------------------------------------*/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void UpdateChangeHistory (list<Answer2__c> newRecords)
	{
		string strWho = userinfo.getFirstName() + ' ' + userinfo.getLastName();
		
		for (Answer2__c sAnswer2New : newRecords)
		{
			list<CS_Questions_Utilities.ChangeHistoryWrapper> li_ChangeHistory = new list<CS_Questions_Utilities.ChangeHistoryWrapper>();
			
			// Only one of these conditions should be met - but don't use 'else' just in case something goes wrong
			if (sAnswer2New.Answer_Checkbox__c != false)	// Default value
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Checkbox__c)));

			if (sAnswer2New.Answer_Currency__c != null)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Currency__c)));

			if (sAnswer2New.Answer_Date__c != null)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Date__c)));

			if (!string.isBlank(sAnswer2New.Answer_Email__c))
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, sAnswer2New.Answer_Email__c));

			if (!string.isBlank(sAnswer2New.Answer_Long_Text__c))
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, sAnswer2New.Answer_Long_Text__c));

			if (sAnswer2New.Answer_Numeric__c != null)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Numeric__c)));

			if (sAnswer2New.Answer_Percent__c != null)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Percent__c)));

			if (sAnswer2New.Answer_Phone__c != null)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Phone__c)));

			if (!string.isBlank(sAnswer2New.Answer_Text__c))
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, sAnswer2New.Answer_Text__c));

			if (!string.isBlank(sAnswer2New.Answer_Url__c))
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, sAnswer2New.Answer_Url__c));

			sAnswer2New.Change_History__c = JSON.serialize(li_ChangeHistory);
		}
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//
	private void UpdateChangeHistory (map<id, SObject> map_oldRecords, list<Answer2__c> newRecords)
	{
		string strWho = userinfo.getFirstName() + ' ' + userinfo.getLastName();
		
		for (Answer2__c sAnswer2New : newRecords)
		{
			Answer2__c sAnswer2Old = (Answer2__c)map_oldRecords.get(sAnswer2New.Id);
			
			list<CS_Questions_Utilities.ChangeHistoryWrapper> li_ChangeHistory = string.isBlank(sAnswer2New.Change_History__c)
				? new list<CS_Questions_Utilities.ChangeHistoryWrapper>()
				: (list<CS_Questions_Utilities.ChangeHistoryWrapper>)JSON.deserialize(sAnswer2New.Change_History__c, list<CS_Questions_Utilities.ChangeHistoryWrapper>.class);
			
			if (sAnswer2New.Answer_Checkbox__c != sAnswer2Old.Answer_Checkbox__c)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Checkbox__c)));

			if (sAnswer2New.Answer_Currency__c != sAnswer2Old.Answer_Currency__c)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Currency__c)));

			if (sAnswer2New.Answer_Date__c != sAnswer2Old.Answer_Date__c)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Date__c)));

			if (sAnswer2New.Answer_Email__c != sAnswer2Old.Answer_Email__c)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, sAnswer2New.Answer_Email__c));

			if (sAnswer2New.Answer_Long_Text__c != sAnswer2Old.Answer_Long_Text__c)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, sAnswer2New.Answer_Long_Text__c));

			if (sAnswer2New.Answer_Numeric__c != sAnswer2Old.Answer_Numeric__c)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Numeric__c)));

			if (sAnswer2New.Answer_Percent__c != sAnswer2Old.Answer_Percent__c)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Percent__c)));

			if (sAnswer2New.Answer_Phone__c != sAnswer2Old.Answer_Phone__c)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, string.valueOf(sAnswer2New.Answer_Phone__c)));

			if (sAnswer2New.Answer_Text__c != sAnswer2Old.Answer_Text__c)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, sAnswer2New.Answer_Text__c));

			if (sAnswer2New.Answer_Url__c != sAnswer2Old.Answer_Url__c)
				li_ChangeHistory.add(new CS_Questions_Utilities.ChangeHistoryWrapper(strWho, sAnswer2New.Answer_Url__c));

			sAnswer2New.Change_History__c = JSON.serialize(li_ChangeHistory);
		}
	}
	
}
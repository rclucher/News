/*------------------------------------------------------------
Author:			Mike Jupp
Company:		CloudSense
Description:	
Test Class:		
History
<Date>		<Authors Name>		<Brief Description of Change>
Jul 18		Mike Jupp			Created
------------------------------------------------------------*/
public with sharing class CS_QuestionsDownload_Controller
{
	/***********************************************************************************************************
		Members
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Singular
	public string		mp_UserName					{get; set;}
	public datetime		mp_Timestamp				{get; set;}

	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//	Collections
	public list<Question2__c> mp_liQuestions		{get; set;}

	/***********************************************************************************************************
		Constructor
	***********************************************************************************************************/
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Our Constructor
	public CS_QuestionsDownload_Controller()
	{
		
	}

	public pageReference Init()
	{
		try
		{
			// Set up userid and timestamp
			mp_UserName = UserInfo.getName();			
			mp_Timestamp = datetime.now();

			mp_liQuestions = CS_Questions_Utilities.getQuestions();
		}
		catch(exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, CS_Questions_Utilities.GENERALERROR));
		}
		
		return null;
	}
    
}
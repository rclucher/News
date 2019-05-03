/**
* @description  controller for lightning component QuickQuote
*
* @author       Timothy Fabros
* @date         2017-10-23
**/
public with sharing class QuickQuoteController {
	
	/**
	* @description  creates an opportunity related to the account
	*
	* @author       Timothy Fabros
	* @date         2017-10-23
	**/	
	@auraEnabled
	public static Id createOpportunity(Id accountId) {

		Account account = [SELECT Name FROM Account WHERE Id = :accountId];

		Opportunity opp = new Opportunity();
		opp.Name = account.Name + ' ' + Date.today();
		opp.AccountId = accountId;
		opp.RecordtypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('SME').getRecordTypeId();
		opp.StageName = 'Discover Needs';
		opp.CloseDate = Date.today() + 14;

		insert opp;

		return opp.Id;
	}
}
global class OLIUpdateOppProbabilityAndOwner_Batch implements Database.Batchable<sObject> {
	
	String query;
	
	global OLIUpdateOppProbabilityAndOwner_Batch() {
		this.query = 'SELECT Opportunity_Probablity__c, Opportunity_Owner__c FROM OpportunityLineItem';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		update (List<OpportunityLineItem>)scope;
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}
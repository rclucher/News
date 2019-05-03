global class CS_BatchTierCalculation implements Database.Batchable<sObject> {
	
	public String query;
	private Date monthAfter = system.today().addMonths(1);
	private list<Id> accIds;

	global CS_BatchTierCalculation() {
		query = 'select Payment__r.order__r.Opportunity__r.accountid, Amount__c from payment_schedule__c where Billing_Date__c  >= TODAY AND Billing_Date__c  < :monthAfter and status__c != ' + '\'Cancelled\'';
	}

	global CS_BatchTierCalculation(Id accountId) {
		query = 'select Payment__r.order__r.Opportunity__r.accountid, Amount__c from payment_schedule__c where Billing_Date__c  >= TODAY '+
		+'AND Billing_Date__c  < :monthAfter and status__c != ' + '\'Cancelled\' AND payment__r.order__r.account__c= \'' + accountId + '\'';
	}

	global CS_BatchTierCalculation(List<Id> accountIds) {
		accIds = accountIds;// Added by shabu
		query = 'select Payment__r.order__r.Opportunity__r.accountid, Amount__c from payment_schedule__c where Billing_Date__c  >= TODAY '+
		+'AND Billing_Date__c  < :monthAfter and status__c != ' + '\'Cancelled\' AND payment__r.order__r.account__c IN  :accIds';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {

		return Database.getQueryLocator(query);
	}

  	global void execute(Database.BatchableContext BC, List<sObject> scope) {

  		List<payment_schedule__c> paySchList = (List<payment_schedule__c>)scope;

  		CS_TierCalculation.setAccountTierFor(paySchList);

    }
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}
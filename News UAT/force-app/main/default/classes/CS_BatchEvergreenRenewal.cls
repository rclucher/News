/**
 * Batch class which picks up all payments scheduled for renewal
 */
global class CS_BatchEvergreenRenewal implements Database.Batchable<sObject> {
	
	private String query;
	
	public CS_BatchEvergreenRenewal() {
		query = 'select id from Payment__c where Number_of_Pending_PS__c = 3 and End_Date__c = null';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC){
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, List<sObject> scope){
		List<Payment__c> payments = (List<Payment__c>) scope;
		Set<Id> paymentIds = new Set<Id>();
		for (Payment__c p : payments) {
			paymentIds.add(p.Id);
		}
		CS_EvergreenPaymentRenewalHelper.clonePaymentScheduleWithLineItems(paymentIds);
	}

	/**
	 * Does nothing
	 */
	global void finish(Database.BatchableContext BC){
	}
	
	

}
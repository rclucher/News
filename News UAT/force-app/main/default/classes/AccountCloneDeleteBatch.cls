global class AccountCloneDeleteBatch implements Database.Batchable<sObject> {
	
	String query= 'Select id,Status__c FROM AccountReport__c where Status__c!=\'Active\'';
	global AccountCloneDeleteBatch() {
		 
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<AccountReport__c> scope) {
   		delete scope;
 	}
	
	global void finish(Database.BatchableContext BC) {
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
	      						TotalJobItems, CreatedBy.Email
	      						FROM AsyncApexJob WHERE Id =:BC.getJobId()];
	   // Send an email to the Apex job's submitter notifying of job completion.

		string subject = 'Batch Delete from the Custom Object AccountReport__c ' + a.Status;
		string body = 'The batch delete job for the object AccountReport__c processed ' + a.TotalJobItems +
	   ' batches with '+ a.NumberOfErrors + ' failures.';
		String[] toAddresses = new String[] {'shared_salesforce@news.com.au'};

		Batch_Utility.sendEmail(toAddresses,subject,body);
	}
	
}
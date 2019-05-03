global class OpportunityCloneDeleteBatch implements Database.Batchable<sObject> {
	
String query ='Select id, Stage__c,Close_Date__c from OpportunityReport__c where Stage__c!=\'Closed Won\'and (Close_Date__c!= last_N_YEARS:3 or Close_Date__c!= THIS_YEAR)';
    global OpportunityCloneDeleteBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<OpportunityReport__c> scope) {
   		delete scope;
	
	}
	
	global void finish(Database.BatchableContext BC) {
			AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
	      						TotalJobItems, CreatedBy.Email
	      						FROM AsyncApexJob WHERE Id =:BC.getJobId()];
	   // Send an email to the Apex job's submitter notifying of job completion.

		string subject = 'Batch Delete from the Custom Object OpportunityReport__c ' + a.Status;
		string body = 'The batch delete job processed ' + a.TotalJobItems +
	   ' batches with '+ a.NumberOfErrors + ' failures.';
		String[] toAddresses = new String[] {'shared_salesforce@news.com.au'};

		Batch_Utility.sendEmail(toAddresses,subject,body);
	}
	
}
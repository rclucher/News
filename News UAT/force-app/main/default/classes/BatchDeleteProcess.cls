global class BatchDeleteProcess implements Database.Batchable<sObject> {
	
	String query = 'Select id FROM Portfolio_Account_Staging__c';
	
	global BatchDeleteProcess() {
		
	}

	// If true delete the Portfolio_Staging__c object records
	global BatchDeleteProcess(boolean deletePortfolio_staging) {
		if (deletePortfolio_staging == true) {
			query = 'Select Id from Portfolio_Staging__c';
		}
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<SObject> scope) {
		delete scope;
	}
	
	global void finish(Database.BatchableContext BC) {
			// notify the executing user context the job is complete
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
	      						TotalJobItems, CreatedBy.Email
	      						FROM AsyncApexJob WHERE Id =:BC.getJobId()];
	   // Send an email to the Apex job's submitter notifying of job completion.

		string subject = 'Batch Delete ' + a.Status;
		string body = 'The batch delete job processed ' + a.TotalJobItems +
	   ' batches with '+ a.NumberOfErrors + ' failures.';
		String[] toAddresses = new String[] {a.CreatedBy.Email};

		Batch_Utility.sendEmail(toAddresses,subject,body);

	}
}
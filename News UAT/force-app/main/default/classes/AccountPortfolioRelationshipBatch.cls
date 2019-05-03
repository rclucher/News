/**
* @author Ashfaq Mohammed
* @description //SFE-1058 Begins
			   // After processing all records from Portfolio Account Staging (PortfolioAccountMappingProcess). If no records in Portfolio Account Staging do the following:
			   //- Find records not modified today in Account_Portfolio_Relationship__c objects
			  //- Set Delete_Flag__c to True for these records
* @date : 08/04/2019
*/ 
global class AccountPortfolioRelationshipBatch implements Database.Batchable<sObject>, Database.Stateful {
	String query = 'SELECT id, Delete_Flag__c, LastModifiedDate, IsDeleted FROM Account_Portfolio_Relationship__c WHERE IsDeleted = false AND LastModifiedDate < TODAY';
    
    global Database.QueryLocator start(Database.BatchableContext bC) {
		if(Test.isRunningTest()) {
			query = 'SELECT id, Delete_Flag__c, LastModifiedDate, IsDeleted FROM Account_Portfolio_Relationship__c WHERE IsDeleted = false';
		}			
		return Database.getQueryLocator(query);
	}
    global void execute(Database.BatchableContext bC, List<Account_Portfolio_Relationship__c> scope) {
		List<Account_Portfolio_Relationship__c> aprList = new List<Account_Portfolio_Relationship__c>();
		// Filter based on the scope with LastModifiedDate is today to filter
		for(Account_Portfolio_Relationship__c apr :scope){
				apr.Delete_Flag__c = true;
				aprList.add(apr);
		}

		if(aprList.size()>0){
			update aprList;
		}
	
    }
    
    global void finish(Database.BatchableContext bC) {
		 // Get the ID of the AsyncApexJob representing this batch job
	   // from Database.BatchableContext.
	   // Query the AsyncApexJob object to retrieve the current job's information.
	   AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
	      TotalJobItems, CreatedBy.Email
	      FROM AsyncApexJob WHERE Id =
	      :bC.getJobId()];
	   // Send an email to the Apex job's submitter notifying of job completion.

		string subject = 'Account Portfolio Relationship Process ' + a.Status;
		string body = 'The AccountPortfolioRelationshipBatch job processed ' + a.TotalJobItems +
	   ' batches with '+ a.NumberOfErrors + ' failures.\n'; 
		String[] toAddresses = new String[] {a.CreatedBy.Email};

		Batch_Utility.sendEmail(toAddresses,subject,body);
		

    }
}
/**
* @author Ashfaq Mohammed
* @description //SFE-1058 Begins
					// After processing all records from Portfolio Account Staging (PortfolioAccountMappingProcess). If no records in Portfolio Account Staging do the following:
					//- Find records not modified today in Booking_System_Portfolio_Junction__c objects
					//- Set Delete_Flag__c to True for these records
* @date : 08/04/2019
*/ 
global class BookingSystemPortfolioJunctionBatch implements Database.Batchable<sObject>, Database.Stateful {
	String query = 'SELECT id, Delete_Flag__c, LastModifiedDate, IsDeleted FROM Booking_System_Portfolio_Junction__c WHERE IsDeleted = false AND LastModifiedDate < TODAY';
    
    global Database.QueryLocator start(Database.BatchableContext bC) {
		if(Test.isRunningTest()) {
			query = 'SELECT id, Delete_Flag__c, LastModifiedDate, IsDeleted FROM Booking_System_Portfolio_Junction__c WHERE IsDeleted = false';
		}		
		return Database.getQueryLocator(query);
	}
    global void execute(Database.BatchableContext bC, List<Booking_System_Portfolio_Junction__c> scope) {
		List<Booking_System_Portfolio_Junction__c> bspjList = new List<Booking_System_Portfolio_Junction__c>();
		// Filter based on the scope with LastModifiedDate is today to filter
		for(Booking_System_Portfolio_Junction__c bspj :scope){
				bspj.Delete_Flag__c = true;
				bspjList.add(bspj);
		}

		if(bspjList.size()>0){
			update bspjList;
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

		string subject = 'Booking System Portfolio Junction Process ' + a.Status;
		string body = 'The BookingSystemPortfolioJunctionBatch job processed ' + a.TotalJobItems +
	   ' batches with '+ a.NumberOfErrors + ' failures.\n'; 
		String[] toAddresses = new String[] {a.CreatedBy.Email};

		Batch_Utility.sendEmail(toAddresses,subject,body);
    }
}
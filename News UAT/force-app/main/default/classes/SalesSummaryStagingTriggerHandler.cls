/*---------------------------------------------------------
 * Author: David Dawson
 * Company: Bluewolf
 * Description: Trigger Handler for the Sales Summary Staging object
 * History: Trigger Created.
 			Functionality added for sales summary staging record transformation
 ---------------------------------------------------------*/

public class SalesSummaryStagingTriggerHandler {
	
	public Map<String, String> TransformStagingData() {
		//final return object
		Map<String, String> errorLog = new Map<String, String>();

		//This is the list we will use to try and insert the new records.
		List<SalesSummary__c> transformObject = new List<SalesSummary__c>();

		//create a list of available users
		Set<String> userExtId = new Set<String>();
		for(SalesSummaryStaging__c sss :(List<SalesSummaryStaging__c>)Trigger.NEW){
			userExtId.add(String.valueOf(sss.SiebelLogin__c));
		}

		//get users from Salesforce that are used within the insert
		List<User> userList = new List<User>([SELECT Id, External_ID__c FROM User WHERE External_Id__c IN :userExtId]);
		Map<String, User> userMap = new Map<String, User>();
		for(User u :userList){
			userMap.put(u.External_Id__c, u);
		}

		for(SalesSummaryStaging__c sss :(List<SalesSummaryStaging__c>)Trigger.NEW){
			//ensure user exists
			if(userMap.containsKey(sss.SiebelLogin__c)){

				//Qualification for target record
				if(sss.TargetArea__c != null && sss.NRTargetAmount__c != null){
					SalesSummary__c targetRecord = new SalesSummary__c(OwnerId = userMap.get(sss.SiebelLogin__c).Id, Type__c = 'Target', UserId__c = userMap.get(sss.SiebelLogin__c).Id, MonthId__c = String.valueOf(sss.FiscMonthId__c.right(6)), Month__c = sss.FiscMonth__c, Year__c = sss.FiscYear__c, TargetType__c = sss.TargetType__c, TargetArea__c = sss.TargetArea__c, Count__c = sss.NRTargetAmount__c, TargetArea2__c = sss.TargetArea2__c, BookingRevenueType__c = sss.BookingRevenueType__c, DivisionScheme__c = sss.DivisionScheme__c, Role__c = sss.EmployeeRole__c, PortfolioName__c = sss.PortfolioName__c, State__c = sss.State__c, TeamName__c = sss.TeamName__c);
					targetRecord.SalesSummaryStaging__c = sss.Id;
					targetRecord.ExternalId__c = ExternalIdUtility.SalesSummaryExternalId(sss.SiebelLogin__c, sss.EmployeeRole__c, 'Target', sss.BookingRevenueType__c, sss.FiscMonthId__c);
					transformObject.add(targetRecord);
				}

				//Qualification for actual record
				if(sss.BookingRevenueType__c != null && sss.BookingRevenueAmount__c != null){
					SalesSummary__c actualRecord = new SalesSummary__c(OwnerId = userMap.get(sss.SiebelLogin__c).Id, Type__c = 'Actual (NewsFact)', UserId__c = userMap.get(sss.SiebelLogin__c).Id, MonthId__c = String.valueOf(sss.FiscMonthId__c.right(6)), Month__c = sss.FiscMonth__c, Year__c = sss.FiscYear__c, Count__c = sss.BookingRevenueAmount__c, BookingRevenueType__c = sss.BookingRevenueType__c, DivisionScheme__c = sss.DivisionScheme__c, Role__c = sss.EmployeeRole__c, PortfolioName__c = sss.PortfolioName__c, NRCredits__c = sss.NRCredits__c, NRDebits__c = sss.NRDebits__c, State__c = sss.State__c, TeamName__c = sss.TeamName__c);
					actualRecord.SalesSummaryStaging__c = sss.Id;
					actualRecord.ExternalId__c = ExternalIdUtility.SalesSummaryExternalId(sss.SiebelLogin__c, sss.EmployeeRole__c, 'Actual (NewsFact)', sss.BookingRevenueType__c, sss.FiscMonthId__c);
					transformObject.add(actualRecord);
				}
			}else{
				sss.addError('This user does not exist in Salesforce. Please ensure this user has been added into Salesforce before adding any summary information.');
			}
		}

		//upsert records
		try{
			upsert transformObject ExternalId__c;
		}catch(exception e){
			ExLog.log(e, 'config', transformObject, 'From SalesSummaryTriggerHandler.TransformStagingData().');  
		}

		//Set of the failed record sources (SalesSummaryStaging records)
		Set<Id> failedRecords = new Set<Id>();

		Schema.SObjectField f = SalesSummary__c.Fields.ExternalId__c;
		database.upsertresult[] results = database.upsert(transformObject, f, false);
	    for(integer idx = 0; idx < results.size(); idx++) {
	        if(!results[idx].isSuccess()) {
	            //will do the error handling in the trigger using the error log map
	            //(List<SalesSummaryStaging__c>)Trigger.newMap.get(transformObject[idx].SalesSummaryStaging__c).addError(results[idx].getErrors()[0].getMessage());
	            if(!errorLog.containsKey(transformObject[idx].SalesSummaryStaging__c)){
	            	errorLog.put(transformObject[idx].SalesSummaryStaging__c, results[idx].getErrors()[0].getMessage());
	            	failedRecords.add(transformObject[idx].SalesSummaryStaging__c);
	        	}
	        }
	    }

	    //loop through the failed sales summary staging records and roll back the children that succeeded
	    /*for(integer idx = 0; idx < results.size(); idx++) {
	    	if(results[idx].isSuccess()) {
	    		if(failedRecords.contains(transformObject[idx].SalesSummaryStaging__c)){
	    			//rollback the records
	    		}
	    	}
	    }*/

	    return errorLog;

	}
}
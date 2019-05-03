trigger SalesSummaryStagingTrigger on SalesSummaryStaging__c (after insert, after update) {

	//make an instance of the trigger handler for execution purposes.
    SalesSummaryStagingTriggerHandler utility = new SalesSummaryStagingTriggerHandler();

	//SalesSummaryStaging data transformation into the SalesSummary object
	if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate)){
		//retrieve the map of results from the trigger handler (format is SalesSummaryStaging__c.Id, Error message)
		Map<String, String> transformationResult = utility.transformStagingData();
		for(String key :transformationResult.keySet()){
			//loop through the errors returned by the trigger handler and add errors to the relevant records for rollback
			Trigger.newMap.get(key).addError(transformationResult.get(key));
		}
	}

}
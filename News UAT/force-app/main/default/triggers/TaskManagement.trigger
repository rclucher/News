trigger TaskManagement on Task (before insert, before update, after insert, after update)
{
	// Cloudsense Release 3
    // START
    
    CS_TriggerHandler.execute(new CS_TaskTriggerDelegate());
    
    // Cloudsense Release 3
    // END
	//Check if the CNN batch is executing
	CCNBatchJobSetting__c batchSetting = CCNBatchJobSetting__c.getInstance();
    
    if (Global_Helper.canTrigger( 'TaskManagement' ) && !batchSetting.Is_Task_Batch_Running__c )
    {
	    if((trigger.isInsert || trigger.isUpdate) && trigger.isBefore)
	    {
	    	// R-0634
	    	// A trigger to record Task Due Date in another field is required to enable 
	    	// the Due Date use in reports and formulas, validations, etc.
	    	for(Task t : trigger.new)
	    	{ 
	    		t.Usable_Due_Date__c = t.ActivityDate;
	    	}
	    }
    }
}
/**
 * @since 20/03/2018
 */
global class CS_XtendSOEndDateUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	global Integer recordCount  = 0;    // to count the number of processed records
	global Boolean doOperation;         // to flag the batch job as debug or not
   
    global CS_XtendSOEndDateUpdateBatch(Boolean updateFlag) {
	
        // sets the flag whether to do the operation or just make a non-update debug run
        doOperation = updateFlag;
        
        System.debug('DEBUG: Starting job');
        System.debug('DEBUG: doOperation flag: ' + doOperation);
	}
    
	global Database.QueryLocator start(Database.BatchableContext BC) {
      	
        // get all Sales Orders that need update
        String query =  'SELECT Id, Campaign_Start_Date__c, Campaign_End_Date__c, Campaign_End_Date2__c ' +
        				' FROM csmso__Sales_Order__c ' +
						' WHERE Platform_Set__c = null';
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<csmso__Sales_Order__c> scope) {
        
        System.debug('DEBUG: Running execute method...');
		
		/*
		 * Update all sales order with relevant From and To values:
		 * To field (csmso__To__c) date based on:
		 * - Campaign_End_Date2__c if Campaign_End_Date2__c != null
		 * - Campaign_End_Date__c if Campaign_End_Date2__c == null
		 * From field (csmso__From__c) date based on Campaign_Start_Date__c
		 */
		for (csmso__Sales_Order__c so : scope) {
			if (so.Campaign_End_Date2__c != null) {
				so.csmso__To__c = so.Campaign_End_Date2__c;
			} else {
				so.csmso__To__c = so.Campaign_End_Date__c;
			}

			so.csmso__From__c = so.Campaign_Start_Date__c;
		}

        if (doOperation == true) {
	        update scope;
            
            System.debug('DEBUG: Updated ' + scope.size() + ' records');
        } else {
         	System.debug('DEBUG: No. of records to be processed: ' + scope.size());   
        }

        recordCount  += scope.size();
    }  
    
    global void finish(Database.BatchableContext BC) {
    	System.debug('DEBUG: Running finish method...');

    	if (doOperation == true) {
		    System.debug('DEBUG: Updated ' + recordCount + ' records');
        } else {
         	System.debug('DEBUG: No. of records to be processed: ' + recordCount);   
        }

        System.debug('DEBUG: Ended batch job.');
    }
}
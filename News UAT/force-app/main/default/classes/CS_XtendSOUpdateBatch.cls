/**
 * @since 08/03/2018
 */
 global class CS_XtendSOUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	global Integer recordCount  = 0;    // to count the number of processed records
	global Boolean doOperation;         // to flag the batch job as debug or not
   
    global CS_XtendSOUpdateBatch(Boolean updateFlag) {
	
        // sets the flag whether to do the operation or just make a non-update debug run
        doOperation = updateFlag;
        
        System.debug('DEBUG: Starting job');
        System.debug('DEBUG: doOperation flag: ' + doOperation);
	}
    
	global Database.QueryLocator start(Database.BatchableContext BC) {
      	
        // get all Sales Orders that need update
        String query =  'SELECT Id FROM csmso__Sales_Order__c ' +
						' 	WHERE Platform_Set__c = null AND csmso__Total_Price__c > 0';
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<csmso__Sales_Order__c> scope) {
        
        System.debug('DEBUG: Running execute method...');
		
		// update all sales order with Xtend Platform Set
		for (csmso__Sales_Order__c so : scope) {
			so.Platform_Set__c = '{Xtend}';
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
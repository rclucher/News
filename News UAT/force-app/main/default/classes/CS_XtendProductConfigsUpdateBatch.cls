/**
 * @since 07/03/2018
 */
 global class CS_XtendProductConfigsUpdateBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	global Integer recordCount  = 0;    // to count the number of processed records
	global Integer invalidCount = 0;
    global Boolean doOperation;         // to flag the batch job as debug or not

    global Map<String,News_Xtend_Product_Ref__c> pNodeProdMap = new Map<String, News_Xtend_Product_Ref__c>();
	global Map<String,News_Xtend_Product_Ref__c> xTendProdMap = new Map<String, News_Xtend_Product_Ref__c>();
    
    global CS_XtendProductConfigsUpdateBatch(Boolean updateFlag) {
	
        // sets the flag whether to do the operation or just make a non-update debug run
        doOperation = updateFlag;
        
        System.debug('DEBUG: Starting job');
        System.debug('DEBUG: doOperation flag: ' + doOperation);

        // get all News Xtend Products (identified by Product Record Type)
		for (News_Xtend_Product_Ref__c nxProdRef : [SELECT Id, Name, Provider__c, Product_Type__c, Product_Line__c, Product_Node__c 
										    FROM News_Xtend_Product_Ref__c 
										    WHERE Record_Type_Name__c = 'Product' AND 
												  Provider__c 	  != null AND 
												  Product_Line__c != null AND 
												  Product_Type__c != null AND 
												  Product_Node__c != null]) {
    
			// Product Configuration will hold the Id of related Xtend Product Node OR the Product Node Id (based on the phase the Product Configuration was made)
			// we have two maps pointing to same NX products but mapped via different Ids
			// for Product Node Product Configurations
		    pNodeProdMap.put(nxProdRef.Product_Node__c, nxProdRef);
			
		    // for News Xtend (Legacy) Product Configurations
		    xTendProdMap.put(nxProdRef.Id, nxProdRef);
    	}
	}
    
	global Database.QueryLocator start(Database.BatchableContext BC) {
      	
      	// get News Xtend Product Configurations that need update
		// Product_ID__c holds the Id of related Xtend Product Node OR the Product Node Id (Implemented in Xtend Remediation Phase)
		// We're looking for Product Configurations that have Xtend Product but no Provider Name mapped from the attribute
        String query = 'SELECT ID, Product_ID__c ' + 
						'FROM cscfga__Product_Configuration__c ' +
						'WHERE Provider_Name__c = \'\' AND ' + 
						'	   Product_ID__c != \'\'';
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<cscfga__Product_Configuration__c> scope) {
        
        System.debug('DEBUG: Running execute method...');
		System.debug('DEBUG: Product Configurations found: ' + scope.size());

		String prod = '';
		Integer invalidRecords = 0;
		List<cscfga__Product_Configuration__c> pcsToUpdate = new List<cscfga__Product_Configuration__c>();

		for (cscfga__Product_Configuration__c pc : scope) {
		    prod = pc.Product_ID__c;
		    
			// if the current Product Configuration does not belong to Xtend, skip it
		    if (!pNodeProdMap.containsKey(prod) && !xTendProdMap.containsKey(prod)) {
		        //System.debug('DEBUG: Invalid product ' + prod +  'in PC:' + pc.Id);
		        invalidRecords += 1;
				
		        continue;
		    }
		    
		    if (pNodeProdMap.containsKey(prod)) {
				//System.debug('DEBUG: Updating "Product Node" Product Configuration :' + pc.Id);
		        
				pc.Provider_Name__c		= pNodeProdMap.get(prod).Provider__c;
		        pc.Product_Name__c 		= pNodeProdMap.get(prod).Name;
		        pc.Product_Type_Name__c = pNodeProdMap.get(prod).Product_Type__c;
		        pc.Product_Line_Name__c = pNodeProdMap.get(prod).Product_Line__c;
		    } else {
		        //System.debug('DEBUG: Updating "News Xtend Ref" Product Configuration :' + pc.Id);
				
				pc.Provider_Name__c 	= xTendProdMap.get(prod).Provider__c;
		        pc.Product_Name__c 		= xTendProdMap.get(prod).Name;
		        pc.Product_Type_Name__c = xTendProdMap.get(prod).Product_Type__c;
		        pc.Product_Line_Name__c = xTendProdMap.get(prod).Product_Line__c;
		    }
		    
		    pcsToUpdate.add(pc);
		}

        if (doOperation == true) {
	        update pcsToUpdate;
            
            System.debug('DEBUG: Updated ' + pcsToUpdate.size() + ' product configurations');
			System.debug('DEBUG: Number of invalid Product Configurations: ' + invalidRecords);

        } else {
         	System.debug('DEBUG: No. of records to be processed: ' + pcsToUpdate.size());   
        }

        recordCount  += pcsToUpdate.size();
        invalidCount += invalidRecords;
    }  
    
    global void finish(Database.BatchableContext BC) {
    	System.debug('DEBUG: Running finish method...');

    	Integer totalConfigs = invalidCount + recordCount;

        System.debug('DEBUG: Total Product Configurations checked: ' + totalConfigs);

    	if (doOperation == true) {
		    System.debug('DEBUG: Updated ' + recordCount + ' records');
			System.debug('DEBUG: Number of invalid Product Configurations: ' + invalidCount);

        } else {
         	System.debug('DEBUG: No. of records to be processed: ' + recordCount);   
         	System.debug('DEBUG: Number of invalid Product Configurations: ' + invalidCount);
        }

        System.debug('DEBUG: Ended batch job.');
    }
}
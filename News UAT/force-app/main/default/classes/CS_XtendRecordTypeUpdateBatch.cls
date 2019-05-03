global class CS_XtendRecordTypeUpdateBatch implements Database.Batchable<sObject> {
    
	global Integer recordCount = 0;
    global Id XtendRecordTypeId;
    global Boolean doUpdate;
    
    global CS_XtendRecordTypeUpdateBatch(Boolean updateFlag) {
	
        // sets the flag whether to do the update or just make a non-update debug run
        doUpdate = updateFlag;
        
        // get Xtend Record Type Id
        XtendRecordTypeId = Schema.SObjectType.csmso__Product_Node__c.getRecordTypeInfosByName().get('Xtend Product').getRecordTypeId();
        
        System.debug('Starting Xtend Record Type update batch job');
        System.debug('doUpdate Flag: ' + doUpdate);
    }
    
	global Database.QueryLocator start(Database.BatchableContext BC) {
      	
        // get Product Nodes to update - these have no Record Type Id
        // I wanted to simply use WHERE RecordTypeId != null but could not write a unit test for it
        String query = 'SELECT Name ' +
            		   'FROM csmso__Product_Node__c ' +
            		   'WHERE RecordType.Name NOT IN (\'Digital Display Product\', \'Print Position\', \'Print Position\', ' + 
                                                     '\'Print Publication\', \'Print Section\', \'Print State\', ' + 
                                                     '\'Print Subsection\', \'Print Type\', \'Xtend Product\')';
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<csmso__Product_Node__c> scope) {
        
        for ( csmso__Product_Node__c pn : scope) {
           	pn.RecordTypeId = XtendRecordTypeId;
 
           	recordCount++;
			System.debug('Product Node ' + recordCount + ': ' + pn.Name);
        }
        
        if (doUpdate == true) {
	        update scope;
            
            System.debug('No. of Product Nodes updated: ' + recordCount);
        } else {
         	System.debug('No. of Product Nodes to be updated: ' + recordCount);   
        }
    }  
    
    global void finish(Database.BatchableContext BC) {
    }
}
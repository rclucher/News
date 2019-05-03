/**
 * Update Xtend Rate Card Item Prices with Record Type = "Xtend Price".
 * These are identified by having related Product Node Record Type of "Xtend Product"
 * @author Igor Vrabec <igor.vrabec@cloudsensesolutions.com>
 * @since 15/02/2018
 */
global class CS_XtendRcipRecordTypeUpdateBatch implements Database.Batchable<sObject> {
    
	global Integer recordCount = 0;
    global Id XtendRecordTypeId;
    global Boolean doUpdate;
    
    global CS_XtendRcipRecordTypeUpdateBatch(Boolean updateFlag) {
	
        // sets the flag whether to do the update or just make a non-update debug run
        doUpdate = updateFlag;
        
        // get Xtend Record Type Id
        XtendRecordTypeId = Schema.SObjectType.csmso__Rate_Card_Item_Price__c.getRecordTypeInfosByName().get('Xtend Price').getRecordTypeId();
        
        System.debug('Starting Xtend RCIP Record Type update batch job');
        System.debug('doUpdate Flag: ' + doUpdate);
    }
    
	global Database.QueryLocator start(Database.BatchableContext BC) {
      	
        // get Rate Card Item Prices to update - these have no Record Type Id
        String query = 'SELECT Name ' +
            		   'FROM csmso__Rate_Card_Item_Price__c ' +
            		   'WHERE csmso__Product_Node__r.RecordType.Name = \'Xtend Product\'';
        
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<csmso__Rate_Card_Item_Price__c> scope) {
        
        for ( csmso__Rate_Card_Item_Price__c rcip : scope) {
           	rcip.RecordTypeId = XtendRecordTypeId;
 
           	recordCount++;
			System.debug('RCIP ' + recordCount + ': ' + rcip.Name);
        }
        
        if (doUpdate == true) {
	        update scope;
            
            System.debug('No. of Rate Card Item Prices updated: ' + recordCount);
        } else {
         	System.debug('No. of Rate Card Item Prices to be updated: ' + recordCount);   
        }
    }  
    
    global void finish(Database.BatchableContext BC) {
    }
}
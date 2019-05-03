/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Bluewolf.com
 * Description: This batch will clean up exception record based on action type 
 * History:
 * 20/07/2014  Bohao Chen  Created
 ---------------------------------------------------------*/
 // TODO: covert this exception proccess class to process TCSTAS exception records
global class ExceptionRecordCleanUp_Batch implements Database.Batchable<sObject>, Database.Stateful
{
    global String query;
	global String actionType;
	
    global ExceptionRecordCleanUp_Batch(String actionType)
    {       
        this.query = 'Select Id from Exception_Record__c Where Action_Type__c = \'' + actionType + '\'';
        this.actionType = actionType;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Exception_Record__c> exceptionRecords)
    {
    	delete exceptionRecords;
    }
    
    global void finish(Database.BatchableContext BC)
    {
	        if(this.actionType == 'TGS')
	        {
	            // After cleaning up TGS (total group spending) exception records, 
	            // AccountUpdateTgs_Batch gets called to update TGS using latest TCS and TAS

                        // when TCS or TAS or parent account get updated, Account_Last_Modified__c will timestamp it.
                // Only rollup accounts' whose Account_Last_Modified__c is greater than last success batch run time.
                String query = 'Select Id, ParentId, RecordType.Name, Total_Group_Spend__c, '
                    + 'Ultimate_Parent_Id__c, Total_Customer_Spend__c, Total_Agency_Spend__c, Account_Last_Modified__c, '
                    + 'Parent.Name, Parent.Id, Parent.ParentId, Parent.RecordType.Name, Parent.Total_Group_Spend__c, ' 
                    + 'Parent.Ultimate_Parent_Id__c, Parent.Total_Customer_Spend__c, Parent.Total_Agency_Spend__c '
                    + 'From Account ' 
                    + 'Where Account_Last_Modified__c > :recordStartDatetime '
                    + 'And Ultimate_Parent_Id__c != NULL';
				
				// SFE-766 2016-01-14 atul.gupta@bluewolfgroup.com - Batch class call exempted from during test class execution
				if(!Test.isRunningTest()){
	                AccountUpdateTgs_Batch accountUpdateTgs = new AccountUpdateTgs_Batch(query);
	                ID batchProcessId; batchProcessId = Database.executeBatch(accountUpdateTgs);
	                System.debug('Account TGS Update Batch batch process ID: ' + batchProcessId);
				}
	        }
	        else if(this.actionType == 'TCSTAS')
	        {	        	
	        	String query = 'Select s.Total_Gross_Price_Ytd__c, s.Payer_Account__c, s.Payer_Account__r.RecordType.Name, '
                     + 's.Advertiser_Account__c, s.Advertiser_Account__r.RecordType.Name, s.Total_Gross_Price_YTD_Last_Modified__c ' 
                     + 'From Sales_Order__c s';
                     
                // SFE-766 2016-01-14 atul.gupta@bluewolfgroup.com - Batch class call exempted from during test class execution
	        	if(!Test.isRunningTest()){
					AccountUpdateTcsTas_Batch b = new AccountUpdateTcsTas_Batch(null, query);
					database.executeBatch(b);  
	        	} 
	        }
    }
}
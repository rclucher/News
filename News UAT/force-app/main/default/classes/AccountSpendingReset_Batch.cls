/*---------------------------------------------------------
* Author: Bohao Chen
* Company: Bluewolf
* Description: This batch is to reset total customer/agency/group spendings for accounts. 
*				It's part of solution for JIRA SFE-4. We need to reset spendings before any calculation for all accounts
* History:
* 26/05/2014   Bohao Chen  Created
---------------------------------------------------------*/
global class AccountSpendingReset_Batch implements Database.Batchable<sObject>, Database.Stateful {
    
    String query;
    Map<String, List<String>> errorMessageByFailedAccountId;
    
    global AccountSpendingReset_Batch() 
    {		
        this.query = 'Select Total_Agency_Spend__c, Total_Customer_Spend__c, Total_Group_Spend__c '
            + 'From Account '
            + 'Where Total_Agency_Spend__c > 0'
            + 'OR Total_Customer_Spend__c > 0 '
            + 'OR Total_Group_Spend__c > 0';
        
        errorMessageByFailedAccountId = new Map<String, List<String>>();
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) 
    {
        List<Account> accounts = (List<Account>)scope;
        
        // reset spendings if they are greater than 0
        for(Account a : accounts)
        {
            if(a.Total_Agency_Spend__c > 0)
                a.Total_Agency_Spend__c = 0;
            
            if(a.Total_Customer_Spend__c > 0)
                a.Total_Customer_Spend__c = 0;
            
            if(a.Total_Group_Spend__c > 0)
                a.Total_Group_Spend__c = 0;
        }
        
        // update accounts
        List<Database.SaveResult> saveResults = Database.update(accounts, false);
        
        // generate detail error messages if there is a failure
        errorMessageByFailedAccountId = AccountBatch_Helper.generateErrorMessagesForAccounts(saveResults, accounts, errorMessageByFailedAccountId);
    }
    
    global void finish(Database.BatchableContext BC) 
    {
        if(errorMessageByFailedAccountId.size() > 0)
        {
            // Send an email to admin to notify this issue
            AccountBatch_Helper.sendBatchErrorMessages(errorMessageByFailedAccountId, 'AccountSpendingReset_Batch');
        }
        else
        {
            // run batch to populate TCS and TAS on accounts
            String query = 'Select s.Total_Gross_Price_Ytd__c, s.Payer_Account__c, s.Payer_Account__r.RecordType.Name, '
                + 's.Advertiser_Account__c, s.Advertiser_Account__r.RecordType.Name, s.Total_Gross_Price_YTD_Last_Modified__c ' 
                + 'From Sales_Order__c s';
            
            AccountUpdateTcsTas_Batch accountUpdateTcsTas = new AccountUpdateTcsTas_Batch(null, query);
            ID batchProcessId = Database.executeBatch(accountUpdateTcsTas);
            System.debug(logginglevel.error, 'Returned batch process ID: ' + batchProcessId);
        }
        
    }
    
}
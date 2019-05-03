/*---------------------------------------------------------
* Author: Bohao Chen
* Company: Salesforce.com
* Description: This trigger is for Requirement: R-0570.
*              The purpose of this trigger is to populate TGS on account 
*              according to their child accounts' TGS or TCS or TAS
*              4/06/2014 BC: update query to find accounts which are updated since yesterday due to total agency/customer spendings update.
* History:
* 19/07/2013  Bohao Chen  Created
* 4/06/2014    Bohao Chen  Updated
* 2016-01-05   Darshan G   Updated
---------------------------------------------------------*/
global class AccountUpdateTgs_Batch implements Database.Batchable<sObject>, Database.Stateful
{
    global String query;
    //global Datetime recordStartDatetime;
    global Datetime recordStartDatetime;
    
    // Updated by Bohao Chen on 20/05/2014 for JIRA SFE-4
    global Datetime recordStopDatetime;
    //global Integer interval;
    //global Integer batchSize;
    global Map<String, List<String>> errorMessageByFailedAcctId;
    
    global Boolean processExceptionAccounts;
    // Update ends
    
    global AccountUpdateTgs_Batch(String q)
    {
        // Updated By Bohao Chen on 5/08/2014 for JIRA 549
        // BEGIN
        // Clean up TCSTAS exception
        List<Exception_Record__c> exs = [Select Id From Exception_Record__c Where Action_Type__c = 'TGS'];
        if(!exs.isEmpty()) delete exs;
        // END
        
        this.recordStartDatetime = Batch_Run_Start_Datetime__c.getAll().get('Account TGS Update Batch').Run_Start_Datetime__c;
        
        // Updated by Bohao Chen on 21/05/2014 for JIRA SFE-4
        // BEGIN
        // To decrement the number of records in query result which could cause "Too many query rows:50001" error
        errorMessageByFailedAcctId = new Map<String, List<String>>(); 
        //batchSize = Integer.valueOf(Batch_Run_Start_Datetime__c.getAll().get('Account TGS Update Batch').Batch_Size__c);
        
        system.debug('@AccountUpdateTgs_Batch start datetime: ' + this.recordStartDatetime);
        system.debug('@AccountUpdateTgs_Batch stop datetime: ' + this.recordStopDatetime);
        
        this.query = q;
        // END
    }
    
    global AccountUpdateTgs_Batch(Boolean processExceptionAccounts)
    {
        this.processExceptionAccounts = processExceptionAccounts;
        
        // Updated by Bohao Chen on 21/05/2014 for JIRA SFE-4
        // BEGIN
        // To decrement the number of records in query result which could cause "Too many query rows:50001" error
        errorMessageByFailedAcctId = new Map<String, List<String>>(); 
        //batchSize = Integer.valueOf(Batch_Run_Start_Datetime__c.getAll().get('Account TGS Update Batch').Batch_Size__c);
        
        this.query = 'Select Id, ParentId, RecordType.Name, Total_Group_Spend__c, '
            + 'Ultimate_Parent_Id__c, Total_Customer_Spend__c, Total_Agency_Spend__c, Account_Last_Modified__c, '
            + 'Parent.Name, Parent.Id, Parent.ParentId, Parent.RecordType.Name, Parent.Total_Group_Spend__c, ' 
            + 'Parent.Ultimate_Parent_Id__c, Parent.Total_Customer_Spend__c, Parent.Total_Agency_Spend__c '
            + 'From Account ' 
            + 'Where Id IN (Select Account__c From Exception_Record__c Where Action_Type__c = \'TGS\')';
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        // Updated by Bohao Chen on 13/05/2014 for JIRA SFE-4
        //this.recordStopDatetime = datetime.now();
        return Database.getQueryLocator(query);
        // Update Ends
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        AccountBatch_Helper.updatedAccountList = new Map<Id, Account>();
        
        Set<String> ultimateParentIdSet = new Set<String>();
        
        // get all ultimate parent id
        for(Account a : (List<Account>)scope)
        {
            // Updated by Bohao Chen on 06/08/2015 for SFE-707
            // Update Reason: Unable to delete private account (Perosn Account) because ultimate parent id is always blank for person account. 
            // This null ultimate parent id caused non-selective query against large object type
            if(a.Ultimate_Parent_Id__c != NULL)
            {
                ultimateParentIdSet.add(a.Ultimate_Parent_Id__c);
            }
        }
        
        // setup account heirarcy tree        
        if(!ultimateParentIdSet.isEmpty()) // for JIRA SFE-525/SFE-555
        {
            Map<Id, Map<Id, Account>> accountListMapByAccountId = AccountBatch_Helper.setupAccountHeirarcy(ultimateParentIdSet);
            
            system.debug(loggingLevel.Error,'====account heirarcy tree=== ' + accountListMapByAccountId);
            
            if(!accountListMapByAccountId.isEmpty()) // for JIRA SFE-525/SFE-555
            {
                // traverse up the account hierarchy tree and update TGS for parent accounts recursively
                for(Account a : (List<Account>)scope)
                {
                    AccountBatch_Helper.updateAccountTgs(a, accountListMapByAccountId);
                    
                    // Updated by Bohao Chen on 20/05/2014 for JIRA SFE-4
                    if(recordStopDatetime == null || recordStopDatetime < a.Account_Last_Modified__c)
                    {
                        recordStopDatetime = a.Account_Last_Modified__c;
                    }
                    // Update Ends
                }        
                
                // Updated by Bohao Chen on 21/05/2014 for JIRA SFE-4
                // in case there is any failures, put failed results in exception record so they will be picked up when batch gets run next time
                
                List<Account> accounts = AccountBatch_Helper.updatedAccountList.values();
                
                system.debug(loggingLevel.Error, '====BC: updatedAccountList===== ' + AccountBatch_Helper.updatedAccountList.values());
                
                system.debug('@AccountUpdateTcsTas_Batch accounts: ' + accounts);
                
                List<Database.SaveResult> saveResults = Database.update(accounts, false);
                
                Map<String, List<String>> localErrorMessageByFailedAcctId = AccountBatch_Helper.generateErrorMessagesForAccounts(saveResults, accounts);
                
                system.debug('@AccountUpdateTcsTas_Batch localErrorMessageByFailedAcctId: ' + localErrorMessageByFailedAcctId);
                
                if(localErrorMessageByFailedAcctId.size() > 0)
                {
                    errorMessageByFailedAcctId.putAll(localErrorMessageByFailedAcctId);
                    
                    // Updated by Bohao Chen on 30th July, 2014 for JIRA SFE-549
                    // BEGIN
                    AccountBatch_Helper.processFailRecords(localErrorMessageByFailedAcctId, 'TGS');
                    // END
                }
            }
        }
    }
    
    global void finish(Database.BatchableContext BC)
    {
        // Get the ID of the AsyncApexJob representing this batch job
        // from Database.BatchableContext.
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus
                          FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        
        // Updated by Bohao Chen on 20/05/2014 for JIRA SFE-4
        system.debug('@AccountUpdateTcsTas_Batch errorMessageByFailedAcctId: ' + errorMessageByFailedAcctId);
        
        if(errorMessageByFailedAcctId.size() > 0)
        {
            // Send an email to admin to notify this issue
            AccountBatch_Helper.sendBatchErrorMessages(errorMessageByFailedAcctId, 'AccountUpdateTgs_Batch');
        }
        // Update Ends
        else{
            // SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
                // Consolidate common function in Batch Utility class
            Batch_Utility.errorHandling(a, 'Account Update TGS Batch');
        }

        
        if(processExceptionAccounts != null && processExceptionAccounts)
        {
            // when TCS or TAS or parent account get updated, Account_Last_Modified__c will timestamp it.
            // Only rollup accounts' whose Account_Last_Modified__c is greater than last success batch run time.
            String query = 'Select Id, ParentId, RecordType.Name, Total_Group_Spend__c, '
                + 'Ultimate_Parent_Id__c, Total_Customer_Spend__c, Total_Agency_Spend__c, Account_Last_Modified__c, '
                + 'Parent.Name, Parent.Id, Parent.ParentId, Parent.RecordType.Name, Parent.Total_Group_Spend__c, ' 
                + 'Parent.Ultimate_Parent_Id__c, Parent.Total_Customer_Spend__c, Parent.Total_Agency_Spend__c '
                + 'From Account ' 
                + 'Where Account_Last_Modified__c > :recordStartDatetime '
                + 'And Ultimate_Parent_Id__c != NULL';
            
            AccountUpdateTgs_Batch accountUpdateTgs = new AccountUpdateTgs_Batch(query);
            ID batchProcessId = Database.executeBatch(accountUpdateTgs);
            System.debug('Returned batch process ID: ' + batchProcessId);
        }
        else
        {
            // timestamp success completed run time in custom setting 
            Batch_Run_Start_Datetime__c runDatetime = Batch_Run_Start_Datetime__c.getAll().get('Account TGS Update Batch');
            
            // Updated by Bohao Chen on 20/05/2014 for JIRA SFE-4
            if(this.recordStopDatetime != null)
            {
                runDatetime.Run_Start_Datetime__c = this.recordStopDatetime;
            }
            else
            {
                runDatetime.Run_Start_Datetime__c = datetime.now();
            }
            // Update Ends
            
            update runDatetime;  
        }          
        
    }
}
/*---------------------------------------------------------
* Author: Bohao Chen
* Company: Bluewolf
* Description: This batch is designed for "Calculate Total Customer/Agency Spendings" button on account records.
It's only used when admin wants to calculate total customer/agency spendings manually
* History:
* 26/05/2014   Bohao Chen  Created
---------------------------------------------------------*/
global class AccountCalculateTcsTas_Batch implements Database.Batchable<sObject>, Database.Stateful 
{
    String query;
    String accountId;
    Account account;
    Boolean singleAccount;
    
    Map<Id, Account> accountsById;
    Set<String> exceptionAccountIdSet;
    
    global AccountCalculateTcsTas_Batch(String accountId, String q)
    {
        this.accountId = accountId;
        this.singleAccount = true;
        if(q == null)
        {
            this.query = 'Select s.Total_Gross_Price_Ytd__c, s.Payer_Account__c, s.Advertiser_Account__c ' 
                + 'From Sales_Order__c s '
                + 'Where (s.Payer_Account__c =: accountId '
                + 'Or s.Advertiser_Account__c =: accountId) '
                + 'And s.Total_Gross_Price_Ytd__c > 0';
        }
        else
        {
            this.query = q;
        }
        
        // update account total customer/agency spendings
        List<Account> accounts = [Select Total_Agency_Spend__c, Total_Customer_Spend__c 
                                  From Account 
                                  Where Id =: accountId];
        
        // reset spendings
        if(accounts.size() > 0)
        {
            account = accounts[0];
            account.Total_Agency_Spend__c = 0;
            account.Total_Customer_Spend__c = 0;
        }
    }
    
    // Added by Bohao Chen on 15/Aug/2014 for JIRA SFE-611
    // This constructor is to reprocess exception accounts in order to update total customer spendings and total agency spendings for those accounts
    global AccountCalculateTcsTas_Batch()
    {
        exceptionAccountIdSet = new Set<String>();
        
        // find exception accounts for tcs or tas
        List<Exception_Record__c> ers = [Select Account__c from Exception_Record__c Where Action_Type__c =  'TCSTAS'];
        
        for(Exception_Record__c er : ers)
        {
            exceptionAccountIdSet.add(er.Account__c);
        }
        
        delete ers;
        
        // get accounts information based on account id from exception records
        // reset total agency spending and total customer spending prior to recalculation
        accountsById = new Map<Id, Account>();
        
        for(Account acct : [Select Total_Agency_Spend__c, Total_Customer_Spend__c 
                            From Account 
                            Where Id IN: exceptionAccountIdSet])
        {
            acct.Total_Agency_Spend__c = 0;
            acct.Total_Customer_Spend__c = 0;
            accountsById.put(acct.Id, acct);
        }
        
        
        this.singleAccount = false; // set to false because it's not for a single account
        
        // query all sales order whose payer account or advertiser account is among exception accounts
        this.query = 'Select s.Total_Gross_Price_Ytd__c, s.Payer_Account__c, s.Advertiser_Account__c ' 
            + 'From Sales_Order__c s '
            + 'Where (s.Payer_Account__c =: exceptionAccountIdSet '
            + 'Or s.Advertiser_Account__c =: exceptionAccountIdSet) '
            + 'And s.Total_Gross_Price_Ytd__c > 0';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Sales_Order__c> salesOrders) 
    {
        if(this.singleAccount)
            AccountBatch_Helper.updateAccountTcsTas(salesOrders, account);
        else
            AccountBatch_Helper.updateAccountTcsTas(salesOrders, accountsById);
    }
    
    global void finish(Database.BatchableContext BC) 
    {
        if(this.singleAccount)
        {
            system.debug('@AccountCalculateTcsTas_Batch finish totalAgencySpendings: ' + account.Total_Agency_Spend__c);
            system.debug('@AccountCalculateTcsTas_Batch finish totalCustomerSpendings: ' +  account.Total_Customer_Spend__c);
            
            Database.SaveResult sr = Database.update(account, false);
        }
        else
        {
            system.debug('@AccountCalculateTcsTas_Batch finish accountsById: ' + accountsById);
            
            List<Account> accounts = accountsById.values();
            
            List<Database.SaveResult> srs = Database.update(accounts, false);
            
            Map<String, List<String>> localErrorMessageByFailedAcctId = AccountBatch_Helper.generateErrorMessagesForAccounts(srs, accounts);
            
            system.debug('@AccountUpdateTcsTas_Batch localErrorMessageByFailedAcctId: ' + localErrorMessageByFailedAcctId);
            
            if(localErrorMessageByFailedAcctId.size() > 0)
            {	            
                // Send an email to admin to notify this issue
                AccountBatch_Helper.sendBatchErrorMessages(localErrorMessageByFailedAcctId, 'AccountCalculateTcsTas_Batch');

                AccountBatch_Helper.processFailRecords(localErrorMessageByFailedAcctId, 'TCSTAS');
            }
            else
            {
                AccountUpdateTgs_Batch b = new AccountUpdateTgs_Batch(true); 
                
                Integer batchSize = Integer.valueOf(Batch_Run_Start_Datetime__c.getAll().get('Account TGS Update Batch').Batch_Size__c);
                
                Id batchProcessId;
                
                if(batchSize != null && batchSize > 0 && batchSize <= 200)
                {
                    batchProcessId = database.executebatch(b, batchSize);
                }
                else
                {
                    batchProcessId = database.executebatch(b);
                }
                
                System.debug('Account TGS Update Batch batch process ID: ' + batchProcessId); 
            }
        }	
    }
}
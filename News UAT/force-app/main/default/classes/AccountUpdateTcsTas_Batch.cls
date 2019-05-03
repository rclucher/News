/*---------------------------------------------------------
* Author: Bohao Chen
* Company: Salesforce.com
* Description: This trigger is for Requirement: R-0570.
*              The purpose of this to populate TCS and TAS on account according to their sales orders.
*              4/06/2014 BC: this batch has been updated to run query for all sales order in order to initialise total spending of all accounts
*              with bookings.              
* History:
* 17/07/2013   Bohao Chen  Created
* 13/01/2014   Bohao Chen  Updated
* 4/06/2014    Bohao Chen  Updated
* 2016-01-05   Darshan G   Updated
---------------------------------------------------------*/
global class AccountUpdateTcsTas_Batch implements Database.Batchable<sObject>, Database.Stateful
{
    global String query;
    global final Datetime lastSuccessRunStartDatetime;
    global Set<Id> salesOrderAgencyAccountIdSet;
    global Set<Id> salesOrderCustomerAccountIdSet;
    //global final Datetime recordStartDatetime;
    
    // Updated by Bohao Chen on 20/05/2014 for JIRA SFE-4
    //global Datetime recordStopDatetime;
    global Map<String, List<String>> errorMessageByFailedAcctId;
    
    // Update Ends
    
    // Updated by Bohao Chen on 30/05/2014
    global final Set<Id> salesOrderIds;
    
    
    global AccountUpdateTcsTas_Batch(Set<Id> salesOrderIds, String query)
    {
        // Updated By Bohao Chen on 5/08/2014 for JIRA 549
        // BEGIN
        // Clean up TCSTAS exception
        List<Exception_Record__c> exs = [Select Id From Exception_Record__c Where Action_Type__c = 'TCSTAS'];
        if(!exs.isEmpty()) delete exs;
        // END
        
        // this is last success run time for this batch
        //this.recordStartDatetime = Batch_Run_Start_Datetime__c.getAll().get('Account TCSTAS Update Batch').Run_Start_Datetime__c;
        //system.debug('@AccountUpdateTcsTas_Batch start datetime: ' + this.recordStartDatetime);
        
        // Updated by Bohao Chen on 21/05/2014 for JIRA SFE-4
        errorMessageByFailedAcctId = new Map<String, List<String>>(); 
        // Update Ends
        
        // it only take in sales orders that have Total_Gross_Price_YTD_Last_Modified__c later than lastSuccessRunStartDatetime.
        // because they are ones whose total gross price gets updated after last time this batch gets ran.
        this.query = query;
        
        if(Test.isRunningTest() && salesOrderIds != null)
        {
            this.salesOrderIds = salesOrderIds;
            
            this.query = 'Select s.Total_Gross_Price_Ytd__c, s.Payer_Account__c, s.Payer_Account__r.RecordType.Name, '
                + 's.Advertiser_Account__c, s.Advertiser_Account__r.RecordType.Name, s.Total_Gross_Price_YTD_Last_Modified__c ' 
                + 'From Sales_Order__c s '
                + 'Where s.Id IN: salesOrderIds';
        }
        
        
        this.salesOrderAgencyAccountIdSet = new Set<Id>();
        this.salesOrderCustomerAccountIdSet = new Set<Id>();
    }
    // Update Ends
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        //system.debug('====scope==== ' + (List<Sales_Order__c>)scope);
        Set<Id> customerAccountIdSet = new Set<Id>();
        Set<Id> agencyAccountIdSet = new Set<Id>();
        
        for(Sales_Order__c salesOrder : (List<Sales_Order__c>)scope)
        {
            if(salesOrder.Payer_Account__c != null && salesOrder.Payer_Account__c != salesOrder.Advertiser_Account__c 
               && !salesOrderAgencyAccountIdSet.contains(salesOrder.Payer_Account__r.Id)) // agency 
            {
                agencyAccountIdSet.add(salesOrder.Payer_Account__r.Id);
                salesOrderAgencyAccountIdSet.add(salesOrder.Payer_Account__r.Id);
            }
            
            if(salesOrder.Advertiser_Account__c != null && !salesOrderCustomerAccountIdSet.contains(salesOrder.Advertiser_Account__r.Id))
            {
                customerAccountIdSet.add(salesOrder.Advertiser_Account__r.Id);
                salesOrderCustomerAccountIdSet.add(salesOrder.Advertiser_Account__r.Id);
            }
            
            /*if(recordStopDatetime == null || recordStopDatetime < salesOrder.Total_Gross_Price_YTD_Last_Modified__c)
{
recordStopDatetime = salesOrder.Total_Gross_Price_YTD_Last_Modified__c;
}*/
        }
        
        //system.debug('====salesOrderAgencyAccountIdSet==== ' + salesOrderAgencyAccountIdSet);
        //system.debug('====salesOrderCustomerAccountIdSet==== ' + salesOrderCustomerAccountIdSet);
        
        // update account TCS or TAS
        Map<Id, Account> accountMapById = AccountBatch_Helper.updateAccountTcsTas(agencyAccountIdSet, customerAccountIdSet);
        
        // Updated by Bohao Chen on 21/05/2014 for JIRA SFE-4
        // in case there is any failures, put failed results in exception record so they will be picked up when batch gets run next time
        
        List<Account> accounts = accountMapById.values();
        
        system.debug('@AccountUpdateTcsTas_Batch accounts: ' + accounts);
        
        List<Database.SaveResult> saveResults = Database.update(accounts, false);
        
        Map<String, List<String>> localErrorMessageByFailedAcctId = AccountBatch_Helper.generateErrorMessagesForAccounts(saveResults, accounts);
        
        system.debug('@AccountUpdateTcsTas_Batch localErrorMessageByFailedAcctId: ' + localErrorMessageByFailedAcctId);
        
        if(localErrorMessageByFailedAcctId.size() > 0)
        {
            errorMessageByFailedAcctId.putAll(localErrorMessageByFailedAcctId);
            
            // Updated by Bohao Chen on 30th July, 2014 for JIRA SFE-549
            // BEGIN
            AccountBatch_Helper.processFailRecords(localErrorMessageByFailedAcctId, 'TCSTAS');
            // END
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
        Boolean errorFlag;
        if(errorMessageByFailedAcctId.size() > 0)
        {
            // Send an email to admin to notify this issue
            AccountBatch_Helper.sendBatchErrorMessages(errorMessageByFailedAcctId, 'AccountUpdateTcsTas_Batch');
        }
        // Update Ends        
        else{
            // SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
                // Consolidate common function in Batch Utility class
            errorFlag = Batch_Utility.errorHandling(a, 'Account Update TCS TAS Batch');
        }
        
        if(!errorFlag){        
            // when TCS & TAS batch finishes
            // run AccountUpdateTgs_Batch
            
                AccountUpdateTgs_Batch b = new AccountUpdateTgs_Batch(true); 
                
                Integer batchSize = Integer.valueOf(Batch_Run_Start_Datetime__c.getAll().get('Account TGS Update Batch').Batch_Size__c);
                
                Id batchProcessId;

            if(!Test.isRunningTest())
            {                
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
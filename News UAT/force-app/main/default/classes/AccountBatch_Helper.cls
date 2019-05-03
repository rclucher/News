/*---------------------------------------------------------
* Author:  Bohao Chen
* Description: This class contains all methods used by AccountUpdateTcsTas_Batch and AccountUpdateTgs_Batch
* Company: Salesforce.com
* Date: 17/07/2013
* History:
* 17/07/2013   Bohao Chen       Created
* 20/05/2014   Bohao Chen       Updated

---------------------------------------------------------*/
global without sharing class AccountBatch_Helper
{
    public static Map<Id, Account> updatedAccountList;
    public static Map<Id, Account> originalAccountList;
    
    // this method will update account total customer spend and total agency spend by querying their sales orders
    // if sales order has different payer account and advertiser account, add total gross price YTD to payer account's total agency spend
    // otherwise, if sales order has same payer and advertiser account, add total gross price YTD to advertiser account's total customer spend
    //public static Map<Id, Account> updateAccountTcsTas(Set<Id> agencyAccountIdSet, Set<Id> customerAccountIdSet, Map<Id, Account> accountMapById)
    public static Map<Id, Account> updateAccountTcsTas(Set<Id> agencyAccountIdSet, Set<Id> customerAccountIdSet)
    {
        system.debug(logginglevel.error, '@updateAccountTcsTas agencyAccountIdSet: ' + agencyAccountIdSet);
        system.debug(logginglevel.error, '@updateAccountTcsTas customerAccountIdSet: ' + customerAccountIdSet);
        
        // Updated by Bohao Chen on 22/05/2014 for JIRA SFE-4
        Map<String, List<Sales_Order__c>> payerSalesOrdersByAccountId = new Map<String, List<Sales_Order__c>>();
        Map<String, List<Sales_Order__c>> advertiserSalesOrdersByAccountId = new Map<String, List<Sales_Order__c>>();
        
        Integer soNumber = 0;
        // query all sales orders associated with agency accounts and customer accounts
        for(Sales_Order__c so : [Select Id, Total_Gross_Price_Ytd__c, Payer_Account__c, Advertiser_Account__c 
                                 From Sales_Order__c
                                 Where Advertiser_Account__c IN: customerAccountIdSet 
                                 OR Payer_Account__c IN: agencyAccountIdSet
                                ])
        {
            // if payer account on sales order is one of agency accounts, put into Map payerSalesOrdersByAccountId
            if(so.Payer_Account__c != null && agencyAccountIdSet.contains(so.Payer_Account__c) && so.Payer_Account__c != so.Advertiser_Account__c)
            {
                if(!payerSalesOrdersByAccountId.containsKey(so.Payer_Account__c))
                {
                    payerSalesOrdersByAccountId.put(so.Payer_Account__c, new List<Sales_Order__c>());
                }
                
                payerSalesOrdersByAccountId.get(so.Payer_Account__c).add(so);
            }
            
            // if advertiser account on sales order is one of customer accounts, put into Map advertiserSalesOrdersByAccountId
            if(so.Advertiser_Account__c != null && customerAccountIdSet.contains(so.Advertiser_Account__c))
            {
                if(!advertiserSalesOrdersByAccountId.containsKey(so.Advertiser_Account__c))
                {
                    advertiserSalesOrdersByAccountId.put(so.Advertiser_Account__c, new List<Sales_Order__c>());
                }
                
                advertiserSalesOrdersByAccountId.get(so.Advertiser_Account__c).add(so);
            }
            
            soNumber++;
            system.debug(logginglevel.error, '@updateAccountTcsTas soNumber: ' + soNumber);
            system.debug(logginglevel.error, '@updateAccountTcsTas payerSalesOrdersByAccountId: ' + payerSalesOrdersByAccountId);
            system.debug(logginglevel.error, '@updateAccountTcsTas advertiserSalesOrdersByAccountId: ' + advertiserSalesOrdersByAccountId);
        }
        
        Map<Id, Account> accountMapById = new Map<Id, Account>([Select Id, Total_Agency_Spend__c, Total_Customer_Spend__c 
                                                                From Account 
                                                                Where Id IN: agencyAccountIdSet OR 
                                                                Id IN: customerAccountIdSet]);
        
        if(!payerSalesOrdersByAccountId.isEmpty())
        {
            for(Id acctId : payerSalesOrdersByAccountId.keySet())
            {
                decimal totalAgencySpend = 0;
                
                //system.debug('====Sales_Orders_Payer__r=== ' + a.Sales_Orders_Payer__r);
                
                for(Sales_Order__c so : payerSalesOrdersByAccountId.get(acctId))
                {
                    if(so.Payer_Account__c != so.Advertiser_Account__c && so.Payer_Account__c == acctId)
                    {
                        totalAgencySpend += so.Total_Gross_Price_Ytd__c;
                        system.debug(logginglevel.error, '====totalAgencySpend==== ' + acctId + ' | ' + totalAgencySpend);
                    }
                }
                
                system.debug(logginglevel.error, '====before totalAgencySpend==== ' + acctId + ' | ' + accountMapById.get(acctId).Total_Agency_Spend__c);
                
                if(accountMapById.get(acctId).Total_Agency_Spend__c == null) accountMapById.get(acctId).Total_Agency_Spend__c = 0;
                
                accountMapById.get(acctId).Total_Agency_Spend__c += totalAgencySpend;
                
                system.debug(logginglevel.error, '====after totalAgencySpend==== ' + acctId + ' | ' + accountMapById.get(acctId).Total_Agency_Spend__c);
                
            }
        }
        
        if(!advertiserSalesOrdersByAccountId.isEmpty())
        {
            for(Id acctId : advertiserSalesOrdersByAccountId.keySet())
            {
                decimal totalCustomerSpend = 0;
                
                //system.debug('====Sales_Orders_Advertiser__r=== ' + a.Sales_Orders_Advertiser__r);
                
                for(Sales_Order__c so : advertiserSalesOrdersByAccountId.get(acctId))
                {
                    if(so.Advertiser_Account__c == acctId)
                    {
                        totalCustomerSpend += so.Total_Gross_Price_Ytd__c;
                        system.debug(logginglevel.error, '====totalCustomerSpend==== ' + acctId + ' | ' + totalCustomerSpend);
                    }
                }
                
                system.debug(logginglevel.error, '====before totalCustomerSpend==== ' + acctId + ' | ' + accountMapById.get(acctId).Total_Customer_Spend__c);
                
                system.debug('@total customer spend: ' + accountMapById.get(acctId).Total_Customer_Spend__c);
                
                if(accountMapById.get(acctId).Total_Customer_Spend__c == null) accountMapById.get(acctId).Total_Customer_Spend__c = 0;
                
                accountMapById.get(acctId).Total_Customer_Spend__c += totalCustomerSpend;
                
                system.debug(logginglevel.error, '====after totalCustomerSpend==== ' + acctId + ' | ' + accountMapById.get(acctId).Total_Customer_Spend__c);
                
            }
        }
        
        system.debug(logginglevel.error, '@AccountBatch_Helper updateAccountTcsTas accountMapById: ' + accountMapById);
        
        return accountMapById;
    }
    
    // Updated by Bohao Chen on 26/05/2014 for JIRA SFE-4
    // this method will update total customer/agency spendings for a single account
    // BEGIN
    public static void updateAccountTcsTas(List<Sales_Order__c> salesOrders, Account acct)
    {
        system.debug(logginglevel.error, '@updateAccountTcsTas before update');
        system.debug(logginglevel.error, '@updateAccountTcsTas totalCustomerSpendings: ' + acct.Total_Customer_Spend__c);
        system.debug(logginglevel.error, '@updateAccountTcsTas totalAgencySpendings: ' + acct.Total_Agency_Spend__c);
        
        // query all sales orders associated with agency accounts and customer accounts
        for(Sales_Order__c so : salesOrders)
        {
            // if payer account on sales order is different from advertiser account and
            // payer account is current account, increment total agency spending
            if(so.Payer_Account__c != null && so.Payer_Account__c != so.Advertiser_Account__c && so.Payer_Account__c == acct.Id)
            {
                acct.Total_Agency_Spend__c += so.Total_Gross_Price_Ytd__c;
            }
            
            // if advertiser account on sales order is current account
            // increment total customer spending
            if(so.Advertiser_Account__c != null && so.Advertiser_Account__c == acct.Id)
            {
                acct.Total_Customer_Spend__c += so.Total_Gross_Price_Ytd__c;
            }            
        }
        
        system.debug(logginglevel.error, '@updateAccountTcsTas after update');
        system.debug(logginglevel.error, '@updateAccountTcsTas totalCustomerSpendings: ' + acct.Total_Customer_Spend__c);
        system.debug(logginglevel.error, '@updateAccountTcsTas totalAgencySpendings: ' + acct.Total_Agency_Spend__c);
        
    }
    // END
    
    // Updated by Bohao Chen on 26/05/2014 for JIRA SFE-611
    // this method will update total customer/agency spendings for list of accounts
    // BEGIN
    public static Map<Id, Account> updateAccountTcsTas(List<Sales_Order__c> salesOrders, Map<Id, Account> accountById)
    {        
        for(Sales_Order__c so : salesOrders)
        {
            // if payer account on sales order is different from advertiser account and
            // payer account is current account, increment total agency spending
            if(so.Payer_Account__c != null && so.Payer_Account__c != so.Advertiser_Account__c && accountById.containsKey(so.Payer_Account__c))
            {
                accountById.get(so.Payer_Account__c).Total_Agency_Spend__c += so.Total_Gross_Price_Ytd__c;
            }
            
            // if advertiser account on sales order is current account
            // increment total customer spending
            if(so.Advertiser_Account__c != null && accountById.containsKey(so.Advertiser_Account__c))
            {
                accountById.get(so.Advertiser_Account__c).Total_Customer_Spend__c += so.Total_Gross_Price_Ytd__c;
            }            
        }
        
        return accountById;
    }
    // END
    
    webService static void runAccountCalculateTcsTasBatch(String accountId)
    {
        if(String.isNotBlank(accountId))
        {
            AccountCalculateTcsTas_Batch b = new AccountCalculateTcsTas_Batch(accountId, null);
            Id batchProcessId = database.executebatch(b);
        }
        else
        {
            throw new RemoteException('Account Id cannot be null');
        }
    }
    
    // update ends
    
    // this method is to set account hierarchy tree based on accounts' ultimate parent Id
    public static Map<Id, Map<Id, Account>> setupAccountHeirarcy(Set<String> ultimateParentIdSet)
    {
        system.debug(loggingLevel.Error, '@AccountBatch_Helper setupAccountHeirarcy ultimateParentIdSet' + ultimateParentIdSet);
        
        Map<Id, Map<Id, Account>> accountListMapByAccountId = new Map<Id, Map<Id, Account>>();
        
        if(!ultimateParentIdSet.isEmpty()) // for JIRA SFE-525/SFE-555
        {
            AccountBatch_Helper.originalAccountList = new Map<Id, Account>();        
            
            // find accounts with same ultimate parent id and build account hierarcy structure
            for(Account a : [Select Name, Id, ParentId, RecordType.Name, Total_Group_Spend__c, 
                             Ultimate_Parent_Id__c, Total_Customer_Spend__c, Total_Agency_Spend__c,
                             Parent.Name, Parent.Id, Parent.RecordType.Name, Parent.Total_Group_Spend__c, 
                             Parent.Ultimate_Parent_Id__c, Parent.Total_Customer_Spend__c, Parent.Total_Agency_Spend__c
                             From Account 
                             Where Ultimate_Parent_Id__c IN: ultimateParentIdSet
                             or Id IN: ultimateParentIdSet
                            ])
            {
                if(!accountListMapByAccountId.containsKey(a.ParentId))
                {
                    accountListMapByAccountId.put(a.ParentId, new Map<Id, Account>());
                }
                accountListMapByAccountId.get(a.ParentId).put(a.Id, a);
                
                originalAccountList.put(a.Id, a);
            }
        }
        return accountListMapByAccountId;
    }
    
    public static void updateAccountTgs(Account a, Map<Id, Map<Id, Account>> accountListMapByAccountId)
    {
        decimal totalGroupSpend = 0;
        
        Boolean hasSameTypeChildAccount = false;
        
        system.debug(loggingLevel.Error, '====BC: current account==== ' + a);
        system.debug(loggingLevel.Error, '====BC: accountListMapByAccountId ==== ' + accountListMapByAccountId);
        
        if(accountListMapByAccountId.containsKey(a.Id))
        {
            //system.debug('====BC: child accounts==== ' + accountListMapByAccountId.get(a.Id) + ' for ' + a.Id);
            
            for(Account childAcct : accountListMapByAccountId.get(a.Id).values())
            {
                if(childAcct.RecordType.Name == a.RecordType.Name)
                {
                    hasSameTypeChildAccount = true;
                    
                    if(childAcct.Total_Group_Spend__c != null && childAcct.Total_Group_Spend__c > 0)
                    {
                        totalGroupSpend += childAcct.Total_Group_Spend__c;
                    }
                    else
                    {
                        childAcct.Total_Group_Spend__c = 0;
                        if(childAcct.RecordType.Name == 'Business Account' && childAcct.Total_Customer_Spend__c != null)
                            totalGroupSpend += childAcct.Total_Customer_Spend__c;
                        else if(childAcct.RecordType.Name == 'Agency Account' && childAcct.Total_Agency_Spend__c != null)
                            totalGroupSpend += childAcct.Total_Agency_Spend__c;
                    }
                    //system.debug(loggingLevel.Error,  '====BC: child account==== ' + childAcct.Name + ' group spending is ' + childAcct.Total_Group_Spend__c);
                }
            }
        }
        
        // depends on record type and whether this account has same type of child accounts
        // if this account has same type of child accounts, TGS should include its own
        // TAS if current account is agency account
        // OR TCS if current account is business account
        if(hasSameTypeChildAccount)
        {
            //system.debug('===BC: has same type of child accounts===');
            if(a.RecordType.Name == 'Business Account')
            {
                if(a.Total_Customer_Spend__c == null)
                {
                    a.Total_Customer_Spend__c = 0;
                }
                
                totalGroupSpend += a.Total_Customer_Spend__c;
            }
            else if(a.RecordType.Name == 'Agency Account')
            {
                if(a.Total_Agency_Spend__c == null)
                {
                    a.Total_Agency_Spend__c = 0;
                }
                
                totalGroupSpend += a.Total_Agency_Spend__c;
            }
        }
        
        a.Total_Group_Spend__c = totalGroupSpend; // update total group spend
        
        // have to update parent TGS in account heirarcy Map as well
        // so total group spend in account heirarcy map always be update-to-date to avoid miscalculation
        if(accountListMapByAccountId.containsKey(a.ParentId) && accountListMapByAccountId.get(a.ParentId).containsKey(a.Id))
        {
            accountListMapByAccountId.get(a.ParentId).get(a.Id).Total_Group_Spend__c = totalGroupSpend;
        }
        
        // add updated account to updatedAccountList        
        AccountBatch_Helper.updatedAccountList.put(a.Id, a);
        
        //system.debug('====a.Parent=== ' + a.Parent + ' | ' + a.ParentId);
        
        system.debug('====AccountBatch_Helper.originalAccountList=== ' + AccountBatch_Helper.originalAccountList);
        
        // if current account has parent account,
        // it needs to traverse up the account hierarchy tree in order to update 
        // TGS on its parent account recursively
        if(a.ParentId != null)
        {
            // NOTE: sometimes we can't get a.Parent even though a.ParentId is NOT NULL.
            // This is workaround solution to use MAP to store account information previously,
            // then retrieve account details by its Id
            if(a.Parent == null && AccountBatch_Helper.originalAccountList.containsKey(a.ParentId))
            {
                AccountBatch_Helper.updateAccountTgs(originalAccountList.get(a.ParentId), accountListMapByAccountId);
            }
            else
            {
                AccountBatch_Helper.updateAccountTgs(a.Parent, accountListMapByAccountId);
            }
        }
    }
    
    // Updated by Bohao Chen on 21/05/2014 for JIRA SFE-4
    // In case there is any failure, we need to go through dml results and find out error details for failed operations
    public static Map<String, List<String>> generateErrorMessagesForAccounts(List<Database.SaveResult> saveResults, List<Account> accounts)
    {     
        return AccountBatch_Helper.generateErrorMessagesForAccounts(saveResults, accounts, new Map<String, List<String>>());
    }
    
    // In case there is any failure, we need to go through dml results and find out error details for failed operations
    public static Map<String, List<String>> generateErrorMessagesForAccounts(List<Database.SaveResult> saveResults, 
                                                                             List<Account> accounts, 
                                                                             Map<String, List<String>> errorMessageByFailedAcctId)
    {
        Integer i = 0;
        
        for(Database.SaveResult sr : saveResults)
        {
            // if a record has been 
            if(!sr.isSuccess())
            {
                if(!errorMessageByFailedAcctId.containsKey(accounts[i].Id))
                {
                    errorMessageByFailedAcctId.put(accounts[i].Id, new List<String>());
                }
                
                for(Database.error err : sr.getErrors())
                {                    
                    errorMessageByFailedAcctId.get(accounts[i].Id).add(err.getMessage());
                }
            }
            i++;
        }
        
        return errorMessageByFailedAcctId;
    }
    
    // send message to admin with batch errors
    public static void sendBatchErrorMessages(Map<String, List<String>> errorMessageByFailedAcctId, String batchName)
    {
        // Send an email to admin to notify this issue
        String emailsString = SystemParameters__c.getAll().get('Spending_Batch_Exception_Recipients').Value__c;

        if(!String.isBlank(emailsString))
        {
            String[] toAddresses;
            
            if(emailsString.contains(';'))
                toAddresses = emailsString.split(';');
            else
                toAddresses = new String[] {emailsString};
            
        String subject = 'The following accounts throw exceptions while executing ' + batchName;
        
        String msg = '<html><body>';
        
        for(String accountId : errorMessageByFailedAcctId.keySet())
        {
            msg += '<div>Account Id: ' + accountId + ' with Error Message(s):';
            
            for(String errMsg : errorMessageByFailedAcctId.get(accountId))
            {
                msg += '<br />' + errMsg;
            }
            
            msg += '</div><br />';
        }
        
        msg += '</body></html>';             
        
        Global_Helper.sendMessageToUsers(subject, msg, toAddresses, 'html');
    }
    }
    // Update Ends
    
    public static void processFailRecords(Map<String, List<String>> errorMessageByFailedAcctId, String actionType)
    {
        Set<String> exceptionIdSet = new Set<String>();
        
        for(Exception_Record__c er : [Select Account__c 
                                      From Exception_Record__c 
                                      Where Account__c IN: errorMessageByFailedAcctId.keySet() 
                                      And Action_Type__c =: actionType])
        {
            exceptionIdSet.add(er.Account__c);
        }
        
        
        List<Exception_Record__c> exceptionRecords = new List<Exception_Record__c>(); 
        
        for(String acctId : errorMessageByFailedAcctId.keySet())
        {
            if(!exceptionIdSet.contains(acctId))
            {
                Exception_Record__c exceptionRecord = new Exception_Record__c();
                exceptionRecord.Action_Type__c = actionType;			
                String message = String.join(errorMessageByFailedAcctId.get(acctId), ' and ');
                exceptionRecord.Failure_Reason__c = message;
                exceptionRecord.Account__c = acctId;
                exceptionRecords.add(exceptionRecord);
            }
        }
        
        insert exceptionRecords;
    }
    
    
    // Updated by Bohao Chen on 26/05/2014 for JIRA SFE-4
    public class RemoteException extends Exception {}
    // Update Ends
    
}
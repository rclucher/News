/*---------------------------------------------------------
* Author: Bohao Chen
* Company: Salesforce.com
* Description: This controller is for trigger AccountManagement for requriement 0570
* History:
* 19/09/2013  Bohao Chen  Created
---------------------------------------------------------*/
public without sharing class AccountHierarchyTree_Controller
{
    public Map<Id, String> ultimateParentIdMapByAccountId { 
        get{ return ultimateParentIdMapByAccountId = ultimateParentIdMapByAccountId == null ? new Map<Id, String>() : ultimateParentIdMapByAccountId; } set; }
    
    public List<Account> childAccountListWithParentUpdated { 
        get{ return childAccountListWithParentUpdated = childAccountListWithParentUpdated == null ? new List<Account>() : childAccountListWithParentUpdated; } set; }        
    
    public Map<Id, Map<Id, Account>> accountListMapByAccountId;
    
    public AccountHierarchyTree_Controller()
    {
    }
    
    // get ultimate parent id for all parent accounts 
    public void getUltimateParentIdMapByAccountId()
    {
        for(Account a : [Select Id, Ultimate_Parent_Id__c, ParentId 
                         From Account 
                         Where Id IN: ultimateParentIdMapByAccountId.keySet()])
        {
            if(a.ParentId != null)
            {
                ultimateParentIdMapByAccountId.put(a.Id, a.Ultimate_Parent_Id__c);
            }
            else
            {
                // Although we assign current account id to ultimate parent id when current account has no parent,
                // this value has been committed to database. Therefore, we have to manually reflect this scenario 
                // in ultimateParentIdMapByAccountId map collection
                ultimateParentIdMapByAccountId.put(a.Id, a.Id);
            }
        }
    }
    
    // update ultimate parent Id for child accounts
    public void updateUltimateParentId(List<Account> accts)
    {
        for(Account a : accts)
        {
            if(String.isNotBlank(a.ParentId))
            {
                a.Ultimate_Parent_Id__c = ultimateParentIdMapByAccountId.get(a.ParentId);
            }
            
            a.Ultimate_Parent_Id__c = Global_Helper.convertIdToFifteenDigits(a.Ultimate_Parent_Id__c);
        }
    }
    
    // update ultimate parent for child accounts of those accounts with their parents updated
    public void updateChildAccounts(List<Account> accountListWithParentUpdated)
    {
        for(Account a : accountListWithParentUpdated)
        {
            if(accountListMapByAccountId.containsKey(a.Id))
            {
                updateChildAccountsUltimateParent(accountListMapByAccountId.get(a.Id).values(), accountListMapByAccountId, a);
            }
        }
    }
    
    // recursive function to update Ultimate_Parent_Id__c for all child accounts
    private void updateChildAccountsUltimateParent(List<Account> childAccounts, Map<Id, Map<Id, Account>> accountListMapByAccountIdLocal, Account acct)
    {
        for(Account a : childAccounts)
        {
            a.Ultimate_Parent_Id__c = acct.Ultimate_Parent_Id__c;
            
            childAccountListWithParentUpdated.add(a);
            
            if(accountListMapByAccountIdLocal.containsKey(a.Id))
            {
                updateChildAccountsUltimateParent(accountListMapByAccountIdLocal.get(a.Id).values(), accountListMapByAccountIdLocal, acct);
            }
        }
    }
}
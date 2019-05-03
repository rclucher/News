/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: 
 * 1. This trigger is for Requirement: R-0570.
 *              The purpose of this trigger is to maintain account hierarchy tree 
 *              based on their parent account and their ultimate parent id.
 *              The account hierarchy tree is to facilitate calculation 
 *              when populating total group spend for one account and all its child accounts
 *              based on their child accounts' total customer spend and total agency spend
 * 2. When empty account's parent account lookup field, need to tick 'No Parent' checkbox. 
 *    Using custom code rather than workflow is because deleting parent account bypass workflow and validation rule.
 * 3. To populate AdPoint User Id from External System User Credential based on account owner 
 * History:
 * 17/07/2013  Bohao Chen  Created
 * 19/09/2013  Bohao Chen  Updated
 * 20/11/2013  Bohao Chen  Updated
 * 25/11/2013  Bohao Chen  Updated
 * 19/12/2013  Bohao Chen  Updated
 * 21/08/2018  Pratyush Chalasani (Ativa) - Updated (NR-390)
 * 03/09/2018  Mohsin Ali (Ativa) - Added the method from Helper Class to the Trigger. {AccountManagement_Trigger_Helper.setCustomerTier(Trigger.New);} Refer to Jira: NR-390 (Comments from Craig Taylor).
 ---------------------------------------------------------*/
trigger AccountManagement on Account (before update, before insert, before delete, after insert) 
{
No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());

if (Global_Helper.canTrigger( 'AccountManagement' ) && !AccountManagement_Trigger_Helper.byPassAccountTrigger){

    // NR-390: Customer Tier for Print includes Segment variation
    if (Trigger.isBefore && Trigger.isUpdate) {
         AccountManagement_Trigger_Helper.setCustomerTier(Trigger.New);
        
        AccountManagement_Trigger_Helper.preventOwnerChangeWhenPortfolioAttached(Trigger.New, Trigger.oldMap);
    }

    // AdSales-121 2016-08-04 darshan.gosar@bluewolfgroup.com
        // Added call to new method to populate Person Contact Id on Primary Account field on insert of Person Account
    if(Trigger.isInsert && Trigger.isAfter){
         AccountManagement_Trigger_Helper.updatePersonAccountPrimaryContact(Trigger.New);
    }

    AccountHierarchyTree_Controller accountHierarchyTree = new AccountHierarchyTree_Controller();
    
    /*
     * when a new account has been inserted
     * if this new account has a parent, look up parent's ultimate parent id. 
     * if its parent account doesn't have ultimate parent id, 
     * use parent account id as ultimate parent Id.
     * Otherwise, if this new account has no parent, then ultimate parent id is current account id
     */
    if(trigger.isBefore && trigger.isInsert)
    {
        Set<Id> ownerIds = new Set<Id>();
        
        for(Account a : trigger.new)
        {
            if ((notriggers == null || !notriggers.Flag__c) && a.csb2c__E_Commerce_Customer_Id__c != a.AdPoint_Id__c) {
                a.csb2c__E_Commerce_Customer_Id__c = a.AdPoint_Id__c;
            }
            if(a.ParentId != null)
            {
                accountHierarchyTree.ultimateParentIdMapByAccountId.put(a.ParentId, '');
            }
            
            /*** Updated By: Bohao Chen on 19/March/2014 for JIRA issue SFE-81 *******/
            /*else
            {
                a.No_Parent_Account__c = true;
            }*/
            /*** Updated By: Bohao Chen ****/
            
            if(a.OwnerId != null)
            {
                ownerIds.add(a.OwnerId);
            }
        }
        
        // get ultimate parent id for all parent accounts
        accountHierarchyTree.getUltimateParentIdMapByAccountId();
        
        accountHierarchyTree.updateUltimateParentId(trigger.new);
         
        // update adpoint user id based on account owner
        /**** Begin: AdPoint *****/
        Map<Id, String> adPointUserIdByAcctId = AccountManagement_Trigger_Helper.findAdPointUserIdByAccountOwner(ownerIds);
        
        for(Account a : trigger.new)
        {
            if(adPointUserIdByAcctId.containsKey(a.OwnerId))
            {
                a.AdPoint_User_Id__c = adPointUserIdByAcctId.get(a.OwnerId);
            }
        }
        /**** Begin: AdPoint *****/
    }
    
    /* 
     * when a new account has been updated
     * 1. from null parent to some parent, assign parent's ultimate parent id to account's ultimate parent id
     * 2. from one parent to another, assign new parent's ultimate parent id to account's ultimate parent id
     * 3. from some parent to null, update account's ultimate parent id to current account id
     */
    if(trigger.isBefore && trigger.isUpdate)
    {
        List<Account> accountListWithParentUpdated = new List<Account>();
        Set<String> oldUltimateParentIdSet = new Set<String>();
         
        /******** Start: R-1208 *********/
        List<Account> ownerChangedAccounts = new List<Account>();
        Map<Id, Id> oldOwnerIdByAccountId = new Map<Id, Id>();
        Map<Id, Id> newOwnerIdByAccountId = new Map<Id, Id>();
        Set<Id> oldOwnerIdSet = new Set<Id>(); 
        /******** End: R-1208 *********/
        
        /************ AdPoint **********/
        List<Account> digitalAccounts = new List<Account>();
        Set<Id> ownerIds = new Set<Id>();
        /************ End: AdPoint **********/
        
        for(Account a : trigger.new)
        {
            if ((notriggers == null || !notriggers.Flag__c) && a.csb2c__E_Commerce_Customer_Id__c != a.AdPoint_Id__c) {
                a.csb2c__E_Commerce_Customer_Id__c = a.AdPoint_Id__c;
            }
            if(a.ParentId != trigger.oldMap.get(a.Id).ParentId)
            {
                oldUltimateParentIdSet.add(trigger.oldMap.get(a.Id).Ultimate_Parent_Id__c);
                
                if(a.ParentId != null)
                {
                    accountHierarchyTree.ultimateParentIdMapByAccountId.put(a.ParentId, '');
                }
                else
                {
                    a.Ultimate_Parent_Id__c = a.Id;
                }
            
                accountListWithParentUpdated.add(a);
            }
            
            a.Ultimate_Parent_Id__c = Global_Helper.convertIdToFifteenDigits(a.Ultimate_Parent_Id__c);
            
            if(a.OwnerId != trigger.oldMap.get(a.Id).OwnerId)
            {
                ownerChangedAccounts.add(a);
                oldOwnerIdByAccountId.put(a.Id, trigger.oldMap.get(a.Id).OwnerId);
                newOwnerIdByAccountId.put(a.Id, a.OwnerId);
                oldOwnerIdSet.add(trigger.oldMap.get(a.Id).OwnerId);
                ownerIds.add(a.OwnerId);
            }
            
            /************ AdPoint **********/
            // when account status changes to 'Active', we have to send outbound message
            // for all of account' contacts to make them digital as well
            if(a.Digital_Status__c == 'Active' 
                && a.Digital_Status__c != trigger.oldMap.get(a.Id).Digital_Status__c
                && a.AdPoint_Id__c != null
                && a.Is_Digital__c 
                && a.Status__c == 'Active')
            {
                digitalAccounts.add(a);
            }
            /************ End: AdPoint **********/
        }
        
        if(accountListWithParentUpdated.size() > 0)
        {
            // set up account hierarcy
            accountHierarchyTree.accountListMapByAccountId = AccountBatch_Helper.setupAccountHeirarcy(oldUltimateParentIdSet);
            
            accountHierarchyTree.getUltimateParentIdMapByAccountId();
            
            accountHierarchyTree.updateUltimateParentId(trigger.new);
        
            accountHierarchyTree.updateChildAccounts(accountListWithParentUpdated);
            update accountHierarchyTree.childAccountListWithParentUpdated;
        }
        
        /******** Start: R-1208 *********/
        // if account owner changed, the previous account owner should be removed from account team
        List<AccountTeamMember> deletedTeamMembers = new List<AccountTeamMember>(); 
        List<AccountTeamMember> newTeamMembers = new List<AccountTeamMember>(); 
        
        system.debug('===ownerChangedAccounts=== ' + ownerChangedAccounts);
        
        if(ownerChangedAccounts.size() > 0)
        {
            for(AccountTeamMember atm : [Select a.UserId, a.AccountId From AccountTeamMember a 
                                        Where a.AccountId IN: ownerChangedAccounts 
                                        And a.UserId IN: oldOwnerIdSet])
            {
                // this condition is to check if account team member belongs to owner changed account
                if(oldOwnerIdByAccountId.get(atm.AccountId) == atm.UserId)
                {
                    deletedTeamMembers.add(atm);
                }
            }
            
            for(Id accountId : newOwnerIdByAccountId.keySet())
            {
                newTeamMembers.add(
                    new AccountTeamMember(UserId = newOwnerIdByAccountId.get(accountId), AccountId = accountId, TeamMemberRole = 'Account Manager')
                );
            }
        }
        
        system.debug('===deletedTeamMembers=== ' + deletedTeamMembers);
        system.debug('===newTeamMembers=== ' + newTeamMembers);
        
        delete deletedTeamMembers;
        insert newTeamMembers;
        
        /******** End: R-1208 *********/
        
        /************ AdPoint **********/
        if(digitalAccounts.size() > 0)
        {
            // change contact digital status to 'Pending' and send outbound message
            // except the one with digital status is already 'Active' 
            ContactUpdate_Helper.updateContactsDigitalStatusForAccounts(digitalAccounts);
        }
        
        // update adpoint user id based on account owner
        Map<Id, String> adPointUserIdByAcctId = AccountManagement_Trigger_Helper.findAdPointUserIdByAccountOwner(ownerIds);
        
        for(Account a : trigger.new)
        {
            if(a.OwnerId != trigger.oldMap.get(a.Id).OwnerId && adPointUserIdByAcctId.containsKey(a.OwnerId))
            {
                a.AdPoint_User_Id__c = adPointUserIdByAcctId.get(a.OwnerId);
            }
        }
        /************ End: AdPoint **********/
    }
    
    /*
     * if deleting account has child accounts, code has to update ultimate parent id on all its child accounts.
     * it will empty ultimate parent Id for deleting accounts' direct child accounts.
     * Next, it will recursively update ultimate parent id for all child accounts of deleting accounts' direct child accounts
     */
     Set<Id> parentAccountIdSet = new Set<Id>();
     
    if(trigger.isBefore && trigger.isDelete)
    {
        Set<String> oldUltimateParentIdSet = new Set<String>();
        
        for(Account a : trigger.old)
        {
            // Updated by Bohao Chen on 06/08/2015 for SFE-707
            // Update Reason: Unable to delete private account (Perosn Account) because ultimate parent id is always blank for person account. 
            // This null ultimate parent id caused non-selective query against large object type
            if(a.Ultimate_Parent_Id__c != NULL)
            {
                oldUltimateParentIdSet.add(a.Ultimate_Parent_Id__c);
            }
            parentAccountIdSet.add(a.Id);
        }
        
        accountHierarchyTree.accountListMapByAccountId = AccountBatch_Helper.setupAccountHeirarcy(oldUltimateParentIdSet);      
        
        List<Account> immediateChildAccounts = new List<Account>();
        
        for(Account a : trigger.old)
        {
            system.debug('===accountListMapByAccountId=== ' + accountHierarchyTree.accountListMapByAccountId);
            
            if(accountHierarchyTree.accountListMapByAccountId.containsKey(a.Id))
            {
                for(Account subA : accountHierarchyTree.accountListMapByAccountId.get(a.Id).values())
                {
                    subA.Ultimate_Parent_Id__c = subA.Id;
                    
                    accountHierarchyTree.childAccountListWithParentUpdated.add(subA);
                }
                
                system.debug('===childAccountListWithParentUpdated=== ' + accountHierarchyTree.childAccountListWithParentUpdated);
                
                immediateChildAccounts.addAll(accountHierarchyTree.accountListMapByAccountId.get(a.Id).values());
            }
        }
        
        system.debug('===immediateChildAccounts=== ' + immediateChildAccounts);
        
        system.debug('===childAccountListWithParentUpdated initial=== ' + accountHierarchyTree.childAccountListWithParentUpdated);
        
        accountHierarchyTree.updateChildAccounts(immediateChildAccounts);
        
        system.debug('===childAccountListWithParentUpdated final=== ' + accountHierarchyTree.childAccountListWithParentUpdated);
        
        update accountHierarchyTree.childAccountListWithParentUpdated;
    }
    
    /******** Start: R-1208 *********/
    List<AccountTeamMember> accountTeamMembers = new List<AccountTeamMember>();
    
    // add account owner into account team if it's first time insert/create
    if(trigger.isAfter && trigger.isInsert)
    {
        for(Account a : trigger.new)
        {
            AccountTeamMember acctTeamMember = new AccountTeamMember();
            acctTeamMember.AccountId = a.Id;
            acctTeamMember.UserId = a.OwnerId;
            acctTeamMember.TeamMemberRole = 'Account Manager';
            accountTeamMembers.add(acctTeamMember);
        }
    }
    
    //insert accountTeamMembers;
    /******** End: R-1208 *********/
    
    // the following code will tick accounts 'no parent' checkbox for those accounts whose parent account being deleted
    if(parentAccountIdSet.size() > 0)
    {
        List<Account> noParentAccounts = new List<Account>();
        
        for(Account a : [Select Id, No_Parent_Account__c From Account Where ParentId IN: parentAccountIdSet])
        {
            a.No_Parent_Account__c = true;
            a.ParentId = null;
            noParentAccounts.add(a);
        }
        
        update noParentAccounts;
    }        
}
}
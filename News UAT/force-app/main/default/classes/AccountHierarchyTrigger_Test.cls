/*---------------------------------------------------------
 * Author:  Bohao Chen
 * Description: This class contains unit tests for validating the behavior of AccountManagement trigger
 * Company: Salesforce.com
 * Date: 22/07/2013
 * History:
 * 22/07/2013   Bohao Chen              Created
 * 2017-06-02   louis.wang@bluewolf.com Updated
 *              Item-00298 - Reduce the hierarchy level from 9 to 3, in order to reduce iteration 
 *                             and avoid CPU Limit exception.
 *                         - Updated Width and Depth variable to 3 (from 5), to reduce iteration
 * Test Coverage
 *      - AccountManagement.trigger             80%
 *      - AccountHierachyTree_Controller.cls    100%
 ---------------------------------------------------------*/
@isTest
private class AccountHierarchyTrigger_Test 
{
    static List<Account> allChildAccounts;
    static List<Account> parentAccounts;

    static final double WIDTH = 3;
    static final double DEPTH = 3;
    static testMethod void insertTest() 
    {
    	AccountHierarchyTrigger_Test.createAccountHierarchy();

    	Test.startTest();

    	system.assertEquals(14, allChildAccounts.size());
    	
    	// validate all accounts, no matter what level they are, have same ultimate parent id 
    	// which is id of top level account 
        for(Account acct : [Select Ultimate_Parent_Id__c 
	                        From Account 
	                        Where Id IN: allChildAccounts])
        {
            system.assertEquals(parentAccounts[0].Id, acct.Ultimate_Parent_Id__c);
        }

    	Test.stopTest();
    }
    
    static testMethod void updateTest() 
    {
        // insert top level account without parent
        AccountHierarchyTrigger_Test.createAccountHierarchy();
        
        Test.startTest();
        
        // change second level accounts to new top level account
        // all child accounts should have their ultimate parent id changed
        List<Account> secondLevelChildAccounts = new List<Account>();
        
        for(Account a : [Select a.ParentId From Account a
                         Where a.ParentId =: parentAccounts[0].Id])
        {
        	a.ParentId = parentAccounts[1].Id;
        	secondLevelChildAccounts.add(a);
        }
        
        update secondLevelChildAccounts;
        
        for(Account acct : [Select Ultimate_Parent_Id__c 
                            From Account 
                            Where Id IN: allChildAccounts])
        {
            system.assertEquals(parentAccounts[1].Id, acct.Ultimate_Parent_Id__c);
        }
        
        // change parent Id from some account to null
        secondLevelChildAccounts.clear();
        for(Account a : [Select a.ParentId From Account a
                         Where a.ParentId =: parentAccounts[1].Id])
        {
            a.ParentId = null;
            a.No_Parent_Account__c = true;
            secondLevelChildAccounts.add(a);
        }
        
        update secondLevelChildAccounts;
        
        // change paret Id from null to some account
        secondLevelChildAccounts.clear();
        for(Account a : [Select a.ParentId From Account a
                         Where a.ParentId =: NULL And a.Id NOT IN: parentAccounts])
        {
            a.ParentId = parentAccounts[1].Id;
            a.No_Parent_Account__c = false;
            secondLevelChildAccounts.add(a);
        }
        
        update secondLevelChildAccounts;
        
        parentAccounts[0].ParentId = parentAccounts[1].Id;
        parentAccounts[0].No_Parent_Account__c = false;
        update parentAccounts[0];
        
        Test.stopTest();        
    }

    static testMethod void deleteTest() 
    {
        // insert top level account without parent
        AccountHierarchyTrigger_Test.createAccountHierarchy();
        
        Test.startTest();

        system.assertEquals(14, allChildAccounts.size()); //2046
        
        // validate all accounts, no matter what level they are, have same ultimate parent id 
        // which is id of top level account 
        for(Account acct : [Select Ultimate_Parent_Id__c 
                            From Account 
                            Where Id IN: allChildAccounts])
        {
            system.assertEquals(Global_Helper.convertIdToFifteenDigits(parentAccounts[0].Id), acct.Ultimate_Parent_Id__c);
        }
        
        // find second level accounts to new top level account
        // then delete top level account.
        // all accounts related to second level accounts 
        // should have their ultimate parent id related to their second level account 
        Set<String> secondLevelChildAccountIdSet = new Set<String>();
        List<Account> secondLevelChildAccounts = new List<Account>();
        Map<Id, List<Account>> childAccountsByUltimateParentId = new Map<Id, List<Account>>();
        
        for(Account a : [Select a.ParentId, a.Id From Account a
                        Where a.ParentId =: parentAccounts[0].Id])
        {
        	childAccountsByUltimateParentId.put(Global_Helper.convertIdToFifteenDigits(a.Id), new List<Account>());
        	secondLevelChildAccountIdSet.add(Global_Helper.convertIdToFifteenDigits(a.Id));
        	secondLevelChildAccounts.add(a);
        }
        
        system.debug('===childAccountsByUltimateParentId=== ' + childAccountsByUltimateParentId);
        system.debug('===secondLevelChildAccountIdSet=== ' + secondLevelChildAccountIdSet);
        
        // delete top level account
        delete parentAccounts;
        
        
        // validate change on ultimate parent id
        for(Account a : [Select a.ParentId, a.Ultimate_Parent_Id__c From Account a
                         Where a.Ultimate_Parent_Id__c IN: secondLevelChildAccountIdSet
                         and a.Id NOT IN: secondLevelChildAccountIdSet])
        {
        	system.assert(childAccountsByUltimateParentId.containsKey(a.Ultimate_Parent_Id__c));
        	childAccountsByUltimateParentId.get(a.Ultimate_Parent_Id__c).add(a);
        }

        for(Id acctId : childAccountsByUltimateParentId.keySet())
        {
        	// for each account on second level, we should be able to retrieve 6 child accounts (3 level scenario)
        	// with same ultimate parent id as account in second level after we delete first level account
        	system.assertEquals(6, childAccountsByUltimateParentId.get(acctId).size());
        } 
        
        
        // delete second level accounts
        Set<String> thirdLevelChildAccountIdSet = new Set<String>();
        childAccountsByUltimateParentId.clear();
        
        // query third level accounts
        for(Account a : [Select a.ParentId, a.Ultimate_Parent_Id__c From Account a
                         Where a.ParentId IN: secondLevelChildAccountIdSet])
        {
        	thirdLevelChildAccountIdSet.add(Global_Helper.convertIdToFifteenDigits(a.Id));
        	childAccountsByUltimateParentId.put(a.Id, new List<Account>());
        }        
        
        delete secondLevelChildAccounts;
        
        // validate change on ultimate parent id after second level child accounts get deleted
        for(Account a : [Select a.ParentId, a.Ultimate_Parent_Id__c From Account a
                         Where a.Ultimate_Parent_Id__c IN: thirdLevelChildAccountIdSet
                         And a.Id NOT IN: thirdLevelChildAccountIdSet])
        {
            system.assert(childAccountsByUltimateParentId.containsKey(a.Ultimate_Parent_Id__c));
            childAccountsByUltimateParentId.get(a.Ultimate_Parent_Id__c).add(a);
        }

        for(Id acctId : childAccountsByUltimateParentId.keySet())
        {
            // for each account on third level, we should be able to retrieve 2 child accounts (3 level scenario)
            // with same ultimate parent id as account in second level after we delete first level account
            system.assertEquals(2, childAccountsByUltimateParentId.get(acctId).size());
        } 
        
        Test.stopTest();
    }
    
    // NOTE: this test method will simulate initial account load without parent id via dataloader.
    // Then update parent id accordingly via dataloader.
    static testMethod void accountLoadTest() 
    {
    	// upload accounts without parent account
    	List<Account> accounts = TestDataFactory.createAccounts(Integer.valueOf(math.pow(WIDTH, DEPTH)), false);
    	insert accounts;
    	
    	accounts = [Select Id, Ultimate_Parent_Id__c, ParentId From Account Where Id IN: accounts];
    	
    	// verify accounts' ultimate parent id is account id
    	for(Account acct : accounts)
    	{
            system.assertEquals(acct.Id, acct.Ultimate_Parent_Id__c);
    	}
    	
    	Test.startTest();
    	
    	List<Account> localParentAccounts = new List<Account>();
    	
    	for(Integer i = 0; i < WIDTH; i++)
    	{
    		localParentAccounts.add(accounts[i]);
    	}
    	
       	assignParentIdToChildren(localParentAccounts, accounts, 2);
    	
        accounts = [Select Id, Ultimate_Parent_Id__c, ParentId From Account Where Id IN: accounts];
    	
    	// when parent id update completed, check ultimate of each child accounts
    	Map<Id, List<Account>> accountsByParentId = new Map<Id, List<Account>>();
    	
    	for(Account acct : accounts)
    	{
    	   if(!accountsByParentId.containsKey(acct.ParentId))
    	   {
                accountsByParentId.put(acct.ParentId, new List<Account>());
    	   }
    	   
    	   accountsByParentId.get(acct.ParentId).add(acct);
    	}
    	
    	system.debug(logginglevel.error, '===accountsByParentId=== ' + accountsByParentId);
    	
    	for(Integer i = 0; i < WIDTH; i++)
    	{
    		Id acctId = accounts[i].Id;
    		system.assertEquals(acctId, accounts[i].Ultimate_Parent_Id__c);
            checkUltimateParentId(accountsByParentId, acctId, acctId);
    	}
    	
    	Test.stopTest();
    }
    
    static void checkUltimateParentId(Map<Id, List<Account>> accountsByParentId, Id ultimateParentId, Id parentAcctId)
    {
    	if(accountsByParentId.containsKey(parentAcctId))
    	{
	    	List<Account> childAccounts = accountsByParentId.get(parentAcctId);
	    	
	    	for(Account a : childAccounts)
	    	{
	    		system.debug(logginglevel.error, '===size of children=== ' + childAccounts.size());
	    	   system.assertEquals(ultimateParentId, a.Ultimate_Parent_Id__c);
	    	   checkUltimateParentId(accountsByParentId, ultimateParentId, a.Id);
	    	}
    	}
    }
    
    static void assignParentIdToChildren(List<Account> localParentAccounts, List<Account> allAccounts, Integer currentDepth)
    {
    	if(currentDepth >= 2 && currentDepth <= DEPTH)
    	{
    		List<Account> childAccounts = new List<Account>();
    		
	    	Integer startIndex = Integer.valueOf(MATH.pow(WIDTH, currentDepth - 1)); 
	    	Integer endIndex = Integer.valueOf(MATH.pow(WIDTH, currentDepth) - 1);
	    	
	    	system.debug(logginglevel.error, '===indices=== ' + startIndex + ' | ' + endIndex);
	    	
	    	for(; startIndex <= endIndex; startIndex++)
	    	{
	    		childAccounts.add(allAccounts[startIndex]);
	    	}
	    	
	    	for(Account pa : localParentAccounts)
	    	{
	    		Integer offset = 0;
	    		
	    		Integer j = Integer.valueOf(WIDTH * offset);
	    		
	    		for(Integer i = j; i < j + WIDTH; i++)
	    		{
	    			childAccounts[i].ParentId = pa.Id;
	    			childAccounts[i].No_Parent_Account__c = false;
	    		}
	    		
	    		offset++;
	    	}
	    	
            system.debug(logginglevel.error, '===childAccounts=== ' + childAccounts);
	    	
	    	update childAccounts;
	    	
	    	// recursively update all child accounts
	    	assignParentIdToChildren(childAccounts, allAccounts, currentDepth + 1);
    	}
    }

    
    // this function is used to set up account hierarchy for each unit test method
    static void createAccountHierarchy()
    {
        // insert top level account without parent
        Account acctTopLevel1 = TestDataFactory.createSingleAccount(null, 0, null, null, null);
        Account acctTopLevel2 = TestDataFactory.createSingleAccount(null, 0, null, null, null);
        
        parentAccounts = new List<Account>();
        parentAccounts.add(acctTopLevel1);
        parentAccounts.add(acctTopLevel2);
        insert parentAccounts;
        
        // verify that top level accounts has ultimate parent id which equals to their account id
        parentAccounts = [Select Ultimate_Parent_Id__c From Account Where Id IN: parentAccounts limit 2];
        system.assertEquals(parentAccounts[0].Id, parentAccounts[0].Ultimate_Parent_Id__c);
        system.assertEquals(parentAccounts[1].Id, parentAccounts[1].Ultimate_Parent_Id__c);
        
        // insert child accounts
        allChildAccounts = new List<Account>();
        // 2017-06-02 Item-0-0298 louis.wang@bluewolf.com 
        //   - Reduce the hierarchy level from 9 to 3, in order to reduce execution time and avoid CPU Limit exception
        allChildAccounts.addAll(TestDataFactory.createChildAccounts(allChildAccounts, new Account[]{parentAccounts[0]}, 2, 
                                                                    1, 3, null, null, null));
        // 2017-06-02 Item-0-0298 louis.wang@bluewolf.com 
        //   - The following numbers are referenced by assertion. 
        //             totalLevel      allChildAccounts.size()
        //                     1               2
        //                     2               6
        //                     3               14
        //                     ...             ...
        //                     8               510
        //                     9               1022
        //   - When totalLevel=9 is used, it would take the entire test class around 14 min to execute,
        //       if CPU Limit Exceeded exception did not occur.
    }
}
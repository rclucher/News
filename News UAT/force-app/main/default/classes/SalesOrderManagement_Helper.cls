/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Bluewolf
 * Description: This helper class contains all necessary class methods for sales order controllers or trigger
 * History:
 * 27/05/2014    Bohao Chen  Created
 ---------------------------------------------------------*/
public without sharing class SalesOrderManagement_Helper 
{	
	public static void updateTcsTasByAccountIdMap(String acctId, Decimal grossPrice, Map<Id, Decimal> tsByAccountId)
	{
		if(acctId != null)
		{
	        if(tsByAccountId.containsKey(acctId))                            
	            tsByAccountId.put(acctId, (tsByAccountId.get(acctId) + grossPrice));                            
	        else
	            tsByAccountId.put(acctId, 0 + grossPrice);   
        }
	}

	public static void updateAccountSpendings(Map<Id, Decimal> tcsByAccountId, Map<Id, Decimal> tasByAccountId)
	{
		List<Account> accounts = new List<Account>();
		// query all accounts
		for(Account acct : [Select Total_Agency_Spend__c, Total_Customer_Spend__c
							From Account 
							Where Id IN: tcsByAccountId.keySet() 
							OR Id IN: tasByAccountId.keySet()])
		{
			if(tcsByAccountId.containsKey(acct.Id))
			{
				if(acct.Total_Customer_Spend__c == null) acct.Total_Customer_Spend__c = 0;
				acct.Total_Customer_Spend__c += tcsByAccountId.get(acct.Id);
			}

			if(tasByAccountId.containsKey(acct.Id))
			{
				if(acct.Total_Agency_Spend__c == null) acct.Total_Agency_Spend__c = 0;
				acct.Total_Agency_Spend__c += tasByAccountId.get(acct.Id);
			}

			accounts.add(acct);
		}

		// TODO: put try and catch here update
		if(accounts.size() > 0)
		{
			try{
				update accounts;
			}
	        catch(Exception ex)
	        {
	            ExLog.log(ex, 'config', accounts, 'SFE-824 Investigation');
	        } 
			//Global_Helper.hasRunSalesOrderTriggerUpdateOnce = true;
		}
	}

    // Update by Bohao Chen for JIRA SFE-4 on 2/06/2014
    // to stop recurisive trigger gets from firing
    @TestVisible private static Set<Id> salesOrderIdsForUpdateTrigger = new Set<Id>();
    @TestVisible private static Set<Id> salesOrderIdsForDeleteTrigger = new Set<Id>();

    public static void addIdIntoSalesOrderIdSetForUpdate(Id soId)
    {
        salesOrderIdsForUpdateTrigger.add(soId);
    }

    public static boolean isNotInSalesOrderIdSetForUpdate(Id soId)
    {
        return !salesOrderIdsForUpdateTrigger.contains(soId);
    }

    public static void addIdIntoSalesOrderIdSetForDelete(Id soId)
    {
        salesOrderIdsForDeleteTrigger.add(soId);
    }

    public static boolean isNotInSalesOrderIdSetForDelete(Id soId)
    {
        return !salesOrderIdsForDeleteTrigger.contains(soId);
    }


    // Update Ends
}
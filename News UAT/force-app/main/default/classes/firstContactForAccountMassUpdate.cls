/*
 * Author: Bohao Chen
 * Description: this is batch class to update first contact for accounts. This is one-off batch and can be deleted later. JIRA SFE-381
 * Date: 31/03/2014
 */
global class firstContactForAccountMassUpdate implements Database.Batchable<sObject>
{
	/*
	 * this is query that pass into this batch
	 String query = 'Select (Select Id From Contacts) From Account a';
	*/
	
	global String query;
	
    global firstContactForAccountMassUpdate(String q)
    {
    	this.query = q;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
    	return Database.getQueryLocator(this.query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accts)
    {
    	FirstContactUpdate_Helper.processContacts(accts);
    }
    
    global void finish(Database.BatchableContext BC)
    {
    	
    }
}
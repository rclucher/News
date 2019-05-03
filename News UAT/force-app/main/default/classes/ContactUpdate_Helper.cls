/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: 
 * 1. This is helper class for trigger 'ContactManagement' and requirement R-0184: 
                Ability to track the employment history of a contact to understand 
                where they may have previuously worked.
 * 2. This is helper class for trigger 'ContactManagement' and requirement R-0284:
                Ability for agent to easily determine if customer is in an active Campaign. 
 * History:
 * 11/06/2013  Bohao Chen  Created
 * 01/07/2013  Bohao Chen  Updated
 ---------------------------------------------------------*/
public with sharing class ContactUpdate_Helper 
{
	/******** this method is for requirement R-0184 ********/
    // this is change code map which maps change code to actual full name of change type
	public static Map<String, Contact_Change_Code__c> contactChangeCodeMap 
	{ 
		get{ return contactChangeCodeMap = contactChangeCodeMap == null ? Contact_Change_Code__c.getAll() : contactChangeCodeMap; } 
	}
	
	/******** this method is for requirement R-0184 ********/
	// create new job histories
    public static void createJobHistoryRecords(Map<String, List<Contact>> contactMap)
    {
    	List<Job_History__c> newJobHistoryRecords = new List<Job_History__c>();
    	
    	for(String k : contactMap.keySet())
    	{
    		for(Contact c : contactMap.get(k))
    		{
    		  Job_History__c newJobHistory = new Job_History__c();
    		  newJobHistory.Account__c = c.AccountId;
    		  newJobHistory.Change_Type__c = ContactUpdate_Helper.contactChangeCodeMap.get(k).Type_Full_Name__c;
    		  newJobHistory.Contact__c = c.Id;
    		  newJobHistory.Contact_Status__c = c.Contact_Status__c;
    		  newJobHistory.Job_Title__c = c.Title;
    		  
    		  if(k == 'NA')
    		  {
    		      Datetime d = c.CreatedDate;
    		      newJobHistory.Date_of_Change__c = date.newinstance(d.year(), d.month(), d.day());
    		  }
    		  else
    		      newJobHistory.Date_of_Change__c = Date.today();
    		  
    		  newJobHistoryRecords.add(newJobHistory);
            }
    	}
    	
    	insert newJobHistoryRecords; 
    }
    
    /******** this method is for requirement R-0184 ********/
    // this is comparison function in order to make sure valid (not every contact update is 
    // going to have job history record)  contact updates get updated later
    public static String compareNewAndOldContacts(Contact newContact, Contact oldContact)
    {
    	String changeCode = '';
    	
    	if(newContact.AccountId != oldContact.AccountId) changeCode += 'A';
    	if(newContact.Title != oldContact.Title) changeCode += 'J';
    	if(newContact.Contact_Status__c != oldContact.Contact_Status__c) changeCode += 'S';
    	
    	if(newContact.Inactive_Date__c != oldContact.Inactive_Date__c) changeCode = '';
    	
        return changeCode;
    }
    
    /******** this method is for requirement R-0284 ********/
    public static void updateCampainAccount(Map<Id, Contact> accountChangedContactMapByContactId)
    {
    	List<CampaignMember> campaignMemberList = new List<CampaignMember>();
			    	           
		try
		{			
			for(CampaignMember cm : [Select c.ContactId, c.Account__c, c.Contact.AccountId
	                                   From CampaignMember c 
	                                   Where c.ContactId IN: accountChangedContactMapByContactId.keySet()
	                                   //And c.Campaign.IsActive = true
	                                   ])
			{
				cm.Account__c = accountChangedContactMapByContactId.get(cm.ContactId).AccountId;
				campaignMemberList.add(cm);
			}    	    
			
            if(campaignMemberList.size() > 0)  
            {     						    	           
                update campaignMemberList;
            }
		}
		catch(Exception e)
		{
		   system.debug('====error message===' + e.getMessage());	
		}
    }



    public static  void findAndUpdateFirstContactForAccount(set<id> accountIds, list<Contact> contacts)
    {
        system.debug('@ findAndUpdateFirstContactForAccount(...)');
        system.debug('@ findAndUpdateFirstContactForAccount(...) accountIds: ' + accountIds);
        system.debug('@ findAndUpdateFirstContactForAccount(...) contacts: ' + contacts);
        
        set<id> contactToBemarkedAsFirstContact = new set<id>();
        list<Contact> firstContacts = new list<Contact>();
        for(Account a : [Select id, name, (Select id from Contacts where id NOT IN :contacts ORDER BY createddate Limit 1) from account where id in :accountIds])
        {
            for(contact c : a.contacts)
            {
                contactToBemarkedAsFirstContact.add(c.Id);
            }
        }  

        for(Contact c : [Select id, First_Contact_in_Account__c From Contact Where id in :contactToBemarkedAsFirstContact])
        {
            c.First_Contact_in_Account__c = true;
            firstContacts.add(c);
        }

        system.debug('@ findAndUpdateFirstContactForAccount(...) firstContacts: ' + firstContacts);
        if(firstContacts.size()>0)
        {
            update firstContacts;
        }
    }


    public static  map<id, Integer> numberOfContactsPerAccount(set<id> accountIds)
    {
        system.debug('@ numberOfContactsPerAccount(...)');
        system.debug('@ numberOfContactsPerAccount(...) accountIds: ' + accountIds);
        map<id, Integer> m = new map<id, Integer>();
        for(AggregateResult ar : [Select count(id) counter, accountId From contact Where accountId in :accountIds Group By accountId])
        {
            m.put((id) ar.get('accountId'), (integer) ar.get('Counter'));
        } 
        system.debug('@ numberOfContactsPerAccount(...) m: ' + m);
        return m;
    }

    /************ AdPoint **********/
    // the following code will send outbound message to webmethods to create digital contacts
    public static void updateContactsDigitalStatusForAccounts(List<Account> accounts)
    {
        if(accounts != null)
        {
            List<Contact> cons = [Select Digital_Status__c
                                  From Contact 
                                  Where Digital_Status__c = null
                                  and Contact_Status__c = 'Active'
                                  and AdPoint_Id__c = null
                                  and AccountId IN: accounts];
            
            for(Contact con : cons)
            {
                con.Digital_Status__c = 'Pending';
            }
            
            update cons;
        }
    }

    /************ End: AdPoint **********/

}
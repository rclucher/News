/*---------------------------------------------------------
* Author: Bohao Chen
* Company: Salesforce.com
* Description: 
1. This trigger is for requirement R-0184: 
Ability to track the employment history of a contact to understand 
where they may have previuously worked.
2. This trigger is also for requirement R-0284:
Ability for agent to easily determine if customer is in an active Campaign.
3. Added functionality to keep First Contact in Account R-1200
4. When deleting contacts, only certain user profiles can delete contacts
* History:
* 11/06/2013  Bohao Chen  Created
* 02/07/2013  Bohao Chen  Updated
* 10/10/2013  Celso de Souza updated
* 22/11/2013  Bohao Chen  Updated 
* 04/05/2015  Celso de Souza update
---------------------------------------------------------*/

trigger ContactManagement on Contact (before insert, before update, after update, after delete, before delete)
{
    if (Global_Helper.canTrigger( 'ContactManagement' ) ){
        if(trigger.isBefore && trigger.isInsert)
        {
            system.debug('@ ContactManagement trigger.isBefore && trigger.isInsert');
            //Set of account id's
            set<Id> accountIdSet = new set<Id>();
            //Current number of contacts per accountId
            map<id, Integer> numberOfContactsByAccountId = new map<id, Integer>();
            
            for(contact c : trigger.new)
            {
                if(c.AccountId!=null)
                    accountIdSet.add(c.AccountId);
                
            } 
            
            //If it's the first contact for the account, it will not be added to the map
            numberOfContactsByAccountId = ContactUpdate_Helper.numberOfContactsPerAccount(accountIdSet);
            
            for(contact c : trigger.new)
            {
                //if AccountId do not exist in the map, it's the first contact for the account.
                if(!numberOfContactsByAccountId.containsKey(c.AccountId))
                {
                    //Mark the contact as first contact
                    c.First_Contact_in_Account__c = true;
                    //Add to the map to keep only one contact per account marked as first contact, 
                    //in case of multiple contacts being uploaded at the same time for intsnce
                    numberOfContactsByAccountId.put(c.AccountId,1);
                }
                
            }         
            
        }
        
        if(trigger.isBefore && trigger.isUpdate)
        {
            system.debug('@ ContactManagement trigger.isBefore && trigger.isUpdate');
            list<Contact> contactMovingAccountList = new list<Contact>();
            list<Contact> firstContactMovingAccountList = new list<Contact>();
            set<Id> accountIdFromSet = new set<Id>();
            set<Id> accountIdToSet = new set<Id>();
            
            for(contact c : trigger.new)
            {
                
                if(c.AccountId != trigger.oldMap.get(c.id).AccountId)
                {
                    
                    accountIdToSet.add(c.accountId); 
                    contactMovingAccountList.add(c);
                    
                    system.debug('@ ContactManagement trigger.isBefore && trigger.isUpdate c.id:' + c.id);   
                    system.debug('@ ContactManagement trigger.isBefore && trigger.isUpdate c.AccountId:' + c.AccountId);   
                    system.debug('@ ContactManagement trigger.isBefore && trigger.isUpdate c.First_Contact_in_Account__c:' + c.First_Contact_in_Account__c);         
                    //ND 21/7/17 AdSales327 - Added to c.MasterRecordId == null to skip the logic during merging process,
					// as merge itself will be performing similar logic of copying First_Contact_in_Account__c from contact being deleted to the winning record
					if(c.First_Contact_in_Account__c && c.MasterRecordId == null)
                    {
                        accountIdFromSet.add(trigger.oldMap.get(c.id).AccountId);   
                        firstContactMovingAccountList.add(c);
                    }
                    
                }
            }
            
            system.debug('@ ContactManagement trigger.isBefore && trigger.isUpdate firstContactMovingAccountList:' + firstContactMovingAccountList);
            
            if(firstContactMovingAccountList.size()>0)
            {
                ContactUpdate_Helper.findAndUpdateFirstContactForAccount(accountIdFromSet, trigger.new);
            }
            
            map<id, Integer> numberOfContactsByAccountId = new map<id, Integer>();
            //If it's the first contact for the account, it will not be added to the map
            numberOfContactsByAccountId = ContactUpdate_Helper.numberOfContactsPerAccount(accountIdToSet);
            
            for(Contact c : contactMovingAccountList)
            {
                system.debug('@ ContactManagement trigger.isBefore && trigger.isUpdate numberOfContactsByAccountId.containsKey(c.AccountId):' + numberOfContactsByAccountId.containsKey(c.AccountId));
                //if AccountId do exists in the map, it is NOT the first contact for the account.
                c.First_Contact_in_Account__c = !numberOfContactsByAccountId.containsKey(c.AccountId);
            }
        }
        
        
        if(trigger.isAfter && trigger.isDelete)
        {
            system.debug('@ ContactManagement trigger.isAfter && trigger.isDelete');
            list<Contact> firstContactDeletedAccountList = new list<Contact>();
            set<Id> accountIdFromSet = new set<Id>();
            set<Id> accountIdToSet = new set<Id>();
            
            for(contact c : trigger.old)
            {
                system.debug('@ ContactManagement trigger.isBefore && trigger.isUpdate c.id:' + c.id);   
                system.debug('@ ContactManagement trigger.isBefore && trigger.isUpdate c.AccountId:' + c.AccountId);   
                system.debug('@ ContactManagement trigger.isBefore && trigger.isUpdate c.First_Contact_in_Account__c:' + c.First_Contact_in_Account__c);         
                if(c.First_Contact_in_Account__c)
                {
                    accountIdFromSet.add(trigger.oldMap.get(c.id).AccountId);
                    firstContactDeletedAccountList.add(c);
                }                
            } 
            
            system.debug('@ ContactManagement trigger.isBefore && trigger.isUpdate firstContactDeletedAccountList:' + firstContactDeletedAccountList);
            if(firstContactDeletedAccountList.size()>0)
            {
                ContactUpdate_Helper.findAndUpdateFirstContactForAccount(accountIdFromSet, firstContactDeletedAccountList);
            } 
        }
        
        
        if(trigger.isAfter && trigger.isUpdate)
        {
            system.debug('@ ContactManagement trigger.isAfter && trigger.isUpdate');
            // this is change code map which maps change code to actual full name of change type
            Map<String, List<Contact>> contactChangeMap = new  Map<String, List<Contact>>();
            for(String k : Contact_Change_Code__c.getAll().keySet())
            {
                contactChangeMap.put(k, new List<Contact>());
            } 
            
            Map<String, Integer> numOfJobHistoryByContactId = new Map<String, Integer>();      
            
            
            //List<Contact> accountChangedContactList = new List<Contact>(); //requirement R-0284
            Map<Id, Contact> accountChangedContactMapByContactId = new Map<Id, Contact>(); //requirement R-0284
            
            // Because we have to insert both new and old contacts when contact record gets updated in the first time,
            // we need to check how many job histories for each contact so we know if job history has been created 
            // for this contact already
            for(Contact c : [Select c.Id, (Select Id From Job_Histories__r) From Contact c Where c.Id IN: trigger.new])
            {
                numOfJobHistoryByContactId.put(c.Id, c.Job_Histories__r.size());
            }
            
            // firstly, create map for new job histories for updated contact records
            // for first time updated contact, we create two job histories
            // for the rest, we create one job history for each updated contact
            for(Contact c : trigger.new)
            {
                //requirement R-0184
                String changeCode = ContactUpdate_Helper.compareNewAndOldContacts(trigger.newMap.get(c.Id), trigger.oldMap.get(c.Id));
                
                if(String.isNotBlank(changeCode))
                {
                    // add contact to change map according to change code
                    contactChangeMap.get(changeCode).add(c);
                    
                    // create the first job history record if there is zero job history for this contact
                    if(numOfJobHistoryByContactId.get(c.Id) == 0)
                    {
                        contactChangeMap.get('NA').add(trigger.oldMap.get(c.Id));
                    } 
                }
                
                //requirement R-0284
                if(trigger.newMap.get(c.Id).AccountId != trigger.oldMap.get(c.Id).AccountId)
                {
                    accountChangedContactMapByContactId.put(c.Id, c);
                }
            }
            
            ContactUpdate_Helper.createJobHistoryRecords(contactChangeMap); //requirement R-0184
            
            /****** the following line has been comment out due to business requirement that to avoid people changing their company *****/
            //ContactUpdate_Helper.updateCampainAccount(accountChangedContactMapByContactId); //requirement R-0284
        }
        
        //When deleting contacts, only certain user profiles can delete contacts
        if(trigger.isAfter && trigger.isDelete) //CdS@04/05/2015 changed from isBefore to IsAfter
        {
            set<String> profileWithContactDeletePermission = new Set<String>();
            profileWithContactDeletePermission.add('System Administrator');
            profileWithContactDeletePermission.add('News System Administrator');
            profileWithContactDeletePermission.add('News IT Administration');
            profileWithContactDeletePermission.add('News Integration');
            
            String profileName = [Select p.Name From Profile p Where p.Id =: userInfo.getProfileId() limit 1].Name;
            for(Contact c : trigger.old)
            {
                
                if(!profileWithContactDeletePermission.contains(profileName) &&
                  	c.MasterRecordId == null) //added check on MaterRecordId as any user should be able to merge contacts
                {
                    c.addError('your profile doesn\'t have delete permission');
                }
            }
        }
    }
}
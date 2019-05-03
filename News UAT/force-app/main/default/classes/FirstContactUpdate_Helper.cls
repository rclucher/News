public with sharing class FirstContactUpdate_Helper 
{
    public static void sendErrorResults(Database.SaveResult[] srList, 
                                        List<Contact> updateContactList)
    {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        
        // Iterate through each returned result
        Integer i = 0;
        for (Database.SaveResult sr : srList) 
        {
            if (!sr.isSuccess()) 
            {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{'bohao.chen@bluewolf.com'});
                mail.setSubject('Fails when trying to update first contact ');
                
                String emailBody = '';
                
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) 
                {
                    emailBody = i + '. error code: ' + err.getStatusCode() + ', error message: ' + err.getMessage();
                }
                
                if(updateContactList.size() > 0 &&  updateContactList[i].Id != null)
                {
                    Contact contactRec = updateContactList[i];
                    emailBody += ' Contact Id is: ' + contactRec.Id;
                    emailBody += ' Parent Account Id is: ' + contactRec.AccountId;
                }
                
                mail.setPlainTextBody(emailBody);
                mails.add(mail);
            }
            
            i++;
        }
        
        if(mails.size() > 0)
            Messaging.sendEmail(mails);
    }
    
    public static void processContacts(List<Account> accts)
    {
    	List<Contact> contacts = new List<Contact>();
        
        Map<String, List<Contact>> contactsByAccountId = new Map<String, List<Contact>>();
        
        for(Contact c : [Select AccountId, Id, First_Contact_in_Account__c From Contact Where AccountId IN: accts])
        {
            if(!contactsByAccountId.containsKey(c.AccountId))
            {
                contactsByAccountId.put(c.AccountId, new List<Contact>());
            }
            
            contactsByAccountId.get(c.accountId).add(c);
        }
        
        for (String acctId : contactsByAccountId.keySet())
        {
            Integer numOfContacts = contactsByAccountId.get(acctId).size();
            Boolean hasFirstContact = false;

            system.debug('@firstContactForAccountMassUpdate execute acctId: ' + acctId);
            
            Integer index = 1;
            
            for(Contact c : contactsByAccountId.get(acctId))
            {
                if(c.First_Contact_in_Account__c)
                {
                    if(hasFirstContact)
                    {
                        c.First_Contact_in_Account__c = false;
                        contacts.add(c);
                    }
                    else
                    {
                        hasFirstContact = true;
                    }
                }
                
                if(index == numOfContacts && !hasFirstContact)
                {
                    c.First_Contact_in_Account__c = true;
                    contacts.add(c);
                }
                
                index++;
            }
        }
        
        system.debug('@firstContactForAccountMassUpdate execute contacts: ' + contacts);
        
        List<Database.SaveResult> srList = Database.update(contacts, false);
        
        FirstContactUpdate_Helper.sendErrorResults(srList, contacts);
    }
}
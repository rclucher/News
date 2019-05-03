/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: 
 *  1. This is the helper class for CaseManagement Trigger to update case owner based on 'supplied to email'
 * History:
 * 09/09/2013  Bohao Chen   Created
 * 18/02/2014  Louis Wang   Updated - created a new method getEmailList
 ---------------------------------------------------------*/
public class Case_Helper{
    
    // this method will find queues/groups and users with same emails based on 'supplied to'
    public static Map<String, List<Id>> getGroupsUsersMapByEmail(List<String> emails)
    {    
        Map<String, List<Id>> groupsUsersMapByEmail = new Map<String, List<Id>>();
        
        // find group/queues by emails
        for(Group g : [Select g.Email, g.Id From Group g 
                        Where g.Email IN: emails And g.Type = 'Queue'])
        {
            if(!groupsUsersMapByEmail.containsKey(g.Email))
            {
                groupsUsersMapByEmail.put(g.Email, new List<Id>());
            }
           
            groupsUsersMapByEmail.get(g.Email).add(g.Id);
        }
        
        // find users by emails
        for(User u : [Select u.Id, u.Email From User u  Where u.Email IN: emails])
        {
            if(!groupsUsersMapByEmail.containsKey(u.Email))
            {
                groupsUsersMapByEmail.put(u.Email, new List<Id>());
            }
           
            groupsUsersMapByEmail.get(u.Email).add(u.Id);
        }
        
        return groupsUsersMapByEmail;
    }

    public static Id getFieldSalesOutlookQueueId()
    {
    	return [Select g.Id From Group g Where g.Name = 'Field Sales Outlook' limit 1].Id;
    }
    
    // this method will return a list of email addresses based on a string
    public static List<string> getEmailList(string emailString)
    {
    	system.debug(logginglevel.error, '@Case_Helper getEmailList emailString1: ' + emailString);
    	
        List<String> staging = new List<String>();
        List<String> output = new List<String>();

        // replace all comma to semicolon
        if(emailString.contains(','))
        {                        
            emailString = emailString.replace(',',';');
        }
            
        /**** Updated by Bohao Chen on 24/03/2014 for JIRA issue SFE-308 ****/
		// this block of code has been rolled back due to the issue of ".dummy" at the end of 
		// queue email. Instead, this JIRA case has been address in Exchange server
        if(emailString.contains(';'))
        {
            // covert email addresses into list
            staging.addall(emailString.split(';'));
        }
        else 
        {
            staging.add(emailString);
        }
        
        /**** Updated By Bohao Chen *****/
         
        // need to clean out the white space and carriage return for each element in the list
        for(string e : staging)
        {
            output.add(e.trim());
        }     
        
        system.debug(logginglevel.error, '@CaseManagement getEmailList emailString2: ' + emailString);
                               
        return output;
    }
    
    /*** Updated By Bohao Chen on 10/03/2014 JIRA case: SFE-131***/
    public static String getIntegratorId()
    {
    	try
    	{
    		return [Select Id From User Where Name = 'Integrator' Limit 1].Id;
    	}
    	catch (Exception e)
    	{
    		List<String> toAddresses = new String[]{'bohao.chen@bluewolf.com'};
    		Global_Helper.sendMessageToUsers('getIntegratorId method issue in Case_Helper', e.getMessage(), toAddresses, 'text');
    		return null;
    	}
    }
    /*** Updated By Bohao Chen ***/
    
    /*** Updated By Bohao Chen on 8/04/2014 JIRA case: SFE-365***/
    // retrieve case origin based on queue email address
    public static Map<String, String> getCaseOriginByEmail(Set<String> emailSet)
    {
    	if(emailSet != null && emailSet.size() > 0)
    	{
    		Map<String, String> caseOriginsByEmail = new Map<String, String>();
    		
        	for(Email_Case_Origin_Mapping__c mapping : [Select Email__c, Case_Origin__c From Email_Case_Origin_Mapping__c Where Email__c IN: emailSet])
        	{
				caseOriginsByEmail.put(mapping.Email__c, mapping.Case_Origin__c);
        	}

        	return caseOriginsByEmail;
    	}
    	
    	return null;
    }
    
    // get emails map with group owner id as key
    public static Map<String, String> getQueueOwnerEmailsByOwnerIdMap(Set<String> queueOwnerIds)
    {
    	Map<String, String> queueOwnerEmailsByOwnerId = new Map<String, String>(); 
    	
    	for(Group gp : [Select g.Id, g.Email From Group g Where g.Id IN: queueOwnerIds])
    	{
    		queueOwnerEmailsByOwnerId.put(gp.Id, gp.Email);
    	}
    	
    	return queueOwnerEmailsByOwnerId;
    }
    /*** Updated By Bohao Chen ***/


            // Updated by Bohao Chen on 8/05/2014 for JIRA case ??? 
        // Issue that we fixed: When queue email in cc address field, case owner doesn't gets updated
    public static String concatenateToAndCcAddresses(String toAddress, String cCAddress)
    {
        String emailAddress = '';

        if(String.isNotBlank(toAddress))
        {
            emailAddress += toAddress;
        }

        if(String.isNotBlank(cCAddress))
        {
            if(emailAddress.length() > 0) emailAddress += ';';
            emailAddress += cCAddress; 
        }

        return emailAddress;
    }

    /**
    * @description SFE-688 Generate a map to get Primary by Alias
    * @param List<String>
    * @return Map<String, String>
    * @author louis.wang@bluewolf.com
    * @date 2015-11-16
    **/
    public static Map<String, String> generate_Primary_By_Alias_Map(List<String> inputList)
    {
        Map<String, String> output = new Map<String, String>();
        if(inputList!=null && !inputList.isEmpty())
        {
            List<Email_Case_Origin_Mapping__c> ecoList = [SELECT Id, Email_Alias__c, Email__c 
                                                            FROM Email_Case_Origin_Mapping__c
                                                            WHERE Email_Alias__c IN: inputList];
            for(Email_Case_Origin_Mapping__c eco : ecoList)
            {
                // in case there is duplicated data that causes Map to fail, so only use the 1st finding
                if(!output.containsKey(eco.Email_Alias__c))
                {                    
                    output.put(eco.Email_Alias__c, eco.Email__c);
                }
            }
        }
        return output;                                                            
    }

    /**
    * @description SFE-688 Replace Alias with Primary email address
    * @param String
    * @param Map<String, String>
    * @return String
    * @author louis.wang@bluewolf.com
    * @date 2015-11-16
    **/
    public static String replace_Alias_with_Primary(String inputString, Map<String,String> inputMap)
    {
        String output = '';
        if(inputString!=null && inputString!='' && inputMap!=null)
        {
            List<String> inputList = getEmailList(inputString);
            for(String s : inputList)
            {
                if(inputMap.containsKey(s))
                {
                    // if the Alias has a match, then use the Primary instead
                    output += inputMap.get(s) + ';';
                }
                else
                {
                    output += s + ';';
                }
            }
        }
        // remove the last character if it is ';'
        if(output.right(1)==';')
        {  
            output = output.mid(0, output.length()-1);
        }
        return output;
    }

    /**
    * @description  updates the related account credit status
    *               (after update)
    *
    * @author       Timothy Fabros
    * @date         2017-10-23
    **/
    //public static void updateCreditCheckedAccount(List<Case> newCases) {

    //    Id recordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Credit Check').getRecordTypeId();
    //    Set<String> closedStatuses = new Set<String>{'Approved', 'Declined'};

    //    List<Account> accountsToUpdate = new List<Account>();

    //    for (Case newCase : newCases) {

    //        if (newCase.RecordtypeId == recordtypeId && closedStatuses.contains(newCase.Status) && !newCase.Has_Credit_Checked__c) {

    //            Account account = new Account(
    //                Id = newCase.AccountId,
    //                Credit_Status__c = newCase.Status,
    //                Has_Credit_Checked__c = true
    //            );

    //            accountsToUpdate.add(account);
    //        }
    //    }

    //    update accountsToUpdate;
    //}
}
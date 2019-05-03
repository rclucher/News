/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This trigger is for 
 *  1. Requirement: R-0715
                1) Set Case Account look-up same as Opportunity__c lookup when creating or updating case (set to Account from the Opty) 
                2) Assign the Case to either the User or Queue based on when the SuppliedToEmail__c is set on Case (set via a X-object workflow from Email Message) 
                3) Trigger the Auto-Response rules
 *  2. R-0791: Ability for the account field to be defaulted when a case is created and the opportunity is populated on the case.
 *  3. R-0747: Trigger on Case when Booking lookup is updated to automatically update the Sales Order lookup on the same case with the Booking's parent Sales Order.
 *  4. R-1275
 *  5. R-1272
 * History:
 * 09/07/2013  Bohao Chen  Created
 * 09/09/2013  Bohao Chen  Updated
 * 20/11/2013  Bohao Chen  Updated
 * 22/11/2013  Bohao Chen  Updated 
 * 18/02/2014  Louis Wang  Updated - to address the issue if SuppliedTo contains multiple email addresses separated by comma or semicolon.
 * 25/02/2014  Bohao Chen  Updated 
 
 ---------------------------------------------------------*/
trigger CaseManagement on Case (after update, after insert, before insert, before update) 
{
    //Check if the CNN batch is executing
    CCNBatchJobSetting__c batchSetting = CCNBatchJobSetting__c.getInstance();
    
    if (Global_Helper.canTrigger( 'CaseManagement' ) && !batchSetting.Is_Case_Batch_Running__c)
    {
        // added by Tim Fabros 2017-10-23
        //if (trigger.isAfter) {
        //    if (trigger.isUpdate) {

        //        Case_Helper.updateCreditCheckedAccount(trigger.new);
        //    }
        //}

        if(trigger.isBefore && (trigger.isInsert || trigger.isUpdate))
        {
            List<Id> opportunityIds = new List<Id>(); 
            List<String> emails = new List<String>(); 
            
            List<Case> closedCases = new List<Case>();
            Map<Id, Boolean> hasOpenTasksByCaseId = new Map<Id, Boolean>();
            
            String fieldSaleOutlookQueueId = Case_Helper.getFieldSalesOutlookQueueId();
            
            /*** Updated By Bohao Chen on 10/03/2014 JIRA case: SFE-131***/
            String integratorId = Case_Helper.getIntegratorId();
            /*** Updated By Bohao Chen ***/
            
            for(Case c : trigger.new)
            {   
                // added by Tim Fabros 17 / 06 / 2014 - SFE-456
                // added a fix so that oldcase is populated only on update to prevent crash 
                // BEGIN:
                Case oldCase;
                if (trigger.isUpdate)
                    oldCase = trigger.oldMap.get(c.Id);

                // update case account to case opportunity account if opportunity is selected / populated
                if(String.isNotBlank(c.Opportunity__c))
                {
                    if (trigger.isInsert)
                        c.AccountId = c.Opportunity_Account__c;
                    else if (trigger.isUpdate && oldCase != null && oldCase.Opportunity__c != c.Opportunity__c)
                        c.AccountId = c.Opportunity_Account__c;
                }
                // END:
                
                //If Booking is selected
                if (String.isNotBlank(c.Booking__c)) 
                {
                    //Then modify Sales Order
                    c.Sales_Order__c = c.Booking_Sales_Order__c;
                }
                
                system.debug(logginglevel.error, '@CaseManagement c.SuppliedTo__c: ' + c.SuppliedTo__c);
                
                /*** Updated By Bohao Chen on 10/03/2014 JIRA case: SFE-131***/
                system.debug('@CaseManagement c.has_Inbound_Email__c: ' + c.has_Inbound_Email__c);
                
                // Only integrator will trigger case queue owner update based on suppliedToEmail value 
                if(trigger.isUpdate && (String.isNotBlank(c.SuppliedTo__c) || String.isNotBlank(c.CC_Recipients__c))
                    && (UserInfo.getUserId() == integratorId || Test.isRunningTest())
                    && c.has_Inbound_Email__c)
                /*** Updated By Bohao Chen ***/
                {
                	system.debug('@new supplied to: ' + trigger.newMap.get(c.Id).SuppliedTo__c);
                	system.debug('@old supplied to: ' + trigger.oldMap.get(c.Id).SuppliedTo__c);
                	
                    String suppliedTo = Case_Helper.concatenateToAndCcAddresses(String.valueOf(c.SuppliedTo__c), String.valueOf(c.CC_Recipients__c));

                    system.debug('@suppliedTo: ' + suppliedTo);

                    // if 'supplied to' is not blank, need to assign case to user/queue based on their email
                    // suppliedTo could contain carriage return, white space, comma and semicolon. They are now handled through helper class.
                    emails.addall(Case_Helper.getEmailList(suppliedTo));  
                    
                    /**** Updated by Bohao Chen on 25/03/2014 for JIRA issue SFE-308 ****/
                    c.has_Inbound_Email__c = false;
                    /**** Updated By Bohao Chen *****/                  
                }
                
                system.debug(logginglevel.error, '@CaseManagement emails: ' + emails);
                
                /*** Updated By Bohao Chen on 8/04/2014 JIRA case: SFE-365 ***
                 * The following block has been commented out due to design flaw. See JIRA case SFE-365
                 **/
                // R-1275 - need to copy case origin to case origin copy field
                // so when custom replies, we know if case origin was 'inbound for routing' before
                /*if(trigger.isBefore && trigger.isInsert)
                {
                    c.Case_Origin_Copy__c = c.Origin;
                }*/
                /**** Updated By Bohao Chen *****/                  
            }
            
            system.debug('@number of emails: ' + emails.size());
            
            if(emails.size() > 0)
            {
                Map<String, List<Id>> groupsUsersMapByEmail = Case_Helper.getGroupsUsersMapByEmail(emails);
                
                system.debug(logginglevel.error, '@CaseManagement groupsUsersMapByEmail: ' + groupsUsersMapByEmail);

                /*** Updated By Bohao Chen on 8/04/2014 JIRA case: SFE-365 ***/
                Set<String> queueOwnerIds = new Set<String>();
                /*** Updated By Bohao Chen ***/
                            
                for(Case c : trigger.new)
                {
    	            // loop through trigger records, find users/queues according to 'supplied to email', 
                	// then assign the very first user/queue to case
                	if(String.isNotBlank(c.SuppliedTo__c) || String.isNotBlank(c.CC_Recipients__c))
                	{
    	                list<string> suppliedToEmails = new list<string>();


    	                String suppliedTo = Case_Helper.concatenateToAndCcAddresses(String.valueOf(c.SuppliedTo__c), String.valueOf(c.CC_Recipients__c));

    	                // suppliedToEmails could contain carriage return, white space, comma and semicolon. 
    	                //They are now handled through helper class.
    	                suppliedToEmails.addall(Case_Helper.getEmailList(suppliedTo));                    
    	
    	                system.debug('@CaseManagement suppliedToEmails: ' + suppliedToEmails);
    	
    	                // loop through each email address, and as soon as a result is returned, exit and assign it as OwnerId                                
    	                for(string emailString : suppliedToEmails)
    	                {
    	                    if(groupsUsersMapByEmail.containsKey(emailString))
    	                    {
    	                    	String ownerId = groupsUsersMapByEmail.get(emailString)[0];
    							String ownerIdPrefix = ownerId.substring(0, 3);
    								                    	
    	                    	// if this is field sales outlook, it means that it is from SFDC to outlook.
    	                    	// Therefore, we need to update case owner according to first USER email.
    	                    	// else, we need to update case owner according to first QUEUE(GROUP) email.
                	            if(c.OwnerId == fieldSaleOutlookQueueId)
                	            {
                	            	// only assign to outlook to SFDC user when suppliedToEmails has only 1 email address
                	            	/*** Updated By Bohao Chen on 03/03/2014 JIRA case: SFE-117***/
                	            	if(suppliedToEmails.size() == 1 && ownerIdPrefix == '005') 
                	            	/*** Updated By Bohao Chen ***/
    				            	{
    				            		c.OwnerId = ownerId;
    				            		break;
    				            	}
                	            }
    	                    	else
    	                    	{
    	                    		if(ownerIdPrefix == '00G') // if owner id is queue (group) id
    	                    		{
    	                    			c.OwnerId = ownerId;
    	                    			
                                        /*** Updated By Bohao Chen on 8/04/2014 JIRA case: SFE-365 ***/
    	                                // generate queue owner id set in order to get case origin based on queue
                                        queueOwnerIds.add(c.OwnerId);
    	                                /*** Updated By Bohao Chen ***/
    	                    			
    	                    			break;
    	                    		}
    	                    	}
    	                    }
    	                }
    	                
    	                system.debug(logginglevel.error, '@CaseManagement ownerId: ' + c.OwnerId);
                	}
                }
                                        
                /*** Updated By Bohao Chen on 8/04/2014 JIRA case: SFE-365***/
                // Custom setting table "Email_Case_Origin_Mapping__c" has been established to keep mapping between queue emails and its case origin.
                // Because there is no way we can query case orgin from email-to-case setting metadata. 
                Map<String, String> queueOwnerEmailsByOwnerId = Case_Helper.getQueueOwnerEmailsByOwnerIdMap(queueOwnerIds);
                Set<String> emailSet = new Set<String>();
                
                system.debug('@CaseManagement queueOwnerEmailsByOwnerId: ' + queueOwnerEmailsByOwnerId);
                
                for(Case c : trigger.new)
                {
                	system.debug('@CaseManagement owner id is: ' + c.OwnerId);
                	
                    String ownerIdPrefix = String.valueOf(c.ownerId).substring(0, 3);
                    
                    if(ownerIdPrefix == '00G' && queueOwnerEmailsByOwnerId.containsKey(c.OwnerId)) // if owner id is queue (group) id
                    {
                    	String queueEmail = queueOwnerEmailsByOwnerId.get(c.OwnerId);
                    	emailSet.add(queueEmail);
                    }
                }
                
            	system.debug('@CaseManagement emailSet: ' + emailSet);
                    
                Map<String, String> caseOriginsByEmail = Case_Helper.getCaseOriginByEmail(emailSet);
                           
                for(Case c : trigger.new)
                {
                    String ownerIdPrefix = String.valueOf(c.ownerId).substring(0, 3);
                    
                    if(ownerIdPrefix == '00G' && queueOwnerEmailsByOwnerId.containsKey(c.OwnerId)) // if owner id is queue (group) id
                    {
                    	String queueEmail = queueOwnerEmailsByOwnerId.get(c.OwnerId);
                    	
                    	if(caseOriginsByEmail.containsKey(queueEmail))
                    	{
    	                    c.Origin =  caseOriginsByEmail.get(queueEmail);
    	            		system.debug('@CaseManagement c.Origin: ' + c.Origin);
                    	}
                    }
                }
            }
                /*** Updated By Bohao Chen ***/
                                
        }
    }
}
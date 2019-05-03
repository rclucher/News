/**
* @company      (already in Production)
* @author       (already in Production)
* @description  This class contains methods that are used for CampaignActionPage pages (console) <p>
* @changelog    2015-02-18 louis.wang@bluewolf.com UserStory16.2
*                   - Added lists to the page
*                       - CaseList
*                       - ExpiredBookingList
*                       - ActivityHistoryList
*                       - OpenActivityList
*               2015-05-14 louis.wang@bluewolf.com
*                   - Updated logic to reflect picklist value changes for Response_Type__c and Response_Subtype__c
*               2015-08-20 louis.wang@bluewolf.com SFE-661
*                   - fetch the correct number of calls made before and after DML
*               2016-01-05  darshan.gosar@bluewolfgroup.com SFE-766
*                   - code refactoring
*/
public with sharing class CampaignActionPage_ControllerXDS {
    
    
    public Campaign_Response__c newResponse {get;set;}
    public Campaign_Response__c previousResponse {get;private set;}
    public list<Campaign_Response__c> campaignResponseHistory {get;private set;}
    public CampaignMember member {get; set;}
    
    public string refTabId {get;set;}
    public boolean doNotProceed {get;private set;}

    // added by Tim Fabros 26 / 08 / 2014 - SFE-273
    // added a boolean to check if in an error state.
    // BEGIN: 
    public boolean hasError {get;private set;} 
    // END:
    
    public list<Case> caseHistoryList {get; private set;}
    public list<OpenActivity> openActivityList {get; private set;}
    public list<ActivityHistory> activityHistoryList {get; private set;}
    public list<Booking__c> expiredBookingList {get; private set;}
    public list<Booking__c> bookingList {get; private set;}
    private static final integer QUERY_LIMIT = 5;
    public string leadOrContact {get; private set;}
    public list<CampaignMember> cmList {get; private set;}
    public list<Campaign_Response__c> contactPlanList {get; private set;}

    public String opportunityContactFieldId{get{return SystemParameters__c.getAll().get('Opportunity.Contact__c').value__c;} private set;}
    
    public CampaignActionPage_ControllerXDS(ApexPages.StandardController controller) {    
        // SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
            // Added FieldList in set of string & only adding it to controller list inside non test context change is done to increase code coverage 
        List<String> fieldList = new List<String>{'Execution_Status__c', 
                'Campaign.Max_Call_Attempts__c',
                'CampaignId',
                'Campaign.Name',
                'ContactId',
                'Contact.Name',
                'Contact.AccountId',
                'Contact.Account.Name',
                'Contact.Account.Phone',
                'Contact.HomePhone',
                'Contact.MobilePhone',
                'Contact.OtherPhone',
                'Contact.LeadSource',
                'Age_in_list__c',
                'Description__c',
                'LeadId',
                'Lead.Name',
                'Account__c',
                'Account__r.Phone',
                'Status',
                'Locked_By__c',
                'Call_Count__c',
                'DNC_Summary__c',
                'Call_Back_Date__c',
                'Campaign.publication_division__c',
                'Campaign.Type',
                'Campaign.NEWS_Campaign_Type__c',
                'Completed_by__c',
                'CreatedDate',
                'Campaign_Membership_Count__c'};      

        if(!test.isRunningTest())
        {
            controller.addFields(fieldList); 
        }      
        
        // added by Tim Fabros 26 / 08 / 2014 - SFE-273
        // initialise error boolean.
        // BEGIN:
        hasError = false;
        // END:
        member = (CampaignMember) controller.getRecord();
        newResponse = new Campaign_Response__c();
        newResponse.Call_Attempt__c = 0;
        doNotProceed = false;
        
        if(member.Execution_Status__c=='Completed')
        {
            doNotProceed = true;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO,'The selected Campaign Member has its Execution Status as Completed and cannot have new responses created.<br />Please select cancel.'));
            return;
        }

        leadOrContact = CampaignActionPage_Helper.update_LeadOrContact(member.ContactId);                        
        if(leadOrContact=='contact')
        {
            caseHistoryList = CampaignActionPage_Helper.fetch_CaseHistoryList(member.ContactId, QUERY_LIMIT);
            expiredBookingList = CampaignActionPage_Helper.fetch_ExpiredBookingList(member.campaign.publication_division__c, member.ContactId, QUERY_LIMIT, 'expired');
        }
        fetchActivities(leadOrContact, member.ContactId, member.LeadId, QUERY_LIMIT);
        cmList = CampaignActionPage_Helper.fetch_CampaignMembershipList(leadOrContact, member.ContactId, member.LeadId, QUERY_LIMIT); 
        contactPlanList = CampaignActionPage_Helper.fetch_ContactPlanList(member.contactId, QUERY_LIMIT);
        bookingList = CampaignActionPage_Helper.fetch_BookingList(member.campaign.publication_division__c, member.ContactId, QUERY_LIMIT, 'active');
    } 

    private void fetchActivities(String leadOrContact, Id contactId, Id leadId, Integer queryLimit)
    {
        // 2015-02-18 louis.wang@bluewolf.com UserStory16.2
        //  - list activities of the Lead or Contact
        //      - if it is Person Account, then list activities of the Account
        //  - this function updates public variables - activityHistoryList and openActivityList
        activityHistoryList = new list<ActivityHistory>();
        openActivityList = new list<OpenActivity>();
        try
        {
            if(leadOrContact=='contact')
            {
                Contact theContact = new Contact();
                string soqlString = CampaignActionPage_Helper.generateSoql_Activities('contact', queryLimit, contactId);
                theContact = Database.query(soqlString);
                activityHistoryList = theContact.ActivityHistories;
                openActivityList = theContact.OpenActivities;

                if(theContact.IsPersonAccount)
                {
                    Account thePAccount = new Account();
                    string soqlString_PA = CampaignActionPage_Helper.generateSoql_Activities('account', queryLimit, theContact.AccountId);
                    thePAccount = Database.query(soqlString_PA);
                    activityHistoryList = thePAccount.ActivityHistories;
                    openActivityList = thePAccount.OpenActivities;
                }
            }
            else
            {
                Lead theLead = new Lead();
                string soqlString_Lead = CampaignActionPage_Helper.generateSoql_Activities('lead', queryLimit, leadId);
                theLead = Database.query(soqlString_Lead);
                activityHistoryList = theLead.ActivityHistories;
                openActivityList = theLead.OpenActivities;
            }
        }
        catch(Exception ex)
        {
            // does not need to handle the error, as it is not driven by user input
            System.debug('@@Exception fetchActivities: ' + ex.getMessage());
        }
    }
    
    private void setResponseFields()
    {
        system.debug('@ setResponseFields()');
        system.debug('@ setResponseFields() newResponse.Response_Type__c:' + newResponse.Response_Type__c);
        system.debug('@ setResponseFields() newResponse.Response_Subtype__c:' + newResponse.Response_Subtype__c);
        system.debug('@ setResponseFields() newResponse.Call_Attempt__c:' + newResponse.Call_Attempt__c);
        system.debug('@ setResponseFields() member.Campaign.Max_Call_Attempts__c:' + member.Campaign.Max_Call_Attempts__c);
        
        member.In_Progress__c = false;

        if(newResponse.Campaign__c == null)
        {
            newResponse.Campaign__c = member.CampaignId;
            // 2015-08-18 SFE-654 louis.wang@bluewolf.com - Update denormalised Campaign_Name at the time linking to Campaign record
            //                      This aims to overcome intermittent Campaign_Name not updated issue
            newResponse.Campaign_Name__c = member.Campaign.Name;
        }
        newResponse.Contact__c = member.ContactId;
        
        if(member.ContactId == null && member.LeadId != null)
            newResponse.Lead__c = member.LeadId;
        
        newResponse.Campaign_Member_Id__c = member.id;
        
        // SFE-661 2015-08-20 louis.wang@bluewolf.com - CallCount is now managed through directly fetching DB
        //member.Call_Count__c = newResponse.Call_Attempt__c;
        member.Response_Type__c = newresponse.Response_Type__c;
        member.Response_Sub_Type__c = newresponse.Response_SubType__c;
        member.Response_Comment__c = newresponse.Response_Comment__c;
        member.Response_Datetime__c = System.now();
        
        system.debug('@ setResponseFields() newResponse.Call_Attempt__c:' + newResponse.Call_Attempt__c);

        // 2015-05-14 louis.wang@bluewolf.com
        //      Updated logic to reflect picklist value changes for Response_Type__c and Response_Subtype__c
        if(newResponse.Response_Type__c=='Yes'
            || newResponse.Response_Type__c=='No'
            || newResponse.Response_Type__c=='No Sales Call')
        {
            executionCompleted();
        }
        else if(newResponse.Response_Type__c=='Follow Up')
        {
            if(newResponse.Response_Subtype__c=='Decision Maker Unavailable')
            {
                executionAttempted();
            }
            else if(newResponse.Response_Subtype__c=='Request Call Back - Same Agent')
            {
                executionCalltoDo_KeepLock();
            }
            else
            {
                executionCalltoDo_ReleaseLock();
            }
        }        

        if(member.Execution_Status__c != 'Completed')
        {        
            if(newResponse.Call_Back_Date__c!=null)
            {
                member.Call_Back_Date__c = newResponse.Call_Back_Date__c;
            }
            else
            {
                member.Call_Back_Date__c = null;
            }
            
            if (newResponse.Call_Attempt__c > member.Campaign.Max_Call_Attempts__c)
            {
                newResponse.Call_Limit_Reached__c = true;
                
                if(newResponse.Response_Type__c != 'Yes' &&
                   newResponse.Response_Type__c != 'No')
                {
                    member.Execution_Status__c = 'Call Limit Reached';
                    member.Locked_By__c = null;
                }
            }
        }
        
    }

    private void executionCompleted()
    {
        member.Execution_Status__c = 'Completed';
        newResponse.Membership_Final_Response__c = true;
        member.Date_Completed__c = system.today();
        member.Completed_by__c = UserInfo.getuserId();
        member.Locked_By__c = null;        
    }
    
    private void executionAttempted()
    {
        member.Execution_Status__c = 'Attempted';
        member.Locked_By__c = null;        
    }

    private void executionCalltoDo_KeepLock()
    {
        member.Execution_Status__c = 'Call to Do';
    }

    private void executionCalltoDo_ReleaseLock()
    {
        executionCalltoDo_KeepLock();
        member.Locked_By__c = null;
    }

    private void refresh_Member_CallCount()
    {
        // SFE-661 2015-08-20 louis.wang@bluewolf.com - fetch the correct number of calls made
        member.Call_Count__c = CampaignActionPage_Helper.fetch_CampaignResponseHistoryForMember(member.CampaignId, member.ContactId, member.LeadId, member.Id).size();   
    }

    public PageReference doSave()
    {        
        system.debug('@ doSave()');
        system.debug('@ doSave() newResponse.Lead__c:' + newResponse.Lead__c);
        system.debug('@ doSave() newResponse.Contact__c:' + newResponse.Contact__c);
        system.debug('@ doSave() member.LeadId:' + member.LeadId);
        system.debug('@ doSave() member.ContactId:' + member.ContactId);
        system.debug('@ doSave() member.CampaignId:' + member.CampaignId);
        
        // added by Tim Fabros 26 / 08 / 2014 - SFE-273
        // added a boolean to check if in an error state.
        // BEGIN:
        hasError = false;
        // END:

        newResponse.Call_Attempt__c  = CampaignActionPage_Helper.fetch_CampaignResponseHistoryForMember(member.CampaignId, member.ContactId, member.LeadId, member.Id).size()+1;
        
        //Check if the lead has been converted since the current action page (member response) was opened
        if(member.LeadId!=null && member.contactId==null)
        {
            //check if lead has been converted
            system.debug('@ doSave() check if lead has been converted');
            Lead l = [Select l.IsConverted From Lead l where id =:member.LeadId];
            system.debug('@ doSave() l.IsConverted:' + l.IsConverted);
            if(l.IsConverted)
            {
                system.debug('@ doSave() Error: converted lead' );
                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'This Lead has been converted to a Contact.<br />Please close this Response (not Cancel to maintain Lock) and reopen from the List.'));
                return null;
            } 
        }

        // added by Tim Fabros 21 / 08 / 2014 - SFE-606
        // revised solution from previous change
        // adds campaign member creation date to response.
        // BEGIN:
        CampaignMember campaignMember = [SELECT CreatedDate FROM CampaignMember WHERE Id =: member.Id LIMIT 1];
        newResponse.Campaign_Member_First_Associated_Date__c = campaignMember.CreatedDate;
        // END:
        
        PageReference pr = null;
        setResponseFields();
        
        system.debug('@ doSave() newResponse:' + newResponse);
        system.debug('@ doSave() member:' + member);
         
        // Updated by Bohao Chen on 22/Aug/2014 for JIRA SFE-273
        // BEGIN
        Savepoint sp = Database.setSavepoint();
        // END

        try
        {
            insert newResponse;
            // SFE-661 2015-08-20 louis.wang@bluewolf.com - fetch from DB to update
            refresh_Member_CallCount();
            update member;              
        }
        catch (exception ex)
        {
            System.debug('@@Exception doSave: ' + ex.getMessage());
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'System Error: ' + ex.getMessage()));
            Database.rollback(sp); // Updated by Bohao Chen on 22/Aug/2014 for JIRA SFE-273

            // SFE-661 2015-08-20 louis.wang@bluewolf.com - fetch from DB to update
            refresh_Member_CallCount();

            // Updated by Bohao Chen on 22/Aug/2014 for JIRA SFE-614
            // BEGIN
            newResponse = new Campaign_Response__c();
            newResponse.Call_Attempt__c = member.Call_Count__c + 1;
            // END

            // added by Tim Fabros 26 / 08 / 2014 - SFE-273
            // set to true to ensure that user does not escape the page.
            // BEGIN:
            hasError = true;
            // END:

            return null;
        }
        // Note: uncomment the following block to simulate exception 
        // LIVE TESTING SECTION
        // BEGIN:
        /*finally
        {
            system.debug('this is testing message, please ignore');
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'this is testing message, please ignore'));
            Database.rollback(sp); // Updated by Bohao Chen on 22/Aug/2014 for JIRA SFE-273
             // Updated by Bohao Chen on 22/Aug/2014 for JIRA SFE-614
             // BEGIN
            newResponse = new Campaign_Response__c();
            newResponse.Call_Attempt__c = 0;
            // END
            return null;
        }*/
        // END:
        
        // updated by Bohao Chen on 12/May/2014
        if(String.isBlank(refTabId))

        {

            //pr = Page.Campaign;
            //pr.getParameters().put('Id', member.CampaignId);
            //System.debug('pageReference in last pr'+pr);
            String memId = '/'+member.Id;
            pr = new PageReference(memId);
            System.debug('pageReference in last pr'+pr);

        }       
        return pr;
    }
    
    
    public pageReference doCancel()
    {
        // added by Tim Fabros 26 / 08 / 2014 - SFE-273
        // reset boolean to ensure proper functionality for cancel button.
        // BEGIN:
        hasError = false;
        // END:

        // SFE-797 2015-12-03 louis.wang@bluewolf.com - reset CampaignMember, so the field changes in VF page from validation errored doSave() won't interfere
        member = [SELECT Id, In_Progress__c, Execution_Status__c, CampaignId, ContactId, LeadId
                    FROM CampaignMember
                    WHERE Id=: member.Id];

        system.debug('@ doCancel()');
        PageReference pr = null;
        try
        {
            system.debug('@ doCancel() member:' + member);
            system.debug('@ doCancel() doNotProceed:' + doNotProceed);
            if(member!=null && !doNotProceed)
            {
                member.In_Progress__c = false;
                
                // SFE-679 2015-12-01 louis.wang@bluewolf.com - if Call Limit Reached, clear out LockedBy so the user won't be locked out.
                if( (previousResponse==null || (previousResponse!=null && previousResponse.Response_SubType__c != 'Request Call Back - Same Agent'))
                    ||                    
                    (member.Execution_Status__c=='Call Limit Reached')
                ) member.Locked_By__c = null;

                // SFE-661 2015-08-20 louis.wang@bluewolf.com - fetch from DB to update
                //refresh_Member_CallCount();

                update member;
                
                //pr = Page.Campaign;
                //pr.getParameters().put('id', member.CampaignId);
                 String memId = '/'+member.Id;
                 pr = new PageReference(memId);
            }
        }
        catch (exception ex)
        {
            // does not need to handle the error, as it is not driven by user input
            System.debug('@@Exception doCancel: ' + ex.getMessage());            
        }
        String memId = '/'+member.Id;
        pr = new PageReference(memId);
        system.debug('@ doCancel() pr:' + pr);
        return pr;
        //return null;
    }
    
    
    
    public void setToInprogress()
    {
        System.debug('@ setToInprogress()');
        
        // added by Tim Fabros - 30 / 07 / 2014 - SFE-550
        // 
        // moved logic from constructor method here
        // fixes race condition issue where 2 or more users
        // would not be locked out and no notification was displayed.
        // BEGIN:
        CampaignMember campaignMember;
        
        try
        {
            // query for the campaign member grabbed in the constructor and lock the record
            campaignMember = [SELECT In_Progress__c, Locked_By__c FROM CampaignMember WHERE Id =: member.Id LIMIT 1 FOR UPDATE]; 
            
            System.debug('@CampaignActionPage_ControllerX setToInprogress campaignMember: ' + campaignMember);
        }
        catch (Exception e)
        {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.WARNING,'An Error occurred grabbing the Campaign Member: ' + e.getMessage()));
            return;
        }
        
        // check if campaign member record is locked by a user
        if (campaignMember.Locked_By__c!=null && campaignMember.Locked_By__c!=UserInfo.getUserId())
        {
            User u = [Select Name from User where id =:member.Locked_By__c];
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Another user (' + u.Name + ') has already locked this Member.<br />Please close this window and refresh the Execution List'));
            doNotProceed = true;
            return;
        }
        
        list<CampaignMember> currentCampaignMembersInProgress = [Select id, Contact.Name, Lead.Name
                                                                 From   CampaignMember
                                                                 where  id != :member.Id
                                                                 AND CampaignId =:member.CampaignId
                                                                 AND Locked_By__c =:UserInfo.getUserId()
                                                                 AND Execution_Status__c != 'Call to Do'];
        if (currentCampaignMembersInProgress.size() > 0)
        {
            doNotProceed = true;
            System.debug('@ CampaignActionPage_ControllerX() currentCampaignMembersInProgress[0]:' + currentCampaignMembersInProgress[0]);
            String currentCampaignMemberName =  currentCampaignMembersInProgress[0].Contact.Name==null?currentCampaignMembersInProgress[0].Lead.Name:currentCampaignMembersInProgress[0].Contact.Name;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO,'You can only lock and work on 1 Campaign Member at a time.<br /> You are currently working on ' + currentCampaignMemberName + '. <br />Please close this window and refresh the Execution List'));
            return;
        }
        
        
        if (ApexPages.currentPage().getParameters().get('refTabId')!=null)      
            refTabId = ApexPages.currentPage().getParameters().get('refTabId');
        
        
        system.debug('@ CampaignActionPage_ControllerX() member:' + member);
        
        if (member != null)
        {
            campaignResponseHistory = CampaignActionPage_Helper.fetch_CampaignResponseHistoryForMember(member.CampaignId, member.ContactId, member.LeadId, member.Id);
        }
        
        if (    campaignResponseHistory!=null &&
            campaignResponseHistory.size()>0)
        {
            previousResponse = campaignResponseHistory[0];
        }
        
        // Needs to be rechecked at save
        newResponse.Call_Attempt__c = campaignResponseHistory.size() + 1;
        // 2015-08-18 SFE-654 louis.wang@bluewolf.com - Shifted the following line to doSave()
        //                      This aims to overcome intermittent Campaign_Name not updated issue
        // newResponse.Campaign_Name__c = member.Campaign.Name;
        // END:
        
        try
        {
            if(campaignMember!=null && !doNotProceed)
            {
                campaignMember.In_Progress__c = true;
                campaignMember.Locked_By__c = UserInfo.getUserId();
                update campaignMember;
            }
            
        }
        catch (exception ex)
        {
            // does not need to handle the error, as it is not driven by user input
            System.debug('@@Exception setToInprogress: ' + ex.getMessage());            
        }       
    }
    
}
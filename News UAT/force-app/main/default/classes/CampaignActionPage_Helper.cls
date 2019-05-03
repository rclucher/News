/**
* @company      Bluewolf
* @author       Louis Wang (louis.wang@bluewolf.com)
* @date         2015-04-23
* @description  This class contains methods that are used for CampaignActionPage_ControllerX
*/
public with sharing class CampaignActionPage_Helper
{
    /**
    * @description Fetch the soql string for fetching CampaignMembership list
    * @param string leadOrContact
    * @param Id contactId
    * @param Id leadId
    * @param Integer queryLimit
    * @return string
    * @author louis.wang@bluewolf.com
    * @date 2015-04-23
    **/
    private static String generateSoql_CampaignMembershipList(String leadOrContact, Id contactId, Id leadId, Integer queryLimit)
    {
        string output = '';
        string whereClause = '';
        if(queryLimit!=null)
        {
            if(leadOrContact=='contact' && contactId!=null)
            {
                whereClause = 'WHERE ContactId = \'' + contactId + '\' ';
            }
            else if(leadOrContact=='lead' && leadId!=null)
            {
                whereClause = 'WHERE LeadId = \'' + leadId + '\' ';
            }

            if(whereClause!='')
            {
                output = 'SELECT Id, Campaign.Name, Campaign.Status, ' +
                                'CompanyOrAccount__c, Call_Count__c, Execution_Status__c, ' + 
                                'Response_Type__c, Response_Sub_Type__c, Age_in_List__c, ' +
                                'LastModifiedDate, LastModifiedBy.Name, ' +
                                'Contact.Name, Lead.Name  ' +
                                'FROM CampaignMember ' +
                                whereClause +
                                'AND Campaign.IsActive=true ' +
                                'ORDER BY LastModifiedDate DESC ' +
                                'LIMIT ' + queryLimit + ' ';
            }
        }
        return output;
    }

    /**
    * @description Fetch the CampaignMembership list
    * @param string leadOrContact
    * @param Id contactId
    * @param Id leadId
    * @param Integer queryLimit
    * @return string
    * @author louis.wang@bluewolf.com
    * @date 2015-04-23
    **/
    public static list<CampaignMember> fetch_CampaignMembershipList(String leadOrContact, Id contactId, Id leadId, Integer queryLimit)
    {
        // 2015-04-23 louis.wang@bluewolf.com UserStory16.3
        //  - List Campaign Members from other Active Campaigns that target
        //  - Order by LastModifiedDate 
        list<CampaignMember> output = new list<CampaignMember>();

        string soqlString = generateSoql_CampaignMembershipList(leadOrContact, contactId, leadId, queryLimit);
        try
        {
	        if(soqlString!='')
	        {
	        	output = Database.query(soqlString);
	        }
	    }
	    catch(Exception ex)
	    {
            // does not need to handle the error, as it is not driven by user input
            System.debug('@@Exception fetchCampaignMembershipList: ' + ex.getMessage());
	    }
        return output;
    }

    /**
    * @description Fetch the CaseHistory list
    * @param Id contactId
    * @param Integer queryLimit
    * @return list<Case>
    * @author louis.wang@bluewolf.com
    * @date 2015-04-23
    **/
    public static list<Case> fetch_CaseHistoryList(Id contactId, Integer queryLimit)
    {
        // 2015-02-18 louis.wang@bluewolf.com UserStory16.2
        //  - List cases that the Contact is assigned as Case Contact or Case Payer Contact
        //  - Order by LastModifiedDate and then sorted by Open then Closed case
        list<Case> output = new list<Case>();

        if(contactId!=null && queryLimit!=null)
        {
	        try
	        {
	            output = [SELECT Id, CaseNumber, RecordType.Name, Status, Subject, Owner.Name, LastModifiedDate 
	                        FROM Case 
	                        WHERE (ContactId =:contactId OR Payer_Contact__c =:contactId)
	                        ORDER BY LastModifiedDate DESC, Status DESC
	                        LIMIT :queryLimit];
	        }
	        catch(Exception ex)
	        {
	            // does not need to handle the error, as it is not driven by user input
	            System.debug('@@Exception fetchCaseHistoryList: ' + ex.getMessage());
	        }
		}
        return output;
    }

    /**
    * @description Fetch ExpiredBooking LIst
    * @param string 
    * @param Id 
    * @param Integer 
    * @param string 
    * @return list<Booking__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-04-23
    **/
    public static list<Booking__c> fetch_ExpiredBookingList(String campaignPubDiv, Id contactId, Integer queryLimit, String queryType)
    {
        // 2015-02-18 louis.wang@bluewolf.com UserStory16.2
        //  - List Expired Bookings
        list<Booking__c> output = new list<Booking__c>();
        try
        {
            String q = generateSoql_Bookings(campaignPubDiv, contactId, queryLimit, queryType);
            System.debug('@@q = ' + q);
            output = Database.query(q);
        }
        catch (Exception ex) 
        {
            // does not need to handle the error, as it is not driven by user input
            System.debug('@@Exception expiredBookingList: ' + ex.getMessage());
        }
        return output;
    }

    /**
    * @description Generate SOQL for Bookings
    * @param string 
    * @param Id 
    * @param Integer 
    * @param string 
    * @return string
    * @author louis.wang@bluewolf.com
    * @date 2015-04-23
    **/
    public static String generateSoql_Bookings(String campaignPubDiv, Id contactId, Integer queryLimit, String queryType)
    {
        String pubDivision='';
        if(campaignPubDiv!=null)
        {
            for(string s : campaignPubDiv.split(';'))
            {
                pubDivision += pubDivision.trim().length()>0 ? ',' : '';
                pubDivision += '\'' + s + '\'';
            }
        }

        String expiryFilter = 'AND (b.Last_Expiry_Appearance__c > LAST_WEEK ' +
                              'AND b.Last_Expiry_Appearance__c <= NEXT_N_MONTHS:3) ';
        if(queryType!='active')
        {
            expiryFilter = 'AND b.Last_Expiry_Appearance__c <= LAST_WEEK ';
        }

        String output = 'Select b.id, ' + 
                    'b.Source_System__c, ' + 
                    'b.Account_No__c, ' + 
                    'b.Booking_Number__c, ' + 
                    'b.sales_Order__r.id, ' + 
                    'b.Sales_Order__r.Calc_External_id__c, ' + 
                    'b.Sales_Order__r.Booking_Division__c, ' + 
                    'b.Sales_Order__r.Source_System__c, ' + 
                    'b.Sales_Order__r.Status__c, ' + 
                    'b.Sales_Order__r.Contact__c, ' + 
                    'b.Sales_Order__r.Creative_Contact_Name__c, ' + 
                    'b.Sales_Order__r.Creative_Contact_Phone__c, ' + 
                    'b.Sales_Order__r.Placer_Contact_Name__c, ' + 
                    'b.Sales_Order__r.Placer_Contact_Phone__c, ' + 
                    'b.Sales_Order__c, ' + 
                    'Sales_Rep__c, ' +
                    'b.Last_Expiry_Appearance__c, ' + 
                    'b.Line_Item_Publication_Divisions_mpl__c, ' + 
                    'b.Line_Item_Classifications__c, ' + 
                    'b.Total_Cost__c, ' + 
                    'b.Advertiser_Account__c, ' +  
                    'b.Status__c, ' +  
                    'b.Name ' + 
                    'From   Booking__c b ' + 
                    'Where  b.Status__c != \'KILLED\'  ';
            
            
         output += pubDivision.length()>0?'AND    b.Line_Item_Publication_Divisions_mpl__c includes (' + pubDivision + ') ':''; 
            
            
         output += 'AND    b.Placer_Contact__c = \'' + contactId + '\' ' +
                    expiryFilter +
                    'Order BY b.Last_Expiry_Appearance__c DESC ' +
                    'LIMIT ' + queryLimit;
        return output;
    }

    /**
    * @description Generate SOQL for Activities
    * @param string 
    * @param Integer 
    * @param Id 
    * @return string
    * @author louis.wang@bluewolf.com
    * @date 2015-04-23
    * @date 2015-05-13 Updated ORDER BY to avoid Salesforce implementation restriction
    **/
    public static String generateSoql_Activities(String sObjectType, Integer queryLimit, Id theId)
    {
        string contactFields = '';
        if(sObjectType=='contact')
        {
            contactFields = 'AccountId, IsPersonAccount, ';
        }

        String output = 'SELECT Id, Name, ' + contactFields +
                        '    (SELECT Id, Subject, ActivityType, IsTask, Owner.Name, LastModifiedDate, ActivityDate ' +
                        '        FROM ActivityHistories ' +
                        '        ORDER BY ActivityDate DESC, LastModifiedDate DESC ' +
                        '        LIMIT ' + queryLimit + '), ' +
                        '    (SELECT Id, Subject, ActivityType, IsTask, Owner.Name, LastModifiedDate, ActivityDate  ' +
                        '        FROM OpenActivities  ' +
                        '        ORDER BY ActivityDate ASC, LastModifiedDate DESC ' +
                        '        LIMIT ' + queryLimit + ') ' +
                        'FROM ' + sObjectType + ' ' +
                        'WHERE Id = \'' + theId + '\' ' +
                        'LIMIT 1';
        return output;
    }

    /**
    * @description Decide whether Lead or Contact
    * @param Id 
    * @return string
    * @author louis.wang@bluewolf.com
    * @date 2015-04-23
    **/
    public static string update_LeadOrContact(Id contactId)
    {
        // CampaignMember can only be contact or lead
        //  CampaignMember can have both ContactId and LeadId for converted Lead
        string output;
        if(contactId!=null)
        {
            output = 'contact';
        }
        else
        {
            output = 'lead';
        }
        return output;
    }  

    /**
    * @description Fetch ContactPlan LIst
    * @param string 
    * @param Id 
    * @param Integer 
    * @param string 
    * @return list<Campaign_Response__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-04-23
    **/
    public static list<Campaign_Response__c> fetch_ContactPlanList(Id contactId, Integer queryLimit)
    {
        list<Campaign_Response__c> output = new list<Campaign_Response__c>();
        try
        {
            if(contactId!=null)
            {
                output = [Select   Name,
                                       Campaign_Member_Id__c,
                                       Contact_Plan_Date__c,
                                       Contact_Plan_Publication_Divisions__c,
                                       Contact_Plan_Ad_Type__c
                                   From Campaign_Response__c
                                   Where    Contact__c = : contactId
                                   AND  Contact_Plan_Date__c > LAST_N_DAYS:2
                                   AND Contact_Plan_Cancelled__c = false
                                   Order By Contact_Plan_Date__c
                                   LIMIT :queryLimit];
            }
            
        }
        catch (Exception ex)
        {
            // does not need to handle the error, as it is not driven by user input
            System.debug('@@Exception fetch_ContactPlanList: ' + ex.getMessage());            
        }
        return output;     
    }

    /**
    * @description Fetch Booking List
    * @param string 
    * @param Id 
    * @param Integer 
    * @param string 
    * @return list<Booking__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-04-23
    **/
    public static list<Booking__c> fetch_BookingList(String campaignPubDiv, Id contactId, Integer queryLimit, String queryType)
    {
        list<Booking__c> output = new list<Booking__c>();
        try
        {
            String q = CampaignActionPage_Helper.generateSoql_Bookings(campaignPubDiv, contactId, queryLimit, queryType);
            system.debug('@ fetch_BookingList() q:' + q);
            output = (list<Booking__c>) database.query(q);
        }
        catch (Exception ex)
        {
            // does not need to handle the error, as it is not driven by user input
            System.debug('@@Exception fetch_BookingList: ' + ex.getMessage());            
        }        
        return output;
    } 
 
     /**
    * @description Fetch Campaign Response History
    * @param Id
    * @param Id 
    * @param Id 
    * @param Id         
    * @return list<Campaign_Response__c>
    * @author louis.wang@bluewolf.com
    * @date 2015-04-27
    **/
    public static list<Campaign_Response__c>  fetch_CampaignResponseHistoryForMember(id campaignID, id contactId, id leadId, id memberId)
    {
        list<Campaign_Response__c> output = new list<Campaign_Response__c>();
        try
        {
            if(contactId!=null)
            {
                output = [Select   Response_Type__c,
                                           Response_Subtype__c,
                                           Response_Comment__c,
                                           Call_Attempt__c,
                                           Call_Back_Reminder__c,
                                           Call_Back_Date__c,
                                           CreatedDate,
                                           CreatedBy.Name
                                           From Campaign_Response__c
                                           Where    Campaign__c = :campaignID
                                           AND  Contact__c = :contactId
                                           AND Campaign_Member_Id__c = :memberId
                                           Order By LastModifiedDate Desc];
            }
            else if(LeadId!=null)
            {
                output = [Select   Response_Type__c,
                                           Response_Subtype__c,
                                           Response_Comment__c,
                                           Call_Attempt__c,
                                           Call_Back_Reminder__c,
                                           Call_Back_Date__c,
                                           CreatedDate,
                                           CreatedBy.Name
                                           From Campaign_Response__c
                                           Where    Campaign__c = :campaignID
                                           AND Lead__c = :leadId
                                           AND Campaign_Member_Id__c = :memberId
                                           Order By LastModifiedDate Desc];
            }
        }
        catch (Exception ex)
        {
            // does not need to handle the error, as it is not driven by user input
            System.debug('@@Exception fetch_CampaignResponseHistoryForMember: ' + ex.getMessage());            
        }
        return output; 
    }


}
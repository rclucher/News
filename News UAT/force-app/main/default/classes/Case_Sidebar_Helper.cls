/**
* @company      Bluewolf
* @author       Louis Wang (louis.wang@bluewolf.com)
* @date         2015-01-29
* @description  This class contains methods that are used for Case Sidebar pages (console) <p>
*                   - Case_AccountInfo <p>
*                   - Case_EnhancedAccountSearch <p>
*                   - Case_NewAccountContact <p>
*                   - Case_RefreshPrimaryTab <p>
*/
public with sharing class Case_Sidebar_Helper 
{
    public static final string PASS_CORRECT_INFO = 'Please pass correct information to the Url.';

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-01-29
    * @description  This method will perform URL redirect
    * @param        PageReference - destination page
    * @param        Boolean - whether it is a redirect
    * @param        Id - record Id to pass through
    * @param        String - type param    
    * @return       PageReference
    */    
    public static PageReference gotoPage(PageReference pageName, Boolean isRedirect, Id recordId, String typeParam)
    {
        PageReference output = pageName;
        if(recordId!=null) output.getParameters().put('id', recordId);
        if(typeParam!=null) output.getParameters().put('type', typeParam);
        output.setRedirect(isRedirect);
        return output;
    }

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-10-28
    * @description  This method will perform URL redirect, with additional param "keyword" (SFE-739)
    * @param        PageReference - destination page
    * @param        Boolean - whether it is a redirect
    * @param        Id - record Id to pass through
    * @param        String - type param    
    * @param        String - type param
    * @return       PageReference
    */    
    public static PageReference gotoPage(PageReference pageName, Boolean isRedirect, Id recordId, String typeParam, String keywordParam)
    {
        PageReference output = pageName;
        if(recordId!=null) output.getParameters().put('id', recordId);
        if(typeParam!=null) output.getParameters().put('type', typeParam);
        if(keywordParam!=null) output.getParameters().put('keyword', EncodingUtil.urlEncode(keywordParam, 'UTF-8'));        
        output.setRedirect(isRedirect);
        return output;
    }

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-01-29
    * @description  This method will fetch Case record based on a ID String
    * @param        String - case Id
    * @return       Case
    */    
    public static Case fetchCaseRecord(string caseRecordId)
    {
        Case output = null;

        if(caseRecordId!=null)
        {
            list<Case> caseList = [SELECT Id, CaseNumber, AccountId 
                                    FROM Case
                                    WHERE Id =: caseRecordId];
            if(!caseList.isEmpty())
            {
                output = caseList[0];
            }
        }
        return output;
    }

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-01-29
    * @description  This method will fetch Contact Id based on few params. <p>
    *                   If the selected Account is a person account, fetch it. <p>
    *                   If the selected Account only has 1 contact, fetch it. <p>
    * @param        String - account Id
    * @param        boolean - whether account is Person Account
    * @param        Id - Contact Id from the Person Account
    * @return       Case
    */    
    public static Id fetchContactId_FromChosenAccount(string selectedAccount_Id, boolean selectedAccount_IsPersonAccount, string selectedAccount_ContactId)
    {
        // This function will fetch a ContactId. 
        Id output_ContactId;

        if(selectedAccount_Id!=null)
        {    
            if(selectedAccount_IsPersonAccount)
            {
                // if the Account is a Private Party (ie. PersonAccount), then fetch contactId
                output_ContactId = selectedAccount_ContactId;
            }
            else
            {
                // if not Person Account (ie. Business Account etc), and there is only 1 contact, then fetch contactId
                list<Contact> cList = [SELECT Id, AccountId 
                                        FROM Contact 
                                        WHERE AccountId = : selectedAccount_Id];
                if(cList.size()==1)
                {
                    output_ContactId = cList[0].Id;
                }                                
            }
        }    
        return output_ContactId;
    }

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-07-29
    * @description  This method will transform the search string to acceptable format
    * @param        String
    * @param        boolean
    * @return       String
    */    
    public static String format_SearchString(String keywordString, Boolean isExactMatch)
    {
        String output = '';
        if(keywordString!=null && keywordString.trim().length()>0)
        {
            if(isExactMatch)
            {
                output = '\'' + string.escapeSingleQuotes(keywordString) + '\'';
            }
            else
            {
                output = '\'' + string.escapeSingleQuotes(keywordString) + '%\'';    
            }
        }
        return output;           
    }   

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-07-29
    * @description  This method will generate SOQL string for booking
    * @param        String
    * @param        String
    * @return       String
    */    
    public static String generate_bookingSoql(string searchString, string limitString)
    {
        string output = 'SELECT Id, Name, Advertiser_Account__r.Name, Status__c, ' +
                        '       Source_System__c, Total_Cost__c, Sales_Order__r.Owner.Name, LastModifiedDate, ' +
                        '       Advertiser_Account__r.IsPersonAccount, Advertiser_Account__r.PersonContactId, ' +
                        '       CyberAd_Classification__c, Line_Item_Publications__c ' +
                        'FROM Booking__c ' +
                        'WHERE Name LIKE ' + searchString + ' ' +
                        'ORDER BY LastModifiedDate DESC ' + 
                        'LIMIT ' + limitString;
        return output;
    }

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-07-29
    * @description  This method will generate SOQL string for case
    * @param        String
    * @param        String
    * @return       String
    */    
    public static String generate_caseSoql(string searchString, string limitString)
    {
        string output = 'SELECT Id, CaseNumber, Account.Name, RecordType.Name, ' + 
                        '       Status, Subject, Owner.Name, LastModifiedDate, ' +
                        '       Account.IsPersonAccount, Account.PersonContactId, ' +
                        '       Type ' +
                        'FROM Case ' +
                        'WHERE CaseNumber LIKE ' + searchString + ' ' +
                        'ORDER BY LastModifiedDate DESC ' + 
                        'LIMIT ' + limitString;
        return output;
    }

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-07-29
    * @description  This method will generate SOQL string for account
    * @param        String
    * @param        String
    * @return       String
    */    
    public static String generate_accountSoql(string searchString, string limitString, string bsaSetName)
    {
        string output = 'SELECT Id, Name, RecordType.Name, Phone, PersonHomePhone, PersonMobilePhone, ' + 
                        '       PersonOtherPhone, IsPersonAccount, PersonContactId, ' +
                        '       AccountNumber, Owner.Name, BillingCity, PersonMailingCity ' +
                        'FROM Account ' +
                        'WHERE (Name LIKE ' + searchString + ' ' +
                        '       OR FirstName LIKE ' + searchString + ' ' +
                        '       OR LastName LIKE ' + searchString + ' ' +
                        '       OR Phone LIKE ' + searchString + ' ' +
                        '       OR PersonHomePhone LIKE ' + searchString + ' ' +
                        '       OR PersonMobilePhone LIKE ' + searchString + ' ' +
                        '       OR PersonOtherPhone LIKE ' + searchString + ') ';
            //Item-00182 DD Added parameters for searching with a set of account ids generated from related BSA
        	if(bsaSetName != null){
                output += '      OR Id IN :' + bsaSetName + ' ';
            }
        output += 'ORDER BY LastModifiedDate DESC ' + 
                         'LIMIT ' + limitString;
        return output;
    }
    
    /**
    * @author       David Dawson (david.dawson@bluewolf.com)
    * @date         2016-11-25
    * @description  This method will generate SOQL string for booking system account
    * @param        String
    * @param        String
    * @return       String
    */    
    public static String generate_bsaSoql(string searchString, string limitString)
    {
        string output = 'SELECT Id, Customer_Account__c ' +
                        'FROM External_Account__c ' +
                        'WHERE Account_No__c LIKE ' + searchString + ' ' +
                        'ORDER BY LastModifiedDate DESC ' + 
                        'LIMIT ' + limitString;
        return output;
    }

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-07-29
    * @description  This method will generate SOQL string for contact
    * @param        String
    * @param        String
    * @return       String
    */    
    public static String generate_contactSoql(string searchString, string limitString)
    {
        string output = 'SELECT Id, Name, Account.Name, Email, Phone, HomePhone, MobilePhone, OtherPhone, AccountId ' +
                        'FROM Contact ' +
                        'WHERE (Name LIKE ' + searchString + ' ' +
                        '       OR FirstName LIKE ' + searchString + ' ' +
                        '       OR LastName LIKE ' + searchString + ' ' +
                        '       OR Phone LIKE ' + searchString + ' ' +
                        '       OR HomePhone LIKE ' + searchString + ' ' +
                        '       OR MobilePhone LIKE ' + searchString + ' ' +
                        '       OR OtherPhone LIKE ' + searchString + ' ' +  
                        '       OR Email LIKE ' + searchString + ') ' +
                        'AND IsPersonAccount=false ' + 
                        'AND Contact_Status__c=\'Active\'' +
                        'ORDER BY LastModifiedDate DESC ' + 
                        'LIMIT ' + limitString;
        return output;
    }  

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-08-14
    * @description  This method will generate SOQL string for Account (for Case_AccountInfo)
    *               (This method is relocated from Case_AccountInfo)
    * @param        String
    * @param        String
    * @param        String    
    * @return       String
    */    
    public static string generate_accountSoql_for_Case_AccountInfo(string acctId, string limitString, string limitString_Contacts)
    {
        string output = '';
        if(acctId!=null && limitString!=null && limitString_Contacts!=null)
        {
            output = 'SELECT Id, Name, RecordType.Name, Status__c, AccountNumber, Last_Booking_Number__c, Owner.Name, IsPersonAccount, ' +
                        '(SELECT Id, Name, Status__c, Source_System__c, Total_Cost__c, Sales_Order__r.Owner.Name, LastModifiedDate, Line_Item_Classifications__c, Ad_Proof_Link__c FROM Bookings__r ORDER BY LastModifiedDate DESC LIMIT ' + limitString + '), ' + 
                        '(SELECT Id, CaseNumber, RecordType.Name, Status, Subject, Owner.Name, LastModifiedDate FROM Cases ORDER BY LastModifiedDate DESC LIMIT ' + limitString + '), ' + 
                        '(SELECT Id, Subject, ActivityType, IsTask, Owner.Name, LastModifiedDate FROM ActivityHistories ORDER BY ActivityDate DESC, LastModifiedDate DESC LIMIT ' + limitString + '), ' + 
                        '(SELECT Id, Subject, ActivityType, IsTask, Owner.Name, LastModifiedDate FROM OpenActivities ORDER BY ActivityDate ASC, LastModifiedDate DESC LIMIT ' + limitString + '), ' + 
                        '(SELECT Id, FirstName, LastName, Email, Phone, LastModifiedDate, AccountId, Name FROM Contacts ORDER BY LastModifiedDate DESC LIMIT ' + limitString_Contacts + ') ' + 
                        'FROM Account ' +
                        'WHERE Id = \'' + acctId + '\'';
        }
        return output;

        /* sample output string
        SELECT Id, Name, RecordType.Name, 
                (SELECT Id, Name FROM Bookings__r LIMIT 4), 
                (SELECT Id, CaseNumber FROM Cases LIMIT 4), 
                (SELECT Id FROM ActivityHistories LIMIT 4), 
                (SELECT Id FROM OpenActivities LIMIT 4),
                (SELECT Id FROM Contacts LIMIT 4)
        FROM Account 
        WHERE Id = '001N000000N2Duv'
        */        
    }

    /**
    * @author       Louis Wang (louis.wang@bluewolf.com)
    * @date         2015-08-14
    * @description  This method will fetch campaignMember list for Account (for Case_AccountInfo)
    * @param        Id
    * @param        String
    * @return       List<CampaignMember>
    */    
    public static List<CampaignMember> fetch_cmList_for_Case_AccountInfo(Id acctId, String limitString)
    {
        List<CampaignMember> output = new List<CampaignMember>();
        if(acctId!=null && limitString!=null)
        {
            output = [SELECT Id, Response_Type__c, Response_Sub_Type__c, LastModifiedDate,
                                Campaign.Name, Campaign.Status,
                                Contact.Name
                        FROM CampaignMember 
                        WHERE Contact.AccountId =: acctId
                        AND Campaign.IsActive = true
                        ORDER BY LastModifiedDate DESC
                        LIMIT : integer.valueOf(limitString)];
        }
        return output;
    }


}
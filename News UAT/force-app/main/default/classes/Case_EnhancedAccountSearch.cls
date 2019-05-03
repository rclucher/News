/**
* @company      Bluewolf
* @author       Louis Wang (louis.wang@bluewolf.com)
* @date         2015-01-29
* @description  This class contains methods that are used for Case Sidebar pages (console) <p>
*                   - Case_AccountInfo <p>
*                   - Case_EnhancedAccountSearch (in particular) <p>
*                   - Case_NewAccountContact <p>
*                   - Case_RefreshPrimaryTab <p>
*/
public with sharing class Case_EnhancedAccountSearch 
{
    public string keywordString {get;set;}
    public list<Booking__c> bookingList {get;set;}
    public list<Case> caseList {get;set;}
    public list<Account> accountList {get;set;}
    public list<Contact> contactList {get;set;}
    public Case caseRecord {get;set;}

    private static final string QUERY_LIMIT = '10';

    public Case_EnhancedAccountSearch(ApexPages.StandardController controller) 
    {
    }

    public PageReference init()
    {
        // setup init to ensure essential parameters are available from the URL
        string caseRecordId = ApexPages.currentPage().getParameters().get('id');

        caseRecord = Case_Sidebar_Helper.fetchCaseRecord(caseRecordId);

        resetSearchLists();

        if(caseRecord==null)
        {
            string errorMsg = Case_Sidebar_Helper.PASS_CORRECT_INFO;
            AddVfMessage(errorMsg);
        }
        return null;
    }

    private void AddVfMessage(string InfoDetail)
    {
        apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.Info,InfoDetail);
        apexpages.addMessage(msg);            
    }    

    public PageReference searchNow_Booking()
    {
        // Perform SOQL serach for all the 
        system.debug('>>>>>>>>>>>>>>>>>>> keywordString: ' + keywordString);
        string bookingSearchKey = ApexPages.currentPage().getParameters().get('bookingSearchKey');
        system.debug('>>>>>>>>>>>>>>>>>>> bookingSearchKey: ' + bookingSearchKey); 
        string searchString = Case_Sidebar_Helper.format_SearchString(keywordString, true);
        if(searchString!='')
        {
            String soqlString = Case_Sidebar_Helper.generate_bookingSoql(searchString, QUERY_LIMIT); 
            bookingList = Database.query(soqlString);                           
        }
        else 
        {
            bookingList = new List<Booking__c>();
        }
        return null;
    }

    public PageReference searchNow_Case()
    {
        // Perform SOQL serach for all the 
        system.debug('>>>>>>>>>>>>>>>>>>> keywordString: ' + keywordString);
        string caseSearchKey = ApexPages.currentPage().getParameters().get('caseSearchKey');
        system.debug('>>>>>>>>>>>>>>>>>>> caseSearchKey: ' + caseSearchKey);
        string searchString = Case_Sidebar_Helper.format_SearchString(keywordString, true);
        if(searchString!='')
        {
            String soqlString = Case_Sidebar_Helper.generate_caseSoql(searchString, QUERY_LIMIT); 
            caseList = Database.query(soqlString);
        }
        else 
        {
            caseList = new List<Case>();
        }
        return null;
    }
    public PageReference searchNow_Account()
    {
        // Perform SOQL serach for all the
        system.debug('>>>>>>>>>>>>>>>>>>> keywordString: ' + keywordString);
        string accountSearchKey = ApexPages.currentPage().getParameters().get('accountSearchKey');
        system.debug('>>>>>>>>>>>>>>>>>>> accountSearchKey: ' + accountSearchKey);
        string searchString = Case_Sidebar_Helper.format_SearchString(keywordString, false);
        if(searchString!='')
        {
            //David Dawson 25/11/2016 Item-00182
            //first query the booking system account object to form a set of account ids
            String bsaSearchString = Case_Sidebar_Helper.generate_bsaSoql(searchString, QUERY_LIMIT);
            List<External_Account__c> bsaList = Database.query(bsaSearchString);
            Set<Id> bsaSet = new Set<Id>();
            String soqlString = '';
            if(!bsaList.isEmpty()){
                for(External_Account__c bsa :bsaList){
                    bsaSet.add(bsa.Customer_Account__c);
                }
                soqlString = Case_Sidebar_Helper.generate_accountSoql(searchString, QUERY_LIMIT, 'bsaSet');
            }else{
                soqlString = Case_Sidebar_Helper.generate_accountSoql(searchString, QUERY_LIMIT, null);
            }
            
            accountList = Database.query(soqlString);
        }
        else 
        {
            accountList = new List<Account>();
        }
        return null;
    }
    public PageReference searchNow_Contact()
    {
        // Perform SOQL serach for all the 
        system.debug('>>>>>>>>>>>>>>>>>>> keywordString: ' + keywordString);
        string contactSearchKey = ApexPages.currentPage().getParameters().get('contactSearchKey');
        system.debug('>>>>>>>>>>>>>>>>>>> contactSearchKey: ' + contactSearchKey);
        string searchString = Case_Sidebar_Helper.format_SearchString(keywordString, false);
        if(searchString!='')
        {
            String soqlString = Case_Sidebar_Helper.generate_contactSoql(searchString, QUERY_LIMIT); 
            contactList = Database.query(soqlString);
        }
        else 
        {
            contactList = new List<Contact>();
        }
        return null;
    }

    private void resetSearchLists()
    {
        bookingList = new list<Booking__c>();
        caseList = new list<Case>();
        accountList = new list<Account>();
        contactList = new list<Contact>();
    }

    public PageReference createNewAccount()
    {
        // SFE-739 2015-10-20 louis.wang@bluewolf.com - display "last keyword used" on New Account page
        return Case_Sidebar_Helper.gotoPage(Page.Case_NewAccountContact, true, caseRecord.Id, 'account', keywordString);
    }
    
    public PageReference applySelection()
    {
        // Based on the particular record in the particualr list block, derive the accociated Account and Conatct
        //  records and update them to Case record.
        String tempSelectedType = ApexPages.currentPage().getParameters().get('tempSelectedType');
        string tempAccountId = ApexPages.currentPage().getParameters().get('tempAccountId');
        string tempContactId = ApexPages.currentPage().getParameters().get('tempContactId');
        boolean tempIsPersonAccount = ApexPages.currentPage().getParameters().get('tempIsPersonAccount') == 'true';
        string tempBookingId = ApexPages.currentPage().getParameters().get('tempBookingId');
        string tempCaseId = ApexPages.currentPage().getParameters().get('tempCaseId');
		
        Id inferredContactId;
        
        if(tempSelectedType=='booking')
        {
            inferredContactId = Case_Sidebar_Helper.fetchContactId_FromChosenAccount(tempAccountId, tempIsPersonAccount, tempContactId);
        }
        else if(tempSelectedType=='case')
        {
            inferredContactId = Case_Sidebar_Helper.fetchContactId_FromChosenAccount(tempAccountId, tempIsPersonAccount, tempContactId);
        }
        else if(tempSelectedType=='account')
        {
            inferredContactId = Case_Sidebar_Helper.fetchContactId_FromChosenAccount(tempAccountId, tempIsPersonAccount, tempContactId);
        }
        else if(tempSelectedType=='contact')
        {
            inferredContactId = tempContactId;
        }
        
        try
        {
            caseRecord.AccountId = tempAccountId;
            caseRecord.ContactId = inferredContactId;
            update caseRecord;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return null;
        }
        return Case_Sidebar_Helper.gotoPage(Page.Case_RefreshPrimaryTab, true, null, null);
    }

    public PageReference gotoAccountInfoPage()
    {
        return Case_Sidebar_Helper.gotoPage(Page.Case_AccountInfo, true, caseRecord.Id, null);
    }

}
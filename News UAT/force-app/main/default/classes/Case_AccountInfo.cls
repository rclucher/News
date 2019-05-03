/**
* @company      Bluewolf
* @author       Louis Wang (louis.wang@bluewolf.com)
* @date         2015-01-29
* @description  This class contains methods that are used for Case Sidebar pages (console) <p>
*					- Case_AccountInfo (in particular) <p>
*					- Case_EnhancedAccountSearch <p>
* 					- Case_NewAccountContact <p>
*					- Case_RefreshPrimaryTab <p>
* @modification 2015-08-14 louis.wang@bluewolf.com - display active campaigns of associated contacts
*/
public with sharing class Case_AccountInfo 
{
    public Case caseRecord {get; private set;}
	public Account acct {get; private set;}
    public list<CampaignMember> cmList {get; private set;}
    private static final string QUERY_LIMIT = '4';
    private static final string QUERY_LIMIT_CONTACTS = '20';
    private static final string QUERY_LIMIT_CAMPAIGNMEMBERS = '3';

    public Case_AccountInfo(ApexPages.StandardController controller) 
    {
    }

    public PageReference createNewContact()
    {
    	return Case_Sidebar_Helper.gotoPage(Page.Case_NewAccountContact, true, caseRecord.Id, 'contact');
    }

    public PageReference changeAccount()
    {
        return Case_Sidebar_Helper.gotoPage(Page.Case_EnhancedAccountSearch, true, caseRecord.Id, null);
    }   

    public PageReference init()
    {
        // setup init to ensure essential parameters are available from the URL
        string caseRecordId = ApexPages.currentPage().getParameters().get('id');

        caseRecord = Case_Sidebar_Helper.fetchCaseRecord(caseRecordId);

        if(caseRecord!=null)
        {
        	if(caseRecord.AccountId==null)
        	{
        		// if Case does not link to an Account, then redirect to Enhanced Account Search page.
        		return changeAccount();
        	}
        	else
	    	{
	    		// if Case links to an Account, then fetch all the children related list.
				string acctId = caseRecord.AccountId;
                string accountSoql = Case_Sidebar_Helper.generate_accountSoql_for_Case_AccountInfo(acctId, QUERY_LIMIT, QUERY_LIMIT_CONTACTS);
				list<Account> accountList = Database.query(accountSoql);
				if(!accountList.IsEmpty())
				{
					acct = accountList[0];
                    // get the full list of active campaigns of associated contacts
                    cmList = Case_Sidebar_Helper.fetch_cmList_for_Case_AccountInfo(acct.Id, QUERY_LIMIT_CAMPAIGNMEMBERS);
				}
	    	}
        }
        /*else
        {
            string errorMsg = Case_Sidebar_Helper.PASS_CORRECT_INFO;
            AddVfMessage(errorMsg);
        }*/
        return null;
    }

    @TestVisible private void AddVfMessage(string InfoDetail)
    {
        apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.Info,InfoDetail);
        apexpages.addMessage(msg);            
    }    

    public PageReference applySelection()
    {
    	// This function updates the selected Contact record to the ContactId of the Case record
        Id selectedId = ApexPages.currentPage().getParameters().get('selectedId');        
        try
        {
            caseRecord.ContactId = selectedId;
            update caseRecord;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return null;
        }
        return Case_Sidebar_Helper.gotoPage(Page.Case_RefreshPrimaryTab, true, null, null);
    }       
}
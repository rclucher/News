/**
* @company      Bluewolf
* @author       Louis Wang (louis.wang@bluewolf.com)
* @date         2015-01-29
* @description  This class contains methods that are used for Case Sidebar pages (console) <p>
*                   - Case_AccountInfo <p>
*                   - Case_EnhancedAccountSearch<p>
*                   - Case_NewAccountContact  (in particular) <p>
*                   - Case_RefreshPrimaryTab <p>
*/
public with sharing class Case_NewAccountContact {
    public list<SelectOption> recordTypeList {get;set;}
    public string recordTypeSelected {get;set;}
    public string personAccountRTId {get;set;}
    public Account acct {get;set;}
    public Case caseRecord {get;set;}
    public Contact cont {get;set;}
    public boolean isParamError {get;set;}
    public string firstNameString {get;set;}
    public string lastNameString {get;set;}
    public string typeOfRecord {get;set;}
    private Id acctId;
    public string lastKeyword {get; private set;}

    public Case_NewAccountContact(ApexPages.StandardController controller) 
    {
        isParamError = false;
    }

    public PageReference init()
    {
        // setup init to ensure essential parameters are available from the URL
        string caseRecordId = ApexPages.currentPage().getParameters().get('id');
        typeOfRecord = ApexPages.currentPage().getParameters().get('type');
        // SFE-739 2015-10-20 louis.wang@bluewolf.com - display "last keyword used" on New Account page
        lastKeyword = ApexPages.currentPage().getParameters().get('keyword');
        if(lastKeyword!=null)
        {
            lastKeyword = EncodingUtil.urlDecode(lastKeyword, 'UTF-8');
        }

        caseRecord = Case_Sidebar_Helper.fetchCaseRecord(caseRecordId);

        if(!(typeOfRecord=='account' || typeOfRecord=='contact'))
        {
            typeOfRecord = null;
        }

        if(caseRecord!=null && typeOfRecord!=null)
        {
            resetAccount();
            resetContact();
            populateRecordTypes();
        }
        else
        {
            // Both param need to be legit. Otherwise, don't display the form.
            isParamError = true;
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

    private void populateRecordTypes()
    {
        recordTypeList = new list<SelectOption>();
        for(RecordType rt : [SELECT Id, Name, IsPersonType 
                                FROM RecordType
                                WHERE SobjectType = 'Account'
                                AND IsActive = true
                                ORDER BY Name])
        {
            recordTypeList.add(new SelectOption(rt.Id, rt.Name));
            if(rt.IsPersonType)
            {
                personAccountRTId = rt.Id;
            }
        }
    }

    private void resetAccount()
    {
        // reset Account when new record type is selected
        if(typeOfRecord=='account')
        {
            acct = new Account();   
            acct.RecordTypeId = recordTypeSelected;    
        }
    }

    private void resetContact()
    {
        // reset Contact
        if(typeOfRecord=='contact')
        {
            cont = new Contact();
            acctId = caseRecord.AccountId;
        }        
    }
                                    
    public PageReference refreshPage()
    {
        // refreshPage when new record type is selected
        resetAccount();
        return null;
    }

    public PageReference saveAccount()
    {
        // save the new account created
        SavePoint sp = Database.setSavepoint();

        acct.No_Parent_Account__c = true;
        acct.RecordTypeId = recordTypeSelected;
        if(recordTypeSelected==personAccountRTId)
        {
            // If it is Person Account, then need to grab firstname and lastname from string variable.
            //  This is workaround for person account data entry.
            acct.FirstName = firstNameString;
            acct.LastName = lastNameString;
        }
        
        try 
        {
            insert acct;
            
            if(recordTypeSelected==personAccountRTId)
            {
                // fetch the saved account. If it is a PersonAccount, then it will have PersonContactId.
                Account fetchedAcct = [SELECT Id, Name, PersonContactId
                                        FROM Account
                                        WHERE Id =: acct.Id];
                caseRecord.ContactId = fetchedAcct.PersonContactId;
            }
            else
            {
                // otherwise clear the Contact info from Case record
                caseRecord.ContactId = null;
            }
            // update the new Account Id to the Case record
            caseRecord.AccountId = acct.Id;
            update caseRecord;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            Database.rollback(sp);
            return null;
        }
        return Case_Sidebar_Helper.gotoPage(Page.Case_RefreshPrimaryTab, true, null, null);
    }

    public PageReference saveContact()
    {    
        // save the newly created Contact    
        SavePoint sp = Database.setSavepoint();

        try 
        {
            cont.AccountId = acctId;
            insert cont;
            caseRecord.ContactId = cont.Id;
            update caseRecord;  
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            Database.rollback(sp);
            return null;
        }
        return Case_Sidebar_Helper.gotoPage(Page.Case_RefreshPrimaryTab, true, null, null);
    }

    public PageReference cancelNewRecord()
    {
        return Case_Sidebar_Helper.gotoPage(Page.Case_AccountInfo, true, caseRecord.Id, null);
    }
}
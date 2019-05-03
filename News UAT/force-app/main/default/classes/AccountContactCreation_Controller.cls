/* 2016-06-10   Shri K       Update
// Item-00083 2015-12-15 shrinivas.kalkote@blueswolfgroup.com   
---------------------------------------------------------*/
public with sharing class AccountContactCreation_Controller  extends PageControllerBase{

    private final Integer MINCHARLENGTH = 3;    
    private final Integer PAGESIZE = 10;

    private list<Account> accountsFound;
    private list<Contact> contactsFound;
    public Account selectedAccount {get;private set;}
    public String refTabId {get;set;}
    public Boolean isVf {get{return isVf == NULL ? false : isVf; }set;}

    // current case
    public Case currCase {
        get
        {

            //set accountId is a new one has been created
            if(CreateAccountComponentController.newAccount.id!=null)
            {
                currCase.accountId = CreateAccountComponentController.newAccount.id;
                CreateAccountComponentController.cancelAddnewAccount(); 
                doSelectAccount();
            } 

            Return currCase;

        }

         private set;}
    public String phoneNumber {get;set;}

    // New Contact
    public boolean showAddnewContactFlag {public get{return showAddnewContactFlag = showAddnewContactFlag!=null?showAddnewContactFlag:false;} private set;}
    public Contact newContact 
    {
        get
        {
            if(newContact==null)
            {
                newContact =new Contact();
                newContact.Accountid = currCase.accountId;
            }
            return newContact;
        }
        set;
    }

    public boolean hasSearched
    {
        get
        { 
            if(SearchAccountComponentController!=null)
            {
                hasSearched = SearchAccountComponentController.hasSearched;
            }
            return hasSearched;
        }
        private set;        
    }

    //// Custom components - Start ////
     public AccountSearch_Controller SearchAccountComponentController
      { 
        get
        {
            if(getComponentControllerMap()!=null)
            {
              AccountSearch_Controller mcc;
              mcc = (AccountSearch_Controller) getComponentControllerMap().get('accountSearch');
              if(mcc!= null)
                 return mcc;    
            }
            return new AccountSearch_Controller();
        } 
        set;
      }
        
      public AccountCreate_Controller CreateAccountComponentController
      { 
        get
        {
            if(getComponentControllerMap()!=null)
            { 
              AccountCreate_Controller mcc;
              mcc = (AccountCreate_Controller) getComponentControllerMap().get('accountCreate');
              if(mcc!= null)
                 return mcc;    
            }
            return new AccountCreate_Controller();
        } 
        set;
      } 



    public AccountContactCreation_Controller(ApexPages.StandardController controller)
    {

        if(!test.isRunningTest())
        {
            controller.addFields(new String[]{'CaseNumber','Origin','AccountId','ContactId','cLI__c', 'SuppliedFromEmail_text__c'});
        }


        if(ApexPages.currentPage().getParameters().get('refTabId')!=null)       
            refTabId = ApexPages.currentPage().getParameters().get('refTabId');

        if(ApexPages.currentPage().getParameters().get('IsVf')!=null)
            isVf = Boolean.valueOf(ApexPages.currentPage().getParameters().get('IsVf'));

        currCase = (Case) controller.getRecord();

        init();
    }


    private void init()
    {
        system.debug('@ init()');
        system.debug('@ init() currCase.accountId:' + currCase.accountId);
        system.debug('@ init() currCase.contactId:' + currCase.contactId);
        system.debug('@ init() currCase.cLI__c:' + currCase.cLI__c);
        //If account seleted and no contact, show list of selected Account's contacts
        
        if(currCase.accountId!=null && currCase.contactId==null)
        {
            searchForContactByAccount(currCase.accountId);
        }
        //Search for contacts and accounts by cLI
        else if(currCase.cLI__c!=null && currCase.Origin=='Call - Inbound')
        {   
            searchForAccountsAndContactByPhoneNumber(currCase);
        }
        else if(currCase.SuppliedFromEmail_text__c!=null && currCase.Origin=='Email - Inbound')
        {   
            searchForAccountsAndContactByEmail(currCase);
        }       
        else if(currCase.accountId==null && currCase.contactId==null &&
                ((currCase.cLI__c==null && currCase.Origin=='Call - Inbound') ||
                (currCase.SuppliedFromEmail_text__c==null && currCase.Origin=='Email - Inbound')))
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Case do not contain the necessary information'));
        }


        if(currCase.accountId!=null && currCase.contactId==null && (contactsFound==null || contactsFound.size()<1))
        {
            showAddnewContactFlag();
        }


        if(currCase.accountId != null)
        {
            selectedAccount = [SELECT recordType.DeveloperName FROM Account WHERE id = :currCase.accountId];
        }
        
        // add helpful message for users about using this page
        String msg = 'This screen assists in searches where multiple CLI (Phone/ Mobile) of contacts and accounts are matched.<br />' +
                    'Where a CLI is matched this will return all contacts who owns the phone or mobile number<br />' + 
                    'Where a CLI is not provided and an account is matched, this will return all contacts associated to the account.';

        // added by Tim Fabros 06 / 06 / 2014 - SFE-143
        // included additional messages to check if case contains account and contact
        // or if no accounts/contacts could be found.
        // BEGIN:
        if (currCase.AccountId != null && currCase.ContactId != null)
        {
            msg += '<br /><br /><b>If you wish to change the contact, please remove the contact from this record and Save.</b>';
        }
        if (accountsFound != null && accountsFound.isEmpty())
        {
            msg += '<br /><b>Could not find any related Account record(s)</b>';
        }
        if (contactsFound != null && contactsFound.isEmpty())
        {
            msg += '<br /><b>Could not find any related Contact record(s)</b>';
        }
        // END:
        
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Info, msg));
        
    } 


    private void searchForContactByAccount(Id accountId)
    {
        system.debug('@ searchForContactByAccount()');
        contactsFound = [SELECT id, accountId, account.Name,
                                Name, Phone, Email, Email_Secondary__c, MobilePhone,
                                MailingStreet, MailingCountry,
                                MailingPostalCode, MailingState,
                                MailingCity
                        FROM    Contact
                        WHERE   accountId = :accountId 
                            AND Contact_Status__c='Active'];
        system.debug('@ searchForContactByAccount() contactsFound:' + contactsFound);                       
    }



    private void searchForAccountsAndContactByPhoneNumber(Case inCase)
    {
        system.debug('@ searchForAccountsAndContactByPhoneNumber()');
        accountsFound = new list<Account>();
        contactsFound = new list<Contact>();

        if(inCase.cLI__c.trim().length()>=MINCHARLENGTH)
        {
            // modified by Tim Fabros 2014-10-21: SFE-643
            // added AccountNumber, ABN_Exempt__c, RecordType.Name to query
            String searchQueryPhone='FIND \'' + String.escapeSingleQuotes(inCase.cLI__c) +
                                       '*\' IN PHONE FIELDS '+
                                       'RETURNING Account(id, Name, Phone, PersonEmail, BillingStreet, BillingCountry, ' +
                                                             'BillingPostalCode, BillingState, BillingCity, AccountNumber, ABN_Exempt__c, RecordType.Name ORDER BY Name), ' +
                                        'Contact(id, accountId, account.Name,  Name, Phone, Email, Email_Secondary__c, MobilePhone, MailingStreet, MailingCountry, ' +
                                                         'MailingPostalCode, MailingState, MailingCity';

            if(inCase.accountId!=null)
                    searchQueryPhone += ' WHERE accountId =\'' + inCase.AccountId + '\'';           


                    searchQueryPhone += ' ORDER By account.Name, Name)';
            
            system.debug('@ searchForAccountsAndContactByPhoneNumber() searchQueryPhone: ' +  searchQueryPhone);

            list<list<sObject>> results = search.query(searchQueryPhone);
            system.debug('@ searchForAccountsAndContactByPhoneNumber() phone results: ' +  results);
            system.debug('@ searchForAccountsAndContactByPhoneNumber() phone results size: ' +  results.size());
            
            if(results.size() > 0)
            {
                accountsFound = (list<Account>) results[0];
                contactsFound = (list<Contact>) results[1];
            }

        }
    }

    private void searchForAccountsAndContactByEmail(Case inCase)
    {
        system.debug('@ searchForAccountsAndContactByEmail()');
        accountsFound = new list<Account>();
        contactsFound = new list<Contact>();

        if(inCase.SuppliedFromEmail_text__c.trim().length()>=MINCHARLENGTH)
        {
            // modified by Tim Fabros 2014-10-21: SFE-643
            // added AccountNumber, ABN_Exempt__c, RecordType.Name to query
            String searchQueryEmail='FIND \'' + String.escapeSingleQuotes(inCase.SuppliedFromEmail_text__c) +
                                       '*\' IN EMAIL FIELDS '+
                                       'RETURNING Account(id, Name, Phone, PersonEmail, BillingStreet, BillingCountry, ' +
                                                             'BillingPostalCode, BillingState, BillingCity, AccountNumber, ABN_Exempt__c, RecordType.Name ORDER BY Name), ' +
                                        'Contact(id, accountId, account.Name,  Name, Phone, Email, Email_Secondary__c, MobilePhone, MailingStreet, MailingCountry, ' +
                                                         'MailingPostalCode, MailingState, MailingCity';

            if(inCase.accountId!=null)
                    searchQueryEmail += ' WHERE accountId =\'' + inCase.AccountId + '\'';           


                    searchQueryEmail += ' ORDER By account.Name, Name)';
            
            system.debug('@ searchForAccountsAndContactByEmail() searchQueryEmail: ' +  searchQueryEmail);

            list<list<sObject>> results = search.query(searchQueryEmail);
            system.debug('@ searchForAccountsAndContactByEmail() email results: ' +  results);
            
            if(results.size() > 0)
            {
                accountsFound = (list<Account>) results[0];
                contactsFound = (list<Contact>) results[1];
            }

        }
    }

    // grab the selected contact and add to the case
    public void doSelectContact()
    {
        system.debug('@ doSelectContact()');
        if(ApexPages.currentPage().getParameters().get('selectedContactId')!=null)
        {
            currCase.contactId = ApexPages.currentPage().getParameters().get('selectedContactId');
        }

        doSelectAccount();
    }

    // grab the account and add to the case
    public void doSelectAccount()
    {
        system.debug('@ doSelectAccount()');
        if(ApexPages.currentPage().getParameters().get('selectedAccountId')!=null)
        {
            currCase.accountId = ApexPages.currentPage().getParameters().get('selectedAccountId');
        }

        init();

        // added by Tim Fabros 06 / 06 / 2014 - SFE-143
        // included save function to update the case when add button is pressed
        // BEGIN:
        save();
        // END:
    }


    public PageReference save()
    {
        PageReference pr = null;
        try
        {
            update currCase;
            
            // set page reference back to case origin
            if(isVf && refTabId==null)
                pr = new PageReference('/' + currCase.id);          
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Case did not save.\n'));
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ex.getMessage()));
        }
        return pr;      
    }


    public PageReference cancel()
    {
        PageReference pr = null;
        if(refTabId==null)
            pr = new PageReference('/' + currCase.id);
        return pr;
    }


    //new contact
    public void showAddNewContactFlag()
    {
        system.debug('@ showAddNewContact()');
        //Check if there is an account if not show the search/create account 
        if(currCase.accountId!=null)
        {
            system.debug('@ showAddNewContact() currCase.accountId!=null');
            showAddNewContactFlag=true;
            newContact = new Contact();
            newContact.Accountid = currCase.accountId;
            newContact.Contact_Status__c = 'Active';
         }
         else
         {
            system.debug('@ showAddNewContact() currCase.accountId==null');
            accountsFound = new list<Account>();
            setConMap.remove('AccountList');
            contactsFound = new list<Contact>();
            setConMap.remove('ContactList');
         }
    }

    public void cancelAddNewContact()
    {
        system.debug('@ cancelAddNewContact()');
        showAddNewContactFlag=false;
        newContact = new Contact();
        newContact.Accountid = currCase.accountId;
        newContact.Contact_Status__c = 'Active';

        currCase.accountId = null;
        update currCase;
    }

    public void saveAddNewContact()
    {
        system.debug('@ saveAddNewContact()');

        try
        {
            showAddNewContactFlag=false;
            upsert NewContact;
            currCase.contactid = NewContact.id;
            //added by shri to update the case
            update currCase;
        }
        catch (Exception ex)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        }
    }

    public void saveAddnewAccount()
    {
        system.debug('@ saveAddnewAccount()');
        CreateAccountComponentController.saveAddnewAccount();
        currCase.accountId = CreateAccountComponentController.newAccount.id;
    }


    // navigation
    private map<String,ApexPages.StandardSetController> setConMap = new map<String,ApexPages.StandardSetController>();

    private Integer calculateListSize(String key)
    {
        Decimal d = Decimal.valueOf(setConMap.get(key).getResultSize()) / Decimal.valueOf(setConMap.get(key).getPageSize());
        d = d.round(System.RoundingMode.UP);
        
        return Integer.valueOf(d);
    }

    // Contact Navigation
    public list<Contact> getcontactsFound() 
    {
        system.debug('@ getcontactsFound()');

        list<Contact> cnts = new list<Contact>();

        system.debug('@ getcontactsFound() contactsFound:' + contactsFound);

        if(contactsFound!=null && contactsFound.size() > 0 && !setConMap.containsKey('ContactList'))
        {
            system.debug('@ getcontactsFound() set con');
            ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(contactsFound);
            setCon.setPageSize(PAGESIZE);
            setConMap.put('ContactList', setCon);   

        }

        if(setConMap.containsKey('ContactList'))
        {
            cnts = setConMap.get('ContactList').getRecords();    
        }

        system.debug('@ getcontactsFound() cnts:' +  cnts);
        return cnts;
    }

    public void setcontactsFound(list<Contact> value)
    {
        contactsFound = value;  
    }

    public integer getContactListSize()
    {
        return setConMap.containsKey('ContactList')?calculateListSize('ContactList'):0;

    } 

    public integer getContactListCurrentPage()
    {
        return setConMap.containsKey('ContactList')?setConMap.get('ContactList').getPageNumber():0;
    }
    
    public void contactPreviousPage()
    {
        setConMap.get('ContactList').previous();
    }   

    public void contactNextPage()
    {
        setConMap.get('ContactList').next();
    }   
    
    
    public boolean getContactListHasNext()
    {
        return setConMap.containsKey('ContactList')?setConMap.get('ContactList').getHasNext():false;
    }

    public boolean getContactListHasPrevious()
    {
        return setConMap.containsKey('ContactList')?setConMap.get('ContactList').getHasPrevious():false;
    }



    //Account Navigation
    public list<Account> getAccountsFound() 
    {
        system.debug('@ getAccountsFound()');
        list<Account> accts = new list<Account>();

        system.debug('@ getAccountsFound() AccountsFound:' + AccountsFound);

        if(AccountsFound!=null && AccountsFound.size() > 0 && !setConMap.containsKey('AccountList'))
        {
            system.debug('@ getAccountsFound() set con');
            ApexPages.StandardSetController setCon = new ApexPages.StandardSetController(AccountsFound);
            setCon.setPageSize(PAGESIZE);
            setConMap.put('AccountList', setCon);   

        }

        if(setConMap.containsKey('AccountList'))
        {
            accts = setConMap.get('AccountList').getRecords();    
        }

        system.debug('@ getcontactsFound() accts:' + accts);
        return accts;
    }

    public void setAccountsFound(list<Account> value)
    {
        accountsFound = value;  
    }

    public integer getAccountListSize()
    {
        return setConMap.containsKey('AccountList')?calculateListSize('AccountList'):0;

    } 

    public integer getAccountListCurrentPage()
    {
        return setConMap.containsKey('AccountList')?setConMap.get('AccountList').getPageNumber():0;
    }
    
    public void AccountPreviousPage()
    {
        setConMap.get('AccountList').previous();
    }   

    public void AccountNextPage()
    {
        setConMap.get('AccountList').next();
    }   
    
    
    public boolean getAccountListHasNext()
    {
        return setConMap.containsKey('AccountList')?setConMap.get('AccountList').getHasNext():false;
    }

    public boolean getAccountListHasPrevious()
    {
        return setConMap.containsKey('AccountList')?setConMap.get('AccountList').getHasPrevious():false;
    }
}
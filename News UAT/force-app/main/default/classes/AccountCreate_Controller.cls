public with sharing class AccountCreate_Controller  extends ComponentControllerBase{

    public String bookingSourceSystem { get; set;}
    public boolean showAddnewAccountFlag {public get{return showAddnewAccountFlag = showAddnewAccountFlag!=null?showAddnewAccountFlag:false;} private set;}
    public Account newAccount
    {
        get
        {
            if(newAccount==null)
            {
                newAccount =new Account();
                newAccount.BillingCountry = 'Australia';
            }
            return newAccount;
        }
        set;
    }

	public Contact contactProxy{get{return contactProxy = contactProxy != null ? contactProxy : new Contact();}set;}

    public AccountCreate_Controller()
    {
    	system.debug('@ constructor ');
    	accountRecordTypeById = new map<String, String>();
    	for (RecordType rt : [SELECT Id, Name, DeveloperName, SobjectType FROM RecordType WHERE SobjectType = 'Account']) {
    		if(rt.DeveloperName != 'Agency_Account_Type')
    	         accountRecordTypeById.put(rt.id, rt.name);
    	}
    }
     

    private String accountSelectedRectype;
    public String getAccountSelectedRectype()
    {
            system.debug('@ getAccountSelectedRectype() ');
            system.debug('accountRecordTypeById: ' + accountRecordTypeById);

            if(accountSelectedRectype!=null)
            {
                if(accountRecordTypeById.containsKey(accountSelectedRectype))
                    accountSelectedRectypeName = accountRecordTypeById.get(accountSelectedRectype);
            }

            system.debug('accountSelectedRectypeName:' + accountSelectedRectypeName);
            system.debug('accountSelectedRectype:' + accountSelectedRectype);

            return accountSelectedRectype;
    }

    public void setAccountSelectedRectype(String selection)
    {
        system.debug('@ setAccountSelectedRectype(String selection) ');
        accountSelectedRectype = selection;
    }


    public String accountSelectedRectypeName{
        public get
        {
            if(accountSelectedRectype!=null)
            {
                if(accountRecordTypeById.containsKey(accountSelectedRectype))
                    accountSelectedRectypeName = accountRecordTypeById.get(accountSelectedRectype);
            }

            return accountSelectedRectypeName;
        }

        private set;
    }

	public map<String, String> accountRecordTypeById;
	
    public List<selectOption> accountRecordTypeOptions {
        get {
            List<selectOption> myRecordTypes = new List<selectOption>();
            myRecordTypes.add(new selectOption('','--select account type--'));
            for (String rtId : accountRecordTypeById.keySet())
            {
            	if(accountRecordTypeById.get(rtId) != 'Private Party' ||
            	   (accountRecordTypeById.get(rtId) == 'Private Party' && bookingSourceSystem != 'AdPoint'))
            	{
            		myRecordTypes.add(new selectOption(rtId, accountRecordTypeById.get(rtId)));
            	}
            }
            
            if(bookingSourceSystem == 'AdPoint')
            {
            	AccountSelectedRectype = myRecordTypes[1].getValue();
            }
            
            return myRecordTypes;
        }
        private set;
    }


	public void cancelAddnewAccount()
    {
        showAddnewAccountFlag=false;
        newAccount = new Account();
        newAccount.BillingCountry = 'Australia';
    }

    public void saveAddnewAccount()
    {
        try
        {
            if(accountSelectedRectypeName == 'Private Party')
            {
                newAccount.FirstName = contactProxy.FirstName;  
                newAccount.LastName = contactProxy.LastName;
                newAccount.PersonMailingStreet = newAccount.BillingStreet;
                newAccount.PersonMailingState = newAccount.BillingState;
                newAccount.PersonMailingPostalCode = newAccount.BillingPostalCode;
                newAccount.PersonMailingCountry = newAccount.BillingCountry;
                newAccount.PersonMailingCity = newAccount.BillingCity;
            }
            
            newAccount.recordTypeId = AccountSelectedRectype;
            insert newAccount;
            
            // call page controller method from component controller
            PageControllerBase pageCtr = this.pageController;
            
            if (pageCtr instanceof SalesOrderCreateBookingv2_ControllerX) 
            {
                SalesOrderCreateBookingv2_ControllerX bookingCtr = (SalesOrderCreateBookingv2_ControllerX)pageCtr;
                bookingCtr.populateSelectedAdvertiser();
            } 

            showAddnewAccountFlag=false;

        }
        catch (Exception ex)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
        }
    }

    public void showAddnewAccount()
    {
        system.debug('@ AccountSelectedRectype()');
        system.debug('AccountSelectedRectype:' + AccountSelectedRectype);
        if(AccountSelectedRectype != '')
        {
            showAddNewAccountFlag=true;
            newAccount = new Account();
            newAccount.recordTypeId = AccountSelectedRectype;
            newAccount.BillingCountry = 'Australia';

        }
        else
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Please select a account type'));
        }
    }

}
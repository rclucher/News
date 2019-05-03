public without sharing class ExternalAccountCreateBA_Controller extends PageControllerBase {
    
    //public Sales_Order__c so {get {return so = so!=null?so:new Sales_order__c();}set;}	
    
    public External_Account__c externalAccountAdvertiserProxy {get{return externalAccountAdvertiserProxy = externalAccountAdvertiserProxy!=null?externalAccountAdvertiserProxy:new External_Account__c();} set;} 
    public External_Account__c externalAccountPayerProxy {get{return externalAccountPayerProxy = externalAccountPayerProxy!=null?externalAccountPayerProxy:new External_Account__c();} set;} 
    
    
    public String bookingType {get;set;}
    
    private Id pAccountSourceId;
    private Account pAccountSource;
    public Account accountSource {
        get
        {
            return pAccountSource;
        }
    }
    
    
    public Account selectedAdvertiser 
    {
        get
        {
            system.debug('@ selectedAdvertiser get');
            system.debug('@ selectedAdvertiser get SearchAccountComponentController:' + SearchAccountComponentController);
            system.debug('@ selectedAdvertiser get SearchAccountComponentController.selectedAccount:' + SearchAccountComponentController.selectedAccount);
            
            if(SearchAccountComponentController!=null && 
               SearchAccountComponentController.selectedAccount.id!=null)
            {
                externalAccountAdvertiserProxy.Customer_Account__c = SearchAccountComponentController.selectedAccount.id;
                selectedAdvertiser = queryForAccount(SearchAccountComponentController.selectedAccount.id);
            }
            system.debug('@ selectedAdvertiser get selectedAdvertiser:' + selectedAdvertiser);
            return selectedAdvertiser;
        }
        set;
    } 
    
    public Account selectedPayer {get;set;} 
    
    
    public boolean getIsDirect()
    {
        return bookingType == 'Direct';
    }
    
    public boolean getIsIndirect()
    {
        return bookingType == 'Indirect';
    }
    
    
    // Toggle Header and Sidebar visibility based on passed querystring parameter s
    public boolean showHeaderAndSidebar {
        get
        {
            showHeaderAndSidebar = false;
            if(ApexPages.currentPage().getParameters().get('s')!=null)
            {
                showHeaderAndSidebar = Boolean.valueOf(ApexPages.currentPage().getParameters().get('s'));
            }
            return showHeaderAndSidebar;
        }
        set;
    }
    
    public ExternalAccountCreateBA_Controller(ApexPages.StandardController controller) {
        this.init();
    }	
    
    public ExternalAccountCreateBA_Controller()
    {
        this.init();
    }
    
    private void init()
    {
        system.debug('@ init');
        externalAccountAdvertiserProxy = new External_Account__c();
        externalAccountPayerProxy = new External_Account__c();
        
        
        if(ApexPages.currentPage().getParameters().get('caseId')!=null &&
           ApexPages.currentPage().getParameters().get('caseId').trim().length()>0)
        {
            system.debug('@ init ApexPages.currentPage().getParameters().get(\'caseId\'):' + ApexPages.currentPage().getParameters().get('caseId'));
            pAccountSourceId = queryForCaseAccount(ApexPages.currentPage().getParameters().get('caseId'));
        }
        else if(ApexPages.currentPage().getParameters().get('acctId')!=null &&
                ApexPages.currentPage().getParameters().get('acctId').trim().length()>0)
        {
            system.debug('@ init ApexPages.currentPage().getParameters().get(\'acctId\'):' + ApexPages.currentPage().getParameters().get('acctId'));
            pAccountSourceId = ApexPages.currentPage().getParameters().get('acctId');	
        }	
    }
    
    
    ////// List Options - Start ///////
    //Available GBA types for creation
    private list<SelectOption> GBATypes;
    public list<SelectOption> getGBATypes()
    {
        GBATypes = new list<SelectOption>();
        GBATypes.add(new SelectOption('', '--select--'));
        GBATypes.add(new SelectOption('Direct', 'Direct'));
        GBATypes.add(new SelectOption('Indirect', 'Agency'));
        return GBATypes;
    }
    ////// List Options - End ///////
    
    
    
    
    ////// Actions - Start ///////
    public void onBookingTypeChange()
    {
        system.debug('@ onBookingTypeChange');
        system.debug('@ onBookingTypeChange pAccountSourceId:' + pAccountSourceId);
        if(pAccountSourceId!=null)
        {
            pAccountSource = queryForAccount(pAccountSourceId);
            system.debug('@ onBookingTypeChange pAccountSource:' + pAccountSource);
            if(pAccountSource!=null)
            {
                externalAccountAdvertiserProxy.Customer_Account__c = pAccountSource.id;
                selectedAdvertiser = pAccountSource;
                externalAccountPayerProxy.Customer_Account__c = accountSource.id;
                selectedPayer = accountSource;
                
                system.debug('@ onBookingTypeChange accountSource:' + accountSource);
                system.debug('@ onBookingTypeChange selectedAdvertiser:' + selectedAdvertiser);
                
                system.debug('@ onBookingTypeChange	getIsIndirect():' + getIsIndirect());
                if(getIsIndirect() && accountSource.recordType.DeveloperName == 'Agency_Account_Type')
                {	
                    system.debug('@ onBookingTypeChange accountSource.recordType.DeveloperName:' + accountSource.recordType.DeveloperName);
                    externalAccountAdvertiserProxy.Customer_Account__c = null;
                    selectedAdvertiser = null;
                    
                }
                else if(getIsIndirect() && accountSource.recordType.DeveloperName != 'Agency_Account_Type')
                {
                    system.debug('@ onBookingTypeChange accountSource.recordType.DeveloperName:' + accountSource.recordType.DeveloperName);
                    externalAccountPayerProxy.Customer_Account__c = null;
                    selectedPayer = null;
                    
                } 
                
                system.debug('@ onBookingTypeChange	externalAccountPayerProxy.Customer_Account__c:' + externalAccountPayerProxy.Customer_Account__c);
                if(getIsIndirect() && externalAccountPayerProxy.Customer_Account__c == null)
                {
                    ExternalAccountFormComponentController.gbaAccount = new External_Account__c();
                    ExternalAccountFormComponentController.showAddNewGBAFlag = false;
                }
                
            }
            
        }	
    }
    
    
    public void onPayerChange()
    {
        system.debug('@ onPayerChange');
        Account tAcct = queryForAccount(externalAccountPayerProxy.Customer_Account__c);
        selectedPayer = tAcct;
    }
    
    public PageReference doCancelAndRedirectToSource()
    {
        PageReference pr = null;
        
        
        if(ApexPages.currentPage().getParameters().get('caseId')!=null &&
           ApexPages.currentPage().getParameters().get('caseId').trim().length()>0)
        {
            pr = new PageReference('/' + ApexPages.currentPage().getParameters().get('caseId').trim());
        }
        else if(ApexPages.currentPage().getParameters().get('acctId')!=null &&
                ApexPages.currentPage().getParameters().get('acctId').trim().length()>0)
        {
            pr = new PageReference('/' + ApexPages.currentPage().getParameters().get('acctId').trim());
        }
        
        return pr;
    }
    
    /*
public void doSelectAdvertiser()
{
Account tAcct = queryForAccount(so.Advertiser_Account__c);
selectedAdvertiser = tAcct;
}
*/	
    
    
    ////// Actions - END ///////
    
    private Account queryForAccount(ID acctId)
    {
        Account acct;
        try{
            acct = [Select	id, 
                    Name,
                    FirstName,
                    LastName,
                    recordType.DeveloperName,
                    Primary_Contact__c,
                    RecordType.name,
                    BillingPostalCode,
                    BillingCountry,
                    BillingState,
                    BillingStreet,
                    BillingCity,
                    DPID_Primary_Address__c ,
                    Revenue_Group__c,
                    AccountNumber,
                    Phone,
                    PersonMailingStreet,
                    PersonMailingState,
                    PersonMailingPostalCode,
                    PersonMailingCountry, 
                    PersonMailingCity,
                    PersonHomePhone,
                    DPID_Primary_Address__pc,
                    IsPersonAccount 
                    from Account 
                    Where id = :acctId
                    LIMIT 1];
            
        }
        catch(System.QueryException qex)
        {
            system.debug('Invalid account');
        }
        
        return acct;
    }
    
    private ID queryForCaseAccount(ID caseId)
    {
        Id acctId;
        try
        {
            Case c;
            c = [Select Accountid from Case Where id = :caseId];
            if(c.Accountid!=null)
            {
                acctId = c.Accountid;
            }
        }
        catch(System.QueryException qex)
        {
            system.debug('Invalid Case');
        }
        
        return acctId;
    }
    
    
    
    ////// Get User settigns - Start ///////
    //Check if user can access cybersell 
    public boolean isCyberSellEnabled {get;private set;}
    
    public boolean canCreateGBA {get{ return canCreateGBA = (UserSettings_Helper.createGBAType!='None');}private set;}
    
    public void ExternalAccountInitCreateBookingAccount()
    {
        isCyberSellEnabled = (UserSettings_Helper.isCyberSellEnabled && UserSettings_Helper.createGBAType!='None') ;
        if(!isCyberSellEnabled)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You have no permission to create a new System Booking Account for Genera!'));
        }
    }
    ////// Get User settigns - End ///////    
    
    
    
    
    ////// PageControllerBase - Start ///////
    
    public AccountSearch_Controller SearchAccountComponentController
    { 
        get
        {
            system.debug('@ SearchAccountComponentController get');
            system.debug('@ SearchAccountComponentController get getComponentControllerMap():' + getComponentControllerMap());
            if(getComponentControllerMap()!=null)
            {
                AccountSearch_Controller mcc;
                mcc = (AccountSearch_Controller) getComponentControllerMap().get('AccountSearch');
                system.debug('@ SearchAccountComponentController get mcc:' + mcc);
                if(mcc!= null)
                    return mcc;	
            }
            system.debug('@ SearchAccountComponentController get returning new AccountSearch_Controller()');
            return new AccountSearch_Controller();
        } 
        set;
    }
    
    
    public ExternalAccountForm_Controller ExternalAccountFormComponentController
    { 
        get
        {
            if(getComponentControllerMap()!=null)
            {
                ExternalAccountForm_Controller mcc;
                mcc = (ExternalAccountForm_Controller) getComponentControllerMap().get('externalAccountForm');
                if(mcc!= null)
                    return mcc;	
            }
            return new ExternalAccountForm_Controller();
        } 
        set;
    }		  
    
    //// Custom components - End ////
    
    /*
public AccountSearch_Controller SearchAccountComponentController { get; set; }

public override void setComponentController(ComponentControllerBase compController) {
SearchAccountComponentController = (AccountSearch_Controller) compController;
}

public override ComponentControllerBase getComponentController() {
return SearchAccountComponentController;
}
*/
    ////// PageControllerBase - End ///////
    
    
}
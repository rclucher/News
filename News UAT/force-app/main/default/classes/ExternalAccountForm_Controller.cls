public with sharing class ExternalAccountForm_Controller  extends ComponentControllerBase{
    
    public External_Account__c gbaAccount {get{return gbaAccount = gbaAccount!=null?gbaAccount:new External_Account__c();}set;}
    
    
    public Account selectedAdvertiser {get;
                                       set
                                       {
                                           system.debug('@ selectedAdvertiser');
                                           system.debug('@ selectedAdvertiser selectedAdvertiser: ' + selectedAdvertiser);
                                           system.debug('@ selectedAdvertiser value: ' + value);           
                                           if(selectedAdvertiser==null || selectedAdvertiser!=value)
                                           {
                                               system.debug('@ selectedAdvertiser in');
                                               selectedAdvertiser = value;
                                               init();
                                           }
                                       }
                                      }
    
    
    
    public Account selectedPayer {get;
                                  set
                                  {
                                      
                                      system.debug('@ selectedPayer');
                                      system.debug('@ selectedPayer selectedPayer: ' + selectedPayer);
                                      system.debug('@ selectedPayer value: ' + value);                        
                                      if(selectedPayer==null || selectedPayer!=value)
                                      {
                                          system.debug('@ selectedPayer in');
                                          selectedPayer = value;              
                                          init();
                                      }
                                  }
                                 }
    
    public Boolean isAgency {get;set;}
    
    public String phoneCountryCode {get;set;}
    public String phoneAreaCode {get;set;}
    public String phone {get;set;}
    
    public List<String> selectedDivisions {get{return selectedDivisions = selectedDivisions==null?new list<String>():selectedDivisions;} set;}
    
    public Boolean showDivisions {get;set;}
    public Boolean showOwningCreditDivisions {get;set;}
    public boolean isABNRequired {get;set;}
    
    public Boolean showAddNewGBAFlag {get;set;}
    public Boolean redirectToPage {get;set;}
    
    private External_Account__c parentAccount;
    
    private ExternalAccountCreateGBA_Helper gbaHelper;
    
    private Boolean isSaving;
    
    private boolean isCurrentAgency;
    
    public map<String, Genera_Account_Type_Mapping__c> availableGBATypeMap
    {
        get
        {
            //if(availableGBATypeMap==null)
            //{
            availableGBATypeMap = new map<String, Genera_Account_Type_Mapping__c>();
            string createGBATypes = UserSettings_Helper.createGBAType;
            
            System.debug('@ExternalAccountForm_Controller availableGBATypeMap parentAccount: ' + parentAccount);
            
            for(Genera_Account_Type_Mapping__c gbaType : Genera_Account_Type_Mapping__c.getAll().values())
            {
                if((createGBATypes=='Sales' && gbaType.CreatedBySales__c) ||
                   (createGBATypes=='NFSS' && gbaType.CreatedByNFSS__c))
                {
                    
                    if((isAgency 
                        && ((gbaType.Parent__c!= null && gbaType.Parent__c.Trim().length()>0) ||
                            gbaType.Name == 'Request for Established')) 
                       ||(!isAgency && gbaType.Parent__c== null))
                    {
                        
                        if((parentAccount != null) && isAgency) {
                            System.debug('@ExternalAccountForm_Controller availableGBATypeMap parentAccount.Account_Type__c: ' + parentAccount.Account_Type__c);
                            if(gbaType.Parent__c==parentAccount.Account_Type__c)
                                availableGBATypeMap.put(gbaType.Name, gbaType);
                        }
                        else if(!isAgency)
                        {
                            if (gbaType.Name == 'Contra')
                            {
                                if(UserSettings_Helper.profileName.contains('System Administrator'))
                                {
                                    availableGBATypeMap.put(gbaType.Name, gbaType);
                                }
                                else
                                {
                                    for (CyberAd_User_Credential__c c : UserSettings_Helper.cyberSellSettings)
                                    {
                                        if(String.isNotBlank(c.Create_GBA_Types__c) && c.Create_GBA_Types__c  == 'NFSS')
                                        {
                                            availableGBATypeMap.put(gbaType.Name, gbaType);
                                            break;
                                        }
                                    }
                                }
                            }
                            else
                            {
                                availableGBATypeMap.put(gbaType.Name, gbaType);
                            }
                        }
                    }//else if(!isAgency)
                    //     availableGBATypeMap.put(gbaType.Name, gbaType);
                }
            }
            //}
            System.debug('@ExternalAccountForm_Controller availableGBATypeMap: '+ availableGBATypeMap);
            return  availableGBATypeMap;
        }
        set;
    }
    
    
    public List<selectOption> gbaAccountTypeOptionsForSelectAdvertiser {
        get {
            //if(gbaAccountTypeOptionsForSelectAdvertiser==null)
            //{
            gbaAccountTypeOptionsForSelectAdvertiser = new List<selectOption>();
            
            for(Genera_Account_Type_Mapping__c gbaType : availableGBATypeMap.values())
            {
                gbaAccountTypeOptionsForSelectAdvertiser.add(new selectOption(gbaType.Name, gbaType.Name));
            }
            
            if(gbaAccountTypeOptionsForSelectAdvertiser.size()>1)
            {
                gbaAccountTypeOptionsForSelectAdvertiser.add(0, new selectOption('', '--select--'));
            }
            //}
            
            
            return gbaAccountTypeOptionsForSelectAdvertiser;
        }
        private set;
    }
    
    
    
    
    public List<selectOption> gbadefaultRevenueGroupGeneraOptions {
        get {
            List<selectOption> gbadefaultRevenueGroupGeneraOptions = new List<selectOption>();
            gbadefaultRevenueGroupGeneraOptions.add(new selectOption('', '--select--'));
            map<String,Genera_Revenue_Groups__c> grgMap = Genera_Revenue_Groups__c.getAll(); 
            list<String> keys = new list<String>();
            keys.addAll(Genera_Revenue_Groups__c.getAll().keySet());
            keys.sort(); 
            for(String key : keys)
            {
                gbadefaultRevenueGroupGeneraOptions.add(new selectOption(grgMap.get(key).Name,grgMap.get(key).Account_Revenue_Group_Value__c));
            }
            return gbadefaultRevenueGroupGeneraOptions;
        }
        private set;
    }
    
    
    
    public List<selectOption> gbaDivisionOptions {
        get {
            List<selectOption> gbaDivisionOptions = new List<selectOption>();
            
            /*** Updated by Bohao Chen on 2/04/2014 *****/
            
            for(CyberAd_User_Credential__c c : UserSettings_Helper.cyberSellSettings)
            {
                system.debug('@ExternalAccountForm_Controller gbaDivisionOptions: ' + c.CyberSell_Divisions__c);
                
                if(String.isNotBlank(c.CyberSell_Divisions__c))
                {
                    List<String> divisionList = c.CyberSell_Divisions__c.split(';');
                    
                    if(divisionList.size() > 0)
                    {
                        for(String d : divisionList)
                        {
                            gbaDivisionOptions.add(new selectOption(d,d));
                        }
                    }
                    else
                    {
                        gbaDivisionOptions.add(new selectOption(c.CyberSell_Divisions__c, c.CyberSell_Divisions__c));
                    }
                }
            }
            
            if(gbaDivisionOptions.size() > 0)
            {
                gbaDivisionOptions.add(0, new selectOption('', '--select--'));
            }
            /**** Updated by Bohao Chen ****/
            
            return gbaDivisionOptions;
        }
        private set;
    }
    
    
    
    
    
    
    ///Constructor
    
    public ExternalAccountForm_Controller()
    {
        gbaHelper = new ExternalAccountCreateGBA_Helper();
        isSaving = false;
    }
    
    
    
    public void init()
    {   
        system.debug('@ init');
        system.debug('@ init selectedAdvertiser:' + selectedAdvertiser);
        system.debug('@ init selectedPayer:' + selectedPayer);
        system.debug('@ init isAgency:' + isAgency);
        system.debug('@ init isCurrentAgency:' + isCurrentAgency);
        system.debug('@ init gbaAccount:' + gbaAccount);
        system.debug('@ init gbaAccount.id:' + gbaAccount.id);
        system.debug('@ init isSaving:' + isSaving);
        
        if(gbaAccount.id != null || isSaving)
            return;
        
        
        if(selectedAdvertiser==null || selectedPayer==null)
            return;
        
        if(isCurrentAgency!=null && (isAgency != isCurrentAgency))
        {
            gbaAccount = new External_Account__c();
            isCurrentAgency = isAgency;                     
        }   
        
        gbaAccount.Customer_Account__c = selectedAdvertiser.id;
        
        prepopulateExternalAccountFromAccount();
        
        list<External_Account__c> parentGBAlist = gbaHelper.getAccountDirectExternalAccount(    selectedPayer,      // @accId
                                                                                            'Booking_Account'   // @externalAccountRecordTypeDeveloperName
                                                                                           );
        
        
        system.debug('parentGBAlist: ' + parentGBAlist);
        system.debug('isAgency: ' + isAgency);       
        
        if(isAgency && (parentGBAlist==null || parentGBAlist.size()==0))
        {
            system.debug('ERROR: External Account for selected payer does not exist');  
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'You cannot proceed, parent External Account for selected payer does not exist'));
            showAddNewGBAFlag=false;
        }
        else
        {
            showAddNewGBAFlag=true;
        }
        
        system.debug('showAddNewGBAFlag: ' + showAddNewGBAFlag);       
        
    }
    
    
    
    
    public void onParentAccountSelection()
    {
        system.debug('@ parentAccountSelected()');
        if(gbaAccount.External_Account__c != null &&
           (parentAccount==null || gbaAccount.External_Account__c!=parentAccount.id))
        {
            parentAccount = [select id, Account_Type__c from External_Account__c where id=:gbaAccount.External_Account__c];
            
            system.debug('@onParentAccountSelection parentAccount: ' + parentAccount);
            system.debug('@onParentAccountSelection availableGBATypeMap: ' + availableGBATypeMap);
            
            for(Genera_Account_Type_Mapping__c gbaType : availableGBATypeMap.values())
            {
                system.debug('gbaType.parent__c: ' + gbaType.parent__c);
                system.debug('parentAccount.Account_Type__c: ' + parentAccount.Account_Type__c);
                
                if(gbaType.parent__c == parentAccount.Account_Type__c)
                {
                    gbaAccount.Account_Type__c = gbaType.Name;
                    onAccountTypeSelection();
                    system.debug('gbaAccount.Account_Type__c: ' + gbaAccount.Account_Type__c);
                }
            }
            system.debug('parentAccount: ' + parentAccount);
        }
        
    }
    
    
    public void onAccountTypeSelection()
    {
        system.debug('@ onAccountTypeSelection()');
        system.debug('gbaAccount.Account_Type__c: ' + gbaAccount.Account_Type__c);
        
        showDivisions = false;
        showOwningCreditDivisions = false;
        
        if(gbaAccount.Account_Type__c!=null && gbaAccount.Account_Type__c.trim().length()>0)
        {
            map<String, Genera_Account_Type_Mapping__c> gbaTypes = Genera_Account_Type_Mapping__c.getAll();
            if(gbaTypes.containskey(gbaAccount.Account_Type__c))
            {
                system.debug('gbaTypes.get(gbaAccount.Account_Type__c).Request_Account_Divisions__c: ' + gbaTypes.get(gbaAccount.Account_Type__c).Request_Account_Divisions__c);
                
                
                //Set Division
                if(gbaTypes.get(gbaAccount.Account_Type__c).Request_Account_Divisions__c=='Y')
                {
                    showDivisions = true;
                }
                else if(gbaTypes.get(gbaAccount.Account_Type__c).Request_Account_Divisions__c=='N')
                {
                }
                else if(gbaTypes.get(gbaAccount.Account_Type__c).Request_Account_Divisions__c=='ALL')
                {
                    selectedDivisions = UserSettings_Helper.cyberSellSettings[0].CyberSell_Divisions__c.split(';');
                }
                else
                {
                    selectedDivisions = new list<string>();
                }
                
                
                //Set Owning Credit Division
                if(gbaTypes.get(gbaAccount.Account_Type__c).Owning_Credit_Division__c=='Y')
                {
                    showOwningCreditDivisions = true;
                }
                else if(gbaTypes.get(gbaAccount.Account_Type__c).Owning_Credit_Division__c=='N')
                {
                }              
                else
                {
                    gbaAccount.Owning_Credit_Division__c = gbaTypes.get(gbaAccount.Account_Type__c).Owning_Credit_Division__c;
                }

        // ADSALES-00048  2016-08-31 darshan.gosar@bluewolfgroup.com 
              // Added new Account Type as NewsPay for showing division & owning credit division with default selected picklist value as National                 
                if(gbaAccount.Account_Type__c == 'NewsPay'){
                    selectedDivisions = new List<String>{'National'};
                    gbaAccount.Owning_Credit_Division__c = gbaTypes.get(gbaAccount.Account_Type__c).Owning_Credit_Division__c;
                    showOwningCreditDivisions = true;
                    showDivisions = true;                    
                }
                
                //Set ABN required
                isABNRequired = gbaTypes.get(gbaAccount.Account_Type__c).isABNRequired__c;
                
            }
            
            
            
            
            
            
            
            
        }
    }
    
    
    
    
    private void prepopulateExternalAccountFromAccount()
    {
        
        String accType = null;
        
        /*
if(!isAgency)
{
accType = 'Casual Business';
}
*/
        
        
        
        
        
        system.debug('@ call gbaHelper.prepopulateExternalAccount(...)');
        gbaAccount = gbaHelper.prepopulateExternalAccount(  gbaAccount,     // @extAcc
                                                          selectedAdvertiser,  // @accAdvertiser
                                                          selectedPayer,       // @accPayer
                                                          isAgency,  // @isBookingTypeAgency
                                                          accType         // @accType
                                                         );
        system.debug('@prepopulateExternalAccountFromAccount gbaAccount: ' + gbaAccount);
        
    }
    
    
    
    public List<SelectOption> getParentBookingAccounts() {
        system.debug('@ getParentBookingAccounts()');
        
        List<SelectOption> bookingAccounts = new List<SelectOption>();
        
        system.debug('selectedPayer:' + selectedPayer);
        if (isAgency && selectedPayer != null)
        {
            system.debug('@ call gbaHelper.getAvailableExternalAccount(...)');
            
            List<External_Account__c> lEa = gbaHelper.getAccountDirectExternalAccount(  selectedPayer,              // @accId
                                                                                      'Booking_Account'           // @externalAccountRecordTypeDeveloperName
                                                                                     );
            // modified by Tim Fabros 20 / 05 /2014 - SFE-362
            // BEGIN:
            for (External_Account__c ea : lEa ) 
            {
                if (ea.Account_Type__c == 'Ad Agency' || ea.Account_Type__c == 'Overseas Agent' || 
                    ea.Account_Type__c == 'Corporate' || ea.Account_Type__c == 'Overseas Advertising Agency')
                {
                    bookingAccounts.add(new SelectOption(ea.Id, ea.Genera_Name_Display__c + ' - ' + ea.Account_Type__c));
                } // added by Tim Fabros - 19 / 05 / 2014
            }
            // END:
            
            // if there is more than one 'valid' external account, force the user selection
            if (bookingAccounts.size() > 1) {
                bookingAccounts.add(0, new SelectOption('', '--select--'));
            }
            
            // modified by Tim Fabros 20 / 05 /2014 - SFE-362
            // BEGIN:
            // default if exactly one valid parent
            if (bookingAccounts.size() == 1) {
                gbaAccount.External_Account__c = bookingAccounts[0].getValue(); //lEa[0].Id;
                onParentAccountSelection();
                onAccountTypeSelection();
            }
            // END:
            
            
        }
        
        
        return bookingAccounts;
    }
    
    /*public PageReference saveNewGBAAndRedirect()
{
system.debug('@ saveNewGBAAndRedirect');

PageReference pr = null;
saveNewGBA();

if(gbaAccount.id != null)
{
if(redirectToPage)
{
pr = new ApexPages.StandardController(gbaAccount).view();
}
else
{
// call page controller method from component controller
PageControllerBase pageCtr = this.pageController;

if (pageCtr != null && pageCtr instanceof SalesOrderCreateBookingv2_ControllerX) 
{
SalesOrderCreateBookingv2_ControllerX bookingCtr = (SalesOrderCreateBookingv2_ControllerX)pageCtr;
bookingCtr.showAddNewGBAFlag = false;
} 
}
}

return pr;
}*/
    
    private Set<String> requiredGbaAccountType
    {
        get
        {
            if(requiredGbaAccountType == null)
            {
                requiredGbaAccountType = new Set<String>();
                for(Genera_Account_Type_Mapping__c gbaType : Genera_Account_Type_Mapping__c.getAll().values())
                {
                    if(gbaType.Parent__c != null && gbaType.Parent__c.trim().length()>0)
                    {
                        requiredGbaAccountType.add(gbaType.Name);
                    }
                }
                //requiredGbaAccountType = Gba_Account_Types__c.getAll().keySet();
            }
            return requiredGbaAccountType;
        }
        private set;
    }
    
    public PageReference saveNewGBAAndRedirect()
    {
        /**** Updated by Bohao Chen on 23/Apr/2014 for JIRA SFE-475 *****/
        system.debug('@ saveNewGBAAndRedirect');
        PageReference pr = null;
        /**** Update Ends *****/
        
        system.debug('@ saveNewGBA');
        system.debug('gbaAccount:' + gbaAccount);
        
        isSaving = true;
        
        gbaAccount.RecordTypeId = [Select Id From RecordType where SobjectType = 'External_Account__c' and DeveloperName='Booking_Account'].id;
        
        
        set<string> selectedDivisionsSet =  new set<string>();
        selectedDivisionsSet.addAll(selectedDivisions);
        if(gbaAccount.Owning_Credit_Division__c!=null &&
           !selectedDivisionsSet.contains(gbaAccount.Owning_Credit_Division__c))
        {
            selectedDivisions.add(gbaAccount.Owning_Credit_Division__c);
        }
        
        gbaAccount.Division__c = String.join(selectedDivisions,',');
        
        // do validation
        if(requiredGbaAccountType.contains(gbaAccount.Account_Type__c) && gbaAccount.External_Account__c == null)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'Account Type ' + gbaAccount.Account_Type__c + ' needs parent account'));
            isSaving = false;
            return null;
        }                      

    // ADSALES-00048  2016-08-31 darshan.gosar@bluewolfgroup.com 
      // Added new validation as if Account Type is NewsPay then Division can not be other than National      
        if(gbaAccount.Account_Type__c == 'NewsPay' && gbaAccount.Division__c  != 'National')
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'When the NewsPay Account Type is selected, the Division and Owning Credit Division must be National. Please update the Division and/or Owning Credit Division to National'));
            isSaving = false;
            return null;
        }                      
        
        if(gbaAccount.GBA_Phone__c != null && gbaAccount.GBA_Phone__c.length()>12)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'Phone number is too long'));
            isSaving = false;
            return null;
        }
        
        // added by Tim Fabros 20 / 05 / 2014.
        // checks if the Account_Type is blank
        if (gbaAccount.Account_Type__c == null) 
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'Account Type is required'));
            isSaving = false;
            return null;
        }
        
        if(gbaAccount.Division__c!=null && gbaAccount.Division__c.trim().length()>0)
            gbaAccount.Division__c = gbaAccount.Division__c.replace(';',',');
        
        String accountNumber;
        
        try{
            
            //transfered to ExternalAccountCreateGBA_Helper.createAccount
            /*if(gbaAccount.Account_Type__c!=null && gbaAccount.Account_Type__c=='Request for Established')
{
gbaAccount.Account_Type__c='Casual Business';
}*/
            
            /**** Updated by Bohao Chen on 23/Apr/2014 for JIRA SFE-475 *****/
            Boolean isValid = true;
            
            String specialCharPattern = '^[\\x20-\\x7E]*$';
            
            if(!Pattern.matches(specialCharPattern, gbaAccount.Suburb__c) || 
               !Pattern.matches(specialCharPattern, gbaAccount.Name) ||
               !Pattern.matches(specialCharPattern, gbaAccount.Street__c) ||
               !Pattern.matches(specialCharPattern, gbaAccount.Country__c))
            {
                if(!Pattern.matches(specialCharPattern, gbaAccount.Suburb__c))
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'Please remove special characters from Suburb field.'));
                if(!Pattern.matches(specialCharPattern, gbaAccount.Name))
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'Please remove special characters from Name field.'));
                if(!Pattern.matches(specialCharPattern, gbaAccount.Street__c))
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'Please remove special characters from Street field.'));
                if(!Pattern.matches(specialCharPattern, gbaAccount.Country__c))
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 'Please remove special characters from Country field.'));
                
                isValid = false;         
                isSaving = false;
                return null;
            }
            
            if(isValid)
            {
                /**** Update Ends *****/
                
                // Genera Web Service Call
                // Because test class doesn't support more than one web service call mock
                // we have to skip web service call and test them seperately and individually            
                if(!Test.isRunningTest())
                {
                    this.login();
                    accountNumber = this.createAccount();
                    system.debug('accountNumber:' + accountNumber);
                    this.saveAccount(accountNumber);
                }
                else
                {
                    accountNumber = '12345678';
                }
                
                
                system.debug('finally');
                //Test Methods do not support callout
                if(!Test.isRunningTest())
                {
                    this.logout();
                }
                
                //receive account number from Genera Web Service Call
                // insert external account record with Genera account number
                gbaAccount.Account_No__c = accountNumber;
                gbaAccount.External_Id__c = 'GBA_' + gbaAccount.Account_No__c;
                gbaAccount.Phone__c = getPhoneNumber(String.valueOf(gbaAccount.GBA_Phone_Country_Code__c),
                                                     String.valueOf(gbaAccount.GBA_Phone_Area_Code__c),
                                                     String.valueOf(gbaAccount.GBA_Phone__c));
                
                
                system.debug('=== gbaAccount on save:' + gbaAccount);
                
                if(gbaAccount.Account_No__c!=null)
                {
                    try
                    {
                        insert gbaAccount;
                    }
                    catch(Exception e)
                    {
                        system.debug('Error:' + e.getMessage());
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
                    }
                }
                /**** Updated by Bohao Chen on 23/Apr/2014 for JIRA SFE-475 *****/
            }
            /**** Update Ends *****/
        }
        catch(Exception e)
        {
            system.debug('Error:' + e.getMessage());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
            //Test Methods do not support callout
            if(!Test.isRunningTest())
            {
                this.logout();
            }
        }
        
        isSaving = false;
        
        /**** Updated by Bohao Chen on 23/Apr/2014 for JIRA SFE-475 *****/
        //     return null;
        
        
        if(gbaAccount.id != null)
        {
            if(redirectToPage)
            {
                pr = new ApexPages.StandardController(gbaAccount).view();
            }
            else
            {
                // call page controller method from component controller
                PageControllerBase pageCtr = this.pageController;
                
                if (pageCtr != null && pageCtr instanceof SalesOrderCreateBookingv2_ControllerX) 
                {
                    SalesOrderCreateBookingv2_ControllerX bookingCtr = (SalesOrderCreateBookingv2_ControllerX)pageCtr;
                    bookingCtr.showAddNewGBAFlag = false;
                } 
            }
        }
        
        return pr;
        /**** Update Ends *****/
    }
    
    
    public void login()
    {
        this.gbaHelper.login();
    }
    
    
    public String createAccount()
    {
        string gbaPhoneAreaCode = String.valueOf(gbaAccount.GBA_Phone_Area_Code__c).length()==1?'0'+String.valueOf(gbaAccount.GBA_Phone_Area_Code__c):String.valueOf(gbaAccount.GBA_Phone_Area_Code__c);
        
        String accountNumber = this.gbaHelper.createAccount(gbaAccount.Country__c,
                                                            gbaAccount.Name,
                                                            gbaAccount.Title__c,
                                                            gbaAccount.Email_Address__c,
                                                            true,
                                                            gbaAccount.Post_Code__c,
                                                            null,
                                                            gbaAccount.State__c,
                                                            gbaAccount.Street__c,
                                                            null,
                                                            gbaAccount.Suburb__c,
                                                            String.valueOf(gbaAccount.GBA_Phone_Country_Code__c),
                                                            gbaPhoneAreaCode,
                                                            String.valueOf(gbaAccount.GBA_Phone__c),
                                                            gbaAccount.Account_Type__c,
                                                            gbaAccount.ABN_Number__c,
                                                            gbaAccount.First_Name__c,
                                                            gbaAccount.Last_Name__c,
                                                            gbaAccount.DPID__c,
                                                            gbaAccount.Default_Revenue_Group__c,
                                                            gbaAccount.Email_Confirmation_Address__c,
                                                            gbaAccount.External_Account__c,
                                                            gbaAccount.Division__c,
                                                            gbaAccount.Owning_Credit_Division__c
                                                           );
        
        //  String accountNumber = this.gbaHelper.createDummyAccount();
        system.debug('=== accountNumber:' + accountNumber);
        
        return accountNumber;
    }
    
    public void saveAccount(String accountNumber)
    {
        this.gbaHelper.saveAccount(accountNumber);
    }
    
    public void logout()
    {
        this.gbaHelper.logout();
    }
    
    
    public PageReference cancelNewGBA()
    {
        return null;
    }
    
    // combine country code, area code and local number into phone value
    private String getPhoneNumber(String phoneCountryCode, String phoneAreaCode, String phone)
    {
        return phoneCountryCode + phoneAreaCode + phone;
    }
    
    
    ////////////////////////
    /// ABN ////////////////
    ////////////////////////
    
    
    private ABNLookupStub.AustralianBusinessNumber abnResponse;
    public  ABNLookupStub.AustralianBusinessNumber abn {get{return abnResponse;}}
    
    public void doABNLookup()
    {
        /**SFE-242 - ABN validation error message is not clear
* Modified by LMancilla 
* May 13 2014
* BwB
* Added try catch and page message
**/
        try{
            abnResponse = ABNLookupStub.ABRSearchByABN(gbaAccount.ABN_Number__c);
            
            if(abnResponse.isInvalid!=null && abnResponse.isInvalid)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, gbaAccount.ABN_Number__c + ' is not a valid ABN'));
            }
            
            SYSTEM.debug('### abnResponse:' + abnResponse);
        }catch(Exception e){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'An error has occurred contacting the ABR website. Please try again later.'));
            System.debug('@Exception ERROR doABNLookup:'+e);
        }
    }
    
    
}
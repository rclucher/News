global with sharing class SalesOrderCreateBookingv2_ControllerX  extends PageControllerBase{

    
    private final string GENERA_LABEL_AND_VALUE = 'Cyber$ell';
    private final string CYBER_LABEL_AND_VALUE = 'CyberAd';
    private final string DIGITAL_LABEL_AND_VALUE = 'AdPoint';

    /****** Begin: adpoint ****/
    private final string SUCCESS_WS_STATUS = 'OK';
    private String runningUserAdPointUserId;
    private String networkUsername;
    
    public Boolean hasErrorMsg {get{return hasErrorMsg == Null ? false : hasErrorMsg; } set;}
    public Boolean hasWarningMsg {get; set;}
    

    private static final String INVALID_ADPOINT_USER_ID = 'You do not have an AdPoint User id. Please contact your Administrator to set the AdPoint User Id for you';
    private static final String INVALID_NETWORK_USERNAME = 'You do not have a network username. Please contact your Administrator to set the network username for you';
    private static final String NO_LOGIN_ACCESS = 'You do not have login access to make booking';
        
    private static final String MAKE_DIGITAL_BOOKING_MSG = 'You need to click \'Make Digital\' button to make it digital before making a booking.';
    private static final String RETRY_MAKE_DIGITAL_MSG ='See error details below. Please retry by pressing \'Make Digital\' button again';
     
    private static final String ACCOUNT_INACTIVE = ' account is inactive';
    private static final String ACCOUNT_NULL_ADPOINTID = ' account doesn\'t have AdPoint Id'; 
    
    private static final String ADVERTISER_ACCOUNT_INACTIVE = 'Advertiser' + ACCOUNT_INACTIVE;
    private static final String ADVERTISER_ACCOUNT_NULL_ADPOINTID = 'Advertiser' + ACCOUNT_NULL_ADPOINTID;
    //Added LMancilla
    //7 October 2014
    //SFE-634 Do not let Agency Accounts be the advertiser account. Disable 'Book' button on VF page
    private static final String ADVERTISER_INVALID_TYPE = 'Invalid Advertiser Type';
    //ENd LMancilla


    private static final String PAYER_ACCOUNT_INACTIVE = 'Payer' + ACCOUNT_INACTIVE;
    private static final String PAYER_ACCOUNT_NULL_ADPOINTID = 'Payer' + ACCOUNT_NULL_ADPOINTID;
         
    private static final String PLACER_ACCOUNT_INACTIVE = 'Placer' + ACCOUNT_INACTIVE;
    private static final String PLACER_ACCOUNT_NULL_ADPOINTID = 'Placer' + ACCOUNT_NULL_ADPOINTID;
    
    @TestVisible private static final String NON_DIGITAL_ADVERTISER_ACCT_MSG = 'Advertiser account is not digital. ' + MAKE_DIGITAL_BOOKING_MSG;
    
    @TestVisible private static final String NON_DIGITAL_AGENCY_PAYER_ACCT_MSG =  'i) You cannot turn Agency Accounts into Digital in the Booking UI<br />' + 
                                                                           'ii) To book with the Agency Account, you must open it and convert it to Digital manually';
    
    @TestVisible private static final String NON_DIGITAL_PAYER_ACCT_MSG = 'Payer account is not digital. ' + MAKE_DIGITAL_BOOKING_MSG;
    
    @TestVisible private static final String NON_DIGITAL_CONTACT_MSG = 'Contact is not digital. ' + MAKE_DIGITAL_BOOKING_MSG;
    @TestVisible private static final String BLACKLIST_ACCT_MSG = 'Payer account is on blacklist. You cannot proceed booking with blacklisted payer account';
    @TestVisible private static final String PRIVATE_PARTY_PAYER_ACCT_MSG = 'Payer account cannot be private party.';
    @TestVisible private static final String PRIVATE_PARTY_ADVERTISER_ACCT_MSG = 'Advertiser account cannot be private party.';
    @TestVisible private static final String WS_CREATE_DIGITAL_CONTACT_ERROR = 'Make contact digital failed due to failure of webservice call out. ' + RETRY_MAKE_DIGITAL_MSG;
    @TestVisible private static final String WS_CREATE_DIGITAL_ADVERTISER_ERROR = 'Make advertiser account digital failed due to failure of webservice call out. ' + RETRY_MAKE_DIGITAL_MSG;
    //@TestVisible private static final String WS_CREATE_DIGITAL_PAYER_ERROR = 'Make advertiser account digital failed due to failure of webservice call out. ' + RETRY_MAKE_DIGITAL_MSG;
    @TestVisible private static final String WS_CREATE_ORDER_ERROR = 'Make order in AdPoint booking system failed due to failure of webservice call out. Please retry by pressing \'Book\' button again';
    @TestVisible private static final String INVALID_ACCOUNT_CONTACT_REL_MSG = 'Contact must associate with payer account.';
    private static final String NULL_PAYER_ACCOUNT = 'Payer Account: You must enter a value';
    @TestVisible private static final String MAKING_DIGITAL_ADVERTISER_ACCT_IN_PROGRESS = 'Making digital advertiser account is still in progress, please try \'Make Digital\' button later';
    @TestVisible private static final String MAKING_DIGITAL_PAYER_ACCT_IN_PROGRESS = 'Making digital payer account is still in progress, please try \'Make Digital\' button later';                
    @TestVisible private static final String MAKING_DIGITAL_CONTACT_IN_PROGRESS = 'Making digital contact is still in progress, please try \'Make Digital\' button later';
    @TestVisible private static final String NON_AGENCY_PAYER = 'Payer account should be an agency account if booking type is \'Agency Booking\'';
    @TestVisible private Boolean isMakingAcctDigitalSuccess { 
        get{ return isMakingAcctDigitalSuccess = isMakingAcctDigitalSuccess == null ? false : isMakingAcctDigitalSuccess; } 
        set; 
    }
    @TestVisible private Boolean isMakingContactDigitalSuccess { 
        get{ return isMakingContactDigitalSuccess = isMakingContactDigitalSuccess == null ? false : isMakingContactDigitalSuccess; } 
        set; 
    }
    @TestVisible private Boolean isMakingOrderSuccess { 
        get{ return isMakingOrderSuccess = isMakingOrderSuccess == null ? false : isMakingOrderSuccess; } 
        set; 
    }
    private AdPointWebserviceStub_Helper adPointWebserviceHelper { 
        get{ return adPointWebserviceHelper = adPointWebserviceHelper == null 
            ? new AdPointWebserviceStub_Helper() : adPointWebserviceHelper; } 
        set; 
    }
    /****** end: adpoint ***/

    /*** begin: BC update ****/
    // this variable indicates whether booking has error
    // the reason is because on book command button, oncomplete will fire javascript to open up external system.
    // We have to prevent external system page from opening up if there is any issue with book in SFDC so user can stay
    // on same page, fix issue and try to press book button again.
    // TODO:
    public boolean isBookingReady { get {return isBookingReady = isBookingReady == null ? false : isBookingReady;} set;}

    /*** end: BC update ****/

    private Sales_Order__c salesOrderSource;
    private Opportunity opptySource;
    private Account accountSource;
    private CampaignMember campaignMemberSource;
    private ExternalAccountCreateGBA_Helper gbaHelper;

    public Case caseSource{get; private set;} //Made public due to case 00001108

    public Sales_Order__c so {get; set;}
    public External_Account__c gbaAccount { get; set; }
    public String payerPicklistSelection {get;set;}
    //CdS 20/08/2015 - SFE-714 : added StageName
    public boolean isOpptyReservation {get; private set;}



    
    public final SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper orderWrapper {get; set;}

    public boolean showAddNewGBAFlag {public get{return showAddNewGBAFlag = showAddNewGBAFlag!=null?showAddNewGBAFlag:false;} set;}
    public boolean canCreateGBA {get{ return canCreateGBA = (UserSettings_Helper.createGBAType!='None');}private set;}
    
    public Boolean getIsGenera() {
        system.debug('@ getIsGenera()');
        
        system.debug('@source system: ' + so.Source_System__c);
        
        return so.Source_System__c == GENERA_LABEL_AND_VALUE;
    }
    
    public Boolean getIsCyber() {
        system.debug('@ getIsCyber()');
        return so.Source_System__c == CYBER_LABEL_AND_VALUE;
    }

    public Boolean getIsDirect() {
        system.debug('@ getIsAgency()');
        return so.Booking_Type__c == 'Direct';
    }
    
    public Boolean getIsAgency() {
        system.debug('@ getIsAgency()');
        return so.Booking_Type__c == 'Agency';
    }
    
    public string noBookingSystemAccountMessage {get{return SystemMessages__c.getAll().get('No Booking System Account').Message__c;}}

    public Account selectedAdvertiser {get; private set;}
    
    public void populateSelectedAdvertiser() 
    {
        system.debug('@populateSelectedAdvertiser');
        
        if(CreateAccountComponentController!=null &&
            CreateAccountComponentController.newAccount.id!=null)
        {
            system.debug('CreateAccountComponentController.newAccount: ' + CreateAccountComponentController.newAccount);
            system.debug('CreateAccountComponentController.newAccount.id: ' + CreateAccountComponentController.newAccount.id);
            so.Advertiser_Account__c = CreateAccountComponentController.newAccount.id;
            this.selectedAdvertiser = queryForAccount(CreateAccountComponentController.newAccount.id);

            if(getIsDirect())
            {
                so.Payer_Account__c = so.Advertiser_Account__c;
                selectedPayer = this.selectedAdvertiser; 
                so.Placer_Account__c = so.Advertiser_Account__c; 
                selectedPlacer = this.selectedAdvertiser;

                if(this.selectedAdvertiser.IsPersonAccount && this.selectedAdvertiser.PersonContactId!=null)
                    so.contact__c = this.selectedAdvertiser.PersonContactId;
            }
                
            CreateAccountComponentController.newAccount = new Account();

        }           
        else if(SearchAccountComponentController!=null && 
            SearchAccountComponentController.selectedAccount.id!=null)
        {
            system.debug('SearchAccountComponentController.selectedAccount: ' + SearchAccountComponentController.selectedAccount);
            system.debug('SearchAccountComponentController.selectedAccount.id: ' + SearchAccountComponentController.selectedAccount.id);
            so.Advertiser_Account__c = SearchAccountComponentController.selectedAccount.id;
            this.selectedAdvertiser = queryForAccount(SearchAccountComponentController.selectedAccount.id);
            //SearchAccountComponentController.selectedAccount = null;

            if(getIsDirect())
            {
                so.Payer_Account__c = so.Advertiser_Account__c;
                selectedPayer = this.selectedAdvertiser; 
                so.Placer_Account__c = so.Advertiser_Account__c; 
                selectedPlacer = this.selectedAdvertiser;
                if(this.selectedAdvertiser.IsPersonAccount && this.selectedAdvertiser.PersonContactId!=null)
                    so.contact__c = this.selectedAdvertiser.PersonContactId;
                
            }

            SearchAccountComponentController.selectedAccount = null;
        }

        if(so.Source_system__c == DIGITAL_LABEL_AND_VALUE)
            this.doDigitalValidation();
    }

    public Boolean getSalesOrderOwnerId()
    {
        system.debug('@defaultSalesOrderOwner Advertiser_Account__c: ' + so.Advertiser_Account__c);
        
        if(so.OwnerId == null)
        {
            so.OwnerId = [Select OwnerId From Account Where Id =: so.Advertiser_Account__c limit 1].OwnerId;
        }
        
        return true;
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


    public Account selectedPayer {get;set;} 
    public Account selectedPlacer {get;set;} 
    
    public boolean showHeaderAndSidebar {
        get { return Global_Helper.showHeaderAndSidebar; }
        set;
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

    /************ AdPoint **********/
    public Boolean isValidRelationship { get{ return isValidRelationship = isValidRelationship == null ? false : isValidRelationship; } set; }
    
    public Boolean isAdvertiserAccountDigital
    {
        get
        {
            if(so.Advertiser_Account__c != null)
            {
                return isAdvertiserAccountDigital = [Select Digital_Status__c From Account Where Id =: so.Advertiser_Account__c limit 1].Digital_Status__c != 'Active' ? false : true;
            }
            return true;
        }
        
        private set;
    }

    public Boolean isMakingAdvertiserAccountDigital
    {
        get
        {
            if(so.Advertiser_Account__c != null)
            {
                Account acct = [Select Digital_Status__c From Account Where Id =: so.Advertiser_Account__c limit 1];
                
                if(String.isBlank(acct.Digital_Status__c) || acct.Digital_Status__c == 'Active') return false;
                else return true;
            }
            return false;
        }
        
        private set;
    }
    
    public Boolean isMakingPayerAccountDigital
    {
        get
        {
            if(so.Advertiser_Account__c != null)
            {
                Account acct = [Select Digital_Status__c From Account Where Id =: so.Payer_Account__c limit 1];
                
                if(String.isBlank(acct.Digital_Status__c) || acct.Digital_Status__c == 'Active') return false;
                else return true;
            }
            return false;
        }
        
        private set;
    }
        
    public Boolean isPayerAccountDigital
    {
        get
        {
            if(so.Payer_Account__c != null)
            {
                return isPayerAccountDigital = [Select Digital_Status__c From Account Where Id =: so.Payer_Account__c limit 1].Digital_Status__c != 'Active' ? false : true;
            }
            return true;
        }
        
        private set;
    }
    
    public Boolean isContactDigital
    {
        get
        {
            if(so.Contact__c != null)
            {
                return isContactDigital = [Select Digital_Status__c From Contact Where Id =: so.Contact__c Limit 1].Digital_Status__c != 'Active' ? false : true;
            }
            return true;
        }
        
        private set;
    }
    
    public Boolean isAdPointBookingSystem
    {
        get
        {
            return so.Source_System__c == DIGITAL_LABEL_AND_VALUE ? true : false; 
        }
        private set;    
    }
    
    public Boolean isPayerAccountOnBlacklist 
    {
        get
        {
            isPayerAccountOnBlacklist = false;
            
            if(so.Payer_Account__c != null)
            {
                isPayerAccountOnBlacklist = [Select Is_on_Black_List_Digital_Media__c From Account Where Id =: so.Payer_Account__c limit 1].Is_on_Black_List_Digital_Media__c;
            }
            
            return isPayerAccountOnBlacklist;
        }   
        
        private set;
    }
    
    public Boolean isPayerAccountPrivateParty
    {
        get
        {
            if(so.Payer_Account__c != null)
            {
                return isPayerAccountPrivateParty = [Select RecordType.DeveloperName 
                                                    From Account 
                                                    Where Id =: so.Payer_Account__c 
                                                    limit 1].RecordType.DeveloperName != 'Private_Party' ? false : true;
            }
            return false;
        }
        
        private set;
    }
    
    // this determines availability of 'make digital' button
    public Boolean isReadyToMakeDigital
    {
        get
        {
            if(!hasErrorMsg && so != null && so.Contact__c != null && so.Advertiser_Account__c != null && so.Payer_Account__c != null)
            {
                Contact con = [Select Digital_Status__c, AdPoint_Id__c From Contact Where Id =: so.Contact__c Limit 1];
                Account advertiserAccount = [Select Digital_Status__c, AdPoint_Id__c From Account Where Id =: so.Advertiser_Account__c];
                Account payerAccount = [Select Digital_Status__c, AdPoint_Id__c From Account Where Id =: so.Payer_Account__c];
                                    
                if((con != null && (con.Digital_Status__c != 'Active' || String.isBlank(con.AdPoint_Id__c))) || 
                    (advertiserAccount != null && advertiserAccount.Digital_Status__c != 'Active' || String.isBlank(advertiserAccount.AdPoint_Id__c)) || 
                    (payerAccount != null && payerAccount.Digital_Status__c != 'Active' || String.isBlank(payerAccount.AdPoint_Id__c)))
                {
                    return true;
                }
            }
            return false;
        }
        
        private set;
    }
    
    private string getOpportunityStageNameBySalesOrderId(Id soId)
    {
        String StageName = '';
        list<OpportunityLineItem> oli = [Select opportunity.StageName from OpportunityLineItem where Sales_Order__c = :soId];
        if(oli.size()>0 && oli[0].opportunity!=null)
            StageName = oli[0].opportunity.StageName;

        return StageName;
    }


    /**********************/

    ///// Constructor - Start /////
    public SalesOrderCreateBookingv2_ControllerX(ApexPages.StandardController controller) 
    {
        if(!test.isRunningTest())
        {
            controller.addFields(new String[]{'Source_System__c', 'Booking_Division__c'});
        }


        isOpptyReservation = false;

        if(controller.getId() != null){
            system.debug('@ SalesOrderCreateBookingv2_ControllerX controller.getId()' + controller.getId());
            salesOrderSource = SalesOrderCreateBooking_Helper.getSingleSalesOrderById(controller.getId());
            system.debug('@ SalesOrderCreateBookingv2_ControllerX  salesOrderSource' + salesOrderSource);
            isOpptyReservation = getOpportunityStageNameBySalesOrderId(controller.getId())=='Reservation';
            orderWrapper = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(salesOrderSource);
        }
        else
        {
            if(ApexPages.currentPage().getParameters().get('opptyId')!=null)
            {
                system.debug('@ SalesOrderCreateBookingv2_ControllerX opptyId:' + ApexPages.currentPage().getParameters().get('opptyId'));
                setOpptySource(ApexPages.currentPage().getParameters().get('opptyId'));

                orderWrapper = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(opptySource);            
            }
            else if(ApexPages.currentPage().getParameters().get('campaignMemberID')!=null)
            {
                system.debug('@ SalesOrderCreateBookingv2_ControllerX campaignMemberID:' + ApexPages.currentPage().getParameters().get('campaignMemberID'));
                setCampaignMemberSource(ApexPages.currentPage().getParameters().get('campaignMemberID'));
    
                orderWrapper = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(campaignMemberSource);
            }
            else if(ApexPages.currentPage().getParameters().get('caseId')!=null)
            {
                system.debug('@ SalesOrderCreateBookingv2_ControllerX caseId:' + ApexPages.currentPage().getParameters().get('caseId'));
                setCaseSource(ApexPages.currentPage().getParameters().get('caseId'));
    
                if(caseSource.Accountid!=null)
                {
                    system.debug('@account id: ' + caseSource.Accountid);
                    
                    setAccountSource(caseSource.Accountid);
                }
    
                orderWrapper = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(caseSource);
            }
            else if(ApexPages.currentPage().getParameters().get('acctId')!=null)
            {
                system.debug('@ SalesOrderCreateBookingv2_ControllerX opptyId:' + ApexPages.currentPage().getParameters().get('acctId'));
                setAccountSource(ApexPages.currentPage().getParameters().get('acctId'));
                orderWrapper = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper(accountSource);
    
            }
            else
            {
                system.debug('@ SalesOrderCreateBookingv2_ControllerX else');
                orderWrapper = new SalesOrderCreateBooking_Helper.SalesOrderOpportunityWrapper();
            }
        }

        so = orderWrapper.salesOrder;
        
        
        gbaHelper = new ExternalAccountCreateGBA_Helper();


        system.debug('@ SalesOrderCreateBookingv2_ControllerX opptySource:' + opptySource);
        system.debug('@ SalesOrderCreateBookingv2_ControllerX caseSource:' + caseSource);       
        if(opptySource!=null || caseSource!=null)
        {
                system.debug('@ SalesOrderCreateBookingv2_ControllerX so.Advertiser_Account__c:' + so.Advertiser_Account__c);
                if(so.Advertiser_Account__c!=null)
                   this.selectedAdvertiser =  queryForAccount(so.Advertiser_Account__c);


                system.debug('@ SalesOrderCreateBookingv2_ControllerX so.Payer_Account__c:' + so.Payer_Account__c);
                if(so.Payer_Account__c!=null)
                   selectedPayer =  queryForAccount(so.Payer_Account__c);   

                // added by Tim Fabros 22 / 05 / 2014 - SFE-521
                // BEGIN:
                if(so.Payer_Account__c==null)
                    so.Payer_Account__c = so.Advertiser_Account__c;
                // END:
        }
        
        
        if(campaignMemberSource!=null)
        {
            /**SFE-60 - Campaigns - Booking is defaulted to Direct Booking Type
            * Modified by LMancilla
            * May 13 2014
            * BwB
            * Line commented out - new default value None
            **/
            //so.Booking_Type__c = 'Direct';
            so.Advertiser_Account__c = campaignMemberSource.contact.accountId;
            so.Payer_Account__c = campaignMemberSource.contact.accountId;
            so.Placer_Account__c = campaignMemberSource.contact.accountId;
            so.Contact__c = campaignMemberSource.contactId;
            
            /**
            * SFE-412 - Campaigns - Campaign field not populated when booking created from campaign member response console
            * Modified by: Lmancilla
            * May 19 2014
            * Added new Campaign__c field to Sales Order. Set value when created fromc ampaign execution
            **/
            so.Campaign__c=campaignMemberSource.CampaignId;
            /**End change SFE-412**/
            
            this.selectedAdvertiser =  queryForAccount(so.Advertiser_Account__c);
            selectedPayer = this.selectedAdvertiser;
        }
        
        // AdPoint
        // if booking system is adPoint, validate accounts and contact
        if(so.source_system__c == DIGITAL_LABEL_AND_VALUE)
        {
            system.debug('@adpoint digital validation');
            
            this.populateAccounts();
            this.doDigitalValidation();
        }
        
        /**
        * Fixed BUG - when only one value in 'Boking System' page was not rendering propoerly.
        *             Users needed to clear selection in pick list and select their default value again for the page to load properly 
        **/

        if((targetSystems!=null)&&targetSystems.size()==1) so.Source_System__c=targetSystems[0].getValue();   

        system.debug('so:' + so);
    }
    ///// Constructor - End /////

    

    //// Private methods - Start ////
    //CdS 20/08/2015 - SFE-714 : added StageName
    private void setOpptySource(string opptyId)
    {
        try{
            opptySource = [Select id, recordType.DeveloperName, AccountId, Contact__c, Payer_Account__c, StageName from Opportunity Where id = :opptyId];
            isOpptyReservation = opptySource.StageName=='Reservation';
        }
        catch(System.QueryException qex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Invalid opportunity'));
        }
    }



    private void setCampaignMemberSource(string campaignMemberId)
    {
        try{
            campaignMemberSource = [Select id, ContactId, contact.AccountId, CampaignId from CampaignMember Where id = :campaignMemberId];
        }
        catch(System.QueryException qex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Invalid Campaign Member'));
        }
    }

    private void setCaseSource(string caseId)
    {
        try{
            caseSource = [Select id, recordType.DeveloperName, Opportunity__c, Opportunity__r.StageName, Opportunity__r.Payer_Account__c, Accountid, ContactId from Case Where id = :caseId];
            if(caseSource!=null && caseSource.Opportunity__c!=null && caseSource.Opportunity__r.StageName=='Reservation')
                isOpptyReservation = true;
        }
        catch(System.QueryException qex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Invalid case'));
        }
    }


    private void setAccountSource(string acctId)
    {
        try{
            accountSource = queryForAccount(acctId);
        }
        catch(System.QueryException qex) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Invalid account'));
        }
    }
    
    private void setSelectedAccounts()
    {
        map<id,Account> selectedAccounts = new map<id,Account>(
                                            [SELECT RecordType.name,
                                                    IsPersonAccount,
                                                    RecordType.DeveloperName,
                                                    BillingPostalCode,
                                                    BillingCountry,
                                                    BillingState,
                                                    BillingStreet,
                                                    BillingCity,
                                                    PersonMailingPostalCode,
                                                    PersonMailingCountry,
                                                    PersonMailingState,
                                                    PersonMailingCity,
                                                    PersonMailingStreet,
                                                    PersonHomePhone,
                                                    DPID_Primary_Address__pc,
                                                    DPID_Primary_Address__c ,
                                                    Revenue_Group__c,
                                                    Name,
                                                    FirstName,
                                                    LastName,
                                                    AccountNumber,
                                                    Phone,
                                                    PersonContactId,
                                                    Creative_Agency_For_Digital_Customer__c,
                                                    Media_Agency_For_Digital_Customer__c
                                            FROM    Account
                                            WHERE   id=:so.Advertiser_Account__c
                                            OR      id=:so.Payer_Account__c
                                            OR      id=:so.Placer_Account__c]);

        this.selectedAdvertiser = selectedAccounts.containsKey(so.Advertiser_Account__c)?selectedAccounts.get(so.Advertiser_Account__c):null;
        selectedPayer = selectedAccounts.containsKey(so.Payer_Account__c)?selectedAccounts.get(so.Payer_Account__c):null;
        selectedPlacer =  selectedAccounts.containsKey(so.Placer_Account__c)?selectedAccounts.get(so.Placer_Account__c):null;
    }   
    
    
    private Account queryForAccount(String accId)
    {
        return [Select id,
                        Primary_Contact__c,
                        RecordType.name,
                        IsPersonAccount,
                        RecordType.DeveloperName,
                        BillingPostalCode,
                        BillingCountry,
                        BillingState,
                        BillingStreet,
                        BillingCity,
                        DPID_Primary_Address__c ,
                        Revenue_Group__c,
                        Name,
                        FirstName,
                        LastName,
                        AccountNumber,
                        Phone,
                        PersonContactId,
                        PersonMailingPostalCode,
                        PersonMailingCountry,
                        PersonMailingState,
                        PersonMailingCity,
                        PersonMailingStreet,
                        PersonHomePhone,
                        DPID_Primary_Address__pc,
                        Creative_Agency_For_Digital_Customer__c,
                        Media_Agency_For_Digital_Customer__c,
                        Is_Agency__c,
                        Status__c,
                        Industry_Code_Name_In_Text__c
                    From Account
                    Where id = :accId
                    Limit 1];
    
    }
    
    private void prepopulateExternalAccountFromAccount(Account accAdvertiser, Account accPayer)
    {

        String accType = null;
        if(so.Booking_Type__c == 'Direct')
        {
            accType = 'Casual Business';
        }

        system.debug('@ call gbaHelper.prepopulateExternalAccount(...)');

        gbaAccount = gbaHelper.prepopulateExternalAccount(  gbaAccount,     // @extAcc
                                                            accAdvertiser,  // @accAdvertiser
                                                            accPayer,       // @accPayer
                                                            getIsAgency(),  // @isBookingTypeAgency
                                                            accType         // @accType
                                                            );
    }   
    
    //// Private  methods - End ////

    ///// ACTIONS - Start /////
    /** SFE-78 - Booking UI - Ability to search for a different advertiser after one has been selected
    * Reset Advertiser Account
    * Created by: LMancilla
    * May 21 2014
    **/
    public void doResetAdvertiserAccount(){
        so.Advertiser_Account__c=null;
        selectedAdvertiser=null;
    }    
    
    public PageReference onChangeBookingType()
    {
        // added by Tim Fabros 29 / 05 / 2014 - SFE-374
        // BEGIN:
        hasErrorMsg = false;
        hasWarningMsg = false;
        // END:

        system.debug(logginglevel.error, '@onChangeBookingType');
        system.debug(logginglevel.error, '@onChangeBookingType selectedAdvertiser: ' + this.selectedAdvertiser);
        system.debug(logginglevel.error, '@onChangeBookingType opptySource: ' + opptySource);
        system.debug(logginglevel.error, '@onChangeBookingType getIsDirect(): ' + getIsDirect());
        
        // modified by  Tim Fabros 22 / 05 / 2014 - SFE-521
        // Updated by  Bohao Chen 29 / 05 / 2014 - SFE-521
        // BEGIN: 

        if((opptySource!=null || caseSource!=null) && getIsAgency()) // if statement now includes case source.
        {
            if(selectedPayer==null || 
                (selectedPayer!=null && selectedPayer.RecordType.DeveloperName!='Agency_Account_Type'))
            {
                if(opptySource != null)
                {
                    so.Payer_Account__c = opptySource.Payer_Account__c;
                }
                else if(caseSource != null && caseSource.Opportunity__c != null)
                {
                    so.Payer_Account__c = caseSource.Opportunity__r.Payer_Account__c;
                }
            }
        }
        // END:
        else if(getIsDirect() && this.selectedAdvertiser!=null && (opptySource!=null || caseSource!=null)) // added case source by Tim Fabros 22 / 05 / 2014 - SFE-521
        {
            so.Payer_Account__c = this.selectedAdvertiser.id;
        }
        
        if(so.Source_System__c == DIGITAL_LABEL_AND_VALUE && getIsDirect() && this.selectedAdvertiser!=null)
        {
            so.Payer_Account__c = this.selectedAdvertiser.id;
            so.Placer_Account__c = so.Payer_Account__c;
        }
        else if(so.Source_System__c == DIGITAL_LABEL_AND_VALUE && getIsAgency())
        {
            so.Payer_Account__c = null;
            so.Placer_Account__c = so.Payer_Account__c;
        }
        
        setFieldValues();
        
        /******** begin: adPoint*******/
        this.populateAccounts();
        
        system.debug('@onChangeBookingType so.Payer_Account__c: ' + so.Payer_Account__c);
        System.debug('@onChangeBookingType so.Source_System__c: ' + so.Source_System__c);
        
        if(so.source_system__c == DIGITAL_LABEL_AND_VALUE)
        {
            so.Contact__c = null;
            this.doDigitalValidation();
        }
        /******** end: adPoint*******/
        
        return null;
    }
    
    // TODO: obsolete method, remove later 
    public void onChangeTargetSystem()
    {
        // added by Tim Fabros 04 / 06 / 2014 - SFE-374
        // resests the boolean fields when changing the booking system.
        // BEGIN:
        hasErrorMsg = false;
        hasWarningMsg = false;
        // END:

        setFieldValues();
        
        /********adPoint*******/
        if(so.source_system__c == DIGITAL_LABEL_AND_VALUE)
        {
            this.populateAccounts();
            this.doDigitalValidation();
        }
        /******** end: adPoint*******/
    }   

    // TODO: obsolete method, remove later 
    public void onChangeBookingDivision()
    {

    }
    
    
    
    public void onChangePicklistSelection()
    {
        system.debug('@ onChangePicklistSelection() payerPicklistSelection:' + payerPicklistSelection);
        
        if(payerPicklistSelection=='new')
        {
            so.Payer_Account__c = null;
            onChangePayerAccount();
        }
        else if(payerPicklistSelection!=null && (payerPicklistSelection != '' && payerPicklistSelection.trim().length()>0))
        {
            so.Payer_Account__c = payerPicklistSelection;
            onChangePayerAccount();
        }
        
        system.debug('@ onChangePicklistSelection() so.Payer_Account__c:' + so.Payer_Account__c);
        
    }
    
    
    public void onChangePayerAccount()
    {
        system.debug('@ onChangePayerAccount() so.Payer_Account__c:' + so.Payer_Account__c);
        setSelectedAccounts();
        
        /******** Begin: AdPoint ********/
        if(so.source_system__c == DIGITAL_LABEL_AND_VALUE)
        {
            this.copyPlacerFromPayerAccount(); // sync placer and payer account
            this.doDigitalValidation();
        }
        /******** End: AdPoint ********/
    }

    public void onChangePlacerAccount()
    {
        system.debug('@ onChangePlacerAccount() so.Placer_Account__c:' + so.Placer_Account__c);
        setSelectedAccounts();
    }


    /****** begin: AdPoint ******/
    public void onChangeContact()
    {
        if(so.source_system__c == DIGITAL_LABEL_AND_VALUE)
        {
           this.doDigitalValidation();
        }
    }
    /****** end: AdPoint ******/

    ///// ACTIONS - End /////


    //// Change of Advertiser - Start /////
    
   // called on setting the advertiser account
    private void setFieldValues() {

        system.debug('@ setFieldValues()');

        if (getIsDirect()) // direct booking
        {
            setFieldValuesForDirectBookingType();
        }
        else if(getIsAgency()) //Agency Booking type
        {
            setFieldValuesForAgencyBookingType();
        }


        setSelectedAccounts();

        system.debug('so.Advertiser_Account__c:' + so.Advertiser_Account__c);
        system.debug('so.Payer_Account__c:' + so.Payer_Account__c);

    }   
    
    private void setFieldValuesForDirectBookingType() {
        system.debug('@ setFieldValuesForDirectBookingType()');
        if(so.Advertiser_Account__c==null &&
                accountSource!=null) //Advertiser not set and Account source not null
            {
                so.Advertiser_Account__c = accountSource.id;
                so.Payer_Account__c = so.Advertiser_Account__c;
                so.Placer_Account__c = so.Advertiser_Account__c;
                so.Planner_Account__c =  so.Advertiser_Account__c;
                so.Creative_Account__c =  so.Advertiser_Account__c;
                
                if(caseSource!=null)
                {
                    so.Contact__c =caseSource.ContactId;
                }
                else
                {
                
                    if(accountSource.recordType.DeveloperName == 'Private_Party')
                    {
                        so.Contact__c = accountSource.PersonContactId;
                    }
                    else if(accountSource.recordType.DeveloperName != 'Agency_Account_Type')
                    {
                        so.Contact__c = so.Advertiser_Account__r.Primary_Contact__c;
                    }
                    else 
                    {
                        so.Contact__c = accountSource.Primary_Contact__c;
                    }
                }
            }
            else if(so.Advertiser_Account__c!=null &&
                (accountSource==null && opptySource == null))
            {
                    so.Payer_Account__c = so.Advertiser_Account__c;
                    so.Placer_Account__c = so.Advertiser_Account__c;
                    so.Planner_Account__c =  so.Advertiser_Account__c;
                    so.Creative_Account__c =  so.Advertiser_Account__c;
                   
            }
    }
    

    private void setFieldValuesForAgencyBookingType() {
        system.debug('@ setFieldValuesForAgencyBookingType()');
        if(so.Advertiser_Account__c==null &&
                accountSource!=null)
         {
                system.debug('accountSource.recordType.DeveloperName: ' + accountSource.recordType.DeveloperName);
                if(accountSource.recordType.DeveloperName == 'Agency_Account_Type')
                {
                    so.Payer_Account__c = accountSource.id;
                    so.Placer_Account__c = accountSource.id;
                    so.Planner_Account__c =  accountSource.id;
                    so.Creative_Account__c =  accountSource.id;
                    so.Contact__c = accountSource.Primary_Contact__c;

                }
                else
                {
                    so.Advertiser_Account__c = accountSource.id;
                }       
         }   
    }

    
    //// Change of Advertiser - End //// 

    //// LIST Options - Start ////
    public List<SelectOption> targetSystems {
        get {
            system.debug('@ targetSystems() get');
            if (targetSystems == null) {
                targetSystems = new List<SelectOption>();

                list<string> availableBookingSystemList = new list<string>();
                set<String> availableBookingSystemSet = orderWrapper.availableBookingSystem.keySet();

                //Availability is checked before addding to the selction list
                if(availableBookingSystemSet.contains(GENERA_LABEL_AND_VALUE))
                    availableBookingSystemList.add(GENERA_LABEL_AND_VALUE);

                if(availableBookingSystemSet.contains(CYBER_LABEL_AND_VALUE))
                    availableBookingSystemList.add(CYBER_LABEL_AND_VALUE);

                if(availableBookingSystemSet.contains(DIGITAL_LABEL_AND_VALUE))
                    availableBookingSystemList.add(DIGITAL_LABEL_AND_VALUE);
                
                system.debug('availableBookingSystemList:' + availableBookingSystemList);
                
                
                list<string> availableSystems = new list<string>();
                for(string s : availableBookingSystemList)
                {
                    for(SelectOption sopt : orderWrapper.availableBookingSystem.get(s).keySet())
                    {
                        targetSystems.add (sopt);
                        if(!sopt.getDisabled())
                        {
                            availableSystems.add(sopt.getValue());
                        }
                    }
                }
                
                System.debug('@ targetSystems() get availableSystems:' + availableSystems);
                if(availableSystems.size()==1)
                {
                    so.Source_System__c = availableSystems[0];
                }
                
                if (targetSystems.size() > 1)
                    targetSystems.add(0, new SelectOption('', '--Select--'));
            }
            return targetSystems;
        }
        private set;
    }
    
    // Updated By Bohao Chen on 10/06/2014 for booking performance issue 
    // In order to display "--Select--" option in dropdown list
    public List<SelectOption> bookingTypes 
    {
        get {
            system.debug('@ bookingTypes() get');
            
            if (bookingTypes == null) 
            {
                Schema.DescribeFieldResult fieldResult = Sales_Order__c.Booking_Type__c.getDescribe();
                
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

                bookingTypes = new List<SelectOption>();
                bookingTypes.add(new SelectOption('', '--Select--'));
                        
                for(Schema.PicklistEntry f : ple)
                    bookingTypes.add(new SelectOption(f.getLabel(), f.getValue()));
            }
            return bookingTypes;
        }
        private set;
    }


    public List<SelectOption> cyberAdDivisions {
        get {
            system.debug('@ cyberAdDivisions() get');
            if (cyberAdDivisions == null) {
                cyberAdDivisions = orderWrapper.availableBookingSystem.get(CYBER_LABEL_AND_VALUE).values()[0];

                if(cyberAdDivisions.size()==1)
                {
                    so.Booking_Division__c = cyberAdDivisions[0].getValue(); 
                }
                else if(cyberAdDivisions.size()>1)
                {
                    cyberAdDivisions.add(0, new SelectOption('', '--Select--'));
                }

            }

            return cyberAdDivisions;
        }
        private set;
    }    
    
        
        public List<SelectOption> getPayerAccounts() {
        system.debug('@ getPayerAccounts()');
         //**********Jack added on 25th Feb 2014 to fix SFE-69 issue
        set<id> accountIDs = new set<id>();
        //**********
        List<SelectOption> payerAccounts = new List<SelectOption>();
            system.debug ('#payer advertiser: ' + so.Advertiser_Account__c);

        if (so.Advertiser_Account__c != null) {

            // for direct, payer is Advertiser
            if (!getIsAgency())
            {
                so.Payer_Account__c = so.Advertiser_Account__c; 
            }
            else
            {
                // Use Booking Accounts to get existing related payers for this Advertiser
                // ## cache on set advertiser??
                for (External_Account__c ea : [SELECT Genera_Name_Display__c, Id, External_Account__c, External_Account__r.Customer_Account__r.Id, External_Account__r.Customer_Account__r.Name, External_Id__c
                                               FROM External_Account__c
                                               WHERE Customer_Account__c = :so.Advertiser_Account__c
                                                 AND External_Account__c != null
                                                 AND External_Account__r.Status__c = 'Active'
                                                 AND Status__c = 'Active'
                                                 AND RecordType.DeveloperName = 'Booking_Account'])
                {
                       //**********Jack added on 25th Feb 2014 to fix SFE-69 issue
                    if(accountIDs.contains(ea.External_Account__r.Customer_Account__r.Id)==false){
                        payerAccounts.add(new SelectOption(ea.External_Account__r.Customer_Account__r.Id, ea.External_Account__r.Customer_Account__r.Name ));
                        accountIDs.add(ea.External_Account__r.Customer_Account__r.Id);
                    }
                    //**********
                }
                // if there is more than one 'valid' external account, force the user selection
                if (payerAccounts.size() > 1) {
                    payerAccounts.add(0, new SelectOption('', '--Select--'));
                }

                // add override option
               payerAccounts.add (new SelectOption('new', '--New Payer--'));

            }
            if (payerAccounts.size() == 2 && payerPicklistSelection!='new') {
                so.Payer_Account__c = payerAccounts.get(0).getValue();
                payerPicklistSelection = payerAccounts.get(0).getValue();
            }
        }
        return payerAccounts;
    }
    
    public List<SelectOption> getBookingAccounts() {
        system.debug('@ getBookingAccounts()');

        List<SelectOption> bookingAccounts;

        setSelectedAccounts();

        system.debug('so.Advertiser_Account__c:' + so.Advertiser_Account__c);
        system.debug('getIsAgency() :' + getIsAgency() );
        system.debug('so.Payer_Account__c:' + so.Payer_Account__c);

        if (this.selectedAdvertiser != null && selectedPayer!=null) {


            bookingAccounts = new List<SelectOption>();

            system.debug('@ call gbaHelper.getAvailableExternalAccount(...)');

            List<External_Account__c> lEa = gbaHelper.getAvailableExternalAccount(  selectedAdvertiser, // @accAdvertiser
                                                                                    selectedPayer,      // @accPayer
                                                                                    getIsAgency(),              // @isBookingTypeAgency
                                                                                    'Booking_Account'           // @externalAccountRecordTypeDeveloperName
                                                                                    );

            for (External_Account__c ea : lEa ) {
                // ## Replace 'pretty name' with formula
                // added by Tim Fabros 04 / 06 / 2014 - SFE-396
                // included an if statement for testing
                // BEGIN:
                System.debug('@SalesOrderCreateBookingv2_ControllerX ea: ' + ea);
                System.debug('@SalesOrderCreateBookingv2_ControllerX ea.Status__c: ' + ea.Status__c);
                if (ea.Status__c != 'Inactive') {
                    // modified by Tim Fabros 17 / 6 / 2014 - SFE-535
                    // added account type to be displayed in the GBA picklist by modifying Genera_Name_Display__c in the config.
                    // BEGIN:
                    bookingAccounts.add(new SelectOption(ea.Id, ea.Genera_Name_Display__c));
                    // END:
                }
                // END:
            }

            // if there is more than one 'valid' external account, force the user selection
            if (bookingAccounts.size() > 1) {
                bookingAccounts.add(0, new SelectOption('', '--Select--'));
            } else if (bookingAccounts.size() == 0) {
                bookingAccounts.add(new SelectOption('', '--Create GBA--'));
            } else
            {
                so.External_Account__c = bookingAccounts[0].getValue();
            }
            
            system.debug('ExternalAccountFormComponentController: ' + ExternalAccountFormComponentController);
            system.debug('ExternalAccountFormComponentController.gbaAccount: ' + ExternalAccountFormComponentController.gbaAccount);
            system.debug('ExternalAccountFormComponentController.gbaAccount.id: ' + ExternalAccountFormComponentController.gbaAccount.id);
            if(ExternalAccountFormComponentController!=null &&
                ExternalAccountFormComponentController.gbaAccount.id !=null)
                {
                    gbaAccount = ExternalAccountFormComponentController.gbaAccount;
                    so.External_Account__c = ExternalAccountFormComponentController.gbaAccount.id;
                    showAddNewGBAFlag=false;
                }            
        }

        return bookingAccounts;
    }    
    
    public List<SelectOption> getBillingAccounts() {
        system.debug('@ getBillingAccounts()');
        
        system.debug('@ getBillingAccounts() so.Advertiser_Account__c:' + so.Advertiser_Account__c);
        system.debug('@ getBillingAccounts() so.Booking_Division__c:' + so.Booking_Division__c);
        
        List<SelectOption> billingAccounts;

        if (so.Advertiser_Account__c != null && so.Booking_Division__c != null) {

            billingAccounts = new List<SelectOption>();
            // modified by Tim Fabros 04/ 06 / 2014 - SFE-396
            // added extra Where clause to prevent getting inactive accoutns
            // BEGIN:  
            for (External_Account__c ea : [SELECT Id, Name, Account_No__c, RecordType.Name, Division__c, Billing_Account_Name_Display__c
                                           FROM External_Account__c
                                           WHERE Customer_Account__c = :so.Advertiser_Account__c
                                             AND RecordType.DeveloperName = 'Billing_Account'
                                             AND Account_Type__c != 'Private Party'
                                             AND Account_Type__c != 'Casual Business'
                                             AND Account_Type__c != 'Casual'
                                             AND Account_Type__c != 'Transient'
                                             AND Account_Type__c !='Non Established'
                                             AND Division__c = :so.Booking_Division__c
                                             AND Status__c != 'Inactive']
                                             ) {
                // ## Replace 'pretty name' with formula
                billingAccounts.add(new SelectOption(ea.Id, ea.Billing_Account_Name_Display__c));
            }
            // END:

            // if there is more than one 'valid' external account, force the user selection
            if (billingAccounts.size() > 1) {
                billingAccounts.add(0, new SelectOption('', '--Select--'));
            } else if (billingAccounts.size() == 0) {
                billingAccounts.add(new SelectOption('', '--Casual--'));
            }else
            {
                so.External_Account__c = billingAccounts[0].getValue();
            }
        }
        return billingAccounts;
    }
    //// LIST Options - End ////





    //// T-Number search - Start ////
    public boolean showTNumberSearchFlag {public get{return showTNumberSearchFlag = showTNumberSearchFlag!=null?showTNumberSearchFlag:false;} private set;}
    public string tNumberSearch{get;set;}
    public list<External_Account__c> tNumberResult{public get; private set;}


    public void doTNumberSearch()
    {
        system.debug('@ doTNumberSearch()');

        if(tNumberSearch.trim().length()>5){
            tNumberResult = new list<External_Account__c>();
            
            // Updated by Bohao Chen on 10/06/2014 for booking UI performance enhancement JIRA SFE-20
            // Begin
            if (!getIsAgency()) 
            {
                tNumberResult= [Select Account_No__c, Id, Name, ABN_Number__c, Customer_Account__r.Name, Customer_Account__r.Phone                
                                From External_Account__c
                                WHERE Account_No__c =:tNumberSearch
                                AND recordType.DeveloperName = 'Booking_Account'
                                AND status__c = 'Active'
                                AND External_Account__c = null];
            }
            else
            {
                tNumberResult= [Select Account_No__c, Id, Name, ABN_Number__c, Customer_Account__r.Name, Customer_Account__r.Phone
                                From External_Account__c e
                                WHERE Account_No__c =:tNumberSearch
                                AND recordType.DeveloperName = 'Booking_Account'
                                AND External_Account__c != null
                                AND External_Account__r.Status__c = 'Active'
                                AND status__c = 'Active'];                                                      
            }
            // End

            /**
            * Tweaked LMancilla
            * May 21 2014
            * Message on page when no results
            **/
            if(tNumberResult.size()==0) ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'No result found. Please check your search criteria and try again.'));
            /** End tweak **/
        }
    }

    public void doSelectTNumber()
    {                                      
        string selectedExternalAccountId = ApexPages.currentPage().getParameters().get('selectedExternalAccountId');
        system.debug('selectedExternalAccountId:' + selectedExternalAccountId);

        // Updated by Bohao Chen on 10/6/2014 for JIRA issue SFE-544
        // Begin
        if(String.isNotBlank(selectedExternalAccountId))
        {
            List<External_Account__c> externalAccounts = [Select e.Customer_Account__r.Id, External_Account__r.Status__c                                                                 
                                                        From External_Account__c e
                                                        WHERE Id =: selectedExternalAccountId];

            if(externalAccounts.size() > 0)
            {
                External_Account__c externalAccount = externalAccounts[0];
                so.Advertiser_Account__c = externalAccount.Customer_Account__r.id;

                if(externalAccount.External_Account__r.Status__c != 'Active')
                {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.Error, 'The parent of the selected booking system account is inactive. Please Contact your administrator'));
                    return;
                }

                //## STU Set Payer & Placer if direct
                //## logic need rework to handle Agency case properly
                if (!getIsAgency()) {
                    so.Payer_Account__c = externalAccount.Customer_Account__r.id;
                    so.Placer_Account__c = externalAccount.Customer_Account__r.id;  
                }

                so.External_Account__c = externalAccount.id;
                
                gbaAccount = externalAccount;
                //findAccountResults=null;
                //changeAdvertiser();

                // ####### STU
                // needs rework - unnecessary re-queries
                setSelectedAccounts();
                // ####### 
            }
            else
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Selected booking system account cannot be found in the system. Please contact your administrator'));
            }
        }
        // End
     }
    //// T-Number search - Start ////  


    //// Booking Account - Start ////
    
    
     public void showAddNewGBA()
        {
            system.debug('@ showAddNewGBA()');
            system.debug('so.Booking_Type__c:' + so.Booking_Type__c);
            gbaHelper = new ExternalAccountCreateGBA_Helper();
            
            gbaAccount = new External_Account__c();
            gbaAccount.Customer_Account__c = so.Advertiser_Account__c;
    
            setSelectedAccounts();
    
            //selectedAccountRecordTypeName = selectedAdvertiser.RecordType.name;
    
            prepopulateExternalAccountFromAccount(selectedAdvertiser, selectedPayer);
    
            list<External_Account__c> parentGBAlist = gbaHelper.getAccountDirectExternalAccount(    selectedPayer,    // @accId
                                                                                                    'Booking_Account' // @externalAccountRecordTypeDeveloperName
    
                                                                                                );
            system.debug('^^^ parentGBAlist:' + parentGBAlist);
            if(getIsAgency() && (parentGBAlist==null || parentGBAlist.size()==0))
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'You cannot proceed, parent External Account for selected payer do not exist'));
            }
            else
            {
                showAddNewGBAFlag=true;
            }
        }
    
    
    
     

    //// Booking Account - Start ////


    //// NEW PAYER CONTACT - Start ////
    public boolean showAddNewPayerContactFlag {public get{return showAddNewPayerContactFlag = showAddNewPayerContactFlag!=null?showAddNewPayerContactFlag:false;} private set;}
    public Contact newPayerContact
    {
        get
        {
            if(newPayerContact==null)
            {
                newPayerContact =new Contact();
                newPayerContact.Accountid = so.Placer_Account__c;
                if(selectedPlacer!=null && selectedPlacer.Phone!=null)
                    newPayerContact.Phone =  selectedPlacer.Phone;
            }
            return newPayerContact;
        }
        set;
    }


    public void showAddNewPayerContactFlag()
    {
        system.debug('@ showAddNewPayerContact()');
            showAddNewPayerContactFlag=true;
            newPayerContact = new Contact();
            newPayerContact.Accountid = so.Placer_Account__c;

            if(selectedPlacer!=null && selectedPlacer.Phone!=null)
                newPayerContact.Phone =  selectedPlacer.Phone;
            
            newPayerContact.Contact_Status__c = 'Active';
    }


    public void cancelAddNewPayerContact()
    {
        system.debug('@ cancelAddNewPayerContact()');
        showAddNewPayerContactFlag=false;
        newPayerContact = new Contact();
        newPayerContact.Accountid = so.Placer_Account__c;
        newPayerContact.Contact_Status__c = 'Active';
        if(selectedPlacer!=null && selectedPlacer.Phone!=null)
            newPayerContact.Phone =  selectedPlacer.Phone;
    }

    public PageReference saveAddNewPayerContact()
    {
        system.debug('@ saveAddNewPayerContact()');

        try
        {
            /*********** Start: AdPoint *************/
            // if source system is 'AdPoint' link contact to account
            if(so.Source_System__c == DIGITAL_LABEL_AND_VALUE)
            {
                if(so.Placer_Account__c == null)
                {
                    this.doDigitalValidation();
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please choose a payer account first.'));
                    return null;
                }
                else
                    newPayerContact.AccountId = so.Placer_Account__c;
                                    
                newPayerContact.Delay_Digital_Creation__c = true;
            }
            /********** End: adPoint ***********/

            insert newPayerContact;
            
            so.contact__c = newPayerContact.id;
            system.debug('so.contact__c:' + so.contact__c);
            showAddNewPayerContactFlag=false;
            
            if(so.Source_System__c == DIGITAL_LABEL_AND_VALUE)
            {
               this.doDigitalValidation();
            }
        }
        catch (Exception ex){
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
            return null;
        }
        
        return null;
    }
    //// NEW PAYER CONTACT - End ////

    public PageReference doBook()
    {
        system.debug('@ doBook()');
        if( so.Booking_Type__c == null ||
            (so.Source_System__c == null ||
            (so.Source_System__c == CYBER_LABEL_AND_VALUE &&
            so.Booking_Division__c == null)))
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Make sure Booking Type and System is selected'));
        }
    
        if(so.Advertiser_Account__c == null ||
            so.Payer_Account__c == null)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Make sure that Advertiser and Payer is selected'));
        }

        if(so.Source_System__c == GENERA_LABEL_AND_VALUE &&
            so.External_Account__c == null)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Make sure a Booking account is selected'));
        }

        system.debug(loggingLevel.error, '@ doBook() ApexPages.hasMessages(): ' + ApexPages.hasMessages());
        
        /******** Begin: AdPoint ********/
        this.copyPlacerFromPayerAccount(); // sync placer and payer account
        /******** End: AdPoint ********/
    
        try
        {
            if(!ApexPages.hasMessages())
            {
                system.debug(loggingLevel.error, '@ doBook()');
                so = orderWrapper.createBooking();
                 
                system.debug(loggingLevel.error, 'so:' + so);
                isBookingReady = true;
            }
        }
        catch(SalesOrderCreateBooking_Helper.SalesOrderCreateException ex)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
            isBookingReady = false;
            system.debug(logginglevel.error, '@doBook exception: ' + ex.getMessage());
        }
        catch(Exception ex) {
            //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Make sure all the information has been entered before pressing the Book button'));
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, ex.getMessage()));
            isBookingReady = false;
            system.debug(logginglevel.error, '@doBook exception: ' + ex.getMessage());
        }

        /*if(so.Source_system__c == DIGITAL_LABEL_AND_VALUE)
        {
            String bookingId = this.createOrderInAdPointCp(so.Advertiser_Account__c, so.Payer_Account__c, so.Contact__c, so.Id);
            PageReference adPointOrderPg = Page.AdPointOrder;
            adPointOrderPg.getParameters().put('id', bookingId);
            adPointOrderPg.getParameters().put('s', String.valueOf(showHeaderAndSidebar));
            return adPointOrderPg;
        }*/
        
        return null;
   }

    public PageReference cancelAndRedirectToSource()
    {

        PageReference pr = null;

            system.debug('salesOrderSource:' + salesOrderSource);
            system.debug('opptySource:' + opptySource);
            system.debug('caseSource:' + caseSource);
            system.debug('accountSource:' + accountSource);

            system.debug(accountSource!=null);

            if(salesOrderSource!=null)
            {
                pr = new ApexPages.StandardController(salesOrderSource).view();
            }
            else if(opptySource!=null)
            {
                pr = new ApexPages.StandardController(opptySource).view();
            }
            else if(caseSource!=null)
            {
                pr = new ApexPages.StandardController(caseSource).view();
            }
            else if(accountSource!=null)
            {
                system.debug('here');
                pr = new ApexPages.StandardController(accountSource).view();
            }

        if(pr==null)
        {
            String soPrefix = Schema.SObjectType.Sales_Order__c.getKeyPrefix();
            pr = new pageReference('/' + soPrefix + '/o');
        }

        return pr;

    }

    /************ AdPoint **********/
    // this method will make digital account and contacts if they are not yet digital
    public PageReference makeDigital()
    {
        system.debug('@SalesOrderCreateBookingv2_AdPoint_CtrX makeDigital');
        
        // retrieve advertiser account, placer account and contact details
        // Update by Bohao Chen on 14 August, 2014 for JIRA issue SFE-584
        // BEGIN
        Account advertiserAcct = [Select Id, Digital_Status__c, is_Digital__c, AdPoint_Id__c, Name,
                                  AccountNumber, Account_Type__c, BillingCity, BillingCountry, AdPoint_User_Id__c,
                                  BillingPostalCode, BillingState, BillingStreet, Blacklist_Reason_Digital__c,
                                  Revenue_Group__c,Creative_Agency_For_Digital_Customer__c, Fax, Industry_Code_Name_In_Text__c,
                                  Is_on_Black_List_Digital_Media__c, Media_Agency_For_Digital_Customer__c,
                                  OwnerId, Phone, ShippingCity, ShippingCountry, ShippingPostalCode,
                                  ShippingState, ShippingStreet, Status__c, Website, Is_Agency__c, Creative_Agency_AdPoint_Id__c,
                                  Media_Agency_AdPoint_Id__c, Industry_Code__c
                                  From Account 
                                  Where Id =: so.Advertiser_Account__c Limit 1];
        
        Account payerAcct = [Select Digital_Status__c, is_Digital__c, AdPoint_Id__c, Name, Industry_Code__c,Revenue_Group__c
                             From Account 
                             Where Id =: so.Payer_Account__c Limit 1];
        // END
        Contact con = [Select Id, Digital_Status__c, AdPoint_Id__c, FirstName, LastName, AccountId, 
                       Email, Fax, MobilePhone, Phone, Salutation, Title
                       From Contact 
                       Where Id =: so.Contact__c Limit 1];
                           
        if(String.isNotBlank(advertiserAcct.Digital_Status__c) && advertiserAcct.Digital_Status__c != 'Active' ||
           String.isNotBlank(con.Digital_Status__c) && con.Digital_Status__c != 'Active' ||
           advertiserAcct.Revenue_Group__c == null ||  payerAcct.Revenue_Group__c == null ||
           String.isNotBlank(payerAcct.Digital_Status__c) && payerAcct.Digital_Status__c != 'Active' ||
           advertiserAcct.Industry_Code__c == null ||
           payerAcct.Industry_Code__c == null)
        {
            if(String.isNotBlank(advertiserAcct.Digital_Status__c) && advertiserAcct.Digital_Status__c != 'Active')
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MAKING_DIGITAL_ADVERTISER_ACCT_IN_PROGRESS));
            }
            
            if(String.isNotBlank(con.Digital_Status__c) && con.Digital_Status__c != 'Active')
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MAKING_DIGITAL_CONTACT_IN_PROGRESS));
            }
            
            if(String.isNotBlank(payerAcct.Digital_Status__c) && payerAcct.Digital_Status__c != 'Active')
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, MAKING_DIGITAL_PAYER_ACCT_IN_PROGRESS));
            }

            // added by Tim Fabros 14 / 08 / 2014 - SFE-584
            // BEGIN:
            if (advertiserAcct.Industry_Code__c == null)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'The Advertiser\'s industry code is blank. Please go into this account and populate this field.'));
            }

            if (payerAcct.Industry_Code__c == null)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'The Payer Account\'s industry code is blank. Please go into this account and populate this field.'));
            }
            
            // END:
                if (advertiserAcct.Revenue_Group__c == null)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'The Advertiser\'s Revenue Group is blank. Please go into this account and populate this field.'));
            }

            if (payerAcct.Revenue_Group__c == null)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'The Payer Account\'s Revenue Group is blank. Please go into this account and populate this field.'));
            }    
                
                
            
            return null;
        }
        else if(this.isAdPointBookingSystem)
        {
            system.debug(logginglevel.error, '===making Digital=== ');
            
            AdPointWebserviceStub.adPointAccountSyncResponse advertiserAcctResp;
            //AdPointWebserviceStub.adPointAccountSyncResponse payerAcctResp;
            AdPointWebserviceStub.adPointContactSyncResponse contactResp;
            
            // send webservice request to create digital customer 
            // if advertiser account is not digital
            if(!this.isAdvertiserAccountDigital)
            {
                try
                {
                    // get adpoint user id based on current running user id
                    String adPointUserId = [Select c.AdPoint_User_Id__c 
                                            From CyberAd_User_Credential__c c 
                                            Where c.User__c =: UserInfo.getUserId()
                                            And c.RecordType.DeveloperName =: DIGITAL_LABEL_AND_VALUE
                                            Limit 1].AdPoint_User_Id__c;
                       
                    if(Test.isRunningTest())
                    {
                        system.debug('@running test for make digital');
                        
                        advertiserAcctResp = new AdPointWebserviceStub.adPointAccountSyncResponse();
                        
                        if(this.isMakingAcctDigitalSuccess)
                        {
                            advertiserAcctResp.status = SUCCESS_WS_STATUS;
                        }
                        else
                        {
                            advertiserAcctResp.status = 'FAIL';
                        }
                    }
                    else
                    {
                        system.debug('@running make digital');
                        advertiserAcctResp = this.adPointWebserviceHelper.createDigitalAccount(advertiserAcct, so);
                    }
                    
                    system.debug('@SalesOrderCreateBookingv2_AdPoint_CtrX makedigital advertiserAcctResp status: ' + advertiserAcctResp.status);
                    
                    if(advertiserAcctResp.status != SUCCESS_WS_STATUS)
                    {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, WS_CREATE_DIGITAL_ADVERTISER_ERROR));
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, advertiserAcctResp.errorDetails));  
                    }
                }
                catch(Exception e) {ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));}
                
            }

            // send webservice request to create digital agency
            // if placer account is different from advertiser account
            /*if(!this.isPayerAccountDigital && so.Advertiser_Account__c != so.Payer_Account__c)
            {
                payerAcctResp = this.adPointWebserviceHelper.createDigitalAccount(payerAcct);
                
                system.debug('@SalesOrderCreateBookingv2_AdPoint_CtrX makedigital payerAcctResp status: ' + payerAcctResp.status);
                
                if(payerAcctResp.status != SUCCESS_WS_STATUS)
                {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, WS_CREATE_DIGITAL_PAYER_ERROR));  
                }
            }*/
            
            // send webservice request to create digital contact
            // if contact is not digital contact
            if(!this.isContactDigital)
            {
                String accountAdPointId;
                
                // since we need contact account adpoint id for webservice call to create digital contact,
                // we need to find out contact account AdPoint Id.
                // If advertiser account is not digital, we get its adpoint id from previous webservice call,
                // else if advertiser is digital, we get its adpoint id from account record details
                if(Test.isRunningTest())
                {
                    accountAdPointId = '1234';
                }
                else
                {
                    if(so.Advertiser_Account__c != so.Payer_Account__c)
                    {
                        if(payerAcct != null && String.isNotBlank(payerAcct.AdPoint_Id__c))
                        {
                            accountAdPointId = payerAcct.AdPoint_Id__c;
                        }
                        else
                        {
                            // should not come to this line
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Payer Account is not digital account'));
                        }
                    }
                    else
                    {
                        if(advertiserAcctResp != null && advertiserAcctResp.status == SUCCESS_WS_STATUS)
                        {
                            accountAdPointId = advertiserAcctResp.crmAdPointResponse.AdPoint_Id_xc;
                        }
                        else if(String.isNotBlank(advertiserAcct.AdPoint_Id__c))
                        {
                            accountAdPointId = advertiserAcct.AdPoint_Id__c;
                        }
                        else
                        {
                            // should not come to this line
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Advertiser Account is not digital account'));
                        }
                    }
                }

                system.debug(logginglevel.error, '@SalesOrderCreateBookingv2_AdPoint_CtrX makeDigital accountAdPointId: ' + accountAdPointId);
                
                // if contact account AdPoint Id found, create digital contact in AdPoint
                // otherwise, we assume there is an error when try to create digital account previously
                if(accountAdPointId != null)
                {
                    try
                    {
                        if(Test.isRunningTest())
                        {
                            contactResp = new AdPointWebserviceStub.adPointContactSyncResponse();
                            
                            if(this.isMakingContactDigitalSuccess)
                            {
                                contactResp.status = SUCCESS_WS_STATUS;
                            }
                            else
                            {
                                contactResp.status = 'FAIL';
                            }
                        }
                        else
                        {
                            contactResp = this.adPointWebserviceHelper.createDigitalContact(con, accountAdPointId);
                        }  
                        
                        system.debug(logginglevel.error, '@SalesOrderCreateBookingv2_AdPoint_CtrX makedigital contactResp status: ' + contactResp.status);
                        
                        if(contactResp.status != SUCCESS_WS_STATUS)
                        {
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, WS_CREATE_DIGITAL_CONTACT_ERROR));
                            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, contactResp.errorDetails));  
                        }
                    }catch(Exception e) {ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));}
                }
            }
            
            // go through each response and check response status
            // then update advertiser accounts, payer accounts and contact
            if(!this.isAdvertiserAccountDigital && advertiserAcctResp != null && advertiserAcctResp.status == SUCCESS_WS_STATUS)
            {
                system.debug(logginglevel.error, 'update advertiser account to digital');
                
                try
                {
                    // if contact is not digital, change digital status to 'Pending'
                    // in order to prevent contact from updating by outbound message when
                    // its account gets updated
                    if(!this.isContactDigital && con.Digital_Status__c == null)
                    {
                        con.Digital_Status__c = 'Requested';
                        update con;                     
                    }
                
                    // update advertiser account in SFDC if ws callout is succeeded
                    advertiserAcct.Digital_Status__c = 'Active';
                    advertiserAcct.Is_Digital__c = true;
                    if(Test.isRunningTest())
                    {
                        advertiserAcct.AdPoint_Id__c = '1234';
                    }
                    else
                    {
                        advertiserAcct.AdPoint_Id__c = advertiserAcctResp.crmAdPointResponse.AdPoint_Id_xc;
                    }
                    
                    system.debug(logginglevel.error, 'before advertiser account gets updated to digital ' + advertiserAcct);
                    update advertiserAcct; 
                    system.debug(logginglevel.error, 'after advertiser account gets updated to digital ' + advertiserAcct);
                }
                catch(Exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                    return null;
                }
            }
            
            /*if(!this.isPayerAccountDigital && so.Advertiser_Account__c != so.Payer_Account__c && payerAcctResp.status == SUCCESS_WS_STATUS)
            {
                try
                {
                    // if contact is not digital and it doesn't gets update previously
                    // change digital status to 'Pending'
                    // in order to prevent contact from updating by outbound message when
                    // its account gets updated
                    if(!this.isContactDigital && con.Digital_Status__c == null)
                    {
                        con.Digital_Status__c = 'Pending';
                        update con;
                    }
                
                    // update advertiser account in SFDC if ws callout is succeeded
                    payerAcct.Digital_Status__c = 'Active';
                    payerAcct.Is_Digital__c = true;
                    payerAcct.AdPoint_Id__c = payerAcct.Id; //TODO:
                    //payerAcct.AdPoint_Id__c = payerAcctResp.salesForceAdPointContactResponse.AdPoint_Id_xc; // TODO: uncomment this line when ready
                    update payerAcct;
                }
                catch(Exception e){
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                    return null;
                }
            }*/
            
            if(!this.isContactDigital && contactResp != null && contactResp.status == SUCCESS_WS_STATUS)
            {
                system.debug(logginglevel.error, 'update contact to digital');
                
                try
                {
                    if(Test.isRunningTest())
                    {
                        con.AdPoint_Id__c = '4567';
                    }
                    else
                    {
                        con.AdPoint_Id__c = contactResp.adPointContactResponse.AdPoint_Id_xc; 
                    }
                    
                    system.debug(logginglevel.error, '@contact AdPoint_Id__c: ' + con.AdPoint_Id__c);
                    
                    con.Digital_Status__c = 'Active';
                    
                    system.debug(logginglevel.error, 'before contact gets updated to digital ' + con);
                    update con;
                    system.debug(logginglevel.error, 'after contact gets updated to digital ' + con);
                    
                }
                catch(Exception e) 
                {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                    if(con.Digital_Status__c == 'Requested')
                    {
                        con.Digital_Status__c = '';
                        update con;
                    }
                    return null;
                }
            }
            else
            {
                if(con.Digital_Status__c == 'Requested')
                {
                    con.Digital_Status__c = '';
                    update con;
                }
            }
        }
        
        // validate digital accounts and contact
        if(so.Source_system__c == DIGITAL_LABEL_AND_VALUE)
            this.doDigitalValidation();
        
        return null;
    }
    
    private void validateDigitalAdvertiserAccount()
    {
        if(this.isAdPointBookingSystem && this.so.Advertiser_Account__c != null)
        {
            Account acct = [Select RecordType.DeveloperName, Digital_Status__c, Status__c, AdPoint_Id__c
                            From Account 
                            Where Id =: so.Advertiser_Account__c limit 1];
            

            //Added LMancilla
            //SFE-634 Do not let Agency Accounts be the advertiser account. Disable 'Book' button on VF page
            if(acct.RecordType.DeveloperName == 'Agency_Account_Type'){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, ADVERTISER_INVALID_TYPE));   
                hasWarningMsg = true;               
            }
            //End LMancilla
            
            if(acct.RecordType.DeveloperName == 'Private_Party')
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, PRIVATE_PARTY_ADVERTISER_ACCT_MSG));
                hasErrorMsg = true;
            }
            
            if(acct.Digital_Status__c != 'Active' || String.isBlank(acct.AdPoint_Id__c))
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, NON_DIGITAL_ADVERTISER_ACCT_MSG));   
                hasWarningMsg = true;                    
            }
            
            if(acct.Status__c != 'Active')
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, ADVERTISER_ACCOUNT_INACTIVE));      
                hasErrorMsg = true;
            }
        }
    }
    
    private void validateDigitalPayerAccount()
    {
        if(this.isAdPointBookingSystem && this.so.Payer_Account__c != null)
        {
            Account payerAccount = [Select RecordType.DeveloperName, Digital_Status__c, Is_on_Black_List_Digital_Media__c, 
                                    Is_Agency__c, Master_Digital_Status__c, Status__c, AdPoint_Id__c
                                    From Account 
                                    Where Id =: so.Payer_Account__c 
                                    limit 1];
            
            if(payerAccount.RecordType.DeveloperName == 'Private_Party')
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, PRIVATE_PARTY_PAYER_ACCT_MSG));       
                hasErrorMsg = true;  
            }
            
            // if booking type is 'agency'
            // 1. check if payer account is agency account
            // 2. throw error message if agency account is not digital
            // if booking type is 'direct'
            // 1. throw warning message if agency account is digital
            if(this.getIsAgency())
            {
                if(!payerAccount.Is_Agency__c)
                {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, NON_AGENCY_PAYER));
                    hasErrorMsg = true; 
                }
                else if(payerAccount.Digital_Status__c != 'Active' || String.isBlank(payerAccount.AdPoint_Id__c))
                {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, NON_DIGITAL_AGENCY_PAYER_ACCT_MSG));
                    hasErrorMsg = true; 
                }
            }
            else if(this.getIsDirect())
            {
                if(payerAccount.Digital_Status__c != 'Active' || String.isBlank(payerAccount.AdPoint_Id__c))
                {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, NON_DIGITAL_PAYER_ACCT_MSG));
                    hasWarningMsg = true; 
                }
            }
            
            if(payerAccount.Status__c != 'Active')
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, PAYER_ACCOUNT_INACTIVE));      
                hasErrorMsg = true;
            }

            if(payerAccount.Is_on_Black_List_Digital_Media__c)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, BLACKLIST_ACCT_MSG));  
                hasErrorMsg = true;
            }
        }
    }
    
    // TODO: has to update this method to have query statement
    private void validateDigitalContact()
    {
        if(this.isAdPointBookingSystem && this.so.Contact__c != null)
        { 
            Contact c = [Select Digital_Status__c, AccountId, AdPoint_Id__c From Contact Where Id =: so.Contact__c Limit 1];
            
            if(!(so.Payer_Account__c != null && c.AccountId == so.Payer_Account__c))
            {
                if(so.Payer_Account__c == null)
                {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, NULL_PAYER_ACCOUNT));
                    hasErrorMsg = true; 
                }
                
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, INVALID_ACCOUNT_CONTACT_REL_MSG));
                hasErrorMsg = true; 
            }  
            
            if(c.Digital_Status__c != 'Active' || String.isBlank(c.AdPoint_Id__c))
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Warning, NON_DIGITAL_CONTACT_MSG));
                hasWarningMsg = true; 
            }
        }  
    }

    // if source system is AdPoint, it needs to make sure placer account (hidden field) has to be the same as payer account
    private void copyPlacerFromPayerAccount()
    {
        if(this.isAdPointBookingSystem)
        {
            so.Placer_Account__c = so.Payer_Account__c;
        }
    }   
    
    // when user is making adpoint agency booking and media agency/creative agency is not empty 
    // we have to prepopulate payer/creative accounts, rules are follows: 
    // 1. From the Account record when a booking is initiated for a non-agency, 
    // CRM will default the relevant placer, payer and creative from the account.
    // 2. From the Opportunity record when a booking is initiated for a non-agency and there are no payer or contacts associated; 
    // CRM will default the relevant placer, payer, and creative fields from the account
    // 3. From the Case record when a booking is initiated for a non-agency and there are no payer/ planner or contacts associated; 
    // CRM will default the relevant placer, payer, and creative fields from the account
    private void populateAccounts()
    {
        if(this.isAdPointBookingSystem)
        {
            // if entry point is from account
            Id payerAccountId;
            Id creativeAccountId;
            Id placerAccountId;
            Id contactId;
            
            system.debug('@populateAccounts');
            
            if(this.caseSource != null && this.caseSource.Opportunity__c == null && this.caseSource.AccountId != null)
            {
                system.debug('@accountId from case: ' + this.caseSource.AccountId);
                system.debug('@contactId from case: ' + this.caseSource.ContactId);
                
                
                Account acct = [Select Media_Agency_For_Digital_Customer__c, Creative_Agency_For_Digital_Customer__c, RecordType.DeveloperName
                                From Account 
                                Where Id =: this.caseSource.AccountId Limit 1];
                
                if(acct.RecordType.DeveloperName != 'Agency_Account_Type')
                {           
                    payerAccountId = acct.Media_Agency_For_Digital_Customer__c;
                    creativeAccountId = acct.Creative_Agency_For_Digital_Customer__c;
                    contactId = this.caseSource.ContactId;
                }  
            }
            else if(this.accountSource != null && this.accountSource.RecordType.DeveloperName != 'Agency_Account_Type')
            {
                payerAccountId = this.accountSource.Media_Agency_For_Digital_Customer__c;
                creativeAccountId = this.accountSource.Creative_Agency_For_Digital_Customer__c;
            }
            else if(this.opptySource != null)
            {
                system.debug('@populateAccounts from Opportunity: ' + this.opptySource.AccountId);
                
                Account acct = [Select Media_Agency_For_Digital_Customer__c, Creative_Agency_For_Digital_Customer__c, RecordType.DeveloperName
                                From Account 
                                Where Id =: this.opptySource.AccountId Limit 1];
                
                if(acct.RecordType.DeveloperName != 'Agency_Account_Type')
                {           
                    if(this.opptySource.Payer_Account__c == null)
                    {
                        payerAccountId = acct.Media_Agency_For_Digital_Customer__c;
                    }
                    
                    creativeAccountId = acct.Creative_Agency_For_Digital_Customer__c;
                    
                    contactId = this.opptySource.Contact__c;
                }
            }
            
            if(this.so.Payer_Account__c == null)
                this.so.Payer_Account__c = payerAccountId;
            if(this.so.Creative_Account__c == null)
                this.so.Creative_Account__c = creativeAccountId;
            if(this.so.Placer_Account__c == null)
                this.so.Placer_Account__c = this.so.Payer_Account__c;
            if(this.so.Contact__c == null)
                this.so.Contact__c = contactId;
        }
    }
    
    private void doDigitalValidation()
    {
        hasErrorMsg = false;
        hasWarningMsg = false;
        
        system.debug('@doDigitalValidation advertiser account: ' + so.Advertiser_Account__c);
        system.debug('@doDigitalValidation payer account: ' + so.Payer_Account__c);
        system.debug('@doDigitalValidation placer account: ' + so.Placer_Account__c); 
        
        this.validateRunningUser();
        this.validateDigitalAdvertiserAccount();
        this.validateDigitalPayerAccount();
        this.validateDigitalContact();
    }
    
    private void validateRunningUser()
    {
        try
        {
            CyberAd_User_Credential__c userCredential = [Select c.AdPoint_User_Id__c, c.Login_Access__c
                                                        From CyberAd_User_Credential__c c 
                                                        Where c.User__c =: userInfo.getUserId()
                                                        And c.RecordType.Name =: DIGITAL_LABEL_AND_VALUE limit 1];
            
            runningUserAdPointUserId = userCredential.AdPoint_User_Id__c;
            Boolean hasLoginAccess = userCredential.Login_Access__c;
            
            if(String.isBlank(runningUserAdPointUserId))
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, INVALID_ADPOINT_USER_ID));
                hasErrorMsg = true;
            }
            
            if(!hasLoginAccess)
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, NO_LOGIN_ACCESS));
                hasErrorMsg = true;
            }
            
            networkUsername = [Select u.Network_Username__c From User u Where u.Id =: userInfo.getUserId() limit 1].Network_Username__c;
              
            if(String.isBlank(networkUsername))
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, INVALID_NETWORK_USERNAME));
                hasErrorMsg = true;
            }
        }catch(QueryException ex) 
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, 
                'Current logged-in user doesn\'t exist in External System User Credentials table. Please contact administrator to set the record.'));
            hasErrorMsg = true;
        }
    }
    
    // Updated by Bohao Chen on 5/06/2014 for JIRA SFE-202
    // In case of webService fails, user needs to use "Add Booking" button on sales order page to send webService request to AdPoint
    webService static String createOrderInAdPointFromAddBookingButton(String advertiserAccountId, String payerAccountId, 
                                                                    String contactId, String salesOrderId, Boolean fromBookingUI)
    {
        try
        {
            system.debug('@createOrderInAdPointFromAddBookingButton advertiserAccountId: ' + advertiserAccountId);
            system.debug('@createOrderInAdPointFromAddBookingButton payerAccountId: ' + payerAccountId);
            system.debug('@createOrderInAdPointFromAddBookingButton contactId: ' + contactId);
            system.debug('@createOrderInAdPointFromAddBookingButton salesOrderId: ' + salesOrderId);
            system.debug('@createOrderInAdPointFromAddBookingButton fromBookingUI: ' + fromBookingUI);

            return SalesOrderCreateBookingv2_ControllerX.createOrderInAdPoint(advertiserAccountId, payerAccountId, contactId, salesOrderId, fromBookingUI);
        }
        catch (Exception e)
        {
            throw e;
            return null;
        }
    }
    // End

    //private Boolean checkAccountRequire
    
    // if source system is AdPoint, we will send out create order webservice call.
    // if web service call fails, delete the sales order and notify user
    // else, redirect user to adpoint booking page by using adpoint order id
    @RemoteAction
    global static String createOrderInAdPoint(String advertiserAccountId, String payerAccountId, 
                                                    String contactId, String salesOrderId, Boolean fromBookingUI)
    {
        system.debug('@SalesOrderCreateBookingv2_AdPoint_CtrX createOrderInAdPointRemote ');
        
        Pattern monthPattern = Pattern.compile('\\b([0-9])\\b');
        
        // modified by Tim Fabros 20 / 06 / 2014 - SFE-270
        // added Campaign__r.Name, Campaign__c to the query
        // BEGIN:
        Sales_Order__c salesOrder = [Select External_Id__c, Name, Advertiser_Account__c, Calc_External_id__c, 
                                        Creative_Account__c, Payer_Account__c, Placer_Account__c, OwnerId, Campaign__r.Name, Campaign__c, booking_Type__c
                                        From Sales_Order__c 
                                        Where Id =: salesOrderId Limit 1];
        // END:

        // retrieve advertiser account, placer account, contact and sales order details
        Account advertiserAcct = [Select AdPoint_Id__c, Name, Industry_Code_Name_In_Text__c,Revenue_Group__c,datasan__Account_ABN__c 
                                  From Account 
                                  Where Id =: advertiserAccountId Limit 1];
        
        Account payerAcct = [Select AdPoint_Id__c, Name, Industry_Code_Name_In_Text__c ,Revenue_Group__c,datasan__Account_ABN__c
                             From Account 
                             Where Id =: payerAccountId Limit 1];
        
        Contact con = [Select AdPoint_Id__c, AccountId, Email
                        From Contact 
                        Where Id =: contactId Limit 1];

        AdPointWebserviceStub_Helper adPointWebserviceHelper = new AdPointWebserviceStub_Helper();
        
        AdPointWebserviceStub.adPointCreateOrderResponse orderResp;
        
        if(Test.isRunningTest())
        {
            orderResp = new AdPointWebserviceStub.adPointCreateOrderResponse();
            orderResp.status = 'OK';
            
            AdPointWebserviceStub.crmAdPointOrder crmAdPointOrder = new AdPointWebserviceStub.crmAdPointOrder();
            crmAdPointOrder.AdPointOrder_ID = '9876';
            
            orderResp.adPointCreateOrderResponse = crmAdPointOrder;
        }   
        else                     
        {
            try
            {
                orderResp = adPointWebserviceHelper.createOrder(con, advertiserAcct, payerAcct, salesOrder);
            }
            catch(QueryException e)
            {
                system.debug('@createOrderInAdPoint fromBookingUI: ' + fromBookingUI);

                if(fromBookingUI)
                    throw new RemoteException('Current logged in user doesn\'t exist in External System User Credentials for AdPoint Booking');
                else
                    throw new RemoteException('Sales order owner doesn\'t exist in External System User Credentials for AdPoint Booking');
            }
            catch(Exception e)
            {
                throw new RemoteException(e.getMessage());
            }
        }
        
        system.debug(logginglevel.error, '@SalesOrderCreateBookingv2_AdPoint_CtrX orderResp status: ' + orderResp.status);
        
        // If webservice callout succeeds, update sales order external id as adpoint id
        // else if callout fails, delete this sales order
        if(orderResp.status == 'OK')
        {
            String bookingId;
            
            String adPointOrderId = orderResp.adPointCreateOrderResponse.AdPointOrder_ID;
            
            // need to create a new shell booking record for above sales order
            // in order for AdPoint to update this booking record later on
            Booking__c booking = new Booking__c();
            booking.Name = adPointOrderId;
            booking.Sales_Order__c = salesOrderId;
            
            Date t = date.today();
            
            Integer month = t.month();
            Integer day = t.day();
        
            String monthString = monthPattern.matcher(String.valueOf(month)).replaceFirst('0$1'); // convert single-digit month to double-digit month
            String dayString = monthPattern.matcher(String.valueOf(day)).replaceFirst('0$1'); // convert single-digit month to double-digit month

            booking.External_Id__c = 'AdPoint_' + adPointOrderId + '_' + t.year() + monthString + dayString;
            booking.Advertiser_Account__c = salesOrder.Advertiser_Account__c;
            booking.Payer_Account__c = salesOrder.Payer_Account__c;
            booking.Placer_Account__c = salesOrder.Placer_Account__c;
            booking.Source_System__c = 'AdPoint';
            insert booking;

            system.debug('@SalesOrderCreateBookingv2_AdPoint_CtrX booking 2: ' + booking);
            
            bookingId = booking.Id;
            return bookingId;
        }
        else
        {
            system.debug('@SalesOrderCreateBookingv2_AdPoint_CtrX orderResp errorDetails: ' + orderResp.errorDetails);
            throw new RemoteException(orderResp.errorDetails);
        }
        
        return null;
    }
    
    public class RemoteException extends Exception {}
  
    /**********************/
}
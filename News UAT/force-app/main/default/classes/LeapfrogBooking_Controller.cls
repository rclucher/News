public with sharing class LeapfrogBooking_Controller {
    
    private enum ActionType {EditOrder, CreateOrder, EditAccount}
    
    public static final string emailValidationMsg = 'Please ensure the Private Party or the contact selected for this account has an email address populated. Email addresses are mandatory for NewsAdds bookings.';
    // Changes related to AS-1287 on 19 March 18 by Lokesh Agarwal.
    public static final string bookDirectYes = 'Yes';
    public static final string digitalStatusActive = 'Active';
    
    public String leapfrogBookingAccountId {get{

        //AdSales 999 darshan.gosar@bluewolfgroup.com Added null check so it doesn't get reset in modify booking usecase
        if(leapfrogBookingAccountId == null || leapfrogBookingAccountId == ''){
            leapfrogBookingAccountId = bookingSystemAccount != NULL ? bookingSystemAccount.External_Id__c : '';            
        }
        return leapfrogBookingAccountId;
    } private set;}
    
    public String leapfrogBookingId {get; private set;}
    public String actionTypeName {get; private set;}
    public String jsonString {
        get {return jsonString == NULL ? '' : jsonString;}
        private set;
    }
    
    public Boolean hasError {
        get {return hasError == NULL ? false : hasError;}
        private set;
    }
    
    public Boolean hasPermission {
        get {return hasPermission == NULL ? false : hasPermission;}
        private set;
    }
    
    public Boolean hasEmail {
        get {return hasEmail == NULL ? true : hasEmail;}
        private set;
    }
    
    public Boolean showCanvasApp {
        get {
            
            System.debug('@hasPermission: ' + hasPermission);
            System.debug('@showConfirmation: ' + showConfirmation);
            System.debug('@hasError: ' + hasError);
            System.debug('@String.isNotBlank(contactId): ' + String.isNotBlank(contactId));
            System.debug('@String.isNotBlank(salesRepId): ' + String.isNotBlank(salesRepId));
            
            if(hasPermission && hasEmail && !showConfirmation && !hasError) {            
                showCanvasApp = true;
            }
            else {
                showCanvasApp = false;  
            }
                        
            return showCanvasApp;
        }
        private set;
    }
    
    public Boolean showConfirmation {
        get {return showConfirmation == NULL ? false : showConfirmation;}
        private set;
    }
    
    public Account account {get;private set;}
    public Account payerCustomerAccount {get;private set;}    
    public Boolean showPayerNewContact {get; set;}
    
    public String pageAction {get; set;}
    
    public String contactId {get;set;}
    public String salesRepId {get;set;}
    private String caseId;
    
    public String accountId;
    public String campaignId;    
    
    public List<SelectOption> contactList {get;private set;}
    public List<SelectOption> salesRepList {get;private set;}
    
    public List<List<SelectOption>> listOfSalesRepList {get;private set;}
    public List<User> salesReps {get;private set;}
    
    //unused vars
    public External_Account__c bsa {get; private set;}
    
    //show GBA and Net DA on Canvas Page -Backlog Item 171/219
    public String bsaId {get; set;}
    private String oldBsaId;
    private String bsaAccountNumber;
    private String bsaAccountType;
    private String bsaSFId;
    private String netDAJDE;
    private Map<Id, External_Account__c> bsaMap;
    
    //2017-10-19 AdSales 822 darshan.gosar@bluewolfgroup.com Added new attributes to pass in JSON
    private String payerName;
    private String payerGBA;
    private String payerGBAType;
    private String payerSFID;
    private String payerAccountSFID;
    // Changes related to AS-1362 to Pass new field through canvas - Referral_Source__c and Referral_Source__pc 
    private String ReferralSource;
    private String ReferralSourcepc;
    
    
    private External_Account__c selectedPayerAccount;
    
    public List<SelectOption> bsaList {get;private set;}
    
    public List<SelectOption> payerList {get;private set;}
    
    //897
    public List<SelectOption> bookingSystemAccountList {get;private set;}
    private Map<Id, External_Account__c> newBSAMap;
    public String selectedBookingSystemAccount {get; set;}
    public String selectedPayerAccountId {get; set;}
    
    ///////////////ND 13/09/17 346 
    public String selectedBookingType {get; set;}
    
    public List<SelectOption> bookingTypes {get{
        if(bookingTypes == null){
            bookingTypes = new List<SelectOption>();
            bookingTypes.add(new SelectOption('Direct', 'Direct'));
            bookingTypes.add(new SelectOption('Agency', 'Agency'));
        }return bookingTypes;
    }private set;}
    
    public String selectedBookingSystemId {get; set;}
    public List<External_Account__c> bookingSystemAccounts{get; set;}
    
    public External_Account__c bookingSystemAccount {
        get{
            if(selectedBookingSystemId != null){
                Map<Id, External_Account__c> bookingSystemAccountsMap = 
                    new Map<Id, External_Account__c>(bookingSystemAccounts);
                bookingSystemAccount = bookingSystemAccountsMap.get(selectedBookingSystemId);
            }
            return bookingSystemAccount;
        }
        set;}
    
    public List<SelectOption> bookingSystemAccountOptions{
        get{
            if(bookingSystemAccountOptions == null){
                bookingSystemAccountOptions = new List<SelectOption>();
                for(External_Account__c bookingSystemAccount: bookingSystemAccounts)
                    bookingSystemAccountOptions.add(new SelectOption(bookingSystemAccount.Id, bookingSystemAccount.Name));
            }
            return bookingSystemAccountOptions;
        }set;
    }
    
    public External_Account__c parentGBA {
        get; private set;}   
    
    private External_Account__c netDA;
    private String networkUsername;
    
    private final String fieldSetName = 'Leapfrog_Fields';
        
    private Set<String> directAccountTypeSet;
    private Set<String> agencyAccountTypeSet;
    
    private User user;
    private Booking__c booking;
    private Contact contact;
    private Sales_Order__c salesOrder;
    private User salesRep;
    
    public boolean showAlert {
        get {return showAlert == NULL ? false : showAlert;}
        private set;
    }
    public String alertMessage {
        //20170808 NK NCS-00337
        //removed default message
        get {return alertMessage == NULL ? '' : alertMessage;}
        private set;
    }
    // 2018-03-19  AdSales 1287 - Added new attribute to pass in JSON.
    public Boolean showAPA {get; set;}
    public String apaValue {
        get {return apaValue == NULL ? '' : apaValue;}
        set;
    }
    
    public LeapfrogBooking_Controller() {
        
        showCanvasApp = false;
        showAPA = false;
        showPayerNewContact = false;
        try {
            
            hasPermission = this.checkUserPermission();
            
            System.debug('@hasPermission: ' + hasPermission);
            
            String objectName;
            
            if(hasPermission) {
                
                String recordId = ApexPages.currentPage().getParameters().get('id');
                
                if(String.isNotBlank(recordId)) {
                    
                    // since booking can be initialised from account/booking system account, case or booking records, 
                    // we need to check what type of object of this record id. 
                    objectName = findObjectNameFromRecordIdPrefix(recordId);
                    
                    System.debug('@LeapfrogBooking_Controller.LeapfrogBooking_Controller objectName : ' + objectName);
                        
                    hasEmail = this.checkEmail(recordId, objectName); 
                    
                    if(hasEmail){
                        
                        this.setBookingTypes();                                                                                          

                        // query user record
                        String userQueryCondition = ' From User Where Id =\'' + UserInfo.getUserId() + '\' Limit 1';
                        String userQuery = this.getQueryString('User', userQueryCondition);
                        user = (User)Database.query(userQuery);
                        
                        //set networkUsername Id
                        networkUsername = user.Network_Username__c;
                        
                        this.populateSelectRepList();
                        
                        // default sales rep to current logged-in user
                        salesRepId = user.Id;
                        
                        String bookingSystemAccountId;
                            
                        // the user could press button "New NewsAdds Booking" on booking related list on booking system account
                        // or button "Manage NewsAdds Booking" on existing booking record. Either way, we need to know what record id it is
                        // in order to query all reocrds that Leapfrog booking system needs
                        if(objectName == 'Booking__c') {
                            
                            actionTypeName = ActionType.EditOrder.name();
                            
                            System.debug('@Object is Booking');
                            
                            String bookingRecId = recordId;
                            
                            // query booking record if applicable
                            String bsaFields = ', External_Account__r.Account_Type__c, External_Account__r.BSA_Account_No__c,';
                            bsaFields += 'External_Account__r.External_Account__r.Account_No__c, External_Account__r.External_Account__r.Account_Type__c, External_Account__r.External_Account__r.Payer_Account_Name__c, External_Account__r.External_Account__c, External_Account__r.External_Account__r.Customer_Account__c ';

                            String bookingQueryCondition = bsaFields +' From Booking__c Where Id =\'' + bookingRecId + '\' Limit 1';

                            String bookingQuery = this.getQueryString('Booking', bookingQueryCondition);

                            System.debug('@LeapfrogBooking_Controller.LeapfrogBooking_Controller bookingQuery : ' + bookingQuery);

                            booking = (Booking__c)Database.query(bookingQuery);
                            bookingSystemAccountId = booking.External_Account__c;
                            
                            // 2017-08-11 AdSales 338 darshan.gosar@bluewolfgroup.com Added code to fetch Campaign & Contact id in order to send as part of JSON string to 3wks team                            
                            if(ApexPages.currentPage().getParameters().containsKey('campaignId'))                            
                                campaignId = ApexPages.currentPage().getParameters().get('campaignId');
                            else
                                campaignId = booking.Campaign__c;
                            
                            System.debug('@booking: ' + booking);
                            
                            // query sales order record
                            if(booking.Sales_Order__c != NULL) {
                                String salesOrderQueryCondition = ' From Sales_Order__c Where Id = \'' + booking.Sales_Order__c + '\'';
                                String salesOrderQuery = this.getQueryString('SalesOrder', salesOrderQueryCondition);
                                salesOrder = (Sales_Order__c)Database.query(salesOrderQuery);
                            }
                            
                            System.debug('@salesOrder: ' + salesOrder);
                            
                            // if it is from booking, placer contact will be the contact sent to Leapfrog
                            if(booking.Placer_Contact__c != NULL) {
                                String contactQueryCondition = ' From Contact Where Id = \'' + booking.Placer_Contact__c + '\' Limit 1';
                                String contactQuery = this.getQueryString('Contact', contactQueryCondition);
                                contact = (Contact)Database.query(contactQuery);
                                contactId = contact.Id;
                                System.debug('@contact: ' + contact);
                            }
                            else {
                                this.showMessage('Couldn\'t find any placer contact on the current booking');
                            }
                            
                            //2017-10-19 AdSales 822 darshan.gosar@bluewolfgroup.com Added to set values for Manage Booking & Go To Booking usecases
                            bsaAccountType = booking.External_Account__r.Account_Type__c;
                            bsaAccountNumber = booking.External_Account__r.BSA_Account_No__c;
                            payerName = booking.External_Account__r.External_Account__r.Payer_Account_Name__c;
                            payerGBA = booking.External_Account__r.External_Account__r.Account_No__c;
                            payerGBAType = booking.External_Account__r.External_Account__r.Account_Type__c;
                            payerSFID = booking.External_Account__r.External_Account__c;
                            payerAccountSFID = booking.External_Account__r.External_Account__r.Customer_Account__c;
                            accountId = booking.Placer_Account__c;
                            bsaSFId = booking.External_Account__c;
                        }
                        else if(objectName == 'Account') {
                            
                            actionTypeName = ActionType.CreateOrder.name();
                            
                            this.showConfirmation = true;
                            
                            System.debug('@Object is Account');
                            
                            // query account details
                            accountId = recordId;
                            
                            // 2017-08-11 AdSales 338 darshan.gosar@bluewolfgroup.com Added code to fetch Campaign & Contact id in order to send as part of JSON string to 3wks team
                            if(ApexPages.currentPage().getParameters().containsKey('campaignId')){                            
                                campaignId = ApexPages.currentPage().getParameters().get('campaignId');
                                
                                if(campaignId != null && campaignId != ''){                                
                                    contactId = ApexPages.currentPage().getParameters().get('contactId');
                                }                                    
                            }
                            
                            // query booking system account details
                            String bookingSystemAccountQueryCondition = ' From External_Account__c Where Customer_Account__c = \'' + accountId 
                                + '\' And RecordType.DeveloperName = \'NewsAdds_Booking_System\' Order By CreatedDate DESC';    
                            
                            String bookingSystemAccountQuery = this.getQueryString('BookingSystemAccount', bookingSystemAccountQueryCondition);
                            system.debug('bookingSystemAccountQuery 1'+bookingSystemAccountQuery);
                            bookingSystemAccounts = (List<External_Account__c>)Database.query(bookingSystemAccountQuery); 
                            system.debug('bookingSystemAccounts '+bookingSystemAccounts);
                            if(!bookingSystemAccounts.isEmpty()) {
                                //bookingSystemAccount = bookingSystemAccounts[0];
                                selectedBookingSystemId = bookingSystemAccounts[0].Id;
                            }
                            
                            System.debug('@bookingSystemAccount: ' + bookingSystemAccount);
                        }
                        else if(objectName == 'External_Account__c') {
                            
                            actionTypeName = ActionType.EditAccount.name();
                            
                            System.debug('@Object is Booking System Account');
                            
                            bookingSystemAccountId = recordId;
                            
                            //2017-10-26 AdSales 822 darshan.gosar@bluewolfgroup.com Added to set values for Manage Booking & Go To Booking usecases
                            String bsaFields = ', BSA_Account_No__c, External_Account__r.Account_Type__c, External_Account__r.Payer_Account_Name__c, External_Account__c, External_Account__r.Customer_Account__c ';

                            String bsaQueryCondition = bsaFields +' From External_Account__c Where Id =\'' + bookingSystemAccountId + '\' Limit 1';

                            String bsaQuery = this.getQueryString('BookingSystemAccount', bsaQueryCondition);

                            External_Account__c tempBSA = (External_Account__c)Database.query(bsaQuery);
                            
                            bsaAccountType = tempBSA.Account_Type__c;
                            bsaAccountNumber = tempBSA.BSA_Account_No__c;
                            payerName = tempBSA.External_Account__r.Payer_Account_Name__c;
                            payerGBA = tempBSA.External_Account__r.Account_No__c;
                            payerGBAType = tempBSA.External_Account__r.Account_Type__c;
                            payerSFID = tempBSA.External_Account__c;
                            payerAccountSFID = tempBSA.External_Account__r.Customer_Account__c;
                            bsaSFId = tempBSA.Id;
                            
                        }
                        else if(objectName == 'Case') {
                            
                            this.showConfirmation = true;
                            
                            System.debug('@Object is Case');
                            
                            caseId = recordId;
                            String caseQueryCondition = ' From Case Where Id = \'' + caseId + '\' Limit 1';
                            String caseQuery = this.getQueryString('Case', caseQueryCondition);
                            Case c = (Case)Database.query(caseQuery);
                            
                            //bookingSystemAccountId = c.Booking_System_Account__r.Id; // TODO: this doesn't have value
                            bookingSystemAccountId = c.Booking__r.External_Account__c; // TODO: this doesn't have value
                            accountId = c.AccountId;
                            contactId = c.ContactId;
                            
                            //2017-04-04 Allanah Mae: FB-255
                            //the user should be taken to the new booking page and be able to create a new booking that is associated with the case.
                            actionTypeName = ActionType.CreateOrder.name();
                            
                            /*if(c.Booking__c != NULL) {
                                // query booking record if applicable
                                String bookingQueryCondition = ' From Booking__c Where Id =\'' + c.Booking__c + '\' Limit 1';
                                String bookingQuery = this.getQueryString('Booking', bookingQueryCondition);
                                booking = (Booking__c)Database.query(bookingQuery);
                                leapfrogBookingId = booking.External_Id__c;

                                actionTypeName = ActionType.EditOrder.name();
                                }
                                else {
                                actionTypeName = ActionType.CreateOrder.name();
                                }
                            */
                                
                            // 2017-06-21 AdSales 301 darshan.gosar@bluewolfgroup.com Added to fetch Booking System Account of related case Account if its not found based on case booking value
                            if(bookingSystemAccountId == null || bookingSystemAccountId == ''){
                                // query booking system account details
                                String bookingSystemAccountQueryCondition = ' From External_Account__c Where Customer_Account__c = \'' + accountId 
                                    + '\' And RecordType.DeveloperName = \'NewsAdds_Booking_System\' Order By CreatedDate DESC';    
                                
                                String bookingSystemAccountQuery = this.getQueryString('BookingSystemAccount', bookingSystemAccountQueryCondition);
                                system.debug('bookingSystemAccountQuery 2'+bookingSystemAccountQuery);
                                bookingSystemAccounts = (List<External_Account__c>)Database.query(bookingSystemAccountQuery); 
                                
                                if(!bookingSystemAccounts.isEmpty()) {
                                    //bookingSystemAccount = bookingSystemAccounts[0];
                                    selectedBookingSystemId = bookingSystemAccounts[0].Id;
                                }
                            }                            
                            
                        }
                        
                        System.debug('@1111bookingSystemAccountId: ' + bookingSystemAccountId);
                        
                        // query booking system account details if it hasn't been queried before
                        if(bookingSystemAccount == NULL && String.isNotBlank(bookingSystemAccountId)) {
                            String bookingSystemAccountQueryCondition = ' From External_Account__c Where Id =\'' + bookingSystemAccountId 
                                + '\' And RecordType.DeveloperName = \'NewsAdds_Booking_System\' Limit 1';
                            
                            String bookingSystemAccountQuery = this.getQueryString('BookingSystemAccount', bookingSystemAccountQueryCondition);
                            
                            try {
                                //bookingSystemAccount = (External_Account__c)Database.query(bookingSystemAccountQuery);  
                                bookingSystemAccounts = Database.query(bookingSystemAccountQuery);  
                                
                                if(!bookingSystemAccounts.isEmpty()) {
                                    //bookingSystemAccount = bookingSystemAccounts[0];
                                    selectedBookingSystemId = bookingSystemAccounts[0].Id;
                                }
                            } catch(Exception e) {
                                if(e.getMessage().contains('List has no rows')) {
                                    this.showMessage('Couldn\'t find any NewsAdds booking system account');
                                }
                                else {
                                    this.showMessage(e.getMessage());
                                }
                            }
                            
                            // if account id is still blank, use customer account on booking system account as account
                            if(String.isBlank(accountId) && bookingSystemAccount.Customer_Account__c != NULL) {
                                accountId = bookingSystemAccount.Customer_Account__c;
                            }
                        }
                        
                        //Leapfrog 240, initialise map
                        
                        bsaMap = new Map<Id, External_Account__c>();
                                                
                        //get GBA and NetDA details from bookingSystemAccount
                        if (bookingSystemAccount != null) 
                            oldBsaId = bookingSystemAccount.BSA__c;
                        
                        //ND 15/9/17 346 Cleaned the code into reusable method
                        /*
                        selectedBookingType = 'Direct';
                        fetchGBAs();
                        */
                        Account tempAccount;
                        // query account record if it hasn't been queried before
                        if(account == NULL && String.isNotBlank(accountId)) {
                            String accountQueryCondition = ' From Account Where Id = \'' + accountId + '\' Limit 1';
                            
                            tempAccount = [Select Id, IsPersonAccount from Account where Id =:accountId Limit 1];                            
                            String accountQuery = '';
                            
                            if(tempAccount.IsPersonAccount == true)
                                accountQuery = this.getQueryString('PersonAccount', accountQueryCondition);                                
                            else
                                accountQuery = this.getQueryString('Account', accountQueryCondition);
                        	system.debug('accountQuery is --' + accountQuery);
                            account = (Account)Database.query(accountQuery);
                        }    
                        System.debug('@account: ' + account);
                        
                        if(account != NULL) {
                            // Changes related to AS-1287 on 19 March 18 by Lokesh Agarwal to show AdPoint field accoridng to below condition
                          //  if(tempAccount.IsPersonAccount == false){
                                
                                if(account.Is_Digital__c == true && account.Customer_Books_Direct__c == bookDirectYes && account.Digital_Status__c == digitalStatusActive){
                                    
                                	apaValue = account.AdPoint_Id__c;
                                    showAPA = true;
                                }
                                else
                                    showAPA = false;
                           // }
                            system.debug('apaValue -' + apaValue);
                            system.debug('showAPA -' + showAPA);
                           // Changes related to AS-1362 to Pass new field through canvas - Referral_Source__c and Referral_Source__pc
                            ReferralSource    = account.Referral_Source__c; 
                            ReferralSourcepc  = account.Referral_Source__pc; 
                            
                            if(objectName == 'Account' || objectName == 'Case')
                                this.populateBookingSystemAccountList(account.Id);
                            /*
                            // query contact list
                            this.refreshContactList();
                            //query BSA list : Leapfrog item 240
                            this.refreshBSAList();
                            */
                        }
                        else {
                            this.showMessage('Couldn\'t find any account');
                        }
                        
                    } else {
                        this.showMessage(emailValidationMsg);                        
                    }
                } else {
                    this.showMessage('You haven\'t passed any id value in the URL');
                }                
            } else {
                this.showMessage('You don\'t have permission to see this page. Please contact your administrator.');
            }
            
            // assign booking external id to order id in signed request parameters
            // assign booking system account external id to bookingAccount id in signed request parameters
            leapfrogBookingId = booking != NULL ? booking.External_Id__c : '';
            //leapfrogBookingAccountId = bookingSystemAccount != NULL ? bookingSystemAccount.External_Id__c : '';
            netDAJDE = netDA != NULL ? netDA.JDE_Account_Number__c : '';
            
            System.debug('bsaId##' + bsaId);
            System.debug('bsaMap##' + bsaMap);
            
            //retreive bsaAccountNumber here to handle accessing leapfrog from places other than account
            if (bsaId != '' && bsaId != NULL && bsaMap.containsKey(bsaId)) {
                bsaAccountNumber = bsaMap.get(bsaId).Account_No__c;
                bsaAccountType = bsaMap.get(bsaId).Account_Type__c;
                bsaSFId = bsaMap.get(bsaId).Id; 
            }
            
            if(objectName == 'Booking__c' || objectName == 'External_Account__c')
                this.refreshJsonString();
            
        } catch(Exception e) {this.showMessage(e.getMessage());}        
    }
    
    public void setBookingTypes(){
        directAccountTypeSet = new Set<String>();
        agencyAccountTypeSet = new Set<String>();

        Map<String, Leapfrog_Account_Types__c> gbaAccountTypeMap = new Map<String, Leapfrog_Account_Types__c>();
        gbaAccountTypeMap = Leapfrog_Account_Types__c.getAll();                
                
        for(Leapfrog_Account_Types__c l: gbaAccountTypeMap.values()){
            if(l.Booking_Type__c=='Direct')
                directAccountTypeSet.add(l.Name);
                
            if(l.Booking_Type__c=='Agency')
                agencyAccountTypeSet .add(l.Name);                
        }
    }
    
    public void populateSelectRepList(){
    
        // get sales rep picklist
        //salesRepList = new List<SelectOption>();
        
        // collection size has limit 1000. Therefore page can only show 999 sales reps plus one '--Select a sales rep--' option
        // Total number of records retrieved by SOQL queries <br/>is 50000. Any records beyond 50000 won't be shown
        // in the sales rep picklist
        //String salesRepQueryCondition = ' From User Where Network_Username__c != NULL And IsActive = true Order By Name Limit 999';
        
        // Bohao Chen on 29th September 2016
        String salesRepQueryCondition = ' From User Where IsActive = true Order By Name ASC';
        
        String salesRepQuery = this.getQueryString('User', salesRepQueryCondition);
        salesReps = (List<User>)Database.query(salesRepQuery);
        
        //salesRepList = new List<SelectOption>();
        
        // workaround solution to avoid 1000 limitation for salesforce picklist options
        listOfSalesRepList = new List<List<SelectOption>>();
        
        // Assumption: only accommodate 3 list of select options for sales reps. In total, picklist should be able to display 3000 users at most.
        listOfSalesRepList.add(new List<SelectOption>());
        listOfSalesRepList.add(new List<SelectOption>());
        listOfSalesRepList.add(new List<SelectOption>());
        
        Integer i = 0;
        Integer j = 0;
        
        for(User u : salesReps) {
            
            listOfSalesRepList[i].add(new SelectOption(u.Id, u.Name));
            
            j++;
            
            if(j == 1000) {
                j = 0;
                i++;
                
                if(i > 2) break; // Assumption: only accommodate 3 list of select options for sales reps. In total, picklist should be able to display 3000 users at most.
            }
        }
        
        System.debug('@listOfSalesRepList: ' + listOfSalesRepList);
    }
    
    //897
    public void populateBookingSystemAccountList(Id accountId){
        String bsaQueryCondition = ' , BSA_Account_No__c From External_Account__c WHERE Customer_Account__c =: accountId AND RecordType.DeveloperName = \'NewsAdds_Booking_System\'';
        newBSAMap = new Map<Id, External_Account__c>();
        
        bsaQueryCondition +=' ORDER BY CreatedDate DESC';
        
        String bsaQuery = this.getQueryString('BookingSystemAccount', bsaQueryCondition);        
        List<External_Account__c> tempList = (List<External_Account__c>)Database.query(bsaQuery);
        
        bookingSystemAccountList = new List<SelectOption>();
        
        if(tempList.size() == 0){
            // 2017-11-22 Added to resolve #2 UAT issue on 897
            newBooking();
        }
        else if(tempList.size() == 1){
            bookingSystemAccountList.add(new SelectOption(tempList[0].Id, tempList[0].Account_No__c + ' ' + tempList[0].Name + ' - ' + tempList[0].Account_Type__c  + ' - ' + tempList[0].BSA_Account_No__c));
            newBSAMap.put(tempList[0].Id, tempList[0]);
            fetchDefaultValues(tempList[0].Id);
            pageAction = 'NEW MODIFY';
        }
        else{
            bookingSystemAccountList.add(new SelectOption('','--Select a Booking System Account --'));
            for(External_Account__c t: tempList){
                newBSAMap.put(t.Id, t);
                bookingSystemAccountList.add(new SelectOption(T.Id, t.Account_No__c + ' ' + t.Name + ' - ' + t.Account_Type__c  + ' - ' + t.BSA_Account_No__c));
            }
            pageAction = 'NEW MODIFY';
        }       
    }
    
    public PageReference newBooking(){
        pageAction = 'NEW';
        bookingSystemAccountList = new List<SelectOption>();
        bookingSystemAccountList.add(new SelectOption('New', 'New'));
        selectedBookingType = 'Direct';
        fetchGBAs();
        this.refreshBSAList();
        this.refreshContactList();
        selectedPayerAccountId = '';
        bsaId = '';
        
        //2017-12-07 AdSales 1011 darshan.gosar@bluewolfgroup.com Added code to reset JSON variables
        bsaAccountType = '';
        bsaAccountNumber = '';
        payerName = '';
        payerGBA = '';
        payerGBAType = '';
        payerSFID = '';
        payerAccountSFID = '';
        bsaSFId = '';
        
                                    
        return null;
    }
    
    public PageReference modifyBooking(){    
        pageAction = 'MODIFY';
        bookingSystemAccountList = new List<SelectOption>();
        
        if(newBSAMap.containsKey(selectedBookingSystemAccount)){
            system.debug('inside=='+selectedbookingsystemaccount);
            External_Account__c tempAct = new External_Account__c();
            tempAct = newBSAMap.get(selectedBookingSystemAccount);

            bookingSystemAccountList.add(new SelectOption(tempAct.Id, tempAct.Account_No__c + ' ' + tempAct.Name + ' - ' + tempAct.Account_Type__c  + ' - ' + tempAct.BSA_Account_No__c));                        
        }
                        
        fetchDefaultValues(selectedBookingSystemAccount);        
        return null;    
    }    
    
    public void fetchDefaultValues(String selectedBSA){
        
        selectedBookingSystemId = selectedBSA;
        
        if(newBSAMap.containsKey(selectedBSA)){
        
            External_Account__c tempAct = new External_Account__c();
            tempAct = newBSAMap.get(selectedBSA);
                        
            System.debug('bookingSystemAccounts###' + bookingSystemAccounts);
            
            leapfrogBookingAccountId = tempAct.External_Id__c;
            
            if(tempAct.Account_Type__c != null){
                if(directAccountTypeSet.contains(tempAct.Account_Type__c))
                    selectedBookingType = 'Direct';
                    
                if(agencyAccountTypeSet.contains(tempAct.Account_Type__c))
                    selectedBookingType = 'Agency';
            }

            fetchGBAs();
            if(selectedBookingType == 'Agency'){
                this.refreshPayerAccountList();                                
                selectedPayerAccountId = tempAct.BSA__c;                
                refreshGBAList();                
                bsaId = tempAct.BSA__c;                
            }
            
            if(selectedBookingType == 'Direct'){                                           
                this.refreshBSAList();                                                
                bsaId = tempAct.BSA__c;
            }
            
            this.refreshContactList();            
                
        }
    }        
    
    public PageReference changeBookingSystemAccount(){
        fetchDefaultValues(selectedBookingSystemAccount);
        return null;
    }
    
    public PageReference changeBookingType(){
        fetchGBAs();
        
        if(selectedBookingType == 'Direct')
            this.refreshBSAList();                    
            
        if(selectedBookingType == 'Agency')         
            this.refreshPayerAccountList();
        
        this.refreshContactList();
            
        return null;

    }
    
    public PageReference fetchGBAs(){

        if (bookingSystemAccount != null) {
            bsaId = bookingSystemAccount.BSA__c;
        }
        
        System.debug('@LeapfrogBookingController: LeapfrogBookingController bsaId = ' + bsaId);

        // 2017-09-20 AdSales 351 darshan.gosar@bluewolfgroup.com Updated Account_Type__c query filter to fetch all GBA account based on custom setting type
        String gbaQueryCondition = ' From External_Account__c WHERE Customer_Account__c =: accountId AND RecordType.DeveloperName = \'Booking_Account\'';
        if(selectedBookingType == 'Direct'){

            //2017-10-26 NK 822 restrict to NewsAdds
            //gbaQueryCondition += ' AND RecordType.DeveloperName = \'NewsAdds_Booking_System\'';
        
            if(directAccountTypeSet.size() > 0)
                gbaQueryCondition += ' AND Account_Type__c in :directAccountTypeSet ';
        }
             
        System.debug('directAccountTypeSet ' + gbaQueryCondition);     
        //String gbaQueryCondition = ' From External_Account__c Where RecordType.DeveloperName = \'Booking_Account\'' +
            //' AND Account_Type__c = \'Established\'';
            
        if(selectedBookingType == 'Agency'){
            
            //if(bookingSystemAccount != null)
                //gbaQueryCondition += ' AND External_Account__c =:selectedBookingSystemId';
                
            if(agencyAccountTypeSet.size() > 0)
                 gbaQueryCondition += ' AND Account_Type__c in :agencyAccountTypeSet';
        }

        System.debug('agencyAccountTypeSet ' + gbaQueryCondition); 
                         
        gbaQueryCondition+=' ORDER BY CreatedDate DESC';
        //String gbaQueryCondition = ' From External_Account__c Where RecordType.DeveloperName = \'Booking_Account\' AND External_Account__c =:selectedBookingSystemId AND Account_Type__c = \'Established\' ORDER BY CreatedDate DESC';
        String gbaQuery = this.getQueryString('BookingSystemAccount', gbaQueryCondition);
        system.debug('gbaQuery '+gbaQuery);
        try {
            bsaMap = new Map<Id, External_Account__c>();
            for (External_Account__c ea : (List<External_Account__c>)Database.query(gbaQuery)) {
                bsaMap.put(ea.Id, ea);
            }
        } catch(Exception e) {
            this.showMessage(e.getMessage());
        }
        
        ////get NetDA details
        //changed for backlog item 240, we are now grabbing this via the ESB
        if (bookingSystemAccount != null && bookingSystemAccount.BSA_Net_DA__c != null) {
            String netDAQueryCondition = ' From External_Account__c Where Id =\'' + bookingSystemAccount.BSA_Net_DA__c + '\' Limit 1';
            String netDAQuery = this.getQueryString('BookingSystemAccount', netDAQueryCondition);
            
            try {
                netDA = (External_Account__c)Database.query(netDAQuery);  
            } catch(Exception e) {
                this.showMessage(e.getMessage());
            }
        }
    
        return null;
    }
    
    private Boolean checkEmail(Id recordId, String objectName) {
        Boolean hasEmail = true;        
        if(objectName == 'Booking__c'){
            List<Booking__c> bookingList = [Select Placer_Account__r.PersonEmail, Placer_Account__r.IsPersonAccount from Booking__c where Id = :recordId Limit 1];
            if(bookingList.size() > 0 && bookingList[0].Placer_Account__r.IsPersonAccount == true && (bookingList[0].Placer_Account__r.PersonEmail == null || bookingList[0].Placer_Account__r.PersonEmail == ''))
                hasEmail = false;           
        }
        else if(objectName == 'Account') {
            List<Account> accountList = [SELECT Id, PersonEmail, IsPersonAccount from Account where Id = :recordId Limit 1];        
            if(accountList.size() > 0 && accountList[0].IsPersonAccount == true && (accountList[0].PersonEmail == null || accountList[0].PersonEmail == ''))
                hasEmail = false;
        }
        else if(objectName == 'External_Account__c') {
            List<External_Account__c> externalAccountList = [Select Customer_Account__r.PersonEmail, Customer_Account__r.IsPersonAccount from External_Account__c where Id = :recordId Limit 1];
            if(externalAccountList.size() > 0 && externalAccountList[0].Customer_Account__r.IsPersonAccount == true && (externalAccountList[0].Customer_Account__r.PersonEmail == null || externalAccountList[0].Customer_Account__r.PersonEmail == ''))
                hasEmail = false;   
        }
        else if(objectName == 'Case') {
            List<Case> caseList = [Select Account.PersonEmail, Account.IsPersonAccount from Case where Id = :recordId Limit 1];
            if(caseList.size() > 0 && caseList[0].Account.IsPersonAccount == true && (caseList[0].Account.PersonEmail == null || caseList[0].Account.PersonEmail == ''))
                hasEmail = false;           
        }
        return hasEmail;
    }
    
    private Boolean checkUserPermission() {
        
        Boolean hasPermission = false;
        
        PermissionSet permSet = [SELECT Id,IsOwnedByProfile,Label
                                 FROM PermissionSet
                                 Where Name = 'Leapfrog_User_Permission' Limit 1];
        
        List<PermissionSetAssignment> pemSetAssignments = [SELECT Assignee.Name, PermissionSet.Id, PermissionSet.isOwnedByProfile, 
                                                           PermissionSet.Profile.Name, PermissionSet.Label
                                                           FROM PermissionSetAssignment
                                                           WHERE PermissionSetId =: permSet.Id
                                                           AND AssigneeId =: UserInfo.getUserId()];
        
        if(pemSetAssignments.size() > 0) {
            hasPermission = true;
        }
        
        return hasPermission;
    }
    
    // this method loops through field set "Leapfrog_Fields" of the object according to object type to determine
    // fields that need to be queried in the SOQL query
    private String getQueryString(String objectType, String queryCondition) {
        
        String query = 'Select ';
        List<Schema.FieldSetMember> fields;
        
        if(objectType == 'Account') {
            fields = Schema.SObjectType.Account.fieldSets.getMap().get(fieldSetName).getFields();
        }
        if(objectType == 'PersonAccount') {
            fields = Schema.SObjectType.Account.fieldSets.getMap().get('Leapfrog_Person_Account_Fields').getFields();
        }
        else if(objectType == 'Contact') { 
            fields = Schema.SObjectType.Contact.fieldSets.getMap().get(fieldSetName).getFields();
        }
        else if(objectType == 'User') { 
            fields = Schema.SObjectType.User.fieldSets.getMap().get(fieldSetName).getFields();
        } 
        else if(objectType == 'Booking') { 
            fields = Schema.SObjectType.Booking__c.fieldSets.getMap().get(fieldSetName).getFields();
        }
        else if(objectType == 'BookingSystemAccount') { 
            fields = Schema.SObjectType.External_Account__c.fieldSets.getMap().get(fieldSetName).getFields();
        }
        else if(objectType == 'SalesOrder') { 
            fields = Schema.SObjectType.Sales_Order__c.fieldSets.getMap().get(fieldSetName).getFields();
        }
        else if(objectType == 'Case') { 
            fields = Schema.SObjectType.Case.fieldSets.getMap().get(fieldSetName).getFields();
        }
        
        for(Schema.FieldSetMember f : fields) {
            System.debug('@field members' + f.fieldPath);
            query += f.fieldPath + ',';
        }
        
        query = query.removeEnd(',');
        
        query += queryCondition;
        
        System.debug('@query: ' + query);
        
        return query;
    }
    
    public PageReference confirm() {
        
        this.showConfirmation = false;
        this.hasError = false;
        
        // query sales rep record
        if(String.isNotBlank(salesRepId)) {
            String salesRepQueryCondition = ' From User Where Id =\'' + salesRepId + '\' Limit 1';
            String salesRepQuery = this.getQueryString('User', salesRepQueryCondition);
            salesRep = (User)Database.query(salesRepQuery);
            
            System.debug('@salesRep: ' + salesRep);
        }
        else {
            // show "No sales rep id " error message
            this.showMessage('You haven\'t confirmed the sales rep');
            this.showConfirmation = true;
        }
        
        // query contact record
        if(String.isNotBlank(contactId)) {
            
            // TODO: need to confirm which contact to be selected
            String contactQueryCondition = ' From Contact Where Id = \'' + contactId + '\' Limit 1';
            String contactQuery = this.getQueryString('Contact', contactQueryCondition);
            contact = (Contact)Database.query(contactQuery);
            
            if(contact.Email == null || contact.Email == ''){
                this.showMessage(emailValidationMsg);
                this.showConfirmation = true;
            }
            System.debug('@contact: ' + contact);
        }
        else {
            // show "No contact id " error message
            this.showMessage('You haven\'t confirmed the contact');
            this.showConfirmation = true;
        }
        
        //System.debug('bsaId: ' + bsaId);
        //set bsa account number here as it can change on the page, allow it to go null
        if (!String.isBlank(bsaId)) {
            if (bsaMap.containsKey(bsaId)) {
                External_Account__c selectedGBA = bsaMap.get(bsaId);
                bsaAccountNumber = selectedGBA.Account_No__c;
                bsaAccountType = selectedGBA.Account_Type__c;
                bsaSFId = selectedGBA.Id;
                //parentGBA = bookingSystemAccount; //selectedGBA.External_Account__r;
                System.debug('bsaAccountNumber: ' + bsaId);
            }
            else {
            /*
                bsaAccountNumber = '';
                bsaAccountType = '';
                bsaSFId = '';
            */
            }
            if (!bsaId.equals(oldBsaId)) {
                netDAJDE = null;
            }
            //ESB callout
            //query ESB for NetDA if gba changed
            if (!String.isBlank(bsaAccountNumber) && String.isBlank(netDAJDE)) {
                List<String> resp = ESBGetDAForGBA.getDAForGBA(bsaAccountNumber);
                //System.debug('resp: ' + resp);
                if (resp[0] == 'SUCCESS') {
                    netDAJDE = resp[1];
                }
                else {
                    //20170808 NK item-00337
                    //if (resp[0] == 'ERROR') {
                    //    alertMessage = 'There was an issue with the retrieval of a NET DA. Post-pay bookings cannot be accepted, but pre-pay bookings can continue.';
                    //}
                    //else 
                    if (resp[0] == 'CREATE') {
                        alertMessage = 'A request for creation of the NetDA has been sent, if you wish to set up post pay, please try again later.';
                    }
                    //this.showMessage('There was an issue with the retrieval of a NET DA. Post-pay bookings cannot be accepted, but pre-pay bookings can continue.');
                    //this.showConfirmation = true;
                    //showAlert = true;
                    System.debug(LoggingLevel.ERROR,'@ESBGetDAForGBA ERROR message: ' + resp[1]);
                }
            }
            
            //save GBA and NetDA to newsAddsbooking account
            System.debug('bookingSystemAccount: ' + bookingSystemAccount);

            /*
            //2017-12-12 AdSales 1011 darshan.gosar@bluewolfgroup.com As per discussion with Ben & Jody no need to update mapping in salesforce via canvas page for all usecase hence commented below code
            // 2017-12-05 AdSales 1011 darshan.gosar@bluewolfgroup.com No need to update existing BSA for New BSA usecase
            if (pageAction != 'NEW' && bookingSystemAccount != null) {
                saveToBookingAccount();
            }
            */
        }
        
        this.refreshJsonString();
        
        System.debug('@jsonString: ' + jsonString);
        
        return null;
    }
    
    private void saveToBookingAccount() {
        bookingSystemAccount.BSA__c = bsaId;
        //System.debug('accountId: ' + accountId);
        //System.debug('JDE_Account_Number__c: ' + netDAJDE);
        if (!String.isBlank(netDAJDE)) {
            List<External_Account__c> matchingNetDAs = [SELECT Id
                                                        FROM External_Account__c
                                                        WHERE RecordType.DeveloperName = 'Billing_Account'
                                                        AND Customer_Account__c =: accountId
                                                        AND (Division__c = 'National' OR Division__c = 'NOZ')
                                                        AND JDE_Account_Number__c =: netDAJDE];
            if (!matchingNetDAs.isEmpty()) {
                bookingSystemAccount.BSA_Net_DA__c = matchingNetDAs[0].Id;
            }
        }
        
        try {
            update bookingSystemAccount;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'There was an issue updating the booking system account: ' + e.getMessage()); 
        }
    }
    
    public PageReference refreshContactList() {
        
        // query contact list
        contactList = new List<SelectOption>();
        List<Contact> contacts = new List<Contact>();
                
        if(selectedBookingType != 'Agency'){
            //AdSales 894 darshan.gosar@bluewolfgroup.com Added order by clause to sort contact by name & filter inactive contacts
            contacts = [Select Id, Name From Contact Where AccountId =: account.Id and Contact_Status__c = 'Active' Order By Name];

            //AdSales 998 darshan.gosar@bluewolfgroup.com Added to hide new contact create button related to Payer Account
            showPayerNewContact = false;
        }
        else{                
            // 2017-10-03 AdSales 346 darshan.gosar@bluewolfgroup.com Added below code to get Payer Account attributes based payer & GBA selection on LeapFrog page
            if(selectedPayerAccount != null && selectedPayerAccount.Customer_Account__c != null){
                //AdSales 894 darshan.gosar@bluewolfgroup.com Added order by clause to sort contact by name & filter inactive contacts
                contacts = [Select Id, Name From Contact Where AccountId =: selectedPayerAccount.Customer_Account__c and Contact_Status__c = 'Active' Order By Name];    
                        
                String accountQueryCondition = ' From Account Where Id = \'' + selectedPayerAccount.Customer_Account__c + '\' Limit 1';
                                
                Account tempAccount = [Select Id, IsPersonAccount from Account where Id =:selectedPayerAccount.Customer_Account__c Limit 1];                            
                String accountQuery = '';
                
                if(tempAccount.IsPersonAccount == true)
                    accountQuery = this.getQueryString('PersonAccount', accountQueryCondition);                                
                else
                    accountQuery = this.getQueryString('Account', accountQueryCondition);
                
                payerCustomerAccount = (Account)Database.query(accountQuery);
                showPayerNewContact = true;    
            }
        }    
        
        //System.debug('#######' + account);        
        
        if(!contacts.isEmpty()) {
            if(contacts.size() > 1) {
                contactList.add(new SelectOption('', '--Select a Contact--'));
            }
            
            Boolean foundDefaultContact = false;
            
            for(Contact c : contacts) {
                contactList.add(new SelectOption(c.Id, c.Name));
                
                if(c.Id == contactId) {
                    foundDefaultContact = true;
                }
            }
            
            if(!foundDefaultContact && String.isNotBlank(contactId)) {
                Contact defultContact = [Select Id, Name From Contact Where Id =: contactId Limit 1];
                contactList.add(new SelectOption(defultContact.Id, defultContact.Name));
            }
        }
        else {
            if(selectedBookingType != 'Agency')
                this.showMessage('Couldn\'t find any contact. Please contact the administrator');
            else{
                if(selectedPayerAccount != null){
                    this.showMessage('Couldn\'t find any contact against selected Payer Account. Please contact the administrator');
                }
            }                
        }
        
        return NULL;
    }
    
    public PageReference refreshPayerAccountList() {
        payerList = new List<SelectOption>();
        bsaList = new List<SelectOption>();
        
        if(!bsaMap.isEmpty()) {
            payerList.add(new SelectOption('', '--Select a Payer--'));
        
            for(External_Account__c b : bsaMap.values()) {                
                payerList.add(new SelectOption(b.Id, b.Payer_Account_Name__c));
            }        
        }
        else{
            this.showMessage('Couldn\'t find any Payer Account. Please contact the administrator');
        }        
        return NULL;                         
    }

    // 2017-10-03 AdSales 346 darshan.gosar@bluewolfgroup.com Added below code to get Payer Account attributes based payer & GBA selection on LeapFrog page
    public void fetchPayerAccount(){
        
        External_Account__c tempAct1;
        
        if(bsaMap.containsKey(selectedPayerAccountId))
            tempAct1 = bsaMap.get(selectedPayerAccountId);
        
        if(tempAct1 != null && tempAct1.External_Account__c != null && selectedBookingType == 'Agency'){
            for(External_Account__c e: [Select Payer_Account_Name__c, Account_No__c, Id, Customer_Account__c, Account_Type__c from External_Account__c where Id = :tempAct1.External_Account__c Limit 1]){
                selectedPayerAccount = e;
            }
        }   
    }
    
    public PageReference refreshGBAList() {        
                
        fetchPayerAccount();
        contactId = null;
        refreshContactList();        
        
        bsaList = new List<SelectOption>();
        
        if(!bsaMap.isEmpty()) {
                        
            for(External_Account__c b : bsaMap.values()) {
                if(selectedPayerAccountId == b.Id){
                    bsaList.add(new SelectOption(b.Id, b.Name + ' : ' + b.Account_Type__c  + ' : ' + b.Account_No__c));
                    break;
                }
            }
        }
        
        return NULL;        
    }
    
    public PageReference refreshBSAList() {
        payerList = new List<SelectOption>();
        bsaList = new List<SelectOption>();
        
        if(!bsaMap.isEmpty()) {
            bsaList.add(new SelectOption('', '--Select a GBA--'));
            
            // 2017-09-27 AdSales 818 darshan.gosar@bluewolfgroup.com Added Account_Type__c to show in GBA drop down along with Account No
            for(External_Account__c b : bsaMap.values()) {
                bsaList.add(new SelectOption(b.Id, b.Name + ' : ' + b.Account_Type__c  + ' : ' + b.Account_No__c));
            }
        }
        return NULL;                         
    }    
    
    private void refreshJsonString() {        
              
        System.debug('@LeapfrogBooking_Controller : bsaId -> ' + bsaId);

        if(selectedPayerAccount != NULL && selectedBookingType == 'Agency'){
            if(selectedPayerAccount.Payer_Account_Name__c != null)
                payerName = selectedPayerAccount.Payer_Account_Name__c;

            if(selectedPayerAccount.Account_No__c!= null)
                payerGBA = selectedPayerAccount.Account_No__c;

            if(selectedPayerAccount.Account_Type__c != null)
                payerGBAType = selectedPayerAccount.Account_Type__c;

            payerSFID = selectedPayerAccount.Id;

            if(selectedPayerAccount.Customer_Account__c != null)            
                payerAccountSFID = selectedPayerAccount.Customer_Account__c;                
        }
        
        jsonString = '{';
        jsonString += '\"user\": ' + (user != NULL ? JSON.serialize(user) : NULL) + ',';
        jsonString += '\"booking\": ' + (booking != NULL ? JSON.serialize(booking) : NULL) + ',';
        //jsonString += '\"booking\": ' + 'null' + ',';
        jsonString += '\"account\": ' + (account != NULL ? JSON.serialize(account) : NULL) + ',';
        
        // 2017-12-05 AdSales 1011 darshan.gosar@bluewolfgroup.com Updated to pass null bookingSystemAccount for New BSA usecase
        if(pageAction == 'NEW')
            jsonString += '\"bookingSystemAccount\" : null,';
        else            
            jsonString += '\"bookingSystemAccount\": ' + (bookingSystemAccount != NULL ? JSON.serialize(bookingSystemAccount) : NULL) + ',';
        //jsonString += '\"bookingSystemAccount\": ' + 'null' + ',';
                       
        jsonString += '\"contact\": ' + (contact != NULL ? JSON.serialize(contact) : NULL) + ',';
        //jsonString += '\"salesOrder\": ' + (salesOrder != NULL ? JSON.serialize(salesOrder) : NULL) + ',';
        System.debug('jsonString ###' + jsonString);
        
        // pass case id and sales rep id in metadata section because Leapfrog doesn't need to process
        // these info. It is used by ESB later to identify records in Salesforce when it writes back.
        jsonString += '\"metadata\": {';
        jsonString += '\"caseId\" : ' + (String.isBlank(caseId) ? 'null' : '\"' + caseId + '\"')  + ',';
        jsonString += '\"salesRepId\" : ' + (String.isBlank(salesRepId) ? 'null' : '\"' + salesRepId + '\"')  + ',';
        jsonString += '\"linkedGBAID\" : ' + (String.isBlank(bsaSFId) ? 'null' : '\"' + bsaSFId + '\"') + ',';
        
        // 2017-08-11 AdSales 338 darshan.gosar@bluewolfgroup.com Added code to pass Campaign id as part of JSON string to 3wks team
        jsonString += '\"campaignId\" : ' + (String.isBlank(campaignId) ? 'null' : '\"' + campaignId + '\"') + ',';

        // 2017-10-19 AdSales 822 darshan.gosar@bluewolfgroup.com If SelectedPayer Account is populated then update values based on it                    
        jsonString += '\"payerName\" : ' + (String.isBlank(payerName) ? 'null' : '\"' + payerName + '\"')  + ',';
        jsonString += '\"payerGBA\" : ' + (String.isBlank(payerGBA) ? 'null' : '\"' + payerGBA + '\"')  + ',';
        jsonString += '\"payergbaType\" : ' + (String.isBlank(payerGBAType) ? 'null' : '\"' + payerGBAType + '\"')  + ',';
        jsonString += '\"payerSFID\" : ' + (String.isBlank(payerSFID) ? 'null' : '\"' + payerSFID + '\"')  + ',';
        jsonString += '\"payerAccountSFID\" : ' + (String.isBlank(payerAccountSFID) ? 'null' : '\"' + payerAccountSFID + '\"')  + ',';
        jsonString += '\"gbaId\" : ' + (String.isBlank(bsaAccountNumber) ? 'null' : '\"' + bsaAccountNumber + '\"')  + ',';        
        jsonString += '\"gbaType\" : ' + (String.isBlank(bsaAccountType) ? 'null' : '\"' + bsaAccountType + '\"') + ',';
        // Changes related to AS-1287 on 19 March 18 by Lokesh Agarwal to add AdPoint Id into JSON
        jsonString += '\"adpointAccountID\" : ' + (String.isBlank(apaValue) ? 'null' : '\"' + apaValue + '\"') + ',';
        // Changes related to AS-1362 to Pass new field through canvas - Referral_Source__c 
        jsonString += '\"ReferralSource\" : ' + (String.isBlank(ReferralSource) ? 'null' : '\"' + ReferralSource + '\"') + ',' ;
        jsonString += '\"ReferralSourcepc\" : ' + (String.isBlank(ReferralSourcepc) ? 'null' : '\"' + ReferralSourcepc + '\"') ;
        jsonString += '},';
        
        // leapfrog wants to move all parameters which originally in the signed request to JSON payload message
        // so it's easy for them to pass the whole message to their server side
        jsonString += '\"parameters\": {';
        
        // 2017-08-11 AdSales 338 darshan.gosar@bluewolfgroup.com Added code to pass Campaign id as part of JSON string to 3wks team
        jsonString += '\"orderId\" : ' + (String.isBlank(leapfrogBookingId) ? 'null' : '\"' + leapfrogBookingId + '\"')  + ',';
        
        System.debug('leapfrogBookingAccountId##' + leapfrogBookingAccountId);
        
        if(pageAction == 'NEW')
            jsonString += '\"bookingAccountId\" : null,';
        else
            jsonString += '\"bookingAccountId\" : ' + (String.isBlank(leapfrogBookingAccountId) ? 'null' : '\"' + leapfrogBookingAccountId + '\"')  + ',';
                    
        jsonString += '\"actionType\" : ' + (String.isBlank(actionTypeName) ? 'null' : '\"' + actionTypeName + '\"')  + ',';
        jsonString += '\"gbaId\" : ' + (String.isBlank(bsaAccountNumber) ? 'null' : '\"' + bsaAccountNumber + '\"')  + ',';
        
        // 2017-09-27 AdSales 818 darshan.gosar@bluewolfgroup.com Added Account_Type__c to be passed as gbaAccountType
        jsonString += '\"gbaType\" : ' + (String.isBlank(bsaAccountType) ? 'null' : '\"' + bsaAccountType + '\"')  + ',';
        jsonString += '\"netDAId\" : ' + (String.isBlank(netDAJDE) ? 'null' : '\"' + netDAJDE + '\"') + ',';
        jsonString += '\"networkUsername\" : ' + (String.isBlank(networkUsername) ? 'null' : '\"' + networkUsername + '\"')+ ',';
        // Changes related to AS-1287 on 19 March 18 by Lokesh Agarwal to add AdPoint Id into JSON
        jsonString += '\"adpointAccountID\" : ' + (String.isBlank(apaValue) ? 'null' : '\"' + apaValue + '\"');
        jsonString += '}';
        
        jsonString += '}';
        
        
        /*  
//20170725 item--00300 NK
//this code has temporaily been hashed out and replaced with the hardcoded
//JSON below it to test


jsonString = '{';
jsonString += '\"user\": {';
jsonString += '\"attributes\": {';
jsonString += '\"type\": \"User\",';
jsonString += '\"url\": \"/services/data/v40.0/sobjects/User/00590000001UhvgAAC\"';
jsonString += '},';
jsonString += '\"Team__c\": \"n/a\",';
jsonString += '\"Id\": \"00590000001UhvgAAC\",';
jsonString += '\"Network_Username__c\": \"taylorcw\",';
jsonString += '\"ProfileId\": \"00e90000001fKezAAE\",';
jsonString += '\"Name\": \"Craig Taylor\",';
jsonString += '\"LastName\": \"Taylor\",';
jsonString += '\"FirstName\": \"Craig\",';
jsonString += '\"Email\": \"craig.taylor=news.com.au@example.com\",';
jsonString += '\"Profile\": {';
jsonString += '\"attributes\": {';
jsonString += '\"type\": \"Profile\",';
jsonString += '\"url\": \"/services/data/v40.0/sobjects/Profile/00e90000001fKezAAE\"';
jsonString += '},';
jsonString += '\"Name\": \"~System Administrator\",';
jsonString += '\"Id\": \"00e90000001fKezAAE\"';
jsonString += '}';
jsonString += '},';
jsonString += '\"booking\": null,';
jsonString += '\"account\": {';
jsonString += '\"attributes\": {';
jsonString += '\"type\": \"Account\",';
jsonString += '\"url\": \"/services/data/v40.0/sobjects/Account/0019000000npTilAAE\"';
jsonString += '},';
jsonString += '\"Id\": \"0019000000npTilAAE\",';
jsonString += '\"Name\": \"Winston Music\",';
jsonString += '\"Phone\": \"0882769988\",';
jsonString += '\"External_ID__c\": \"1-10W0-374\",';
jsonString += '\"BillingStreet\": \"87 Winston Ave\",';
jsonString += '\"BillingCity\": \"Daw Park\",';
jsonString += '\"BillingState\": \"SA\",';
jsonString += '\"BillingPostalCode\": \"5041\",';
jsonString += '\"BillingCountry\": \"Australia\",';
jsonString += '\"Type\": \"Non Account Managed\",';
jsonString += '\"Revenue_Group__c\": \"Retail\",';
jsonString += '\"GST_Exempt__c\": false,';
jsonString += '\"Has_Agreement__c\": 0,';
jsonString += '\"AccountNumber\": \"90007894046\",';
jsonString += '\"RecordTypeId\": \"01290000000X3tXAAS\"';
jsonString += '},';
jsonString += '\"bookingSystemAccount\": null,';
jsonString += '\"contact\": {';
jsonString += '\"attributes\": {';
jsonString += '\"type\": \"Contact\",';
jsonString += '\"url\": \"/services/data/v40.0/sobjects/Contact/003O0000012BjRTIA0\"';
jsonString += '},';
jsonString += '\"FirstName\": \"Craig\",';
jsonString += '\"LastName\": \"Taylor\",';
jsonString += '\"Email\": \"craig.taylor+1002@news.com.au\",';
jsonString += '\"Phone\": \"0398758575\",';
jsonString += '\"Id\": \"003O0000012BjRTIA0\"';
jsonString += '},';
jsonString += '\"metadata\": {';
jsonString += '\"caseId\": null,';
jsonString += '\"salesRepId\": \"00590000001UhvgAAC\"';
jsonString += '},';
jsonString += '\"parameters\": {';
jsonString += '\"orderId\": null,';
jsonString += '\"bookingAccountId\": null,';
jsonString += '\"actionType\": \"CreateOrder\",';
jsonString += '\"gbaId\": \"T555007\",';
jsonString += '\"netDAId\": null,';
jsonString += '\"networkUsername\": \"taylorcw\"';
jsonString += '}';
jsonString += '}';

*/
        
        System.debug('@generateJSONString jsonString before escape: ' + jsonString);
        
        jsonString = String.escapeSingleQuotes(jsonString);
        
        System.debug('@generateJSONString jsonString after escape: ' + jsonString);
        
    }
    
    private void showMessage(String msg) {
        this.hasError = true;
        ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, msg);
        ApexPages.addMessage(errMsg);
    }
    
    public static String findObjectNameFromRecordIdPrefix(String recordIdOrPrefix){
        String objectName = '';
        //Get prefix from record ID
        //This assumes that you have passed at least 3 characters
        String myIdPrefix = String.valueOf(recordIdOrPrefix).substring(0,3);
        
        //Get schema information
        Map<String, Schema.SObjectType> gd =    Schema.getGlobalDescribe(); 
        
        //Loop through all the sObject types returned by Schema
        for(Schema.SObjectType stype : gd.values()){
            Schema.DescribeSObjectResult r = stype.getDescribe();
            String prefix = r.getKeyPrefix();
            System.debug('Prefix is ' + prefix);
            
            //Check if the prefix matches with requested prefix
            if(prefix!=null && prefix.equals(myIdPrefix)){
                objectName = r.getName();
                System.debug('Object Name! ' + objectName);
                break;
            }
        }
        
        return objectName;
    }
    
}
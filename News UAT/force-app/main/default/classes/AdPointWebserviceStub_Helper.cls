public with sharing class AdPointWebserviceStub_Helper
{
    AdPointWebserviceStub.news_crm_adapter_pub_adPointSyncWD_Port AdPointWebservice;
    AdPointWebserviceStub.crmAdPointAccount accountReq;
    AdPointWebserviceStub.crmAdPointContact contactReq;
    AdPointWebserviceStub.crmAdPointOrder orderReq;
    
    public AdPointWebserviceStub_Helper()
    {
        this.AdPointWebservice = new AdPointWebserviceStub.news_crm_adapter_pub_adPointSyncWD_Port();
        this.accountReq = new AdPointWebserviceStub.crmAdPointAccount();
        this.contactReq = new AdPointWebserviceStub.crmAdPointContact();
        this.orderReq = new AdPointWebserviceStub.crmAdPointOrder();
    }

    public AdPointWebserviceStub.adPointAccountSyncResponse createDigitalAccount(Account acct, Sales_Order__c salesOrder)
    {
        this.accountReq.Customer_Books_Direct_xc = salesOrder.Booking_Type__c == 'Direct'?'Yes':'No';
        return createDigitalAccount(acct);
    }

    
    public AdPointWebserviceStub.adPointAccountSyncResponse createDigitalAccount(Account acct)
    {
        this.accountReq.Id = acct.Id;
        this.accountReq.AccountNumber = acct.AccountNumber;
        this.accountReq.Account_Type_xc = acct.Account_Type__c;
        this.accountReq.Name = acct.Name;
        this.accountReq.AdPoint_User_Id_xc = acct.AdPoint_User_Id__c;
        this.accountReq.Is_Agency_xc = String.valueOf(acct.Is_Agency__c);
        
        this.accountReq.BillingCity = String.isBlank(acct.BillingCity) ? '' : acct.BillingCity;
        this.accountReq.BillingCountry = String.isBlank(acct.BillingCountry) ? '' : acct.BillingCountry;
        this.accountReq.BillingPostalCode = String.isBlank(acct.BillingPostalCode) ? '' : acct.BillingPostalCode;
        this.accountReq.BillingState = String.isBlank(acct.BillingState) ? '' : acct.BillingState;
        this.accountReq.BillingStreet = String.isBlank(acct.BillingStreet) ? '' : acct.BillingStreet;
        
        this.accountReq.ShippingCity = String.isBlank(acct.ShippingCity) ? '' : acct.ShippingCity;
        this.accountReq.ShippingCountry = String.isBlank(acct.ShippingCountry) ? '' : acct.ShippingCountry;
        this.accountReq.ShippingPostalCode = String.isBlank(acct.ShippingPostalCode) ? '' : acct.ShippingPostalCode;
        this.accountReq.ShippingState = String.isBlank(acct.ShippingState) ? '' : acct.ShippingState;
        this.accountReq.ShippingStreet = String.isBlank(acct.ShippingStreet) ? '' : acct.ShippingStreet;
        
        this.accountReq.Creative_Agency_For_Digital_Customer_xc = String.isBlank(acct.Creative_Agency_AdPoint_Id__c) ? '' : acct.Creative_Agency_AdPoint_Id__c;
        this.accountReq.Media_Agency_For_Digital_Customer_xc = String.isBlank(acct.Media_Agency_AdPoint_Id__c) ? '' : acct.Media_Agency_AdPoint_Id__c;
        
        this.accountReq.Fax = String.isBlank(acct.Fax) ? '' : acct.Fax;
        this.accountReq.Phone = String.isBlank(acct.Phone) ? '' : acct.Phone;
        
        this.accountReq.Industry_Code_Name_In_Text_xc = String.isBlank(acct.Industry_Code_Name_In_Text__c) ? '' : acct.Industry_Code_Name_In_Text__c;
        this.accountReq.Revenue_Group_c = String.isBlank(acct.Revenue_Group__c) ? '' : acct.Revenue_Group__c;
        this.accountReq.Status_xc = acct.Status__c == 'Active' ? 'true' : 'false';
        
        this.accountReq.Is_on_Black_List_Digital_Media_xc = String.valueOf(acct.Is_on_Black_List_Digital_Media__c);
        this.accountReq.Blacklist_Reason_Digital_xc = String.isBlank(acct.Blacklist_Reason_Digital__c) ? '' : acct.Blacklist_Reason_Digital__c;
        
        this.accountReq.Website = String.isBlank(acct.Website) ? '' : acct.Website;
        
        AdPointWebserviceStub.adPointAccountSyncResponse accountResp = AdPointWebservice.adPointAccountSync(null, this.accountReq);
        
        system.debug('@accountResp status:' + accountResp.status);
        return accountResp;
    }
    
    public AdPointWebserviceStub.adPointContactSyncResponse createDigitalContact(Contact con, String AccountAdPointId)
    {
        this.contactReq.Id = con.Id;
        this.contactReq.AccountId = con.AccountId;
        this.contactReq.Account_AdPoint_Id_xc = AccountAdPointId;
        this.contactReq.Email = String.isBlank(con.Email) ? '' : con.Email;
        this.contactReq.Fax = String.isBlank(con.Fax) ? '' : con.Fax;
        this.contactReq.FirstName = con.FirstName;
        this.contactReq.LastName = con.LastName; 
        this.contactReq.MobilePhone = String.isBlank(con.MobilePhone) ? '' : con.MobilePhone;
        this.contactReq.Phone = con.Phone;
        this.contactReq.Salutation = String.isBlank(con.Salutation) ? '' : con.Salutation;
        this.contactReq.Title = String.isBlank(con.Title) ? '' : con.Title;
        
        AdPointWebserviceStub.adPointContactSyncResponse contactResp = AdPointWebservice.adPointContactSync(null, this.contactReq);
        system.debug('@contactResp status:' + contactResp.status);
        return contactResp;
    }
    
    public AdPointWebserviceStub.adPointCreateOrderResponse createOrder(Contact con, Account customerAcct, 
                                                                        Account agencyAcct, Sales_Order__c salesOrder)
    {
        this.orderReq.Customer_ID = customerAcct.AdPoint_Id__c;
        this.orderReq.PaymentCondition_ID = '1';
        this.orderReq.Contract_ID = '0';
        
        // if customer and agency account have different ids, it means it is an agency sale
        // otherwise, ignore agency_id because it is a non agency sale
        if(customerAcct.Id != agencyAcct.Id)
        {
            this.orderReq.Agency_ID = agencyAcct.AdPoint_Id__c;
            this.orderReq.InvoiceTo = 'Agency';
        }
        else
            this.orderReq.InvoiceTo = 'Customer';
        
        this.orderReq.Customer_Books_Direct_xc = salesOrder.Booking_Type__c == 'Direct'?'Yes':'No';
        this.orderReq.datasan_xAccount_ABN_xc  = customerAcct.datasan__Account_ABN__c;
        this.orderReq.Placer_Contact_Email_c = con.Email;
        this.orderReq.AccountName = customerAcct.Name;

        this.orderReq.Contact_ID = con.AdPoint_Id__c;
        this.orderReq.Ref_num_2 = salesOrder.Calc_External_id__c;
        
        // added by Tim Fabros 20 / 06 / 2014 - SFE-270
        // changes the order name to the campaign name
        // reverted back to original state
        // BEGIN:
        this.orderReq.Name = salesOrder.Name;
        // END:
        
        this.orderReq.Segment = String.isBlank(customerAcct.Industry_Code_Name_In_Text__c) ? '' : customerAcct.Industry_Code_Name_In_Text__c;
        
        // confirmed and updated on 20/01/2014
        // using network username instead of adpoint user id for current running user
        String networkUsername;
        
        if(!Test.isRunningTest())
        {
            networkUsername = [Select u.Network_Username__c From User u Where u.Id =: userInfo.getUserId() limit 1].Network_Username__c;
        } 
        this.orderReq.BookingAccountManagerNetworkLogin = networkUsername;
        
        
        String adPointUserIdForSaleOrderOwner;
        
        if(!Test.isRunningTest())
        {
            adPointUserIdForSaleOrderOwner = [Select c.AdPoint_User_Id__c 
                                              From CyberAd_User_Credential__c c 
                                              Where c.User__c =: salesOrder.OwnerId
                                              And c.RecordType.DeveloperName = 'AdPoint'
                                              Limit 1].AdPoint_User_Id__c;  
        } 
        
        this.orderReq.AccountManager_ID = adPointUserIdForSaleOrderOwner;
        
        system.debug('@orderResp adPointCreateOrder this.orderReq: ' + this.orderReq);
        
        AdPointWebserviceStub.adPointCreateOrderResponse orderResp = AdPointWebservice.adPointCreateOrder(null, this.orderReq);
        system.debug('@orderResp status:' + orderResp.status);
        return orderResp;
    }
    
}
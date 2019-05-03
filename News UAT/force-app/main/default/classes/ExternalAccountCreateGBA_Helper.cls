/*---------------------------------------------------------
author: Celso de Souza
Company: Salesforce.com
description: Handles creation of GBA in SF and genera
History:
23/05/2013  Celso de Souza  Created
20/06/2013  Bohao Chen      Updated
---------------------------------------------------------*/
public without sharing class ExternalAccountCreateGBA_Helper {
    
    
    private String authorizationToken;
    private GeneraWebserviceLiteStub.EnterpriseWebServiceSoap ws;
    
    public ExternalAccountCreateGBA_Helper()
    {
        system.debug('@ Constructor ExternalAccountCreateGBA_Helper()');
        ws = new GeneraWebserviceLiteStub.EnterpriseWebServiceSoap();
        ws.timeout_x = 10000;
        ws.outputHttpHeaders_x = new Map<String, String>();
        ws.inputHttpHeaders_x = new Map<String, String>();
    }
    
    // login to web service
    public void login()
    {
        system.debug('@ login()');
        ws.login();
        authorizationToken = ws.outputHttpHeaders_x.get('Set-Cookie');
        ws.inputHttpHeaders_x.put('Cookie', authorizationToken);
        system.debug('### Set-Cookie:' + authorizationToken);
    }
    
    // logout from web service
    public void logout()
    {
        system.debug('@ logout()');
        ws.logout();
    }
    
    public void saveAccount(String accNumber)
    {
        system.debug('@ saveAccount(String accNumber)');
        system.debug('accNumber:' + accNumber);
        list<GeneraWebserviceLiteStub.Refund> refunds;
        refunds = ws.SaveAccount(accNumber);
        system.debug('ws.endpoint_x:' + ws.endpoint_x);
        system.debug('refunds:' + refunds);
    }
    
    public void setAccount(String accNumber, String fieldName, String fieldDetail) {
        ws.SetAccountField(accNumber, fieldName, fieldDetail);
    }

    public String createAccount(    String Country,
                                String CustomerName,
                                String CustomerTitle,
                                String EmailAddress,
                                Boolean IsNew,
                                String Postcode,
                                Decimal RefundTotal,
                                String State,
                                String Street1,
                                String Street2,
                                String Suburb,
                                String TelephoneCountryCode,
                                String TelephoneAreaCode,
                                String TelephoneLocalNumber,
                                String Type,
                                String Abn,
                                String FirstName,
                                String LastName,
                                String DPID,
                                String DefaultRevenueGroup,
                                String ConfirmationEmail,
                                String parentExternalAccountId,
                                String newAccountRequest,
                                String OwningCreditDivision
                               ) 
    {
        system.debug('@ createAccount(...)');
        GeneraWebserviceLiteStub.AccountInfo accInfo = new GeneraWebserviceLiteStub.AccountInfo();
        
        accInfo.Country              = Country;
        accInfo.CustomerName         = CustomerName;
        accInfo.CustomerTitle        = CustomerTitle;
        accInfo.EmailAddress         = EmailAddress;
        accInfo.IsNew                = IsNew;
        accInfo.Postcode             = Postcode;
        accInfo.RefundTotal          = RefundTotal;
        accInfo.State                = State;
        accInfo.Street1              = Street1;
        accInfo.Street2              = Street2;
        accInfo.Suburb               = Suburb;
        accInfo.TelephoneAreaCode    = TelephoneAreaCode;
        accInfo.TelephoneCountryCode = TelephoneCountryCode;
        accInfo.TelephoneLocalNumber = TelephoneLocalNumber;
        accInfo.Type_x               = Type;
        
        // set extended fields
        List<GeneraWebserviceLiteStub.NameValuePair> ExtendedFields = new List<GeneraWebserviceLiteStub.NameValuePair>();
        
        GeneraWebserviceLiteStub.NameValuePair extendedFieldNameValuePair = new GeneraWebserviceLiteStub.NameValuePair();
        extendedFieldNameValuePair.Name = 'ABN';
        extendedFieldNameValuePair.Value = Abn;
        ExtendedFields.add(extendedFieldNameValuePair);
        
        
        
        extendedFieldNameValuePair = new GeneraWebserviceLiteStub.NameValuePair();
        extendedFieldNameValuePair.Name = 'Channel';
        extendedFieldNameValuePair.Value = 'Salesforce';
        ExtendedFields.add(extendedFieldNameValuePair);
        
        
        if(Type == 'Private Party')
        {
            extendedFieldNameValuePair = new GeneraWebserviceLiteStub.NameValuePair();
            extendedFieldNameValuePair.Name = 'FirstName';
            extendedFieldNameValuePair.Value = FirstName;
            ExtendedFields.add(extendedFieldNameValuePair);
            
            extendedFieldNameValuePair = new GeneraWebserviceLiteStub.NameValuePair();
            extendedFieldNameValuePair.Name = 'LastName';
            extendedFieldNameValuePair.Value = LastName;
            ExtendedFields.add(extendedFieldNameValuePair);
        }
        
        
        
        extendedFieldNameValuePair = new GeneraWebserviceLiteStub.NameValuePair();
        extendedFieldNameValuePair.Name = 'PostDPID';
        extendedFieldNameValuePair.Value = DPID;
        ExtendedFields.add(extendedFieldNameValuePair);
        
        
        if(String.isNotBlank(DPID))
        {
            ExtendedFields.add(this.createExtendedFieldNameValuePair('PostValidated', '1'));
            ExtendedFields.add(this.createExtendedFieldNameValuePair('PostIsValid', '1'));
        }
        
        // 0 for any account type other than casual business
        if(Type == 'Casual Business' || Type == 'Private Party')
        {
            ExtendedFields.add(this.createExtendedFieldNameValuePair('IsTransient', '1'));
            ExtendedFields.add(this.createExtendedFieldNameValuePair('DefaultBillingMethod', 'PP - Credit Card')); 
            ExtendedFields.add(this.createExtendedFieldNameValuePair('InvalidBillMethod', 'Statement'));            
        }
        else if (Type == 'Request for Established')
        {
            accInfo.Type_x = 'Casual Business';
            ExtendedFields.add(this.createExtendedFieldNameValuePair('IsTransient', '1'));
            ExtendedFields.add(this.createExtendedFieldNameValuePair('OwningCreditDivision', OwningCreditDivision));
            ExtendedFields.add(this.createExtendedFieldNameValuePair('DefaultBillingMethod', 'PP - Credit Card'));
            ExtendedFields.add(this.createExtendedFieldNameValuePair('InvalidBillMethod', 'Statement'));                    
        }
        else
        {
            ExtendedFields.add(this.createExtendedFieldNameValuePair('IsTransient', '0'));
            ExtendedFields.add(this.createExtendedFieldNameValuePair('OwningCreditDivision', OwningCreditDivision));
            ExtendedFields.add(this.createExtendedFieldNameValuePair('DefaultBillingMethod', 'Statement'));                        
        }
        
        
        if(newAccountRequest.trim().length()>0)
        {
            ExtendedFields.add(this.createExtendedFieldNameValuePair('NewAccountRequest', newAccountRequest));
            ExtendedFields.add(this.createExtendedFieldNameValuePair('NewAccountRequestState', 'Is Required'));
        }
        
        if(DefaultRevenueGroup.trim().length()>0)
            ExtendedFields.add(this.createExtendedFieldNameValuePair('DefaultRevenueGroup', DefaultRevenueGroup));
        
        if(ConfirmationEmail.trim().length()>0)
            ExtendedFields.add(this.createExtendedFieldNameValuePair('ConfirmationEmail', ConfirmationEmail));
        
        /**** Updated by Bohao Chen on 28th April, 2014 for JIRA issue SFE-422 ******/
        /* 16/6/2015 Celso de Souza added Type Contra to be flagged as GST exempt  (IM719908) */
        if( Type=='Client of Overseas Advertising Agency' ||
            Type=='Client of Overseas Agent' ||
            Type=='Contra' ||
            Type=='House' ||
            Type=='Overseas' ||
            Type=='Overseas Advertising Agency' ||
            Type=='Overseas Agent')
        {
            ExtendedFields.add(this.createExtendedFieldNameValuePair('GSTExempt', 'Yes'));
        }
        /**** Update Ends ******/
        
        /**** Updated by Bohao Chen on 7th May, 2014 for JIRA issue SFE-494 ******/
        /* Agency commission missing on new Client of Ad Agency and Overseas GBA creates
* The Default Values CyberSell uses:
* Client of Ad Agency = 1000
* Client of Newsagent = 1000
* Client of Overseas Advertising Agency = 1000
* Client of Overseas Agent = 3000
*/
        if(Type == 'Client of Ad Agency' || Type == 'Client of Overseas Advertising Agency')
        {
            ExtendedFields.add(this.createExtendedFieldNameValuePair('AgencyCommission', '1000'));
        }
        else if(Type == 'Client of Overseas Agent')
        {
            ExtendedFields.add(this.createExtendedFieldNameValuePair('AgencyCommission', '3000'));
        }
        
        // Updated by Bohao Chen on 11/06/2014 for JIRA SFE-543
        // BEGIN
        if(ConfirmationEmail != null && ConfirmationEmail != '')
        {
            ExtendedFields.add(this.createExtendedFieldNameValuePair('ConfirmAllBookings', 'YES'));
        }
        else
        {
            ExtendedFields.add(this.createExtendedFieldNameValuePair('ConfirmAllBookings', 'NO'));
        }
        // END
        
        /**** Update Ends ******/
        
        if(parentExternalAccountId != null)
        {
            External_Account__c parentExternalAcct = [Select Name, Account_No__c, Genera_Name_Display__c
                                                      From External_Account__c e
                                                      Where e.Id =: parentExternalAccountId limit 1];
            
            //Parent Account Name
            ExtendedFields.add(this.createExtendedFieldNameValuePair('ParentName', parentExternalAcct.Name));
            
            //Parent GBA Number
            ExtendedFields.add(this.createExtendedFieldNameValuePair('ParentGBA', parentExternalAcct.Account_No__c));
        }
        
        accInfo.ExtendedField = ExtendedFields;
        
        system.debug('accInfo:' + accInfo);
        
        String accNumber = ws.CreateAccount(accInfo);
        system.debug('accNumber:' + accNumber);
        
        return accNumber;
    }
    
    private GeneraWebserviceLiteStub.NameValuePair createExtendedFieldNameValuePair(String name, String value)
    {
        GeneraWebserviceLiteStub.NameValuePair extendedFieldNameValuePair = new GeneraWebserviceLiteStub.NameValuePair();
        extendedFieldNameValuePair.Name = name;
        extendedFieldNameValuePair.Value = value;
        return extendedFieldNameValuePair;
    }
    
    public External_Account__c prepopulateExternalAccount(External_Account__c extAcc, Account accAdvertiser, Account accPayer, boolean isBookingTypeAgency)
    {
        return prepopulateExternalAccount(extAcc, accAdvertiser, accPayer, isBookingTypeAgency, null);
    }
    
    public External_Account__c prepopulateExternalAccount(External_Account__c extAcc, Account accAdvertiser, Account accPayer, boolean isBookingTypeAgency, String accType)
    {
        system.debug('@ prepopulateExternalAccount(...)');
        system.debug('extAcc:' + extAcc);
        system.debug('accAdvertiser:' + accAdvertiser);
        system.debug('accPayer:' + accPayer);
        system.debug('isBookingTypeAgency:' + isBookingTypeAgency);
        system.debug('accType:' + accType);
        
        if((!isBookingTypeAgency))// || accAdvertiser.Name == accPayer.Name)
        {
            if(!accAdvertiser.IsPersonAccount)
            {
                extAcc.name = accAdvertiser.Name;
                extAcc.Post_Code__c = accAdvertiser.BillingPostalCode;
                extAcc.Country__c = accAdvertiser.BillingCountry;
                extAcc.State__c = accAdvertiser.BillingState;
                extAcc.Suburb__c = accAdvertiser.BillingCity;
                extAcc.Street__c = accAdvertiser.BillingStreet;
                extAcc.DPID__c = accAdvertiser.DPID_Primary_Address__c ;
                extAcc.ABN_Number__c = accAdvertiser.AccountNumber;
                extAcc.Phone__c = accAdvertiser.Phone;
            }
            else
            {
                extAcc.name = accAdvertiser.Name;
                extAcc.Post_Code__c = accAdvertiser.PersonMailingPostalCode;
                extAcc.Country__c = accAdvertiser.PersonMailingCountry;
                extAcc.State__c = accAdvertiser.PersonMailingState;
                extAcc.Suburb__c = accAdvertiser.PersonMailingCity;
                extAcc.Street__c = accAdvertiser.PersonMailingStreet;
                extAcc.DPID__c = accAdvertiser.DPID_Primary_Address__pc;
                extAcc.Phone__c = accAdvertiser.PersonHomePhone;
                extAcc.First_Name__c = accAdvertiser.FirstName;
                extAcc.Last_Name__c = accAdvertiser.LastName;                   
            }
        }
        else
        {
            extAcc.name = accAdvertiser.Name; // + ' via ' + accPayer.Name;
            
            extAcc.Post_Code__c = accPayer.BillingPostalCode;
            extAcc.Country__c = accPayer.BillingCountry;
            extAcc.State__c = accPayer.BillingState;
            extAcc.Suburb__c = accPayer.BillingCity;
            extAcc.Street__c = accPayer.BillingStreet;
            extAcc.DPID__c = accPayer.DPID_Primary_Address__c ;
            extAcc.ABN_Number__c = accPayer.AccountNumber;
        }
        
        
        
        if(accAdvertiser.Revenue_Group__c!=null && accAdvertiser.Revenue_Group__c.trim().length()>0)
        {
            for(string s : Genera_Revenue_Groups__c.getAll().keySet())
            {
                //system.debug('Genera_Revenue_Groups__c s: ' + s +  ' :: ' + Genera_Revenue_Groups__c.getAll().get(s).Account_Revenue_Group_Value__c);
                
                if(Genera_Revenue_Groups__c.getAll().get(s).Account_Revenue_Group_Value__c == accAdvertiser.Revenue_Group__c)
                {
                    extAcc.Default_Revenue_Group__c = s;
                    //system.debug('extAcc.Default_Revenue_Group__c:' + extAcc.Default_Revenue_Group__c);
                }
            }
        }
        
        if(accType!=null)
            extAcc.Account_Type__c = accType;
        
        return extAcc;
    }
    
    
    
    
    
    
    public list<External_Account__c> getAvailableExternalAccount(Account accAdvertiser, Account accPayer, boolean isBookingTypeAgency, String externalAccountRecordTypeDeveloperName)
    {
        system.debug('@ getAvailableExternalAccount(...)');
        system.debug('accAdvertiser:' + accAdvertiser);
        system.debug('accPayer:' + accPayer);
        system.debug('isBookingTypeAgency:' + isBookingTypeAgency);
        system.debug('externalAccountRecordTypeDeveloperName:' + externalAccountRecordTypeDeveloperName);
        
        List<External_Account__c> lEa = new List<External_Account__c>();
        
        if (accAdvertiser != null &&
            (!isBookingTypeAgency || accPayer != null))
        {
            
            if (!isBookingTypeAgency)
            {
                // get all direct (no parent) Booking Accounts
                lEa = getAccountDirectExternalAccount(accAdvertiser, externalAccountRecordTypeDeveloperName);
            }
            else if (accPayer != null)
            {
                // modified by Tim Fabros 04/ 06 / 2014 - SFE-396
                // added extra Where clause to prevent getting inactive accounts
                // added Status__c to the query
                // BEGIN:
                // get all client Booking Accounts for the select payer
                lEa = [SELECT Id,
                       Name,
                       Account_No__c,
                       RecordType.Name,
                       External_Account__r.Name,
                       Customer_Account__c,
                       Customer_Account__r.Name,
                       Payer_Account__c,
                       Payer_Account_Name__c,
                       Account_Type__c,
                       Genera_Name_Display__c,
                       Status__c
                       FROM External_Account__c
                       WHERE Customer_Account__c = :accAdvertiser.id
                       AND External_Account__r.Customer_Account__c = :accPayer.id
                       AND RecordType.DeveloperName = :externalAccountRecordTypeDeveloperName
                       AND Status__c <> 'Inactive'];
                // END:
            }
        }
        
        system.debug('lEa:' + lEa);
        
        return lEa;
    }
    
    
    public list<External_Account__c> getAccountDirectExternalAccount(Account acc, String externalAccountRecordTypeDeveloperName)
    {
        system.debug('@ getAccountDirectExternalAccount(...)');
        
        system.debug('externalAccountRecordTypeDeveloperName:' + externalAccountRecordTypeDeveloperName);
        
        List<External_Account__c> lEa = new List<External_Account__c>();
        // modified by Tim Fabros 04/ 06 / 2014 - SFE-396
        // added extra Where clause to prevent getting inactive accounts
        // added Status__c to the query
        // BEGIN:
        lEa = [SELECT Id,
               Name,
               Account_No__c,
               RecordType.Name,
               External_Account__r.Name,
               Customer_Account__c,
               Customer_Account__r.Name,
               Payer_Account__c,
               Payer_Account_Name__c,
               Account_Type__c,
               Genera_Name_Display__c,
               Status__c
               FROM External_Account__c
               WHERE Customer_Account__c = :acc.id
               AND RecordType.DeveloperName = :externalAccountRecordTypeDeveloperName
               AND External_Account__c = null
               AND Status__c != 'Inactive'];
        // END:
        system.debug('lEa.size():' + lEa.size());
        
        return lEa;
    }
    
}
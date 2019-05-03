/*---------------------------------------------------------
Author: James Neave
Company: Salesforce.com
description: Controller for pre-processing address information
History:
23/06/2013  James Neave Created
01/07/2013  Bohao Chen  Updated
22/07/2013  Bohao Chen  Updated
---------------------------------------------------------*/

global with sharing class SimplePrefill_ControllerX 
{
    @TestVisible private static final String SAVE_ERR_MSG = 'Cannot save this update, please contact administrator for this issue.';
    private SObject sObj;
    public Account acct {get;set;}
    public Lead lead {get;set;}
    public Contact cnt {get;set;}
    public External_Account__c gbaAcct {get;set;}
    public String acctName {get;set;}
    public String returnUrl {get;set;}
    public String recordTypeId {get;set;}
    public String sectionTitle {get;set;}
    public String ringLeadUrl 
    {
        get
        {
           if(ringLeadUrl == null)
           {
               ringLeadUrl = SystemParameters__c.getall().get('RingLead_url').Value__c;
           }
           return ringLeadUrl;
        }
        set;
    }
    
    // prepare error messages map from custom setting
    public Map<String, Address_Validation_Error_Message__c> errorMsgMap
    {
        get
        {
           if(errorMsgMap == null)
           {
               errorMsgMap = Address_Validation_Error_Message__c.getall();
           }
           return errorMsgMap;
        }
        set;
    }
    
    public SimplePrefill_ControllerX(ApexPages.StandardController controller) 
    {        
        sObj = controller.getRecord();
        String recordId = controller.getId();
        
        returnUrl = apexpages.currentPage().getParameters().get('retURL');
        recordTypeId = apexpages.currentPage().getParameters().get('RecordType'); 
        
        // get account, contact, lead, gba account prefixes dynamically
        String acctPrefix = Schema.getGlobalDescribe().get('Account').getDescribe().getKeyPrefix();
        String cntPrefix = Schema.getGlobalDescribe().get('Contact').getDescribe().getKeyPrefix();
        String leadPrefix = Schema.getGlobalDescribe().get('Lead').getDescribe().getKeyPrefix();
        String gbaAcctPrefix = Schema.getGlobalDescribe().get('External_Account__c').getDescribe().getKeyPrefix();
        
        if(sObj.getSObjectType().getDescribe().getKeyPrefix() == acctPrefix)
        {
            if(recordId == null)
            {
                acct = (Account)sObj;
                this.sectionTitle = 'New Account';
            }
            else
            {
                
                acct = [Select Name, DPID_Secondary_Address__pc, DPID_Primary_Address__pc,
                        datasan__PersonMailing_Address_DPID__c,
                        BillingStreet, PersonMailingStreet,
                        BillingCountry, PersonMailingCountry,
                        BillingCity, PersonMailingCity, 
                        BillingState, PersonMailingState, 
                        BillingPostalCode, PersonMailingPostalCode, 
                        DPID_Primary_Address__c, 
                        ShippingStreet, PersonOtherStreet, 
                        ShippingCountry, PersonOtherCountry, 
                        ShippingCity, PersonOtherCity, 
                        ShippingState, PersonOtherState, 
                        ShippingPostalCode, PersonOtherPostalCode, 
                        DPID_Secondary_Address__c,
                        RecordTypeId, IsPersonAccount, 
                        RecordType.Name
                        from Account Where Id =: recordId limit 1];
                
                this.sectionTitle = acct.Name;
                
                if(acct.IsPersonAccount)
                {
                    acct = [Select FirstName, LastName, Salutation, 
                            DPID_Secondary_Address__pc, DPID_Primary_Address__pc,
                            datasan__PersonMailing_Address_DPID__c,
                            BillingStreet, PersonMailingStreet,
                            BillingCountry, PersonMailingCountry,
                            BillingCity, PersonMailingCity, 
                            BillingState, PersonMailingState, 
                            BillingPostalCode, PersonMailingPostalCode, 
                            DPID_Primary_Address__c, 
                            ShippingStreet, PersonOtherStreet, 
                            ShippingCountry, PersonOtherCountry, 
                            ShippingCity, PersonOtherCity, 
                            ShippingState, PersonOtherState, 
                            ShippingPostalCode, PersonOtherPostalCode, 
                            DPID_Secondary_Address__c,
                            RecordTypeId, IsPersonAccount, 
                            RecordType.Name
                            from Account Where Id =: recordId limit 1];
                    
                    this.copyAddressFromPersonToAccount(acct);
                    this.sectionTitle = acct.FirstName + ' ' + acct.LastName;
                }
                
                recordTypeId = acct.RecordTypeId;
            }
        }
        else if (sObj.getSObjectType().getDescribe().getKeyPrefix() == leadPrefix)
        {
            if(recordId == null)
            {
                lead = (Lead)sObj;
                this.sectionTitle = 'New Lead';
            }
            else
            {
                lead = [Select Name, Street, Country, City, State, PostalCode, 
                        datasan__Address_DPID__c
                        from Lead Where Id =: recordId limit 1];
                        
                this.sectionTitle = lead.Name;
            }
        }
        else if (sObj.getSObjectType().getDescribe().getKeyPrefix() == cntPrefix)
        {
            if(recordId == null)
            {
                cnt = (Contact)sObj;
                this.sectionTitle = 'New Contact';
            }
            else
            {
                cnt = [Select c.OtherStreet, c.OtherState, c.OtherPostalCode, c.OtherCountry, c.OtherCity, c.MailingStreet, 
                        c.MailingState, c.MailingPostalCode, c.MailingLongitude, c.MailingCountry, c.MailingCity, 
                        c.DPID_Secondary_Address__c, c.DPID_Primary_Address__c, c.FirstName, c.LastName 
                        From Contact c
                        Where Id =: recordId limit 1];
                        
                this.sectionTitle = cnt.FirstName + ' ' + cnt.LastName;
            }
        } 
        else if(sObj.getSObjectType().getDescribe().getKeyPrefix() == gbaAcctPrefix)
        {
            if(recordId == null)
            {
                gbaAcct = (External_Account__c)sObj;
                this.sectionTitle = 'Booking System Account';
            }
            else
            {
                gbaAcct = [Select e.Suburb__c, e.Street__c, e.State__c, e.Post_Code__c, e.Country__c, e.DPID__c, e.Name
                        From External_Account__c e
                        Where e.Id =: recordId limit 1];
                        
                this.sectionTitle = gbaAcct.Name;
            }
        }   
    }
    
    // in order to avoid hardcoded url (domain name for RingLead visualforce page)
    // the following code reads domain name from custom setting
    @RemoteAction
    global static String pageRedirect()
    {
        String ringleadUrl = SystemParameters__c.getAll().get('RingLead_url').Value__c;    
        return ringleadUrl;
    }
    
    public PageReference save()
    {
        PageReference pageRef;
        
        if(acct != null && acct.Id != null)
        {
            // in case of private party (person account), it needs to copy data from account addresses to person addresses
            if(this.acct.RecordType.Name == 'Private Party')
            {
                this.copyAddressFromAccountToPerson(this.acct);
            }

            update this.acct;
            pageRef = new PageReference('/' + acct.Id);
            pageRef.setRedirect(true);    
            
        }
        else if(lead != null && lead.Id != null)
        {            
            update lead;
            pageRef = new PageReference('/' + lead.Id);
            pageRef.setRedirect(true);        
        }
        else if(cnt != null && cnt.Id != null)
        {            
            update cnt;
            pageRef = new PageReference('/' + cnt.Id);
            pageRef.setRedirect(true);        
        }     
        else if(gbaAcct != null && gbaAcct.Id != null)
        {
            update gbaAcct;
            pageRef = new PageReference('/' + gbaAcct.Id);
            pageRef.setRedirect(true);  
        }   
        else
        {
            pageRef = null;
            ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, SAVE_ERR_MSG));
        }
        return pageRef; 
    }
    
    public PageReference next()
    {   
        PageReference pageRef;
        
        if(acct != null)
        {
            List<String> errorMsgs = this.validateAccount(acct);
            
            if(errorMsgs.size() > 0)
            {
                for(String errorMsg : errorMsgs)
                {
                    ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
                }
                return null;
            }
            
            pageRef = new PageReference(this.ringLeadUrl + 'uniqueAccount');
            
            // person account and standard account are using different field name for addresses
            // therefore, it needs to read record type name and passing the values to ring lead page
            
            Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Account; 
            Map<String,Schema.RecordTypeInfo> AccountRecordTypeInfo = cfrSchema.getRecordTypeInfosByName(); 

            Id privatePartyRecTypeId = AccountRecordTypeInfo.get('Private Party').getRecordTypeId();
            
            system.debug('====privatePartyRecTypeId=== ' + privatePartyRecTypeId);
            system.debug('====recordTypeId=== ' + recordTypeId);
            
            
            if(privatePartyRecTypeId == recordTypeId)
            {
                pageRef.getParameters().put('PersonMailingStreet',acct.BillingStreet);        
                pageRef.getParameters().put('PersonMailingCountry',acct.BillingCountry);
                pageRef.getParameters().put('PersonMailingCity',acct.BillingCity);
                pageRef.getParameters().put('PersonMailingState',acct.BillingState);
                pageRef.getParameters().put('PersonMailingPostalCode',acct.BillingPostalCode);
                pageRef.getParameters().put('DPID_Primary_Address__pc',acct.DPID_Primary_Address__c);
        
                pageRef.getParameters().put('PersonOtherStreet',acct.ShippingStreet);        
                pageRef.getParameters().put('PersonOtherCountry',acct.ShippingCountry);
                pageRef.getParameters().put('PersonOtherCity',acct.ShippingCity);
                pageRef.getParameters().put('PersonOtherState',acct.ShippingState);
                pageRef.getParameters().put('PersonOtherPostalCode',acct.ShippingPostalCode);
                pageRef.getParameters().put('DPID_Secondary_Address__pc',acct.DPID_Secondary_Address__c);
            }
            else
            {
                pageRef.getParameters().put('BillingStreet',acct.BillingStreet);        
                pageRef.getParameters().put('BillingCountry',acct.BillingCountry);
                pageRef.getParameters().put('BillingCity',acct.BillingCity);
                pageRef.getParameters().put('BillingState',acct.BillingState);
                pageRef.getParameters().put('BillingPostalCode',acct.BillingPostalCode);
                pageRef.getParameters().put('DPID_Primary_Address__c',acct.DPID_Primary_Address__c);
        
                pageRef.getParameters().put('ShippingStreet',acct.ShippingStreet);        
                pageRef.getParameters().put('ShippingCountry',acct.ShippingCountry);
                pageRef.getParameters().put('ShippingCity',acct.ShippingCity);
                pageRef.getParameters().put('ShippingState',acct.ShippingState);
                pageRef.getParameters().put('ShippingPostalCode',acct.ShippingPostalCode);
                pageRef.getParameters().put('DPID_Secondary_Address__c',acct.DPID_Secondary_Address__c);
            }
        }
        else if(lead != null)
        {
            List<String> errorMsgs = this.validateLead(lead);
            
            if(errorMsgs.size() > 0)
            {
                for(String errorMsg : errorMsgs)
                {
                    ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
                }
                return null;
            }
            
            pageRef = new PageReference(this.ringLeadUrl + 'uniqueLead');
            pageRef.getParameters().put('Street',lead.Street); 
            pageRef.getParameters().put('Country',lead.Country);
            pageRef.getParameters().put('City',lead.City);
            pageRef.getParameters().put('State',lead.State);
            pageRef.getParameters().put('PostalCode',lead.PostalCode);
            pageRef.getParameters().put('datasan__Address_DPID__c',lead.datasan__Address_DPID__c);
        }
        else if(cnt != null)
        {
            List<String> errorMsgs = this.validateContact(cnt);
            
            if(errorMsgs.size() > 0)
            {
                for(String errorMsg : errorMsgs)
                {
                    ApexPages.addMessage( new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
                }
                return null;
            }
            
            pageRef = new PageReference(this.ringLeadUrl + 'uniqueContact');
            pageRef.getParameters().put('MailingStreet',cnt.MailingStreet);        
            pageRef.getParameters().put('MailingCountry',cnt.MailingCountry);
            pageRef.getParameters().put('MailingCity',cnt.MailingCity);
            pageRef.getParameters().put('MailingState',cnt.MailingState);
            pageRef.getParameters().put('MailingPostalCode',cnt.MailingPostalCode);
            pageRef.getParameters().put('DPID_Primary_Address__c',cnt.DPID_Primary_Address__c);
            
            pageRef.getParameters().put('OtherStreet',cnt.OtherStreet);        
            pageRef.getParameters().put('OtherCountry',cnt.OtherCountry);
            pageRef.getParameters().put('OtherCity',cnt.OtherCity);
            pageRef.getParameters().put('OtherState',cnt.OtherState);
            pageRef.getParameters().put('OtherPostalCode',cnt.OtherPostalCode);
            pageRef.getParameters().put('DPID_Secondary_Address__c',cnt.DPID_Secondary_Address__c);
        }
        pageRef.getParameters().put('RecordType', recordTypeId);
        pageRef.getParameters().put('sfdc.override', '1');
        
        pageRef.setRedirect(true);   
 
        return pageRef;           
    }

    private void copyAddressFromPersonToAccount(Account acct)
    {
        acct.BillingStreet = acct.PersonMailingStreet;  
        acct.BillingCountry = acct.PersonMailingCountry;
        acct.BillingCity = acct.PersonMailingCity;
        acct.BillingState = acct.PersonMailingState;
        acct.BillingPostalCode = acct.PersonMailingPostalCode;
        acct.ShippingStreet = acct.PersonOtherStreet;
        acct.ShippingCountry = acct.PersonOtherCountry;
        acct.ShippingCity = acct.PersonOtherCity;
        acct.ShippingState = acct.PersonOtherState;
        acct.ShippingPostalCode = acct.PersonOtherPostalCode;
        acct.DPID_Primary_Address__c = acct.DPID_Primary_Address__pc;
        acct.DPID_Secondary_Address__c = acct.DPID_Secondary_Address__pc;
        
        acct.PersonMailingStreet = null;
        acct.PersonMailingCountry = null;
        acct.PersonMailingCity = null;
        acct.PersonMailingState = null;
        acct.PersonMailingPostalCode = null;
        acct.PersonOtherStreet = null;
        acct.PersonOtherCountry = null;
        acct.PersonOtherCity = null;
        acct.PersonOtherState = null;
        acct.PersonOtherPostalCode = null;
        acct.DPID_Primary_Address__pc = null;
        acct.DPID_Secondary_Address__pc = null;
    }
    
    private void copyAddressFromAccountToPerson(Account acct)
    {
        acct.PersonMailingStreet = acct.BillingStreet;  
        acct.PersonMailingCountry = acct.BillingCountry;
        acct.PersonMailingCity = acct.BillingCity;
        acct.PersonMailingState = acct.BillingState;
        acct.PersonMailingPostalCode = acct.BillingPostalCode;
        acct.PersonOtherStreet = acct.ShippingStreet;
        acct.PersonOtherCountry = acct.ShippingCountry;
        acct.PersonOtherCity = acct.ShippingCity;
        acct.PersonOtherState = acct.ShippingState;
        acct.PersonOtherPostalCode = acct.ShippingPostalCode;
        acct.DPID_Primary_Address__pc = acct.DPID_Primary_Address__c;
        acct.DPID_Secondary_Address__pc = acct.DPID_Secondary_Address__c;
        
        acct.BillingStreet = null;
        acct.BillingCountry = null;
        acct.BillingCity = null;
        acct.BillingState = null;
        acct.BillingPostalCode = null;
        acct.ShippingStreet = null;
        acct.ShippingCountry = null;
        acct.ShippingCity = null;
        acct.ShippingState = null;
        acct.ShippingPostalCode = null;
        acct.DPID_Primary_Address__c = null;
        acct.DPID_Secondary_Address__c = null;
    }
    
    public PageReference Cancel()
    {
        PageReference returnPage;
        
        if(returnUrl != null)
        {
            returnPage = new PageReference(returnUrl);
        }
        else if(this.acct != null && this.acct.Id != null)
        {
            returnPage = new PageReference('/' + this.acct.Id);
        }
        else if(this.lead != null && this.lead.Id != null)
        {
            returnPage = new PageReference('/' + this.lead.Id);
        }
        else if(this.cnt != null && this.cnt.Id != null)
        {
            returnPage = new PageReference('/' + this.cnt.Id);
        }  
        else if(this.gbaAcct != null && this.gbaAcct.Id != null)
        {
            returnPage = new PageReference('/' + this.gbaAcct.Id);
        }   
        else
        {
            returnPage = new PageReference('/');
        }
        return returnPage;
    }
    
    public PageReference clear()
    {
        PageReference returnPage;
        
        if(sObj.getSObjectType().getDescribe().getKeyPrefix() == '001')
        {
            acct.BillingStreet = null;
            acct.BillingCountry = null;
            acct.BillingCity = null;
            acct.BillingState = null;
            acct.BillingPostalCode = null;
            acct.ShippingStreet = null;
            acct.ShippingCountry = null;
            acct.ShippingCity = null;
            acct.ShippingState = null;
            acct.ShippingPostalCode = null;
            acct.DPID_Primary_Address__c = null;
            acct.DPID_Secondary_Address__c = null;
        }
        else if (sObj.getSObjectType().getDescribe().getKeyPrefix() == '00Q')
        {
            lead.Street = null;
            lead.City = null;
            lead.State = null;
            lead.PostalCode = null;
            lead.Country = null;
            lead.datasan__Address_DPID__c = null;
        }
        else if (sObj.getSObjectType().getDescribe().getKeyPrefix() == '003')
        {
            cnt.MailingStreet = null;        
            cnt.MailingCountry = null;
            cnt.MailingCity = null;
            cnt.MailingState = null;
            cnt.MailingPostalCode = null;
            cnt.DPID_Primary_Address__c = null;
            
            cnt.OtherStreet = null;        
            cnt.OtherCountry = null;
            cnt.OtherCity = null;
            cnt.OtherState = null;
            cnt.OtherPostalCode = null;
            cnt.DPID_Secondary_Address__c = null;        
        }
        
        return null;
    }
    
    // validate account primary address before going to next page
    private List<String> validateAccount(Account acct)
    {
        List<String> errorMsgs = new List<String>();
        
        if(String.isBlank(acct.BillingStreet))
        {
            errorMsgs.add('Primary ' + errorMsgMap.get('Street').Message__c);
        }
        if(String.isBlank(acct.BillingCountry))
        {
            errorMsgs.add('Primary ' + errorMsgMap.get('Country').Message__c);
        }
        if(String.isBlank(acct.BillingCity))
        {
            errorMsgs.add('Primary ' + errorMsgMap.get('City').Message__c);
        }
        if(String.isBlank(acct.BillingState))
        {
            errorMsgs.add('Primary ' + errorMsgMap.get('State').Message__c);
        }
        if(String.isBlank(acct.BillingPostalCode))
        {
            errorMsgs.add('Primary ' + errorMsgMap.get('PostalCode').Message__c);
        }

        return errorMsgs;
    }
    
    // validate lead address before going to next page
    private List<String> validateLead(Lead lead)
    {
        List<String> errorMsgs = new List<String>();
        
        if(String.isBlank(lead.Street))
        {
            errorMsgs.add(errorMsgMap.get('Street').Message__c);
        }
        if(String.isBlank(lead.Country))
        {
            errorMsgs.add(errorMsgMap.get('Country').Message__c);
        }
        if(String.isBlank(lead.City))
        {
            errorMsgs.add(errorMsgMap.get('City').Message__c);
        }
        if(String.isBlank(lead.State))
        {
            errorMsgs.add(errorMsgMap.get('State').Message__c);
        }
        if(String.isBlank(lead.PostalCode))
        {
            errorMsgs.add(errorMsgMap.get('PostalCode').Message__c);
        }
        
        return errorMsgs;
    }
    
    // validate contact primary address before going to next page
    private List<String> validateContact(Contact cnt)
    {
        List<String> errorMsgs = new List<String>();
        
        if(String.isBlank(cnt.MailingStreet))
        {
            errorMsgs.add('Primary ' + errorMsgMap.get('Street').Message__c);
        }
        if(String.isBlank(cnt.MailingCountry))
        {
            errorMsgs.add('Primary ' + errorMsgMap.get('Country').Message__c);
        }
        if(String.isBlank(cnt.MailingCity))
        {
            errorMsgs.add('Primary ' + errorMsgMap.get('City').Message__c);
        }
        if(String.isBlank(cnt.MailingState))
        {
            errorMsgs.add('Primary ' + errorMsgMap.get('State').Message__c);
        }
        if(String.isBlank(cnt.MailingPostalCode))
        {
            errorMsgs.add('Primary ' + errorMsgMap.get('PostalCode').Message__c);
        }

        return errorMsgs;
    }

    
}
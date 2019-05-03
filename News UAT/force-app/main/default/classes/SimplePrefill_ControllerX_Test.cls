/*---------------------------------------------------------
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Author: Bohao Chen
 * Company: Salesforce.com
 * description: Test class for simplePrefill_controllerX
 * History:
 * 01/07/2013  Bohao Chen  Created
 * 2015-12-14  Atul Gupta  Updated
 // 2016-01-15 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - SimplePrefill_CotrollerX   83%
 ----------------------------------------------------------*/
@isTest
private class SimplePrefill_ControllerX_Test 
{
    // 2015-11-24 SFE-766 louis.wang@bluewolf.com - Fix test class so the vfUrl is no longer Org specific.
    static String vfUrl = 'https://sample.salesforce.com/apex/';  
    static void setup()
    {
        SystemParameters__c sp = new SystemParameters__c();
        sp.Name = 'RingLead_url';
        sp.Value__c = vfUrl;
        sp.External_Id__c = '1234';
        insert sp; 
    }

    static testMethod void saveAccountTest() 
    {
    	setup();

    	TestDataFactory.createAddressValidationErrorMessage();
    	
        PageReference pageRef = Page.AccountSimplePrefill;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(new Account());
        SimplePrefill_ControllerX simplePrefillCtr = new SimplePrefill_ControllerX(ctr);
        
        String accountPrefix = Account.SObjectType.getDescribe().getKeyPrefix();
        simplePrefillCtr.returnUrl = '/' + accountPrefix + '/o';
        
        PageReference newAccountPage = simplePrefillCtr.Save();
        
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        
        system.assertEquals(1, msgs.size());
        
        boolean b = false;
        for(Apexpages.Message msg:msgs)
        {
            if (msg.getDetail().contains(SimplePrefill_ControllerX.SAVE_ERR_MSG)) b = true;
        }
        
        system.assert(b);
        
        simplePrefillCtr.acct.BillingStreet = 'teststreet';
        simplePrefillCtr.acct.BillingCountry = 'Australia';
        simplePrefillCtr.acct.BillingCity = 'Sydney';
        simplePrefillCtr.acct.BillingState = 'NSW';
        simplePrefillCtr.acct.BillingPostalCode = '2000';
        simplePrefillCtr.acct.DPID_Primary_Address__c = '12345'; 
        
        simplePrefillCtr.acct.ShippingStreet = 'TestStreet1';
        simplePrefillCtr.acct.ShippingCountry = 'Australia';
        simplePrefillCtr.acct.ShippingCity = 'Chatswood';
        simplePrefillCtr.acct.ShippingState = 'NSW';
        simplePrefillCtr.acct.ShippingPostalCode = '2111';
        simplePrefillCtr.acct.DPID_Secondary_Address__c = '76543';
        
        newAccountPage = simplePrefillCtr.next();

        String url = vfUrl + 'uniqueAccount?'
                    + 'BillingCity=' + simplePrefillCtr.acct.BillingCity +
                    + '&BillingCountry=' + simplePrefillCtr.acct.BillingCountry +
                    + '&BillingPostalCode=' + simplePrefillCtr.acct.BillingPostalCode +                      
                    + '&BillingState=' + simplePrefillCtr.acct.BillingState +                      
                    + '&BillingStreet=' + simplePrefillCtr.acct.BillingStreet +
                    + '&DPID_Primary_Address__c=' + simplePrefillCtr.acct.DPID_Primary_Address__c +
                    + '&DPID_Secondary_Address__c=' + simplePrefillCtr.acct.DPID_Secondary_Address__c +
                    + '&sfdc.override=1' +                                                                
                    + '&ShippingCity=' + simplePrefillCtr.acct.ShippingCity +                      
                    + '&ShippingCountry=' + simplePrefillCtr.acct.ShippingCountry +
                    + '&ShippingPostalCode=' + simplePrefillCtr.acct.ShippingPostalCode +                    
                    + '&ShippingState=' + simplePrefillCtr.acct.ShippingState + 
                    + '&ShippingStreet=' + simplePrefillCtr.acct.ShippingStreet;               
                    
        system.assertEquals(url, newAccountPage.getUrl(), false);
        
        simplePrefillCtr.Cancel();
    }
    
    static testMethod void updateAccountTest() 
    {
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(accounts[0]);
        SimplePrefill_ControllerX simplePrefillCtr = new SimplePrefill_ControllerX(ctr);
        
        PageReference acctPage = simplePrefillCtr.save();
        
        simplePrefillCtr.clear();
    }
    
    static testMethod void savePersonAccountTest() 
    {
        setup();

        TestDataFactory.createAddressValidationErrorMessage();
        
        PageReference pageRef = Page.AccountSimplePrefill;
        Test.setCurrentPage(pageRef);
        apexpages.currentPage().getParameters().put('RecordType', Global_Helper.getRecordTypeIdByName('Private Party', 'Account'));
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(new Account());
        SimplePrefill_ControllerX simplePrefillCtr = new SimplePrefill_ControllerX(ctr);
        
        String accountPrefix = Account.SObjectType.getDescribe().getKeyPrefix();
        simplePrefillCtr.returnUrl = '/' + accountPrefix + '/o';
        
        PageReference newAccountPage = simplePrefillCtr.Save();
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        
        system.assertEquals(1, msgs.size());
        
        boolean b = false;
        for(Apexpages.Message msg:msgs)
        {
            if (msg.getDetail().contains(SimplePrefill_ControllerX.SAVE_ERR_MSG)) b = true;
        }
        
        system.assert(b);
        
        simplePrefillCtr.acct.BillingStreet = 'teststreet';
        simplePrefillCtr.acct.BillingCountry = 'Australia';
        simplePrefillCtr.acct.BillingCity = 'Sydney';
        simplePrefillCtr.acct.BillingState = 'NSW';
        simplePrefillCtr.acct.BillingPostalCode = '2000';
        simplePrefillCtr.acct.DPID_Primary_Address__c = '12345'; 
        
        simplePrefillCtr.acct.ShippingStreet = 'TestStreet1';
        simplePrefillCtr.acct.ShippingCountry = 'Australia';
        simplePrefillCtr.acct.ShippingCity = 'Chatswood';
        simplePrefillCtr.acct.ShippingState = 'NSW';
        simplePrefillCtr.acct.ShippingPostalCode = '2111';
        simplePrefillCtr.acct.DPID_Secondary_Address__c = '76543';
        
        newAccountPage = simplePrefillCtr.next();
		
		//SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - removed dead code
        
        simplePrefillCtr.Cancel();
    }
    
    static testMethod void updatePersonAccountTest() 
    {
        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        insert accounts;
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(accounts[0]);
        SimplePrefill_ControllerX simplePrefillCtr = new SimplePrefill_ControllerX(ctr);
        
        PageReference acctPage = simplePrefillCtr.save();
        
        simplePrefillCtr.clear();
    }
    
    static testMethod void saveLeadTest() 
    {
        setup();

        TestDataFactory.createAddressValidationErrorMessage();
        
        PageReference pageRef = Page.AccountSimplePrefill;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(new Lead());
        SimplePrefill_ControllerX simplePrefillCtr = new SimplePrefill_ControllerX(ctr);
        
        String leadPrefix = Lead.SObjectType.getDescribe().getKeyPrefix();
        simplePrefillCtr.returnUrl = '/' + leadPrefix + '/o';
        
        PageReference newLeadPage = simplePrefillCtr.Save();
        
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        
        system.assertEquals(1, msgs.size());
        
		boolean b = false;
		for(Apexpages.Message msg:msgs)
		{
		    if (msg.getDetail().contains(SimplePrefill_ControllerX.SAVE_ERR_MSG)) b = true;
		}
        
        simplePrefillCtr.lead.Street = 'teststreet';
        simplePrefillCtr.lead.Country = 'Australia';
        simplePrefillCtr.lead.City = 'Sydney';
        simplePrefillCtr.lead.State = 'NSW';
        simplePrefillCtr.lead.PostalCode = '2000';
        simplePrefillCtr.lead.datasan__Address_DPID__c = '12345'; 
        
        newLeadPage = simplePrefillCtr.next();
        
        String url = vfUrl + 'uniqueLead?'
                    + 'City=' + simplePrefillCtr.lead.City +
                    + '&Country=' + simplePrefillCtr.lead.Country +
                    + '&datasan__Address_DPID__c=' + simplePrefillCtr.lead.datasan__Address_DPID__c +                      
                    + '&PostalCode=' + simplePrefillCtr.lead.PostalCode +
                    + '&sfdc.override=1' +                       
                    + '&State=' + simplePrefillCtr.lead.State +
                    + '&Street=' + simplePrefillCtr.lead.Street;
                    
        system.assertEquals(url, newLeadPage.getUrl(), false);
        
        ctr = new ApexPages.StandardController(simplePrefillCtr.lead);
        simplePrefillCtr = new SimplePrefill_ControllerX(ctr);
    }
    
    static testMethod void updateLeadTest() 
    {
        List<Lead> leads = TestDataFactory.createLeads(1);
        insert leads;
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(leads[0]);
        SimplePrefill_ControllerX simplePrefillCtr = new SimplePrefill_ControllerX(ctr);
        
        PageReference leadPage = simplePrefillCtr.save();
        
        simplePrefillCtr.clear();
    }
    
    static testMethod void saveContactTest() 
    {        
        setup();

        TestDataFactory.createAddressValidationErrorMessage();
        
        PageReference pageRef = Page.ContactSimplePrefill;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(new Contact());
        SimplePrefill_ControllerX simplePrefillCtr = new SimplePrefill_ControllerX(ctr);
        
        String contactPrefix = Contact.SObjectType.getDescribe().getKeyPrefix();
        simplePrefillCtr.returnUrl = '/' + contactPrefix + '/o';
        
        PageReference newContactPage = simplePrefillCtr.Save();
        
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        
        system.assertEquals(1, msgs.size());
        
        boolean b = false;
        for(Apexpages.Message msg:msgs)
        {
            if (msg.getDetail().contains(SimplePrefill_ControllerX.SAVE_ERR_MSG)) b = true;
        }
        
        
        simplePrefillCtr.cnt.MailingStreet = 'teststreet';
        simplePrefillCtr.cnt.MailingCountry = 'Australia';
        simplePrefillCtr.cnt.MailingCity = 'Sydney';
        simplePrefillCtr.cnt.MailingState = 'NSW';
        simplePrefillCtr.cnt.MailingPostalCode = '2000';
        simplePrefillCtr.cnt.DPID_Primary_Address__c = '12345'; 
        
        simplePrefillCtr.cnt.OtherStreet = 'teststreet';
        simplePrefillCtr.cnt.OtherCountry = 'Australia';
        simplePrefillCtr.cnt.OtherCity = 'Sydney';
        simplePrefillCtr.cnt.OtherState = 'NSW';
        simplePrefillCtr.cnt.OtherPostalCode = '2000';
        simplePrefillCtr.cnt.DPID_Primary_Address__c = '12345'; 
        
        newContactPage = simplePrefillCtr.next();
		
		//SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - removed dead code
        
        ctr = new ApexPages.StandardController(simplePrefillCtr.cnt);
        simplePrefillCtr = new SimplePrefill_ControllerX(ctr);
    }
    
    static testMethod void updateContactTest() 
    {
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
    	
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(contacts[0]);
        SimplePrefill_ControllerX simplePrefillCtr = new SimplePrefill_ControllerX(ctr);
        
        PageReference contactPage = simplePrefillCtr.save();
        
        simplePrefillCtr.clear();
    }
    
    
    static testMethod void pageRedirectTest() 
    {
		//SFE-766 2016-01-15 atul.gupta@bluewolfgroup.com - removed dead code
        setup();
    	SimplePrefill_ControllerX.pageRedirect();
    }
}
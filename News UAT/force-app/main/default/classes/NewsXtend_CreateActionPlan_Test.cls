/**
 * @author       Bohao Chen
 * @date         2015-07-21
 * @version      1.0
 * @description  This is test class for controller NewsXtend_CreateActionPlan and visualforce page NewsXtend_CreateActionPlan
 * @mod          2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
 *                  - NewsXtend_CreateActionPlan     98%
 * @mod          2018-09-14 david.scullion@news.com.au - updated test class to include new Campaign Brief Form validation.
 *               
 */
@isTest(SeeAllData=false)
private class NewsXtend_CreateActionPlan_Test {
    static public List<Product2> products;
    static public List<Pricebook2> pricebooks;
    static public List<PricebookEntry> pricebookEntries;    
    static public void setupProductData(){    
        // create 10 products
        products = TestDataFactory.createProducts(1);
        // create pricebooks
        pricebooks = TestDataFactory.createCustomPricebookData();
        pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
    }
    
    /**
     * Test Case 1
     * Because NewsXtend_CreateActionPlan gets redirected from opportunity, code need to make sure it contains opportunity id as parameter in URL.
     * This test case is to test there is no error message when this page gets redirected from opportunity link 'Goto Action Plan' field.
     **/
    static testMethod void pageTestWithOpportunityId() 
    {
        // Create sample test data
        // Create an account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        insert accts;
        Account acct = accts[0];

        // create a contact
        List<Contact> conts = TestDataFactory.createContacts(1, acct);
        insert conts;
        Contact con = conts[0];

        // create an opportunity
        Id pricebookId = Test.getStandardPricebookId();
        
        
        List<Opportunity> oppties = TestDataFactory.createOpportunities_withContact(1, pricebookId, acct, con);
        insert oppties;
        Opportunity oppty = oppties[0];
        
        // testing starts here
        Test.startTest();

        // Load visualforce page
        PageReference pageRef = Page.NewsXtend_CreateActionPlan;
        Test.setCurrentPage(pageRef);

        oppty = refresh_Opportunity(oppty.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
        NewsXtend_CreateActionPlan controller = new NewsXtend_CreateActionPlan(sc);

        Test.stopTest();

        // Check there is no error message
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size());
    }
    
    /**
     * Test Case 2
     * Because NewsXtend_CreateActionPlan gets redirected from opportunity, code need to make sure it contains opportunity id as parameter in URL.
     * This test case is to test if page could display relevant error messages when this page is NOT from link 'Goto Action Plan' field on opportunity record.
     **/
    static testMethod void pageTestWithoutOpportunityId() 
    {
        // Create sample test data
        // Create an account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        insert accts;
        Account acct = accts[0];

        // create a contact
        List<Contact> conts = TestDataFactory.createContacts(1, acct);
        insert conts;
        Contact con = conts[0];

        // create an opportunity
        Id pricebookId = Test.getStandardPricebookId();

        List<Opportunity> oppties = TestDataFactory.createOpportunitiesNew(1, pricebookId, acct);        
        //insert oppties;
        Opportunity oppty = oppties[0];

        // testing starts here
        Test.startTest();

        // Load visualforce page
        PageReference pageRef = Page.NewsXtend_CreateActionPlan;
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
        NewsXtend_CreateActionPlan controller = new NewsXtend_CreateActionPlan(sc);

        Test.stopTest();
        
        // Check error message
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(1, pageMessages.size());

        ApexPages.Message msg = pageMessages[0];
        System.assertEquals(msg.getDetail(), 'Opportunity id has not been provided');
    }
    
    /**
     * Test Case 3
     * This case is to test if page could display relevant error messages when opportunity doesn't have account and contact
     **/
    static testMethod void pageTestWithInvalidOpportunityNoAccountNoContact() 
    {
        // Create an account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        accts[0].Is_Digital__c = true;
        accts[0].Digital_Status__c = 'Active';
        accts[0].Adpoint_id__c = '1';
        accts[0].Industry_Code__c = 'a1Y90000000I5r5';
        insert accts;
        Account acct = accts[0];

        // create a contact
        List<Contact> conts = TestDataFactory.createContacts(1, acct);
        insert conts;
        Contact con = conts[0];

        // create an opportunity
        Id pricebookId = Test.getStandardPricebookId();

        List<Opportunity> oppties = TestDataFactory.createOpportunitiesNew(1, pricebookId, NULL);

        // Valid values in opportunity
        //oppties[0].StageName = 'Closed Won';
        oppties[0].OpportunityGroup__c = 'NewsXtend';
        oppties[0].Has_an_Approved_SO__c = True;
        oppties[0].Payer_Account__c = acct.Id;
        oppties[0].Opportunity_Type__c = 'Agreement Negotiation';
        oppties[0].Competitor__c = 'Style Magazine';
        oppties[0].Campaign_Brief_Form_Completed__c = True ;

        // Invalid values in opportunity
        oppties[0].Account = NULL;
        //oppties[0].Contact__c = NULL;

        // there is a new validation rule, making both Payer Account and Contact required, when OppGroup=NewsXtend and Probablity=100%
        oppties[0].Payer_Account__c = acct.Id;
        oppties[0].Contact__c = con.Id;

        insert oppties;
        
        setupProductData();
        
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(oppties, products, pricebookEntries, null);
        insert olis;
        Id recordType = Schema.SObjectType.Briefing_Form__c.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Briefing_Form__c briefingForm = new Briefing_Form__c(RecordTypeId = recordType, Status__c = 'Completed');
        insert briefingForm;
        oppties[0].Briefing_Form__c = briefingForm.Id; 
        oppties[0].StageName = 'Closed Won';
        oppties[0].Campaign_Brief_Form_Completed__c = True;
        update oppties;
        Opportunity oppty = oppties[0];

        // testing starts here
        Test.startTest();

        // Load visualforce page
        PageReference pageRef = Page.NewsXtend_CreateActionPlan;
        Test.setCurrentPage(pageRef);

        oppty = refresh_Opportunity(oppty.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
        NewsXtend_CreateActionPlan controller = new NewsXtend_CreateActionPlan(sc);

        PageReference pr = controller.goToActionPlan();

        Test.stopTest();

        // Check error messages
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        // darshan.gosar@bluewolfgroup.com Reduce check for number of errors from 5 to 4 as opportunity contact has email address due to change in TestDataFactory create contact method
        System.assertEquals(4, pageMessages.size());

        Boolean fountAllMessages = false;
        String missingMessage;

        for(ApexPages.Message msg : pageMessages)
        {
            if(msg.getDetail() == 'Opportunity doesn\'t have contact')
            {
                fountAllMessages = true;
                continue;
            }
            else if(msg.getDetail() == 'Opportunity contact doesn\'t have email address')
            {
                fountAllMessages = true;
                continue;
            }
            else if(msg.getDetail() == 'Opportunity contact doesn\'t have mobile or phone number')
            {
                fountAllMessages = true;
                continue;
            }
            else if(msg.getDetail() == 'Opportunity doesn\'t have account')
            {
                fountAllMessages = true;
                continue;
            }
            else if(msg.getDetail() == 'Opportunity account doesn\'t have ABN')
            {
                fountAllMessages = true;
                continue;
            }
            else if(msg.getDetail() == 'Opportunity account doesn\'t have address detail')
            {
                fountAllMessages = true;
                continue;
            }

            fountAllMessages = false;
            missingMessage = msg.getDetail();
            break;
        }

        System.assert(fountAllMessages, 'You haven\'t tested error message: ' + missingMessage);

    }

    /**
     * Test Case 4
     * This case is to test if page could display relevant error messages when opportunity has account and contact BUT has invalid value on other fields
     **/
    static testMethod void pageTestWithInvalidOpportunity() 
    {
        // Create an account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        insert accts;
        Account acct = accts[0];

        // create a contact
        List<Contact> conts = TestDataFactory.createContacts(1, acct);
        conts[0].Email = 'test@test.com';
        conts[0].MobilePhone = '0453662771';
        insert conts;
        Contact con = conts[0];

        // create an opportunity
        Id pricebookId = Test.getStandardPricebookId();

        List<Opportunity> oppties = TestDataFactory.createOpportunitiesNew(1, pricebookId, NULL);

        // Invalid values in opportunity
        oppties[0].StageName = 'Open';
        oppties[0].OpportunityGroup__c = 'Other';
        oppties[0].Payer_Account__c = NULL;

        // valid values in opportunity
        oppties[0].AccountId = acct.Id;
        oppties[0].Contact__c = con.Id;
        oppties[0].Campaign_Brief_Form_Completed__c = True ;

        insert oppties;
        Opportunity oppty = oppties[0];

        // testing starts here
        Test.startTest();

        // Load visualforce page
        PageReference pageRef = Page.NewsXtend_CreateActionPlan;
        Test.setCurrentPage(pageRef);

        oppty = refresh_Opportunity(oppty.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
        NewsXtend_CreateActionPlan controller = new NewsXtend_CreateActionPlan(sc);

        PageReference pr = controller.goToActionPlan();

        Test.stopTest();

        // Check error messages
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(3, pageMessages.size());

        Boolean foundAllMessages = false;
        String missingMessage;

        for(ApexPages.Message msg : pageMessages)
        {
            if(msg.getDetail() == 'Opportunity probability is not 100%')
            {
                foundAllMessages = true;
                continue;
            }
            else if(msg.getDetail() == 'Opportunity platform is not \'NewsXtend\' or Lead Source is not a \'Walk In\'')
            {
                foundAllMessages = true;
                continue;
            }
            else if(msg.getDetail() == 'Opportunity contact doesn\'t have mobile or phone number')
            {
                foundAllMessages = true;
                continue;
            }
            else if(msg.getDetail() == 'Opportunity doesn\'t have payer account')
            {
                foundAllMessages = true;
                continue;
            }

            foundAllMessages = false;
            missingMessage = msg.getDetail();
            break;
        }

        System.assert(foundAllMessages, 'You haven\'t tested error message: ' + missingMessage);
    }

    /**
     * Test Case 5
     * This case is to test if page could display relevant error messages when opportunity has person account 
     * BUT that person account doesn't have person mailing address
     **/
    static testMethod void pageTestWithInvalidOpportunityWithPersonAccount() 
    {
        // Create a person account
        List<Account> accts = TestDataFactory.createAccounts(1, true);
        accts[0].PersonMailingStreet = NULL;
        accts[0].PersonMailingCity = NULL;
        accts[0].PersonMailingState = NULL;
        accts[0].PersonMailingPostalCode = NULL;
        accts[0].PersonMailingCountry = NULL;
        accts[0].PersonMailingLatitude = NULL;
        accts[0].PersonMailingLongitude = NULL;
        accts[0].AccountNumber = '39144774934';
        
        accts.addAll(TestDataFactory.createAccounts(1, false));
        accts[0].Is_Digital__c = true;
        accts[0].Digital_Status__c = 'Active';
        accts[0].Adpoint_id__c = '1';
        accts[0].Industry_Code__c = 'a1Y90000000I5r5';
        insert accts;
        Account acct = accts[0];

        // create a contact
        List<Contact> conts = TestDataFactory.createContacts(1, accts[1]);
        conts[0].Email = 'test@test.com';
        conts[0].MobilePhone = '0453662771';
        insert conts;
        Contact con = conts[0];

        // create an opportunity
        Id pricebookId = Test.getStandardPricebookId();

        List<Opportunity> oppties = TestDataFactory.createOpportunitiesNew(1, pricebookId, NULL);

        // valid values in opportunity
        //oppties[0].StageName = 'Closed Won';
        oppties[0].OpportunityGroup__c = 'NewsXtend';
        oppties[0].Has_an_Approved_SO__c = True;
        oppties[0].Payer_Account__c = acct.Id;
        oppties[0].Opportunity_Type__c = 'Agreement Negotiation';
        oppties[0].Competitor__c = 'Style Magazine';
        oppties[0].AccountId = acct.Id;
        oppties[0].Contact__c = con.Id;
        oppties[0].Campaign_Brief_Form_Completed__c = True ;

        insert oppties;
        
        setupProductData();
        
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(oppties, products, pricebookEntries, null);
        insert olis;
        Id recordType = Schema.SObjectType.Briefing_Form__c.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Briefing_Form__c briefingForm = new Briefing_Form__c(RecordTypeId = recordType, Status__c = 'Completed');
        insert briefingForm;
        oppties[0].Briefing_Form__c = briefingForm.Id; 
        oppties[0].StageName = 'Closed Won';
        update oppties;
        
        Opportunity oppty = oppties[0];

        // testing starts here
        Test.startTest();

        // Load visualforce page
        PageReference pageRef = Page.NewsXtend_CreateActionPlan;
        Test.setCurrentPage(pageRef);

        oppty = refresh_Opportunity(oppty.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
        NewsXtend_CreateActionPlan controller = new NewsXtend_CreateActionPlan(sc);

        PageReference pr = controller.goToActionPlan();

        Test.stopTest();

        // Check error messages
        ApexPages.Message[] pageMessages = ApexPages.getMessages();

        System.debug('@pageMessages: ' + pageMessages);

        System.assertEquals(1, pageMessages.size());

        Boolean fountAllMessages = false;
        String missingMessage;


        for(ApexPages.Message msg : pageMessages)
        {
            if(msg.getDetail() == 'Opportunity account doesn\'t have address detail')
            {
                fountAllMessages = true;
                continue;
            }

            fountAllMessages = false;
            missingMessage = msg.getDetail();
            break;
        }

        System.assert(fountAllMessages, 'You haven\'t tested error message: ' + missingMessage);
    }

    /**
     * Test Case 6
     * This case is to test if page controller can create a new action plan and associate it with opportunity 
     * when opportunity doesn't have action plan.
     **/
    static testMethod void pageTestWithValidOpportunityWithoutExistingActionPlan() 
    {
        // Create an account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        accts[0].Is_Digital__c = true;
        accts[0].Digital_Status__c = 'Active';
        accts[0].Adpoint_id__c = '1';
        accts[0].Industry_Code__c = 'a1Y90000000I5r5';
        insert accts;
        Account acct = accts[0];

        // create a contact
        List<Contact> conts = TestDataFactory.createContacts(1, acct);
        conts[0].Email = 'test@test.com';
        conts[0].MobilePhone = '0453662771';
        insert conts;
        Contact con = conts[0];

        // create an opportunity
        Id pricebookId = Test.getStandardPricebookId();

        List<Opportunity> oppties = TestDataFactory.createOpportunitiesNew(1, pricebookId, acct);
        //oppties[0].StageName = 'Closed Won';
        oppties[0].OpportunityGroup__c = 'NewsXtend';
        oppties[0].Has_an_Approved_SO__c = True;
        oppties[0].Payer_Account__c = acct.Id;
        oppties[0].Opportunity_Type__c = 'Agreement Negotiation';
        oppties[0].Competitor__c = 'Style Magazine';
        oppties[0].AccountId = acct.Id;
        oppties[0].Contact__c = con.Id;
        oppties[0].Campaign_Brief_Form_Completed__c = True ;
        insert oppties;
        
        setupProductData();
        
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(oppties, products, pricebookEntries, null);
        insert olis;
        Id recordType = Schema.SObjectType.Briefing_Form__c.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Briefing_Form__c briefingForm = new Briefing_Form__c(RecordTypeId = recordType, Status__c = 'Completed');
        insert briefingForm;
        oppties[0].Briefing_Form__c = briefingForm.Id; 
        
        oppties[0].StageName = 'Closed Won';
        oppties[0].Campaign_Brief_Form_Completed__c = True ;
        update oppties;
        Opportunity oppty = oppties[0];

        // testing starts here
        Test.startTest();

        // Load visualforce page
        PageReference pageRef = Page.NewsXtend_CreateActionPlan;
        Test.setCurrentPage(pageRef);

        oppty = refresh_Opportunity(oppty.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
        NewsXtend_CreateActionPlan controller = new NewsXtend_CreateActionPlan(sc);

        // redirect user to action plan page
        PageReference pr = controller.goToActionPlan();
        Test.setCurrentPage(pr);

        Test.stopTest();

        // Check there is no error message
        ApexPages.Message[] pageMessages = ApexPages.getMessages();
        System.assertEquals(0, pageMessages.size());

        // Check if new action plan gets created
        // Check this opportunity has been linked to action plan
        oppty = refresh_Opportunity(oppty.Id);

        System.assertEquals(pr.getUrl(), '/' + oppty.Action_Plan__c);

    }

    /**
     * Test Case 7
     * This case is to test if page controller can redirect user to existing action plan if opportunity has already had action plan.
     * when opportunity's action plan is unavailable
     **/
    static testMethod void pageTestWithExistingActionPlan() 
    {
        // Create an account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        accts[0].Is_Digital__c = true;
        accts[0].Digital_Status__c = 'Active';
        accts[0].Adpoint_id__c = '1';
        accts[0].Industry_Code__c = 'a1Y90000000I5r5';
        insert accts;
        Account acct = accts[0];

        // create a contact
        List<Contact> conts = TestDataFactory.createContacts(1, acct);
        conts[0].Email = 'test@test.com';
        conts[0].MobilePhone = '0453662771';
        insert conts;
        Contact con = conts[0];

        // create action plan
        Action_Plan__c ap = new Action_Plan__c();
        insert ap;

        // create an opportunity
        Id pricebookId = Test.getStandardPricebookId();

        List<Opportunity> oppties = TestDataFactory.createOpportunitiesNew(1, pricebookId, acct);
        //oppties[0].StageName = 'Closed Won';
        oppties[0].OpportunityGroup__c = 'NewsXtend';
        oppties[0].Has_an_Approved_SO__c = True;
        oppties[0].Payer_Account__c = acct.Id;
        oppties[0].Opportunity_Type__c = 'Agreement Negotiation';
        oppties[0].Competitor__c = 'Style Magazine';
        oppties[0].AccountId = acct.Id;
        oppties[0].Contact__c = con.Id;
        oppties[0].Action_Plan__c = ap.Id;
        oppties[0].Campaign_Brief_Form_Completed__c = True ;
        insert oppties;
        
        
        setupProductData();
        
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(oppties, products, pricebookEntries, null);
        insert olis;
        Id recordType = Schema.SObjectType.Briefing_Form__c.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Briefing_Form__c briefingForm = new Briefing_Form__c(RecordTypeId = recordType, Status__c = 'Completed');
        insert briefingForm;
        oppties[0].Briefing_Form__c = briefingForm.Id; 
        
        oppties[0].StageName = 'Closed Won';
        oppties[0].Campaign_Brief_Form_Completed__c = True ;
        update oppties;
        Opportunity oppty = oppties[0];


        // testing starts here
        Test.startTest();

        // Load visualforce page
        PageReference pageRef = Page.NewsXtend_CreateActionPlan;
        Test.setCurrentPage(pageRef);

        oppty = refresh_Opportunity(oppty.Id);

        ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
        NewsXtend_CreateActionPlan controller = new NewsXtend_CreateActionPlan(sc);

        controller.getFields();

        PageReference pr = controller.goToActionPlan();
        Test.setCurrentPage(pr);

        Test.stopTest();

        // Check there is no error message
        ApexPages.Message[] pageMessages = ApexPages.getMessages();

        System.debug('pageMessages: ' + pageMessages);

        System.assertEquals(0, pageMessages.size());

        // Check if new action plan gets created
        // Check this opportunity has been linked to action plan
        oppty = refresh_Opportunity(oppty.Id);

        System.assertEquals(pr.getUrl(), '/' + oppty.Action_Plan__c);
    }

    /**
     * Test Case 8
     * This case is to test if page controller can display relevant error message when there are exceptions from DML operation. 
     * e.x. updating opportunity without opportunity name
     **/
    static testMethod void pageTestForDatabaseException() 
    {
        // Create an account
        List<Account> accts = TestDataFactory.createAccounts(1, false);
        accts[0].Is_Digital__c = true;
        accts[0].Digital_Status__c = 'Active';
        accts[0].Adpoint_id__c = '1';
        accts[0].Industry_Code__c = 'a1Y90000000I5r5';
        insert accts;
        Account acct = accts[0];

        // create a contact
        List<Contact> conts = TestDataFactory.createContacts(1, acct);
        conts[0].Email = 'test@test.com';
        conts[0].MobilePhone = '0453662771';
        insert conts;
        Contact con = conts[0];

        // create an opportunity
        Id pricebookId = Test.getStandardPricebookId();

        List<Opportunity> oppties = TestDataFactory.createOpportunitiesNew(1, pricebookId, acct);
        //oppties[0].StageName = 'Closed Won';
        oppties[0].OpportunityGroup__c = 'NewsXtend';
        oppties[0].Has_an_Approved_SO__c = True;
        oppties[0].Payer_Account__c = acct.Id;
        oppties[0].Opportunity_Type__c = 'Agreement Negotiation';
        oppties[0].Competitor__c = 'Style Magazine';
        oppties[0].AccountId = acct.Id;
        oppties[0].Contact__c = con.Id;
        oppties[0].Campaign_Brief_Form_Completed__c = True ;
        insert oppties;
        
        setupProductData();
        
        // create opportunity line items
        List<OpportunityLineItem> olis = TestDataFactory.createOpportunityLineItems(oppties, products, pricebookEntries, null);
        insert olis;
        Id recordType = Schema.SObjectType.Briefing_Form__c.getRecordTypeInfosByName().get('Sales').getRecordTypeId();
        Briefing_Form__c briefingForm = new Briefing_Form__c(RecordTypeId = recordType, Status__c = 'Completed');
        insert briefingForm;
        oppties[0].Briefing_Form__c = briefingForm.Id; 
        oppties[0].StageName = 'Closed Won';
        oppties[0].Campaign_Brief_Form_Completed__c = True ;
        update oppties;
        Opportunity oppty = oppties[0];

        // testing starts here
        Test.startTest();

        // Load visualforce page
        PageReference pageRef = Page.NewsXtend_CreateActionPlan;
        Test.setCurrentPage(pageRef);

        oppty = refresh_Opportunity(oppty.Id);

        // blank name in order to throw database exception during the time when opportunity gets updated
        oppty.Name = NULL;

        ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
        NewsXtend_CreateActionPlan controller = new NewsXtend_CreateActionPlan(sc);

        PageReference pr = controller.goToActionPlan();

        Test.stopTest();

        // Check there is no error message
        ApexPages.Message[] pageMessages = ApexPages.getMessages();

        System.debug('pageMessages: ' + pageMessages);

        System.assertEquals(2, pageMessages.size());
    }

    static Opportunity refresh_Opportunity(Id opptyId)
    {        
        Opportunity output = [Select Name, Id, Status__c, OpportunityGroup__c, Contact__c, Contact__r.Email, Contact__r.Phone, Contact__r.MobilePhone, 
                                    Payer_Account__c, Account.IsPersonAccount, 
                                    Account.AccountNumber, Action_Plan__c, Probability, AccountId, LeadSource,
                                    Account.ShippingStreet, 
                                    Account.BillingStreet, 
                                    Account.PersonOtherStreet, 
                                    Account.PersonMailingStreet
                                From Opportunity Where Id =: opptyId Limit 1];            
        return output;
    }
}
// 2017-09-28 darshan.gosar@bluewolfgroup.com 
// This class provides test coverage for
//  - ViewEmailMessageCtrl          86%
@isTest(SeeAllData=false)
private class ViewEmailMessageCtrlTest{
    
    @isTest static void checkBookingEmailMessageTest() {
        
        Id businessAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        
        // create user records
        List<User> users = TestDataFactory.createUsers(2, 'System Administrator', null, false, false);
        insert users;
        
        SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert salesRep;
        
        // create account record
        Account acct = TestDataFactory.createSingleAccount(null, null, businessAccountRecordTypeId, null, null);
        insert acct;
        
        // create account record
        Account privatePartyAct = TestDataFactory.createAccounts(1, true)[0];
        insert privatePartyAct;
        
        // create contact records for account
        List<Contact> contacts = TestDataFactory.createContacts(1, acct);
        insert contacts;
        
        // create sales order for booking system record
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, acct, acct, acct, contacts[0], 'Leapfrog');
        insert salesOrders;
        
        // create booking for booking system record
        Booking__c booking = TestDataFactory.createBooking(salesOrders[0]);
        
        EmailMessage e = new EmailMessage();
        e.FromAddress='support@newsadds.com.au';
        e.FromName = 'News Adds Customer Support';
        e.HtmlBody='test ABC';
        e.RelatedToId = booking.Id;
        insert e;
        
        PageReference pageRef = Page.ViewEmailMessage;
        pageRef.getParameters().put('Id', e.Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(e);            
        ViewEmailMessageCtrl leapfrogCtr = new ViewEmailMessageCtrl(sc);
        
        leapfrogCtr.checkEmailMessage();
    }
    
    
    @isTest static void checkNonBookingEmailMessageTest() {
        
        EmailMessage e = new EmailMessage();
        e.FromAddress='support@newsadds.com.au';
        e.FromName = 'News Adds Customer Support';
        e.HtmlBody='test ABC';
        insert e;
        
        PageReference pageRef = Page.ViewEmailMessage;
        pageRef.getParameters().put('Id', e.Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(e);            
        ViewEmailMessageCtrl leapfrogCtr = new ViewEmailMessageCtrl(sc);
        
        leapfrogCtr.checkEmailMessage();
    }  
    public static EmailMessage e;
    public static Booking__c testBooking;
    public static Case testParentCase;
    public static List<Contact> testContacts;
    public static void setup(){
        Id businessAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Business Account').getRecordTypeId();
        
        // create user records
        List<User> users = TestDataFactory.createUsers(2, 'System Administrator', null, false, false);
        insert users;
        
        SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert salesRep;
        
        // create account record
        Account acct = TestDataFactory.createSingleAccount(null, null, businessAccountRecordTypeId, null, null);
        insert acct;
        
        // create account record
        Account privatePartyAct = TestDataFactory.createAccounts(1, true)[0];
        insert privatePartyAct;
        
        // create contact records for account
        testContacts = TestDataFactory.createContacts(2, acct);
        insert testContacts;
        
        // create sales order for booking system record
        List<Sales_Order__c> salesOrders = 
            TestDataFactory.createSalesOrders(1, acct, acct, acct, testContacts[0], 'Leapfrog');
        insert salesOrders;
        
        testParentCase = new Case(Origin='Call - Inbound', cLI__c = '61411');
        insert testParentCase;        
        // create booking for booking system record
        Booking__c testBooking = TestDataFactory.createBooking(salesOrders[0], false);
        testBooking.Placer_Contact__c = testContacts[0].Id;
        insert testBooking;
        e = new EmailMessage();
        e.FromAddress='support@newsadds.com.au';
        e.FromName = 'News Adds Customer Support';
        e.HtmlBody='test ABC';
        e.RelatedToId = testBooking.Id;        
    }
    @isTest static void testSendToContactAndAttachToCase() {
        setup();        
        insert e;        
        PageReference pageRef = Page.ViewEmailMessage;
        pageRef.getParameters().put('Id', e.Id);
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(e);            
        ViewEmailMessageCtrl leapfrogCtr = new ViewEmailMessageCtrl(sc);
        leapfrogCtr.parentCase.parentId = testParentCase.Id;
        leapfrogCtr.checkEmailMessage();
        leapfrogCtr.sendToPlacer = leapfrogCtr.sendToCustom = true;
        leapfrogCtr.parentCase.contactId = testContacts[1].Id;
        Test.startTest();
        leapfrogCtr.sendToContactAndAttachToCase();
        Integer expectedLimits = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(1, expectedLimits, 'Emails should have gone out');
    }
    
    @isTest static void testNegativeSendToContactAndAttachToCase_NO_PLACER_CUSTOM() {
        setup();        
        insert e;        
        PageReference pageRef = Page.ViewEmailMessage;
        pageRef.getParameters().put('Id', e.Id);
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(e);            
        ViewEmailMessageCtrl leapfrogCtr = new ViewEmailMessageCtrl(sc);
        leapfrogCtr.parentCase.parentId = testParentCase.Id;
        leapfrogCtr.checkEmailMessage();
        //leapfrogCtr.sendToPlacer = leapfrogCtr.sendToCustom = true;
        leapfrogCtr.parentCase.contactId = testContacts[1].Id;
        Test.startTest();
        leapfrogCtr.sendToContactAndAttachToCase();
        Test.stopTest();
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean b = false;
        for(Apexpages.Message msg:msgs){
            if (msg.getDetail().contains(ViewEmailMessageCtrl.NO_PLACER_CUSTOM)) b = true;
        }
        system.assert(b);
    }
}
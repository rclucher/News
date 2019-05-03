/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This test class is for trigger CaseManagement
 * History:
 * 09/07/2013  Bohao Chen  Created
 * 10/09/2013  Bohao Chen  Updated 
 */
@isTest
private class CaseManagement_Trigger_Test 
{
    static testMethod void caseAccountUpdateTest() 
    {
        // create an account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create opportunities
        List<Opportunity> opportunities = TestDataFactory.createOpportunities(10, null, accounts[0]);
        
        // create new cases
        List<Case> cases = new List<Case>();
        for(Opportunity o : opportunities)
        {
           cases.addAll(TestDataFactory.createCases(21, o, null));
        }

        system.debug('### CPU Time: ' + Limits.getCpuTime());
        system.debug('### CPU Limit: ' + Limits.getLimitCpuTime());

        Test.startTest();
                
        system.debug('### CPU Time: ' + Limits.getCpuTime());
        system.debug('### CPU Limit: ' + Limits.getLimitCpuTime());

        insert cases;

        // check if case account is as same as its opportunity account
        for(Case c : [Select Id, AccountId, Opportunity__r.AccountId From Case Where Id IN: cases])
        {
            system.assert(c.AccountId == c.Opportunity__r.AccountId);
        }
        
        Test.stopTest();
    }
    
    static testMethod void caseSalesOrderUpdateTest() 
    {
        // create users
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
        
        // set default sales rep
        // treat last user in the list as default sales rep
        SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert salesRep;
        
        // create different types of accounts
        List<Account> accounts = new List<Account>();
        
        Account payerAccount = TestDataFactory.createSingleAccount(null, null, null, 0, 0);
        Account advertiserAccount = TestDataFactory.createSingleAccount(null, null, null, 0, 0);
        Account placerAccount = TestDataFactory.createSingleAccount(null, null, null, 0, 0);
        
        accounts.add(payerAccount);
        accounts.add(advertiserAccount);
        accounts.add(placerAccount);
        insert accounts;
        
        // create a contact for placer account
        List<Contact> contacts = TestDataFactory.createContacts(1, placerAccount);
        insert contacts;
        
        // create sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(5, payerAccount, advertiserAccount, 
                                                                            placerAccount, contacts[0], null);
        insert salesOrders;
        
        // create bookings for each sales order
        List<Booking__c> bookings = new List<Booking__c>();
        
        for(Sales_Order__c so : salesOrders)
        {
            bookings.addAll(TestDataFactory.createBookings(5, so));
        }
        
        system.debug('===bookings=== ' + bookings);
        insert bookings;
        
        Test.startTest();
        
        // create new cases
        List<Case> cases = new List<Case>();
        for(Booking__c b : bookings)
        {
           cases.addAll(TestDataFactory.createCases(5, null, b));
        }
        
        insert cases;

        // check if case account is as same as its opportunity account
        for(Case c : [Select Id, Sales_Order__c, Booking__r.Sales_Order__c From Case Where Id IN: cases])
        {
            system.assertEquals(c.Sales_Order__c, c.Booking__r.Sales_Order__c);
        }

        Test.stopTest();
    }
    
    static testMethod void caseEmailReassignTest() 
    {
        // create users
        List<User> users = TestDataFactory.createUsers(40, 'System Administrator', null, null, false);
        users.add(TestDataFactory.createUser('System Administrator', 'Integrator', null, null, null, false));
        insert users;
        
        // create queues
        List<Group> groups = TestDataFactory.createGroups(40, 'Queue');
        
        // create email to case origin mappings
        TestDataFactory.createEmailCaseOriginMappings(groups);
        
        List<QueueSobject> mappingObjects = new List<QueueSobject>();
         
        for(Group g : groups)
        {
            QueueSobject mappingObject = new QueueSobject(QueueId = g.Id, SobjectType = 'Case');
            mappingObjects.add(mappingObject);
        }
        
        System.runAs(new User(Id = UserInfo.getUserId()))
        {insert mappingObjects;}

        System.runAs(users[40])
        {

            // create cases
            List<Case> caseGroup1 = TestDataFactory.createCases(40, null, null);
            List<Case> caseGroup2 = TestDataFactory.createCases(40, null, null);
            
            List<Case> cases = new List<Case>();        
            cases.addAll(caseGroup1);
            cases.addAll(caseGroup2);
            insert cases;
            
            // check case owner before creating email messages. 
            // case owner should be current user
            for(Case c : [Select Id, OwnerId From Case Where Id IN: caseGroup1 Or Id IN: caseGroup2])
            {
                system.assert(c.OwnerId == UserInfo.getUserId());
            }
            
            Test.startTest();
        

            // create email messages and link to case
            List<EmailMessage> emailMessages = new List<EmailMessage>();
            for(Integer i = 0; i < 40; i++)
            {
                EmailMessage em = TestDataFactory.createEmailMessage(caseGroup1[i], users[i].Email);
                em.Incoming = true;
                em.MessageDate = datetime.now();
                emailMessages.add(em);
            }
            
            for(Integer i = 0; i < 40; i++)
            {
                EmailMessage em = TestDataFactory.createEmailMessage(caseGroup2[i], groups[i].Email);
                em.Incoming = true;
                em.MessageDate = datetime.now();
                emailMessages.add(em);
            }
            
            insert emailMessages;
         
        
        Test.stopTest();
        
        // check case owner after creating email messages. 
        // case owner in case group 1 should be user
        // case owner in case group 40 should be queue
        for(Case c : [Select Id, OwnerId From Case Where Id IN: caseGroup1])
        {
            system.assert(String.valueOf(c.OwnerId).substring(0, 3) ==  Schema.SObjectType.User.getKeyPrefix());
        }
        
        
        for(Case c : [Select Id, OwnerId From Case Where Id IN: caseGroup2])
        {
            system.assert(String.valueOf(c.OwnerId).substring(0, 3) ==  Schema.SObjectType.Group.getKeyPrefix());
        }
    }
        
    }
/*
    @isTest static void test_updateCreditCheckedAccount() {

        // create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;

        Case creditCase = new Case();

        creditCase.AccountId = accounts[0].Id;
        creditCase.RecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Credit application').getRecordTypeId();
        creditCase.Status = 'Pending';

        insert creditCase;

        Test.startTest();

        creditCase.Status = 'Declined';
        update creditCase;

        Test.stopTest();
    }*/
}
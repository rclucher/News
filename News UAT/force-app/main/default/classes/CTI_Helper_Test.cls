/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * Author: Stuart Hamilton
 * Company: Salesforce.com
 * Description: This test class is for CTI_Helper
 * History:
 * 30/07/2013  Stuart Hamilton  Created
 * 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c   
 *    This class provides test coverage for
 *      - CTI_Helper.class      88% 
 * 2019-03-14 SFE-1068 david.scullion@news.com.au - updated Profile of user created to ensure access to Cases and Business Hours.
 **/
@isTest
public class CTI_Helper_Test{

    static testMethod void CreateCase_InCall_NoContact() {
        
        Id caseId = CTI_Helper.CreateCase(CTI_Helper.eventType.CALL_INBOUND, '12345', '12asID3312', null, null);
        
        List<Case> c = [SELECT Origin, Type, Status, Call_ID__c 
                        FROM Case WHERE Id = :caseId];
        
        System.assertEquals(1, c.size());
        System.assertEquals('Advertising', c[0].Type);
        System.assertEquals('Call - Inbound', c[0].Origin);
//        System.assertEquals('Open', c[0].Status);
        System.assertEquals('12asID3312', c[0].Call_ID__c);
        
    }

    static testMethod void CreateCallCase_InCall_OneContact() {
        
        List<Account> accs = TestDataFactory.createAccounts(1, false);
        insert accs;
        List<Contact> cons = TestDataFactory.createContacts(1, accs[0]);
        insert cons;
        
        List<String> conIds = new String[]{cons[0].Id};
        
        Id caseId = CTI_Helper.CreateCase(CTI_Helper.eventType.CALL_INBOUND, '12345', '23ga8awge8', conIds, null);
        
        List<Case> c = [SELECT Origin, Type, Status, ContactId, Call_ID__c 
                        FROM Case WHERE Id = :caseId];
        
        System.assertEquals(1, c.size());
        System.assertEquals('Advertising', c[0].Type);
        System.assertEquals('Call - Inbound', c[0].Origin);
  //      System.assertEquals('Open', c[0].Status);
        System.assertEquals(cons[0].Id, c[0].ContactId);
        System.assertEquals('23ga8awge8', c[0].Call_ID__c);
        
    }

    static testMethod void CreateCallCase_OutCall_OneContact() {
        
        List<Account> accs = TestDataFactory.createAccounts(1, false);
        insert accs;
        List<Contact> cons = TestDataFactory.createContacts(1, accs[0]);
        insert cons;
        
        List<String> conIds = new String[]{cons[0].Id};
        
        Id caseId = CTI_Helper.CreateCase(CTI_Helper.eventType.CALL_OUTBOUND, '12345', '23ga8awge8', conIds, null);
        
        List<Case> c = [SELECT Origin, Type, Status, ContactId, Call_ID__c 
                        FROM Case WHERE Id = :caseId];
        
        System.assertEquals(1, c.size());
        System.assertEquals('Advertising', c[0].Type);
        System.assertEquals('Call - Outbound', c[0].Origin);
//        System.assertEquals('Open', c[0].Status);
        System.assertEquals(cons[0].Id, c[0].ContactId);
        System.assertEquals('23ga8awge8', c[0].Call_ID__c);
        
    }

    
    static testMethod void CreateTask_InCall_OneAccount_NoContact() {
        
        List<Account> accs = TestDataFactory.createAccounts(1, false);
        insert accs;
        
        Id caseId = CTI_Helper.CreateCase(CTI_Helper.eventType.CALL_INBOUND, '12345', '12asID3312', null, new String[]{accs[0].Id});
        
        Id taskId = CTI_Helper.CreateTask(CTI_Helper.eventType.CALL_INBOUND, 'Case', caseId, DateTime.now(), Datetime.now(), 5, '12asID3312', '12345', true);
        
        List<Task> t = [SELECT Type, Subject, Status, CallDurationInSeconds, CallObject, ActivityDate, WhatId, WhoId, Call_ID__c
                        FROM Task
                        WHERE Id = :taskId]; 
            
        System.assertEquals(1, t.size());
        System.assertEquals('Call', t[0].Subject);
        System.assertEquals('Call - Inbound', t[0].Type);
        System.assertEquals('In Progress', t[0].Status);
        System.assertEquals(5, t[0].CallDurationInSeconds);
        System.assertEquals('12asID3312', t[0].Call_ID__c);
        System.assertEquals(caseId, t[0].WhatId);
        
    }
    
    static testMethod void CreateTask_OutCall_OneContact() {

        List<Account> accs = TestDataFactory.createAccounts(1, false);
        insert accs;
        List<Contact> cons = TestDataFactory.createContacts(1, accs[0]);
        insert cons;
        
        Id taskId = CTI_Helper.CreateTask(CTI_Helper.eventType.CALL_OUTBOUND, 'Contact', cons[0].Id, DateTime.now(), Datetime.now(), 5, '12asID3312', '12345', true);
        
        List<Task> t = [SELECT Type, Subject, Status, CallDurationInSeconds, CallObject, ActivityDate, WhatId, WhoId,Call_ID__c
                        FROM Task
                        WHERE Id = :taskId]; 
            
        System.assertEquals(1, t.size());
        System.assertEquals('Call', t[0].Subject);
        System.assertEquals('Call - Outbound', t[0].Type);
        System.assertEquals('In Progress', t[0].Status);
        System.assertEquals(5, t[0].CallDurationInSeconds);
        System.assertEquals('12asID3312', t[0].Call_ID__c);
        System.assertEquals(cons[0].AccountId, t[0].WhatId);
        
    }
    
    static testMethod void CreateTask_Email_OneContact() {

        List<Account> accs = TestDataFactory.createAccounts(1, false);
        insert accs;
        List<Contact> cons = TestDataFactory.createContacts(1, accs[0]);
        insert cons;
        
        Id taskId = CTI_Helper.CreateTask(CTI_Helper.eventType.EMAIL_INBOUND, 'Contact', cons[0].Id, DateTime.now(), Datetime.now(), 5, '12asID3312', '12345', true);
        
        List<Task> t = [SELECT Type, Subject, Status, CallDurationInSeconds, CallObject, ActivityDate, WhatId, WhoId,Call_ID__c
                        FROM Task
                        WHERE Id = :taskId]; 
            
        System.assertEquals(1, t.size());
        System.assertEquals('Email', t[0].Subject);
        System.assertEquals('Email - Inbound', t[0].Type);
        System.assertEquals('In Progress', t[0].Status);
        System.assertEquals(5, t[0].CallDurationInSeconds);
        System.assertEquals('12asID3312', t[0].Call_ID__c);
        System.assertEquals(cons[0].AccountId, t[0].WhatId);
        
    }    
    
    
    static testMethod void CreateTask_InCall_Lead_NoContact() {
        
        
        id leadId = TestDataFactory.createLeads(1)[0].id;
        
        Id taskId = CTI_Helper.CreateTask(CTI_Helper.eventType.CALL_INBOUND, 'Lead', leadId, DateTime.now(), Datetime.now(), 5, '12asID3312', '12345', true);
        
        List<Task> t = [SELECT Type, Subject, Status, CallDurationInSeconds, CallObject, ActivityDate, WhatId, WhoId, Call_ID__c
                        FROM Task
                        WHERE Id = :taskId]; 
            
        System.assertEquals(1, t.size());
        System.assertEquals('Call', t[0].Subject);
        System.assertEquals('Call - Inbound', t[0].Type);
        System.assertEquals('In Progress', t[0].Status);
        System.assertEquals(5, t[0].CallDurationInSeconds);
        System.assertEquals('12asID3312', t[0].Call_ID__c);
        System.assertEquals(leadId, t[0].WhatId);
        
    }    
    
    static testMethod void CreateTask_InCall_Opportunity_NoContact() {
        
        
        List<Account> accs = TestDataFactory.createAccounts(1, false);
        insert accs;

        // create a contact for account
        List<Contact> contacts = TestDataFactory.createContacts(1, accs[0]);
        insert contacts;        
        
        list<Opportunity> opptys = TestDataFactory.createOpportunities_withContact(1, null, accs[0], contacts[0]);
        insert opptys;
        id opptyId = opptys[0].id;
        
        Id taskId = CTI_Helper.CreateTask(CTI_Helper.eventType.CALL_INBOUND, 'Opportunity', opptyId, DateTime.now(), Datetime.now(), 5, '12asID3312', '12345', true);
        
        List<Task> t = [SELECT Type, Subject, Status, CallDurationInSeconds, CallObject, ActivityDate, WhatId, WhoId, Call_ID__c
                        FROM Task
                        WHERE Id = :taskId]; 
            
        System.assertEquals(1, t.size());
        System.assertEquals('Call', t[0].Subject);
        System.assertEquals('Call - Inbound', t[0].Type);
        System.assertEquals('In Progress', t[0].Status);
        System.assertEquals(5, t[0].CallDurationInSeconds);
        System.assertEquals('12asID3312', t[0].Call_ID__c);
        System.assertEquals(opptyId, t[0].WhatId);
        
    }  
 
  static testMethod void CreateTask_CampaignMember_Contact_OneContact() {

        List<Account> accs = TestDataFactory.createAccounts(1, false);
        insert accs;
        List<Contact> cons = TestDataFactory.createContacts(1, accs[0]);
        insert cons;
 
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        insert campaigns;
        
        List<CampaignMember> cms = TestDataFactory.createCampaignMembers(1, cons, campaigns[0]);
        insert cms;
        
        Id taskId = CTI_Helper.CreateTask(CTI_Helper.eventType.CALL_INBOUND, 'CampaignMember', cms[0].Id, DateTime.now(), Datetime.now(), 5, '12asID3312', '12345', true);
        
        List<Task> t = [SELECT Type, Subject, Status, CallDurationInSeconds, CallObject, ActivityDate, WhatId, WhoId,Call_ID__c
                        FROM Task
                        WHERE Id = :taskId]; 
            
        System.assertEquals(1, t.size());
        System.assertEquals('Call', t[0].Subject);
        System.assertEquals('Call - Inbound', t[0].Type);
        System.assertEquals('Done', t[0].Status);
        System.assertEquals(5, t[0].CallDurationInSeconds);
        System.assertEquals('12asID3312', t[0].Call_ID__c);
        System.assertEquals(cms[0].CampaignId, t[0].WhatId);
        System.assertEquals(cms[0].ContactId, t[0].WhoId);
    }       
     
     
     
    static testMethod void CreateTask_CampaignMember_Lead_OneContact() {


        List<Lead> leads = TestDataFactory.createLeads(1);
        insert leads;
 
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        insert campaigns;
        
        List<CampaignMember> cms = TestDataFactory.createCampaignMembers(1, leads, campaigns[0]);
        insert cms;
        
        Id taskId = CTI_Helper.CreateTask(CTI_Helper.eventType.CALL_INBOUND, 'CampaignMember', cms[0].Id, DateTime.now(), Datetime.now(), 5, '12asID3312', '12345', true);
        
        List<Task> t = [SELECT Type, Subject, Status, CallDurationInSeconds, CallObject, ActivityDate, WhatId, WhoId,Call_ID__c
                        FROM Task
                        WHERE Id = :taskId]; 
            
        System.assertEquals(1, t.size());
        System.assertEquals('Call', t[0].Subject);
        System.assertEquals('Call - Inbound', t[0].Type);
        System.assertEquals('Done', t[0].Status);
        System.assertEquals(5, t[0].CallDurationInSeconds);
        System.assertEquals('12asID3312', t[0].Call_ID__c);
        System.assertEquals(cms[0].LeadId, t[0].WhoId);
    }        
     
     
    static testMethod void CreateTask_InCall_Case_MultipleAccountAndSingleContact() {
        
        List<Account> accs = TestDataFactory.createAccounts(2, false);
        insert accs;
        List<Contact> cons = TestDataFactory.createContacts(1, accs[0]);
        insert cons;        
        
         List<String> conIds = new String[]{cons[0].Id};
        list<String> accIds = new list<String>();
         for (Account acc : accs)
         {
            accIds.add(acc.id);
         }
        
        Id caseId = CTI_Helper.CreateCase(CTI_Helper.eventType.CALL_INBOUND, '12345', '12asID3312', conIds, accIds);
        
        
        Id taskId = CTI_Helper.CreateTask(CTI_Helper.eventType.CALL_INBOUND, 'Case', caseId, DateTime.now(), Datetime.now(), 5, '12asID3312', '12345', true);
        
        List<Task> t = [SELECT Type, Subject, Status, CallDurationInSeconds, CallObject, ActivityDate, WhatId, WhoId, Call_ID__c
                        FROM Task
                        WHERE Id = :taskId]; 
            
        System.assertEquals(1, t.size());
        System.assertEquals('Call', t[0].Subject);
        System.assertEquals('Call - Inbound', t[0].Type);
        System.assertEquals('In Progress', t[0].Status);
        System.assertEquals(5, t[0].CallDurationInSeconds);
        System.assertEquals('12asID3312', t[0].Call_ID__c);
        System.assertEquals(caseId, t[0].WhatId);
        
    }        
    
    static testMethod void CreateTask_InCall_Other_NoContact() {
        
        List<Account> accs = TestDataFactory.createAccounts(1, false);
        insert accs;
        
        Id taskId = CTI_Helper.CreateTask(CTI_Helper.eventType.CALL_INBOUND, 'Account', accs[0].id, DateTime.now(), Datetime.now(), 5, '12asID3312', '12345', true);
        
        List<Task> t = [SELECT Type, Subject, Status, CallDurationInSeconds, CallObject, ActivityDate, WhatId, WhoId, Call_ID__c
                        FROM Task
                        WHERE Id = :taskId]; 
            
        System.assertEquals(1, t.size());
        System.assertEquals('Call', t[0].Subject);
        System.assertEquals('Call - Inbound', t[0].Type);
        System.assertEquals('In Progress', t[0].Status);
        System.assertEquals(5, t[0].CallDurationInSeconds);
        System.assertEquals('12asID3312', t[0].Call_ID__c);
        System.assertEquals(accs[0].id, t[0].WhatId);
        
    }  
    
    static testMethod void SetCaseOwnerValid() {
        // create the case, then change user session and check that case is reassigned
        
        List<Case> cases = TestDataFactory.createCases(1, null, null);
        insert cases;
        
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound NVM', null, false, false);
        insert users;
        
        System.runAs(users[0]) {
            CTI_Helper.SetCaseOwner (cases[0].Id);
        }
        Case c = [SELECT OwnerId FROM Case WHERE Id = :cases[0].Id];
        system.assertEquals(users[0].Id, c.OwnerId);
    }
    
    static testMethod void SetCaseOwnerInvalidCase() {
        // negative test for exception
        String err;
        try {
            CTI_Helper.SetCaseOwner (UserInfo.getUserId()); // any Id
        } catch (CTI_Helper.CTIHelperException e) {
            err = e.getMessage();
        }
        System.assertEquals('Case not found: ' + UserInfo.getUserId(), err);
    }
    
    static testMethod void SetCaseOwnerNoCase() {
        // negative test for exception
        String err;
        try {
            CTI_Helper.SetCaseOwner (null);
        } catch (CTI_Helper.CTIHelperException e) {
            err = e.getMessage();
        }
        System.assertEquals('Parameter caseId is required', err);
    }

}
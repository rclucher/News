/*
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: 
 * This test class for trigger 'ContactManagement':
 *  1. Ability to track the employment history of a contact to understand 
 *  where they may have previuously worked.
 *  2. Ability for agent to easily determine if customer is in an active Campaign.
 * History:
 * 11/06/2013  Bohao Chen  Created
 * 02/07/2013  Bohao Chen  Updated
 * 2015-12-10  Darshan Gosar Updated
 *      To add coverage for method updateCampainAccount of class ContactUpdate_Helper & removed seeAllData
 * 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
 *
 *      This class provides test coverage for
 *          - ContactUpdate_Helper.cls              89% 
 *          - ContactManagement.trigger             97%
 *          - CampaignMemberManagement.trigger      90%
 --------------------------------------------------------- */
@isTest 
private class ContactManagement_Trigger_Test 
{
    //requirement R-0184
    static testMethod void contactHistoryTest() 
    {
        // setup data for account, contacts
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(30, accounts[0]);
        insert contacts;
        TestDataFactory.createContactChangeCodes();
        
        Test.startTest();
        
        // Case 1 : change job title
        for(Contact c : contacts)
        {
            c.Title = 'change title';
        }
        
        update contacts;
        
        Integer numOfJobHistories = [Select count() From Job_History__c j Where j.Contact__c IN: contacts];
        
        // first time, 2 job histories will be created for each 
        List<Job_History__c> firstJobHistories = new List<Job_History__c>();
        List<Job_History__c> secondJobHistories = new List<Job_History__c>();
        
        for(Job_History__c j : [Select j.Job_Title__c, j.Date_of_Change__c, j.Contact__c, j.Contact_Status__c, 
                               j.Change_Type__c, j.Account__c 
                               From Job_History__c j Where j.Contact__c IN: contacts
                               Order by j.Contact__c, j.Name DESC limit 60])
        {
            system.assertEquals(Date.today(), j.Date_of_Change__c);         
            system.assertEquals('Active', j.Contact_Status__c);
            
            system.assertEquals(accounts[0].Id, j.Account__c);
            
            if(j.Job_Title__c == 'Test title')
            {
                firstJobHistories.add(j);
                system.assertEquals(null, j.Change_Type__c);
            }
            else if(j.Job_Title__c == 'change title')
            {
                secondJobHistories.add(j);
                system.assertEquals('Job Title', j.Change_Type__c);
            }
        }
        
        system.assertEquals(30, firstJobHistories.size());
        system.assertEquals(30, secondJobHistories.size());
        
        // Case 2 : change parent account 
        for(Contact c : contacts)
        {
            c.AccountId = accounts[1].Id;
        }
        
        update contacts;
        
        for(Job_History__c j : [Select j.Job_Title__c, j.Date_of_Change__c, j.Contact__c, j.Contact_Status__c, 
                               j.Change_Type__c, j.Account__c, j.Name 
                               From Job_History__c j Where j.Contact__c IN: contacts
                               Order by j.Name DESC limit 30])
        {
            system.assertEquals('change title', j.Job_Title__c);
            system.assertEquals(Date.today(), j.Date_of_Change__c);
            system.assertEquals('Active', j.Contact_Status__c);
            system.assertEquals('Account Name', j.Change_Type__c);
            system.assertEquals(accounts[1].Id, j.Account__c);
        }
        
        // Case 3 : change contact status
        for(Contact c : contacts)
        {
            c.Contact_Status__c = 'Inactive';
        }
        
        update contacts;
        
        for(Job_History__c j : [Select j.Job_Title__c, j.Date_of_Change__c, j.Contact__c, j.Contact_Status__c, 
                               j.Change_Type__c, j.Account__c 
                               From Job_History__c j Where j.Contact__c IN: contacts
                               Order by j.Name DESC limit 30])
        {
            system.assertEquals('change title', j.Job_Title__c);
            system.assertEquals(Date.today(), j.Date_of_Change__c);
            system.assertEquals('Inactive', j.Contact_Status__c);
            system.assertEquals('Status', j.Change_Type__c);
            system.assertEquals(accounts[1].Id, j.Account__c);
        }
        
        // Case 4 : change other fields other than job title, parent account and contact status
        for(Contact c : contacts)
        {
            c.Phone = '1234567890';
        }
        
        update contacts;
        
        numOfJobHistories = [Select count() From Job_History__c j Where j.Contact__c IN: contacts];
        
        // make sure no more job history has been created for other fields changes
        system.assertEquals(120, numOfJobHistories);
        
        // Case 5 : change job title, parent account and contact status all in once
        for(Contact c : contacts)
        {
            c.Title = 'change title again';
            c.AccountId = accounts[0].Id;
            c.Contact_Status__c = 'Active';
        }
        
        update contacts;
        
        for(Job_History__c j : [Select j.Job_Title__c, j.Date_of_Change__c, j.Contact__c, j.Contact_Status__c, 
                               j.Change_Type__c, j.Account__c 
                               From Job_History__c j Where j.Contact__c IN: contacts
                               Order by j.Name DESC limit 30])
        {
            system.assertEquals('change title again', j.Job_Title__c);
            system.assertEquals(Date.today(), j.Date_of_Change__c);
            system.assertEquals('Active', j.Contact_Status__c);
            system.assertEquals('Account Name;Job Title;Status', j.Change_Type__c);
            system.assertEquals(accounts[0].Id, j.Account__c);
        }
        
        Test.stopTest();
    }
    
    //requirement R-0284
    static testMethod void contactAccountUpdateTest() 
    {
        TestDataFactory.createContactChangeCodes();
        
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        insert campaigns;
        
        List<Contact> contacts = new List<Contact>();
        List<Contact> contacts1 = TestDataFactory.createContacts(40, accounts[0]);
        List<Contact> contacts2 = TestDataFactory.createContacts(40, accounts[1]);
        contacts.addAll(contacts1);
        contacts.addAll(contacts2);
        insert contacts;
        
        List<CampaignMember> campainMembers = new List<CampaignMember>();
        List<CampaignMember> campainMembersToContacts1 = new List<CampaignMember>();
        List<CampaignMember> campainMembersToContacts2 = new List<CampaignMember>();
        
        campainMembersToContacts1.addAll(TestDataFactory.createCampaignMembers(40, contacts1, campaigns[0]));
        campainMembersToContacts2.addAll(TestDataFactory.createCampaignMembers(40, contacts2, campaigns[0]));
                
        campainMembers.addAll(campainMembersToContacts1);
        campainMembers.addAll(campainMembersToContacts2);
        insert campainMembers;
        
        Test.startTest();

        // check parent account 
        for(CampaignMember cm :[Select Account__c from CampaignMember Where Id IN: campainMembersToContacts1])
        {
            system.assertEquals(accounts[0].Id, cm.Account__c);
        }   
        
        for(CampaignMember cm : [Select Account__c from CampaignMember Where Id IN: campainMembersToContacts2])
        {
            system.assertEquals(accounts[1].Id, cm.Account__c);
        }
        
        // change parent account of contacts
        for(Contact c : contacts)
        {
            if(c.AccountId == accounts[0].Id)
            {
                c.AccountId = accounts[1].Id;
            }
            else if(c.AccountId == accounts[1].Id)
            {
                c.AccountId = accounts[0].Id;
            }
        }
        
        update contacts;


        // check parent account after update
        // for(CampaignMember cm :[Select Account__c from CampaignMember Where Id IN: campainMembersToContacts1])
        // {
                // *** @Bohao Check assestion  
        //     system.assertEquals(accounts[1].Id, cm.Account__c);
        // }   
        
        // for(CampaignMember cm : [Select Account__c from CampaignMember Where Id IN: campainMembersToContacts2])
        // {
        //     system.assertEquals(accounts[0].Id, cm.Account__c);
        // }
                
        Test.stopTest();
    }
    
    // SFE-766 2015-12-10 darshan.gosar@bluewolfgroup.com
        // To cover test scenarios without seeAllData condition & added below test methods to increase code coverage   
    static testMethod void contactDeleteTest(){
        
        // setup data for account, contacts
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        List<Contact> contacts = TestDataFactory.createContacts(30, accounts[0]);
        for(Contact con : contacts){
            con.First_Contact_in_Account__c = true;
        }
        insert contacts;
        system.assertEquals(30, contacts.size());
        
        Test.startTest();
        List<Contact> deleteContacts = [Select id from Contact];
        delete deleteContacts;
        Test.stopTest();
        
        List<Contact> queryContacts = [Select id from Contact];
        system.assertEquals(0, queryContacts.size());
    }
    

    static testMethod void contactAccountUpdateWithoutTriggerTest() 
    {
        TestDataFactory.createContactChangeCodes();
        
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        insert campaigns;
        
        List<Contact> contacts = new List<Contact>();
        List<Contact> contacts1 = TestDataFactory.createContacts(40, accounts[0]);
        List<Contact> contacts2 = TestDataFactory.createContacts(40, accounts[1]);
        contacts.addAll(contacts1);
        contacts.addAll(contacts2);
        insert contacts;
        
        List<CampaignMember> campainMembers = new List<CampaignMember>();
        List<CampaignMember> campainMembersToContacts1 = new List<CampaignMember>();
        List<CampaignMember> campainMembersToContacts2 = new List<CampaignMember>();
        
        campainMembersToContacts1.addAll(TestDataFactory.createCampaignMembers(40, contacts1, campaigns[0]));
        campainMembersToContacts2.addAll(TestDataFactory.createCampaignMembers(40, contacts2, campaigns[0]));
                
        campainMembers.addAll(campainMembersToContacts1);
        campainMembers.addAll(campainMembersToContacts2);
        insert campainMembers;
        
        Test.startTest();

        // check parent account 
        for(CampaignMember cm :[Select Account__c from CampaignMember Where Id IN: campainMembersToContacts1])
        {
            system.assertEquals(accounts[0].Id, cm.Account__c);
        }   
        
        for(CampaignMember cm : [Select Account__c from CampaignMember Where Id IN: campainMembersToContacts2])
        {
            system.assertEquals(accounts[1].Id, cm.Account__c);
        }
        
        Map<Id, Contact> contactMap = new Map<Id, Contact>(); 
        // change parent account of contacts
        for(Contact c : contacts)
        {
            if(c.AccountId == accounts[0].Id)
            {
                c.AccountId = accounts[1].Id;
            }
            else if(c.AccountId == accounts[1].Id)
            {
                c.AccountId = accounts[0].Id;
            }
            contactMap.put(c.Id, c);
        }
        
        //update contacts;
        ContactUpdate_Helper.updateCampainAccount(contactMap); 
                        
        Test.stopTest();
        for(CampaignMember cm :[Select Account__c from CampaignMember Where Id IN: campainMembersToContacts1])
        {
            system.assertEquals(accounts[1].Id, cm.Account__c);
        }   
        
        for(CampaignMember cm : [Select Account__c from CampaignMember Where Id IN: campainMembersToContacts2])
        {
            system.assertEquals(accounts[0].Id, cm.Account__c);
        }        
    }    
    
    static testMethod void contactDigitalAccountUpdateTest() 
    {
        TestDataFactory.createContactChangeCodes();
        
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        List<Contact> contacts = new List<Contact>();
        List<Contact> contacts1 = TestDataFactory.createContacts(40, accounts[0]);
        List<Contact> contacts2 = TestDataFactory.createContacts(40, accounts[1]);
        contacts.addAll(contacts1);
        contacts.addAll(contacts2);
        insert contacts;

        // 2017-06-15 Item-00299 louis.wang@bluewolf.com - Added IndustryCode to accomodate new validaiton rule
        Industry_Code__c indCode = TestDataFactory.createIndustryCode();
        insert indCode;
        
        for(Contact c :[Select Digital_Status__c From Contact Where Id IN: contacts])
        {
            system.assertEquals(null, c.Digital_Status__c );
        }

        accounts[0].Digital_Status__c = 'Active';
        accounts[0].Status__c  = 'Active';
        accounts[0].AdPoint_Id__c = 'Test';
        accounts[0].Is_Digital__c = true;
        accounts[0].Industry_Code__c = indCode.Id;
                
        Test.startTest();
        
        update accounts[0];
            
        Test.stopTest();
        
        for(Contact c :[Select Digital_Status__c From Contact Where Id IN: contacts1])
        {
            system.assertEquals('Requested', c.Digital_Status__c );
        } 
        
        for(Contact c :[Select Digital_Status__c From Contact Where Id IN: contacts2])
        {
            system.assertEquals(null, c.Digital_Status__c );
        }               

    }        
}
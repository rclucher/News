/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Unit tests are class methods that verify whether a particular piece
* of code is working properly. Unit test methods take no arguments,
* commit no data to the database, and are flagged with the testMethod
* keyword in the method definition.
*
* All test methods in an organization are executed whenever Apex code is deployed
* to a production organization to confirm correctness, ensure code
* coverage, and prevent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production organization. In addition, all triggers must have some code coverage.
* 
* The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the organization size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
*
*   CampaignActionPage_ControllerX - coverage: 81%
*   CampaignActionPage_Helper - coverage: 91%
*/
@isTest
private class CampaignActionPage_ControllerX_Test {
    
    static testMethod void myUnitResponseTest() {
        
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        campaigns[0].Publication_Division__c = 'NWN;NMG;HWT';
        insert campaigns;
        
        List<Contact> contacts = new List<Contact>();
        List<Contact> contacts1 = TestDataFactory.createContacts(40, accounts[0]);
        List<Contact> contacts2 = TestDataFactory.createContacts(40, accounts[1]);
        contacts.addAll(contacts1);
        contacts.addAll(contacts2);
        insert contacts;
        
        
        list<CampaignMember> campaignMembers =  TestDataFactory.createCampaignMembers(contacts.size(), contacts, campaigns[0]);
        insert campaignMembers;
        
        insert TestDataFactory.createCampaignResponses(1,campaignMembers);
        
        
        Test.startTest();
        
        PageReference pageRef = Page.campaignActionPage;
        pageRef.getParameters().put('refTabId','ts-nn-nn');
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(campaignMembers[0]);
        
        CampaignActionPage_ControllerX controller = new CampaignActionPage_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        
        
        
        controller.setToInprogress();
        
        controller.member = [SELECT In_Progress__c, Locked_By__c, Execution_Status__c, CampaignId, ContactId,
                             LeadId, Account__c, Status, Call_Count__c, Call_Back_Date__c, Campaign.Max_Call_Attempts__c,
                             DNC_Summary__c, Campaign.Name
                             FROM CampaignMember WHERE Id =: controller.member.Id LIMIT 1];
        
        system.assert(controller.member.In_Progress__c);  
        system.assert(controller.member.Locked_By__c == UserInfo.getUserId());
        
        
        controller.doCancel();
        system.assert(!controller.member.In_Progress__c);
        
        controller.newResponse = new Campaign_Response__c(); 
        controller.setToInprogress();        
        controller.newResponse.Response_Type__c = 'Follow Up';
        controller.newResponse.Response_SubType__c = 'Decision Maker Unavailable';
        controller.newResponse.Call_Back_Date__c = system.now();
        controller.doSave();
        system.assert(controller.member.Execution_Status__c == 'Attempted');
        system.assert(controller.member.Locked_By__c == null);   
        
        controller.newResponse = new Campaign_Response__c(); 
        controller.setToInprogress();  
        controller.newResponse.Response_Type__c = 'Follow Up';
        controller.newResponse.Response_SubType__c = 'Request Call Back - Same Agent';
        controller.doSave();
        system.assert(controller.member.Execution_Status__c == 'Call to Do');
        
        controller.newResponse = new Campaign_Response__c(); 
        controller.setToInprogress();  
        controller.newResponse.Response_Type__c = 'Follow Up';
        controller.newResponse.Response_SubType__c = 'Request Call Back - Any Agent';
        controller.doSave();
        system.assert(controller.member.Execution_Status__c == 'Call to Do'); 
        system.assert(controller.member.Locked_By__c == null);         
        
        controller.newResponse = new Campaign_Response__c(); 
        controller.setToInprogress();  
        controller.newResponse.Response_Type__c = 'Yes';
        controller.newResponse.Response_SubType__c = 'New Business';
        controller.doSave();
        system.assert(controller.member.Execution_Status__c == 'Completed'); 
        system.assert(controller.member.Locked_By__c == null);        

        controller.newResponse = new Campaign_Response__c(); 
        controller.setToInprogress();  
        controller.newResponse.Response_Type__c = 'No';
        controller.newResponse.Response_SubType__c = 'No ROI';
        controller.doSave();
        system.assert(controller.member.Execution_Status__c == 'Completed'); 
        system.assert(controller.member.Locked_By__c == null);        

        controller.newResponse = new Campaign_Response__c(); 
        controller.setToInprogress();  
        controller.newResponse.Response_Type__c = 'No Sales Call';
        controller.newResponse.Response_SubType__c = 'Out of Business';
        controller.doSave();
        system.assert(controller.member.Execution_Status__c == 'Completed'); 
        system.assert(controller.member.Locked_By__c == null);        

        Test.stopTest();
    }
    
    
    static testMethod void myUnitLimitTest() {
        
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        insert campaigns;
        
        List<Contact> contacts = new List<Contact>();
        List<Contact> contacts1 = TestDataFactory.createContacts(40, accounts[0]);
        contacts.addAll(contacts1);
        insert contacts;
        
        
        list<CampaignMember> campaignMembers =  TestDataFactory.createCampaignMembers(contacts.size(), contacts, campaigns[0]);
        insert campaignMembers;
        
        insert TestDataFactory.createCampaignResponses(1,campaignMembers);
        
        Test.startTest(); 
        
        PageReference pageRef = Page.campaignActionPage;        
        ApexPages.StandardController stdController = new ApexPages.StandardController(campaignMembers[0]);       
        CampaignActionPage_ControllerX controller = new CampaignActionPage_ControllerX(stdController);
        Test.setCurrentPage(pageRef);
        
        controller.setToInprogress(); 
        
        controller.member = [SELECT In_Progress__c, Locked_By__c, Execution_Status__c, CampaignId, ContactId,
                             LeadId, Account__c, Status, Call_Count__c, Call_Back_Date__c, Campaign.Max_Call_Attempts__c,
                             DNC_Summary__c, Campaign.Name
                             FROM CampaignMember WHERE Id =: controller.member.Id LIMIT 1];
        
        system.assert(controller.member.In_Progress__c);  
        system.assert(controller.member.Locked_By__c == UserInfo.getUserId());
        
        controller.member = [Select ContactId, CampaignId, LeadId, Account__c, Status, Locked_By__c, Call_Count__c, Call_Back_Date__c, Campaign.Max_Call_Attempts__c,DNC_Summary__c
                             from CampaignMember
                             where id = :campaignMembers[0].id];
        
        
        controller.newResponse.Response_Type__c = 'Follow Up';
        controller.newResponse.Response_SubType__c = 'Request Call Back - Same Agent';
        controller.member.Campaign.Max_Call_Attempts__c = 0;
        controller.newResponse.Call_Attempt__c = controller.member.Campaign.Max_Call_Attempts__c + 1;
        system.debug('@ myUnitLimitTest controller.newResponse.Call_Attempt__c:' + controller.newResponse.Call_Attempt__c);
        system.debug('@ myUnitLimitTest controller.member.Campaign.Max_Call_Attempts__c:' + controller.member.Campaign.Max_Call_Attempts__c);
        system.debug('@ myUnitLimitTest controller.newResponse.Response_Type__c:' + controller.newResponse.Response_Type__c);
        controller.doSave();
        
        system.debug('@ myUnitLimitTest #controller.newResponse.Call_Attempt__c:' + controller.newResponse.Call_Attempt__c);
        system.debug('@ myUnitLimitTest #controller.member.Campaign.Max_Call_Attempts__c:' + controller.member.Campaign.Max_Call_Attempts__c);
        system.debug('@ myUnitLimitTest #controller.newResponse.Response_Type__c:' + controller.newResponse.Response_Type__c);        
        system.debug('@ myUnitLimitTest #controller.member.Execution_Status__c:' + controller.member.Execution_Status__c);
        system.assert(controller.member.Execution_Status__c == 'Call Limit Reached'); 
        system.assert(controller.member.Locked_By__c == null);
                
        Test.stopTest();
        
        
    }   
    
    
    static testMethod void myUnitLeadMemberTest() {
        
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        insert campaigns;
        
        list<Lead> leads = TestDataFactory.createLeads(1);
        insert leads;
        
        
        list<CampaignMember> campaignMembers =  TestDataFactory.createCampaignMembers(1, leads, campaigns[0]);
        insert campaignMembers;
        
        insert TestDataFactory.createCampaignResponses(1,campaignMembers);
        
        
        Test.startTest();
        
        PageReference pageRef = Page.campaignActionPage;
        pageRef.getParameters().put('refTabId','ts-nn-nn');
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(campaignMembers[0]);
        
        CampaignActionPage_ControllerX controller = new CampaignActionPage_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        
        
        
        controller.setToInprogress();  
        
        controller.member = [SELECT In_Progress__c, Locked_By__c, Execution_Status__c, CampaignId, ContactId,
                             LeadId, Account__c, Status, Call_Count__c, Call_Back_Date__c, Campaign.Max_Call_Attempts__c,
                             DNC_Summary__c, Campaign.Name
                             FROM CampaignMember WHERE Id =: controller.member.Id LIMIT 1];
        
        system.assert(controller.member.In_Progress__c);  
        system.assert(controller.member.Locked_By__c == UserInfo.getUserId());
        
        controller.setToInprogress();
        
        
        Test.stopTest();
        
        
    }  

    static testMethod void PersonAccountMemberTest() {
        
        List<Account> accounts = TestDataFactory.createAccounts(1, true);
        insert accounts;
        accounts = [SELECT Id, IsPersonAccount, PersonContactId FROM Account WHERE Id =: accounts];

        list<Id> contactIds = new list<Id>();
        for(Account a: accounts)
        {
            contactIds.add(a.PersonContactId);
        }
        list<Contact> contacts = [SELECT Id, Name, AccountId FROM Contact WHERE Id IN :contactIds];

        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        insert campaigns;

        list<CampaignMember> campaignMembers =  TestDataFactory.createCampaignMembers(1, contacts, campaigns[0]);
        insert campaignMembers;

        insert TestDataFactory.createCampaignResponses(1,campaignMembers);
        
        Test.startTest();
        
        PageReference pageRef = Page.campaignActionPage;
        pageRef.getParameters().put('refTabId','ts-nn-nn');
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(campaignMembers[0]);
        
        CampaignActionPage_ControllerX controller = new CampaignActionPage_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        
        
        
        controller.setToInprogress();  
        
        controller.member = [SELECT In_Progress__c, Locked_By__c, Execution_Status__c, CampaignId, ContactId,
                             LeadId, Account__c, Status, Call_Count__c, Call_Back_Date__c, Campaign.Max_Call_Attempts__c,
                             DNC_Summary__c, Campaign.Name
                             FROM CampaignMember WHERE Id =: controller.member.Id LIMIT 1];
        
        system.assert(controller.member.In_Progress__c);  
        system.assert(controller.member.Locked_By__c == UserInfo.getUserId());
        
        controller.setToInprogress();
        
        Test.stopTest();
        
        
    }   

    static testMethod void additionalTest() {
        
        SystemParameters__c sysParam = new SystemParameters__c();
        sysParam.Name = 'Opportunity.Contact__c';
        sysParam.External_Id__c = 'Opportunity.Contact__c';
        sysParam.Value__c = 'CF00N90000008T5gO';
        insert sysParam;

        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        campaigns[0].Publication_Division__c = 'NWN;NMG;HWT';
        insert campaigns;
        
        List<Contact> contacts = new List<Contact>();
        List<Contact> contacts1 = TestDataFactory.createContacts(40, accounts[0]);
        List<Contact> contacts2 = TestDataFactory.createContacts(40, accounts[1]);
        contacts.addAll(contacts1);
        contacts.addAll(contacts2);
        insert contacts;
        
        
        list<CampaignMember> campaignMembers =  TestDataFactory.createCampaignMembers(contacts.size(), contacts, campaigns[0]);
        insert campaignMembers;
        
        CampaignMember cm = campaignMembers[0];
        cm.Execution_Status__c = 'Completed';
        update cm;

        insert TestDataFactory.createCampaignResponses(1,campaignMembers);
                
        Test.startTest();
        
        PageReference pageRef = Page.campaignActionPage;
        pageRef.getParameters().put('refTabId','ts-nn-nn');
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(campaignMembers[0]);
        
        CampaignActionPage_ControllerX controller = new CampaignActionPage_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        String oppContactId = controller.opportunityContactFieldId;            
        
        controller.setToInprogress();    
        controller.doCancel();

        Test.stopTest();
    }      

    static testMethod void anotherUserTest() {
        
        SystemParameters__c sysParam = new SystemParameters__c();
        sysParam.Name = 'Opportunity.Contact__c';
        sysParam.External_Id__c = 'Opportunity.Contact__c';
        sysParam.Value__c = 'CF00N90000008T5gO';
        insert sysParam;

        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        campaigns[0].Publication_Division__c = 'NWN;NMG;HWT';
        insert campaigns;
        
        List<Contact> contacts = new List<Contact>();
        List<Contact> contacts1 = TestDataFactory.createContacts(40, accounts[0]);
        List<Contact> contacts2 = TestDataFactory.createContacts(40, accounts[1]);
        contacts.addAll(contacts1);
        contacts.addAll(contacts2);
        insert contacts;
    
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
        
        list<CampaignMember> campaignMembers =  TestDataFactory.createCampaignMembers(contacts.size(), contacts, campaigns[0]);
        insert campaignMembers;


        CampaignMember cm = campaignMembers[0];
        cm.Execution_Status__c = 'Call Limit Reached';
        cm.Locked_By__c = users[0].Id;
        update cm;

        insert TestDataFactory.createCampaignResponses(1,campaignMembers);
                
        Test.startTest();
        
        PageReference pageRef = Page.campaignActionPage;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(campaignMembers[0]);
        CampaignActionPage_ControllerX controller = new CampaignActionPage_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        controller.setToInprogress();        
        controller.doCancel();

        Test.stopTest();
    }   

    static testMethod void alreadyStartedAnotherCampaignMemberTest() {
        
        SystemParameters__c sysParam = new SystemParameters__c();
        sysParam.Name = 'Opportunity.Contact__c';
        sysParam.External_Id__c = 'Opportunity.Contact__c';
        sysParam.Value__c = 'CF00N90000008T5gO';
        insert sysParam;

        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        campaigns[0].Publication_Division__c = 'NWN;NMG;HWT';
        insert campaigns;
        
        List<Contact> contacts = new List<Contact>();
        List<Contact> contacts1 = TestDataFactory.createContacts(40, accounts[0]);
        List<Contact> contacts2 = TestDataFactory.createContacts(40, accounts[1]);
        contacts.addAll(contacts1);
        contacts.addAll(contacts2);
        insert contacts;
    
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
        
        list<CampaignMember> campaignMembers =  TestDataFactory.createCampaignMembers(contacts.size(), contacts, campaigns[0]);
        insert campaignMembers;

        for(CampaignMember cm : campaignMembers)
        {
            cm.Locked_By__c = UserInfo.getUserId();
        }
        update campaignMembers;

        insert TestDataFactory.createCampaignResponses(1,campaignMembers);
                
        Test.startTest();
        
        PageReference pageRef = Page.campaignActionPage;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(campaignMembers[0]);
        CampaignActionPage_ControllerX controller = new CampaignActionPage_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        controller.setToInprogress();        
        controller.doCancel();

        Test.stopTest();
    }  

    static testMethod void leadCampaignMemberTest() {
                
        List<Campaign> campaigns = TestDataFactory.createCampaigns(1);
        campaigns[0].Publication_Division__c = 'NWN;NMG;HWT';
        insert campaigns;
        
        list<Lead> leads = TestDataFactory.createLeads(1);
        insert leads;        
        
        list<CampaignMember> campaignMembers =  TestDataFactory.createCampaignMembers(1, leads, campaigns[0]);
        insert campaignMembers;
        
        insert TestDataFactory.createCampaignResponses(1,campaignMembers);

                
        Test.startTest();
        
        PageReference pageRef = Page.campaignActionPage;
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(campaignMembers[0]);
        CampaignActionPage_ControllerX controller = new CampaignActionPage_ControllerX(stdController); 
        
        Test.setCurrentPage(pageRef);
        controller.setToInprogress();        

        // convert the lead
        Database.LeadConvert lc = new database.LeadConvert();
        lc.setLeadId(leads[0].id);
        lc.setDoNotCreateOpportunity(false);
        lc.setConvertedStatus('Converted');
        //lc.setConvertedStatus('Qualified');
        Database.LeadConvertResult lcr = Database.convertLead(lc);

        controller.doSave();

        Test.stopTest();
    }  

}
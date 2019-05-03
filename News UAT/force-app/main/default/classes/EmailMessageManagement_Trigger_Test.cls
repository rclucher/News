/**
 * Author: Bohao Chen
 * Company: Salesforce.com
 * This class contains unit tests for validating the behavior of Apex classes and triggers.
 * test requirement R-1275
 * 20/11/2013  Bohao Chen  Created
 * 26/02/2014  Bohao Chen  Updated
 * 
 *  Test Coverage Summary
 *      - EmailMessageManagement.trigger    100%
 *      - EmailMessageTrigger_Helper.cls    84%
 */
@isTest
private class EmailMessageManagement_Trigger_Test 
{
    static testMethod void caseOwnerTest() 
    {
        // create integrator user
        User user = TestDataFactory.createUser('System Administrator', 'Integrator', null, null, null, false);
        insert user;
        
        // create group emails
        List<Group> groups = TestDataFactory.createGroups(1, 'Queue');
        
        // Associate a queue with the sObject that can be associated with the queue, including custom objects.
        List<QueueSobject> mappingObjects = new List<QueueSobject>();
         
        for(Group g : groups)
        {
            QueueSobject mappingObject = new QueueSobject(QueueId = g.Id, SobjectType = 'Case');
            mappingObjects.add(mappingObject);
        }
        
        System.runAs(new User(Id = UserInfo.getUserId()))
        {insert mappingObjects;}
        
        // create new cases
        List<Case> cases = TestDataFactory.createCases(1, null, null);
        
        Integer i = 0;
        
        for(Case c : cases)
        {
            c.Origin = 'Email - Inbound for Routing';
        }
        insert cases;
        
        system.debug('@EmailMessageManagement_Trigger_Test caseOriginCopyTest insert test cases');
        
        // 2016-04-06 Item-00056 louis.wang@bluewolf.com - added custom setting records 'Keyword Match'
        list<Keyword_Match__c> kmList = new list<Keyword_Match__c>();
        Keyword_Match__c km1 = new Keyword_Match__c();
        km1.Name = 'KM-000001';
        km1.External_Id__c = 'KM-000001';
        km1.Input_Object__c = 'EmailMessage';
        km1.Input_Keyword__c = 'Employment';
        km1.Output_Object__c = 'Case';
        km1.Output_Object_Field__c = 'Pillar__c';
        km1.Output_Object_Field_String__c = 'CareerOne';
        kmList.add(km1);
        Keyword_Match__c km2 = new Keyword_Match__c();
        km2.Name = 'KM-000002';
        km2.External_Id__c = 'KM-000002';
        km2.Input_Object__c = 'EmailMessage';
        km2.Input_Keyword__c = 'Newslife Media';
        km2.Output_Object__c = 'Case';
        km2.Output_Object_Field__c = 'Genesys_Publication__c';
        km2.Output_Object_Field_String__c = 'News Life Media';
        kmList.add(km2);
        insert kmList;

        Test.startTest();
        
        i = 0;
        for(Case c : [Select Origin, OwnerId, SuppliedTo__c 
                      From Case 
                      Where Id IN: cases])
        {
           //system.assertEquals('Email - Inbound for Routing', c.Origin);
           system.assertEquals('Case owner: ' + UserInfo.getUserId(), 'Case owner: ' + c.OwnerId);
        }
        
        List<EmailMessage> ems = new List<EmailMessage>();
        
        i = 0;
        for(Case c : cases)
        {
            EmailMessage em = TestDataFactory.createEmailMessage(c, 'queue' + i + '@email.com');
            em.Incoming = true;
            //Added LMancilla SFE-445 - Convert HTML to text for Ad Proof
            em.Subject='Ad Proof';
            em.HtmlBody='<HTML>Employment Newslife Media</HTML>';            
            //End LMancilla
            em.MessageDate = datetime.now();
            ems.add(em);
            i++;
        }
        
        insert ems;

        system.debug('@EmailMessageManagement_Trigger_Test caseOriginCopyTest ems: ' + ems);

        i = 0;
        for(Case c : [Select Case_Origin_Copy__c, Origin, OwnerId, SuppliedTo__c 
                      From Case 
                      Where Id IN: cases])
        {
           //system.assertEquals('Email - Inbound for Routing', c.Origin);
           system.assertEquals('Case owner: ' + groups[0].Id, 'Case owner: ' + c.OwnerId);
        }
                
        Test.stopTest();
        
    }
}
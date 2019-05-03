@isTest
public class AT_AccountHierarchy_Test {
    static final String serviceType = Account_Services_Rel__c.Services__c.getDescribe().getPicklistValues()[0].getValue();
    
    static Account cons, agency, client;
    
    static void init() {
        RecordType agencyRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Agency_Account_Type'];
        RecordType businessRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Business_Account_Type'];
        RecordType kacRT = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'KAC'];
        
        cons = new Account(Name = 'Consortium', No_Parent_Account__c = true, RecordTypeId = kacRT.Id, Account_Type__c = 'Consortium', Type='Consortium');
        
        insert cons;
        
        agency = new Account(Name = 'Agency', No_Parent_Account__c = true, RecordTypeId = agencyRT.Id, Consortium__c = cons.Id);
        
        insert agency;
        
        client = new Account(Name = 'Client', No_Parent_Account__c = true, RecordTypeId = businessRT.Id);
        
        insert client;
        
        Account_Services_Rel__c rel = new Account_Services_Rel__c(Source_Account__c = agency.Id, Target_Account__c = client.Id, Services__c = serviceType);
        
        insert rel;
    }
    
    @isTest
    static void testConsortium() {
        init();
        
        Test.startTest();
        
        AT_AccountHierarchy.Hierarchy h = AT_AccountHierarchy.getAccountHierarchy(cons.Id);
        
        System.assertEquals('consortium', h.type);
        System.assertEquals(agency.Id, h.records[0].name);
        System.assertEquals(serviceType, h.records[0].items[0].name);
        System.assertEquals(client.Id, h.records[0].items[0].items[0].name);
        
        Test.stopTest();
    }
    
    @isTest
    static void testAgency() {
        init();
        
        Test.startTest();
        
        AT_AccountHierarchy.Hierarchy h = AT_AccountHierarchy.getAccountHierarchy(agency.Id);
        
        System.assertEquals('agency', h.type);
        System.assertEquals(agency.Id, h.records[0].name);
        System.assertEquals(serviceType, h.records[0].items[0].name);
        System.assertEquals(client.Id, h.records[0].items[0].items[0].name);
        
        Test.stopTest();
    }
    
    @isTest
    static void testClient() {
        init();
        
        Test.startTest();
        
        AT_AccountHierarchy.Hierarchy h = AT_AccountHierarchy.getAccountHierarchy(client.Id);
        
        System.assertEquals('client', h.type);
        System.assertEquals(cons.Id, h.records[0].name);
        System.assertEquals(agency.Id, h.records[0].items[0].name);
        
        Test.stopTest();
    }
}
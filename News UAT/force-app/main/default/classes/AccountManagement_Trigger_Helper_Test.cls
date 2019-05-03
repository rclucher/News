/*---------------------------------------------------------
* Author:  Darshan Gosar
* Description: This class contains unit tests for validating the behavior of AccountManagement trigger
* Company: Salesforce.com
* Date: 04/08/2016
* History:
* 04/08/2016   Darshan Gosar       Created
// AdSales-121 2016-08-04 darshan.gosar@bluewolfgroup.com
// This class provides test coverage for 
//  - AccountManagement_Trigger_Helper             89% 
* History: Mohsin Ali
* 03-09-2018: Added New Test Method setCustomerTierTest() and addSpend_Tier_Mapping() to add create Spend_Tier_Mapping__c
* Code Coverage: AccountManagement_Trigger_Helper	   77%
* Adding @TestSetup Method to create User and also Unit01 for Code Coverage
* Code Coverage: AccountManagement_Trigger_Helper	   84%
---------------------------------------------------------*/
@isTest
private class AccountManagement_Trigger_Helper_Test
{
    
    @testSetup
    static void createUser(){
        String profileName = 'The Aus Sales';
        String userroleName = 'System Administrator';
        Profile pf = [select id, name from profile where name=: profileName];
        UserRole ur = [select id, name from userrole where name =:userroleName];
        String orgId=UserInfo.getOrganizationId();
        String dateString=String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','') ;
        Integer RandomId=Integer.valueOf(Math.rint(Math.random()*1000000));
        String uniqueName=orgId+dateString+RandomId;
        User uu=new User(firstname = 'ABC',
                         lastName = 'XYZ',
                         email = uniqueName + '@test' + orgId + '.org',
                         Username = uniqueName + '@test' + orgId + '.org',
                         EmailEncodingKey = 'ISO-8859-1',
                         Alias = uniqueName.substring(18, 23),
                         TimeZoneSidKey = 'Australia/Sydney',
                         LocaleSidKey = 'en_US',
                         LanguageLocaleKey = 'en_US',
                         userRoleID = ur.id,
                         ProfileId = pf.Id
                        );
        insert uu;
    }
    static testMethod void insertTest() 
    {
        List<Account> actList = TestDataFactory.createAccounts(2 , True);
        Test.startTest();
        insert actList;
        Test.stopTest();
        
        List<Account> extractAccountList = [Select Id, PersonContactId, Primary_Contact__c from Account where Id in :actList];
        
        system.assertEquals(2, extractAccountList.size(), 'Account Creation Failed');
        
        for(Account a: extractAccountList){
            system.assertEquals(a.PersonContactId, a.Primary_Contact__c, 'Primary Contact Not populated correctly for Person Account');
        }
        
    }
    
    static testMethod void setCustomerTierTest() 
    {
        List<Account> actList = TestDataFactory.createAccounts(2 , True);
        Test.startTest();
        addSpend_Tier_Mapping();
        insert actList;
        Test.stopTest();
        
        List<Account> extractAccountList = [Select Id, PersonContactId, Primary_Contact__c from Account where Id in :actList];
        
        system.assertEquals(2, extractAccountList.size(), 'Account Creation Failed');
        
        for(Account a: extractAccountList){
            system.assertEquals(a.PersonContactId, a.Primary_Contact__c, 'Primary Contact Not populated correctly for Person Account');
        }
        
    }
    
    /*
* 19-11-2018: Mohsin Ali: Writing Test Method for Code Coverage
*/
    static testMethod void Unit01(){
        
        String profileName = 'The Aus Sales';
        String userroleName = 'System Administrator';
        List<Account> actList = TestDataFactory.createAccounts(2 , FALSE);        
        Test.startTest();
        addSpend_Tier_Mapping();
        insert actList;
        
        List<Account> extractAccountList = [Select Id, PersonContactId, Primary_Contact__c from Account where Id in :actList];
        
        ID ownerprofileID = UserInfo.getProfileId();
        ID ownerID = UserInfo.getUserId();
        System.debug('ownerID: '+ownerID+' ownerprofileID: '+ownerprofileID);        
        updateOwnerID(extractAccountList,ownerID);
        
        User us = [select id, name from User where CreatedDate = Today order by createddate desc limit 1];
        System.debug('User us: '+us);
        
        System.runAs(us){
            ownerprofileID = UserInfo.getProfileId();
            ownerID = UserInfo.getUserId();
            System.debug('ownerID: '+ownerID+' ownerprofileID: '+ownerprofileID);
            try{
                updateOwnerID(extractAccountList,ownerID);
            }
            catch (Exception e){
                System.debug('Exception: '+e);
                
            }
        }
        
        delete actList;
        
        actList = TestDataFactory.createAccounts(2 , TRUE);        
        addSpend_Tier_Mapping();
        insert actList;
        
        Test.stopTest();        
    }
    
    @isTest
    static void testDeleteParentAccount() {
        List<Account> accounts = TestDataFactory.createAccounts(2 , FALSE);
        
        insert accounts;
        
        accounts[0].No_Parent_Account__c = false;
        accounts[0].ParentId = accounts[1].Id;
        
        update accounts[0];
        
        Test.startTest();
        
        delete accounts[1];
        
        Account acc = [SELECT No_Parent_Account__c, ParentId FROM Account WHERE Id = :accounts[0].Id];
        
        System.assertEquals(true, acc.No_Parent_Account__c);
        System.assertEquals(null, acc.ParentId);
        
        Test.stopTest();
    }
    
    public static void updateOwnerID(List<Account> accounts, String profileName){
        for(Account a: accounts){
            a.OwnerID = [select id from User where Profile.Name =: profileName And IsActive = TRUE LIMIT 1].ID;
        }
    }
    
    public static void updateOwnerID(List<Account> accounts, ID ownerID){
        for(Account a: accounts){
            a.OwnerID = ownerID;
        }
        update accounts;
    }
    
    public static void addSpend_Tier_Mapping(){
        List<Spend_Tier_Mapping__c> spendTM = new List<Spend_Tier_Mapping__c>();
        Spend_Tier_Mapping__c tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='SME';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=0;	tmpSpend_Tier_Mapping.Max_Spend__c=1;	tmpSpend_Tier_Mapping.Tier__c='New Client';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Key';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=0;	tmpSpend_Tier_Mapping.Max_Spend__c=1;	tmpSpend_Tier_Mapping.Tier__c='New Client';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='IMA';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=0;	tmpSpend_Tier_Mapping.Max_Spend__c=1;	tmpSpend_Tier_Mapping.Tier__c='New Client';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Con';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=0;	tmpSpend_Tier_Mapping.Max_Spend__c=1;	tmpSpend_Tier_Mapping.Tier__c='New Client';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='SME';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=1;	tmpSpend_Tier_Mapping.Max_Spend__c=2499;	tmpSpend_Tier_Mapping.Tier__c='D';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='IMA';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=1;	tmpSpend_Tier_Mapping.Max_Spend__c=14999;	tmpSpend_Tier_Mapping.Tier__c='D';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Con';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=1;	tmpSpend_Tier_Mapping.Max_Spend__c=19999;	tmpSpend_Tier_Mapping.Tier__c='D';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Key';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=1;	tmpSpend_Tier_Mapping.Max_Spend__c=49999;	tmpSpend_Tier_Mapping.Tier__c='D';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='SME';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=2500;	tmpSpend_Tier_Mapping.Max_Spend__c=4999;	tmpSpend_Tier_Mapping.Tier__c='C';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='SME';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=5000;	tmpSpend_Tier_Mapping.Max_Spend__c=19999;	tmpSpend_Tier_Mapping.Tier__c='B';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='IMA';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=15000;	tmpSpend_Tier_Mapping.Max_Spend__c=29999;	tmpSpend_Tier_Mapping.Tier__c='C';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='SME';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=20000;	tmpSpend_Tier_Mapping.Max_Spend__c=49999;	tmpSpend_Tier_Mapping.Tier__c='A';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Con';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=20000;	tmpSpend_Tier_Mapping.Max_Spend__c=49999;	tmpSpend_Tier_Mapping.Tier__c='C';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='IMA';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=30000;	tmpSpend_Tier_Mapping.Max_Spend__c=59999;	tmpSpend_Tier_Mapping.Tier__c='B';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Con';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=50000;	tmpSpend_Tier_Mapping.Max_Spend__c=99999;	tmpSpend_Tier_Mapping.Tier__c='B';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='SME';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=50000;	tmpSpend_Tier_Mapping.Max_Spend__c=99999;	tmpSpend_Tier_Mapping.Tier__c='AA';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Key';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=50000;	tmpSpend_Tier_Mapping.Max_Spend__c=249999;	tmpSpend_Tier_Mapping.Tier__c='C';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='IMA';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=60000;	tmpSpend_Tier_Mapping.Max_Spend__c=124999;	tmpSpend_Tier_Mapping.Tier__c='A';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Con';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=100000;	tmpSpend_Tier_Mapping.Max_Spend__c=299999;	tmpSpend_Tier_Mapping.Tier__c='A';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='SME';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=100000;	tmpSpend_Tier_Mapping.Max_Spend__c=999990;	tmpSpend_Tier_Mapping.Tier__c='AAA';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='IMA';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=125000;	tmpSpend_Tier_Mapping.Max_Spend__c=249999;	tmpSpend_Tier_Mapping.Tier__c='AA';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Key';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=250000;	tmpSpend_Tier_Mapping.Max_Spend__c=499999;	tmpSpend_Tier_Mapping.Tier__c='B';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='IMA';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=250000;	tmpSpend_Tier_Mapping.Max_Spend__c=999990;	tmpSpend_Tier_Mapping.Tier__c='AAA';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Con';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=300000;	tmpSpend_Tier_Mapping.Max_Spend__c=749999;	tmpSpend_Tier_Mapping.Tier__c='AA';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Key';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=500000;	tmpSpend_Tier_Mapping.Max_Spend__c=749000;	tmpSpend_Tier_Mapping.Tier__c='A';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Key';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=750000;	tmpSpend_Tier_Mapping.Max_Spend__c=1999999;	tmpSpend_Tier_Mapping.Tier__c='AA';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Con';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=750000;	tmpSpend_Tier_Mapping.Max_Spend__c=999990;	tmpSpend_Tier_Mapping.Tier__c='AAA';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        tmpSpend_Tier_Mapping.Segment__c='Key';	tmpSpend_Tier_Mapping.Platform__c='Print';	tmpSpend_Tier_Mapping.Min_Spend__c=2000000;	tmpSpend_Tier_Mapping.Max_Spend__c=999990;	tmpSpend_Tier_Mapping.Tier__c='AAA';	spendTM.add(tmpSpend_Tier_Mapping);tmpSpend_Tier_Mapping = new Spend_Tier_Mapping__c();
        insert spendTM;
    }   
    
}
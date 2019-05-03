@isTest
public class NXX2_SendEmailForCustomerActivityTest{
    public static testMethod void testTriggerHandler() {
        NXX2_TestUtility.disableAllTriggerDuringTesting();
        User currentUser = TestDataFactory.createUser('System Administrator','Test','Demo',null,false,false);
        System.runAs(currentUser){
            Test.startTest();
            NXX2_TestUtility.insertProofSetting();
            UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];
            Profile profile1 = [Select Id from Profile where name = 'System Administrator'];
            User portalAccountOwner1 = new User(
                UserRoleId = portalRole.Id,
                ProfileId = profile1.Id,
                Username = System.now().millisecond() + 'test2@test.com',
                Alias = 'batman',
                Email='test@testSalesforce.com',
                EmailEncodingKey='UTF-8',
                Firstname='Bruce',
                Lastname='Wayne',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='America/Chicago'
            );
            insert portalAccountOwner1;
            List<Account> accounts = TestDataFactory.createAccounts(3,false);
            accounts[0].ownerId = portalAccountOwner1.Id;
            insert accounts;
            List<Contact> contacts = TestDataFactory.createContacts(1,accounts[0]);
            contacts[0].Email = 'NXX2Test123@News.com';
            contacts[0].NewsXtend_My_Account_Access__c = true;
            insert contacts;
            NXX2_TestUtility.createPortalUser(contacts[0]);
            List<Opportunity> opportunities = TestDataFactory.createOpportunities_withContact(2,Test.getStandardPricebookId(),accounts[0],contacts[0]);
            opportunities[0].Payer_Account__c = accounts[1].Id;
            opportunities[1].Payer_Account__c = accounts[2].Id;
            insert opportunities;
            List<String> roles = new List<String>();
            Schema.DescribeFieldResult fieldResult = Contact_Role__c.Role__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry f : ple){
                roles.add(f.getValue());
            }       
            List<Customer_Role_Access__c> roleAccess = NXX2_TestUtility.createCustomerRoleAccess(roles);
            roleAccess[1].Account_Access__c = 'Public Read/Write';
            insert roleAccess;
            List<Contact_Role__c> contactRoles = NXX2_TestUtility.createContactRole(contacts[0].Id,accounts,roleAccess[0].Contact_Role__c);
            Order__c campaignOrder = NXX2_TestUtility.createCampaignOrder(opportunities[0].Id, contacts[0].Id, accounts[0].Id);
            List<Product_Order__c> pos = NXX2_TestUtility.createProductOrder(1, campaignOrder.Id);
            SocialCampaign__c proof = NXX2_TestUtility.createProof(pos[0].Id);
            List<Customer_Task__c> activityForCO = NXX2_TestUtility.createCustomerActivityForCampaignOrder(new List<Order__c>{campaignOrder});
            List<Customer_Task__c> activityForPO = NXX2_TestUtility.createCustomerActivityForProductOrder(pos);
            List<Customer_Task__c> activityForProof = NXX2_TestUtility.createCustomerActivity(new List<SocialCampaign__c>{proof});
            Test.stopTest();
            NXX2_SendEmailForCustomerActivity.sendEmailToCustomer(activityForCO);
            NXX2_SendEmailForCustomerActivity.sendEmailToCustomer(activityForPO);
            NXX2_SendEmailForCustomerActivity.sendEmailToCustomer(new List<Customer_Task__c>{activityForProof[0]});
            NXX2_SendEmailForCustomerActivity.sendEmailToCustomer(new List<Customer_Task__c>{activityForProof[1]});
            NXX2_SendEmailForCustomerActivity.sendEmailToCustomer(new List<Customer_Task__c>{activityForProof[2]});
            List<Customer_Task__c> allActivities = [SELECT Number_of_email_sent__c FROM Customer_Task__c];
            for(Customer_Task__c task : allActivities){
                task.Number_of_email_sent__c = 2;
            }
            update allActivities;
            for(Customer_Task__c task : allActivities){
                NXX2_SendEmailForCustomerActivity.sendEmailToCustomer(new List<Customer_Task__c>{task});
            }
        }
    }
}